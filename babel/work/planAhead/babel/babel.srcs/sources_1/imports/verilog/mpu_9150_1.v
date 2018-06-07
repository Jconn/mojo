module mpu_9150_1(
    // 50MHz clock input
    input clk,

    // i2c data 
    inout sda,
    // i2c clock - no clock stretching supported
    output scl,

    //the start condition 
    input sample_start,

    output mod_busy
    );


//connect i2c_master
//
parameter SIZE = 4;

parameter IDLE = 1'h0;
parameter START = 1'h3;
parameter FINISH  = 1'h7;
parameter WAIT  = 1'h8;
parameter PHY_ADDR  = 1'h9;
parameter REG_ADDR  = 1'h1;
parameter SECOND_START  = 1'h2;
parameter READ_MSB  = 1'h2;
parameter READ_LSB  = 1'h4;


parameter I2C_START = 1'h0;
parameter I2C_READ = 1'h2;
parameter I2C_WRITE = 1'h3;
parameter I2C_STOP  = 1'h1;
parameter I2C_REG_X_MSB = 2'h3b;

parameter I2C_ADDR_W = 2'hb0;
parameter I2C_ADDR_R = 2'hb1;
reg busy = 1'b0;

assign mod_busy = busy;
wire byte_busy;
reg byte_start = 1'b0;
reg [1:0] i2c_cmd;
reg [7:0] data;
reg read_ack;
wire [7:0] data_out;
reg [15:0] x_data;
reg byte_read;
reg [SIZE-1:0] state = IDLE;
reg [SIZE-1:0] next_state;

i2c_master_2 i2c_master(.clk(clk), .start(byte_start), .sda(sda), .scl(scl),
                .data_in(data), .requested_data_out(data_out), .read_ack(byte_read),
                .busy(byte_busy) );



always@(posedge clk)
begin
case(state)
    IDLE:
    begin
        if(sample_start)
        begin
            state <= START;
        end
    end
    START:
    begin
        busy <= 1'b1;
        state <= WAIT;
        i2c_cmd <= I2C_START;
        next_state[SIZE-1:0] <= PHY_ADDR; 
        byte_start <= 1'b1;
    end
    PHY_ADDR:
    begin
        byte_start <= 1'b1;
        state <= WAIT;
        data <= I2C_ADDR_W;
        i2c_cmd <= I2C_WRITE;
        next_state <= REG_ADDR;
    end
    REG_ADDR:
    begin
        byte_start <= 1'b1;
        state <= WAIT;
        data <= I2C_REG_X_MSB;
        i2c_cmd <= I2C_WRITE;
        next_state <= SECOND_START;
    end
    SECOND_START:
    begin
        state <= WAIT;
        i2c_cmd <= I2C_START;
        next_state <= READ_MSB; 
        byte_start <= 1'b1;
        data <= I2C_REG_X_MSB;
    end
    READ_MSB:
    begin
        read_ack <= 1'b1;
        byte_start <= 1'b1;
        i2c_cmd <= I2C_READ;
        state <= WAIT;
        next_state <= READ_LSB;
    end
    READ_LSB:
    begin
        read_ack <= 1'b1;
        x_data[15:8] <= data_out[7:0];
        byte_start <= 1'b1;
        i2c_cmd <= I2C_READ;
        state <= WAIT;
        next_state <= FINISH;
    end
    FINISH:
    begin
        x_data[7:0] <= data_out[7:0];
        state <= IDLE;
        busy <= 1'b0;
    end
    WAIT:
    begin
        byte_start <= 1'b0;
    end
endcase

    if(byte_busy == 1) 
    begin
        state <= WAIT;
    end
    else
    begin
        state <= next_state;
    end
end



endmodule
