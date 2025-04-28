class decoding_item;

  // ===== AXI4 Write Address (AW) 채널 =====
  rand bit [31:0] aaddr;
  rand bit [7:0]  alen;
       bit [2:0]  asize  = 3'b011;  // 64-bit (8B)
       bit [1:0]  aburst = 2'b01;   // INCR (고정)

  // ===== AXI4 Write Data (W) 채널 =====
  rand bit [255:0] wdata[];         // 1 beat = 32B = 256bit
  rand bit         wlast[];         // 각 beat마다 wlast 여부

  // ===== 기대하는 DUT 출력 (TLP-like) =====
       bit [31:0]   out_addr;
       bit [7:0]    out_length;       // in DW
       bit [15:0]   out_bdf = 16'h0200;
       bit          out_is_memwrite = 1;
       bit [1023:0] out_wdata;        // 최대 4 beat = 128B = 1024bit

  // ===== 디버깅용 출력 =====
  function void print(string tag = "");
    $display("T=%0t [%s] AXI addr=0x%08h, alen=%0d", $time, tag, aaddr, alen);
    for (int i = 0; i < wdata.size(); i++) begin
      $display("    W[%0d] = 0x%064h  wlast=%0b", i, wdata[i], wlast[i]);
    end
    $display("    Expect: out_addr=0x%08h, length=%0d DW, BDF=0x%04h, is_write=%0b",
              out_addr, out_length, out_bdf, out_is_memwrite);
  endfunction

endclass