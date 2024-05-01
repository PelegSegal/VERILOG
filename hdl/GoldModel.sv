//
// Verilog Module HT1_lib.GoldModel
//
// Created:
//          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
//          at - 17:42:03 15/04/2024
//
// using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
//

`resetall
`timescale 1ns/10ps

module GoldModel(
  	interface_m.GOLDEN intf
);
    parameter BW = 64;
	parameter DW = 16;
    parameter ADDR_W = 32;
	parameter SP_NTARGETS = 4;

	// tb Params
	localparam time CLK_NS = 10ns; // 100MHz Clock
	localparam int unsigned rst_cycle = 1;
	localparam MAX_DIM = BW/DW;

	integer i, j, error_count;
	integer total_err_counter;

	always @(posedge intf.clk or negedge intf.rst_verification) begin: golden_cmp
		if (!intf.rst_verification) begin
			total_err_counter = 0;
			intf.cmp_err_flag = 0;
		end
		else if( intf.start_cmp) begin
			error_count = 0;
			for (i = 0; i < intf.N_file; i = i + 1) begin
				for (j = 0; j < intf.M_file; j = j + 1) begin
					if (intf.mat_res_by_py[i][j] !== intf.mat_res_by_hw[i][j]) begin
						$display("[GOLDEN] Differrent values in RES_mat [%1d][%1d]: Expected %0d, Got %0d", i, j, intf.mat_res_by_py[i][j], intf.mat_res_by_hw[i][j]);
						error_count = error_count + 1;
					end
				end 
			end
			if (error_count == 0) begin
				intf.cmp_err_flag = 0;
			end else begin
				$display("[GOLDEN] Verification failed. Errors amount: %0d mismatches.\n", error_count);
				total_err_counter = total_err_counter + 1;
				intf.cmp_err_flag = 1;
			end			
		end
	end
endmodule

