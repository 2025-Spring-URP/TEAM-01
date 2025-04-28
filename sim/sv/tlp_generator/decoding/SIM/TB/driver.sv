class driver;

  // 연결 자원
  virtual AXI4_A_IF #(4, 32) axi_a_vif;
  virtual AXI4_W_IF #(256)   axi_w_vif;

  event   drv_done;
  mailbox drv_mbx;

  task run();
    $display("T=%0t [Driver] 시작", $time);
    @(posedge axi_a_vif.aclk);  // 클럭 동기화

    forever begin
      decoding_item item;
      drv_mbx.get(item);  // 하나 받아오기
      $display("T=%0t [Driver] ▶ 트랜잭션 수신", $time);
      item.print("DRV");

      // ===================================================
      // 1) Write Address 전송 (A 채널)
      // ===================================================
      axi_a_vif.avalid <= 1;
      axi_a_vif.aaddr  <= item.aaddr;
      axi_a_vif.alen   <= item.alen;
      axi_a_vif.asize  <= item.asize;
      axi_a_vif.aburst <= item.aburst;
      axi_a_vif.aid    <= 0;

      // avalid & aready 핸드셰이크 기다림
      do @(posedge axi_a_vif.aclk); while (!axi_a_vif.aready);

      axi_a_vif.avalid <= 0;

      // ===================================================
      // 2) Write Data 전송 (W 채널)
      // ===================================================
      for (int i = 0; i < item.wdata.size(); i++) begin
        axi_w_vif.wvalid <= 1;
        axi_w_vif.wdata  <= item.wdata[i];
        axi_w_vif.wlast  <= item.wlast[i];

        // wvalid & wready 핸드셰이크
        do @(posedge axi_w_vif.aclk); while (!axi_w_vif.wready);
      end

      axi_w_vif.wvalid <= 0;
      axi_w_vif.wlast  <= 0;

      // ===================================================
      // 3) 완료 처리
      // ===================================================
      $display("T=%0t [Driver] ▶ 트랜잭션 완료", $time);
      ->drv_done;
    end
  endtask

endclass