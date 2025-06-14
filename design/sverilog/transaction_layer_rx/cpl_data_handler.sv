// File: cpl_data_handler.sv
// 역할: AXI4-R 채널에서 Read Completion 페이로드를 받아
//       TX로 넘길 cpl_pay_fifo에 32B 단위로 기록합니다.

module cpl_data_handler #(
  parameter int DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH
)(
  input  wire                  clk,
  input  wire                  rst_n,

  // AXI4-R 마스터 인터페이스
  AXI4_R_IF.master             r_if,

  // 중간 FIFO가 있으면 여기 empty/rden 연결 가능
  input  wire                  r_fifo_empty,   // (optional)
  input  wire [DATA_WIDTH-1:0] r_fifo_data,    // (optional)
  input  wire                  r_fifo_last,    // (optional)
  output logic                 r_fifo_rden,    // (optional)

  // TX로 넘길 Read-Completion 페이로드
  output logic                 cpl_pay_wren,
  output logic [DATA_WIDTH-1:0] cpl_pay_data,
  output logic                 cpl_pay_last
);

  // 상태 머신: IDLE -> SEND -> IDLE
  typedef enum logic [1:0] { IDLE, SEND } state_t;
  state_t state, next_state;

  // 상태 전이
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else        state <= next_state;
  end

  always_comb begin
    next_state = state;
    case(state)
      IDLE:
        // r_if.rvalid이 1이 되면 SEND로
        if (r_if.rvalid)
          next_state = SEND;
      SEND:
        // 마지막 beat 전달 완료 시 IDLE 복귀
        if (r_if.rvalid && r_if.rready && r_if.rlast)
          next_state = IDLE;
    endcase
  end

  // busy 표시
  assign r_busy = (state != IDLE);

  // FIFO 대신 직접 r_if로부터 읽어 쓰기
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cpl_pay_wren  <= 1'b0;
      cpl_pay_data  <= '0;
      cpl_pay_last  <= 1'b0;
      r_if.rready   <= 1'b0;
    end else begin
      // 기본값
      cpl_pay_wren <= 1'b0;
      cpl_pay_last <= 1'b0;
      r_if.rready  <= 1'b0;

      case (state)
        IDLE: begin
          // 언제든지 준비되면 rready 활성
          r_if.rready <= 1'b1;
        end
        SEND: begin
          if (r_if.rvalid && r_if.rready) begin
            // 유효 데이터 있을 때만
            cpl_pay_wren <= 1'b1;
            cpl_pay_data <= r_if.rdata;
            cpl_pay_last <= r_if.rlast;
            // 다음 beat도 받으려면 계속 rready 유지
            r_if.rready <= 1'b1;
          end
        end
      endcase
    end
  end

endmodule
