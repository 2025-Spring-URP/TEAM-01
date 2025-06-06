module dll_tx_arbiter (
    input  logic          clk,
    input  logic          rst_n,

    input  logic [47:0]   dllp_i,
    input  logic          dllp_valid_i,

    input  logic [1195:0] tlp_i,
    input  logic          tlp_valid_i,

    output logic [1195:0] tx_data_o,
    output logic          tx_valid_o
);

    always_comb begin
        tx_data_o = '0;
        tx_valid_o = 1'b0;

        if (dllp_valid_i) begin
            tx_data_o[47:0] = dllp_i;
            tx_data_o[1195:48] = 88'd0;
            tx_valid_o = 1'b1;
        end
        else if (tlp_valid_i) begin
            tx_data_o[1195:0] = tlp_i;
            tx_valid_o = 1'b1;
        end
        $display("[%t] ARBITER: %h, %b", $time, tx_data_o, tx_valid_o);
    end

endmodule
