module dll_rx_packet_demux (
    input  logic          clk,
    input  logic          rst_n,

    input  logic [1:0]    dlc_state_i,

    input  logic [1195:0] rx_data_i,
    input  logic          rx_valid_i,

    output logic [47:0]   dllp_o,
    output logic          dllp_valid_o,

    output logic [1195:0] tlp_o,
    output logic          tlp_valid_o
);
    localparam DLC_DL_ACTIVE = 2'b11;

    always_comb begin
        dllp_o        = '0;
        dllp_valid_o  = 1'b0;
        tlp_o         = '0;
        tlp_valid_o   = 1'b0;

        if (dlc_state_i == DLC_DL_ACTIVE && rx_valid_i) begin
            if (rx_data_i[1195:48] == 88'd0) begin
                dllp_o       = rx_data_i[47:0];
                dllp_valid_o = 1'b1;
            end
            else begin
                tlp_o        = rx_data_i[1195:0];
                tlp_valid_o  = 1'b1;
            end
        end
        $display("[%t] DEMUX: %h, %b, %h, %b", $time, tlp_o, tlp_valid_o, dllp_o, dllp_valid_o);
    end
endmodule
