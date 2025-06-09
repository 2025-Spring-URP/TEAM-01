module dll_rx_packet_demux (
    input  logic          clk,
    input  logic          rst_n,

    input  logic [1:0]    dlc_state_i,

    input  logic [1195:0] rx_data_i,
    input  logic          rx_valid_i,

    output logic [47:0]   dllp_o,
    output logic          dllp_valid_o,

    output logic [1195:0] tlp_o,
    output logic          tlp_valid_o,

    output logic          initfc1_done_o,
    output logic          initfc2_done_o

);
    localparam DLC_DL_INIT1  = 2'b01; 
    localparam DLC_DL_INIT2  = 2'b10;
    localparam DLC_DL_ACTIVE = 2'b11;
    localparam INITFC1_CPL   = 4'b0110;
    localparam INITFC2_CPL   = 4'b1110;

    always_comb begin
        dllp_o         = '0;
        dllp_valid_o   = 1'b0;
        tlp_o          = '0;
        tlp_valid_o    = 1'b0;
        initfc1_done_o = 1'b0;
        initfc2_done_o = 1'b0;

        if (dlc_state_i == DLC_DL_ACTIVE && rx_valid_i) begin
            if (rx_data_i[1195:48] == '0) begin
                dllp_o       = rx_data_i[47:0];
                dllp_valid_o = 1'b1;
                $display("UpdateFC. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            end
            else begin
                tlp_o        = rx_data_i[1195:0];
                tlp_valid_o  = 1'b1;
                $display("TLP. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            end
        end
        else if (dlc_state_i == DLC_DL_INIT1 && rx_valid_i && rx_data_i[1195:48] == '0) begin
            dllp_o       = rx_data_i[47:0];
            dllp_valid_o = 1'b1;
            $display("INIT1. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            if (rx_data_i[7:4] == INITFC1_CPL) begin
                initfc1_done_o = 1'b1;  // 한 사이클만 유효
                $display("INITFC1_CPL. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            end
        end
        else if (dlc_state_i == DLC_DL_INIT2 && rx_valid_i && rx_data_i[1195:48] == '0) begin
            dllp_o       = rx_data_i[47:0];
            dllp_valid_o = 1'b1;
            $display("INIT2. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            if (rx_data_i[7:4] == INITFC2_CPL) begin
                initfc2_done_o = 1'b1;
                $display("INITFC2_CPL. [%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
            end
        end
        $display("[%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
    end

   



endmodule