module spi_master_3 (
    input clk,  // clock
    input rst,  // reset
    input xmit,
    input sclk,  //spi clock baby
    input wire [15:0]inputData,
    output reg [15:0]recvData,
    input miso,
    output wire mosi,
    output reg ss
  );
  reg [4:0]curbit;
  reg [1:0] sclk_state;
  reg state;
  reg init_flag;
  reg [15:0]xmitData;
  /* Combinational Logic */
  assign mosi = xmitData[15-curbit];
  always @* begin
    
  end
  
  /* Sequential Logic */
  always @(posedge clk) begin
    sclk_state[1] <= sclk_state[0];
    sclk_state[0] <= sclk;
    
    if (rst) begin
      ss <= 1;  
    end 
    else 
    begin
      if(ss == 0 ) //we should begin the transaction
      begin
        if(sclk_state[1] == 1 && sclk_state[0] == 0 && init_flag) begin //falling edge
        // on falling edge of spi clock alter the bit, we are outputting
            curbit <= curbit + 1;
        end
        if(sclk_state[1] == 0 && sclk_state[0] == 1) begin //rising edge
        //rising edge of spi clock, clock in our bit
          init_flag <= 1;
          recvData[15-curbit] <= miso;
        end
      
        ss <= (curbit == 16);  //set to high when curbit hits 16, we are done with transaction at that time
      end
      else
      begin
          curbit <= 0;
          ss <= xmit;
          init_flag <= xmit;  //compensates for the case when we see a falling edge before the rising edge
                               //at the beginning of a transaction
      end
      if(xmit==1)
       begin
         xmitData <= inputData;
       end
     
  end
  
  
  end /* sequential logic end */
  
endmodule
