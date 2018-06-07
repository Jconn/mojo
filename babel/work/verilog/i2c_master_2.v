module i2c_master_2(
    // 50MHz clock input
    input clk,

    //the start condition 
    input start,

    // i2c data 
    inout sda,
    // i2c clock - no clock stretching supported
    output reg scl,
    // input data byte from external device 
    input [7:0]data_in, 
    // output data byte to external device 
    output reg [7:0]requested_data_out,
    input read_ack,
    //whether to do start, stop, read, write
    input [1:0] request,
    output reg busy
    );

//50 MHz input clock
//i2c run at 400 kHz 
//
//50 MHz/.4MHZ = 125 cycles as the overflow counter
//
//
reg [7:0] overflow_value = 8'd125;

parameter SIZE = 4;
parameter IDLE = 1'h0;
parameter START = 1'h3;
parameter READ = 1'h4;
parameter WRITE = 1'h5;
parameter STOP  = 1'h6;
parameter FINISH  = 1'h7;
parameter WAIT  = 1'h8;
parameter ACK = 1'h9;

reg [SIZE-1:0] state = IDLE;
reg [SIZE-1:0] next_state;
reg [7:0] data;
reg [8:0] clk_count;
reg acked;
reg [3:0] current_bit;
reg master_drive = 1'b0;
reg read_snapshot;
reg sda_master;
reg reset_clk;
assign sda = master_drive ? sda_master : 1'bz;
always @(posedge clk)
begin
case(state)
    IDLE:
    begin
        if(start)
        begin
            if(request[1:0] == 0)
            begin
                next_state <= START;
                scl <= 1'bz;
            end
            else if(request[1:0] == 1)
            begin
                scl <= 1'b0;
                next_state <= STOP;
            end
            else if(request[1:0] == 2)
            begin
                scl <= 1'b0;
                sda_master <= 1'bx;
                master_drive <= 1'b0;
                next_state <= READ;
                read_snapshot <= read_ack;
            end
            else if(request[1:0] == 3)
            begin
                scl <= 1'b0;
                data <= requested_data_out;
                next_state <= WRITE;
            end
            state <= WAIT;
            busy <= 1'b1;
            reset_clk <= 1'b1;
            current_bit <= 1'h0;
        end
    end
    START:
    begin
        //case: completed 
        if( ((clk_count[8:0]>>1) + clk_count[8:0]) > overflow_value[7:0])
        begin
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
            scl <= 1'bz;
        end
        //case: 3/4 of the way through
        else if( ((clk_count[8:0]>>1) + clk_count[8:0]) > overflow_value[7:0])
        begin
            sda_master <= 1'b1;
            master_drive <= 1'b1;
        end
        //case: 1/2 of the way through 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'b0;
        end
        //case: 1/4 of the way through 
        else if(clk_count[8:0] > (overflow_value[7:0] >>2))
        begin
            master_drive <= 1'b1;
            sda_master <= 1'b0;
        end
    end
    READ:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[8:0] > (overflow_value[7:0]))
        begin
            scl <= 1'bz;
            reset_clk <= 1'b1;
    
            //we're done with this byte, generate a stop condition 
            if(current_bit[3:0] > 7)
            begin
                //for master read, the master performs the ack
                sda_master <= ~read_snapshot;
                master_drive <= 1'b1;
                next_state <= ACK; 
                state <= WAIT;
            end
            //set up for next bit 
            else
            begin
                next_state <= READ;
                state <= WAIT;
                current_bit[3:0] <= current_bit[3:0] + 1;
            end
        end
        //case: 3/4 of the way through - snapshot SDA 
        else if((clk_count[8:0] + (clk_count[8:0] >>1) ) > overflow_value[7:0] )
        begin
            data[current_bit] <= sda;
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
    end
    WRITE:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[8:0] > (overflow_value[7:0]))
        begin
            scl <= 1'bz;
            reset_clk <= 1'b1;
    
            //we're done with this byte, generate a stop condition 
            if(current_bit[3:0] > 7)
            begin
                //for the master write, ack bit is driven by slave
                sda_master <= 1'bx;
                master_drive <= 1'b0;
                next_state <= ACK;
                state <= WAIT;
            end
            //set up for next bit 
            else
            begin
                next_state <= WRITE;
                state <= WAIT;
                current_bit[3:0] <= current_bit[3:0] + 1;
            end
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - send the data bit
        else if(clk_count[8:0] > (overflow_value[7:0] >>2))
        begin
            sda_master <= data[current_bit];
            master_drive <= 1'b1;
        end
    end
    WAIT:
    begin
        //wait for the reset clock to take effect
        sda_master <= 1'bx;
        master_drive <= 1'b0;
    end
    STOP:
    begin
        //case: all the way through - go to cleanup state 
        if(clk_count[8:0] > overflow_value[7:0])
        begin
            scl <= 1'bz;
            sda_master <= 1'b1;
            master_drive <= 1'b1;
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
        end
        //case: 3/4 of the way through - raise sda for the stop condition 
        else if(( clk_count[8:0] +  (clk_count[8:0] >> 1) ) > (overflow_value[7:0] >>1))
        begin
            sda_master <= 1'b1;
            master_drive <= 1'b1;
        end
 
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - send the data bit
        else if(clk_count[8:0] > (overflow_value[7:0] >>2))
        begin
            sda_master <= 1'b0; 
        end
    end
    ACK:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[8:0] > (overflow_value[7:0]))
        begin
            scl <= 1'bz;
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
        end
        //case: 3/4 of the way through - snapshot SDA 
        else if((clk_count[8:0] + (clk_count[8:0] >>1) ) > overflow_value[7:0] )
        begin
            acked <= sda;
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
    end
    FINISH:
    begin
        scl <= 1'bz;
        busy <= 1'b0;
        sda_master <= 1'bx;
        master_drive <= 1'b0;
        requested_data_out[7:0] <= data[7:0];
        state  <= IDLE;
    end
    default:
    begin
        scl <= 1'bz;
        sda_master <= 1'bx;
        master_drive <= 1'b0;
    end
endcase
if(reset_clk)
begin
    reset_clk <= 1'b0;
    clk_count[8:0] <= 3'h000;
    state <= next_state;
end
else
    clk_count[8:0] <= clk_count[8:0] + 1;
end



endmodule


