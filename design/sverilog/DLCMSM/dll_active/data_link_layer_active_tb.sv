module data_link_layer_active_tb;

    // Clock & Reset
    logic clk;
    logic rst_n;

    // RX side inputs
    logic [1195:0] rx_data_i;
    logic          rx_valid_i;

    // TX side outputs
    logic [1195:0] tx_data_o;
    logic          tx_valid_o;

    // TLP inputs to TX generator
    logic [1151:0] tlp_i;
    logic          tlp_valid_i;

    // DLLP Update FC inputs
    logic [7:0]    hdr_credit_i;
    logic [11:0]   data_credit_i;
    logic [1:0]    update_type_i;
    logic          update_req_i;

    // DLLP Update FC outputs
    logic          is_updatefc_o;
    logic [1:0]    fc_type_o;
    logic [5:0]    hdr_credit_o;
    logic [11:0]   data_credit_o;

    // TLP outputs from RX
    logic [1151:0] tlp_o;
    logic          tlp_valid_o;

    // DUT instance
    data_link_layer_active dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_data_i(rx_data_i),
        .rx_valid_i(rx_valid_i),
        .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o),
        .tlp_i(tlp_i),
        .tlp_valid_i(tlp_valid_i),
        .hdr_credit_i(hdr_credit_i),
        .data_credit_i(data_credit_i),
        .update_type_i(update_type_i),
        .update_req_i(update_req_i),
        .is_updatefc_o(is_updatefc_o),
        .fc_type_o(fc_type_o),
        .hdr_credit_o(hdr_credit_o),
        .data_credit_o(data_credit_o),
        .tlp_o(tlp_o),
        .tlp_valid_o(tlp_valid_o)
    );

    // Clock generator
    always #5 clk = ~clk;

    // Task to send RX DLLP frame
    task send_rx_dllp(input [47:0] dllp);
        begin
            rx_data_i = {88'd0, dllp};
            rx_valid_i = 1;
            #10;
            rx_valid_i = 0;
            rx_data_i = 0;
        end
    endtask

    // Task to send RX TLP frame
    task send_rx_tlp(input [1195:0] dll_tlp);
        begin
            rx_data_i = dll_tlp;
            rx_valid_i = 1;
            #10;
            rx_valid_i = 0;
            rx_data_i = 0;
        end
    endtask

    // Task to send TX DLLP (Flow Control Update)
    task send_update_fc(input [7:0] hdr, input [11:0] data, input [1:0] typ);
        begin
            hdr_credit_i = hdr;
            data_credit_i = data;
            update_type_i = typ;
            update_req_i = 1;
            #10;
            update_req_i = 0;
        end
    endtask

    // Task to send TLP to TX generator
    task send_tx_tlp(input [1151:0] tlp_data);
        begin
            tlp_i = tlp_data;
            tlp_valid_i = 1;
            #10;
            tlp_valid_i = 0;
            tlp_i = 0;
        end
    endtask

    initial begin
        $display("[TB] Starting simulation");

        clk = 0;
        rst_n = 0;
        rx_data_i = 0;
        rx_valid_i = 0;
        tlp_i = 0;
        tlp_valid_i = 0;
        hdr_credit_i = 0;
        data_credit_i = 0;
        update_type_i = 0;
        update_req_i = 0;

        #20;
        rst_n = 1;
        #20;

        // RX DLLP test (CRC=0xBEEF matches hardcoded)
        send_rx_dllp(48'hBEEF_8A_00_55_11); #20;
        send_rx_dllp(48'hBEEF_8B_01_66_22); #20;
        send_rx_dllp(48'hBEEF_8C_02_77_33); #20;

        // RX TLP test (CRC = lower 32b, seq = 0)
        send_rx_tlp({12'd1,   {1152{1'b0}}, 32'hDEADBEEF}); #20;
        send_rx_tlp({12'd1,   {1152{1'b1}}, 32'hDEADBEEF}); #20;
        send_rx_tlp({12'd2,   {576{1'b0}}, {576{1'b1}}, 32'hDEADBEEF}); #20;

        // TX DLLP generator test
        send_update_fc(8'hA5, 12'hBCD, 2'b01); #20;
        send_update_fc(8'hB6, 12'hDCE, 2'b10); #20;
        send_update_fc(8'hC7, 12'hEAF, 2'b00); #20;

        // TX TLP generator test
        send_tx_tlp({1152{1'b0}}); #20;
        send_tx_tlp({ {576{1'b1}}, {576{1'b0}} }); #20;
        send_tx_tlp({ {288{1'b1}}, {576{1'b0}}, {288{1'b1}} }); #20;

        #100;

        $display("[TB] Simulation completed");
        $finish;
    end

endmodule
