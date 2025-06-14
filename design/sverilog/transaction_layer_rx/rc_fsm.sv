// File: rc_fsm.sv
// AXI4 Read Data (R) 채널 드라이버
// Read Completion TLP 헤더/페이로드 FIFO에서 꺼내
// AXI4 Master R 채널로 데이터를 전송합니다.

module rc_fsm #(
  parameter int DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH
)(
  input  wire                  clk,
  input  wire                  rst_n,

  // Completion 헤더 FIFO 인터페이스
  input  wire                  rc_hdr_empty,   // 헤더 FIFO empty
  input  wire [127:0]          rc_hdr_data,    // 128b 헤더
  output logic                 rc_hdr_rden,    // 헤더 FIFO read enable

  // Completion 페이로드 FIFO 인터페이스
  input  wire                  rc_pay_empty,   // 페이로드 FIFO empty
  input  wire [DATA_WIDTH-1:0] rc_pay_data,    // 32B 데이터
  input  wire                  rc_pay_last,    // 마지막 beat 표시
  output logic                 rc_pay_rden,    // 페이로드 FIFO read enable

  // AXI4 Master Read Data 채널
  AXI4_R_IF.master             r_if,

  // 진행 중 표시 (IDLE 아닐 때 busy=1)
  output logic                 r_busy
);

  // 상태 정의: IDLE -> HDR -> PAY -> IDLE
  typedef enum logic [1:0] { IDLE, HDR, PAY } state_t;
  state_t state, next_state;

  // 캡처된 헤더 필드
  logic [9:0]   tag_dw;
  logic [9:0]   len_dw;
  logic [2:0]   cpl_status;

  // 상태 전이
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    next_state = state;
    case (state)
      IDLE:
        // 헤더가 있으면 읽으러 가기
        if (!rc_hdr_empty)
          next_state = HDR;
      HDR:
        // 헤더 캡처 후 페이로드 단계로
        if (state==HDR)
          next_state = PAY;
      PAY:
        // 마지막 beat 전송 완료되면 IDLE
        if (r_if.rvalid && r_if.rready && rc_pay_last)
          next_state = IDLE;
    endcase
  end

  // busy 플래그
  assign r_busy = (state != IDLE);

  // 헤더 캡처 및 FIFO read
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rc_hdr_rden <= 1'b0;
      tag_dw      <= '0;
      len_dw      <= '0;
      cpl_status  <= '0;
    end else begin
      rc_hdr_rden <= 1'b0;
      if (state==IDLE && !rc_hdr_empty) begin
        // 헤더 한 싸이클 읽기
        rc_hdr_rden <= 1'b1;
        // 필드 추출
        tag_dw     <= PCIE_PKG::get_tag_from_req_hdr(rc_hdr_data);
        len_dw     <= PCIE_PKG::get_len_dw_from_cpl_hdr(rc_hdr_data);
        cpl_status <= PCIE_PKG::get_cpl_status_from_cpl_hdr(rc_hdr_data);
      end
    end
  end

  // 페이로드 FIFO read control
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rc_pay_rden <= 1'b0;
    end else begin
      rc_pay_rden <= 1'b0;
      if (state==PAY && !rc_pay_empty) begin
        // beat 당 하나씩 꺼내서 전송
        rc_pay_rden <= 1'b1;
      end
    end
  end

  // AXI4 R 채널 드라이브
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_if.rvalid <= 1'b0;
      r_if.rdata  <= '0;
      r_if.rid    <= '0;
      r_if.rresp  <= 2'b00;
      r_if.rlast  <= 1'b0;
    end else begin
      // 기본은 valid 낮추고 last 클리어
      r_if.rvalid <= 1'b0;
      r_if.rlast  <= 1'b0;

      if (state==PAY && rc_pay_rden) begin
        r_if.rvalid <= 1'b1;
        r_if.rdata  <= rc_pay_data;
        r_if.rid    <= tag_dw;
        r_if.rresp  <= cpl_status;
        r_if.rlast  <= rc_pay_last;
      end

      // 전송 완료 시 valid 클리어
      if (r_if.rvalid && r_if.rready) begin
        r_if.rvalid <= 1'b0;
      end
    end
  end

endmodule
