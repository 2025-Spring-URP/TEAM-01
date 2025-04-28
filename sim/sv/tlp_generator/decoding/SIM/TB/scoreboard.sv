class scoreboard;

  // 연결 mailbox
  mailbox scb_mbx;
  bit pass = 1;

  task run();
    $display("T=%0t [Scoreboard] 시작", $time);

    forever begin
      decoding_item mon_item[$];
      scb_mbx.get(mon_item);  // monitor → scoreboard

      if (mon_item.size() == 0) begin
        $fatal("T=%0t [Scoreboard] ❌ Reference queue가 비었습니다!", $time);
      end

      // 비교 결과
      if (mon_item.out_addr        !== mon_item.out_addr)        pass = 0;
      if (mon_item.out_length      !== mon_item.out_length)      pass = 0;
      if (mon_item.out_bdf         !== mon_item.out_bdf)         pass = 0;
      if (mon_item.out_is_memwrite !== mon_item.out_is_memwrite) pass = 0;
      if (mon_item.out_wdata       !== mon_item.out_wdata)       pass = 0;

      if (pass) begin
        $display("T=%0t [Scoreboard] ✅ PASS", $time);
        $display("    ▶ Addr=0x%08h, Len=%0d DW, BDF=0x%04h",
                  mon_item.out_addr, mon_item.out_length, mon_item.out_bdf);
      end else begin
        $display("T=%0t [Scoreboard] ❌ MISMATCH!", $time);
        $display("    ▶ REF     : Addr=0x%08h, Len=%0d, BDF=0x%04h, Write=%0b",
                  mon_item.out_addr, mon_item.out_length, mon_item.out_bdf, mon_item.out_is_memwrite);
        $display("    ▶ MONITOR : Addr=0x%08h, Len=%0d, BDF=0x%04h, Write=%0b",
                  mon_item.out_addr, mon_item.out_length, mon_item.out_bdf, mon_item.out_is_memwrite);
      end
    end
  endtask

endclass