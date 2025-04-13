// -----------------------------------------------------------------------------
// 모듈: axi4_if_decoding
// 작성 목적:
//   AXI4 Write Address/Write Data 채널을 받아, 특정 조건(최대 4beat=128Byte 등)에
//   도달하거나 마지막 beat가 들어왔을 때 out_valid를 올려 한 덩어리(Chunk)로
//   데이터를 내보냄.
//
// 파라미터 설명:
//   ID_WIDTH        : AXI4 ID 식별자 폭 (디자인에 따라 안 쓸 수도 있음)
//   ADDR_WIDTH      : 주소 폭 (32bit 주소 사용 가정)
//   DATA_WIDTH      : 한 번에 들어오는 Write Data 폭(256bit => 32Byte per beat)
//   CHUNK_MAX_BEATS : 한 Chunk 최대 Beat 수(4 => 4×32B=128B)
//
// 포트:
//   clk, rst_n              : 전체 동작 클럭/리셋
//   s_axi_aw (AXI4_A_IF.slave) : Write Address 채널 (avalid, aaddr, alen, etc.)를 인풋
//   s_axi_w  (AXI4_W_IF.slave) : Write Data 채널 (wvalid, wdata, wlast 등)을 인풋
//   out_addr, out_length    : 디코딩 결과(주소, 길이(DW단위))
//   out_bdf, out_is_memwrite: 예시로 BDF ID(고정), 메모리Write 여부(1)
//   out_wdata               : 한 번에 모은 128Byte(최대) 또는 leftover를 담은 데이터
//   out_valid, out_ready    : Chunk가 유효할 때 out_valid=1, 다음 스테이지가 ready=1일 때 핸드셰이크
// -----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
    // 전제 조건
    // Byte Enable은 사용하지 않음 => wstrb 무시
    // Address는 DW 정렬 => aaddr 하위 2비트는 0
    // 32B 단위 burst => Host Req도, Device Req도 32B 단위
    // Burst type = INCR
    // ----------------------------------------------------------------------------


module axi4_if_decoding #(
    parameter ID_WIDTH         = 4,
    parameter ADDR_WIDTH       = 32,   // 주소 길이 (32bit 가정)
    parameter DATA_WIDTH       = 256,  // 32B씩 한 번에 들어옴(256bit)
    parameter CHUNK_MAX_BEATS  = 4     // 4beat => 128Byte
)(
    input  wire clk,
    input  wire rst_n,

    // AXI Write Address / Write Data 채널 (slave modport)
    //  - s_axi_aw: avalid, aaddr, alen, etc. 인풋
    //  - s_axi_w : wvalid, wdata, wlast 등 인풋
    //    todo : 모듈 내부에서 aready, wready를 처리하는데 원래는 내보내줘야함. 어떻게 할까....
    AXI4_A_IF.slave s_axi_aw,
    AXI4_W_IF.slave s_axi_w,

    // 디코딩(수집) 결과 출력 (예: TLP 등으로 패킷화할 때 사용)
    output logic [ADDR_WIDTH-1:0]                  out_addr,      // chunk base address
    output logic [7:0]                             out_length,    // (DW단위) => 1 beat=8DW=32B 즉 한 tlp에 들어갈 wdata의 사이즈
    output logic [15:0]                            out_bdf,       // 예시로 고정한 BDF ID
    output logic                                   out_is_memwrite,// 1이면 Write TLP
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0]  out_wdata,     // 최대 128B buffer
    output logic                                   out_valid,     // chunk 유효
    input  logic                                   out_ready      // 다음 단계에서 받아갈 준비
);

    // -------------------------------------------------------------------------
    // 상수/상태 변수
    // -------------------------------------------------------------------------
    // 예시로 BDF ID=0x0200 (2:0:0)
    localparam logic [15:0] DEVICE_BDF = 16'h0200;

    // (1) Write Address 관련 레지스터들
    //  - 핸드셰이크 된 AW 값을 보관해두어야, 이후 데이터 burst 처리 동안 참조 가능
    logic [ADDR_WIDTH-1:0] awaddr_reg; // 수신한 주소
    logic [7:0]            awlen_reg;  // AXI4에서 alen=(beat수-1)
    logic [ID_WIDTH-1:0]   awid_reg;   // ID(굳이 안 쓰더라도 보관만)
    logic                  awvalid_reg;// "AW valid"를 한번 받은 적 있는지 표시

    // aready를 내부에서 제어하기 위해 사용
    logic                  awready_r;

    // (2) "AW valid을 수신했다" 표시(나중에 aready랑 핸드셰이크크) + 남은 beat 수
    //  - beats_left=(alen+1) => 남은 Write Beat 개수
    logic                  aw_valid_received;
    logic [7:0]            beats_left;  //총 받을 wdata를 저장하고 처리할때마다 -1을 통해 마지막 신호 판별 가능

    // (3) Write data 버퍼링
    logic [ADDR_WIDTH-1:0] chunk_offset;             // offset (128B씩 누적)
    logic [DATA_WIDTH-1:0] chunk_buf [0:CHUNK_MAX_BEATS-1]; // 최대 4 beat 수집용
    logic [2:0]            chunk_count;              // 현재 chunk에 모인 beat 수
    logic                  wready_r;

    // (4) 최종 out_valid 제어 레지스터
    logic                  out_valid_reg;

    // -------------------------------------------------------------------------
    // 1) Address Channel (AW)
    // -------------------------------------------------------------------------
    //  - alen=(beat수-1) => beats_left=(alen+1)
    //  - 한번 valid&ready가 성립하면 aw_valid_received=1 => Write Data를 받을 준비
    //  - burst 끝(beats_left=0)되면 다시 aw_valid_received=0으로 내려가므로
    //    다음 burst를 위해 대기
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_r         <= 1'b0;
            awvalid_reg       <= 1'b0;
            awaddr_reg        <= '0;
            awlen_reg         <= '0;
            awid_reg          <= '0;
            aw_valid_received <= 1'b0;
            beats_left        <= '0;
        end
        else begin
            // 간단하게 always ready=1 로 가정 (버퍼 여유 있다고 보고) todo 나중에 이 신호 어떻게 받아서 처리할 지 생각해야함!!
            awready_r <= 1'b1;

            // Address 핸드셰이크 (avalid & aready)
            if (s_axi_aw.avalid && s_axi_aw.aready) begin
                awvalid_reg       <= 1'b1;    // 내부에서 "AW valid됨" 표시
                awaddr_reg        <= s_axi_aw.aaddr; // 받은 주소 보관
                awlen_reg         <= s_axi_aw.alen;  // alen=(beat수-1)
                awid_reg          <= s_axi_aw.aid;
                aw_valid_received <= 1'b1;           // Write data 수신 가능
                beats_left        <= s_axi_aw.alen + 1; // total beat 수
            end

            // beats_left==0 -> 이번 burst 끝났음 -> 더이상 w 수신 안 함
            if (beats_left == 0) begin
                aw_valid_received <= 1'b0;
            end
        end
    end

    // Address 채널에 대한 ready
    assign s_axi_aw.aready = awready_r;

    // -------------------------------------------------------------------------
    // 2) Write Data Channel (W) + chunk 관리
    // -------------------------------------------------------------------------
    //  - aw_valid_received=1 일 때만 wready=1
    //  - 매 beat마다 chunk_buf에 저장 -> chunk_count++
    //  - 4 beat 꽉 차면 => out_valid=1
    //  - leftover(마지막 beat)도 => out_valid=1
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_r      <= 1'b0;
            out_valid_reg <= 1'b0;
            chunk_count   <= 0;
            chunk_offset  <= 0;
        end
        else begin
            // wready=1 iff 주소를 이미 받은 상태 todo 이것도 역시 나중에 버퍼에 의해 결정되어야할 것 같은데,,
            wready_r <= aw_valid_received; //우선 주소를 받은 다음에 보내줘야함!!!!

            // out_valid & out_ready 핸드셰이크 -> 이 chunk 송출 완료 전자는 우리가 보내주는 것 후자는 우리가 받는것()
            if (out_valid_reg && out_ready) begin
                out_valid_reg <= 1'b0;
                // chunk_offset += (현재 chunk_count × 32Byte)
                // DATA_WIDTH=256 => 1beat=32byte
                chunk_offset <= chunk_offset + (chunk_count * 32);  //주소 증가시켜주는부분분
                // 다음 chunk 준비
                chunk_count  <= 0;
            end

            // Write Data handshake
            if (s_axi_w.wvalid && wready_r) begin
                // 버퍼에 저장
                chunk_buf[chunk_count] <= s_axi_w.wdata;
                chunk_count            <= chunk_count + 1;

                // 남은 beat 수 하나 감소
                beats_left <= beats_left - 1;

                // (1) 4 beat(=CHUNK_MAX_BEATS) 꽉 차면 -> out_valid=1
                if (chunk_count + 1 == CHUNK_MAX_BEATS) begin
                    out_valid_reg <= 1'b1;
                end

                // (2) leftover(마지막 beat):
                //     wlast=1이거나 beats_left==1이면 -> out_valid=1
                //     => chunk_count가 4 미만이어도 partial chunk 보냄
                if (s_axi_w.wlast || (beats_left == 1)) begin
                    out_valid_reg <= 1'b1;
                end
            end
        end
    end

    // Write Data 채널에 대한 ready
    assign s_axi_w.wready = wready_r;

    // -------------------------------------------------------------------------
    // 3) 출력 계산 (out_addr, out_length, out_wdata)
    // -------------------------------------------------------------------------
    //  - out_bdf, out_is_memwrite는 고정
    //  - out_addr = base addr + chunk_offset
    //  - out_length(DW) = chunk_count × 8
    //  - out_wdata = chunk_buf 4개 합쳐 1024bit
    // -------------------------------------------------------------------------
    always_comb begin
        // 예시로 BDF=0x0200, Write만
        out_bdf         = DEVICE_BDF;
        out_is_memwrite = 1'b1;

        // base addr + offset
        out_addr        = awaddr_reg + chunk_offset; //버스트모드 인크리즈라 주소를 증가시켜야함함

        // chunk_count beat -> DW 단위 => chunk_count×8DW
        if (chunk_count == 0) begin
            out_length = 0;
        end
        else begin
            out_length = chunk_count * 8;
        end

        // 버퍼에 저장된 데이터를 하나의 대형 bus(256bit×4=1024bit)로 매핑
        out_wdata = {
            chunk_buf[3],
            chunk_buf[2],
            chunk_buf[1],
            chunk_buf[0]
        };
    end

    // out_valid는 레지스터
    assign out_valid = out_valid_reg;

endmodule