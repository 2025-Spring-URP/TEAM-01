class scoreboard;

  mailbox scb_mbx;
  decoding_item ref_q[$];

  task run();
    $display("T=%0t [Scoreboard] 시작", $time);

    forever begin
      decoding_item mon_item;
      scb_mbx.get(mon_item);

      if (ref_q.size() == 0) begin
        $fatal("T=%0t [Scoreboard] ❌ 정답 없음! Monitor에서 예기치 않게 item이 들어왔습니다.", $time);
      end

      decoding_item ref_item;
      ref_item = ref_q.pop_front();

      // 비교 조건
      bit pass = 1;

      if (mon_item.out_addr        !== ref_item.out_addr)        pass = 0;
      if (mon_item.out_length      !== ref_item.out_length)      pass = 0;
      if (mon_item.out_bdf         !== ref_item.out_bdf)         pass = 0;
      if (mon_item.out_is_memwrite !== ref_item.out_is_memwrite) pass = 0;
      if (mon_item.out_wdata       !== ref_item.out_wdata)       pass = 0;

      // 출력
      if (pass) begin
        $display("T=%0t [Scoreboard] ✅ PASS", $time);
        $display("    ▶ Addr=0x%08h, Len=%0d DW, Write=%0b, BDF=0x%04h",
                  ref_item.out_addr, ref_item.out_length,
                  ref_item.out_is_memwrite, ref_item.out_bdf);
      end else begin
        $display("T=%0t [Scoreboard] ❌ MISMATCH", $time);
        $display("    ▶ REF     : Addr=0x%08h Len=%0d Write=%0b BDF=0x%04h",
                  ref_item.out_addr, ref_item.out_length,
                  ref_item.out_is_memwrite, ref_item.out_bdf);
        $display("    ▶ MONITOR : Addr=0x%08h Len=%0d Write=%0b BDF=0x%04h",
                  mon_item.out_addr, mon_item.out_length,
                  mon_item.out_is_memwrite, mon_item.out_bdf);
      end
    end
  endtask

endclass

