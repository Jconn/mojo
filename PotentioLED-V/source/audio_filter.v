

module audio_filter(
	input  [11:0] 		aSyncData ,
	output	[11:0] 	 	filterOut,
	input  							clk //50 khz clock
  );
  wire signed [11:0] y;
  reg signed [12:0] x;
  wire signed [12:0] tempOut;
  parameter ORDER = 50;	
  reg signed  [27:0] delay [ORDER:1]; //TRANSPOSE FORM
  wire signed [15:0] coef  [ORDER:0];
  reg signed [28:0] sum;
    
    assign coef[0] = 1051;
    assign coef[1] = 220;
    assign coef[2] = 199;
    assign coef[3] = 146;
    assign coef[4] = 61;
    assign coef[5] = -51;
    assign coef[6] = -183;
    assign coef[7] = -323;
    assign coef[8] = -457;
    assign coef[9] = -570;
    assign coef[10] = -645;
    assign coef[11] = -668;
    assign coef[12] = -626;
    assign coef[13] = -510;
    assign coef[14] = -315;
    assign coef[15] = -44;
    assign coef[16] = 296;
    assign coef[17] = 692;
    assign coef[18] = 1126;
    assign coef[19] = 1574;
    assign coef[20] = 2012;
    assign coef[21] = 2415;
    assign coef[22] = 2758;
    assign coef[23] = 3019;
    assign coef[24] = 3184;
    assign coef[25] = 3240;
    assign coef[26] = 3184;
    assign coef[27] = 3019;
    assign coef[28] = 2758;
    assign coef[29] = 2415;
    assign coef[30] = 2012;
    assign coef[31] = 1574;
    assign coef[32] = 1126;
    assign coef[33] = 692;
    assign coef[34] = 296;
    assign coef[35] = -44;
    assign coef[36] = -315;
    assign coef[37] = -510;
    assign coef[38] = -626;
    assign coef[39] = -668;
    assign coef[40] = -645;
    assign coef[41] = -570;
    assign coef[42] = -457;
    assign coef[43] = -323;
    assign coef[44] = -183;
    assign coef[45] = -51;
    assign coef[46] = 61;
    assign coef[47] = 146;
    assign coef[48] = 199;
    assign coef[49] = 220;
    assign coef[50] = 1051;
	integer i;

	// TRANSPOSE FORM 

	always@(posedge clk)
	begin
    x <= aSyncData;
		sum <= x * coef[0] + delay[1];
	end
	
	always@(posedge clk)
	begin
		delay[ORDER] <= x * coef[ORDER];
		for(i = 1; i <= ORDER-1;i = i+1)
			delay[i] <= delay[i+1] + x*coef[i];
	end

	assign y= (sum[28:27]==2'b10) ? 12'h800:  
				    (sum[28:27]==2'b01) ? 12'h7ff: 
            sum[27:16];
  assign tempOut = y + 13'sd2048;
  assign filterOut = tempOut[11:0] + tempOut[11:0];
endmodule
