`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2024 09:55:47 PM
// Design Name: 
// Module Name: test
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


`timescale 1ns / 1ps

module mult_tb;

    // Testbench parameters
    parameter width = 32;

    // Testbench inputs and outputs
    reg [width-1:0] a, b;   // Inputs (floating-point numbers)
    wire [width-1:0] result; // Output (result of multiplication)
    
    // Instantiate the DUT (Device Under Test)
    mult #(width) uut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Task to display floating-point numbers in human-readable format
    task display_result;
        input [width-1:0] op1;
        input [width-1:0] op2;
        input [width-1:0] res;
        begin
            $display("a = %h, b = %h, result = %h", op1, op2, res);
        end
    endtask

    // Test procedure
    initial begin
        // Initialize inputs
        a = 32'h3FC00000; // 1.5 in IEEE 754
        b = 32'h3FC00000; // 1.5 in IEEE 754
        #10;
        display_result(a, b, result); // Expected result: 0x40100000 (2.25)

        a = 32'h400CCCCD; // 2.2 in IEEE 754
        b = 32'h400CCCCD; // 2.2 in IEEE 754
        #10;
        display_result(a, b, result); // Expected result: 0x409ae148 (12.0)

        a = 32'h3F800000; // 1.0 in IEEE 754
        b = 32'hBF800000; // -1.0 in IEEE 754
        #10;
        display_result(a, b, result); // Expected result: 0xBF800000 (-1.0)

        a = 32'h3FB33333; // 1.4 in IEEE 754
        b = 32'h3FB33333; // 1.4 in IEEE 754
        #10;
        display_result(a, b, result); // Expected result: 0x3ffae148 (1.96)

        a = 32'hC0000000; // -2.0 in IEEE 754
        b = 32'hC0000000; // -2.0 in IEEE 754
        #10;
        display_result(a, b, result); // Expected result: 0x40800000 (4.0)

        $stop; // Stop simulation
    end
endmodule

