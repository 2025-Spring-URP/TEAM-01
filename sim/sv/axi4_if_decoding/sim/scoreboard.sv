class scoreboard;

  // Monitor → Scoreboard 연결 mailbox
  mailbox scb_mbx;

  // 정답 item 리스트 (generator가 넣어줌)
  decoding_item ref_q[$];

  task run();
    $display("T=%0t [Scoreboard] 시작", $time);
    
    forever begin
      decoding_item monitor_item;
      scb_mbx.get(monitor_item); // monitor에서 수신

      // Reference (정답) 큐에서 하나 꺼냄
      if (ref_q.size() == 0) begin
        $fatal("T=%0t [Scoreboard] ❌ 정답 큐가 비었는데 모니터 데이터가 들어옴!", $time);
      end

      decoding_item ref_item = ref_q.pop_front();

      // 비교 시작
      if (monitor_item.out_addr        !== ref_item.out_addr ||
          monitor_item.out_length      !== ref_item.out_length ||
          monitor_item.out_bdf         !== ref_item.out_bdf ||
          monitor_item.out_is_memwrite !== ref_item.out_is_memwrite ||
          monitor_item.out_wdata       !== ref_item.out_wdata) begin

        $display("T=%0t [Scoreboard] ❌ MISMATCH 발생!", $time);
        $display("  ▷ REF     : addr=0x%08h len=%0d BDF=0x%04h", ref_item.out_addr, ref_item.out_length, ref_item.out_bdf);
        $display("  ▷ MONITOR : addr=0x%08h len=%0d BDF=0x%04h", monitor_item.out_addr, monitor_item.out_length, monitor_item.out_bdf);
      end
      else begin
        $display("T=%0t [Scoreboard] ✅ PASS - addr=0x%08h, len=%0d", $time, ref_item.out_addr, ref_item.out_length);
      end
    end
  endtask

endclass
