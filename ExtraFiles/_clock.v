/*****************************************************************************
* Hardware Clock
******************************************************************************/
module clock(
	clk_i,		// 25MHZ
	ph_2,			// CPU clock for CPU bus
	cs_i,			// clock module chip select (SLOT4IO)
	address_i,	// 4 bit address from CPU
	db_o,			// CPU databus out
	db_i,			// CPU databus in
	reset_n,		// system reset input (negative)
	rw_n,			// Read/Write signal
	tick_1hz_o,	// one hertz output
	hours_t,
	hours_o,
	min_t,
	min_o,
	sec_t,
	sec_o
);

input 			clk_i;
input 			cs_i;
input				ph_2;
input		[3:0] address_i;
input				reset_n;
input				rw_n;
input		[7:0] db_i;
output	[7:0] db_o;
output			tick_1hz_o;
output	[1:0]	hours_t;
output	[3:0]	hours_o;
output	[2:0]	min_t;
output	[3:0]	min_o;
output	[2:0]	sec_t;
output	[3:0]	sec_o;

wire	[3:0]		YEARS_TENS;
wire	[3:0]		YEARS_ONES;
wire				MONTHS_TENS;
wire	[3:0]		MONTHS_ONES;
reg	[2:0]		DAY_WEEK; // this one is handled special
wire	[1:0]		DAYS_TENS;
wire	[3:0]		DAYS_ONES;
wire	[1:0]		HOURS_TENS;
wire	[3:0]		HOURS_ONES;
wire	[2:0]		MINUTES_TENS;
wire	[3:0]		MINUTES_ONES;
wire	[2:0]		SECONDS_TENS;
wire	[3:0]		SECONDS_ONES;

reg	[3:0]		YEARS_TENS_SET;
reg	[3:0]		YEARS_ONES_SET;
reg				MONTHS_TENS_SET;
reg	[3:0]		MONTHS_ONES_SET;
reg	[2:0]		DAY_WEEK_SET;
reg	[1:0]		DAYS_TENS_SET;
reg	[3:0]		DAYS_ONES_SET;
reg	[1:0]		HOURS_TENS_SET;
reg	[3:0]		HOURS_ONES_SET;
reg	[2:0]		MINUTES_TENS_SET;
reg	[3:0]		MINUTES_ONES_SET;
reg	[2:0]		SECONDS_TENS_SET;
reg	[3:0]		SECONDS_ONES_SET;

reg	[23:0]	TIME;

reg	[7:0]		db_reg;

reg	time_set_go;

wire		seconds_last;
wire		minutes_last;
wire		hours_last;

reg		onesec_pulse;
reg		tick_1hz;

assign   tick_1hz_o = tick_1hz;
assign	hours_t	= HOURS_TENS;
assign	hours_o	= HOURS_ONES;
assign	min_t		= MINUTES_TENS;
assign	min_o		= MINUTES_ONES;
assign	sec_t		= SECONDS_TENS;
assign	sec_o		= SECONDS_ONES;

always @(cs_i, address_i, YEARS_TENS, YEARS_ONES, MONTHS_TENS, MONTHS_ONES, DAY_WEEK, DAYS_TENS, DAYS_ONES,
			HOURS_TENS, HOURS_ONES, MINUTES_TENS, MINUTES_ONES, SECONDS_TENS, SECONDS_ONES)
begin
	if(cs_i)
	begin
		db_reg <= 8'h30;
		case(address_i)
			
			4'h0: db_reg[3:0] <= 4'd2; // breaks at year 2100
			4'h1: db_reg[3:0] <= 4'd0;
			4'h2: db_reg[3:0] <= YEARS_TENS;
			4'h3: db_reg[3:0] <= YEARS_ONES;
			4'h4: db_reg[0]   <= MONTHS_TENS;
			4'h5: db_reg[3:0] <= MONTHS_ONES;
			4'h6: db_reg[2:0] <= DAY_WEEK;
			4'h7: db_reg[1:0] <= DAYS_TENS;
			4'h8: db_reg[3:0] <= DAYS_ONES;
			4'h9: db_reg[3:0] <= HOURS_TENS;
			4'hA: db_reg[3:0] <= HOURS_ONES;
			4'hB: db_reg[2:0] <= MINUTES_TENS;
			4'hC: db_reg[3:0] <= MINUTES_ONES;
			4'hD: db_reg[2:0] <= SECONDS_TENS;
			4'hE: db_reg[3:0] <= SECONDS_ONES;
			4'hF: db_reg[7:0] <= 8'h00; // Not applicable (original used DEB COUNTER)
		endcase
	end
	else
		db_reg <= 8'h00;
end

assign db_o = db_reg;

always @ (negedge ph_2)//s or negedge reset_n)
begin
	if(~reset_n)
	begin
		YEARS_TENS_SET			<= 4'd0;		// Years tens
		YEARS_ONES_SET			<= 4'd0;		// Years ones
		MONTHS_TENS_SET		<= 4'd0;			// Months tens
		MONTHS_ONES_SET		<= 4'd0;		// Months ones
		DAY_WEEK_SET			<= 4'd0;		// Day of Week
		DAYS_TENS_SET			<= 4'd0;		// Days tens
		DAYS_ONES_SET			<= 4'd0;		// Days ones
		HOURS_TENS_SET			<= 4'd0;		// Hours tens
		HOURS_ONES_SET			<= 4'd0;		// Hours ones
		MINUTES_TENS_SET		<= 4'd0;		// Minutes tens
		MINUTES_ONES_SET		<= 4'd0;		// Minutes ones
		SECONDS_TENS_SET		<= 4'd0;		// Seconds tens
		SECONDS_ONES_SET		<= 4'd0;
		time_set_go <= 1'b0;
	end
	else
		time_set_go <= 1'b0;
		if(cs_i && ~rw_n)
			case(address_i[3:0])
				4'b0000:	time_set_go				<= db_i[7];			// set
				4'b0001:	time_set_go				<= db_i[7];			// set
				4'b0010:	YEARS_TENS_SET			<= db_i[3:0];		// Years tens
				4'b0011:	YEARS_ONES_SET			<= db_i[3:0];		// Years ones
				4'b0100:	MONTHS_TENS_SET		<= db_i[0];			// Months tens
				4'b0101:	MONTHS_ONES_SET		<= db_i[3:0];		// Months ones
				4'b0110:	DAY_WEEK_SET			<= db_i[2:0];		// Day of Week
				4'b0111:	DAYS_TENS_SET			<= db_i[1:0];		// Days tens
				4'b1000:	DAYS_ONES_SET			<= db_i[3:0];		// Days ones
				4'b1001:	HOURS_TENS_SET			<= db_i[1:0];		// Hours tens
				4'b1010:	HOURS_ONES_SET			<= db_i[3:0];		// Hours ones
				4'b1011:	MINUTES_TENS_SET		<= db_i[2:0];		// Minutes tens
				4'b1100:	MINUTES_ONES_SET		<= db_i[3:0];		// Minutes ones
				4'b1101:	SECONDS_TENS_SET		<= db_i[2:0];		// Seconds tens
				4'b1110:	SECONDS_ONES_SET		<= db_i[3:0];		// Seconds ones
				4'b1111:;
			endcase
end

always @ (posedge clk_i)
begin
	if (TIME == 24'D12_499_999)
	begin
		TIME <= 24'H0000;
		tick_1hz <= ~tick_1hz;
		if(tick_1hz == 1'b0)
		begin
			onesec_pulse <= 1'b1;
		end
	end
	else
	begin
		TIME <= TIME + 1;
		onesec_pulse <= 1'b0;
	end
end

// Seconds counters
countbcd sec_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({SECONDS_TENS_SET,SECONDS_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(onesec_pulse),
	
	.data_o		   		({SECONDS_TENS, SECONDS_ONES}),
	.carry_lookahead_o	(seconds_last)
	);
defparam sec_i0.num_bits_p = 7;
defparam sec_i0.last_count_p = 7'h59;

// Minutes counters
countbcd min_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({MINUTES_TENS_SET, MINUTES_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(seconds_last),

	.data_o		   		({MINUTES_TENS, MINUTES_ONES}),
	.carry_lookahead_o	(minutes_last)
	);
defparam min_i0.num_bits_p = 7;
defparam min_i0.last_count_p = 7'h59;
	
// Hours counters
countbcd hours_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({HOURS_TENS_SET, HOURS_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(minutes_last),

	.data_o		   		({HOURS_TENS, HOURS_ONES}),
	.carry_lookahead_o	(hours_last)
	);
defparam hours_i0.num_bits_p = 6;
defparam hours_i0.last_count_p = 6'h23;

// days counters
countbcd days_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({DAYS_TENS_SET, DAYS_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(hours_last),

	.data_o		   		({DAYS_TENS, DAYS_ONES}),
	.carry_lookahead_o	(days_last)
	);
defparam days_i0.num_bits_p = 6;
defparam days_i0.last_count_p = 6'h31;

// months counters
countbcd months_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({MONTHS_TENS_SET, MONTHS_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(days_last),

	.data_o		   		({MONTHS_TENS, MONTHS_ONES}),
	.carry_lookahead_o	(months_last)
	);
defparam months_i0.num_bits_p = 5;
defparam months_i0.last_count_p = 5'h12;

// years counters
countbcd years_i0  (
	.reset_n 				(reset_n),
	.clk_i 					(clk_i),
	.load_data_i			({YEARS_TENS_SET, YEARS_ONES_SET}),
	.load_en_i  			(time_set_go),
	.inc_i					(months_last),

	.data_o		   		({YEARS_TENS, YEARS_ONES}),
	.carry_lookahead_o	(years_last)
	);
defparam years_i0.num_bits_p = 8;
defparam years_i0.last_count_p = 6'h99;

// DAY OF WEEK is Special
always @(posedge clk_i or negedge reset_n)
begin
	if(~reset_n)
		DAY_WEEK <= 3'd0;
	else if(time_set_go)
		DAY_WEEK <= DAY_WEEK_SET;
	else if(hours_last)
	begin
		if(DAY_WEEK <= 3'd7)
			DAY_WEEK <= 3'd0;
		else
			DAY_WEEK <= DAY_WEEK + 1;
	end
	else
		DAY_WEEK <= DAY_WEEK;
end

endmodule

module countbcd(
	reset_n,
	clk_i,
	load_data_i,
	load_en_i,
	inc_i,
	data_o,
	carry_lookahead_o);

parameter num_bits_p = 8;
parameter [num_bits_p-1:0] last_count_p = 8'h99;

input							reset_n;
input							clk_i;
input  [(num_bits_p-1):0]	load_data_i;
input							load_en_i;
input							inc_i;
output [(num_bits_p-1):0]	data_o;
output						carry_lookahead_o;

reg	[3:0] ones;
reg	[num_bits_p - 5:0] tens;

assign carry_lookahead_o = ({tens,ones} == last_count_p) & inc_i;
assign data_o = {tens,ones};

always @(posedge clk_i or negedge reset_n)
begin
	if(~reset_n)
	begin
		ones <= 0;
		tens <= 0;
	end
	else if(load_en_i)
	begin
		ones <= load_data_i[3:0];
		tens <= load_data_i[num_bits_p-1:4];
	end
	else if(inc_i)
	begin
		if(tens == last_count_p[num_bits_p-1:4] && ones == last_count_p[3:0])
		begin
			ones <= 4'h0;
			tens <= 0;
		end
		else if(ones == 4'h9)
		begin
			ones <= 0;
			tens <= tens + 1;
		end
		else
			ones <= ones + 1;
	end
	else
	begin
		ones <= ones;
		tens <= tens;
	end
end

endmodule
