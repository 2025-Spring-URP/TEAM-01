//work_PCIE_PKG_SVH


//`ifndef __PCIE_PKG_SVH__
//`define __PCIE_PKG_SVH__
`timescale 1ns/1ps
package PCIE_PKG;

    //----------------------------------------------------------
    // PCIe constants
    //----------------------------------------------------------

    parameter int ADDR_WIDTH                  = 64;
    parameter int DATA_WIDTH                  = 256;
    parameter int MAX_PAYLOAD_SIZE            = 128;



    typedef struct packed {
        // byte 0
        logic   [2:0]               fmt;            
        logic   [4:0]               tlp_type;
        
        //byte 1
        logic                       tag_h;          //T9
        logic   [2:0]               tc;             //TC
        logic                       tag_l;          //T8
        logic                       attr_h;         //1b?
        logic                       ln;             //0b
        logic                       th;             //0b
        
        //byte 2
        logic                       td;             //0b
        logic                       ep;             //0b
        logic   [1:0]               attr_l;         //0b
        logic   [1:0]               at;             //0b
        logic   [1:0]               length_h;

        //byte 3
        logic   [7:0]               length_l;

        //byte 4 ~ byte 7
        logic   [15:0]              requester_id;   
        logic   [7:0]               tag;
        logic   [3:0]               last_dw_be;     
        logic   [3:0]               first_dw_be;      

        //byte 8 ~ byte 11
        logic   [29:0]              address;
        logic   [1:0]               ph;             
    } tlp_memory_req_header;




    // memory request tlp의 header 생성 function
    function automatic tlp_memory_req_header create_header( 
        input logic [31:0] addr,
        input logic [9:0]  length,
        input logic        bdf
    );
        tlp_memory_req_header hdr;

        // Byte 0
        hdr.fmt          = 3'b010;     
        hdr.tlp_type     = 5'b00000;   // Memory Write request인 상황

        // Byte 1
        hdr.tag_h        = 1'b0;
        hdr.tc           = 3'b000;     
        hdr.tag_l        = 1'b0;
        hdr.attr_h       = 1'b0;
        hdr.ln           = 1'b0;
        hdr.th           = 1'b0;

        // Byte 2
        hdr.td           = 1'b0;
        hdr.ep           = 1'b0;
        hdr.attr_l       = 2'b00;
        hdr.at           = 2'b00;
        hdr.length_h     = length[9:8]; // 상위 2비트 

        // Byte 3
        hdr.length_l     = length[7:0]; // 하위 8비트

        // Byte 4 ~ 7
        hdr.requester_id = bdf;        
        hdr.tag          = 8'h00;      
        hdr.last_dw_be   = 4'b0000;    // 안 씀
        hdr.first_dw_be  = 4'b1111;    // 전체 DW 유효함

        // Byte 8 ~ 11
        hdr.address      = addr[31:2]; // DW 정렬 주소
        hdr.ph           = 2'b00;

        return hdr;
    endfunction

endpackage