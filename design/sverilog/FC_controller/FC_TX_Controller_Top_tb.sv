`timescale 1ns/1ps

module FC_TX_Controller_Top_tb;

    logic         clk;
    logic         rst_n;

    logic [7:0]   hdr_credit;
    logic [11:0]  data_credit;
    logic         is_initFC;
    logic         is_updateFC;
    logic [1:0]   type_credit;

    logic         send_tlp_req;
    logic [1:0]   send_tlp_type;
    logic [7:0]   send_tlp_size;

    logic         send_tlp_grant;

    FC_TX_Controller_Top dut (
        .clk(clk),
        .rst_n(rst_n),
        .hdr_credit_i(hdr_credit),
        .data_credit_i(data_credit),
        .is_initFC_i(is_initFC),
        .is_updateFC_i(is_updateFC),
        .type_credit_i(type_credit),
        .send_tlp_req_i(send_tlp_req),
        .send_tlp_type_i(send_tlp_type),
        .send_tlp_size_i(send_tlp_size),
        .send_tlp_grant_o(send_tlp_grant)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task print_state(string step);
        $display("[%t] %s", $time, step);
        $display("  cl_hdr = %0d, cl_data = %0d", dut.cl_hdr, dut.cl_data);
        $display("  cc_hdr = %0d, cc_data = %0d", dut.cc_hdr, dut.cc_data);
        $display("  required_hdr_credit = %0d, required_data_credit = %0d", dut.required_hdr_credit, dut.required_data_credit);
        $display("  gating_pass = %b, send_tlp_grant = %b", dut.gating_pass, send_tlp_grant);
        $display("------------------------------------------------------------");
    endtask

    // is_initFC와 is_updateFC는 hdr_credit와 data_credit, type_credit이 들어오기 최소 한 clock 주기 전에 들어와야 한다.
    // send_tlp_req가 1이 된 후 한 clock 주기 후에 send_tlp_grant가 1이 되어야 한다. 그렇지 않으면 cc가 계속 올라감.

    initial begin
        rst_n = 0;
        hdr_credit = 0;
        data_credit = 0;
        is_initFC = 0;
        is_updateFC = 0;
        type_credit = 2'b11;
        send_tlp_req = 0;
        send_tlp_type = 2'b11;
        send_tlp_size = 0;

        #20;
        rst_n = 1;

        // Step 1: InitFC
        @(posedge clk);
        is_initFC   = 1;
        is_updateFC = 0;
        @(posedge clk);
        hdr_credit  = 8'h07;
        data_credit = 12'h00a;
        type_credit = 2'b00;

        @(posedge clk);
        is_initFC   = 1;
        is_updateFC = 0;
        @(posedge clk);
        hdr_credit  = 8'h08;
        data_credit = 12'h00b;
        type_credit = 2'b01;

        @(posedge clk);
        is_initFC   = 1;
        is_updateFC = 0;
        @(posedge clk);
        hdr_credit  = 8'h09;
        data_credit = 12'h00c;
        type_credit = 2'b10;

        @(posedge clk);
        is_initFC   = 0;
        
        @(posedge clk);
        print_state("Step 1: InitFC 완료");

        // initFC를 할 때 is_initFC와 is_updateFC가 먼저 들어온 후 나머지 credit 정보가 들어와야 한다.
        // 왜냐하면 credit limit 모듈에서 is_initFC와 is_updateFC에 의해 상태가 업데이트 된 후 credit 정보는 input 그대로 사용하기 때문에 타이밍이 어긋날 수 있다.





        // Step 2 - 1: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 1;
        @(posedge clk);
        print_state("Step 2 - 1: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 2: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 2;
        @(posedge clk);
        print_state("Step 2 - 2: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 3: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 3;
        @(posedge clk);
        print_state("Step 2 - 3: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 4: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 4;
        @(posedge clk);
        print_state("Step 2 - 4: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 5: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 5;
        @(posedge clk);
        print_state("Step 2 - 5: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 6: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 6;
        @(posedge clk);
        print_state("Step 2 - 6: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 7: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 7;
        @(posedge clk);
        print_state("Step 2 - 7: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 8: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 8;
        @(posedge clk);
        print_state("Step 2 - 8: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 9: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size =9;
        @(posedge clk);
        print_state("Step 2 - 9: MWr 요청");
        send_tlp_req = 0;
        // Step 2 - 10: MWr 요청
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b00;
        send_tlp_size = 10;
        @(posedge clk);
        print_state("Step 2 - 10: MWr 요청");
        send_tlp_req = 0;





        // Step 3: UpdateFC
        @(posedge clk);
        is_updateFC = 1;
        @(posedge clk);
        hdr_credit  = 8'd10;
        data_credit = 12'd50;
        type_credit = 2'b00;

        @(posedge clk);
        hdr_credit = 0;
        data_credit = 0;

        @(posedge clk);
        print_state("Step 3: UpdateFC 수행 (Header+10, Data+50)");
        is_updateFC = 0;
        type_credit = 2'b11;





        // Step 4 - 1: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 1: MRd 요청");
        // Step 4 - 2: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 2: MRd 요청");
        // Step 4 - 3: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 3: MRd 요청");
        // Step 4 - 4: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 4: MRd 요청");
        // Step 4 - 5: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 5: MRd 요청");
        // Step 4 - 6: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 6: MRd 요청");
        // Step 4 - 7: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 7: MRd 요청");
        // Step 4 - 8: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 8: MRd 요청");
        // Step 4 - 9: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 9: MRd 요청");
        // Step 4 - 10: MRd 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b01;
        send_tlp_size = 0;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 4 - 10: MRd 요청");





        // Step 5: UpdateFC
        @(posedge clk);
        is_updateFC = 1;
        @(posedge clk);
        hdr_credit  = 8'd10;
        data_credit = 12'd50;
        type_credit = 2'b01;

        @(posedge clk);
        hdr_credit = 0;
        data_credit = 0;

        @(posedge clk);
        print_state("Step 4: UpdateFC 수행 (Header+10, Data+50)");
        is_updateFC = 0;
        type_credit = 2'b11;





        // Step 6 - 1: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 1;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 1: Cpl 요청");
        // Step 6 - 2: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 2;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 2: Cpl 요청");
        // Step 6 - 3: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 3;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 3: Cpl 요청");
        // Step 6 - 4: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 4;
        
        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 4: Cpl 요청");
        // Step 6 - 5: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 5;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 5: Cpl 요청");
        // Step 6 - 6: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 6;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 6: Cpl 요청");
        // Step 6 - 7: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 7;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 7: Cpl 요청");
        // Step 6 - 8: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 8;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 8: Cpl 요청");
        // Step 6 - 9: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 9;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 9: Cpl 요청");
        // Step 6 - 10: Cpl 요청
        #20;
        @(posedge clk);
        send_tlp_req = 1;
        send_tlp_type = 2'b10;
        send_tlp_size = 10;

        @(posedge clk);
        send_tlp_req = 0;

        @(posedge clk);
        print_state("Step 6 - 10: Cpl 요청");





        // Step 7: UpdateFC
        @(posedge clk);
        is_updateFC = 1;
        @(posedge clk);
        hdr_credit  = 8'd10;
        data_credit = 12'd50;
        type_credit = 2'b10;

        @(posedge clk);
        hdr_credit = 0;
        data_credit = 0;

        @(posedge clk);
        print_state("Step 7: UpdateFC 수행 (Header+10, Data+50)");
        is_updateFC = 0;
        type_credit = 2'b11;

        #50;
        $finish;
    end
endmodule
