`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
`define A_E_WIDTH 8
`define B_E_WIDTH 8
`define A_M_WIDTH 23
`define B_M_WIDTH 23
`define ADD_SIGNAL 0  // Change to 1 for addition, 0 for subtraction
`define A_WIDTH (`A_E_WIDTH + `A_M_WIDTH + 1)
`define B_WIDTH (`B_E_WIDTH + `B_M_WIDTH + 1)
`define OUT_E_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)
`define OUT_M_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)
`define OUT_WIDTH `B_WIDTH

module Floating_addition(
    input [`A_WIDTH-1:0] a, 
    input [`B_WIDTH-1:0] b, 
    output reg [`OUT_WIDTH-1:0] p
);

    // A's exponent and mantissa slicing
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
    reg signed [7:0] A_exp_adjusted; // Adjusted exponent for A
            reg signed [7:0] B_exp_adjusted; // Adjusted exponent for B
  localparam [`OUT_E_WIDTH:0] MAX_EXP = 255;
  localparam [`OUT_E_WIDTH:0] MIN_EXP = 1;  // Minimum exponent value for normalized numbers
  localparam [`OUT_E_WIDTH:0] BIAS = 127;    // Bias for 8-bit exponent

    initial begin
        mant_f = 24'b00000000;
      $display("%d", `OUT_M_WIDTH);
  
    end

    always @(*) begin
        // Extract exponents and mantissas
        A_sign = a[`A_WIDTH-1];
        A_exp = a[`A_E_WIDTH+`A_M_WIDTH-1:`A_M_WIDTH];
      A_m = {1'b1, a[`A_M_WIDTH-1:0]}; // Implicit leading 1 added for normalized numbers
        B_sign = b[`B_WIDTH-1];
        B_exp = b[`B_E_WIDTH+`B_M_WIDTH-1:`B_M_WIDTH];
      B_m = {1'b1, b[`B_M_WIDTH-1:0]}; // Implicit leading 1 added for normalized numbers

        // Special cases handling (NaN, infinity, zero)
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
        else begin
            // Adjust for bias
            

            A_exp_adjusted = A_exp - BIAS; // Adjust for bias
            B_exp_adjusted = B_exp - BIAS; // Adjust for bias

            // Normal floating-point addition or subtraction
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

            // Perform addition or subtraction based on ADD_SIGNAL
            if (`ADD_SIGNAL == 1) begin  // ADD operation
                if (A_sign == B_sign) begin
                    // Same sign: Perform addition
                    mant_f = mant_a_shift + mant_b_shift;
                     $display("manta = %b", mant_a_shift);
                    $display("mantb = %b", mant_b_shift);
                  // Addition with implicit leading 1s
                    result_sign = A_sign;  // Keep A's sign
                  $display("A");
                end else begin
                    // Different sign: Perform subtraction
                    if (mant_a_shift >= mant_b_shift) begin
                        mant_f = mant_a_shift - mant_b_shift;
                        result_sign = A_sign;
                      $display("b");// Keep A's sign
                    end else begin
                        mant_f = mant_b_shift - mant_a_shift;
                        result_sign = B_sign;
                      $display("c");// Keep B's sign
                    end
                end
            end else begin  // SUB operation
                if (A_sign != B_sign) begin
                    // Different signs: Perform addition
                    mant_f = mant_a_shift + mant_b_shift; // Addition with implicit leading 1s
                  
                    result_sign = A_sign; 
                  $display("d");// Keep A's sign
                end else begin
                    // Same sign: Perform subtraction
                    if (mant_a_shift >= mant_b_shift) begin
                        mant_f = mant_a_shift - mant_b_shift;
                        result_sign = A_sign;
                      $display("e");// Keep A's sign
                    end else begin
                        mant_f = mant_b_shift - mant_a_shift;
                        result_sign = ~A_sign;
                      $display("f");// Flip A's sign
                    end
                end
            end
          $display("mantf = %b", mant_f);
          $display("result sign = %b", result_sign);
          
            // Normalize the mantissa
            normalized_mantissa = mant_f;
            normalized_exponent = aligned_exp;

//            while (normalized_mantissa[`OUT_M_WIDTH] == 1'b0 && normalized_exponent > MIN_EXP) begin
//                normalized_mantissa = normalized_mantissa << 1;  // Shift left
//                normalized_exponent = normalized_exponent - 1;  // Decrement exponent
//            end

            if (normalized_mantissa[24]) begin 
            // Handle overflow 
           normalized_mantissa={0,normalized_mantissa[23:1]};
           normalized_exponent = normalized_exponent + 1;

        end else begin 
            if(`ADD_SIGNAL == 1)
            normalized_mantissa={0,normalized_mantissa[22:0]};
            else
            begin
            while (normalized_mantissa[`OUT_M_WIDTH] == 1'b0 && normalized_exponent > MIN_EXP) begin
                normalized_mantissa = normalized_mantissa << 1;  // Shift left
                normalized_exponent = normalized_exponent - 1;  // Decrement exponent
            end
            end
        end 



            
            // Round the mantissa
          rounded_mantissa = normalized_mantissa;  // Rounding mantissa
          rounded_exponent = normalized_exponent;
            if (normalized_mantissa[0] == 1'b1) begin
                // Round up if the LSB is 1
              $display("X");
                rounded_mantissa = rounded_mantissa + 1;
                    //         Adjust exponent if rounding caused overflow
                if (rounded_mantissa[`OUT_M_WIDTH] == 1'b1) begin
                    rounded_mantissa = rounded_mantissa << 1;
                    rounded_exponent = normalized_exponent + 1;
                end 
            end
            //rounded_exponent = rounded_exponent + BIAS;
              

          $display("normalised_mantissa = %b", normalized_mantissa);
          $display("normalised_exponent = %b", normalized_exponent);
          $display("rounded_mantissa = %b", rounded_mantissa);
          $display("rounded_exponent = %b", rounded_exponent);
          
          $display("%b", MAX_EXP);
            // Overflow/Underflow handling
            if (rounded_exponent > MAX_EXP) begin
                // Set to infinity (overflow)
                $display("overflow");
                p = {result_sign, 8'hFF, {`OUT_M_WIDTH{1'b0}}};  // Infinity representation
            end else if (rounded_exponent <= MIN_EXP) begin
                // Set to zero (underflow)
                $display("underflow");
              
              $display("%b", result_sign);
                p = {result_sign, {`OUT_E_WIDTH{1'b0}}, {`OUT_M_WIDTH{1'b0}}};  // Zero representation
            end else begin
                // Assign the final result
                $display("final");
              $display("%b", result_sign);
              $display("%b", rounded_exponent + BIAS);
              p = {result_sign, rounded_exponent[`OUT_E_WIDTH-1:0], rounded_mantissa[`OUT_M_WIDTH-1:0]};
            end
        end
    end
endmodule