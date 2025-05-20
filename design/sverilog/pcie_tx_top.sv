`timescale 1ns/1ps

import PCIE_PKG::*;

module pcie_tx_top (
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4 Slave 인터페이스 (상위 모듈이 Master 역할)
    AXI4_A_IF.slave              aw_if,
    AXI4_A_IF.slave              ar_if,
    AXI4_W_IF.slave              w_if
);
    // aw 채널에 대한 신호호
    wire        aw_fifo_full, aw_fifo_afull;
    wire        aw_fifo_empty, aw_fifo_aempty;
    wire [127:0] aw_hdr_data;
    wire        aw_hdr_wren;

    aw_header_maker #(
        .ADDR_WIDTH(PCIE_PKG::ADDR_WIDTH)
    ) u_aw_hdr (
        .clk             (clk),
        .rst_n           (rst_n),
        .aw_if           (aw_if),
        .aw_fifo_afull   (aw_fifo_afull),   //out
        .aw_fifo_wren    (aw_hdr_wren),     //out
        .aw_fifo_data    (aw_hdr_data)      //out
    );

    SAL_FIFO #(
        .DATA_WIDTH      (128),
        .AFULL_THRES     (8)
    ) u_aw_fifo (
        .clk             (clk),
        .rst_n           (rst_n),
        .wren_i          (aw_hdr_wren),
        .wdata_i         (aw_hdr_data),
        .afull_o         (aw_fifo_afull),
        .full_o          (aw_fifo_full),
        .rden_i          (1'b0),            // 나중에 tlp_assembler에서 읽을 예정
        .rdata_o         (),
        .empty_o         (aw_fifo_empty),
        .aempty_o        (aw_fifo_aempty),
        .debug_o         ()
    );

    //ar에 대한 신호호
    wire        ar_fifo_full, ar_fifo_afull;
    wire        ar_fifo_empty, ar_fifo_aempty;
    wire [127:0] ar_hdr_data;
    wire        ar_hdr_wren;

    ar_header_maker #(
        .ADDR_WIDTH(PCIE_PKG::ADDR_WIDTH)
    ) u_ar_hdr (
        .clk             (clk),
        .rst_n           (rst_n),
        .ar_if           (ar_if),           
        .ar_fifo_afull   (ar_fifo_afull),   //in
        .ar_fifo_wren    (ar_hdr_wren),     //out
        .ar_fifo_data    (ar_hdr_data)      //out
    );

    SAL_FIFO #(
        .DATA_WIDTH      (128),
        .AFULL_THRES     (8)
    ) u_ar_fifo (
        .clk             (clk),
        .rst_n           (rst_n),
        .wren_i          (ar_hdr_wren),
        .wdata_i         (ar_hdr_data),
        .afull_o         (ar_fifo_afull),
        .full_o          (),
        .rden_i          (1'b0),
        .rdata_o         (),
        .empty_o         (ar_fifo_empty),
        .aempty_o        (ar_fifo_aempty),
        .debug_o         ()
    );

    //w에 대한 신호호
    wire        pw_fifo_full, pw_fifo_afull;
    wire        pw_fifo_empty, pw_fifo_aempty;
    wire [PCIE_PKG::PIPE_DATA_WIDTH-1:0] pw_data;
    wire        pw_wren;
    wire        pw_last;

    payload_handler #(
        .DATA_WIDTH     (PCIE_PKG::PIPE_DATA_WIDTH)
    ) u_payload (
        .clk             (clk),
        .rst_n           (rst_n),
        .w_if            (w_if),
        .payload_fifo_afull(pw_fifo_afull),
        .payload_fifo_wren (pw_wren),   //out
        .payload_fifo_data (pw_data),   //out
        .payload_last      (pw_last)    //out
    );

    SAL_FIFO #(
        .DATA_WIDTH      (PCIE_PKG::PIPE_DATA_WIDTH),
        .AFULL_THRES     (8)
    ) u_pw_fifo (
        .clk             (clk),
        .rst_n           (rst_n),
        .wren_i          (pw_wren),
        .wdata_i         (pw_data),
        .afull_o         (pw_fifo_afull),
        .full_o          (pw_fifo_full),
        .rden_i          (1'b0),
        .rdata_o         (),
        .empty_o         (pw_fifo_empty),
        .aempty_o        (pw_fifo_aempty),  //사용 안할 듯?
        .debug_o         ()
    );

    //tlp 어셈블러 만들어야함.
    // 여기서 AW/AR/WDATA FIFO의 empty_o, rdata_o, last 이용용
    // 실제 TLP 패킷을 만듦.

    // tlp_assembler u_tlp_asm (
    //     .clk             (clk),
    //     .rst_n           (rst_n),
    //     // AW: aw_fifo_empty, aw_fifo_rdata
    //     // AR: ar_fifo_empty, ar_fifo_rdata
    //     // PW: pw_fifo_empty, pw_fifo_rdata, pw_last
    //    
    // );
    

endmodule
