// File: ar_fsm.sv
// AXI4 Read Address (AR) 채널을 구동하는 FSM
// tlp_demux에서 분기된 AR 헤더를 받아서
// AXI4 Master AR 채널에 요청을 보냅니다.

module ar_fsm #(
  parameter int ADDR_WIDTH = PCIE_PKG::ADDR_WIDTH
)(
  input  wire                 clk,
  input  wire                 rst_n,

  // tlp_demux → AR 헤더
  input  wire                 ar_hdr_wren,   // 헤더 유효 신호
  input  wire [127:0]         ar_hdr_data,   // 128b TLP 헤더

  // AXI4 Master Read Address
  AXI4_A_IF.master            ar_if,

  // AR 요청 진행 중 표시 (다음 AR을 억제할 때 사용)
  output logic                ar_busy
);

  // 상태 정의: IDLE → SEND → IDLE
  typedef enum logic [1:0] { IDLE, SEND } state_t;
  state_t state, next_state;

  // 헤더 캡처 레지스터
  logic [63:0] req_addr;
  logic [9:0]  req_len_dw;
  logic [9:0]  req_tag;

  // 상태 전이 로직
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // 다음 상태 결정
  always_comb begin
    next_state = state;
    case (state)
      IDLE: begin
        // tlp_demux가 새로운 AR 헤더를 줬으면 SEND 단계로
        if (ar_hdr_wren) 
          next_state = SEND;
      end

      SEND: begin
        // AR handshake 끝나면 다시 IDLE
        if (ar_if.avalid && ar_if.aready) 
          next_state = IDLE;
      end
    endcase
  end

  // AR 요청 busy 플래그 (IDLE 아닐 때 busy)
  assign ar_busy = (state != IDLE);

  // 헤더를 잡아서 AR 필드로 변환
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_addr    <= '0;
      req_len_dw  <= '0;
      req_tag     <= '0;
    end
    else if (state == IDLE && ar_hdr_wren) begin
      // 패키지의 helper로 필드 추출
      req_addr   <= PCIE_PKG::get_addr_from_req_hdr(ar_hdr_data);
      req_len_dw <= PCIE_PKG::get_len_dw_from_req_hdr(ar_hdr_data);
      req_tag    <= PCIE_PKG::get_tag_from_req_hdr(ar_hdr_data);
    end
  end

  // AXI4 AR 신호 드라이브
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_if.avalid <= 1'b0;
      // 그 외 신호는 외부에서 reset_master() 호출로 초기화
    end
    else begin
      // 기본은 valid 낮춤
      ar_if.avalid <= 1'b0;

      if (state == SEND) begin
        // AR 주소 채널에 요청 뿌리기
        ar_if.avalid <= 1'b1;
        ar_if.aaddr  <= req_addr;
        ar_if.alen   <= req_len_dw - 1;  // AXI4는 len-1 인코딩
        ar_if.aid    <= req_tag;
        // 필요시 aburst/asize 등 다른 필드도 설정 가능

        // HANDSHAKE 완료 시 valid 내림
        if (ar_if.avalid && ar_if.aready) begin
          ar_if.avalid <= 1'b0;
        end
      end
    end
  end

endmodule
