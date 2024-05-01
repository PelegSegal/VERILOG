
`resetall
`timescale 1ns/10ps

interface interface_m(input wire clk, input wire rst_verification);

  	parameter BW = 64;
	parameter DW = 16;
 	parameter ADDR_W = 32;
	parameter SP_NTARGETS = 4;

	// tb Params
	localparam time CLK_NS = 10ns; // 100MHz Clock
	localparam int unsigned rst_cycle = 1;
	localparam MAX_DIM = BW/DW;

	logic psel_i;
    logic penable_i;
    logic pwrite_i;
    logic [MAX_DIM-1:0] pstrb_i;
    logic [-1:0] pwdata_i;
    logic [ADDR_W-1:0] paddr_i;
    logic [-1:0] prdata_o;
    logic pready_o;
    logic pslverr_o;
    logic busy_o;
	logic start_cmp;
	logic cmp_err_flag;
	integer N_file, M_file, K_file, SPN_val, Mode_bit;
	integer mat_res_by_py [MAX_DIM-1:0][MAX_DIM-1:0];
	integer mat_res_by_hw [MAX_DIM-1:0][MAX_DIM-1:0]; 

	modport DUT 	 (input clk, rst_verification, psel_i, penable_i, pwrite_i, pstrb_i, pwdata_i, paddr_i, 
					  output pready_o, pslverr_o, prdata_o, busy_o);
	modport STIMULUS (input clk, rst_verification, prdata_o, pready_o, pslverr_o, busy_o,
					  output psel_i, penable_i, pwrite_i, pstrb_i, pwdata_i, paddr_i, start_cmp, mat_res_by_py ,mat_res_by_hw ,N_file, K_file, M_file, SPN_val, Mode_bit);
	modport GOLDEN	 (input clk, rst_verification, start_cmp, mat_res_by_py, mat_res_by_hw, N_file, M_file, 
					  output cmp_err_flag);	
endinterface
