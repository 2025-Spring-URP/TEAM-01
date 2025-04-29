`timescale 1ns/1ps


//R이나 B는 아직 여기에 구현된 게 아님. 나중에 RX단 처리할 때 구현할 생각임.

module axi4_if_decoding #(
  parameter ID_WIDTH        = 4,
  parameter ADDR_WIDTH      = 32,
  parameter DATA_WIDTH      = 256,
  parameter CHUNK_MAX_BEATS = 4
)(
  input  wire                        clk,
  input  wire                        rst_n,

  // Write 어드레스/데이터 슬레이브 포트
  AXI4_A_IF.slave                    s_axi_aw,
  AXI4_W_IF.slave                    s_axi_w,

  // Read 어드레스 슬레이브 포트
  AXI4_A_IF.slave                    s_axi_ar,

  // Write용 TLP로 보낼 포트
  output logic [ADDR_WIDTH-1:0]                out_w_addr,
  output logic [7:0]                           out_w_length,
  output logic [15:0]                          out_w_bdf,
  output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] out_w_data,
  output logic                                 out_w_valid,
  input  logic                                 out_w_ready,

  // Read용 TLP로 보낼 포트
  output logic [ADDR_WIDTH-1:0]                out_r_addr,
  output logic [7:0]                           out_r_length,
  output logic                                 out_r_valid,
  input  logic                                 out_r_ready
);

  // 고정으로 박아놓는 BDF
  localparam logic [15:0] DEVICE_BDF = 16'h0200;

  // Write 쪽에 필요한 레지스터들
  logic [ADDR_WIDTH-1:0] awaddr_reg;
  logic [7:0]            awlen_reg;
  logic                  aw_received;
  logic [DATA_WIDTH-1:0] chunk_buf [0:CHUNK_MAX_BEATS-1];
  logic [2:0]            chunk_count;
  logic [ADDR_WIDTH-1:0] chunk_offset;
  logic                  awready_r, wready_r;
  logic                  out_w_valid_reg;
  logic [7:0]            beats_left;

  // Read 쪽에 필요한 레지스터들
  logic [ADDR_WIDTH-1:0] araddr_reg;
  logic [7:0]            arlen_reg;
  logic                  ar_received;
  logic                  arready_r;

  //-------------------------------------------------------------------------
  // Write랑 Read 처리하는 메인 always 블록
  //-------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 리셋 걸리면 전부 초기화
      awaddr_reg     <= '0;
      awlen_reg      <= '0;
      aw_received    <= 1'b0;
      beats_left     <= '0;
      chunk_count    <= '0;
      chunk_offset   <= '0;
      out_w_valid_reg<= 1'b0;
      awready_r      <= 1'b0;
      wready_r       <= 1'b0;
      for (int i = 0; i < CHUNK_MAX_BEATS; i++) begin
        chunk_buf[i] <= '0;
      end
      araddr_reg   <= '0;
      arlen_reg    <= '0;
      ar_received  <= 1'b0;
      arready_r    <= 1'b0;
    end else begin
      // ------------ Write 채널 처리 -------------
      awready_r <= !aw_received;   // 아직 AW 안받았으면 ready
      wready_r  <= aw_received;    // AW 받고 나면 W 데이터 받기

      // AW 핸드셰이크 (주소 받고)
      if (s_axi_aw.avalid && awready_r) begin
        awaddr_reg     <= s_axi_aw.aaddr;
        awlen_reg      <= s_axi_aw.alen;
        aw_received    <= 1'b1;
        beats_left     <= s_axi_aw.alen + 1;
      end

      // W 데이터 모으기
      if (s_axi_w.wvalid && wready_r) begin
        chunk_buf[chunk_count] <= s_axi_w.wdata;
        chunk_count            <= chunk_count + 1;
        beats_left             <= beats_left - 1;
        // 버퍼가 다 찼거나, 마지막 데이터거나, 남은게 하나뿐이면 내보낼 준비
        if ((chunk_count + 1 == CHUNK_MAX_BEATS) || s_axi_w.wlast || (beats_left == 1)) begin
          out_w_valid_reg <= 1'b1;
        end
      end

      // 출력 handshake
      if (out_w_valid_reg && out_w_ready) begin
        out_w_valid_reg <= 1'b0;
        chunk_offset    <= chunk_offset + (chunk_count * (DATA_WIDTH/8));
        chunk_count     <= '0;
      end

      // 다 보내고 나면 AW 다시 받을 수 있게
      if (beats_left == 0)
        aw_received <= 1'b0;

      // ------------ Read 채널 처리 ------------
      arready_r <= !ar_received;   // 아직 AR 안받았으면 ready

      // AR 핸드셰이크 (읽을 주소 받고)
      if (s_axi_ar.avalid && arready_r) begin
        araddr_reg  <= s_axi_ar.aaddr;
        arlen_reg   <= s_axi_ar.alen;
        ar_received <= 1'b1;
      end

      // 읽기 요청 내보냈으면 다시 초기화
      if (ar_received && out_r_ready) begin
        ar_received <= 1'b0;
      end
    end
  end

  //-------------------------------------------------------------------------
  // 외부로 내보내는 출력들
  //-------------------------------------------------------------------------
  // AXI ready 신호
  assign s_axi_aw.aready = awready_r;
  assign s_axi_w.wready  = wready_r;
  assign s_axi_ar.aready = arready_r;

  // Write쪽 출력
  assign out_w_addr   = awaddr_reg + chunk_offset;
  assign out_w_length = chunk_count;
  assign out_w_bdf    = DEVICE_BDF;
  assign out_w_data   = {chunk_buf[3], chunk_buf[2], chunk_buf[1], chunk_buf[0]}; // 큰 데이터부터 붙임
  assign out_w_valid  = out_w_valid_reg;

  // Read쪽 출력
  assign out_r_addr   = araddr_reg;
  assign out_r_length = arlen_reg + 1;    // burst 길이 = len + 1
  assign out_r_valid  = ar_received;

endmodule
