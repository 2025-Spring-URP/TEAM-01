`timescale 1ns/1ps

module aw_header_maker #(
    parameter ADDR_WIDTH = PCIE_PKG::ADDR_WIDTH
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4 AW 채널 (slave)
    AXI4_A_IF.slave              aw_if,

    // AW 전용 헤더 FIFO 상태
    input  wire                  aw_fifo_afull,

    // AW 전용 헤더 FIFO 쓰기
    output logic                 aw_fifo_wren,
    output logic [127:0]         aw_fifo_data
);

    // FIFO 거의 가득 차면 READY 낮춤
    assign aw_if.aready = !aw_fifo_afull;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_fifo_wren  <= 1'b0;
            aw_fifo_data  <= 128'd0;
        end 
        else if (aw_if.avalid && aw_if.aready) begin
            aw_fifo_data <= create_w_header(aw_if.aaddr, (aw_if.alen + 1) * 8);  //alen 0이면 8*4 = 32바이트트
            aw_fifo_wren <= 1'b1;
        end
    end

endmodule
