interface AXI4_A_IF #(parameter ID_WIDTH = 4, ADDR_WIDTH = 32)(
    input logic aclk, input logic areset_n
);
    logic                         avalid;
    logic                         aready;
    logic [ID_WIDTH-1:0]          aid;
    logic [ADDR_WIDTH-1:0]        aaddr;
    logic [7:0]                   alen;
    logic [2:0]                   asize;
    logic [1:0]                   aburst;

    modport master (
        output avalid, aid, aaddr, alen, asize, aburst,
        input  aready
    );
    modport slave (
        input  avalid, aid, aaddr, alen, asize, aburst,
        output aready
    );
    modport monitor (
        input avalid, aid, aaddr, alen, asize, aburst, aready
    );
endinterface

interface AXI4_W_IF #(parameter DATA_WIDTH = 256)(
    input logic aclk, input logic areset_n
);
    logic                    wvalid;
    logic                    wready;
    logic [DATA_WIDTH-1:0]   wdata;
    logic                    wlast;

    modport master (
        output wvalid, wdata, wlast,
        input  wready
    );
    modport slave (
        input  wvalid, wdata, wlast,
        output wready
    );
    modport monitor (
        input wvalid, wdata, wlast, wready
    );
endinterface

interface decoding_result_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 256,
    parameter CHUNK_MAX_BEATS = 4
)(
    input logic clk,
    input logic rst_n
);
    logic [ADDR_WIDTH-1:0]                    out_addr;
    logic [7:0]                               out_length;
    logic [15:0]                              out_bdf;
    logic                                     out_is_memwrite;
    logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0]    out_wdata;
    logic                                     out_valid;
    logic                                     out_ready;

    // DUT는 output만 내보냄
    modport dut_out (
        output out_addr,
               out_length,
               out_bdf,
               out_is_memwrite,
               out_wdata,
               out_valid,
        input  out_ready
    );

    // monitor는 이것을 입력으로 관측
    modport monitor (
        input  clk,
            rst_n,
               out_addr,
               out_length,
               out_bdf,
               out_is_memwrite,
               out_wdata,
               out_valid,
        output out_ready
    );
endinterface
