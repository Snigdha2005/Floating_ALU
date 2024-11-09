`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
`define A_E_WIDTH 8
`define B_E_WIDTH 8
`define A_M_WIDTH 7
`define B_M_WIDTH 7
`define ADD_SIGNAL 1
`define A_WIDTH (`A_E_WIDTH + `A_M_WIDTH + 1)
`define B_WIDTH (`B_E_WIDTH + `B_M_WIDTH + 1)
`define OUT_E_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)
`define OUT_M_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)
`define OUT_WIDTH `B_WIDTH

module Floating_addition(

    input [`A_WIDTH-1:0] a, input [`B_WIDTH-1:0] b, output reg [`OUT_WIDTH-1:0] p
    );
    
    reg [`A_E_WIDTH-1:0] A_exp;
    reg [`A_M_WIDTH-1:0] A_m;
    reg [`B_E_WIDTH-1:0] B_exp;
    reg [`B_M_WIDTH-1:0] B_m;
    reg [`OUT_E_WIDTH-1:0] aligned_exp;  // Use the correct width here
    reg [`OUT_M_WIDTH-1:0] mant_a_shift;
    reg [`OUT_M_WIDTH-1:0] mant_b_shift;
    reg [`OUT_M_WIDTH:0] mant_f;
    reg signed [7:0] exp_diff;  // Signed to handle exponent differences
    reg [`OUT_M_WIDTH:0] normalized_mantissa;
    reg [`OUT_E_WIDTH-1:0] normalized_exponent;
    reg [`OUT_M_WIDTH:0] rounded_mantissa;
    reg [`OUT_E_WIDTH-1:0] rounded_exponent;
    reg A_sign;
    reg B_sign;
    reg result_sign;
    localparam MAX_EXP = (1 << `OUT_E_WIDTH) - 1;
    localparam MIN_EXP = 0;  // Minimum exponent value for normalized numbers

initial
mant_f = 8'b00000000;

    always @(*) begin
        // Extract exponents and mantissas
        A_sign = a[`A_WIDTH-1];
        A_exp = a[`A_E_WIDTH+`A_M_WIDTH-1:`A_M_WIDTH];
        A_m = a[`A_M_WIDTH-1:0];
        B_sign = b[`B_WIDTH-1];
        B_exp = b[`B_E_WIDTH+`B_M_WIDTH-1:`B_M_WIDTH];
        B_m = b[`B_M_WIDTH-1:0];
        
        // Compare actual exponents
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
        
        if (`ADD_SIGNAL == 1)begin  // ADD operation
            if (A_sign == B_sign) begin
                // Same sign: Perform addition
                mant_f = mant_a_shift + mant_b_shift;
                result_sign = A_sign;  // Sign remains the same
            end else begin
                // Different sign: Perform subtraction
                if (mant_a_shift >= mant_b_shift) begin
                    mant_f = mant_a_shift - mant_b_shift;
                    result_sign = A_sign;  // Keep A's sign
                end else begin
                    mant_f = mant_b_shift - mant_a_shift;
                    result_sign = B_sign;  // Keep B's sign
                end
            end
        end else begin  // SUB operation
            if (A_sign != B_sign) begin
                // Different signs: Perform addition
                mant_f = mant_a_shift + mant_b_shift;
                result_sign = A_sign;  // Sign remains as A's sign
            end else begin
                // Same sign: Perform subtraction
                if (mant_a_shift >= mant_b_shift) begin
                    mant_f = mant_a_shift - mant_b_shift;
                    result_sign = A_sign;  // Keep A's sign
                end else begin
                    mant_f = mant_b_shift - mant_a_shift;
                    result_sign = ~A_sign;  // Flip A's sign for the result
                end
            end
        end
       
    //Perform normalisation   
    normalized_mantissa = mant_f;
    normalized_exponent = aligned_exp;
    while (normalized_mantissa[`OUT_M_WIDTH-1] == 1'b0 && normalized_exponent > 0) begin
        normalized_mantissa = normalized_mantissa << 1; // Shift left
        normalized_exponent = normalized_exponent - 1; // Decrement exponent
    end
    //handling underflow
//    if (normalized_exponent <= MIN_EXP) begin
//            // If exponent reaches below minimum allowed value, set to zero (underflow)
//            p = {result_sign, {`OUT_E_WIDTH{1'b0}}, {`OUT_M_WIDTH{1'b0}}};  // Output zero
//     end       
 //   else
 //    begin  

 //perform rounding off      
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
        
        // Overflow handling
        if (rounded_exponent > MAX_EXP) begin
            // Set to infinity (or max representable value)
            p = {result_sign, MAX_EXP, {`OUT_M_WIDTH{1'b0}}}; // Infinity representation
        end else begin
            // Assign result to output
            p = {result_sign, rounded_exponent, rounded_mantissa[`OUT_M_WIDTH-1:0]};
        end
        // Assign result to output
        p = {result_sign,rounded_exponent, rounded_mantissa[`OUT_M_WIDTH-1:0]};
        end
//end   
endmodule
