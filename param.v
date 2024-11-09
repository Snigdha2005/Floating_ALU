`define A_E_WIDTH 8
`define B_E_WIDTH 8
`define A_M_WIDTH 7
`define B_M_WIDTH 7
`define ADD_SIGNAL 1
`define A_WIDTH (`A_E_WIDTH + `A_M_WIDTH + 1)
`define B_WIDTH (`B_E_WIDTH + `A_M_WIDTH + 1)
`define OUT_E_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_E_WIDTH):(`B_E_WIDTH)
`define OUT_M_WIDTH (`A_E_WIDTH > `B_E_WIDTH)?(`A_M_WIDTH):(`B_M_WIDTH)
`define OUT_WIDTH (`OUT_E_WIDTH + `OUT_M_WIDTH + 1)