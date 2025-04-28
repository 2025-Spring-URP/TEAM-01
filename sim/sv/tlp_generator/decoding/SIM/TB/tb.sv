`timescale 1ns/1ps

module tb;

  parameter ID_WIDTH         = 4;
  parameter ADDR_WIDTH       = 32;
  parameter DATA_WIDTH       = 256;
  parameter CHUNK_MAX_BEATS  = 4;

  // --------------------------------------
  // Clock & Reset
  // --------------------------------------
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5 clk = ~clk;  // 100MHz

  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // --------------------------------------
  // Interface 인스턴스
  // --------------------------------------
  AXI4_A_IF #(ID_WIDTH, ADDR_WIDTH) axi_a_if (.aclk(clk), .areset_n(rst_n));
  AXI4_W_IF #(DATA_WIDTH)           axi_w_if (.aclk(clk), .areset_n(rst_n));
  decoding_result_if #(ADDR_WIDTH, DATA_WIDTH, CHUNK_MAX_BEATS) result_if (.clk(clk), .rst_n(rst_n));

  // --------------------------------------
  // DUT 인스턴스 (axi4_if_decoding)
  // --------------------------------------
  dummy_axi4_if_decoding dut (
    .clk(clk),
    .rst_n(rst_n),
    .s_axi_aw(axi_a_if),
    .s_axi_w(axi_w_if),
    .result_if(result_if)
  );

  // --------------------------------------
  // Test 클래스 실행
  // --------------------------------------
  test t0;

  initial begin
    t0 = new;
    t0.e0.axi_a_vif = axi_a_if;
    t0.e0.axi_w_vif = axi_w_if;
    t0.e0.result_vif = result_if;

    t0.run();

    #1000 $finish;
  end

  // --------------------------------------
  // Waveform
  // --------------------------------------
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
  end

endmodule
