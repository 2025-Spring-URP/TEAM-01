class env;

  // ------------------------------------------------------------
  // 구성 요소들
  // ------------------------------------------------------------
  driver      d0;
  monitor     m0;
  generator   g0;
  //scoreboard  s0;

  // ------------------------------------------------------------
  // 연결용 리소스
  // ------------------------------------------------------------
  mailbox     drv_mbx;     // generator → driver
  mailbox     scb_mbx;     // monitor → scoreboard
  event       drv_done;    // generator ↔ driver 완료 동기화

  // ------------------------------------------------------------
  // virtual interface 선언
  // ------------------------------------------------------------
  virtual AXI4_A_IF #(4, 32)               axi_a_vif;
  virtual AXI4_W_IF #(256)                 axi_w_vif;
  virtual decoding_result_if #(32, 256, 4) result_vif;

  // ------------------------------------------------------------
  // 생성자
  // ------------------------------------------------------------
  function new();
    d0 = new;
    m0 = new;
    g0 = new;
    //s0 = new;

    drv_mbx = new();
    scb_mbx = new();

    // mailbox 연결
    d0.drv_mbx = drv_mbx;
    g0.drv_mbx = drv_mbx;
    m0.scb_mbx = scb_mbx;
    //s0.scb_mbx = scb_mbx;

    // event 연결
    d0.drv_done = drv_done;
    g0.drv_done = drv_done;
  endfunction

  // ------------------------------------------------------------
  // 전체 테스트 실행 task
  // ------------------------------------------------------------
  virtual task run();

    // virtual interface 연결
    d0.axi_a_vif = axi_a_vif;
    d0.axi_w_vif = axi_w_vif;
    m0.result_vif = result_vif;

    // 병렬 실행
    fork
      g0.run();
      d0.run();
      m0.run();
      //s0.run();
    join_any
  endtask

endclass