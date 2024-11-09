`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2024 21:02:30
// Design Name: 
// Module Name: Fixed_addition
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "C:/Users/SnigdhaYS/Summer_school/Summer_school.srcs/sources_1/new/param.v"
module Fixed_addition(
    input [`A_WIDTH-1:0] a, input [`B_WIDTH-1:0] b, output reg [`OUT_WIDTH-1:0] p
    );
    // A's exponent and mantissa slicing
reg [`A_E_WIDTH-1:0] A_exp = a[`A_E_WIDTH+`A_M_WIDTH:`A_M_WIDTH+1];  // Slice the exponent
reg [`A_M_WIDTH-1:0] A_m   = a[`A_M_WIDTH-1:0];                      // Slice the mantissa
reg [(`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)-1:0] aligned_exp;

// B's exponent and mantissa slicing (assuming `b` is the input for B)
reg [`B_E_WIDTH-1:0] B_exp = b[`B_E_WIDTH+`B_M_WIDTH:`B_M_WIDTH+1];  // Slice the exponent
reg [`B_M_WIDTH-1:0] B_m   = b[`B_M_WIDTH-1:0];                      // Slice the mantissa
reg [(`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)-1:0] mant_a_shift;
reg [(`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)-1:0] mant_b_shift;
reg [(`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)-1:0] mant_f;

reg exp_diff;

always @(*) begin
    if(`A_E_WIDTH > `B_E_WIDTH) begin
    exp_diff = `A_E_WIDTH - `B_E_WIDTH;
    aligned_exp = A_exp;
    mant_a_shift = A_m;
    mant_b_shift = B_m >> exp_diff;
    end
    else begin
    exp_diff = `B_E_WIDTH - `A_E_WIDTH;
    aligned_exp = B_exp;
    mant_a_shift = A_m >> exp_diff;
    mant_b_shift = B_m;
    end
    if (`ADD_SIGNAL == 1)
    mant_f = mant_a_shift + mant_b_shift;
    else 
    mant_f = mant_a_shift - mant_b_shift;
    p = {aligned_exp, mant_f[`OUT_M_WIDTH-1:0]};
end   
endmodule
