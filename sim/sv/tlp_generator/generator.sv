class generator;

  mailbox drv_mbx;
  event   drv_done;

  int num = 10;  // 생성할 트랜잭션 수

  task run();
    for (int i = 0; i < num; i++) begin
      tlp_item item = new;

      // ===== A 채널 (공통 요청 정보) =====
      item.avalid = 1;
      item.aaddr  = 32'h1000 + i * 128;       // 128B aligned address
      item.alen   = 3;                        // 4 beats (32B)
      // asize = 3, aburst = 01은 고정값

      int beats = item.alen + 1;              // 실제 beat 수: 4

      // ===== 랜덤하게 write 요청일 경우에만 W 채널 추가 =====
      if ($urandom_range(0, 1)) begin  // 50% 확률로 write 요청
        item.wdata  = new[beats];
        item.wvalid = new[beats];
        item.wlast  = new[beats];

        foreach (item.wdata[j]) begin
          item.wdata[j]  = {$random, $random}; // 64-bit random
          item.wvalid[j] = 1;
          item.wlast[j]  = (j == beats - 1);
        end

        // 예상 header 필드 작성 (scoreboard용)
        item.format   = 2'b010;     // 3DW header + data
        item.type     = 5'b00000;   // Mem Write
        item.tag      = i[7:0];
        item.length   = (beats * 8) / 4;  // byte → DW
        item.tlp_addr = item.aaddr;
      end
      else begin
        // read 요청이므로 rdata는 나중에 monitor가 수집
        item.format   = 2'b000;     // 3DW header only
        item.type     = 5'b00000;   // Mem Read
        item.tag      = i[7:0];
        item.length   = (beats * 8) / 4;
        item.tlp_addr = item.aaddr;
      end

      $display("T=%0t [Generator] #%0d 트랜잭션 생성", $time, i+1);
      item.print("GEN");

      drv_mbx.put(item);
      @(drv_done);
    end

    $display("T=%0t [Generator] 모든 트랜잭션 생성 완료", $time);
  endtask

endclass
