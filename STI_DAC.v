module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output	reg so_data, so_valid;

output  reg oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output  reg [4:0] oem_addr;
output  reg [7:0] oem_dataout;

//==============================================================================
/// write my code here

parameter IDLE = 0,
		  CLEAR = 1,
		  CLEAR2 = 2,	  
		  READ = 3,
		  WAIT = 4,
		  DATA_OUT8 = 5,
		  DATA_OUT16 = 6,
		  DATA_OUT24 = 7,
		  DATA_OUT32 = 8,
		  DONE = 9;

reg [9:0] cs, ns;


//var for seqential logic
reg [7:0] o_8bit;
reg [15:0] o_16bit;
reg [23:0] o_24bit;
reg [31:0] o_32bit;
reg [4:0] so_cnt;

wire [0:7] o_8bit_rev;
wire [0:15] o_16bit_rev;
wire [0:23] o_24bit_rev;
wire [0:31] o_32bit_rev;

///comobintation logic

always@(*)begin
	case(pi_length)
		2'b00:begin
			o_8bit = (pi_low)? (pi_data[15:8]):(pi_data[7:0]);
			o_16bit = 'd0;
			o_24bit = 'd0;
			o_32bit = 'd0;
		end
		2'b01: begin
			o_8bit = 'd0;
			o_16bit = pi_data;
			o_24bit = 'd0;
			o_32bit = 'd0;
		end
		2'b10: begin
			o_8bit = 'd0;
			o_16bit = 'd0;
			o_24bit = (pi_fill)? ({pi_data,{8'd0}}):({{8'd0},pi_data});
			o_32bit = 'd0;
		end
		2'b11:begin
			o_8bit = 'd0;
			o_16bit = 'd0;
			o_24bit = 'd0;
			o_32bit = (pi_fill)? ({pi_data,{16'd0}}):({{16'd0},pi_data});
		end
	endcase
end
assign o_8bit_rev[0:7] = o_8bit[7:0];
assign o_16bit_rev[0:15] = o_16bit[15:0];
assign o_24bit_rev[0:23] = o_24bit[23:0];
assign o_32bit_rev[0:31] = o_32bit[31:0];

///FSM HERE
// cs logic


always@(posedge clk or posedge reset)begin
	if(reset)begin
		cs <= 'd0;
		cs[IDLE] <= 1'd1;
	end
	else cs <= ns;
end


//ns logic
always@(*)begin
	ns = 'd0;
	case(1'd1)
		cs[IDLE]: ns[CLEAR] = 1'd1;
		cs[CLEAR]:begin
			if(oem_addr == 5'd31) ns[READ] = 1'd1;
			else ns[CLEAR2] = 1'd1;
		end
		cs[CLEAR2]: ns[CLEAR] = 1'd1;
		cs[READ]:begin
			case(pi_length)
				2'b00: ns[DATA_OUT8] = 1'd1;
				2'b01: ns[DATA_OUT16] = 1'd1;
				2'b10: ns[DATA_OUT24] = 1'd1;
				2'b11: ns[DATA_OUT32] = 1'd1;
			endcase
		end
		cs[DATA_OUT8]:begin
			if(so_cnt == 5'd0) ns[WAIT] = 1'd1;
			else ns[DATA_OUT8] = 1'd1;
		end
		cs[DATA_OUT16]:begin
			if(so_cnt == 5'd0) ns[WAIT] = 1'd1;
			else ns[DATA_OUT16] = 1'd1;
		end
		cs[DATA_OUT24]:begin
			if(so_cnt == 5'd0) ns[WAIT] = 1'd1;
			else ns[DATA_OUT24] = 1'd1;
		end
		cs[DATA_OUT32]:begin
			if(so_cnt == 5'd0) ns[WAIT] = 1'd1;
			else ns[DATA_OUT32] = 1'd1;
		end
		cs[WAIT]:begin
			if(pi_end) ns[DONE] = 1'd1;
			else if(load) ns[READ] = 1'd1;
			else ns[WAIT] = 1'd1;
		end
		cs[DONE]: ns[DONE] = 1'd1;
		default: ns[IDLE] = 1'd1;
	endcase
end

//registered output logic
always@(posedge clk or posedge reset)begin
	if(reset)begin
		so_data <= 1'd0;
		so_valid <= 1'd0;
		oem_finish <= 'd0;
		odd1_wr <= 'd0;
		odd2_wr <= 'd0;
		odd3_wr <= 'd0; 
		odd4_wr <= 'd0; 
		even1_wr <= 'd0; 
		even2_wr <= 'd0;
		even3_wr <= 'd0;
		even4_wr <= 'd0;
		oem_addr <= 'd0;
		oem_dataout <= 'd0;
		so_cnt <= 'd0;
	end
	else begin
		case(1'd1)
			cs[IDLE]:begin 
				so_data <= 1'd0;
				so_valid <= 1'd0;
				oem_finish <= 'd0;
				odd1_wr <=  'd1;
				odd2_wr <=  'd1;
				odd3_wr <=  'd1; 
				odd4_wr <=  'd1; 
				even1_wr <= 'd1; 
				even2_wr <= 'd1;
				even3_wr <= 'd1;
				even4_wr <= 'd1;
				oem_dataout <= 'd0;
				oem_addr <= 'd0;
				so_cnt <= 'd0;
			end
			cs[CLEAR]:begin
				oem_addr <= oem_addr + 1'd1;
				oem_dataout <= oem_dataout;
				odd1_wr <= 'd0;
				odd2_wr <= 'd0;
				odd3_wr <= 'd0; 
				odd4_wr <= 'd0; 
				even1_wr <= 'd0; 
				even2_wr <= 'd0;
				even3_wr <= 'd0;
				even4_wr <= 'd0;
			end
			cs[CLEAR2]:begin
				odd1_wr <=  'd1;
				odd2_wr <=  'd1;
				odd3_wr <=  'd1; 
				odd4_wr <=  'd1; 
				even1_wr <= 'd1; 
				even2_wr <= 'd1;
				even3_wr <= 'd1;
				even4_wr <= 'd1;
			end
			cs[WAIT]:begin
				so_valid <= 1'd0;
			end
			cs[READ]:begin
				case(pi_length)
					2'b00: so_cnt <= 5'd7;
					2'b01: so_cnt <= 5'd15;
					2'b10: so_cnt <= 5'd23;
					2'b11: so_cnt <= 5'd31;
				endcase
			end
			cs[DATA_OUT8]:begin
				so_valid <= 1'd1;
				so_cnt <= so_cnt - 1'd1;
				if(pi_msb)	so_data <= o_8bit[so_cnt];
				else 		so_data <= o_8bit_rev[so_cnt];
			end
			cs[DATA_OUT16]:begin
				so_valid <= 1'd1;
				so_cnt <= so_cnt - 1'd1;
				if(pi_msb)	so_data <= o_16bit[so_cnt];
				else 		so_data <= o_16bit_rev[so_cnt];
			end
			cs[DATA_OUT24]:begin
				so_valid <= 1'd1;
				so_cnt <= so_cnt - 1'd1;
				if(pi_msb)	so_data <= o_24bit[so_cnt];
				else 		so_data <= o_24bit_rev[so_cnt];
			end
			cs[DATA_OUT32]:begin
				so_valid <= 1'd1;
				so_cnt <= so_cnt - 1'd1;
				if(pi_msb)	so_data <= o_32bit[so_cnt];
				else 		so_data <= o_32bit_rev[so_cnt];
			end
			cs[DONE]:begin
				oem_finish <= 1'd1;
			end
		endcase
	end
end


/// end
endmodule
