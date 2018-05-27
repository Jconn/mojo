module IIR(
	input signed 	[11:0] 		x ,
	output	[11:0] 	 	digOut ,
	input  							    clk    //50 khz
	);
    reg [11:0] inData;
    always @(posedge clk)
    begin
      inData <= x;
    end
    
    
    wire signed [11:0] acc;
    wire signed [12:0] expanded;
    parameter COEFFS = 40;
    parameter BIQUADS=8;
    wire signed [16:0] coef  [COEFFS-1:0];
    //we are using a biquad IIR filter
    wire signed [11:0] interm[BIQUADS-1:1];
    assign coef[0] = 0;
    assign coef[1] = 0;
    assign coef[2] = 0;
    assign coef[3] = -65522;
    assign coef[4] = 32754;
    assign coef[5] = 0;
    assign coef[6] = 0;
    assign coef[7] = 0;
    assign coef[8] = -65498;
    assign coef[9] = 32730;
    assign coef[10] = 0;
    assign coef[11] = 0;
    assign coef[12] = 0;
    assign coef[13] = -65485;
    assign coef[14] = 32717;
    // filter 17Q15, input 12Q11, result 29Q26
    //we have eight biquads now -> resulted in 256 percent overutilization
    //five biquads -> resulted in 159% overutilization of MUXCYS
    
    biquad s0(x, interm[1], clk, coef[0], coef[1], coef[2], coef[3], coef[4]);
    biquad s1(interm[1], interm[2], clk, coef[5], coef[6], coef[7], coef[8], coef[9]);
    biquad s2(interm[2], acc, clk, coef[10], coef[11], coef[12], coef[13], coef[14]);
    /*
    biquad s3(interm[3], interm[4], clk, coef[15], coef[16], coef[17], coef[18], coef[19]);
    biquad s4(interm[4], acc, clk, coef[20], coef[21], coef[22], coef[23], coef[24]);   
    biquad s5(interm[5], interm[6], clk, coef[25], coef[26], coef[27], coef[28], coef[29]);
    biquad s6(interm[6], interm[7], clk, coef[30], coef[31], coef[32], coef[33], coef[34]);
    biquad s7(interm[7], acc, clk, coef[35], coef[36], coef[37], coef[38], coef[39]);
    */
    assign expanded = acc + 13'sh08000; 
    assign digOut = expanded[11:0];
    // give us a bias so that everything is positive again.
    //dac can only output positive values,   potentially might be better to 
    //give the dac a signed value and have it handle the biasing
endmodule



module biquad(	
	input signed 	[11:0] 		x , 	// 12 Q 11
	output reg signed 	[11:0] 	 	acc ,	//	12 Q 11
	input  							clock,
	input				[16:0]		b0,	//17 Q 15
	input				[16:0]		b1,	//17 Q 15
	input				[16:0]		b2,	//17 Q 15
	input				[16:0]		a1,	//17 Q 15
	input				[16:0]		a2	//17 Q 15
	);
	
	reg signed [28:0] delay_1;
	reg signed [28:0] delay_2;
	reg signed [28:0] temp;
	reg signed [2:0]	integer_bits;
	
	// update
	always@(posedge clock)
	begin
	temp = delay_2 + b0*x;
	integer_bits = temp[28:26];
	if(integer_bits >= 1)
		acc = 12'h7ff;
	else if (integer_bits < -1)
		acc = 12'h800;
	else
		acc = temp[26:15];
	delay_2 = delay_1 + b1*x - a1*acc;	
	delay_1 = b2*x- a2*acc;
	end
	
	
endmodule