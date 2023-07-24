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
output  reg odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output oem_finish;
output  reg [4:0] oem_addr;
output   [7:0] oem_dataout;

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
// after clear jump to read
//ns logic
always@(*)begin
	ns = 'd0;
	case(1'd1)
		cs[IDLE]: ns[CLEAR] = 1'd1;
		cs[CLEAR]: ns[CLEAR2] = 1'd1;
		cs[CLEAR2]: begin
			if(so_cnt == 'd31) ns[READ] = 1'd1;
			else ns[CLEAR] = 1'd1;
		end
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
		so_cnt <= 'd0;
	end
	else begin
		case(1'd1)
			cs[IDLE]:begin 
				so_data <= 1'd0;
				so_valid <= 1'd0;
				so_cnt <= 'd31;
			end
			cs[CLEAR]:begin
				so_cnt <= so_cnt + 1'd1;
			end
			cs[CLEAR2]:begin
				
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
			end
		endcase
	end
end

///DAC
reg [8:0] mem_num;
reg [3:0] line_cnt;
reg [7:0] data_buffer;
reg [3:0] data_cnt;
reg [4:0] odd_cnt;
reg [4:0] even_cnt;
reg odd_even;
wire line_en;
wire data_buffer_en;
assign line_en = (line_cnt == 4'd7)? 1'd1: 1'd0;
assign data_buffer_en = ((data_cnt == 4'd7))? 1'd1: 1'd0;
assign oem_dataout = data_buffer;
// assign oem_addr = (odd_even)? odd_cnt: even_cnt;
assign oem_finish = (mem_num == 9'd255 );



//once for one bit data
/// check correct
always@(posedge clk or posedge reset)begin
	if(reset) data_cnt <= 4'd0;
	else if (so_valid)begin
		if(data_cnt == 4'd7) data_cnt <= 'd0;
		else data_cnt <= data_cnt + 1'd1;
	end
end

//check correct
always@(posedge clk or posedge reset)begin
	if(reset) line_cnt <= 4'd0;
	else if(data_buffer_en) begin
		if(line_cnt == 4'd7) line_cnt <= 'd0;
		else line_cnt <= line_cnt + 1'd1;
	end
end

//check correct
// word cnt 0 ~ 255
always@(posedge clk or posedge reset)begin
	if(reset) mem_num <= 9'd0;
	else if(pi_end) mem_num <= mem_num + 1'd1;
	else if (data_buffer_en) begin
		if(mem_num == 9'd255) mem_num <= 'd0;
		else mem_num <= mem_num + 1'd1;
	end
end

//check correct
always@(posedge clk or posedge reset)begin
	if(reset) begin
		data_buffer <= 'd0;
	end
	else if(so_valid)begin
		data_buffer <= data_buffer << 1'd1;
		data_buffer[0] <= so_data;
	end
end

always@(posedge clk or posedge reset)begin
	if(reset) oem_addr <= 'd0;
	else if(cs == 'd2) oem_addr <= so_cnt;
	else oem_addr <= (odd_even)? odd_cnt: even_cnt;
end

// odd or even?
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd_even <= 1'd1;
	end
	else if(data_buffer_en && line_en) odd_even <= odd_even;
	else if(data_buffer_en) odd_even <= ~odd_even;
end

// odd_even count
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd_cnt <= 'd0;
		even_cnt <= 'd0;
	end
	else if(data_buffer_en)begin
		if(odd_even) odd_cnt <= odd_cnt + 1'd1;
		else even_cnt <= even_cnt + 1'd1;
	end
end

// wr control1
// wr odd1 ,even1
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd1_wr <= 'd0;
		even1_wr <= 'd0;
	end
	else if(cs  == 'd2)begin
		odd1_wr <= 1'd1;
		even1_wr <= 1'd1;
	end
	else if(cs == 'd4)begin
		odd1_wr <= 1'd0;
		even1_wr <= 1'd0;
	end
	else if(mem_num <= 9'd63)begin
		if(data_buffer_en)begin
			if(odd_even)begin
				odd1_wr <= 1'd1;
				even1_wr <= 1'd0;
			end
			else begin
				odd1_wr <= 1'd0;
				even1_wr <= 1'd1;
			end
		end
		else begin
			odd1_wr <= 'd0;
			even1_wr <= 'd0;
		end
	end
	else begin
		odd1_wr <= 'd0;
		even1_wr <= 'd0;
	end
end	

// wr control2
// wr odd2 , even2
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd2_wr <= 'd0;
		even2_wr <= 'd0;
	end
	else if(cs  == 'd2)begin
		odd2_wr <= 1'd1;
		even2_wr <= 1'd1;
	end
	else if(cs == 'd4)begin
		odd2_wr <= 1'd0;
		even2_wr <= 1'd0;
	end
	else if((9'd63 < mem_num) && (mem_num <= 9'd127))begin
		if(data_buffer_en)begin
			if(odd_even)begin
				odd2_wr <= 1'd1;
				even2_wr <= 1'd0;
			end
			else begin
				odd2_wr <= 1'd0;
				even2_wr <= 1'd1;
			end
		end
		else begin
			odd2_wr <= 'd0;
			even2_wr <= 'd0;
		end
	end
	else begin
		odd2_wr <= 'd0;
		even2_wr <= 'd0;
	end
end

//wr control3
//wr odd3 , even3
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd3_wr <= 'd0;
		even3_wr <= 'd0;
	end
	else if(cs  == 'd2)begin
		odd3_wr <= 1'd1;
		even3_wr <= 1'd1;
	end
	else if(cs == 'd2)begin
		odd3_wr <= 1'd0;
		even3_wr <= 1'd0;
	end
	else if((9'd127 < mem_num) && (mem_num <= 9'd191))begin
		if(data_buffer_en)begin
			if(odd_even)begin
				odd3_wr <= 1'd1;
				even3_wr <= 1'd0;
			end
			else begin
				odd3_wr <= 1'd0;
				even3_wr <= 1'd1;
			end
		end
		else begin
			odd3_wr <= 'd0;
			even3_wr <= 'd0;
		end
	end
	else begin
		odd3_wr <= 'd0;
		even3_wr <= 'd0;
	end
end

//wr control4
//wr odd4 , even4
always@(posedge clk or posedge reset)begin
	if(reset)begin
		odd4_wr <= 'd0;
		even4_wr <= 'd0;
	end
	else if(cs  == 'd2)begin
		odd4_wr <= 1'd1;
		even4_wr <= 1'd1;
	end
	else if(cs == 'd4)begin
		odd4_wr <= 1'd0;
		even4_wr <= 1'd0;
	end
	else if((9'd191 < mem_num) && (mem_num <= 9'd255))begin
		if(data_buffer_en)begin
			if(odd_even)begin
				odd4_wr <= 1'd1;
				even4_wr <= 1'd0;
			end
			else begin
				odd4_wr <= 1'd0;
				even4_wr <= 1'd1;
			end
		end
		else begin
			odd4_wr <= 'd0;
			even4_wr <= 'd0;
		end
	end
	else begin
		odd4_wr <= 'd0;
		even4_wr <= 'd0;
	end
end


endmodule
