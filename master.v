module master (

	/*...signal with comment
		 F -> full implemented 
		 P-> partially implemented
		 N-> Not implemented (Not used at all)*/

	/*.....................application dependency signals.....................*/
	input 				start,				//F 		/*start sending data*/  
	input 				Burst,				//F  		/*start sending Burst*/ 
	input [31:0] 		AWDATA, 			//F
	input [31:0] 		AADDR,  			//F
	input [2:0]  		ASIZE,  			//F
	input [2:0]  		ABURST, 			//F
	input [1:0]  		ATRANS, 			//F
	input 		 		AWRITE, 			//F
	output reg	 		hold,   			//F         /*telling the master to Stop sending any new input*/  
	output reg [31:0] 	ARDATA,				//F 		/*Master interface send the valid data to the master to read*/	

	/*.....................AHB Standard signals.....................................*/

	/* global inputs */
	input 				HCLK,    			//F
	input 				HRESETn, 			//F
	
	/* inputs from slaves */	
	input 				HREADY,				//F 
	input 				HRESP,				//N
	input [31:0]	    HRDATA,				//F

	/* output to Slaves , interconnectes */
	output reg [31:0] 	HADDR, 				//F
	output reg [31:0] 	HWDATA,				//F
	output reg        	HWRITE,				//F
	output reg[2:0]   	HSIZE, 				//P
	output reg[2:0]   	HBURST,				//P
	output reg[1:0]   	HTRANS,				//P
	output reg	      	HMASTLOCK,			//N
	output reg[3:0]   	HPROT 				//N
	
);

/*.......the states of AHB Master interface , and bust isn't supported here.......*/
parameter Idle=0;
parameter non_seq=1;
parameter seq=2;
reg [1:0] cs,ns;

/*.......the types of Burst which are supported here.......*/
parameter SINGLE=0;
parameter INCR=1;

/* Regarding the HSIZE since we just worked on 32 Bus (Mux) so we will support up to 32 Byte
they must remain constant throughout a burst transfer.
*/


/*registered value from the input data because there is a one shift cycle between reading and writing 
	assuming that the master gives you both of address and data at the same cycle*/

reg[31:0]	AWDATA_R;

reg[3:0] 	trans_shift; 				//mapping the HSIZE to realy shift 
reg 		HWRITE_filtered; 			//register to store the last value in case of non ready 

/*........................regester the inputs and mapping it..............................*/ 

always @(posedge HCLK or negedge HRESETn )  
begin
	if(~HRESETn)
	begin
			HWRITE<=0;
			hold<=0;
			HWRITE_filtered<=0;
			HTRANS<=0;
			HSIZE<=0;
			HBURST<=0;
	end
	else 
	begin
		if(HREADY==0) // Keep the old value untill the ready be one again 
		begin
			hold<=1;
		end
		
		else
		begin
			hold<=0;
			AWDATA_R<=AWDATA; 
			HWRITE<=AWRITE;
			HWRITE_filtered<=HWRITE; //here i'm sure that ready=1 else i won't register it to keep the last value before ready was down
			HTRANS<=ATRANS;

			/*mapping the size (BYTE - half_word- word)*/
			HSIZE<=ASIZE;
			/*mapping the burst type (single - INCR)*/
			if(ABURST==3'b000 ||ABURST==3'b001 ) // signle or INCR take it
			begin
				HBURST<=ABURST;
			end
			else
			begin
				HBURST<=3'b001; // if it other case , map it INCR
			end
		end
	end	
end

/*..........................................Mapping HSIZE...........................................*/
always @(*)
begin
	case(HSIZE)
	3'd0:	trans_shift=1;
	3'd1:	trans_shift=2;
	3'd2:	trans_shift=4;
	default:trans_shift=4; //if it other , map it to word
	endcase
end




/*........................calculating the next state from the FSM..............................*/ 
always @(*) 
begin 
	case (cs)
		Idle:begin
			if(HREADY==0) // In case of non ready slave stay as it is 
			begin
				ns=Idle;
			end
			else
			begin
				if(start==0)
				begin
					ns=Idle;
				end
				if(start==1)
				begin
					ns=non_seq;
				end	
			end
			 end

		non_seq:begin
				if(HREADY==0) // In case of non ready slave stay as it is
				begin
					ns=non_seq;
				end
				else
				begin

					if(start==0)
					begin
						ns=Idle;
					end
					else if (start==1&& Burst==1) begin
						ns=seq;
					end

					else if(start==1)
					begin
						ns=non_seq;
					end
				end
				end

		seq:begin
				if(HREADY==0) // In case of non ready slave stay as it is
				begin
					ns=seq;
				end
				else
				begin
					if(start==0 && Burst==0)
					begin
						ns=Idle;
					end
					else if (start==1&& Burst==1) begin
						ns=seq;
					end

					else if(start==1&& Burst==0)
					begin
						ns=non_seq;
					end
				end
				end				
		default : ns=Idle;
	endcase
end


/*........................moving the next state to be the next state..............................*/ 
always @(posedge HCLK or negedge HRESETn) 
begin 
	if(~HRESETn) 
	begin
		 cs<= 0;
	end
	else
	begin
		 cs<=ns ;
	end
end

/*..calculating the output from input ,current state but giving the output at the positive edge of the clock (registed) ..*/ 

always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn) 
	begin
		 HADDR<= 0;
		 HWDATA<=0;
		 ARDATA<=0;

	end
	else 
	begin
		/* ...............................Idle -> Idle (no change) .............................................*/
		if(cs==Idle&&start==0)
		begin
			HADDR<=0;
			HWDATA<=0;
	
			/*.......because the read operation can come after reutrn to idle case look at Figure 3-1 Read transfer
					 but without B transaction But we can't write ....*/
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end
	
		/* ...............................Idle -> non_seq.............................................*/	
		else if	(cs==Idle&&start==1)
		begin
			HADDR<=AADDR;
			HWDATA<=0;
		end
	
		/* ...............................non_seq -> Idle.............................................*/	
		else if (cs==non_seq && start==0 && HREADY==1 ) //get back from non_seq -> idle  (Master has just send one frame)
		begin
			HADDR<=0;
			if(HWRITE==1)
				begin
					HWDATA<=AWDATA_R;
				end	
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end
	
		/* ...............................non_seq -> non_seq (no change) .............................................*/	
		/*.......................Master send more than one frame (but not burst).........................*/
		else if (cs==non_seq && start==1 && HREADY && ~Burst) 
		begin
			HADDR<=AADDR;
			if(HWRITE==1)
				begin
					HWDATA<=AWDATA_R;
				end		
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end
	
		/* ...............................non_seq -> seq.............................................*/	
		else if (cs==non_seq && start==1 && HREADY && Burst) //(Burst (seq) )
		begin
			HADDR<=HADDR+trans_shift;
			if(HWRITE==1)
				begin
					HWDATA<=AWDATA_R;
				end		
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end	
	
		/* ...............................seq -> seq (no change) .............................................*/	
		else if (cs==seq && start==1 && HREADY && Burst) //(Burst (seq) doesn't end yet )
		begin
			HADDR<=HADDR+trans_shift;
			if(HWRITE==1)
				begin
					HWDATA<=AWDATA_R;
				end		
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end	
	
	
		/* ...............................seq -> non_seq .............................................*/	
		else if (cs==seq && start==1 && HREADY && ~Burst) //(Burst have just endded now and another transaction will heppen )
		begin
			/*seq->non_seq */
			HADDR<=AADDR;
			if(HWRITE==1)
			begin
					HWDATA<=AWDATA_R;
			end		
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end
			end
		end		
	
		/* ...............................seq -> idle .............................................*/	
		else if (cs==seq && ~start && HREADY && ~Burst) //(Burst endded and no other (non_seq transfere -> idle) )
		begin
			HADDR<=0;
			if(HWRITE==1)
			begin
				HWDATA<=AWDATA_R;
			end		
			if(HWRITE_filtered==0 )
			begin
				if(HREADY==1)
				begin
					ARDATA<=HRDATA;
				end	
			end
		end	
	end
end
endmodule 