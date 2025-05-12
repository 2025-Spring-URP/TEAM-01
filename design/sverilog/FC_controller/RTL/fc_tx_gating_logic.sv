module fc_tx_gating_logic (
    input  logic [7:0]   cl_hdr_i,
    input  logic [11:0]  cl_data_i,
    input  logic [7:0]   cc_hdr_i,
    input  logic [11:0]  cc_data_i,
    input  logic [1:0]   send_tlp_type_i, // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic [7:0]   send_tlp_size_i, // Payload 크기 (DW 단위)
    output logic [7:0]   required_hdr_credit_o,
    output logic [11:0]  required_data_credit_o,
    output logic         gating_pass_o
);
    
    logic [7:0] required_hdr_credit;
    logic [11:0] required_data_credit;
    logic [7:0] hdr_cr;
    logic [11:0] data_cr;

    always_comb begin
        case (send_tlp_type_i)
            2'b00: begin // MWr
                required_hdr_credit = 1;
                required_data_credit = (send_tlp_size_i + 3) >> 2; // DW 단위로 변환
            end
            2'b01: begin // MRd
                required_hdr_credit = 1;
                required_data_credit = 0;
            end
            2'b10: begin // Cpl
                required_hdr_credit = 1;
                required_data_credit = (send_tlp_size_i + 3) >> 2;
            end
            default: begin
                required_hdr_credit = 8'h00;
                required_data_credit = 12'h000;
            end
        endcase

        hdr_cr  = (cl_hdr_i - (cc_hdr_i + required_hdr_credit)) & 8'hFF;   // mod 256
        data_cr = (cl_data_i - (cc_data_i + required_data_credit)) & 12'hFFF; // mod 4096

        gating_pass_o = (hdr_cr <= 8'h80) && (data_cr <= 12'h800);
        required_hdr_credit_o = required_hdr_credit;
        required_data_credit_o = required_data_credit;
    end
endmodule