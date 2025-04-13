class generator;

  mailbox drv_mbx;
  event   drv_done;

  int num = 10;  // 트랜잭션 수

  task run();
    for (int i = 0; i < num; i++) begin
      decoding_item item = new;

      // ========== A 채널 ==========
      item.aaddr  = 32'h1000 + i * 128;  // 128B aligned
      item.alen   = $urandom_range(0, 3); // 1~4 beats
      int beats   = item.alen + 1;

      // ========== W 채널 ==========
      item.wdata = new[beats];
      item.wlast = new[beats];

      for (int j = 0; j < beats; j++) begin
        item.wdata[j] = {$random, $random, $random, $random}; // 256bit
        item.wlast[j] = (j == beats - 1); // 마지막 beat만 wlast=1
      end

      // ========== 예측값 계산 ==========
      item.out_addr        = item.aaddr;
      item.out_length      = beats * 8;  // 1 beat = 8DW
      item.out_bdf         = 16'h0200;
      item.out_is_memwrite = 1'b1;

      // out_wdata: 1024bit로 묶기 (없는 beat는 0으로 패딩)
      item.out_wdata = '0;
      for (int j = 0; j < beats; j++) begin
        item.out_wdata[j*256 +: 256] = item.wdata[j];
      end

      $display("T=%0t [Generator] 생성 #%0d (beats=%0d)", $time, i+1, beats);
      item.print("GEN");

      drv_mbx.put(item);
      @(drv_done);
    end

    $display("T=%0t [Generator] 모든 트랜잭션 생성 완료", $time);
  endtask

endclass
