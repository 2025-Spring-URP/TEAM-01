module dll_rx_tlp_checker (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [1195:0] dll_tlp_i,
    input  logic          dll_tlp_valid_i,

    output logic [1151:0] tlp_o,
    output logic          tlp_valid_o
);

    localparam IDLE  = 1'b0,
               CHECK = 1'b1;

    logic state, state_n;

    logic [1195:0] dll_tlp_r, dll_tlp_r_n;
    logic [11:0]   sequence_number, sequence_number_n;
    logic [11:0]   expected_sequence, expected_sequence_n;
    logic [31:0]   lcrc_calc;
    logic          tlp_valid, tlp_valid_n;

    // CRC 계산 함수
    function automatic [31:0] crc32;
        input [1151:0] data;
        integer i;
        reg [31:0] crc;
        begin
            crc = 32'hFFFFFFFF;
            for (i = 1151; i >= 0; i = i - 1)
                crc = {crc[30:0], 1'b0} ^ (crc[31] ^ data[i] ? 32'h04C11DB7 : 32'h0);
            crc32 = crc;
        end
    endfunction

    assign lcrc_calc = crc32(dll_tlp_r[1183:32]);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= IDLE;
            dll_tlp_r         <= '0;
            sequence_number   <= 12'd0;
            expected_sequence <= 12'd0;
            tlp_valid         <= 1'b0;
        end else begin
            state             <= state_n;
            dll_tlp_r         <= dll_tlp_r_n;
            sequence_number   <= sequence_number_n;
            expected_sequence <= expected_sequence_n;
            tlp_valid         <= tlp_valid_n;
        end
    end

    always_comb begin
        state_n             = state;
        dll_tlp_r_n         = dll_tlp_r;
        sequence_number_n   = sequence_number;
        expected_sequence_n = expected_sequence;
        tlp_valid_n         = 1'b0;

        case (state)
            IDLE: begin
                if (dll_tlp_valid_i) begin
                    dll_tlp_r_n         = dll_tlp_i;
                    sequence_number_n   = dll_tlp_i[1195:1184];
                    state_n             = CHECK;
                end
            end

            CHECK: begin
                if (dll_tlp_r[31:0] == lcrc_calc &&
                    sequence_number == expected_sequence) begin
                    tlp_valid_n         = 1'b1;
                    expected_sequence_n = expected_sequence + 12'd1;
                end
                state_n = IDLE;
            end
        endcase
    end

    assign tlp_o        = dll_tlp_r[1183:32];
    assign tlp_valid_o  = tlp_valid;

endmodule
