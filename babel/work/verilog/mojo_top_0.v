module mojo_top_0(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0]led,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    
    inout sda,
    
    output scl,
    
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full,
    output busy_pinout,
    output start
    );

wire rst = ~rst_n; // make reset active high

// these signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;
reg [7:0]led_out;
reg [8:0]counter;
reg prev_rst;
reg filtered_rst;
assign start = start_mpu;
always @(posedge clk)
begin
 if (filtered_rst == 1 && prev_rst ==0)
   led_out <= led_out + 1;
 
  prev_rst <= filtered_rst;
if(rst != filtered_rst)
    begin
      counter <= counter + 1;
      start_mpu <= 1;
    end
  else
    begin
      counter <= 0;
      start_mpu <= 0;
    end
if(counter > 100)
  begin
   filtered_rst <= rst;
  end
end

assign led[6:0] = led_out[6:0];
assign led[7] = mpu_busy;
assign busy_pinout = mpu_busy;

wire mpu_busy;
reg start_mpu = 0;

mpu_9150_1 mpu_9150(
    // 50MHz clock input
    .clk(clk),

    // i2c data 
    .sda(sda),
    // i2c clock - no clock stretching supported
    .scl(scl),

    //the start condition 
    .sample_start(start_mpu),
    
    .mod_busy(mpu_busy)
    );
    
    
endmodule