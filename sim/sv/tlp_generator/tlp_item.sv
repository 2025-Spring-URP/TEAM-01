class tlp_item;

  // ===== A 채널 =====
  rand bit        avalid;
  rand bit [31:0] aaddr;
  rand bit [7:0]  alen;              // burst length (alen + 1 = beats)
       bit [2:0] asize = 3'b011;    // 64-bit fixed
       bit [1:0] aburst = 2'b01;    // INCR fixed

  // ===== W 채널 =====
  rand bit [63:0] wdata[];
  rand bit        wvalid[];
  rand bit        wlast[];

  // ===== R 채널 =====
       bit [63:0] rdata[];
       bit        rvalid[];
       bit        rlast[];

  // ===== Expected TLP Header 필드 (optional for scoreboard) =====
       bit [1:0]  format;
       bit [4:0]  type;
       bit [7:0]  tag;
       bit [9:0]  length;       // in DW
       bit [31:0] tlp_addr;

  // ===== 디버그용 출력 =====
  function void print(string tag = "");
    $display("T=%0t [%s] A-addr=0x%08h, alen=%0d", $time, tag, aaddr, alen);
    for (int i = 0; i < wdata.size(); i++) begin
      $display("  W[%0d] = 0x%016h, wlast=%b", i, wdata[i], wlast[i]);
    end
    for (int i = 0; i < rdata.size(); i++) begin
      $display("  R[%0d] = 0x%016h, rlast=%b", i, rdata[i], rlast[i]);
    end
  endfunction

endclass