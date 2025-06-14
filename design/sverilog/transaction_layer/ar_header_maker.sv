`timescale 1ns/1ps

module ar_header_maker #(
    parameter ADDR_WIDTH = PCIE_PKG::ADDR_WIDTH
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4 AR 채널 (slave)
    AXI4_A_IF.slave              ar_if,

    // AR 전용 헤더 FIFO
    input  wire                  ar_fifo_afull,

    // AR 전용 헤더 FIFO 쓰기
    output logic                 ar_fifo_wren,
    output logic [127:0]         ar_fifo_data
);

    // FIFO 거의 가득 차면 ready 낮춤
    assign ar_if.aready = !ar_fifo_afull;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ar_fifo_wren  <= 1'b0;
            ar_fifo_data  <= 128'd0;
        end
        else if (ar_if.avalid && ar_if.aready) begin
            // AR용 헤더 생성
            ar_fifo_data <= create_r_header(ar_if.aaddr,(ar_if.alen + 1) * 8);  //alen 0이면 8*4 = 32바이트트
            ar_fifo_wren <= 1'b1;
        end
        else begin
            ar_fifo_wren <= 1'b0;
        end
    end

endmodule