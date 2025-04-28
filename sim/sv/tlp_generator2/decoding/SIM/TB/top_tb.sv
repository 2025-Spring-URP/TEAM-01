`timescale 1ns/1ps
import PCIE_PKG::*;

module top_tb_random;

    parameter DATA_WIDTH = 256;
    parameter CHUNK_MAX_BEATS = 4;

    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        #20 rst_n = 1;
    end

    // DUT 연결 신호
    logic awvalid_in, awready_out;
    logic [3:0]  awid_in;
    logic [31:0] awaddr_in;
    logic [7:0]  awlen_in;
    logic [2:0]  awsize_in;
    logic [1:0]  awburst_in;

    logic wvalid_in, wready_out;
    logic [DATA_WIDTH-1:0] wdata_in;
    logic wlast_in;

    logic [31:0] out_addr;
    logic [7:0]  out_length;
    logic [15:0] out_bdf;
    logic        out_is_memwrite;
    logic [DATA_WIDTH*4-1:0] out_wdata;
    logic        out_valid;
    logic        out_ready = 1;

    tlp_memory_req_header tlp_hdr_out;
    logic [DATA_WIDTH*4-1:0] tlp_payload_out;
    logic [DATA_WIDTH*4 + $bits(tlp_memory_req_header)-1 : 0] tlp_out;
    logic tlp_valid;

    logic [DATA_WIDTH*4-1:0] ref_concat;

    dummy_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .awvalid_in(awvalid_in),
        .awready_out(awready_out),
        .awid_in(awid_in),
        .awaddr_in(awaddr_in),
        .awlen_in(awlen_in),
        .awsize_in(awsize_in),
        .awburst_in(awburst_in),

        .wvalid_in(wvalid_in),
        .wready_out(wready_out),
        .wdata_in(wdata_in),
        .wlast_in(wlast_in),

        .out_addr(out_addr),
        .out_length(out_length),
        .out_bdf(out_bdf),
        .out_is_memwrite(out_is_memwrite),
        .out_wdata(out_wdata),
        .out_valid(out_valid),
        .out_ready(out_ready),

        .tlp_hdr_out(tlp_hdr_out),
        .tlp_payload_out(tlp_payload_out),
        .tlp_out(tlp_out),
        .tlp_valid(tlp_valid)
    );

    // reference payload queue
    tlp_memory_req_header ref_hdr;

    task automatic generate_write_and_check(input int test_id);
        logic [31:0] addr = $urandom & 32'hFFFF_FFC0; // 64B align
        logic [7:0] burst_len = 4; // 고정
        logic [2:0] awsize = 3'd5; // 32B (2^5)
        logic [1:0] awburst = 2'b01;
        logic [15:0] bdf = 16'h0002;
        logic [DATA_WIDTH-1:0] ref_payload [CHUNK_MAX_BEATS];

        // 1. address burst
        awvalid_in <= 1;
        awaddr_in  <= addr;
        awlen_in   <= burst_len - 1;
        awsize_in  <= awsize;
        awburst_in <= awburst;
        awid_in    <= 0;

        @(posedge clk);
        while (!awready_out) @(posedge clk);
        awvalid_in <= 0;

        // 2. data burst
        for (int i = 0; i < burst_len; i++) begin
            wvalid_in <= 1;
            wlast_in <= (i == burst_len - 1);
            ref_payload[i] = $urandom;
            wdata_in <= ref_payload[i];
            @(posedge clk);
            while (!wready_out) @(posedge clk);
        end
        wvalid_in <= 0;
        wlast_in <= 0;

        // 3. reference header 생성
        ref_hdr = create_header(addr, burst_len, bdf);

        // 4. 결과 대기 후 비교
        wait (tlp_valid);

        if (tlp_hdr_out.fmt     !== ref_hdr.fmt     ||
            tlp_hdr_out.tlp_type!== ref_hdr.tlp_type||
            tlp_hdr_out.length_l!== ref_hdr.length_l||
            tlp_hdr_out.address !== ref_hdr.address ||
            tlp_hdr_out.requester_id !== ref_hdr.requester_id) begin
            $display("[TEST %0d] ❌ Header Mismatch!", test_id);
            $display("  Expected: %p", ref_hdr);
            $display("  Got     : %p", tlp_hdr_out);
            $fatal;
        end
        else begin
            $display("[TEST %0d] ✅ Header Match", test_id);
        end

        // payload 비교
        ref_concat = {ref_payload[0], ref_payload[1], ref_payload[2], ref_payload[3]};
        if (tlp_payload_out !== ref_concat) begin
            $display("[TEST %0d] ❌ Payload Mismatch!", test_id);
            $display("  Expected: %x", ref_concat);
            $display("  Got     : %x", tlp_payload_out);
            $fatal;
        end
        
        else begin
            $display("[TEST %0d] ✅ Payload Match", test_id);
        end

        $display("[TEST %0d] ✅ PASS", test_id);
    endtask

    initial begin
        awvalid_in = 0; wvalid_in = 0; wlast_in = 0;
        @(posedge rst_n);
        repeat (5) @(posedge clk);

        // 10개의 랜덤 테스트
        for (int i = 0; i < 10; i++) begin
            generate_write_and_check(i);
            repeat (5) @(posedge clk);
        end

        $display("🎉 All TLP tests PASSED!");
        $finish;
    end

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, top_tb_random); // tb은 최상위 모듈 이름
    end

endmodule