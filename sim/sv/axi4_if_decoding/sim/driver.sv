class driver;

  // 인터페이스 핸들
  virtual AXI4_A_IF axi_a_if;
  virtual AXI4_W_IF axi_w_if;

  mailbox drv_mbx;
  event   drv_done;

  task run();
    decoding_item item;

    $display("T=%0t [Driver] 시작", $time);

    forever begin
      drv_mbx.get(item);
      $display("T=%0t [Driver] 트랜잭션 수신", $time);
      item.print("DRV");

      // ========== A 채널 전송 ==========
      axi_a_if.avalid <= 1;
      axi_a_if.aaddr  <= item.aaddr;
      axi_a_if.alen   <= item.alen;
      axi_a_if.asize  <= item.asize;
      axi_a_if.aburst <= item.aburst;

      @(posedge axi_a_if.aclk);
      axi_a_if.avalid <= 0;

      // ========== W 채널 전송 ==========
      for (int i = 0; i < item.wdata.size(); i++) begin
        axi_w_if.wvalid <= 1;
        axi_w_if.wdata  <= item.wdata[i];
        axi_w_if.wlast  <= item.wlast[i];

        @(posedge axi_w_if.aclk);
      end

      // 전송 완료 → wvalid 0
      axi_w_if.wvalid <= 0;
      axi_w_if.wlast  <= 0;

      -> drv_done;
    end
  endtask

endclass
