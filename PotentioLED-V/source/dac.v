
module dac(		input		[11:0]	inputa,
					input		[11:0]	inputb,
					output	[3:0]		pmod,
					input					clk
					);
		
		// 
		//    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24   0   1   2   3
		// _|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-
		//  ________________d11 d10 d9  d8  d7  d6  d5  d4  d3  d2  d1  d0  ____________________________________
		
		parameter wait_clocks=	8'd25;	// total clocks per send (rest dead) 
		
		reg 				sync,sclk;
		reg 	[7:0]		counter;
		reg	[15:0]	sr_a, sr_b;
		
		
		assign pmod[3:0]={sclk, sr_b[15], sr_a[15], sync};
		
		always@(posedge clk)
				sclk <=!sclk;
				
		always@(posedge sclk)
		begin
			if(counter >= (wait_clocks-1) )
			begin
				counter 		<= 8'b0;  // start at 1, makes math easier.
				sync        <= 1'b1;
			end
			else if(counter==0)
			begin
				counter 		<= counter+8'b1;
				sr_a[15:0] 	<= {4'b0,inputa};
				sr_b[15:0] 	<= {4'b0,inputb};
				sync 			<= 1'b0;
			end
			else
			begin
				counter 		<= counter+8'b1;
				sr_a[15:0]	<= {sr_a[14:0],1'b0};
				sr_b[15:0]	<= {sr_b[14:0],1'b0};
				sync		 	<= 1'b0;
			end
		end
endmodule