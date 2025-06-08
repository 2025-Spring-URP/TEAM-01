module dllp_crc16_generator(
    input   logic [31:0] dllp_data,
    output  logic [15:0] crc16_out
);
    //parameter          crc16_POLY = 16'h100B;   // 다항식 X12 + X3 + X + 1
    
    integer i;
    always_comb begin
        logic [15:0] crc = 16'hFFFF;            // 초기값
        // DLLP Bit 순서: (LSB) byte0의 bit0부터 byte3의 bit7까지 
        for (i = 0; i < 32; i++) begin
            if(crc[15] ^ dllp_data[i]) begin    // DLLP의 LSB부터 crc의 MSB와 비교하여 
                //crc = (crc << 1) ^ crc16_POLY;  
                crc = (crc << 1) ^ 16'h100B;    // 서로 다르면 crc에 다항식을 XOR한다
            end else begin
                crc = (crc << 1);               // crc는 반복마다 왼쪽 1비트 shift
            end
        end

        // 비트 보수
        crc = ~crc;

        // 비트 재배열하여 crc 필드에 맵핑
        crc16_out[7]  = crc[0];
        crc16_out[6]  = crc[1];
        crc16_out[5]  = crc[2];
        crc16_out[4]  = crc[3];
        crc16_out[3]  = crc[4];
        crc16_out[2]  = crc[5];
        crc16_out[1]  = crc[6];
        crc16_out[0]  = crc[7];
        crc16_out[15] = crc[8];
        crc16_out[14] = crc[9];
        crc16_out[13] = crc[10];
        crc16_out[12] = crc[11];
        crc16_out[11] = crc[12];
        crc16_out[10] = crc[13];
        crc16_out[9]  = crc[14];
        crc16_out[8]  = crc[15];

    end    
endmodule
    