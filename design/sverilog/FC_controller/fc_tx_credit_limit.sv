module fc_tx_credit_limit (
    input  logic         clk,
    input  logic         rst_n,
    input  logic [7:0]   hdr_credit_i,
    input  logic [11:0]  data_credit_i,
    input  logic         is_initFC_i,
    input  logic         is_updateFC_i,
    input  logic [1:0]   type_credit_i, // MWr, MRd, Cpl
    input  logic [1:0]   send_tlp_type_i, // MWr, MRd, Cpl
    output logic [7:0]   cl_hdr_o,
    output logic [11:0]  cl_data_o
);

    localparam MWr = 2'b00, // P (Posted)
               MRd = 2'b01, // NP (Non-posted)
               Cpl = 2'b10; // Cpl (Completion)
    localparam IDLE = 2'b00,
               upFC = 2'b01;

    logic [1:0] state, state_n;
    logic [7:0] cl_ph, cl_ph_n;
    logic [7:0] cl_nph, cl_nph_n;
    logic [7:0] cl_cplh, cl_cplh_n;
    logic [11:0] cl_pd, cl_pd_n;
    logic [11:0] cl_cpld, cl_cpld_n;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            cl_ph <= 8'h00;
            cl_nph <= 8'h00;
            cl_cplh <= 8'h00;
            cl_pd <= 12'h000;
            cl_cpld <= 12'h000;
        end
        else begin
            state <= state_n;
            cl_ph <= cl_ph_n;
            cl_nph <= cl_nph_n;
            cl_cplh <= cl_cplh_n;
            cl_pd <= cl_pd_n;
            cl_cpld <= cl_cpld_n;
        end
        $display("%0t: cl_ph=%h, cl_nph=%h, cl_cplh=%h, cl_pd=%h, cl_cpld=%h", $time, cl_ph, cl_nph, cl_cplh, cl_pd, cl_cpld);
        $display("%0t: is_initFC_i=%b, is_updateFC_i=%b, type_credit_i=%b", $time, is_initFC_i, is_updateFC_i, type_credit_i);
        $display("%0t: state=%b, state_n=%b", $time, state, state_n);
    end

    always_comb begin
        state_n = state;
        cl_ph_n = cl_ph;
        cl_nph_n = cl_nph;
        cl_cplh_n = cl_cplh;
        cl_pd_n = cl_pd;
        cl_cpld_n = cl_cpld;

        case(state)
            IDLE: begin
                if(is_initFC_i || is_updateFC_i) begin
                    state_n = upFC;
                end
                else begin
                    state_n = IDLE;
                end
            end
            upFC: begin
                case (type_credit_i)
                    MWr : begin
                        cl_ph_n = hdr_credit_i;
                        cl_pd_n = data_credit_i;
                    end
                    MRd : begin
                        cl_nph_n = hdr_credit_i;
                    end
                    Cpl : begin
                        cl_cplh_n = hdr_credit_i;
                        cl_cpld_n = data_credit_i;
                    end
                    default: begin
                        cl_ph_n = cl_ph;
                        cl_nph_n = cl_nph;
                        cl_cplh_n = cl_cplh;
                        cl_pd_n = cl_pd;
                        cl_cpld_n = cl_cpld;
                    end
                endcase
                state_n = IDLE;
            end
            default: begin
                state_n = IDLE;
            end
        endcase
    end

    assign cl_hdr_o  =  (send_tlp_type_i == MWr) ? cl_ph   :
                        (send_tlp_type_i == MRd) ? cl_nph  :
                        (send_tlp_type_i == Cpl) ? cl_cplh : 8'd0;
    assign cl_data_o =  (send_tlp_type_i == MWr) ? cl_pd   :
                        (send_tlp_type_i == MRd) ? 12'd0   :
                        (send_tlp_type_i == Cpl) ? cl_cpld : 12'd0;
endmodule