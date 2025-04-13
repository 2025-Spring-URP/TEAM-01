module tb;

  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  parameter ID_WIDTH = 4;
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 256;
  parameter CHUNK_MAX_BEATS = 4;

  AXI4_A_IF #(ID_WIDTH, ADDR_WIDTH) axi_a_if (.aclk(clk), .areset_n(rst_n));
  AXI4_W_IF #(ID_WIDTH, DATA_WIDTH) axi_w_if (.aclk(clk), .areset_n(rst_n));

  logic [ADDR_WIDTH-1:0]        out_addr;
  logic [7:0]                   out_length;
  logic [15:0]                  out_bdf;
  logic                         out_is_memwrite;
  logic [1023:0]                out_wdata;
  logic                         out_valid;
  logic                         out_ready = 1;

  axi4_if_decoding #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .CHUNK_MAX_BEATS(CHUNK_MAX_BEATS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_axi_aw(axi_a_if.slave),
    .s_axi_w(axi_w_if.slave),
    .out_addr(out_addr),
    .out_length(out_length),
    .out_bdf(out_bdf),
    .out_is_memwrite(out_is_memwrite),
    .out_wdata(out_wdata),
    .out_valid(out_valid),
    .out_ready(out_ready)
  );

  // test 실행
  test t0;

  initial begin
    t0 = new;

    // DUT 포트와 env 내부 연결
    t0.e0.clk             = clk;
    t0.e0.rst_n           = rst_n;
    t0.e0.axi_a_if        = axi_a_if;
    t0.e0.axi_w_if        = axi_w_if;
    t0.e0.out_valid       = out_valid;
    t0.e0.out_addr        = out_addr;
    t0.e0.out_length      = out_length;
    t0.e0.out_bdf         = out_bdf;
    t0.e0.out_is_memwrite = out_is_memwrite;
    t0.e0.out_wdata       = out_wdata;
    t0.e0.out_ready       = out_ready;

    t0.run();
  end

  initial begin
    #2000;
    $display("T=%0t [TB] 시뮬레이션 종료", $time);
    $finish;
  end

endmodule
