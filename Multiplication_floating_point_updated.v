module mult(a, b, result);
parameter width = 32;

input [width-1:0] a, b;
output [width-1:0] result;

wire sign_a, sign_b, sign_result;
wire [7:0] exp_a, exp_b, exp, exp_result;
wire [23:0] mant_a, mant_b;
wire [22:0] mant_result;
wire [47:0] mant;
wire [23:0] rounded_mantissa;

wire underflow, overflow;
wire guard, round_bit, sticky;
reg [7:0] final_exp;

// Extract the sign bit
assign sign_a = a[width-1];           // Extract the sign bit from 'a' (bit 31)
assign sign_b = b[width-1];           // Extract the sign bit from 'b' (bit 31)

// Extract the exponents
assign exp_a = a[30:23];              // Extract the exponent from 'a' (bits 30 to 23)
assign exp_b = b[30:23];              // Extract the exponent from 'b' (bits 30 to 23)


// Add hidden leading '1' to the mantissa for normalized numbers, or leave as is for denormals
// In normalized numbers, IEEE 754 assumes an implicit leading 1 in the mantissa.
// For denormals, this leading bit is not present.
assign mant_a = {1'b1, a[22:0]};  // For 'a', add leading '1' if normalized, else keep as is
assign mant_b = {1'b1, b[22:0]};  // For 'b', add leading '1' if normalized, else keep as is

// Perform mantissa multiplication (mantissas are 24 bits, the result will be 48 bits)
assign mant = mant_a * mant_b;        // Multiply the mantissas of 'a' and 'b', generating a 48-bit result

// Add exponents and subtract the bias (127), handle denormals by treating their exponent as 1
// In IEEE 754, exponents are stored with a bias of 127. We subtract this bias after adding the exponents.
// If 'a' or 'b' is denormal, their exponent is treated as 1 instead of 0.
assign exp = exp_a + exp_b - 8'd127; // Add exponents and subtract bias

// Calculate result sign (XOR of input signs)
// If both inputs have the same sign, the result will be positive; if different, the result will be negative.
assign sign_result = sign_a ^ sign_b; // XOR the signs of 'a' and 'b' to get the result's sign

// Normalize the mantissa (shift right if needed and adjust exponent)
// If the MSB (mant[47]) is 1, the mantissa is already normalized, else shift it left by 1
assign mant_result = mant[47] ? mant[46:24] : mant[45:23];  // If MSB is set, no shift needed; otherwise shift left
assign exp_result = mant[47] ? exp + 1 : exp;               // Adjust the exponent if the mantissa was shifted

//initial // for debugging
//begin    
//#2
//$display("exponent is %b, mantissa is %b", exp_result,mant);
//$display("mant_result is %b", mant_result);
//$display("%b %b %b", guard, round_bit, sticky);

//end

// Rounding logic (round to nearest, ties to even)
// IEEE 754 rounding mode: round to the nearest even number if there's a tie.
// This logic uses the guard, round, and sticky bits to determine if rounding up is necessary.
assign guard = mant[23];             // Guard bit: first bit beyond the mantissa precision
assign round_bit = mant[22];         // Round bit: second bit beyond precision
assign sticky = |mant[21:0];         // Sticky bit: OR of all remaining bits beyond the precision (to track information loss)

// Round the mantissa: if guard bit is 1 and either round or sticky bit is set, round up
assign rounded_mantissa = (guard && (round_bit || sticky)) ? mant_result + 1 : mant_result; // Perform rounding

// Adjust exponent if rounding causes mantissa overflow
always @(*) begin
    if (rounded_mantissa == 24'b100000000000000000000000) begin  // If rounding causes an overflow in mantissa
        final_exp = exp_result + 1;        // Increment the exponent by 1
    end else begin
        final_exp = exp_result;            // Otherwise, leave the exponent as is
    end
end

// Overflow and underflow detection
assign overflow = (final_exp >= 8'd255);   // Overflow if the final exponent is too large (>= 255)
assign underflow = (final_exp <= 8'b0);    // Underflow if the final exponent is too small (<= 0)

// Handling special cases for overflow, underflow, and denormals
// 1. If either input is zero, return zero.
// 2. If overflow occurs, return infinity (exp = 255, mantissa = 0).
// 3. If underflow occurs, return a subnormal number (exponent = 0) or zero.
// 4. Otherwise, return the normalized result with the adjusted exponent and rounded mantissa.
assign result = (a == 32'b0 || b == 32'b0) ? 32'b0 :              // If either 'a' or 'b' is zero, result is zero
                overflow ? {sign_result, 8'hFF, 23'b0} :          // If overflow, return infinity (exp = all 1's, mantissa = 0)
                underflow ? {sign_result, 8'b0, rounded_mantissa[22:0]} : // If underflow, return subnormal (exp = 0)
                {sign_result, final_exp[7:0], rounded_mantissa[22:0]};    // Otherwise, return the normalized result

endmodule
