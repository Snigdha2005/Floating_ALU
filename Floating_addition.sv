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
module Floating_addition(
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
reg [`OUT_M_WIDTH-1:0] normalized_mantissa;
reg [`OUT_E_WIDTH-1:0] normalized_exponent;
reg [`OUT_M_WIDTH-1:0] rounded_mantissa;
reg [`OUT_E_WIDTH-1:0] rounded_exponent;
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
    //p = {aligned_exp, mant_f[`OUT_M_WIDTH-1:0]};
    normalized_mantissa = mant_f;
    normalized_exponent = aligned_exp;
    while (normalized_mantissa[`OUT_M_WIDTH-1] == 1'b0 && normalized_exponent > 0) begin
        normalized_mantissa = normalized_mantissa << 1; // Shift left
        normalized_exponent = normalized_exponent - 1; // Decrement exponent
    end
    
    // Handle zero case
    if (normalized_mantissa == 0) begin
        normalized_exponent = 0;
    end
    rounded_mantissa = normalized_mantissa;
        if (rounded_mantissa[`OUT_M_WIDTH] == 1'b1) begin
            // Round up if the overflow bit is set
            rounded_mantissa = rounded_mantissa[`OUT_M_WIDTH-1:0] + 1;
            // Adjust exponent if rounding causes overflow
            if (rounded_mantissa[`OUT_M_WIDTH-1] == 1'b0) begin
                rounded_exponent = normalized_exponent + 1;
            end else begin
                rounded_exponent = normalized_exponent;
            end
        end else begin
            rounded_exponent = normalized_exponent;
        end

        // Assign result to output
        p = {rounded_exponent, rounded_mantissa[`OUT_M_WIDTH-1:0]};
end   
endmodule
