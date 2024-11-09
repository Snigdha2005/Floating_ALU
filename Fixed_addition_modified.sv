
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
`define A_E_WIDTH 8
`define B_E_WIDTH 8
`define A_M_WIDTH 7
`define B_M_WIDTH 7
`define ADD_SIGNAL 0
`define A_WIDTH (`A_E_WIDTH + `A_M_WIDTH + 1)
`define B_WIDTH (`B_E_WIDTH + `A_M_WIDTH + 1)
`define OUT_E_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)
`define OUT_M_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)
`define OUT_WIDTH `B_WIDTH

module Fixed_addition(
    input [`A_WIDTH-1:0] a, input [`B_WIDTH-1:0] b, output reg [`OUT_WIDTH-1:0] p
    );
    // A's exponent and mantissa slicing
    reg [`A_E_WIDTH-1:0] A_exp;
    reg [`A_M_WIDTH-1:0] A_m;
    reg [`B_E_WIDTH-1:0] B_exp;
    reg [`B_M_WIDTH-1:0] B_m;
    reg [`OUT_E_WIDTH-1:0] aligned_exp;  // Use the correct width here
    reg [`OUT_M_WIDTH-1:0] mant_a_shift;
    reg [`OUT_M_WIDTH-1:0] mant_b_shift;
    reg [`OUT_M_WIDTH-1:0] mant_f;
    reg signed [7:0] exp_diff;  // Signed to handle exponent differences
    
    always @(*) begin
        // Extract exponents and mantissas
        A_exp = a[`A_E_WIDTH+`A_M_WIDTH-1:`A_M_WIDTH];
        A_m = a[`A_M_WIDTH-1:0];
        B_exp = b[`B_E_WIDTH+`B_M_WIDTH-1:`B_M_WIDTH];
        B_m = b[`B_M_WIDTH-1:0];
        
        // Compare actual exponents, not the widths
        if (A_exp > B_exp) begin
            exp_diff = A_exp - B_exp;
            aligned_exp = A_exp;
            mant_a_shift = A_m;
            mant_b_shift = B_m >> exp_diff;  // Shift B's mantissa by the exponent difference
        end else begin
            exp_diff = B_exp - A_exp;
            aligned_exp = B_exp;
            mant_a_shift = A_m >> exp_diff;  // Shift A's mantissa by the exponent difference
            mant_b_shift = B_m;
        end
        
        // Perform the addition or subtraction based on ADD_SIGNAL
        if (`ADD_SIGNAL == 1)
            mant_f = mant_a_shift + mant_b_shift;
        else
           if(mant_a_shift > mant_b_shift)
            mant_f = mant_a_shift - mant_b_shift;
           else
           mant_f = mant_b_shift - mant_a_shift;
        // Assign final result
        p = {aligned_exp, mant_f[`OUT_M_WIDTH-1:0]};
    end
endmodule
