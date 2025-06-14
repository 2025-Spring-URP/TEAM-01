`timescale 1ns/1ps

module payload_handler #(
    parameter DATA_WIDTH = PCIE_PKG::PIPE_DATA_WIDTH
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // AXI4 W 채널 (slave modport)
    AXI4_W_IF.slave                w_if,

    // Payload 전용 FIFO almost‐full
    input  wire                    payload_fifo_afull,

    // Payload 전용 FIFO 쓰기 인터페이스
    output logic                   payload_fifo_wren,
    output logic [DATA_WIDTH-1:0]  payload_fifo_data,

    // TLP 어셈블러용 wlast 신호
    output logic                   payload_last
);

    //FIFO 거의 가득 차면 WREADY 낮춤
    assign w_if.wready = !payload_fifo_afull;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            payload_fifo_wren  <= 1'b0;
            payload_fifo_data  <= {DATA_WIDTH{1'b0}};
            payload_last       <= 1'b0;
        end
        else if (w_if.wvalid && w_if.wready) begin
            payload_fifo_data <= w_if.wdata;
            payload_fifo_wren <= 1'b1;
            payload_last      <= w_if.wlast;
        end
        else begin
            payload_fifo_wren <= 1'b0;
            payload_last      <= 1'b0;
        end
    end

endmodule