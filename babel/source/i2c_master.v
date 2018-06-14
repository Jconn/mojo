module i2c_master(
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
parameter IDLE = 4'h0;
parameter START = 4'h3;
parameter READ = 4'h4;
parameter WRITE = 4'h5;
parameter STOP  = 4'h6;
parameter FINISH  = 4'h7;
parameter WAIT  = 4'h8;
parameter ACK = 4'h9;

reg [SIZE-1:0] state = IDLE;
reg [SIZE-1:0] next_state;
reg [7:0] data;
reg [8:0] clk_count = 0;
reg acked;
reg [3:0] current_bit;
reg master_drive = 1'b0;
reg read_snapshot;
reg reset_clk = 0;
reg buffered_master_drive = 1'b0;
assign sda = buffered_master_drive ? 1'b0 : 1'bz;
always @(posedge clk)
begin

if(reset_clk == 1'b1)
begin
    reset_clk <= 1'b0;
    clk_count[8:0] <= 9'h000;
    state <= next_state;
end
else
begin
    clk_count[8:0] <= clk_count[8:0] + 1;
end



buffered_master_drive <= master_drive;
overflow_value <= 8'd125;
case(state)
    IDLE:
    begin
        if(start == 1'b1)
        begin
            if(request[1:0] == 0)
            begin
                next_state <= START;
                scl <= 1'b0;
            end
            else if(request[1:0] == 1)
            begin
                scl <= 1'b0;
                next_state <= STOP;
            end
            else if(request[1:0] == 2)
            begin
                scl <= 1'b0;
                next_state <= READ;
                read_snapshot <= read_ack;
            end
            else if(request[1:0] == 3)
            begin
                scl <= 1'b0;
                //we don't ack our own transaction
                read_snapshot <= 1'b0;
                data <= data_in;
                next_state <= WRITE;
            end
            state <= WAIT;
            busy <= 1'b1;
            reset_clk <= 1'b1;
            current_bit <= 4'h0;
        end
    end
    START:
    begin
        //case: completed 
        if(clk_count[8:0] > overflow_value[7:0])
        begin
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
            //scl <= 1'b1;
        end
        //case: 4/5 of the way through
        else if( ((clk_count[7:0]>>2) + clk_count[7:0]) > overflow_value[7:0])
        begin
            //scl <= 1'b1;
        end
        //case: 2/3 of the way through - lower data
        else if( ((clk_count[7:0]>>1) + clk_count[7:0]) > overflow_value[7:0])
        begin
            master_drive <= 1'b1;
        end
        //case: 1/2 of the way through - raise clock
        else if(clk_count[7:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - raise data
        else if(clk_count[7:0] > (overflow_value[7:0] >>2))
        begin
            master_drive <= 1'b0;
        end
    end
    READ:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[7:0] > (overflow_value[7:0]))
        begin
            scl <= 1'b0;
            reset_clk <= 1'b1;
    
            //we're done with this byte, generate a stop condition 
            if(current_bit[3:0] >= 7)
            begin
                //for master read, the master performs the ack
                next_state <= ACK; 
                state <= WAIT;
                master_drive <= read_snapshot;
            end
            //set up for next bit 
            else
            begin
                scl <= 1'b0;
                next_state <= READ;
                state <= WAIT;
                current_bit[3:0] <= current_bit[3:0] + 1;
            end
        end
        //case: 3/4 of the way through - snapshot SDA 
        else if((clk_count[7:0] + (clk_count[7:0] >>1) ) > overflow_value[7:0] )
        begin
            data[7-current_bit] <= sda;
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[7:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - release sda so that ext chip can drive
        else if( (clk_count[7:0]) > (overflow_value[7:0]>>2))
        begin
           master_drive <= 1'b0;
        end
        
    end
    WRITE:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[8:0] > (overflow_value[7:0]))
        begin
            scl <= 1'b0;
            reset_clk <= 1'b1;
            state <= WAIT;

            //grab the ack
            if(current_bit[3:0] >= 7)
            begin
                //for the master write, ack bit is driven by slave
                master_drive <= 1'b0;
                next_state <= ACK;
            end
            //set up for next bit 
            else
            begin
                next_state <= WRITE;
                current_bit[3:0] <= current_bit[3:0] + 1;
            end
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[7:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - send the data bit
        else if(clk_count[7:0] > (overflow_value[7:0] >>2))
        begin
            master_drive <= ~data[7-current_bit];
        end
    end
    WAIT:
    begin
        next_state <= next_state;
    end
    STOP:
    begin
        //case: all the way through - go to cleanup state 
        if(clk_count[7:0] > overflow_value[7:0])
        begin
            scl <= 1'bz;
            master_drive <= 1'b0;
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
        end
        //case: 3/4 of the way through - raise sda for the stop condition 
        else if(( clk_count[7:0] +  (clk_count[7:0] >> 1) ) > overflow_value[7:0])
        begin
            master_drive <= 1'b0;
        end
 
        //case: 1/2 of the way through - raise the clock 
        else if(clk_count[8:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
        //case: 1/4 of the way through - lower the data line
        else if(clk_count[8:0] > (overflow_value[7:0] >>2))
        begin            
            master_drive <= 1'b1;
        end
    end
    ACK:
    begin
        //case: all the way through - toggle the clock 
        if(clk_count[7:0] > (overflow_value[7:0]))
        begin
            reset_clk <= 1'b1;
            next_state <= FINISH;
            state <= WAIT;
        end
        //case: 3/4 of the way through - snapshot SDA 
        else if((clk_count[7:0] + (clk_count[7:0] >>1) ) > overflow_value[7:0] )
        begin
            acked <= sda;
        end
        //case: 1/2 of the way through - toggle the clock 
        else if(clk_count[7:0] > (overflow_value[7:0] >>1))
        begin
            scl <= 1'bz;
        end
    end
    FINISH:
    begin
        busy <= 1'b0;
        //master_drive <= 1'b0;
        requested_data_out[7:0] <= data[7:0];
        state  <= IDLE;
    end
    default:
    begin
        scl <= 1'bz;
        master_drive <= 1'b0;
    end
endcase

end


endmodule


