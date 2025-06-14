// File: aw_fsm.sv
// 역할: tlp_demux에서 분기된 PCIe Write Request 헤더를 받아
//       AXI4 Master AW 채널에 Write Address 요청을 보냅니다.

module aw_fsm #(
  parameter int ADDR_WIDTH = PCIE_PKG::ADDR_WIDTH
)(
  input  wire                 clk,
  input  wire                 rst_n,

  // tlp_demux → AW 헤더
  input  wire                 aw_hdr_wren,   // 새로운 AW 헤더 유효
  input  wire [127:0]         aw_hdr_data,   // 128비트 TLP 헤더

  // AXI4 Master Write Address
  AXI4_A_IF.master            aw_if,

  // 진행 중 표시 (다음 요청 억제용)
  output logic                aw_busy
);

  // 상태 머신: IDLE ↔ SEND
  typedef enum logic [1:0] { IDLE, SEND } state_t;
  state_t state, next_state;

  // 캡처된 필드 저장
  logic [63:0] req_addr;
  logic [9:0]  req_len_dw;
  logic [9:0]  req_tag;

  // 상태 전이
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    next_state = state;
    case(state)
      IDLE:
        if (aw_hdr_wren)
          next_state = SEND;
      SEND:
        // AW handshake 끝나면 IDLE
        if (aw_if.avalid && aw_if.aready)
          next_state = IDLE;
    endcase
  end

  // busy 플래그: IDLE 아닐 때 busy
  assign aw_busy = (state != IDLE);

  // 헤더에서 주소/길이/태그 추출
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_addr   <= '0;
      req_len_dw <= '0;
      req_tag    <= '0;
    end
    else if (state==IDLE && aw_hdr_wren) begin
      req_addr   <= PCIE_PKG::get_addr_from_req_hdr(aw_hdr_data);
      req_len_dw <= PCIE_PKG::get_len_dw_from_req_hdr(aw_hdr_data);
      req_tag    <= PCIE_PKG::get_tag_from_req_hdr(aw_hdr_data);
    end
  end

  // AXI4 AW 채널 드라이브
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_if.avalid <= 1'b0;
      // aw_if.aready 등은 인터페이스 리셋 함수 사용
    end
    else begin
      // 기본은 내려놓기
      aw_if.avalid <= 1'b0;

      if (state == SEND) begin
        aw_if.avalid <= 1'b1;
        aw_if.aaddr  <= req_addr;
        aw_if.alen   <= req_len_dw - 1;  // burst length = DW count - 1
        aw_if.aid    <= req_tag;
        // 필요시 burst/type/size 설정 추가

        // handshake 완료 시 valid 내리기
        if (aw_if.avalid && aw_if.aready)
          aw_if.avalid <= 1'b0;
      end
    end
  end

endmodule
