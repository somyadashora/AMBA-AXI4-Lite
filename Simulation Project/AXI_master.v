//AXI_master.v
`define WIDTH 32
module AXI_master  
	(
		input ACLK, 
		input ARESETn,
			// ADDRESS WRITE CHANNEL	
				input	AWREADY,
				output reg	AWVALID,
				output reg	[`WIDTH-1:0]	AWADDR,	
			// DATA WRITE CHANNEL
				input	WREADY,
				output reg	WVALID,
				output reg	[(`WIDTH/8)-1:0] WSTRB,
				output reg	[`WIDTH-1:0] WDATA,
			// WRITE RESPONSE CHANNEL
				input	[1:0]	BRESP,
				input	BVALID,
				output reg	BREADY,
			// READ ADDRESS CHANNEL
				input	ARREADY,
				output reg	ARVALID,
				output reg	[`WIDTH-1:0]ARADDR,
			// READ DATA CHANNEL
				input [`WIDTH-1:0]	RDATA,
				input	[1:0] RRESP,
				input	RVALID,
				output reg	RREADY,
			// Sending inputs to master which will the transfered through AXI protocol.
				input   [`WIDTH-1:0]  awaddr,
				input	[(`WIDTH/8)-1:0]   wstrb,
				input	[`WIDTH-1:0]	wdata,
				input	[`WIDTH-1:0]	araddr,
				output	reg [31:0] data_out 
		);

	//creating the master's local ram of 4096 Bytes(4 KB).
		reg	[7:0] read_mem [4095:0];


//////////////////////////////////// WRITE ADDRESS CHANNEL MASTER//////////////////////////////////
	/////////////////////////// VARIABLES FOR WRITE ADDRESS MASTER ////////////////////////////////////

		parameter [1:0] WA_IDLE_M = 2'b00,
						WA_VALID_M= 2'b01,
						WA_ADDR_M= 2'b10,
						WA_WAIT_M= 2'b11;
		reg [1:0]		WAState_M,WANext_state_M;	


	//////////////////////////////  SEQUENTIAL BLOCK
						always@(posedge ACLK or negedge ARESETn)

								if(!ARESETn)		WAState_M <= WA_IDLE_M;
								else				WAState_M <= WANext_state_M;

	//////////////////////////////	NEXT STATE DETERMINING BLOCK
						always@*
								case(WAState_M)

									WA_IDLE_M : 	if(awaddr > 32'h0)	WANext_state_M = WA_VALID_M;
													else				WANext_state_M = WA_IDLE_M;

									WA_VALID_M:		if(AWREADY)			WANext_state_M = WA_ADDR_M;
													else				WANext_state_M = WA_VALID_M;

									WA_ADDR_M:							WANext_state_M = WA_WAIT_M;
									
									WA_WAIT_M:		if(BVALID)			WANext_state_M = WA_IDLE_M;
													else				WANext_state_M = WA_WAIT_M;

									default :							WANext_state_M = WA_IDLE_M;
									
									endcase // WAState_M

	//////////////////////////////  OUTPUT DETERMINATION LOGIC
						always@(posedge ACLK or negedge ARESETn)

							if(!ARESETn) 		  AWVALID <= 1'B0;
							else		 		
								case (WANext_state_M)

									WA_IDLE_M  :  AWVALID <= 1'B0;

									WA_VALID_M :  begin AWVALID <= 1'B1;
														AWADDR  <= awaddr; end

									WA_ADDR_M  :  AWVALID <= 1'B0;

									WA_WAIT_M  :  AWVALID <= 1'B0;

									default    :  AWVALID <= 1'B0;

								endcase	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

//////////////////////////////////// WRITE DATA CHANNEL MASTER  
	/////////////////////////// VARIABLES FOR WRITE DATA MASTER ////////////////////////////////////
			parameter [1:0] 		W_IDLE_M = 2'b00,
									W_GET_M	 = 2'b01,
									W_WAIT_M = 2'b10,
									W_TRANS_M= 2'b11;
					reg [1:0]		WState_M,WNext_state_M;					
								

	//////////////////////////////////// SEQUENTIAL
						always@(posedge ACLK or negedge ARESETn)

								if(!ARESETn)				WState_M <= W_IDLE_M;
								else						WState_M <= WNext_state_M;
	/////////////////////////////////// NEXT STATE DETERMINATION
				
						always@*

								case(WState_M)

									W_IDLE_M  :  			WNext_state_M = W_GET_M;

									W_GET_M   :	if(AWREADY) WNext_state_M = W_WAIT_M;
												else		WNext_state_M = W_GET_M;

									W_WAIT_M  : if(WREADY)  WNext_state_M = W_TRANS_M;
												else		WNext_state_M = W_WAIT_M;

									W_TRANS_M : 			WNext_state_M = W_IDLE_M;
									
									default   :				WNext_state_M = W_IDLE_M;

								endcase // WNext_state_M
	////////////////////////////////// OUTPUT DETERMINING BLOCK

						always@(posedge ACLK or negedge ARESETn)

								if(!ARESETn)				WVALID <=1'B0;
								else
									case(WNext_state_M)

										W_IDLE_M  :  			WVALID <= 1'B0;

										W_GET_M   :		  begin WVALID <= 1'B0;
																WSTRB  <= wstrb;
																WDATA  <= wdata; end	


										W_WAIT_M  : 			WVALID <= 1'B1;

										W_TRANS_M : 			WVALID <= 1'B0;

										default   :				WVALID <= 1'B0;
									endcase // WNext_state_M
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////									


///////////////////////////////////// WRITE RESPONSE CHANNEL MASTER

	////////////////////////////////// VARIABLES FOR QRITE RESPONSE MASTER
				parameter [1:0] 		B_IDLE_M = 3'b00,
										B_START_M= 3'b01,
										B_READY_M= 3'b10;
									
					reg [1:0]		BState_M,BNext_state_M;

	//////////////////////////////////// SEQUENTIAL BLOCK

				always@(posedge ACLK or negedge ARESETn)

								if(!ARESETn)			BState_M <= B_IDLE_M;
								else					BState_M <= BNext_state_M;
	/////////////////////////////////// NEXT STATE DETERMINATION LOGIC

				always@*

						case(BState_M)

							B_IDLE_M  :  	if(AWREADY)		BNext_state_M = B_START_M;
											else			BNext_state_M = B_IDLE_M;

							B_START_M :     if(BVALID)		BNext_state_M = B_READY_M;
											else			BNext_state_M = B_START_M;

							B_READY_M :						BNext_state_M = B_IDLE_M;																	

							default   :						BNext_state_M = B_IDLE_M;

						endcase // BState_M
	/////////////////////////////////// OUTPUT DETERMINING LOGIC

				always@(posedge ACLK or negedge ARESETn)

						if(!ARESETn)						BREADY <= 1'B0;
						else
							case(BNext_state_M)

								B_IDLE_M  : 				BREADY <= 1'B0;

								B_START_M :					BREADY <= 1'B1;

								B_READY_M :      			BREADY <= 1'B0;

								default   :					BREADY <= 1'B0;

							endcase // BNext_state_M
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////// READ ADDR CHANNEL MASTER
	//////////////////////////// VARIABLES FOR READ ADDR CHANNEL
								parameter [1:0]		AR_IDLE_M  = 2'B00,
													AR_VALID_M = 2'B01;
													
								reg [1:0]			ARState_M,ARNext_state_M;
	//////////////////////////////////////// SEQUENTIAL BLOCK
	
								always@(posedge ACLK or negedge ARESETn)

										if(!ARESETn)								ARState_M <= AR_IDLE_M;
										else										ARState_M <= ARNext_state_M;
	//////////////////////////////////////// NEXT STATE DETERMINING BLOCK
	
								always@*

										case(ARState_M)

											AR_IDLE_M  :  if(araddr > 32'h0)		ARNext_state_M = AR_VALID_M;
														  else						ARNext_state_M = AR_IDLE_M;

											AR_VALID_M :  if(ARREADY)				ARNext_state_M = AR_IDLE_M;
														  else						ARNext_state_M = AR_VALID_M;

											
											default    : 							ARNext_state_M = AR_IDLE_M;

										endcase // ARState_M
	///////////////////////////////////////// OUTPUT DETERMINING LOGIC

								always@(posedge ACLK or negedge ARESETn)

										if(!ARESETn)								ARVALID <= 1'B0;
										else
											case(ARNext_state_M)				

												 AR_IDLE_M  : 						ARVALID <= 1'B0;

												 AR_VALID_M :				begin   ARVALID <= 1'B1;
												 									ARADDR  <= araddr; end

												 default    :						ARVALID <= 1'B0;

											endcase // ARNext_state_M
//////////////////////////////////////////////////////////////////////////////	

/////////////////////////////////// READ DATA CHANNEL MASTER
		//////////////////// VARIABLES FOR READ DATA CHANNEL
								parameter [1:0] R_IDLE_M  = 2'B00,
												R_READY_M = 2'B01;
												//R_TRAN_M  = 2'B10;
									reg   [1:0] RState_M, RNext_state_M;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
									
		///////////////////// SEQUENTIAL BLOCK
								always@(posedge ACLK or negedge ARESETn)

											if(!ARESETn)				RState_M <= R_IDLE_M;
											else						RState_M <= RNext_state_M;

		////////////////////// NEXT SATTE DETERMINATION LOGIC
								always@*

										case(RState_M)

											R_IDLE_M  :    if(ARREADY && araddr != awaddr) RNext_state_M = R_READY_M;
														   else		  			begin	   RNext_state_M = R_IDLE_M;
														   								$display("CANNOT READ WRITE AT SAME LOCATION %t",$time); end
											R_READY_M :    if(RVALID)  RNext_state_M = R_IDLE_M;
														   else		   RNext_state_M = R_READY_M;

											//R_TRAN_M  :    			   RNext_state_M = R_IDLE_M;
											
											default   :   			   RNext_state_M = R_IDLE_M;

										endcase // RState_M

		////////////////////////// OUTPUT DETERMINATION LOGIC

								always@(posedge ACLK or negedge ARESETn)

										if(!ARESETn)				   RREADY <= 1'B0;
										else
											case(RNext_state_M)

												R_IDLE_M  :			   RREADY <= 1'B0;

												R_READY_M :			 begin  RREADY <= 1'B1;
																	   data_out <= RDATA; end 

												// R_TRAN_M  :		begin  RREADY <= 1'B0;
												// 					   data_out <= RDATA; end

												default   :            RREADY <=  1'B0;
											
											endcase // RNext_state_M						   
///////////////////////////////////////////////////////////////////////////////////////////////////




													


endmodule // AXI_master						

