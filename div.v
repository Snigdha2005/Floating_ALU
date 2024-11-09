`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2024 02:19:29 PM
// Design Name: 
// Module Name: div
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


module div(a,b,result,start);

parameter width = 32;

input [width-1:0] a, b;
input start;
output reg [width-1:0] result;

reg [width-1:0] temp_b;  
reg [width-1:0] half = 32'h3F000000; 
wire [width-1:0] mult_result;
reg signed [7:0] scalefactor = 0;

reg [width-1:0] firstTerm = 32'h4034B4B5;
reg [width-1:0] secondCoeff = 32'h3FF0F0F1;
reg [width-1:0] secondTerm;
reg [width-1:0] z;
wire [width-1:0] zi;


reg [width-1:0] two = 32'h40000000;
reg [width-1:0] factor1;
reg [width-1:0] factor2;
wire [width-1:0] product;

reg [width-1:0] inter;
reg [7:0] exp;

wire sign_a,sign_b;
assign sign_a = a[31];
assign sign_b = b[31];
reg sign;

mult #(width) mul (
        .a(temp_b), 
        .b(half), 
        .result(mult_result)
    );
    
mult #(width) iterations (
        .a(factor1), 
        .b(factor2), 
        .result(product)
    );    


Floating_addition add (
        .a(firstTerm),
        .b(secondTerm),
        .p(zi) 
    );


//initial
always @ (posedge start)
begin
    
    $display("*******************************************************************");
    firstTerm = 32'h4034B4B5;
    scalefactor = 0;
    half = 32'h3F000000;
    
#1
    sign = sign_a ^ sign_b;
    $display("sign is %b", sign);
    
    temp_b = b;
    temp_b[31] = 0;
    
    $display("b is %h",b);
    while( temp_b > 32'h3F800000)
    begin
        #1
        temp_b = mult_result;
        scalefactor = scalefactor + 1;
        $display("b is %h",temp_b);
    end
    half = 32'h40000000;
    while( temp_b < 32'h3F000000)
    begin
        #1
        temp_b = mult_result;
        scalefactor = scalefactor - 1;
        $display("b is %h",temp_b);
    end
    $display("scalefactor is %d",scalefactor);
    
    half = secondCoeff;
    #1
    secondTerm = mult_result;
    $display("secondTerm is %h", secondTerm);
    #1
    z = zi;
    $display("Z0 is %h", z);
 
    half = z;
    #1
    
    firstTerm = two;
    secondTerm = mult_result;
    #1
    
    factor1 = z;
    factor2 = zi;
    #1
    
    z = product;
    $display("Z1 is %h", z);
    
    half = z;
    #1
    
    secondTerm = mult_result;
    #1
    
    factor1 = z;
    factor2 = zi;
    #1
    
    z = product;
    $display("Z2 is %h", z);
    
    half = z;
    #1
    
    secondTerm = mult_result;
    #1
    
    factor1 = z;
    factor2 = zi;
    #1
    
    z = product;
    $display("Z3 is %h", z);
    
    factor1 = a;
    factor2 = z;
    #1
    
    inter = product;
    exp = inter[30:23];
    
    $display("inter is %h", inter);
    
    exp = exp - scalefactor;  // need to adjusted with constraints
    
    
    $display("exp is %b", exp);
    
    inter[30:23] = exp;
    inter[31] = sign;
    
    if (a == 0)
        result = 32'h0;
    
    else
        result = inter;

    
end

endmodule
