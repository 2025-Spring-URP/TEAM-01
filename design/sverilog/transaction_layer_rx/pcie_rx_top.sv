// File: pcie_rx_top.sv
// 역할: TLP 스트림 받아서 demux → FIFO → AXI4-master FSM →
//       Read-Completion 헤더/페이로드 FIFO로 넘김

module pcie_rx_top #(
  parameter int DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH
)(
  input  wire                   clk,
  input  wire                   rst_n,

  // Link Layer → RX
  input  wire                   tlp_in_valid,
  input  wire [DATA_WIDTH-1:0]  tlp_in_data,
  input  wire                   tlp_in_last,

  // AXI4 Master (디바이스 코어)
  AXI4_A_IF.master              aw_if,
  AXI4_W_IF.master              w_if,
  AXI4_A_IF.master              ar_if,
  AXI4_R_IF.master              r_if,
  AXI4_B_IF.master              b_if,

  // RX → TX Read-Completion FIFO 인터페이스
  output wire                   cpl_hdr_wren,
  output wire [127:0]           cpl_hdr_data,
  output wire                   cpl_pay_wren,
  output wire [DATA_WIDTH-1:0]  cpl_pay_data,
  output wire                   cpl_pay_last
);

  //========================================================
  // 1) TLP 분기 : tlp_demux
  //========================================================
  logic                   ar_w, aw_w, wr_w, rc_h, rc_p;
  logic [127:0]           ar_d, aw_d, rc_hd;
  logic [DATA_WIDTH-1:0]  wr_d, rc_pd;
  logic                   wr_l, rc_pl;

  tlp_demux #(.DATA_WIDTH(DATA_WIDTH)) demux_u (
    .clk          (clk),        .rst_n       (rst_n),
    .tlp_in_valid (tlp_in_valid), .tlp_in_data(tlp_in_data),
    .tlp_in_last  (tlp_in_last),
    .ar_hdr_wren  (ar_w),       .ar_hdr_data (ar_d),
    .aw_hdr_wren  (aw_w),       .aw_hdr_data (aw_d),
    .wr_pay_wren  (wr_w),       .wr_pay_data (wr_d),
    .wr_pay_last  (wr_l),
    .rc_hdr_wren  (rc_h),       .rc_hdr_data (rc_hd),
    .rc_pay_wren  (rc_p),       .rc_pay_data (rc_pd),
    .rc_pay_last  (rc_pl)
  );

  //========================================================
  // 2) 각 경로별 FIFO
  //    - AR 헤더, AW 헤더, W 페이로드
  //    - Read-Completion 헤더/페이로드
  //========================================================
  logic ar_empty, aw_empty, w_empty;
  logic rc_hdr_empty, rc_pay_empty;

  // AR Header FIFO
  SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(128)) ar_fifo (
    .clk    (clk), .rst_n  (rst_n),
    .afull_o(),        // optional back-pressure
    .wren_i (ar_w),
    .wdata_i(ar_d),
    .empty_o(ar_empty),
    .rden_i (ar_fsm_inst.ar_busy ? 1'b0 : ar_fifo_rden),
    .rdata_o(ar_fifo_data)
  );

  // AW Header FIFO
  SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(128)) aw_fifo (
    .clk    (clk), .rst_n  (rst_n),
    .afull_o(),
    .wren_i (aw_w),
    .wdata_i(aw_d),
    .empty_o(aw_empty),
    .rden_i (aw_fsm_inst.aw_busy ? 1'b0 : aw_fifo_rden),
    .rdata_o(aw_fifo_data)
  );

  // Write Payload FIFO
  SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(DATA_WIDTH)) w_fifo (
    .clk    (clk), .rst_n  (rst_n),
    .afull_o(),
    .wren_i (wr_w),
    .wdata_i(wr_d),
    .empty_o(w_empty),
    .rden_i (w_fsm_inst.w_busy ? 1'b0 : w_fifo_rden),
    .rdata_o(w_fifo_data)
  );

  // Read-Completion Header FIFO (TX로 넘김)
  SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(128)) rc_hdr_fifo (
    .clk    (clk), .rst_n  (rst_n),
    .afull_o(),
    .wren_i (rc_h),
    .wdata_i(rc_hd),
    .empty_o(rc_hdr_empty),
    .rden_i (cpl_hdr_rden),
    .rdata_o(cpl_hdr_data)
  );

  // Read-Completion Payload FIFO (TX로 넘김)
  SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(DATA_WIDTH)) rc_pay_fifo (
    .clk    (clk), .rst_n  (rst_n),
    .afull_o(),
    .wren_i (rc_p),
    .wdata_i(rc_pd),
    .empty_o(rc_pay_empty),
    .rden_i (cpl_pay_rden),
    .rdata_o(cpl_pay_data)
  );

  assign cpl_hdr_wren = rc_hdr_fifo.rden_i;
  assign cpl_pay_wren = rc_pay_fifo.rden_i;
  assign cpl_pay_last = rc_pl;  // tlp_demux에서 넘겨준 last

  //========================================================
  // 3) FSM 인스턴스 연결
  //========================================================

  // AR FSM
  ar_fsm ar_fsm_inst (
    .clk          (clk),        .rst_n      (rst_n),
    .ar_hdr_wren  (ar_w),       .ar_hdr_data(ar_d),
    .ar_if        (ar_if),
    .ar_busy      (/* 보고 싶으면 wire 연결 */)
  );

  // AW FSM
  aw_fsm aw_fsm_inst (
    .clk          (clk),        .rst_n      (rst_n),
    .aw_hdr_wren  (aw_w),       .aw_hdr_data(aw_d),
    .aw_if        (aw_if),
    .aw_busy      (/* 필요 시 */)
  );

  // Write Data FSM
  w_fsm #(.DATA_WIDTH(DATA_WIDTH)) w_fsm_inst (
    .clk          (clk),       .rst_n      (rst_n),
    .w_fifo_empty (w_empty),   .w_fifo_data(w_fifo_data),
    .w_fifo_last  (wr_l),      .w_fifo_rden(w_fifo_rden),
    .w_if         (w_if),
    .w_busy       (/*optional*/)
  );

  // Read Data FSM
  rc_fsm #(.DATA_WIDTH(DATA_WIDTH)) rc_fsm_inst (
    .clk           (clk),       .rst_n       (rst_n),
    .rc_hdr_empty  (rc_hdr_empty), .rc_hdr_data(rc_hdr_data),
    .rc_hdr_rden   (cpl_hdr_rden),
    .rc_pay_empty  (rc_pay_empty), .rc_pay_data(rc_pay_data),
    .rc_pay_last   (rc_pay_last),  .rc_pay_rden(cpl_pay_rden),
    .r_if          (r_if),
    .r_busy        (/*optional*/)
  );

  // b_if는 지금 무시(혹은 bready=1 계속)
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) b_if.bready <= 1'b0;
    else        b_if.bready <= 1'b1;

endmodule
