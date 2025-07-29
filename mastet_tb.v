module mastet_tb ();

reg Burst_tb;
reg 	    start_tb;
reg [31:0]  AWDATA_tb;
reg [31:0]  AADDR_tb;
reg [2:0]   ASIZE_tb;
reg [2:0]   ABURST_tb;
reg [1:0]   ATRANS_tb;
reg 		AWRITE_tb;
wire 		hold_tb;
wire [31:0] WRDATA_tb;
reg 		HCLK_tb;    
reg 		HRESETn_tb; 
reg 		HREADY_tb;
reg 		HRESP_tb;
reg  [31:0] HRDATA_tb;
wire [31:0] HADDR_tb;
wire [31:0] HWDATA_tb;
wire 	    HWRITE_tb;
wire [2:0]  HSIZE_tb;
wire [2:0]  HBURST_tb;
wire [3:0]  HPROT_tb;
wire [1:0]  HTRANS_tb;
wire 		HMASTLOCK_tb;


master Dut (
	.Burst(Burst_tb),
	.start(start_tb),
	.AWDATA(AWDATA_tb),
	.AADDR(AADDR_tb),
	.ASIZE(ASIZE_tb),
	.ABURST(ABURST_tb),
	.ATRANS(ATRANS_tb),
	.AWRITE(AWRITE_tb),
	.hold(hold_tb),
	.ARDATA(WRDATA_tb),
	.HCLK(HCLK_tb),    
	.HRESETn(HRESETn_tb), 
	.HREADY(HREADY_tb),
	.HRESP(HRESP_tb),
	.HRDATA(HRDATA_tb),
	.HADDR(HADDR_tb),
	.HWDATA(HWDATA_tb),
	.HWRITE(HWRITE_tb),
	.HSIZE(HSIZE_tb),
	.HBURST(HBURST_tb),
	.HPROT(HPROT_tb), //Not implemented
	.HTRANS(HTRANS_tb),
	.HMASTLOCK(HMASTLOCK_tb) //Not implemented
);

initial 
begin
	HCLK_tb=0;
	forever
	begin
		#5;
		HCLK_tb=~HCLK_tb;
	end	
end

initial 
begin

	Read_transfer();
	reset_between_cycles();

	Write_transfer();
	reset_between_cycles();

	Read_transfer_with_wait_states();
	reset_between_cycles();

	write_transfer_with_wait_states();
	reset_between_cycles();

	Multiple_transfers();
	reset_between_cycles();

	Transfer_type_examples();
	reset_between_cycles();

	Undefined_length_bursts();
	reset_between_cycles();


	$stop;
end

/*.....................Tasks for each trancation for readability ............................................*/

/* clean_cycle*/
task clean_cycle;
	begin
		HREADY_tb=1; HRESETn_tb=0; 
		@(negedge HCLK_tb);
	end
	
endtask 

/* Figure 3-1 Read transfer*/
task Read_transfer;
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; AADDR_tb=32'hA; AWRITE_tb=0; ATRANS_tb=1; /*Non_seq*/ Burst_tb=0;
	@(negedge HCLK_tb);
	AADDR_tb=32'hB; AWRITE_tb=1; ATRANS_tb=0; //idle
	@(negedge HCLK_tb);
	HRDATA_tb=5;
	@(negedge HCLK_tb);
end
endtask 

/* Figure 3-2 Write transfer*/
task Write_transfer;
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; AADDR_tb=32'hA; AWRITE_tb=1; AWDATA_tb=8;  ATRANS_tb=1; /*Non_seq*/ Burst_tb=0;
	@(negedge HCLK_tb);
	AADDR_tb=32'hB; AWRITE_tb=1; AWDATA_tb=2;  ATRANS_tb=0; //idle
	@(negedge HCLK_tb);
end
endtask 

/*Figure 3-3 Read transfer with wait states*/
task Read_transfer_with_wait_states;
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; AADDR_tb=32'hA; AWRITE_tb=0; ATRANS_tb=1; /*Non_seq*/ Burst_tb=0;
	@(negedge HCLK_tb);
	AADDR_tb=32'hB; AWRITE_tb=1; ATRANS_tb=1;  //Non_seq
	@(posedge HCLK_tb);
	HREADY_tb=0;
	@(negedge HCLK_tb);
	ATRANS_tb=0; start_tb=0; //idle
	@(posedge HCLK_tb);
	@(posedge HCLK_tb);
	HREADY_tb=1;
	@(negedge HCLK_tb);
	HRDATA_tb=5;
	@(negedge HCLK_tb);
	@(negedge HCLK_tb);
end
endtask 

/*Figure 3-4 write transfer with wait states*/
task write_transfer_with_wait_states();
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; AWDATA_tb=9; AADDR_tb=32'hA; AWRITE_tb=1; ATRANS_tb=1; /*Non_seq*/ Burst_tb=0;
	@(negedge HCLK_tb);
	AADDR_tb=32'hB; AWRITE_tb=0; ATRANS_tb=1;  //Non_seq
	@(posedge HCLK_tb);
	HREADY_tb=0;
	@(negedge HCLK_tb);
	ATRANS_tb=0; start_tb=0; //idle
	@(posedge HCLK_tb);
	HREADY_tb=1;
	@(negedge HCLK_tb);
end
endtask 

/*Figure 3-5 Multiple transfers*/	
task Multiple_transfers();
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; AWDATA_tb=9; AADDR_tb=32'hA; AWRITE_tb=1; ATRANS_tb=1; /*Non_seq*/ Burst_tb=0;
	@(negedge HCLK_tb);
	AADDR_tb=32'hB; AWRITE_tb=0; ATRANS_tb=1;  //Non_seq
	@(negedge HCLK_tb);
	AADDR_tb=32'hC; AWRITE_tb=1; AWDATA_tb=2; ATRANS_tb=1;  //Non_seq
	@(posedge HCLK_tb);
	HREADY_tb=0;
	@(negedge HCLK_tb);
	ATRANS_tb=0; start_tb=0; //idle
	@(posedge HCLK_tb);
	HREADY_tb=1;
	@(negedge HCLK_tb);
	HRDATA_tb=5;
	@(negedge HCLK_tb);
	@(negedge HCLK_tb);
end
endtask 

/*3-6 Transfer type examples*/
task Transfer_type_examples();
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; Burst_tb=0;  AADDR_tb=32'h20; AWRITE_tb=0; ATRANS_tb=1; //Non_seq
	ABURST_tb=1; ASIZE_tb=2; //shift size is 4 
	@(negedge HCLK_tb);
	ATRANS_tb=2; Burst_tb=1;  //seq 
	@(negedge HCLK_tb);
	HRDATA_tb=32'h20;  //seq 
	@(negedge HCLK_tb);
	HRDATA_tb=32'h24; 
	@(posedge HCLK_tb);
	HREADY_tb=0;
	@(negedge HCLK_tb);
	/*here the master has ended its transaction and regarding the wait due to slave's unready the 
	master interface will handle it internally */
	HRDATA_tb=32'h28; start_tb=0; Burst_tb=0; ASIZE_tb=0; ABURST_tb=0; ATRANS_tb=0;//Back to idle 
	@(posedge HCLK_tb);
	HREADY_tb=1;
	repeat(2) @(negedge HCLK_tb);
	HRDATA_tb=32'h2C;
	@(negedge HCLK_tb);
end
endtask 

//3-12 Undefined_length_bursts
task Undefined_length_bursts;
begin
	clean_cycle();
	HRESETn_tb=1; start_tb=1; Burst_tb=0;  AADDR_tb=32'h20; AWRITE_tb=1;/*write*/ ATRANS_tb=1; /*Non_seq*/
	AWDATA_tb=32'h20; ABURST_tb=1;/*INCR*/ ASIZE_tb=1; /*shift size is 2 Half_Word*/ 		/*Before T0*/
	@(negedge HCLK_tb);
	Burst_tb=1;  ATRANS_tb=2; AWDATA_tb=32'h22; /*seq*/ 									/*Before T1*/
	@(negedge HCLK_tb);
	Burst_tb=0; AWRITE_tb=0;/*read*/ ATRANS_tb=1; /*Non_seq*/ AADDR_tb=32'h5C;/*pushing new address*/
	ABURST_tb=1;/*INCR*/ ASIZE_tb=2; /*shift size is 4 Word*/ 			/*Before T2*/
	@(negedge HCLK_tb);
	Burst_tb=1;  ATRANS_tb=2; /*seq*/  /*Before T3*/
	@(posedge HCLK_tb);
	HREADY_tb=0;														/*at T3*/
	@(posedge HCLK_tb);
	HREADY_tb=1;														/*at T4*/
	@(negedge HCLK_tb);
	HRDATA_tb=32'h5C;	/*slave write the new data*/  					/*Before T5*/
	@(negedge HCLK_tb);
	HRDATA_tb=32'h60; /*slave write the new data*/  start_tb=0; /*end the connection*/ 
	Burst_tb=0; /*finish the Burst*/  ATRANS_tb=0; /*IDLE*/
	ABURST_tb=0; /*single*/ ASIZE_tb=0;									/*Before T6*/
	@(negedge HCLK_tb);
	HRDATA_tb=32'h64;	/*slave write the new data*/ 					 /*Before T7*/
	@(negedge HCLK_tb);
end
endtask

/* rest to begin new test (idle)*/
task reset_between_cycles;
begin

	HREADY_tb=1; HRESETn_tb=0; start_tb=0; ATRANS_tb=0; //idle
	@(negedge HCLK_tb);
	@(negedge HCLK_tb);
	@(negedge HCLK_tb);
end
endtask 
endmodule 
