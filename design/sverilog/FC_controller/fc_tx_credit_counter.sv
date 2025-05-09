module fc_tx_credit_counter (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         is_initFC_i,
    input  logic         send_tlp_req_i,
    input  logic [1:0]   send_tlp_type_i, // 2'b00: MWr, 2'b01: MRd, 2'b10: Cpl
    input  logic         gating_pass_i,
    input  logic [7:0]   required_hdr_credit_i,
    input  logic [11:0]  required_data_credit_i,
    output logic [7:0]   cc_hdr_o,
    output logic [11:0]  cc_data_o,
    output logic         send_tlp_grant_o
);

    localparam MWr = 2'b00, // P (Posted)
               MRd = 2'b01, // NP (Non-posted)
               Cpl = 2'b10; // Cpl (Completion)
    localparam IDLE = 2'b00,
               PASS = 2'b01, 
               inFC = 2'b10;

    logic [1:0] state, state_n;
    logic [7:0] cc_ph, cc_ph_n;
    logic [7:0] cc_nph, cc_nph_n;
    logic [7:0] cc_cplh, cc_cplh_n;
    logic [11:0] cc_pd, cc_pd_n;
    logic [11:0] cc_cpld, cc_cpld_n;
    logic send_tlp_grant, send_tlp_grant_n;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            cc_ph <= 8'h00;
            cc_nph <= 8'h00;
            cc_cplh <= 8'h00;
            cc_pd <= 12'h000;
            cc_cpld <= 12'h000;
            send_tlp_grant <= 1'b0;
        end
        else begin
            state <= state_n;
            cc_ph <= cc_ph_n;
            cc_nph <= cc_nph_n;
            cc_cplh <= cc_cplh_n;
            cc_pd <= cc_pd_n;
            cc_cpld <= cc_cpld_n;
            send_tlp_grant <= send_tlp_grant_n;
        end
        $display("%0t: cc_ph=%h, cc_nph=%h, cc_cplh=%h, cc_pd=%h, cc_cpld=%h", $time, cc_ph, cc_nph, cc_cplh, cc_pd, cc_cpld);
        $display("%0t: state=%b, state_n=%b, send_tlp_req_i=%b, gating_pass_i=%b", $time, state, state_n, send_tlp_req_i, gating_pass_i);
        $display("----------------------------------------------------------");
    end

    always_comb begin
        state_n = state;
        cc_ph_n = cc_ph;
        cc_nph_n = cc_nph;
        cc_cplh_n = cc_cplh;
        cc_pd_n = cc_pd;
        cc_cpld_n = cc_cpld;

        case(state)
            IDLE: begin
                if (is_initFC_i) begin
                    state_n = inFC;
                end
                else if (send_tlp_req_i && gating_pass_i) begin
                    state_n = PASS;
                end
                else if (send_tlp_req_i == 0 || gating_pass_i == 0) begin
                    send_tlp_grant_n = 1'b0;
                    state_n = IDLE;
                end
                else begin
                    state_n = IDLE;
                end
            end
            inFC: begin
                cc_ph_n = 8'h00;
                cc_pd_n = 12'h000;
                cc_nph_n = 8'h00;
                cc_cplh_n = 8'h00;
                cc_cpld_n = 12'h000;
                state_n = IDLE;
            end
            PASS: begin
                case (send_tlp_type_i)
                    MWr: begin // MWr
                        cc_ph_n = cc_ph + required_hdr_credit_i;
                        cc_pd_n = cc_pd + required_data_credit_i;
                    end
                    MRd: begin // MRd
                        cc_nph_n = cc_nph + required_hdr_credit_i;
                    end
                    Cpl: begin // Cpl
                        cc_cplh_n = cc_cplh + required_hdr_credit_i;
                        cc_cpld_n = cc_cpld + required_data_credit_i;
                    end
                    default: begin
                        state_n = IDLE;
                    end
                endcase
                send_tlp_grant_n = 1'b1;
                state_n = IDLE;
            end
            default: begin
                state_n = IDLE;
            end
        endcase
    end

    assign cc_hdr_o  =  (send_tlp_type_i == MWr) ? cc_ph   :
                        (send_tlp_type_i == MRd) ? cc_nph  :
                        (send_tlp_type_i == Cpl) ? cc_cplh : 8'd0;
    assign cc_data_o =  (send_tlp_type_i == MWr) ? cc_pd   :
                        (send_tlp_type_i == MRd) ? 12'd0   :
                        (send_tlp_type_i == Cpl) ? cc_cpld : 12'd0;
    assign send_tlp_grant_o = send_tlp_grant;
endmodule