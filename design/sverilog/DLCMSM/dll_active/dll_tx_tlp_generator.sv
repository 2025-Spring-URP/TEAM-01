module dll_tx_tlp_generator (
    input logic clk,
    input logic rst_n,

    input logic [1:0] dlc_state_i,
    
    input logic [1151:0] tlp_i,
    input logic tlp_valid_i,

    output logic [1195:0] dll_tlp_o,
    output logic dll_tlp_valid_o
);
    localparam IDLE = 1'b0,
               GENE = 1'b1;
    localparam DLC_DL_ACTIVE = 2'b11;

    logic state, state_n;
    logic [11:0] sequence_number, sequence_number_n;
    logic [31:0] lcrc, lcrc_n;
    logic [1151:0] tlp, tlp_n;
    logic [1195:0] dll_tlp, dll_tlp_n;
    logic dll_tlp_valid, dll_tlp_valid_n;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            sequence_number <= 0;
            lcrc <= 0;
            tlp <= 0;
            dll_tlp <= 0;
            dll_tlp_valid <= 0;
        end
        else begin
            state <= state_n;
            sequence_number <= sequence_number_n;
            lcrc <= lcrc_n;
            tlp <= tlp_n;
            dll_tlp <= dll_tlp_n;
            dll_tlp_valid <= dll_tlp_valid_n;
        end
    end

    always_comb begin
        state_n = state;
        sequence_number_n = sequence_number;
        lcrc_n = lcrc;
        tlp_n = tlp;
        dll_tlp_n = dll_tlp;
        dll_tlp_valid_n = 1'b0;

        case (state)
            IDLE: begin
                if (dlc_state_i == DLC_DL_ACTIVE && tlp_valid_i) begin
                    tlp_n = tlp_i;
                    lcrc_n = 32'hDEADBEEF;
                    state_n = GENE;
                end
            end
            GENE: begin
                dll_tlp_n[1195:1184] = sequence_number;
                dll_tlp_n[1183:32] = tlp;
                dll_tlp_n[31:0] = lcrc;
                dll_tlp_valid_n = 1'b1;
                sequence_number_n = sequence_number + 1'b1;
                state_n = IDLE;
            end
        endcase
        $display("[%t] TLP_GEN: %h, %b", $time, dll_tlp_o, dll_tlp_valid_o);
    end

    assign dll_tlp_o = dll_tlp;
    assign dll_tlp_valid_o = dll_tlp_valid;

endmodule
