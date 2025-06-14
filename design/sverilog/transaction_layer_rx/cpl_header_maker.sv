`timescale 1ns/1ps
import PCIE_PKG::*;
    // File: cpl_header_maker.sv
    // 역할: Read Request TLP 헤더(ar_hdr_data)를 받아
    //       PCIe Read Completion 헤더(3DW)를 생성하여
    //       TX로 넘길 FIFO에 기록합니다.

    module cpl_header_maker #(
        parameter int HDR_WIDTH = 128
    )(
        input  wire                clk,
        input  wire                rst_n,

        // tlp_demux 또는 ar_fsm에서 넘어온 Read Request 헤더
        input  wire                ar_hdr_wren,
        input  wire [HDR_WIDTH-1:0] ar_hdr_data,

        // 생성된 Completion 헤더 출력
        output logic                cpl_hdr_wren,
        output logic [HDR_WIDTH-1:0] cpl_hdr_data
    );

        // 캡처된 필드
        logic [63:0] addr;
        logic [9:0]  len_dw;
        logic [9:0]  tag_dw;
        logic [6:0]  lower_addr;
        tlp_memory_req_header req_hdr;

        // ar_hdr_data를 struct로 unpack
        always_comb begin
            req_hdr = ar_hdr_data;
        end

        // 주요 필드 추출
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                addr       <= '0;
                len_dw     <= '0;
                tag_dw     <= '0;
                lower_addr <= '0;
            end else if (ar_hdr_wren) begin
                addr       <= PCIE_PKG::get_addr_from_req_hdr(req_hdr);
                len_dw     <= PCIE_PKG::get_len_dw_from_req_hdr(req_hdr);
                tag_dw     <= PCIE_PKG::get_tag_from_req_hdr(req_hdr);
                lower_addr <= PCIE_PKG::get_addr_from_req_hdr(req_hdr)[6:0];
            end
        end

        // Completion 헤더 생성 및 페이즈 생성
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                cpl_hdr_wren <= 1'b0;
                cpl_hdr_data <= '0;
            end else begin
                cpl_hdr_wren <= 1'b0;
                if (ar_hdr_wren) begin
                    // Read Completion with Data 헤더 생성
                    // 96비트 struct 반환, 하위 32비트는 패딩
                    logic [95:0] hdr96 = PCIE_PKG::create_cpl_with_data(
                        len_dw,
                        tag_dw,
                        lower_addr
                    );
                    cpl_hdr_data <= { hdr96, 32'h0000_0000 };
                    cpl_hdr_wren <= 1'b1;
                end
            end
        end

    endmodule
