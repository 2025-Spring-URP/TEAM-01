import PCIE_PKG::*;

module pcie_tlp_gen #(
    parameter ID_WIDTH        = 4,
    parameter ADDR_WIDTH      = 32,
    parameter DATA_WIDTH      = 256,
    parameter CHUNK_MAX_BEATS = 4
)(
    input  logic                        clk,
    input  logic                        rst_n,

    // Write 요청 (디코더로부터 입력)
    input  logic [ADDR_WIDTH-1:0]       in_w_addr,
    input  logic [7:0]                  in_w_length,
    input  logic [15:0]                 in_w_bdf,
    input  logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] in_w_data,
    input  logic                        in_w_valid,
    output logic                        in_w_ready,

    // Read 요청 (디코더로부터 입력)
    input  logic [ADDR_WIDTH-1:0]       in_r_addr,
    input  logic [7:0]                  in_r_length,
    input  logic                        in_r_valid,
    output logic                        in_r_ready,

    // 생성된 PCIe TLP 출력
    output tlp_memory_req_header        tlp_hdr_out,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS-1:0] tlp_payload_out,
    output logic [DATA_WIDTH*CHUNK_MAX_BEATS + $bits(tlp_memory_req_header)-1:0] tlp_out,
    output logic                        tlp_valid
);

    //----------------------------------------------------------------------
    // 내부 제어 신호
    //----------------------------------------------------------------------
    logic out_ready;  // 요청 수락 가능 여부

    // write / read 모두 공통 ready 핸들링
    assign in_w_ready = out_ready;
    assign in_r_ready = out_ready;

    //----------------------------------------------------------------------
    // 메인 시퀀스 로직
    //----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlp_valid <= 1'b0;
            out_ready <= 1'b1;
        end else begin
            if (out_ready && in_w_valid) begin
                // Write 요청 처리
                tlp_hdr_out     <= create_w_header(in_w_addr, in_w_length);
                tlp_payload_out <= in_w_data;
                tlp_valid       <= 1'b1;
                out_ready       <= 1'b0;
            end else if (out_ready && in_r_valid) begin
                // Read 요청 처리
                tlp_hdr_out     <= create_r_header(in_r_addr, in_r_length);
                tlp_payload_out <= '0;  // Read는 payload 없음
                tlp_valid       <= 1'b1;
                out_ready       <= 1'b0;
            end else if (tlp_valid) begin
                // TLP 전송 완료 후 ready 복구
                tlp_valid <= 1'b0;
                out_ready <= 1'b1;
            end
        end
    end

    //----------------------------------------------------------------------
    // 헤더와 Payload를 합쳐서 최종 TLP 패킷 생성
    //----------------------------------------------------------------------
    always_comb begin
        tlp_out = {tlp_hdr_out, tlp_payload_out};
    end

endmodule
