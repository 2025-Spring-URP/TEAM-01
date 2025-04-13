`timescale 1ns/1ps

module axi4_if_decoding #(
    parameter ID_WIDTH         = 4,
    parameter ADDR_WIDTH       = 32,
    parameter DATA_WIDTH       = 256,
    parameter CHUNK_MAX_BEATS  = 4   // 최대 몇 beat 모아서 한 덩어리(chunk)로 전송?
)(
    input  wire clk,
    input  wire rst_n,

    // AXI Write Address / Write Data 채널( slave modport )
    AXI4_A_IF.slave s_axi_aw,
    AXI4_W_IF.slave s_axi_w,

    // 디코딩 결과 출력 (TLP 등으로 패킷화할 때 사용한다고 가정)
    output logic [ADDR_WIDTH-1:0]                  out_addr,
    output logic [7:0]                             out_length,    // 단위: DW(4 Byte)
    output logic [15:0]                            out_bdf,
    output logic                                   out_is_memwrite,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0]  out_wdata,
    output logic                                   out_valid,
    input  logic                                   out_ready
);

    //--------------------------------------------------------------------------
    // 1) 상수/상태 변수
    //--------------------------------------------------------------------------
    localparam logic [15:0] DEVICE_BDF = 16'h0200;  // 예시로 고정한 BDF ID

    // Address 보관
    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic [7:0]            awlen_reg;      // alen=(beat수-1)
    logic [ID_WIDTH-1:0]   awid_reg;
    logic                  awvalid_reg;    
    logic                  awready_r;

    // "AW valid 받음" 플래그와 남은 beat 수
    logic                  aw_valid_received; 
    logic [7:0]            beats_left; // = awlen_reg + 1

    // Write data 수신 버퍼
    logic [ADDR_WIDTH-1:0] chunk_offset;
    logic [DATA_WIDTH-1:0] chunk_buf [0:CHUNK_MAX_BEATS-1];
    logic [2:0]            chunk_count;  // 현재까지 모은 beat 수(0~CHUNK_MAX_BEATS)
    logic                  wready_r;

    // handshake, out_valid 제어
    logic                  out_valid_reg;

    //--------------------------------------------------------------------------
    // 2) Address Channel (AW)
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_r        <= 1'b0;
            awvalid_reg      <= 1'b0;
            awaddr_reg       <= '0;
            awlen_reg        <= '0;
            awid_reg         <= '0;
            aw_valid_received<= 1'b0;
            beats_left       <= '0;
        end
        else begin
            // 간단히 always ready = 1 (버퍼 여유 있다고 가정)
            awready_r <= 1'b1;

            // 새 Burst 수신
            if (s_axi_aw.avalid && s_axi_aw.aready) begin
                awvalid_reg       <= 1'b1; 
                awaddr_reg        <= s_axi_aw.aaddr;
                awlen_reg         <= s_axi_aw.alen;    // alen=(beat수-1)
                awid_reg          <= s_axi_aw.aid;
                aw_valid_received <= 1'b1;             // W 수신 준비
                beats_left        <= s_axi_aw.alen + 1; // (beat수 -1) +1 = beat수
            end

            // 만약 burst가 끝났으면(아래 W 채널에서 beats_left=0 → end)
            // 다시 AW 수신 대기 상태로 돌려놓음
            if (beats_left == 0) begin
                aw_valid_received <= 1'b0;
            end
        end
    end

    assign s_axi_aw.aready = awready_r;

    //--------------------------------------------------------------------------
    // 3) Write Data Channel (W) + chunk 관리
    //--------------------------------------------------------------------------
    //  - AW handshake 완료(aw_valid_received=1) 후에야 W 데이터를 수신
    //  - beats_left 관리 (alen+1번 받으면 해당 burst 끝)
    //  - chunk_count == CHUNK_MAX_BEATS → out_valid
    //  - leftover(wlast나 beats_left=0) → out_valid
    //--------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_r        <= 1'b0;
            out_valid_reg   <= 1'b0;
            chunk_count     <= 0;
            chunk_offset    <= 0;
        end
        else begin
            // Wready = 1 iff aw_valid_received=1 (즉, 주소를 받은 상태)
            wready_r <= aw_valid_received;

            // out_valid=1 → out_ready=1 핸드셰이크 되면 전송 끝
            if (out_valid_reg && out_ready) begin
                out_valid_reg <= 1'b0;
                // chunk_offset += (chunk_count×32 Byte)
                //   (DATA_WIDTH=256 → 32Byte per beat)
                chunk_offset <= chunk_offset + (chunk_count*32);
                chunk_count  <= 0;
            end

            // W data handshake
            if (s_axi_w.wvalid && wready_r) begin
                // 수신
                chunk_buf[chunk_count] <= s_axi_w.wdata;
                chunk_count            <= chunk_count + 1;

                // 남은 beat 1줄임
                beats_left <= (beats_left - 1);

                // (1) 4 beat 꽉 찼으면 out_valid 올림
                if (chunk_count + 1 == CHUNK_MAX_BEATS) begin
                    out_valid_reg <= 1'b1;
                end

                // (2) leftover 발생조건: wlast=1이거나 beats_left==1
                //     → 이번 beat가 마지막임 => out_valid=1
                //     (단, 이미 (1)에서 CHUNK_MAX_BEATS 꽉 찼으면 거기서 out_valid=1)
                if (s_axi_w.wlast || (beats_left == 1)) begin
                    // leftover는 chunk_count+1 <4일 수도 있고, 또는 chunk_count+1=4
                    // 어쨌든 out_valid=1
                    out_valid_reg <= 1'b1;
                end
            end
        end
    end

    assign s_axi_w.wready = wready_r;

    //--------------------------------------------------------------------------
    // 4) 출력 계산
    //--------------------------------------------------------------------------
    //  - out_addr = awaddr_reg + chunk_offset
    //  - out_length = chunk_count × 8 (DW) [beat당 32B=8DW]
    //--------------------------------------------------------------------------
    always_comb begin
        // BDF 고정
        out_bdf         = DEVICE_BDF;
        // Write만 처리
        out_is_memwrite = 1'b1;

        // Address = Burst 시작 주소 + offset
        out_addr  = awaddr_reg + chunk_offset;

        // length(DW) = chunk_count × 8 (한 beat=32B=8DW)
        out_length = (chunk_count == 0) ? 0 : (chunk_count * 8);

        // chunk_buf[0..3]를 하나로 패킹 (256bit×4=1024bit)
        out_wdata = {
            chunk_buf[3],
            chunk_buf[2],
            chunk_buf[1],
            chunk_buf[0]
        };
    end

    assign out_valid = out_valid_reg;

endmodule
