`timescale 1ns/1ps

import PCIE_PKG::*;

module top #(
    parameter ID_WIDTH        = 4,
    parameter ADDR_WIDTH      = 32,
    parameter DATA_WIDTH      = 256,
    parameter CHUNK_MAX_BEATS = 4   // 한번에 32B × 4 = 128B 처리
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // Write Address (AW) 채널
    input  wire                          awvalid_in,
    output wire                          awready_out,
    input  wire [ID_WIDTH-1:0]           awid_in,
    input  wire [ADDR_WIDTH-1:0]         awaddr_in,
    input  wire [7:0]                    awlen_in,
    input  wire [2:0]                    awsize_in,
    input  wire [1:0]                    awburst_in,

    // Write Data (W) 채널
    input  wire                          wvalid_in,
    output wire                          wready_out,
    input  wire [DATA_WIDTH-1:0]         wdata_in,
    input  wire                          wlast_in,

    // Read Address (AR) 채널
    input  wire                          arvalid_in,
    output wire                          arready_out,
    input  wire [ID_WIDTH-1:0]           arid_in,
    input  wire [ADDR_WIDTH-1:0]         araddr_in,
    input  wire [7:0]                    arlen_in,
    input  wire [2:0]                    arsize_in,
    input  wire [1:0]                    arburst_in
);

    //----------------------------------------------------------------------
    // 1) AXI4 인터페이스 인스턴스 연결
    //----------------------------------------------------------------------

    // Write Address (AW)
    AXI4_A_IF #(ID_WIDTH, ADDR_WIDTH) i_axi_aw (
        .aclk     (clk),
        .areset_n (rst_n)
    );
    assign i_axi_aw.avalid = awvalid_in;
    assign i_axi_aw.aid    = awid_in;
    assign i_axi_aw.aaddr  = awaddr_in;
    assign i_axi_aw.alen   = awlen_in;
    assign i_axi_aw.asize  = awsize_in;
    assign i_axi_aw.aburst = awburst_in;
    assign awready_out     = i_axi_aw.aready;

    // Write Data (W)
    AXI4_W_IF #(ID_WIDTH, DATA_WIDTH) i_axi_w (
        .aclk     (clk),
        .areset_n (rst_n)
    );
    assign i_axi_w.wvalid = wvalid_in;
    assign i_axi_w.wdata  = wdata_in;
    assign i_axi_w.wlast  = wlast_in;
    assign wready_out     = i_axi_w.wready;

    // Read Address (AR)
    AXI4_A_IF #(ID_WIDTH, ADDR_WIDTH) i_axi_ar (
        .aclk     (clk),
        .areset_n (rst_n)
    );
    assign i_axi_ar.avalid = arvalid_in;
    assign i_axi_ar.aid    = arid_in;
    assign i_axi_ar.aaddr  = araddr_in;
    assign i_axi_ar.alen   = arlen_in;
    assign i_axi_ar.asize  = arsize_in;
    assign i_axi_ar.aburst = arburst_in;
    assign arready_out     = i_axi_ar.aready;

    //----------------------------------------------------------------------
    // 2) AXI 디코딩 결과 연결
    //----------------------------------------------------------------------

    // Write 요청 디코딩 결과
    wire [ADDR_WIDTH-1:0] out_w_addr;
    wire [7:0]            out_w_length;
    wire [15:0]           out_w_bdf;
    wire [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] out_w_data;
    wire                  out_w_valid;
    wire                  out_w_ready;

    // Read 요청 디코딩 결과
    wire [ADDR_WIDTH-1:0] out_r_addr;
    wire [7:0]            out_r_length;
    wire                  out_r_valid;
    wire                  out_r_ready;

    // AXI 요청 -> 내부 형식으로 변환
    axi4_if_decoding #(
        .ID_WIDTH       (ID_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .CHUNK_MAX_BEATS(CHUNK_MAX_BEATS)
    ) dec_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_aw      (i_axi_aw.slave),
        .s_axi_w       (i_axi_w.slave),
        .out_w_addr    (out_w_addr),
        .out_w_length  (out_w_length),
        .out_w_bdf     (out_w_bdf),
        .out_w_data    (out_w_data),
        .out_w_valid   (out_w_valid),
        .out_w_ready   (out_w_ready),
        .s_axi_ar      (i_axi_ar.slave),
        .out_r_addr    (out_r_addr),
        .out_r_length  (out_r_length),
        .out_r_valid   (out_r_valid),
        .out_r_ready   (out_r_ready)
    );

    //----------------------------------------------------------------------
    // 3) 디코딩 결과 → TLP 생성 연결
    //----------------------------------------------------------------------

    // 핸드셰이크 신호임 디코딩 측에서 tlp gen측과 핸드셰이크 용도. 
    logic in_w_ready, in_r_ready;

    // TLP 출력 신호
    logic [DATA_WIDTH*CHUNK_MAX_BEATS + $bits(tlp_memory_req_header)-1:0] tlp_out;
    logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0]                                tlp_payload_out;
    tlp_memory_req_header                                                 tlp_hdr_out;
    logic                                                                 tlp_valid;

    // 디코딩 → TLP 생성 모듈 연결 (ready 연결)
    assign out_w_ready = in_w_ready;
    assign out_r_ready = in_r_ready;

    // 디코딩된 정보를 기반으로 PCIe TLP 패킷 생성
    pcie_tlp_gen #(
        .ID_WIDTH       (ID_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .CHUNK_MAX_BEATS(CHUNK_MAX_BEATS)
    ) pcie_tlp_gen_inst (
        .clk              (clk),
        .rst_n            (rst_n),
        .in_w_addr        (out_w_addr),
        .in_w_length      (out_w_length),
        .in_w_bdf         (out_w_bdf),
        .in_w_data        (out_w_data),
        .in_w_valid       (out_w_valid),
        .in_w_ready       (in_w_ready),
        .in_r_addr        (out_r_addr),
        .in_r_length      (out_r_length),
        .in_r_valid       (out_r_valid),
        .in_r_ready       (in_r_ready),
        .tlp_hdr_out      (tlp_hdr_out),
        .tlp_payload_out  (tlp_payload_out),
        .tlp_out          (tlp_out),
        .tlp_valid        (tlp_valid)
    );

    //----------------------------------------------------------------------
    // 4) (TODO) TLP PHY 연결 예정
    //----------------------------------------------------------------------

endmodule
