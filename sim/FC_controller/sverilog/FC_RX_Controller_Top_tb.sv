`timescale 1ns/1ps

module FC_RX_Controller_Top_tb;

    logic         clk;
    logic         rst_n;

    logic [7:0]   buffer_hdr_credit_i;
    logic [11:0]  buffer_data_credit_i;
    logic [7:0]   buffer_hdr_rsv_i;
    logic [11:0]  buffer_data_rsv_i;
    logic         is_initFC_i;
    logic         is_updateFC_i;
    logic [1:0]   type_credit_i;     // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl

    logic [7:0]   hdr_credit_o;
    logic [11:0]  data_credit_o;
    logic         initfc_send_o;
    logic         updatefc_send_o;
    logic [1:0]   type_send_o;       // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl

    FC_RX_Controller_Top dut (
        .clk(clk),
        .rst_n(rst_n),

        .buffer_hdr_credit_i(buffer_hdr_credit_i),
        .buffer_data_credit_i(buffer_data_credit_i),
        .buffer_hdr_rsv_i(buffer_hdr_rsv_i),
        .buffer_data_rsv_i(buffer_data_rsv_i),
        .is_initFC_i(is_initFC_i),
        .is_updateFC_i(is_updateFC_i),
        .type_credit_i(type_credit_i),

        .hdr_credit_o(hdr_credit_o),
        .data_credit_o(data_credit_o),
        .initfc_send_o(initfc_send_o),
        .updatefc_send_o(updatefc_send_o),
        .type_send_o(type_send_o)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task print_state(string step);
        $display("%t: %s", $time, step);
        $display("  ca_ph = %0d, ca_nph = %0d, ca_cplh = %0d, ca_pd = %0d, ca_cpld= %0d", dut.u_fc_rx_credit_allocator.ca_ph, dut.u_fc_rx_credit_allocator.ca_nph, dut.u_fc_rx_credit_allocator.ca_cplh, dut.u_fc_rx_credit_allocator.ca_pd, dut.u_fc_rx_credit_allocator.ca_cpld);
        $display("  hdr_credit_o = %0d, data_credit_o = %0d", hdr_credit_o, data_credit_o);
        $display("  initfc_send_o = %b, updatefc_send_o = %b", initfc_send_o, updatefc_send_o);
        $display("------------------------------------------------------------");
    endtask

    initial begin
        rst_n = 0;
        buffer_hdr_credit_i = 0;
        buffer_data_credit_i = 0;
        buffer_hdr_rsv_i = 0;
        buffer_data_rsv_i = 0;
        is_initFC_i = 0;
        is_updateFC_i = 0;

        #20;
        rst_n = 1;

        // is_initFC_i: 1 -> state_n: 10 -> state: 10
        // Step 1: InitFC 수행
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b00; // MWr
        buffer_hdr_credit_i = 8'd20;
        buffer_data_credit_i = 12'd300;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 1: InitFC 수행");

        // Step 2: UpdateFC 수행 - 처리한 credit 추가
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b00; // MWr
        buffer_hdr_rsv_i = 8'd5;
        buffer_data_rsv_i = 12'd50;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd00;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 2: UpdateFC 수행 (+5, +50)");

        // Step 3: 또다른 UpdateFC
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b00; // MWr
        buffer_hdr_rsv_i = 8'd10;
        buffer_data_rsv_i = 12'd100;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd000;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 3: UpdateFC 수행 (+10, +100)");

        // Step 4: 다시 InitFC (초기화)
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b00; // MWr
        buffer_hdr_credit_i = 8'd7;
        buffer_data_credit_i = 12'd80;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 4: InitFC 수행 (다시 초기화)");









        // is_initFC_i: 1 -> state_n: 10 -> state: 10
        // Step 5: InitFC 수행
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b01; // MWr
        buffer_hdr_credit_i = 8'd21;
        buffer_data_credit_i = 12'd310;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 5: InitFC 수행");

        // Step 6: UpdateFC 수행 - 처리한 credit 추가
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b01; // MWr
        buffer_hdr_rsv_i = 8'd6;
        buffer_data_rsv_i = 12'd60;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd00;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 6: UpdateFC 수행 (+5, +50)");

        // Step 7: 또다른 UpdateFC
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b01; // MWr
        buffer_hdr_rsv_i = 8'd20;
        buffer_data_rsv_i = 12'd200;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd000;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 7: UpdateFC 수행 (+10, +100)");

        // Step 8: 다시 InitFC (초기화)
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b01; // MWr
        buffer_hdr_credit_i = 8'd8;
        buffer_data_credit_i = 12'd90;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 8: InitFC 수행 (다시 초기화)");









        // is_initFC_i: 1 -> state_n: 10 -> state: 10
        // Step 9: InitFC 수행
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b10; // MWr
        buffer_hdr_credit_i = 8'd22;
        buffer_data_credit_i = 12'd320;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 9: InitFC 수행");

        // Step 10: UpdateFC 수행 - 처리한 credit 추가
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b10; // MWr
        buffer_hdr_rsv_i = 8'd7;
        buffer_data_rsv_i = 12'd70;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd00;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 10: UpdateFC 수행 (+5, +50)");

        // Step 11: 또다른 UpdateFC
        @(posedge clk);
        is_updateFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b10; // MWr
        buffer_hdr_rsv_i = 8'd30;
        buffer_data_rsv_i = 12'd300;
        @(posedge clk);
        buffer_hdr_rsv_i = 8'd00;
        buffer_data_rsv_i = 12'd000;
        @(posedge clk);
        is_updateFC_i = 0;

        print_state("Step 11: UpdateFC 수행 (+10, +100)");

        // Step 12: 다시 InitFC (초기화)
        @(posedge clk);
        is_initFC_i = 1;
        @(posedge clk);
        type_credit_i = 2'b10; // MWr
        buffer_hdr_credit_i = 8'd9;
        buffer_data_credit_i = 12'd100;
        @(posedge clk);

        @(posedge clk);
        is_initFC_i = 0;

        print_state("Step 12: InitFC 수행 (다시 초기화)");

        #50;
        $finish;
    end
endmodule
