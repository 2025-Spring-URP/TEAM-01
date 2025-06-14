// File: pcie_tx_top_with_obs.sv
`timescale 1ns/1ps
import PCIE_PKG::*;

module pcie_tx_top #(
    parameter ADDR_WIDTH     = PCIE_PKG::ADDR_WIDTH,
    parameter PAYLOAD_WIDTH  = PCIE_PKG::PIPE_DATA_WIDTH
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // AXI4 Slave 인터페이스
    AXI4_A_IF.slave             aw_if,
    AXI4_A_IF.slave             ar_if,
    AXI4_W_IF.slave             w_if,



    // 최종 TLP 스트림 출력 관찰용 포트
    output wire                 tlp_out_valid,
    output wire [PAYLOAD_WIDTH-1:0] tlp_out_data,
    output wire                 tlp_out_last
);


 
    // 1 AW 헤더 생성 및 FIFO

    wire        aw_hdr_wren, aw_hdr_afull;
    wire [127:0] aw_hdr_data;
    wire        aw_fifo_empty;
    wire [127:0] aw_fifo_rdata;
    wire        aw_fifo_rden_sig;

    aw_header_maker #(.ADDR_WIDTH(ADDR_WIDTH)) u_aw_hdr (
        .clk           (clk),
        .rst_n         (rst_n),
        .aw_if         (aw_if),
        .aw_fifo_afull (aw_hdr_afull),
        .aw_fifo_wren  (aw_hdr_wren),
        .aw_fifo_data  (aw_hdr_data)
    );

    SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(128)) u_aw_fifo (
        .clk       (clk),
        .rst_n     (rst_n),
        .full_o    (),                 // 내부용
        .afull_o   (aw_hdr_afull),
        .wren_i    (aw_hdr_wren),
        .wdata_i   (aw_hdr_data),
        .empty_o   (aw_fifo_empty),
        .aempty_o  (),
        .rden_i    (aw_fifo_rden_sig), // tlp_assembler가 제어
        .rdata_o   (aw_fifo_rdata),
        .debug_o   ()
    );


    // 2 AR 헤더 생성 및 FIFO
    wire        ar_hdr_wren, ar_hdr_afull;
    wire [127:0] ar_hdr_data;
    wire        ar_fifo_empty;
    wire [127:0] ar_fifo_rdata;
    wire        ar_fifo_rden_sig;

    ar_header_maker #(.ADDR_WIDTH(ADDR_WIDTH)) u_ar_hdr (
        .clk           (clk),
        .rst_n         (rst_n),
        .ar_if         (ar_if),
        .ar_fifo_afull (ar_hdr_afull),
        .ar_fifo_wren  (ar_hdr_wren),
        .ar_fifo_data  (ar_hdr_data)
    );

    SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(128)) u_ar_fifo (
        .clk       (clk),
        .rst_n     (rst_n),
        .full_o    (),
        .afull_o   (ar_hdr_afull),
        .wren_i    (ar_hdr_wren),
        .wdata_i   (ar_hdr_data),
        .empty_o   (ar_fifo_empty),
        .aempty_o  (),
        .rden_i    (ar_fifo_rden_sig), // tlp_assembler가 제어
        .rdata_o   (ar_fifo_rdata),
        .debug_o   ()
    );

    // 3 Payload 핸들러 및 FIFO
    wire        pw_wren_int, pw_afull_int;
    wire [PAYLOAD_WIDTH-1:0] pw_data_int;
    wire        pw_last_int;
    wire        pw_fifo_empty;
    wire [PAYLOAD_WIDTH-1:0] pw_fifo_rdata;
    wire        pw_fifo_rden_sig;

    payload_handler #(.DATA_WIDTH(PAYLOAD_WIDTH)) u_payload (
        .clk                (clk),
        .rst_n              (rst_n),
        .w_if               (w_if),
        .payload_fifo_afull (pw_afull_int),
        .payload_fifo_wren  (pw_wren_int),
        .payload_fifo_data  (pw_data_int),
        .payload_last       (pw_last_int)
    );

    SAL_FIFO #(.DEPTH_LG2(4), .DATA_WIDTH(PAYLOAD_WIDTH)) u_pw_fifo (
        .clk       (clk),
        .rst_n     (rst_n),
        .full_o    (),
        .afull_o   (pw_afull_int),
        .wren_i    (pw_wren_int),
        .wdata_i   (pw_data_int),
        .empty_o   (pw_fifo_empty),
        .aempty_o  (),
        .rden_i    (pw_fifo_rden_sig),  // tlp_assembler가 제어
        .rdata_o   (pw_fifo_rdata),
        .debug_o   ()
    );

    // 4 TLP Assembler 연결
    tlp_assembler #(.PAYLOAD_WIDTH(PAYLOAD_WIDTH)) u_assembler (
        .clk             (clk),
        .rst_n           (rst_n),

        // AW FIFO 읽기
        .aw_fifo_empty   (aw_fifo_empty),
        .aw_fifo_data    (aw_fifo_rdata),
        .aw_fifo_rden    (aw_fifo_rden_sig),

        // AR FIFO 읽기
        .ar_fifo_empty   (ar_fifo_empty),
        .ar_fifo_data    (ar_fifo_rdata),
        .ar_fifo_rden    (ar_fifo_rden_sig),

        // Payload FIFO 읽기
        .pw_fifo_empty   (pw_fifo_empty),
        .pw_fifo_data    (pw_fifo_rdata),
        .pw_fifo_last    (pw_last_int),
        .pw_fifo_rden    (pw_fifo_rden_sig),

        // 최종 TLP 스트림 출력
        .tlp_out_valid   (tlp_out_valid),
        .tlp_out_data    (tlp_out_data),
        .tlp_out_last    (tlp_out_last)
    );

endmodule
