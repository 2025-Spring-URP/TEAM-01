`timescale 1ns/1ps
module tb_pcie_rx_top;
  //-------------------------------------------------------------------------
  // 파라미터 및 신호 선언
  //-------------------------------------------------------------------------
  parameter int ADDR_WIDTH = 64;
  parameter int DATA_WIDTH = 256;

  // 클럭/리셋
  logic clk, rst_n;

  // Link Layer → RX TLP 입력
  logic                   tlp_in_valid;
  logic [DATA_WIDTH-1:0]  tlp_in_data;
  logic                   tlp_in_last;

  // AXI4 Master 인터페이스(디바이스 코어)
  AXI4_A_IF  #(.ADDR_WIDTH(ADDR_WIDTH)) aw_if();
  AXI4_W_IF  #(.DATA_WIDTH(DATA_WIDTH)) w_if();
  AXI4_A_IF  #(.ADDR_WIDTH(ADDR_WIDTH)) ar_if();
  AXI4_R_IF  #(.DATA_WIDTH(DATA_WIDTH)) r_if();
  AXI4_B_IF                                 b_if();

  // Read-Completion FIFO 출력 모니터링
  logic                   cpl_hdr_wren;
  logic [127:0]           cpl_hdr_data;
  logic                   cpl_pay_wren;
  logic [DATA_WIDTH-1:0]  cpl_pay_data;
  logic                   cpl_pay_last;

  // DUT 인스턴스
  pcie_rx_top #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .tlp_in_valid  (tlp_in_valid),
    .tlp_in_data   (tlp_in_data),
    .tlp_in_last   (tlp_in_last),
    .aw_if         (aw_if.master),
    .w_if          (w_if.master),
    .ar_if         (ar_if.master),
    .r_if          (r_if.master),
    .b_if          (b_if.master),
    .cpl_hdr_wren  (cpl_hdr_wren),
    .cpl_hdr_data  (cpl_hdr_data),
    .cpl_pay_wren  (cpl_pay_wren),
    .cpl_pay_data  (cpl_pay_data),
    .cpl_pay_last  (cpl_pay_last)
  );

  // slave(디바이스 코어) 쪽 always ready
  assign aw_if.aready = 1;
  assign w_if.wready  = 1;
  assign ar_if.aready = 1;
  // B-Channel은 무시
  assign b_if.bvalid  = 0;

  //-------------------------------------------------------------------------
  // 클럭 생성
  //-------------------------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  //-------------------------------------------------------------------------
  // 테스트 시나리오
  //-------------------------------------------------------------------------
  import PCIE_PKG::*;

  initial begin
    // 초기화
    rst_n         = 0;
    tlp_in_valid  = 0;
    tlp_in_data   = '0;
    tlp_in_last   = 0;
    r_if.rvalid   = 0;
    #20 rst_n = 1;

    // --- 1) 간단한 Write Request (32B 페이로드) ---
    // TLP 헤더 생성: 주소=0x1000_0000, 길이=32 bytes
    logic [127:0] w_hdr = create_w_header(64'h1000_0000, 32);
    // 헤더 beat
    tlp_in_valid = 1;
    tlp_in_data  = { w_hdr, 128'h0 };
    tlp_in_last  = 1;  // 32B payload이지만 단일 beat로 처리
    #10 tlp_in_valid = 0;

    // 손잡이(wait) – Write Address 전송 완료
    wait(aw_if.avalid && aw_if.aready);
    #10;

    // Write Data 전송 완료
    wait(w_if.wvalid && w_if.wready);
    #10;

    // --- 2) 간단한 Read Request (no payload) ---
    logic [127:0] r_hdr = create_r_header(64'h2000_0000, 16);
    tlp_in_valid = 1;
    tlp_in_data  = { r_hdr, 128'h0 };
    tlp_in_last  = 1;
    #10 tlp_in_valid = 0;

    // Read Address 전송 대기
    wait(ar_if.avalid && ar_if.aready);
    #10;

    // --- 3) Read Completion (device core 응답) ---
    // 응답 데이터 beat
    r_if.rvalid = 1;
    r_if.rdata  = 256'hDEAD_BEEF_DEAD_BEEF_DEAD_BEEF_DEAD_BEEF;
    r_if.rlast  = 1;
    #10 r_if.rvalid = 0;

    // Completion FIFO에 기록된 값 출력
    $display("CPL HDR = %h", cpl_hdr_data);
    $display("CPL PAY = %h (last=%0b)", cpl_pay_data, cpl_pay_last);

    // --- 4) Burst Write (64B 페이로드, 2 beats) ---
    logic [127:0] wb_hdr = create_w_header(64'h3000_0000, 64);
    // beat0: header
    tlp_in_valid = 1; tlp_in_data = { wb_hdr, 128'h0 }; tlp_in_last = 0; #10;
    // beat1: payload0
    tlp_in_valid = 1; tlp_in_data = 256'h1111;             tlp_in_last = 0; #10;
    // beat2: payload1 (last)
    tlp_in_valid = 1; tlp_in_data = 256'h2222;             tlp_in_last = 1; #10;
    tlp_in_valid = 0;

    // AW handshake + W beats
    repeat(3) @(posedge clk);

    // --- 5) Burst Read (48 bytes, 2 beats) ---
    logic [127:0] rb_hdr = create_r_header(64'h4000_0000, 48);
    tlp_in_valid = 1; tlp_in_data = { rb_hdr, 128'h0 }; tlp_in_last = 0; #10;
    tlp_in_valid = 1; tlp_in_data = 256'hAAAA;           tlp_in_last = 1; #10;
    tlp_in_valid = 0;
    wait(ar_if.avalid && ar_if.aready);
    #10;

    // 디바이스 코어 → read data burst 응답 (2 beats)
    r_if.rvalid = 1; r_if.rdata = 256'hCAFEBABE; r_if.rlast = 0; #10;
    r_if.rvalid = 1; r_if.rdata = 256'hFEEDFACE; r_if.rlast = 1; #10;
    r_if.rvalid = 0;

    // FIFO 내용 표시
    $display("CPL HDR = %h", cpl_hdr_data);
    $display("CPL PAY = %h (last=%0b)", cpl_pay_data, cpl_pay_last);

    #100 $finish;
  end

  // 모니터링하기 쉽게 모든 주요 신호를 화면에
  always_ff @(posedge clk) begin
    if (aw_if.avalid && aw_if.aready)
      $display($time, " AW addr=%h len=%0d id=%0d", aw_if.aaddr, aw_if.alen+1, aw_if.aid);
    if (w_if.wvalid && w_if.wready)
      $display($time, " W data=%h last=%b", w_if.wdata, w_if.wlast);
    if (ar_if.avalid && ar_if.aready)
      $display($time, " AR addr=%h len=%0d id=%0d", ar_if.aaddr, ar_if.alen+1, ar_if.aid);
    if (r_if.rvalid && r_if.rready)
      $display($time, " R data=%h last=%b", r_if.rdata, r_if.rlast);
  end

endmodule
