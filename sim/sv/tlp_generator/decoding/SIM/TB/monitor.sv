class monitor;

  // 연결 자원
  mailbox scb_mbx;
  virtual decoding_result_if.monitor result_vif;

  task run();
    $display("T=%0t [Monitor] 시작", $time);
    @(posedge result_vif.clk);  // 시작 동기화

    forever begin
      @(posedge result_vif.clk);

      if (result_vif.out_valid) begin
        decoding_item item = new;

        // DUT의 출력 값을 복사
        item.out_addr        = result_vif.out_addr;
        item.out_length      = result_vif.out_length;
        item.out_bdf         = result_vif.out_bdf;
        item.out_is_memwrite = result_vif.out_is_memwrite;
        item.out_wdata       = result_vif.out_wdata;

        item.print("MON");
        scb_mbx.put(item);

        // out_ready는 항상 1로 응답
        result_vif.out_ready <= 1;
      end
      else begin
        result_vif.out_ready <= 0;
      end
    end
  endtask

endclass