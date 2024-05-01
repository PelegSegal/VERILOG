`resetall
`timescale 1ns/10ps

module stimulus_m(
interface_m.STIMULUS intf
);
  	parameter BW = 64;
	parameter DW = 16;
 	parameter ADDR_W = 32;
	parameter SP_NTARGETS = 4;
	parameter MAX_DIM = BW/DW;
	parameter Elements_Num = MAX_DIM*MAX_DIM; // How many elements in total.
	parameter string PROJECT_PATH =  $sformatf("C:/HDS/HT1/HT1_lib/hdl/files_part_2");	
	localparam time CLK_NS = 10ns; // clock period for 100MHZ
	localparam int unsigned RST_CYC = 1;		

	localparam SUB_ADDRESS_BITS = MAX_DIM > 2 ? 4 : 2; //amount of sub_adress bits depends on MAX_DIM
	localparam ADDRESS_BITS = ADDR_W - SUB_ADDRESS_BITS - 5;	// 5 lsb bits to reg address
    
	// tb Signals
	wire [BW-1:0] mat_a_flat [MAX_DIM-1:0];
    wire [BW-1:0] mat_b_flat [MAX_DIM-1:0];
	wire [BW-1:0] mat_c_flat [MAX_DIM-1:0];
    wire [BW-1:0] mat_I_flat [MAX_DIM-1:0];
	reg  [BW-1:0] line_to_print;
	integer mat_a [MAX_DIM-1:0][MAX_DIM-1:0];
    integer mat_b [MAX_DIM-1:0][MAX_DIM-1:0];
	integer mat_c [MAX_DIM-1:0][MAX_DIM-1:0];
    integer mat_I [MAX_DIM-1:0][MAX_DIM-1:0];
	integer mat_res_by_py [MAX_DIM-1:0][MAX_DIM-1:0];
	integer mat_res_by_hw [MAX_DIM-1:0][MAX_DIM-1:0];
    // parameters to read from files
    integer DW_PY, BW_PY, ADDR_W_PY, SPN, SPN_val, Mode_bit, N_file, K_file, M_file;
    // file descriptors
    integer parameter_fd, mat_a_fd, mat_b_fd, mat_c_fd, mat_i_fd, res_mat_fd;
    integer line_read_fd, line_assign_fd;
	
	string line;
	string PARAMETERS_PATH;
	string MAT_A_PATH;
	string MAT_B_PATH;
	string MAT_C_PATH;
	string MAT_I_PATH;
	string RES_MAT_PATH;
	
	assign intf.mat_res_by_py = mat_res_by_py;
	assign intf.mat_res_by_hw = mat_res_by_hw;
	assign intf.N_file        = N_file;
	assign intf.M_file        = M_file;
	assign intf.K_file        = K_file;
	assign intf.SPN_val       = SPN_val;
	assign intf.Mode_bit      = Mode_bit;
	
    genvar row,col;	
	generate // flat matrices
		for (row = 0; row < MAX_DIM; row = row + 1) begin
			for (col = 0; col < MAX_DIM; col = col + 1) begin : flat_matrices
				assign mat_a_flat[row][(col+1)*DW - 1 -: DW] = mat_a[row][col][DW-1:0];
				assign mat_b_flat[row][(col+1)*DW - 1 -: DW] = mat_b[row][col][DW-1:0];
				assign mat_c_flat[row][(col+1)*DW - 1 -: DW] = mat_c[row][col][DW-1:0];
				assign mat_I_flat[row][(col+1)*DW - 1 -: DW] = mat_I[row][col][DW-1:0];
			end
		end			
    endgenerate
	

    task read_parameters; begin
		line_read_fd = ($fgets(line, parameter_fd));
		if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading parameters line"));
		else begin
            line_assign_fd = $sscanf(line, "DW=%d, BW=%d, ADDR_W=%d, SPN=%d, SPN_val=%d, Mode_bit=%d, N=%d, K=%d, M=%d\n", DW_PY, BW_PY, ADDR_W_PY, SPN, SPN_val, Mode_bit, N_file, K_file, M_file);
		    if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign parameters vals from files to actual vals in HW"));
		end	
		if (ADDR_W_PY != ADDR_W) $fatal("[STIMULUS] Read ADDR_W= %2d\t!=\t Defined ADDR_W= %2d", ADDR_W_PY, ADDR_W);
		if (SPN       != SP_NTARGETS) $fatal("[STIMULUS] Read SPN=%2d\t!=\t Defined SPN=%2d", SPN, SP_NTARGETS);		
		if (DW_PY     != DW) $fatal("[STIMULUS] Read DW= %2d\t!=\t Defined DW= %2d", DW_PY , DW);
		if (BW_PY     != BW) $fatal("[STIMULUS] Read BW= %2d\t!=\t Defined BW= %2d", BW_PY, BW);
    end endtask


	task read_matrices; begin
		//mat_a NxK
		for (int i = 0; i < N_file && !$feof(mat_a_fd); i++) begin
			line_read_fd = $fgets(line, mat_a_fd);
			if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading mat A line"));
			else begin
				case(K_file)
					1: line_assign_fd = $sscanf(line, "%d\n", mat_a[i][0]);
					2: line_assign_fd = $sscanf(line, "%d,%d\n", mat_a[i][0], mat_a[i][1]);
					3: line_assign_fd = $sscanf(line, "%d,%d,%d\n", mat_a[i][0], mat_a[i][1], mat_a[i][2]);
					4: line_assign_fd = $sscanf(line, "%d,%d,%d,%d\n", mat_a[i][0], mat_a[i][1], mat_a[i][2], mat_a[i][3]);
					
					default: begin
						//if K value is wrong
						$display("[STIMULUS] Unexpected K value: %d", K_file);
					end
				endcase
				if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign mat A line to actual vals in HW"));
			end
		end
		
		//mat_b KxM
		for (int i = 0; i < K_file && !$feof(mat_b_fd); i++) begin
			line_read_fd = $fgets(line, mat_b_fd);
			if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading mat B line"));
			else begin
				case(M_file)
					1: line_assign_fd = $sscanf(line, "%d\n", mat_b[i][0]);
					2: line_assign_fd = $sscanf(line, "%d,%d\n", mat_b[i][0], mat_b[i][1]);
					3: line_assign_fd = $sscanf(line, "%d,%d,%d\n", mat_b[i][0], mat_b[i][1], mat_b[i][2]);
					4: line_assign_fd = $sscanf(line, "%d,%d,%d,%d\n", mat_b[i][0], mat_b[i][1], mat_b[i][2], mat_b[i][3]);
					default: begin
						//if M value is wrong
						$display("[STIMULUS] Unexpected M value: %d", M_file);
					end
				endcase
				if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign mat B line to actual vals in HW"));
			end			
		end
		
		//mat_c NxM
		for (int i = 0; i < N_file && !$feof(mat_c_fd); i++) begin
			line_read_fd = $fgets(line, mat_c_fd);
			if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading mat C line"));
			else begin
				case(M_file)
					1: line_assign_fd = $sscanf(line, "%d\n", mat_c[i][0]);
					2: line_assign_fd = $sscanf(line, "%d,%d\n", mat_c[i][0], mat_c[i][1]);
					3: line_assign_fd = $sscanf(line, "%d,%d,%d\n", mat_c[i][0], mat_c[i][1], mat_c[i][2]);
					4: line_assign_fd = $sscanf(line, "%d,%d,%d,%d\n", mat_c[i][0], mat_c[i][1], mat_c[i][2], mat_c[i][3]);
					default: begin
						//if M value is wrong
						$display("[STIMULUS] Unexpected M value: %d", M_file);
					end
				endcase
				if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign mat C line to actual vals in HW"));
			end			
		end
		
		//mat_I MxM
		for (int i = 0; i < M_file && !$feof(mat_i_fd); i++) begin
			line_read_fd = $fgets(line, mat_i_fd);
			if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading mat I line"));
			else begin
				case(M_file)
					1: line_assign_fd = $sscanf(line, "%d\n", mat_I[i][0]);
					2: line_assign_fd = $sscanf(line, "%d,%d\n", mat_I[i][0], mat_I[i][1]);
					3: line_assign_fd = $sscanf(line, "%d,%d,%d\n", mat_I[i][0], mat_I[i][1], mat_I[i][2]);
					4: line_assign_fd = $sscanf(line, "%d,%d,%d,%d\n", mat_I[i][0], mat_I[i][1], mat_I[i][2], mat_I[i][3]);
					default: begin
						//if M value is wrong
						$display("[STIMULUS] Unexpected M value: %d", M_file);
					end
				endcase
				if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign mat I line to actual vals in HW"));
			end			
		end

		//Res Mat NxM
		for (int i = 0; i < N_file && !$feof(res_mat_fd); i++) begin
			line_read_fd = $fgets(line, res_mat_fd);
			if (line_read_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading RES mat line"));
			else begin
				case(M_file)
					1: line_assign_fd = $sscanf(line, "%d\n", mat_res_by_py[i][0]);
					2: line_assign_fd = $sscanf(line, "%d,%d\n", mat_res_by_py[i][0], mat_res_by_py[i][1]);
					3: line_assign_fd = $sscanf(line, "%d,%d,%d\n", mat_res_by_py[i][0], mat_res_by_py[i][1], mat_res_by_py[i][2]);
					4: line_assign_fd = $sscanf(line, "%d,%d,%d,%d\n", mat_res_by_py[i][0], mat_res_by_py[i][1], mat_res_by_py[i][2], mat_res_by_py[i][3]);
					default: begin
						//if M value is wrong
						$display("[STIMULUS] Unexpected M value: %d", M_file);
					end
				endcase
				if (line_assign_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to assign RES mat line to actual vals in HW"));
			end			
		end
	end endtask


	task apb_master_sim; begin
		integer res_row, res_col, addr_offset;
		// initialize 
		intf.pstrb_i = {MAX_DIM{1'b0}};
        intf.pwdata_i = {BW{1'b0}};
        intf.paddr_i = {ADDR_W{1'b0}};
        intf.psel_i = 1'b0;
        intf.penable_i = 1'b0;
        intf.pwrite_i = 1'b0;
  
		
		if(Mode_bit[0]) begin: add_matC_is_on
			// assign mat c to op_a
			addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b00100}; // 5 lsb bits - op_a address
			for (int i = 0; i < 32*N_file; i = i + 32) begin
				@(posedge intf.clk);
				intf.pwrite_i = 1'b1;
				intf.psel_i = 1'b1;
				intf.paddr_i = addr_offset + i; // define the subadresses bits 
				case (M_file)
					1: intf.pstrb_i = 1'b1;
					2: intf.pstrb_i = 2'b11;
					3: intf.pstrb_i = 3'b111;
					4: intf.pstrb_i = 4'b1111;
				endcase
				intf.pwdata_i = mat_c_flat[i]; // use mat_C flat
				@(posedge intf.clk);
				intf.penable_i = 1'b1;
			end
			
			@(posedge intf.clk);
			intf.psel_i = 1'b0;
			intf.penable_i = 1'b0;
			intf.pstrb_i = {MAX_DIM{1'b0}};			
			
			// assign mat I to op_b
			addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b01000}; //5 lsb bits - op_b address
			for (int i = 0; i < 32*M_file; i = i + 32) begin
				@(posedge intf.clk);
				intf.pwrite_i = 1'b1;
				intf.psel_i = 1'b1;
				intf.paddr_i = addr_offset + i; // define the subadresses bits
				case (M_file)
					1: intf.pstrb_i = 1'b1;
					2: intf.pstrb_i = 2'b11;
					3: intf.pstrb_i = 3'b111;
					4: intf.pstrb_i = 4'b1111;
				endcase
				intf.pwdata_i = mat_I_flat[i]; // use mat_I flat
				@(posedge intf.clk);
				intf.penable_i = 1'b1;
			end
			
			@(posedge intf.clk);
			intf.psel_i = 1'b0;
			intf.penable_i = 1'b0;
			intf.pstrb_i = {MAX_DIM{1'b0}};						
			
			// start mult in order to write mat C into mem
			// assign relevant bits to control reg
			@(posedge intf.clk);
			intf.psel_i = 1'b1;
			intf.paddr_i = {ADDR_W{1'b0}}; // control reg address
			intf.pwdata_i = {{(BW-16){1'b0}}, 2'b00, (M_file[1:0] - 1'b1),  (M_file[1:0] - 1'b1), (N_file[1:0] - 1'b1), 2'b00, SPN_val[1:0], SPN_val[1:0], 1'b0, 1'b1}; 
			@(posedge intf.clk);
			intf.penable_i = 1'b1;
			@(posedge intf.clk);
			intf.psel_i = 0; intf.penable_i = 0;

			repeat (35) @(posedge intf.clk); // wait till mult is done
		end
		
		
		// assign mat A to op_a
		addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b00100}; // 5 lsb bits - op_a address
		for (int i = 0; i < 32*N_file; i = i + 32) begin
			@(posedge intf.clk);
			intf.pwrite_i = 1'b1;
			intf.psel_i = 1'b1;
			intf.paddr_i = addr_offset + i; // define the subadresses bits
			case (K_file)
				1: intf.pstrb_i = 1'b1;
				2: intf.pstrb_i = 2'b11;
				3: intf.pstrb_i = 3'b111;
				4: intf.pstrb_i = 4'b1111;
			endcase
			intf.pwdata_i = mat_a_flat[i]; // use mat_A flat
			@(posedge intf.clk);
			intf.penable_i = 1'b1;
		end
		
		@(posedge intf.clk);
        intf.psel_i = 1'b0;
        intf.penable_i = 1'b0;	
		intf.pstrb_i = {MAX_DIM{1'b0}};			
			
		// assign mat B to op_b
		addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b01000}; // 5 lsb bits - op_b address
		for (int i = 0; i < 32*K_file; i = i + 32) begin
			@(posedge intf.clk);
			intf.pwrite_i = 1'b1;
			intf.psel_i = 1'b1;
			intf.paddr_i = addr_offset + i; // define the subadresses bits
			case (M_file)
				1: intf.pstrb_i = 1'b1;
				2: intf.pstrb_i = 2'b11;
				3: intf.pstrb_i = 3'b111;
				4: intf.pstrb_i = 4'b1111;
			endcase
			intf.pwdata_i = mat_b_flat[i]; // use mat_B flat
			@(posedge intf.clk);
			intf.penable_i = 1'b1;
		end
		
		@(posedge intf.clk);
        intf.psel_i = 1'b0;
        intf.penable_i = 1'b0;
		intf.pstrb_i = {MAX_DIM{1'b0}};					
		
		// start mult in order to write mat A*B into mem
		// assign relevant bits to control reg
		@(posedge intf.clk);
		intf.psel_i = 1'b1;
		intf.paddr_i = {ADDR_W{1'b0}};
		intf.pwdata_i = {{(BW-16){1'b0}}, 2'b00, (M_file[1:0] - 1'b1),  (K_file[1:0] - 1'b1), (N_file[1:0] - 1'b1), 2'b00, SPN_val[1:0], SPN_val[1:0], Mode_bit[0], 1'b1};
		@(posedge intf.clk);
		intf.penable_i = 1'b1;
		@(posedge intf.clk);
		intf.psel_i = 0; intf.penable_i = 0;

		repeat (50) @(posedge intf.clk); // wait till mult is done
		
		case(SPN_val[1:0])
				0: addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b10000}; // SPN 1
				1: addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b10100}; // SPN 2
				2: addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b11000}; // SPN 3
				3: addr_offset = {{ADDRESS_BITS{1'b0}} ,{SUB_ADDRESS_BITS{1'b0}}, 5'b11100}; // SPN 4
		endcase
		
		//populate res_mat
		for (int i = 0; i < 32*Elements_Num; i = i + 32) begin 
			@(posedge intf.clk);
			intf.psel_i = 1'b1;
			intf.pwrite_i = 1'b0;
			intf.paddr_i = addr_offset + i;
			@(posedge intf.clk);
			intf.penable_i = 1'b1;
			@(posedge intf.clk);
			intf.psel_i = 1'b0;
			intf.penable_i = 1'b0;
			line_to_print = intf.prdata_o;
			res_row = i / MAX_DIM; 	//each mem red is MAX_DIM elements so res_row gtse valuse evry MAX_DIM
			res_col = i % MAX_DIM; 	//each mem red is MAX_DIM elements so every MAX_DIM elements we put zeros but update it in each iteration
			if (res_row < N_file && res_col < M_file) begin
				mat_res_by_hw[res_row][res_col] = $signed(line_to_print);
			end
		end
		@(posedge intf.clk);
		intf.psel_i = 0; intf.penable_i = 0;
	end endtask


	always @(negedge intf.rst_verification) begin: main_block
		if(!intf.rst_verification) begin
			intf.start_cmp = 0 ;
			N_file <= 0;
			K_file <= 0;
			M_file <= 0;
			for (int i = 0; i < MAX_DIM; i = i + 1) begin
				for (int j = 0; j < MAX_DIM; j = j + 1) begin
					mat_res_by_py[i][j] = 0;
					mat_res_by_hw[i][j] = 0;
					mat_a[i][j] = 0;
					mat_b[i][j] = 0;
					mat_c[i][j] = 0;
					mat_I[i][j] = 0;
				end 
			end

			repeat(RST_CYC) @(posedge intf.clk);
			//define files pathes
			PARAMETERS_PATH = $sformatf("%0s/parameters.txt", PROJECT_PATH);
			MAT_A_PATH 	= $sformatf("%0s/A_matrix.txt", PROJECT_PATH);
			MAT_B_PATH 	= $sformatf("%0s/B_matrix.txt", PROJECT_PATH);
			MAT_C_PATH 	= $sformatf("%0s/C_matrix.txt", PROJECT_PATH);
			MAT_I_PATH 	= $sformatf("%0s/I_matrix.txt", PROJECT_PATH);
			RES_MAT_PATH = $sformatf("%0s/res_matrix.txt", PROJECT_PATH);
			// Open files and read parameters
			parameter_fd = $fopen(PARAMETERS_PATH, "r");
			if (parameter_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", PARAMETERS_PATH));

			mat_a_fd = $fopen(MAT_A_PATH, "r");
			if (mat_a_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", MAT_A_PATH));
			
			mat_b_fd = $fopen(MAT_B_PATH, "r");
			if (mat_b_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", MAT_B_PATH));
			
			mat_c_fd = $fopen(MAT_C_PATH, "r");
			if (mat_c_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", MAT_C_PATH));
			
			mat_i_fd = $fopen(MAT_I_PATH, "r");
			if (mat_i_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", MAT_I_PATH));
			
			res_mat_fd = $fopen(RES_MAT_PATH, "r");
			if (res_mat_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed opening %s", RES_MAT_PATH)); 
			read_parameters(); // Read parameters from the parameter file
			read_matrices();
			apb_master_sim(); 
			@(posedge intf.clk);
			intf.start_cmp = 1'b1;
			@(posedge intf.clk);
			intf.start_cmp = 1'b0;
			$fclose(parameter_fd);
			$fclose(mat_a_fd);
			$fclose(mat_b_fd);
			$fclose(mat_c_fd);
			$fclose(mat_i_fd);
			$fclose(res_mat_fd);
			$display("Simulation Done\n");
						repeat(RST_CYC) @(posedge intf.clk);

			$finish;
		end
	end
endmodule