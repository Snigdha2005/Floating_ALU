`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
`define A_E_WIDTH 8
`define B_E_WIDTH 8
`define A_M_WIDTH 23
`define B_M_WIDTH 23
//`define ADD_SIGNAL 0  // Change to 1 for addition, 0 for subtraction
`define A_WIDTH (`A_E_WIDTH + `A_M_WIDTH + 1)
`define B_WIDTH (`B_E_WIDTH + `B_M_WIDTH + 1)
`define OUT_E_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)
`define OUT_M_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)
`define OUT_WIDTH `B_WIDTH

module Floating_addsub(
    input [`A_WIDTH-1:0] a, 
    input [`B_WIDTH-1:0] b, 
    input ADD_SIGNAL,
    output reg [`OUT_WIDTH-1:0] p
);
  reg [`A_E_WIDTH-1:0] A_exp;
  reg [`A_M_WIDTH:0] A_m;
  reg [`B_E_WIDTH-1:0] B_exp;
  reg [`B_M_WIDTH:0] B_m;
  reg [`OUT_E_WIDTH-1:0] aligned_exp;  // Use the correct width here
  reg [`OUT_M_WIDTH:0] mant_a_shift;
  reg [`OUT_M_WIDTH:0] mant_b_shift;
    reg [`OUT_M_WIDTH+1:0] mant_f;
    reg signed [7:0] exp_diff;  // Signed to handle exponent differences
    reg [`OUT_M_WIDTH+1:0] normalized_mantissa;
    reg [`OUT_E_WIDTH-1:0] normalized_exponent;
    reg [`OUT_M_WIDTH+1:0] rounded_mantissa;
    reg [`OUT_E_WIDTH-1:0] rounded_exponent;
    reg A_sign;
    reg B_sign;
    reg result_sign;
    reg isadd;
   reg signed [7:0] A_exp_adjusted; // Adjusted exponent for A
   reg signed [7:0] B_exp_adjusted; // Adjusted exponent for B
   reg guard, round_bit, sticky;

  localparam [`OUT_E_WIDTH:0] MAX_EXP = 255;
  localparam [`OUT_E_WIDTH:0] MIN_EXP = 0;  // Minimum exponent value for normalized numbers
  localparam [`OUT_E_WIDTH:0] BIAS = 127;    // Bias for 8-bit exponent

    initial begin
        mant_f = 24'b00000000;
      isadd=0;
  
    end

    always @(*) begin
        A_sign = a[`A_WIDTH-1];
        A_exp = a[`A_E_WIDTH+`A_M_WIDTH-1:`A_M_WIDTH];
        A_m = {1'b1, a[`A_M_WIDTH-1:0]}; // Implicit leading 1 added for normalized numbers
        B_sign = b[`B_WIDTH-1];
        B_exp = b[`B_E_WIDTH+`B_M_WIDTH-1:`B_M_WIDTH];
        B_m = {1'b1, b[`B_M_WIDTH-1:0]}; // Implicit leading 1 added for normalized numbers

///////////////////////// Special cases handling (NaN, infinity, zero)
        if ((A_exp == 8'hFF && A_m[`A_M_WIDTH-1:0] != 0) || (B_exp == 8'hFF && B_m[`B_M_WIDTH-1:0] != 0)) begin
            p = {1'b0, 8'hFF, {`OUT_M_WIDTH{1'b1}}};  // NaN representation
        end
        else if ((A_exp == 8'hFF && B_exp == 8'hFF) && (A_sign != B_sign)) begin
            p = {1'b0, 8'hFF, {`OUT_M_WIDTH{1'b1}}};  // NaN representation (inf - inf)
        end
        else if (A_exp == 8'hFF) begin
            p = {A_sign, 8'hFF, {`OUT_M_WIDTH{1'b0}}};  // Infinity
        end
        else if (B_exp == 8'hFF) begin
            p = {B_sign, 8'hFF, {`OUT_M_WIDTH{1'b0}}};  // Infinity
        end
        else if ((a[30:0] == 31'b0) && (b[30:0] == 31'b0)) begin
            p = {1'b0, {`OUT_E_WIDTH{1'b0}}, {`OUT_M_WIDTH{1'b0}}};  // Zero result
        end
  ////////////////////////////////
        else begin  ////making the exponents equal
            A_exp_adjusted = A_exp - BIAS; // Adjust for bias
            B_exp_adjusted = B_exp - BIAS; // Adjust for bias

            if (A_exp_adjusted > B_exp_adjusted) begin
                exp_diff = A_exp_adjusted - B_exp_adjusted;
                aligned_exp = A_exp; // A's exponent is used
                mant_a_shift = A_m;  // A's mantissa is already normalized
                mant_b_shift = B_m >> exp_diff;  // Shift B's mantissa
            end else begin
                exp_diff = B_exp_adjusted - A_exp_adjusted;
                aligned_exp = B_exp; // B's exponent is used
                mant_b_shift = B_m;  // B's mantissa is already normalized
                mant_a_shift = A_m >> exp_diff;  // Shift A's mantissa
            end
            if (ADD_SIGNAL == 1) begin  // ADD operation
                if (A_sign == B_sign) begin
                    mant_f = mant_a_shift + mant_b_shift;                    
                    isadd=1;
                    result_sign = A_sign;  
                end else begin
                    if (mant_a_shift >= mant_b_shift) begin
                        mant_f =mant_a_shift - mant_b_shift;
                        result_sign = A_sign;
                    end else begin
                        mant_f =mant_b_shift - mant_a_shift;
                        result_sign = B_sign;
                    end
                end
            end else begin  //Sub operation
                if (A_sign != B_sign) begin
                    isadd=1;
                    mant_f = mant_a_shift + mant_b_shift;
                    result_sign = A_sign; 
                end else begin
                    if (mant_a_shift >= mant_b_shift) begin
                        mant_f = mant_a_shift - mant_b_shift;
                        result_sign = A_sign;
                    end else begin
                        mant_f = mant_b_shift - mant_a_shift;
                        result_sign = ~A_sign;
                    end
                end
            end
 ////////////////////////////////////// Normalize the mantissa
            normalized_mantissa = mant_f;
            normalized_exponent = aligned_exp;
            if (normalized_mantissa[24]) begin             // Handle overflow 
               normalized_mantissa={0,normalized_mantissa[23:1]};
               normalized_exponent = normalized_exponent + 1;
            end else begin 
                if(isadd == 1)
                    normalized_mantissa={0,normalized_mantissa[22:0]};
                else begin
                    while (normalized_mantissa[`OUT_M_WIDTH] == 1'b0 && normalized_exponent > MIN_EXP) begin
                        normalized_mantissa = normalized_mantissa << 1;  // Shift left
                        normalized_exponent = normalized_exponent - 1;  // Decrement exponent
                    end
                end
            end 


////////////////////////////////// Rounding the mantessa
        rounded_mantissa = normalized_mantissa;  
        rounded_exponent = normalized_exponent;
              
        guard = normalized_mantissa[23];             
        round_bit = normalized_mantissa[22];        
        sticky = |normalized_mantissa[21:0];         
        

        rounded_mantissa = (guard && (round_bit || sticky)) ? normalized_mantissa + 1 : normalized_mantissa; 

        if (rounded_mantissa == 24'b100000000000000000000000) begin
            rounded_mantissa = rounded_mantissa << 1;
            rounded_exponent = normalized_exponent + 1;
        end 
              
//////////////////// Overflow/Underflow handling
            if (rounded_exponent > MAX_EXP) begin
                p = {result_sign, 8'hFF, {`OUT_M_WIDTH{1'b0}}};  // Infinity representation
            end else if (rounded_exponent <= MIN_EXP) begin
                p = {result_sign, {`OUT_E_WIDTH{1'b0}}, {`OUT_M_WIDTH{1'b0}}};  // Zero representation
            end else begin
              p = {result_sign, rounded_exponent[`OUT_E_WIDTH-1:0], rounded_mantissa[`OUT_M_WIDTH-1:0]};
            end
        end
    end
endmodule