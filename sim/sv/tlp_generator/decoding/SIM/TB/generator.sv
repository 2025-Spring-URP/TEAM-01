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

      // ========== W 채널 ==========
      item.wdata = new[item.alen + 1]; // beats 수 만큼 wdata 생성
      item.wlast = new[item.alen + 1]; // beats 수 만큼 wlast 생성

      for (int j = 0; j < item.alen + 1; j++) begin
        item.wdata[j] = {$random, $random, $random, $random}; // 256bit
        item.wlast[j] = (j == item.alen); // 마지막 beat만 wlast=1
      end

      // ========== 예측값 계산 ==========
      item.out_addr        = item.aaddr;
      item.out_length      = (item.alen + 1) * 8;  // 1 beat = 8DW
      item.out_bdf         = 16'h0200;
      item.out_is_memwrite = 1'b1;

      item.out_wdata = '0;
      for (int j = 0; j < item.alen + 1; j++) begin
        item.out_wdata[j*256 +: 256] = item.wdata[j];
      end

      $display("T=%0t [Generator] 생성 #%0d (beats=%0d)", $time, i+1, item.alen + 1);
      item.print("GEN");

      drv_mbx.put(item);
      @(drv_done);
    end

    $display("T=%0t [Generator] 모든 트랜잭션 생성 완료", $time);
  endtask

endclass