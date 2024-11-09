`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2024 02:37:38 PM
// Design Name: 
// Module Name: tb_div
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


module tb_div();

    parameter width = 32;
    
    reg start;

    // Testbench inputs and outputs
    reg [width-1:0] a, b;   // Inputs (floating-point numbers)
    wire [width-1:0] result; // Output (result of multiplication)
    
     div #(width) uut (
        .a(a),
        .b(b),
        .result(result),
        .start(start)
    );
    
        task display_result;
        input [width-1:0] op1;
        input [width-1:0] op2;
        input [width-1:0] res;
        begin
            $display("a = %h, b = %h, result = %h", op1, op2, res);
        end
    endtask

    initial begin
    
        start = 0;        
        // Initialize inputs
        a = 32'h40400000; // 3 in IEEE 754
        b = 32'h40800000; // 4 in IEEE 754
        start = 1;
        #20
        start = 0;
        display_result(a, b, result); // Expected result: 0x3F400000 (0.75)
        
        #2
        a = 32'h40400000; // 3 in IEEE 754
        b = 32'hC0800000; // -4 in IEEE 754
        start = 1;
        #20;
        start = 0;
        display_result(a, b, result); // Expected result: 0x3F400000 (-0.75)
        
        #2
        a = 32'h40A00000; // 5 in IEEE 754
        b = 32'h40400000; // 3 in IEEE 754
        start = 1;
        #20;
        start = 0;
        display_result(a, b, result);
        
//        #5
//        a = 32'h00000000; 
//        b = 32'h40A00000; 
//        start = 1;
//        #10;
//        display_result(a, b, result);
        
    end 
    
endmodule

