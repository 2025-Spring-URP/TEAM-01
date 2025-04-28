`timescale 1ns/1ps

module dummy_axi4_if_decoding #(
    parameter ID_WIDTH         = 4,
    parameter ADDR_WIDTH       = 32,
    parameter DATA_WIDTH       = 256,
    parameter CHUNK_MAX_BEATS  = 4
)(
    input  logic clk,
    input  logic rst_n,

    // AXI4 Write Address / Write Data 인터페이스 (slave로 연결됨)
    AXI4_A_IF.slave s_axi_aw,
    AXI4_W_IF.slave s_axi_w,

    // 디코딩 결과 (TLP-like output)
    decoding_result_if.dut_out result_if
);

    // 더미 동작: out_valid는 0으로 고정
    assign result_if.out_valid        = 1'b0;
    assign result_if.out_addr         = '0;
    assign result_if.out_length       = '0;
    assign result_if.out_bdf          = 16'h0200;
    assign result_if.out_is_memwrite  = 1'b1;
    assign result_if.out_wdata        = '0;

    // aready/wready 항상 수신 가능
    assign s_axi_aw.aready = 1'b1;
    assign s_axi_w.wready  = 1'b1;

endmodule