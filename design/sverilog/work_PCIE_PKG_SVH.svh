//work_PCIE_PKG_SVH

// Copyright Sungkyunkwan University
// Author: Sanghyun Park <psh2018314072@gmail.com>
// Description:

// Follows PCIe gen5 specification 1.1

`ifndef __PCIE_PKG_SVH__
`define __PCIE_PKG_SVH__

package PCIE_PKG;

    //----------------------------------------------------------
    // PCIe constants
    //----------------------------------------------------------
    localparam  ADDR_WIDTH                  = 64;
    localparam  LANE_COUNT                  = 4;
    localparam  PIPE_DATA_WIDTH             = 256; //32B
    localparam  MAX_PAYLOAD_SIZE            = 128;
    localparam  MAX_READ_REQ_SIZE           = 512;
    localparam  READ_COMPLETION_BOUNDARY    = 64;
    localparam  CREDIT_UNIT                 = 16; // 4DW(16B)
    /*
    * TODO:
    */

    typedef struct packed {
        // Header 16B
        logic   [5:0]               addr_l;
        logic   [1:0]               reserved;
        logic   [23:0]              addr_m;
        logic   [31:0]              addr_h;
        logic   [7:0]               byte_enable;
        logic   [7:0]               tag;
        logic   [15:0]              requester_id;

        logic   [7:0]               length_l;
        logic                       td;             //0b
        logic                       ep;             //0b
        logic   [1:0]               attr_l;         //0b
        logic   [1:0]               at;             //0b
        logic   [1:0]               length_h;
        logic                       tg_h;           //T8, dont use
        logic   [2:0]               tc;             //TC, 000b
        logic                       tg_m;           //T9, dont use
        logic                       attr_h;         //1b?
        logic                       ln;             //0b
        logic                       th;             //0b
        logic   [2:0]               fmt;
        logic   [4:0]               tlp_type;
    } tlp_memory_req_hdr_t;

    function automatic tlp_memory_req_hdr_t gen_tlp_memwr_hdr(
        input   logic   [63:0]      address,     //64비트 address 입력받아 구조체를 채움.
        input   logic   [9:0]       full_length, //burst 길이에 따라 계산된 10비트 길이 (DW 단위)
        input   logic   [9:0]       full_tag     //트랜잭션 식별용 태그 (10비트; 만약 10비트 태그를 사용하지 않는다면 하위 8비트만 활용)
    );
        tlp_memory_req_hdr_t        tlp_memwr_hdr;
        tlp_memwr_hdr.addr_h        = {address[39:32], address[47:40], address[55:48], address[63:56]};
                    
        // -- 길이 필드 설정 --
        // full_length를 10비트로 받아서 상위 2비트와 하위 8비트로 분리
        tlp_memwr_hdr.length_h = full_length[9:8];
        tlp_memwr_hdr.length_l = full_length[7:0];

        tlp_memwr_hdr.td      = 1'b0;      
        tlp_memwr_hdr.ep      = 1'b0;    
        tlp_memwr_hdr.attr_l  = 2'b00;     
        tlp_memwr_hdr.at      = 2'b00;     
        tlp_memwr_hdr.tg_h    = 1'b0;      
        tlp_memwr_hdr.tc      = 3'b000;    
        tlp_memwr_hdr.tg_m    = 1'b0;      
        tlp_memwr_hdr.attr_h  = 1'b1;      // (?)
        tlp_memwr_hdr.ln      = 1'b0;      
        tlp_memwr_hdr.th      = 1'b0;      

        tlp_memwr_hdr.fmt     = 3'b011;    //memory write request
        tlp_memwr_hdr.tlp_type = 5'b00000;

        //tlp_memwr_hdr.tag = full_tag[7:0];


    endfunction

endpackage