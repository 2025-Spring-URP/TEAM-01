`timescale 1ns/1ps
import PCIE_PKG::*;

module dummy_top #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 256,
    parameter CHUNK_MAX_BEATS = 4
)(
    input  logic clk,
    input  logic rst_n,

    input  logic awvalid_in,
    output logic awready_out,
    input  logic [ID_WIDTH-1:0] awid_in,
    input  logic [ADDR_WIDTH-1:0] awaddr_in,
    input  logic [7:0] awlen_in,
    input  logic [2:0] awsize_in,
    input  logic [1:0] awburst_in,

    input  logic wvalid_in,
    output logic wready_out,
    input  logic [DATA_WIDTH-1:0] wdata_in,
    input  logic wlast_in,

    output logic [ADDR_WIDTH-1:0] out_addr,
    output logic [7:0] out_length,
    output logic [15:0] out_bdf,
    output logic out_is_memwrite,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] out_wdata,
    output logic out_valid,
    input  logic out_ready,

    output tlp_memory_req_header tlp_hdr_out,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] tlp_payload_out,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS + $bits(tlp_memory_req_header)-1 : 0] tlp_out,
    output logic tlp_valid
);

    typedef enum logic [1:0] {
        IDLE, COLLECT, OUTPUT
    } state_t;

    state_t state;
    logic [1:0] count;
    logic [ADDR_WIDTH-1:0] addr_latch;
    logic [DATA_WIDTH-1:0] buffer [0:CHUNK_MAX_BEATS-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 0;
            addr_latch <= 0;
            for (int i = 0; i < CHUNK_MAX_BEATS; i++) buffer[i] <= '0;
            tlp_valid <= 0;
        end else begin
            tlp_valid <= 0;

            case (state)
                IDLE: begin
                    if (awvalid_in) begin
                        addr_latch <= awaddr_in;
                        count <= 0;
                        state <= COLLECT;
                    end
                end

                COLLECT: begin
                    if (wvalid_in) begin
                        buffer[count] <= wdata_in;
                        count <= count + 1;
                        if (wlast_in) begin
                            state <= OUTPUT;
                        end
                    end
                end

                OUTPUT: begin
                    tlp_hdr_out <= create_header(addr_latch, CHUNK_MAX_BEATS, 16'h0002);
                    tlp_payload_out <= {buffer[0], buffer[1], buffer[2], buffer[3]};
                    tlp_valid <= 1;

                    out_addr <= addr_latch;
                    out_length <= CHUNK_MAX_BEATS;
                    out_bdf <= 16'h0002;
                    out_is_memwrite <= 1;
                    out_wdata <= {buffer[0], buffer[1], buffer[2], buffer[3]};
                    out_valid <= 1;

                    state <= IDLE;
                end
            endcase
        end
    end

    assign awready_out = (state == IDLE);
    assign wready_out  = (state == COLLECT);
    assign tlp_out     = {tlp_hdr_out, tlp_payload_out};

endmodule