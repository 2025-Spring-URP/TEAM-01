// File: w_fsm.sv
// AXI4 Write Data (W) 채널 드라이버
// tlp_demux(또는 WR_PAY_FIFO)에서 분기된 Write 페이로드를 받아
// AXI4 Master W 채널로 전송합니다.

module w_fsm #(
  parameter int DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH  // 일반적으로 256
)(
  input  wire                  clk,
  input  wire                  rst_n,

  // Write Payload FIFO 인터페이스
  input  wire                  w_fifo_empty,   // FIFO empty 표시
  input  wire [DATA_WIDTH-1:0] w_fifo_data,    // 32B 데이터
  input  wire                  w_fifo_last,    // 이 beat가 마지막인지
  output logic                 w_fifo_rden,    // FIFO에서 꺼낼 때 1

  // AXI4 Master Write Data 채널
  AXI4_W_IF.master             w_if,

  // 진행 중 표시 (IDLE이 아닐 때 busy=1)
  output logic                 w_busy
);

  // 상태 정의: IDLE → SEND → IDLE
  typedef enum logic [1:0] { IDLE, SEND } state_t;
  state_t state, next_state;

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
        // FIFO에 데이터가 있으면 전송 모드로
        if (!w_fifo_empty)
          next_state = SEND;
      SEND:
        // 마지막 beat이면서 전송(handshake) 완료되면 IDLE로
        if (w_if.wvalid && w_if.wready && w_fifo_last)
          next_state = IDLE;
    endcase
  end

  // busy 플래그: SEND 중이면 1
  assign w_busy = (state != IDLE);

  // W 채널 제어 및 FIFO read enable
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_fifo_rden <= 1'b0;
      w_if.wvalid <= 1'b0;
      w_if.wdata  <= '0;
      w_if.wstrb  <= {DATA_WIDTH/8{1'b1}}; // 모든 바이트 유효
      w_if.wlast  <= 1'b0;
    end else begin
      // 기본값: valid/last/rden 모두 낮춤
      w_fifo_rden <= 1'b0;
      w_if.wvalid <= 1'b0;
      w_if.wlast  <= 1'b0;

      if (state == SEND) begin
        if (!w_fifo_empty) begin
          w_fifo_rden <= 1'b1;           // FIFO에서 데이터 꺼내기
          w_if.wvalid <= 1'b1;           // 데이터 유효 표시
          w_if.wdata  <= w_fifo_data;    // 32바이트 페이로드
          // 필요시 wstrb 조정 가능
          w_if.wlast  <= w_fifo_last;    // 마지막 beat 표시
        end

        // 전송 완료(handshake) 시 valid 내려줌
        if (w_if.wvalid && w_if.wready)
          w_if.wvalid <= 1'b0;
      end
    end
  end

endmodule
