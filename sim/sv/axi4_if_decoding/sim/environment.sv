class env;

  driver       d0;
  monitor      m0;
  generator    g0;
  scoreboard   s0;

  mailbox drv_mbx;
  mailbox scb_mbx;
  event   drv_done;

  virtual AXI4_A_IF axi_a_if;
  virtual AXI4_W_IF axi_w_if;

  input  logic clk;
  input  logic rst_n;

  logic         out_valid;
  logic         out_ready;
  logic [31:0]  out_addr;
  logic [7:0]   out_length;
  logic [15:0]  out_bdf;
  logic         out_is_memwrite;
  logic [1023:0] out_wdata;

  function new();
    d0 = new;
    m0 = new;
    g0 = new;
    s0 = new;

    drv_mbx = new();
    scb_mbx = new();

    d0.drv_mbx = drv_mbx;
    g0.drv_mbx = drv_mbx;

    m0.scb_mbx = scb_mbx;
    s0.scb_mbx = scb_mbx;

    d0.drv_done = drv_done;
    g0.drv_done = drv_done;
  endfunction

  task run();
    // 인터페이스 바인딩
    d0.axi_a_if = axi_a_if;
    d0.axi_w_if = axi_w_if;

    // 모니터에 신호 바인딩
    m0.clk             = clk;
    m0.rst_n           = rst_n;
    m0.out_valid       = out_valid;
    m0.out_addr        = out_addr;
    m0.out_length      = out_length;
    m0.out_bdf         = out_bdf;
    m0.out_is_memwrite = out_is_memwrite;
    m0.out_wdata       = out_wdata;
    m0.out_ready       = out_ready;

    fork
      g0.run();
      d0.run();
      m0.run();
      s0.run();
    join_none

    // generator의 예상값을 scoreboard로
    forever begin
      decoding_item item;
      drv_mbx.peek(item);
      s0.ref_q.push_back(item);
      @(drv_done);
    end
  endtask

endclass
