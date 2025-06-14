// File: tb_pcie_tx_top.sv
`timescale 1ns/1ps
import PCIE_PKG::*;

module tb_pcie_tx_top();

    //======================================================================
    // 1) 로컬 파라미터 정의
    //======================================================================
    localparam int ADDR_WIDTH    = 64;
    localparam int PAYLOAD_WIDTH = 256;

    //======================================================================
    // 2) Clock and reset
    //======================================================================
    reg clk;
    reg rst_n;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
    end

    //======================================================================
    // 3) AXI4 인터페이스 인스턴스
    //======================================================================
    AXI4_A_IF #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) aw_if (
        .aclk    (clk),
        .areset_n(rst_n)
    );

    AXI4_A_IF #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ar_if (
        .aclk    (clk),
        .areset_n(rst_n)
    );

    AXI4_W_IF #(
        .DATA_WIDTH(PAYLOAD_WIDTH)
    ) w_if (
        .aclk    (clk),
        .areset_n(rst_n)
    );

    //======================================================================
    // 4) DUT 출력 관찰용 신호
    //======================================================================
    wire                     aw_in_valid;
    wire [ADDR_WIDTH-1:0]    aw_in_addr;
    wire [7:0]               aw_in_len;

    wire                     ar_in_valid;
    wire [ADDR_WIDTH-1:0]    ar_in_addr;
    wire [7:0]               ar_in_len;

    wire                     w_in_valid;
    wire [PAYLOAD_WIDTH-1:0] w_in_data;
    wire                     w_in_last;

    wire                     tlp_out_valid;
    wire [PAYLOAD_WIDTH-1:0] tlp_out_data;
    wire                     tlp_out_last;

    //======================================================================
    // 5) DUT 인스턴스 (pcie_tx_top)
    //======================================================================
    pcie_tx_top #(
        .ADDR_WIDTH    (ADDR_WIDTH),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH)
    ) DUT (
        .clk           (clk),
        .rst_n         (rst_n),

        .aw_if         (aw_if),
        .ar_if         (ar_if),
        .w_if          (w_if),

        .aw_in_valid   (aw_in_valid),
        .aw_in_addr    (aw_in_addr),
        .aw_in_len     (aw_in_len),

        .ar_in_valid   (ar_in_valid),
        .ar_in_addr    (ar_in_addr),
        .ar_in_len     (ar_in_len),

        .w_in_valid    (w_in_valid),
        .w_in_data     (w_in_data),
        .w_in_last     (w_in_last),

        .tlp_out_valid (tlp_out_valid),
        .tlp_out_data  (tlp_out_data),
        .tlp_out_last  (tlp_out_last)
    );

    //======================================================================
    // 6) AXI 신호 초기화 & 시퀀스
    //======================================================================
    initial begin
        // AW 인터페이스 초기화
        aw_if.avalid   = 1'b0;
        aw_if.aaddr    = '0;
        aw_if.alen     = 8'd0;
        aw_if.asize    = 3'd2;   // 4 bytes
        aw_if.aburst   = 2'b01;  // INCR
        aw_if.acache   = 4'd0;
        aw_if.aprot    = 3'd0;
        aw_if.aqos     = 4'd0;
        aw_if.aregion  = 4'd0;
        aw_if.aid      = 4'd0;

        // AR 인터페이스 초기화
        ar_if.avalid   = 1'b0;
        ar_if.aaddr    = '0;
        ar_if.alen     = 8'd0;
        ar_if.asize    = 3'd2;   // 4 bytes
        ar_if.aburst   = 2'b01;  // INCR
        ar_if.acache   = 4'd0;
        ar_if.aprot    = 3'd0;
        ar_if.aqos     = 4'd0;
        ar_if.aregion  = 4'd0;
        ar_if.aid      = 4'd0;

        // W 인터페이스 초기화
        w_if.wvalid    = 1'b0;
        w_if.wdata     = '0;
        w_if.wstrb     = {PAYLOAD_WIDTH/8{1'b1}};
        w_if.wlast     = 1'b0;

        // Reset 해제 후 잠시 대기
        wait(rst_n);
        #10;

        //----------------------------------------------------
        // 테스트 1: AW(1DW) + Payload(1DW) → TLP 생성
        //----------------------------------------------------
        // 1) AW 전송 (헤더)
        @(posedge clk);
        aw_if.aaddr  <= 64'h0000_1100;
        aw_if.alen   <= 8'd0;       // (0+1)*8 bytes = 8바이트 → 1 DW
        aw_if.avalid <= 1'b1;
        wait(aw_if.aready == 1'b1);
        @(posedge clk);
        aw_if.avalid <= 1'b0;

        // 2) W 전송 (페이로드 1 워드)
        @(posedge clk);
        w_if.wdata  <= 256'hAAAA_AAAA_BBBB_BBBB_CCCC_CCCC_DDDD_DDDD;
        w_if.wlast  <= 1'b1;       // 마지막 페이로드 워드
        w_if.wvalid <= 1'b1;
        wait(w_if.wready == 1'b1);
        @(posedge clk);
        w_if.wvalid <= 1'b0;
        w_if.wlast  <= 1'b0;

        // TLP 출력 완료 대기
        wait(tlp_out_last == 1'b1);
        #20;

        //----------------------------------------------------
        // 테스트 2: AW(2DW) + Payload(2DW) → TLP 생성
        //----------------------------------------------------
        // 1) AW 전송 (헤더)
        @(posedge clk);
        aw_if.aaddr  <= 64'h0000_2200;
        aw_if.alen   <= 8'd1;       // (1+1)*8 bytes = 16바이트 → 2 DW
        aw_if.avalid <= 1'b1;
        wait(aw_if.aready == 1'b1);
        @(posedge clk);
        aw_if.avalid <= 1'b0;

        // 2) W 전송 (페이로드 1 워드)
        @(posedge clk);
        w_if.wdata  <= 256'h1111_2222_3333_4444_5555_6666_7777_8888;
        w_if.wlast  <= 1'b0;       // 첫 번째 페이로드
        w_if.wvalid <= 1'b1;
        wait(w_if.wready == 1'b1);
        @(posedge clk);
        w_if.wvalid <= 1'b0;

        // 3) W 전송 (페이로드 2 워드, 마지막)
        @(posedge clk);
        w_if.wdata  <= 256'h9999_AAAA_BBBB_CCCC_DDDD_EEEE_FFFF_0000;
        w_if.wlast  <= 1'b1;       // 마지막 워드
        w_if.wvalid <= 1'b1;
        wait(w_if.wready == 1'b1);
        @(posedge clk);
        w_if.wvalid <= 1'b0;
        w_if.wlast  <= 1'b0;

        // TLP 출력 완료 대기
        wait(tlp_out_last == 1'b1);
        #20;

        //----------------------------------------------------
        // 테스트 3: AR(1DW) → 헤더만 TLP 생성
        //----------------------------------------------------
        @(posedge clk);
        ar_if.aaddr  <= 64'h0000_3300;
        ar_if.alen   <= 8'd0;       // (0+1)*8 bytes = 8바이트 → 1 DW
        ar_if.avalid <= 1'b1;
        wait(ar_if.aready == 1'b1);
        @(posedge clk);
        ar_if.avalid <= 1'b0;

        // AR 헤더 TLP 출력 완료 대기
        wait(tlp_out_last == 1'b1);
        #20;

        //----------------------------------------------------
        // 테스트 4: AW(1DW) → AR(1DW) 순차 전송 (AW 페이로드 없이)
        //----------------------------------------------------
        // 1) AW 전송(헤더만, 페이로드 보내지 않음)
        @(posedge clk);
        aw_if.aaddr  <= 64'h0000_4400;
        aw_if.alen   <= 8'd0;       // (0+1)*8 bytes
        aw_if.avalid <= 1'b1;
        wait(aw_if.aready == 1'b1);
        @(posedge clk);
        aw_if.avalid <= 1'b0;

        // 2) 곧바로 AR 전송
        @(posedge clk);
        ar_if.aaddr  <= 64'h0000_5500;
        ar_if.alen   <= 8'd0;
        ar_if.avalid <= 1'b1;
        wait(ar_if.aready == 1'b1);
        @(posedge clk);
        ar_if.avalid <= 1'b0;

        // 잠시 대기 후 종료
        #200;
        $finish;
    end

    //======================================================================
    // 7) 모니터: tlp_out_valid가 1일 때마다 데이터 출력
    //======================================================================
    always @(posedge clk) begin
        if (tlp_out_valid) begin
            // 상위 128비트: 헤더, 하위 128비트: 페이로드(없으면 0)
            $display("[TIME %0t] HEADER = %h, PAYLOAD = %h, LAST = %b",
                      $time,
                      tlp_out_data[PAYLOAD_WIDTH-1 -: 128],  // [255:128]
                      tlp_out_data[127:0],                  // [127:0]
                      tlp_out_last);
        end
    end

endmodule
