module mpu_9150(
    // 50MHz clock input
    input clk,

    // i2c data 
    inout sda,
    // i2c clock - no clock stretching supported
    output scl,

    //the start condition 
    input sample_start,

    output mod_busy,
    output byte_busy
    );


//connect i2c_master
//
parameter SIZE = 4;

parameter IDLE = 4'h0;
parameter START = 4'h3;
parameter FINISH  = 4'h7;
parameter WAIT  = 4'h8;
parameter PHY_WR_ADDR  = 4'h9;
parameter PHY_RD_ADDR  = 4'hA;
parameter STOP  = 4'hB;

parameter REG_ADDR  = 4'h1;
parameter SECOND_START  = 4'h2;
parameter READ_MSB  = 4'h5;
parameter READ_LSB  = 4'h4;


parameter I2C_START = 4'h0;
parameter I2C_READ = 4'h2;
parameter I2C_WRITE = 4'h3;
parameter I2C_STOP  = 4'h1;
parameter I2C_REG_X_MSB = 8'h3b;

parameter I2C_ADDR_W = 8'hd0;
parameter I2C_ADDR_R = 8'hd1;
reg busy = 1'b0;

assign mod_busy = busy;

reg byte_start = 1'b0;
reg [1:0] i2c_cmd;
reg [7:0] data;
reg read_ack;
wire [7:0] data_out;
reg [15:0] x_data;
reg [SIZE-1:0] state = IDLE;
reg [SIZE-1:0] next_state;
reg [3:0] delay = 0;
i2c_master i2c_master(.clk(clk), .start(byte_start), .sda(sda), .scl(scl),
                .data_in(data), .requested_data_out(data_out), .read_ack(read_ack),
                .busy(byte_busy), .request(i2c_cmd) );



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
        delay <= 10;
        i2c_cmd <= I2C_START;
        next_state[SIZE-1:0] <= PHY_WR_ADDR; 
        byte_start <= 1'b1;
    end
    PHY_WR_ADDR:
    begin
        byte_start <= 1'b1;
        state <= WAIT;
        delay <= 10;
        data <= I2C_ADDR_W;
        i2c_cmd <= I2C_WRITE;
        next_state <= REG_ADDR;
    end
    REG_ADDR:
    begin
        byte_start <= 1'b1;
        state <= WAIT;
        delay <= 10;
        data <= I2C_REG_X_MSB;
        i2c_cmd <= I2C_WRITE;
        next_state <= SECOND_START;
    end
    SECOND_START:
    begin
        state <= WAIT;
        delay <= 10;
        i2c_cmd <= I2C_START;
        next_state <= PHY_RD_ADDR; 
        byte_start <= 1'b1;
    end
    PHY_RD_ADDR:
    begin
        byte_start <= 1'b1;
        state <= WAIT;
        delay <= 10;
        data <= I2C_ADDR_R;
        i2c_cmd <= I2C_WRITE;
        next_state <= READ_MSB;
    end
    READ_MSB:
    begin
        read_ack <= 1'b1;
        byte_start <= 1'b1;
        delay <= 10;
        i2c_cmd <= I2C_READ;
        state <= WAIT;
        next_state <= READ_LSB;
    end
    READ_LSB:
    begin
        read_ack <= 1'b0;
        x_data[15:8] <= data_out[7:0];
        byte_start <= 1'b1;
        i2c_cmd <= I2C_READ;
        delay <= 10;
        state <= WAIT;
        next_state <= STOP;
    end
    STOP:
    begin
        byte_start <= 1'b1;
        i2c_cmd <= I2C_STOP;
        delay <= 10;
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
        if(delay == 0)
        begin
          if(byte_busy == 1) 
          begin
              state <= WAIT;
          end
          else
          begin
              state <= next_state;
          end
        end
        else
        begin
          delay <= delay - 1;
        end
    end

endcase   
end



endmodule
