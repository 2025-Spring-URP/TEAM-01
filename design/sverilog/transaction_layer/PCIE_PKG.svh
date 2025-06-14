// Copyright Sungkyunkwan University
// Author: Sanghyun Park <psh2018314072@gmail.com>
// Description:

// Follows PCIe gen5 specification 1.1

`ifndef __PCIE_PKG_SVH__
`define __PCIE_PKG_SVH__

package PCIE_PKG;


    // PCIe constants
    localparam  ADDR_WIDTH                  = 64;
    localparam  LANE_COUNT                  = 4;
    localparam  PIPE_DATA_WIDTH             = 256; //32B
    localparam  MAX_PAYLOAD_SIZE            = 128;
    localparam  MAX_READ_REQ_SIZE           = 512;
    localparam  READ_COMPLETION_BOUNDARY    = 64;
    /*
    * TODO:
    */

    
    // 메모리 요청용 TLP 헤더 포맷
    typedef struct packed {
        // Header 16B
        logic   [5:0]               addr_l;
        logic   [1:0]               reserved;
        logic   [23:0]              addr_m;
        logic   [31:0]              addr_h;
        logic   [7:0]               byte_enable;
        logic   [7:0]               tag_l;
        logic   [15:0]              requester_id;

        logic   [7:0]               length_l;
        logic                       td;
        logic                       ep;
        logic   [1:0]               attr_l;
        logic   [1:0]               at;
        logic   [1:0]               length_h;
        logic                       tag_h;
        logic   [2:0]               tc;
        logic                       tag_m;
        logic                       attr_h;
        logic                       ln;
        logic                       th;
        logic   [2:0]               fmt;
        logic   [4:0]               tlp_type;
    } tlp_memory_req_header;


    // Memory Write 요청용 헤더 생성 함수
    function automatic tlp_memory_req_header create_w_header(
        input logic [63:0] addr,
        input logic [9:0]  length
    );
        tlp_memory_req_header hdr;

        // 포맷: 4DW + 데이터
        hdr.fmt       = 3'b011;
        hdr.tlp_type  = 5'b00000;   // Memory Write

        // 기본 세팅 (특수 기능 미사용)
        hdr.tag_h     = 1'b0;
        hdr.tc        = 3'b000;
        hdr.tag_m     = 1'b0;
        hdr.attr_h    = 1'b0;
        hdr.ln        = 1'b0;
        hdr.th        = 1'b0;

        hdr.td        = 1'b0;
        hdr.ep        = 1'b0;
        hdr.attr_l    = 2'b00;
        hdr.at        = 2'b00;

        hdr.reserved  = 2'b00;

        // 길이 설정
        hdr.length_h  = length[9:8];
        hdr.length_l  = length[7:0];

        // 요청자 ID, 태그 등 설정
        hdr.requester_id = 16'h0200;
        hdr.tag_l         = 8'h00;
        hdr.byte_enable = 8'b11111111;

        // 주소 (32비트 기준, 4B 정렬)
        hdr.addr_h = {addr[39:32], addr[47:40], addr[55:48], addr[63:56]};
        hdr.addr_m = {addr[15:8], addr[23:16], addr[31:24]};
        hdr.addr_l = addr[7:2];

        return hdr;
    endfunction


    // Memory Read 요청용 헤더 생성 함수
    function automatic tlp_memory_req_header create_r_header(
        input logic [63:0] addr,
        input logic [9:0]  length
        
    );
        tlp_memory_req_header hdr;

        // 포맷: 4DW + 데이터
        hdr.fmt       = 3'b001;
        hdr.tlp_type  = 5'b00000;  // Memory read

        // 기본 세팅 (특수 기능 미사용)
        hdr.tag_h     = 1'b0;
        hdr.tc        = 3'b000;
        hdr.tag_m     = 1'b0;
        hdr.attr_h    = 1'b0;
        hdr.ln        = 1'b0;
        hdr.th        = 1'b0;

        hdr.td        = 1'b0;
        hdr.ep        = 1'b0;
        hdr.attr_l    = 2'b00;
        hdr.at        = 2'b00;

        hdr.reserved  = 2'b00;

        // 길이 설정
        hdr.length_h  = length[9:8];
        hdr.length_l  = length[7:0];

        // 요청자 ID, 태그 등 설정
        hdr.requester_id = 16'h0200;
        hdr.tag_l        = 8'h00;
        hdr.byte_enable = 8'b11111111;

        // 주소 (32비트 기준, 4B 정렬)
        hdr.addr_h = {addr[39:32], addr[47:40], addr[55:48], addr[63:56]};
        hdr.addr_m = {addr[15:8], addr[23:16], addr[31:24]};
        hdr.addr_l = addr[7:2];

        return hdr;
    endfunction


    // Completion (Cpl) 패킷 헤더 타입
    typedef struct packed {
        // [95]          MSB
        logic                reserved;       
        logic   [6:0]        lower_addr;     
        logic   [7:0]        tag;            
        logic   [15:0]       requester_id;   

        logic   [7:0]        byte_count_l;   
        logic   [2:0]        cpl_status;     
        logic                bcm;            
        logic   [3:0]        byte_count_h;   
        logic   [15:0]       completer_id;   

        // [31:0] : 공통 TLP 헤더
        logic   [7:0]        length_l;       
        logic                td;             
        logic                ep;             
        logic   [1:0]        attr_l;         
        logic   [1:0]        at;             
        logic   [1:0]        length_h;       
        logic                tag_h;          
        logic   [2:0]        tc;             
        logic                tag_m;          
        logic                attr_h;         
        logic                ln;             
        logic                th;             
        logic   [2:0]        fmt;            
        logic   [4:0]        tlp_type;       
    } tlp_cpl_hdr_t;

    // Completion 헤더 생성 함수
    function automatic tlp_cpl_hdr_t gen_tlp_cplx_hdr(
        input logic [2:0]  fmt,
        input logic [4:0]  tlp_type,
        input logic [2:0]  tc,
        input logic        ln,
        input logic        th,
        input logic        td,
        input logic        ep,
        input logic [2:0]  attr,
        input logic [1:0]  at,
        input logic [9:0]  length,
        input logic [15:0] completer_id,
        input logic [2:0]  cpl_status,
        input logic        bcm,
        input logic [11:0] byte_cnt,
        input logic [15:0] requester_id,
        input logic [9:0]  tag,
        input logic [6:0]  lower_addr,
        input logic        reserved_in
    );
        tlp_cpl_hdr_t hdr;

        hdr.fmt            = fmt;
        hdr.tlp_type       = tlp_type;
        hdr.tc             = tc;
        hdr.ln             = ln;
        hdr.th             = th;
        hdr.td             = td;
        hdr.ep             = ep;
        hdr.attr_h         = attr[2];
        hdr.attr_l         = attr[1:0];
        hdr.at             = at;
        hdr.length_h       = length[9:8];
        hdr.length_l       = length[7:0];
        hdr.completer_id   = completer_id;
        hdr.cpl_status     = cpl_status;
        hdr.bcm            = bcm;
        hdr.byte_count_h   = byte_cnt[11:8];
        hdr.byte_count_l   = byte_cnt[7:0];
        hdr.requester_id   = requester_id;
        hdr.tag_h          = tag[9];
        hdr.tag_m          = tag[8];
        hdr.tag            = tag[7:0];
        hdr.lower_addr     = lower_addr;
        hdr.reserved       = reserved_in;

        return hdr;
    endfunction

endpackage

`endif