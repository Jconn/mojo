module mojo_top(
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
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full
    output mic_out, //output to the mic
    output mcp_mosi,
    output mcp_ss,
    output mcp_clk
  );
  assign mic_out =1;
  wire rst = ~rst_n; // make reset active high
   
  wire [3:0] channel;
  wire new_sample;
  wire [9:0] sample;
  wire [3:0] sample_channel; 
  wire [9:0] adc_temp;
  avr_interface avr_interface (
    .clk(clk),
    .rst(rst),
    .cclk(cclk),
    .spi_miso(spi_miso),
    .spi_mosi(spi_mosi),
    .spi_sck(spi_sck),
    .spi_ss(spi_ss),
    .spi_channel(spi_channel),
    .tx(avr_rx),
    .rx(avr_tx),
    .channel(channel),
    .new_sample(new_sample),
    .sample(sample),
    .sample_channel(sample_channel),
    .tx_data(8'h00),
    .new_tx_data(1'b0),
    .tx_busy(),
    .tx_block(avr_rx_busy),
    .rx_data(),
    .new_rx_data()
  );
  
  input_capture input_capture (
    .clk(clk),
    .rst(rst),
    .channel(channel),
    .new_sample(new_sample),
    .sample(sample),
    .sample_channel(sample_channel),
    .led(led),
    .sample_q(adc_temp)
    
  );
  
  
  //mcp 4921 supports up to 20 MHz clock,
  //let's give it a 1 Mhz clock
  wire mcp_xmit;
  parameter FTV_VAL = 1;
  reg [6:0] mcp_count;
  reg [9:0] khz_50_count;
  reg [31:0] ss_count;
  assign mcp_clk = mcp_count < 25;
  assign mcp_xmit = ss_count > 1500;
  assign khz_50_clk = khz_50_count < 500;
  wire [15:0]mcp_data;
  wire signed [15:0]dds_out;
  wire signed [11:0]truncated;
  wire signed [16:0] tempSignedConv;
  wire [11:0]filter_out;
  wire [11:0]audioData;
  assign mcp_data =  {4'h3,/*adc_temp*/ /*dds_out*/ /*filter_out*/ audioData};
  assign truncated = dds_out[11:0];
  assign tempSignedConv = dds_out + 16'sh0800;
  assign audioData = tempSignedConv[11:0];
    /*
    dds_1MCLK_1KHZOUT your_instance_name (
    .aclk(mcp_clk), // input aclk
    .m_axis_data_tvalid(), // output m_axis_data_tvalid
    .m_axis_data_tdata(dds_out), // output [15 : 0] m_axis_data_tdata
    .m_axis_phase_tvalid(), // output m_axis_phase_tvalid
    .m_axis_phase_tdata() // output [23 : 0] m_axis_phase_tdata
    );
    */
    /*
    dds_1MCLK_1KHZOUT_2 your_instance_name (
    .aclk(mcp_clk), // input aclk
    .m_axis_data_tvalid(), // output m_axis_data_tvalid
    .m_axis_data_tdata(dds_out) // output [15 : 0] m_axis_data_tdata
    );
    */
    /*
    sine_synth audioAttempt(
    .clk(clk),
    .FTV(FTV_VAL),
    .rst(rst),
    .dataOut(audioData)
    );
    */
    
    dds_compiler_v5_0 oneKHz (
      .aclk(mcp_clk), // input aclk
      .m_axis_data_tvalid(), // output m_axis_data_tvalid
      .m_axis_data_tdata(dds_out) // output [15 : 0] m_axis_data_tdata
    );
    
    /*
    audio_filter FIRLPF(
    .aSyncData(dds_out),
    .clk(khz_50_clk),
    .filterOut(filter_out)
    );
    */
    /*
    IIR audio_attempt2(
  	.x(dds_out) ,
  	.digOut(filter_out) ,
  	.clk(khz_50_clk)    //50 khz
    );
    */
  always @(posedge clk) begin
    if(mcp_count < 50)
      mcp_count <= mcp_count + 1;
    else
      mcp_count <= 0;
    if(khz_50_count < 999)
      khz_50_count <= khz_50_count + 1;
    else
      khz_50_count <= 0;
    if(ss_count < 3000)
      ss_count <= ss_count + 1;
    else
      ss_count <= 0;
  //  mcp_data <= 16'h3800;  //run this enables a mid-level write
  end
     spi_master mcp_4921(
    .clk(clk),  // clock
    .rst(rst),  // reset
    .xmit(mcp_xmit),  //this indicates when we want to xmit, pulse or keep high
    .sclk(mcp_clk),  //spi clock baby
    .inputData(mcp_data),  //what we want to send
    .recvData(),  //what we received from the slave, which is a dont care for this app
    .miso(1'b1),  //top level 
    .mosi(mcp_mosi),  //top level
    .ss(mcp_ss)
  );
  
  
  
  endmodule