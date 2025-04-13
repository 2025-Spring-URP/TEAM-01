class monitor;

  input  logic clk;
  input  logic rst_n;

  // DUT 출력 연결
  input  logic         out_valid;
  output logic         out_ready;
  input  logic [31:0]  out_addr;
  input  logic [7:0]   out_length;
  input  logic [15:0]  out_bdf;
  input  logic         out_is_memwrite;
  input  logic [1023:0] out_wdata;

  mailbox scb_mbx;

  task run();
    $display("T=%0t [Monitor] 시작", $time);

    // 기본적으로 out_ready는 항상 1로 응답한다고 가정
    out_ready = 1;

    forever begin
      @(posedge clk);
      if (rst_n && out_valid) begin
        decoding_item item = new;

        item.out_addr        = out_addr;
        item.out_length      = out_length;
        item.out_bdf         = out_bdf;
        item.out_is_memwrite = out_is_memwrite;
        item.out_wdata       = out_wdata;

        $display("T=%0t [Monitor] TLP 수신 (addr=0x%08h, length=%0d DW)", $time, out_addr, out_length);
        scb_mbx.put(item);
      end
    end
  endtask

endclass
