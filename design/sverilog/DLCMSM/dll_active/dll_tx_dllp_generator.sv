module dll_tx_dllp_generator (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [1:0]  dlc_state_i,

    input  logic [7:0]  hdr_credit_i,
    input  logic [11:0] data_credit_i,
    input  logic [1:0]  update_type_i,
    input  logic        update_req_i,

    output logic [47:0] dll_dllp_o,
    output logic        dll_dllp_valid_o
);
    localparam IDLE = 1'b0,
               GENE = 1'b1;
    localparam DLC_DL_ACTIVE = 2'b11;

    logic state, state_n;
    logic [47:0] dllp, dllp_n;
    logic dllp_valid, dllp_valid_n;
    logic [3:0] dllp_type, dllp_type_n;
    logic [7:0] hdr_credit, hdr_credit_n;
    logic [11:0] data_credit, data_credit_n;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dllp <= 48'd0;
            dllp_valid <= 1'b0;
            dllp_type <= 0;
            hdr_credit <= 0;
            data_credit <= 0;
        end else begin
            state <= state_n;
            dllp <= dllp_n;
            dllp_valid <= dllp_valid_n;
            dllp_type <= dllp_type_n;
            hdr_credit <= hdr_credit_n;
            data_credit <= data_credit_n;
        end
    end

    always_comb begin
        state_n = state;
        dllp_n = dllp;
        dllp_valid_n = 1'b0;
        dllp_type_n = dllp_type;
        hdr_credit_n = hdr_credit;
        data_credit_n = data_credit;

        case (state)
            IDLE: begin
                if (dlc_state_i == DLC_DL_ACTIVE && update_req_i) begin
                    hdr_credit_n = hdr_credit_i;
                    data_credit_n = data_credit_i;
                    case (update_type_i)
                        2'b00: dllp_type_n = 4'b1000;
                        2'b01: dllp_type_n = 4'b1001;
                        2'b10: dllp_type_n = 4'b1010;
                        default: dllp_type_n = 4'b0000;
                    endcase
                    state_n = GENE;
                end
            end
            GENE: begin
                //BYTE 0
                dllp_n[7:4]   = dllp_type;
                dllp_n[3]     = 1'b0;
                dllp_n[2:0]   = 3'b000; 

                //BYTE 1
                dllp_n[15:14] = 2'b00;
                dllp_n[13:8]  = hdr_credit_n[7:2];

                //BYTE 2
                dllp_n[23:22] = hdr_credit_n[1:0];
                dllp_n[21:20] = 2'b00;
                dllp_n[19:16] = data_credit_n[11:8];

                //BYTE 3
                dllp_n[31:24] = data_credit_n[7:0];

                //BYTE 5,6
                dllp_n[47:32] = 16'hBEEF; // TODO: Replace with actual CRC-16 calculation

                dllp_valid_n = 1'b1;
                state_n = IDLE;
            end
        endcase
    end

    assign dll_dllp_o = dllp;
    assign dll_dllp_valid_o = dllp_valid;

endmodule
