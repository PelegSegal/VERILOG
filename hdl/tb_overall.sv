//
// Verilog Module HT1_lib.tb_overall
//
// Created:
//          by - NadavHugi.UNKNOWN (DESKTOP-9P9608N)
//          at - 17:42:03 15/04/2024
//
// using Mentor Graphics HDL Designer(TM) 2021.1 Built on 14 Jan 2021 at 15:11:42
//

`resetall
`timescale 1ns/10ps

module tb_overall;
  	parameter BW = 64;
	parameter DW = 16;
 	parameter ADDR_W = 32;
	parameter SP_NTARGETS = 4;
	
	// tb Params
	localparam time CLK_NS = 10ns; // 100MHz Clock
	localparam int unsigned rst_cycle = 1;
	localparam MAX_DIM = BW/DW;
	
	// signals
	logic clk = 1'b0, rst_verification;
	//instances
	interface_m intf(
		.clk(clk), .rst_verification(rst_verification)
	);

	//init rst
	initial begin: tb_overall_rst
		rst_verification = 1'b0; 
		repeat(rst_cycle) @(posedge clk);
		rst_verification = 1'b1; 
	end		
	
	//init clk
	initial forever 
		#(CLK_NS/2) clk = ~clk;
	
	// instantiations
	GoldModel golden_instance (
		.intf(intf)
	);
	stimulus_m stimulus_instance (
		.intf(intf)
	);
	
	// DUT 
	matmul #(
        .DW(DW),
        .BW(BW),
        .ADDR_W(ADDR_W),
		.SP_NTARGETS(SP_NTARGETS)
    ) matmul_instance (
        .clk_i(clk),
        .reset_ni(rst_verification),
        .psel_i(intf.psel_i),
        .penable_i(intf.penable_i),
        .pwrite_i(intf.pwrite_i),
        .pstrb_i(intf.pstrb_i),
        .pwdata_i(intf.pwdata_i),
        .paddr_i(intf.paddr_i),
        .pready_o(intf.pready_o),
        .pslverr_o(intf.pslverr_o),
	    .prdata_o(intf.prdata_o),
        .busy_o(intf.busy_o)
    );
endmodule