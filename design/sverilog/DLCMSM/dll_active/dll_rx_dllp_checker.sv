module dll_rx_dllp_checker (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [47:0] dllp_i,
    input  logic        dllp_valid_i,

    output logic        is_updatefc_o,
    output logic [1:0]  fc_type_o,
    output logic [5:0]  hdr_credit_o,
    output logic [11:0] data_credit_o
);

    localparam IDLE  = 1'b0,
               CHECK = 1'b1;

    logic state, state_n;

    logic [47:0] dllp_r, dllp_r_n;
    logic [1:0]  fc_type, fc_type_n;
    logic        is_updatefc, is_updatefc_n;
    logic [5:0]  hdr_credit, hdr_credit_n;
    logic [11:0] data_credit, data_credit_n;

    logic [15:0] crc_calc;

    function automatic [15:0] crc16;
        input [31:0] data;
        integer i;
        reg [15:0] crc;
        begin
            crc = 16'hFFFF;
            for (i = 31; i >= 0; i = i - 1) begin
                crc = {crc[14:0], 1'b0} ^ (crc[15] ^ data[i] ? 16'h1021 : 16'h0000);
            end
            crc16 = crc;
        end
    endfunction

    assign crc_calc = crc16(dllp_r[31:0]);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            dllp_r        <= '0;
            fc_type       <= '0;
            is_updatefc   <= 1'b0;
            hdr_credit    <= '0;
            data_credit   <= '0;
        end else begin
            state         <= state_n;
            dllp_r        <= dllp_r_n;
            fc_type       <= fc_type_n;
            is_updatefc   <= is_updatefc_n;
            hdr_credit    <= hdr_credit_n;
            data_credit   <= data_credit_n;
        end
    end

    always_comb begin
        state_n         = state;
        dllp_r_n        = dllp_r;
        fc_type_n       = fc_type;
        is_updatefc_n   = 1'b0;
        hdr_credit_n    = hdr_credit;
        data_credit_n   = data_credit;

        case (state)
            IDLE: begin
                if (dllp_valid_i) begin
                    dllp_r_n = dllp_i;
                    state_n = CHECK;
                end
            end

            CHECK: begin
                if (dllp_r[47:32] == crc_calc) begin
                    if (dllp_r[7:4] == 4'b1000 ||
                        dllp_r[7:4] == 4'b1001 ||
                        dllp_r[7:4] == 4'b1010) begin
                        case (dllp_r[7:4])
                            4'b1000: fc_type_n = 2'b00;
                            4'b1001: fc_type_n = 2'b01;
                            4'b1010: fc_type_n = 2'b10;
                            default: fc_type_n = 2'b00;
                        endcase
                        is_updatefc_n = 1'b1;
                        hdr_credit_n  = dllp_r[13:8];
                        data_credit_n = {dllp_r[19:16], dllp_r[31:24]};
                    end
                end

                state_n = IDLE;
            end
        endcase
    end

    assign is_updatefc_o = is_updatefc;
    assign fc_type_o     = fc_type;
    assign hdr_credit_o  = hdr_credit;
    assign data_credit_o = data_credit;

endmodule
