// Raw data capture function for ADE7168
// CC BY 4.0 Tadashi Kadowaki (tadakado@gmail.com)

// SDRAM controler was obtained from
// http://www.hmwr-lsi.co.jp/fpga/fpga_10.htm
// http://www.hmwr-lsi.co.jp/fpga/camera_ap_de0_sdram_files.zip

//****************************************
// Top module (ADE7816SDRAM)
//****************************************

module ADE7816SDRAM
(
  input clk,
	input reset_n,
  // SPI slave
	input  sclk,
  input  cs_n,
	input  mosi,
	output miso,
  // ADE7816 HSDC
	input hsclk,
	input hsa,
	input hsd,
  // sdram
	output ram_clke,
	output ram_cs_n,
	output ram_cas_n,
	output ram_ras_n,
	output ram_we_n,
	output ram_dqml,
	output ram_dqmu,
	output ram_ba0,
	output ram_ba1,
	output [11:0] ram_adr,
	inout  [15:0] ram_dq
);

	// sdram controller
	reg  u_wreq;        //user write req
	wire u_wack;        //user write ack
	wire u_wr_da_en;    //user write enable
	reg  [19:0]u_wadr;  //user write address
	reg  [15:0]u_wr_da; //user write data
	wire u_rreq;        //user read req
	wire u_rack;        //user read ack
	wire u_rd_da_en;    //user read enable
	reg  [19:0]u_radr;  //user read address
	wire [15:0]u_rd_da; //user read data
	wire out_en;
	wire [3:0] sdc_state;   //state

	sdram sdram_ctl(
		.clk(clk),
		.reset_n(reset_n),
		.ram_clke(ram_clke),
		.ram_cs_n(ram_cs_n),
		.ram_cas_n(ram_cas_n),
		.ram_ras_n(ram_ras_n),
		.ram_we_n(ram_we_n),
		.ram_dqml(ram_dqml),
		.ram_dqmu(ram_dqmu),
		.ram_ba0(ram_ba0),
		.ram_ba1(ram_ba1),
		.ram_adr(ram_adr),
		.ram_dq_w(ram_dq_w),
		.ram_dq_r(ram_dq_r),
		.u_wreq(u_wreq),
		.u_wack(u_wack),
		.u_wr_da_en(u_wr_da_en),
		.u_wadr(u_wadr),
		.u_wr_da(u_wr_da),
		.u_rreq(u_rreq),
		.u_rack(u_rack),
		.u_radr(u_radr),
		.u_rd_da_en(u_rd_da_en),
		.u_rd_da(u_rd_da),
		.out_en(out_en),
		.state(sdc_state));

	// sdram data inout
	wire [15:0] ram_dq_w; //sdram write data
	wire [15:0] ram_dq_r; //sdram read data

	assign ram_dq = ram_dq_r;
	assign ram_dq = out_en ? ram_dq_w : 8'hZZZZ;
	//assign ram_dq[7:0]  = out_en ? ram_dq_w[7:0]  : 8'hZZ;
	//assign ram_dq[15:8] = out_en ? ram_dq_w[15:8] : 8'hZZ;

  // SPI interface
  reg spi_state;
  reg [7:0] spi_reg;
  reg [3:0] spi_counter;
  reg [7:0] spi_out;
  reg dc_run;
  reg rd_run;
  reg rd_continue;
  parameter spi_s_init = 2'b00;
  parameter spi_s_idle = 2'b01;
  parameter spi_s_capture = 2'b10;
  parameter spi_s_read = 2'b11;
  always @ (posedge sclk or negedge reset_n or negedge cs_n) begin
    if (!reset_n) begin
      spi_reg <= 8'h00;
      spi_counter <= 4'h0;
      spi_out <= 8'h00;
      dc_run <= 1'b0;
      rd_run <= 1'b0;
      rd_continue <= 1'b0;
      spi_state <= spi_s_instruction;
    end else begin
      if (!cs_n) begin
        spi_reg <= 8'h00;
        spi_counter <= 4'h0;
        spi_out <= 8'h00;
        spi_state <= spi_s_instruction;
      end else begin
        miso <= spi_out[7];
        spi_out <= spi_out << 1;
        if (spi_counter == 4'h8) begin
          spi_out <= spi_data;
          case (spi_reg)
            8'h00: begin
              dc_run <= 1'b1;
              rd_run <= 1'b0;
              rd_continue <= 1'b0;
            end
            8'h01: begin
              dc_run <= 1'b0;
              rd_run <= 1'b1;
              rd_continue <= 1'b1;
            end
            8'h03: begin
              dc_run <= 1'b0;
              rd_run <= 1'b1;
              rd_continue <= 1'b1;
            end
          endcase
        end
      end
    end
  end

	// HSDC interface
	reg  [192:0] ad_raw_data;
	wire [191:0] ad_data;
	wire ad_stop;
	assign {ad_stop, ad_data} = ad_raw_data;
	reg ad_data_rdy;

	always @ (posedge hsclk or negedge reset_n or negedge hsa) begin
		if (!reset_n | !hsa) begin
		  ad_data_rdy <= 1'b0;
		  ad_raw_data <=
				193'h0_00000000_00000000_00000000_00000000_00000000_00000001;
		end else begin
		  if (!hsa) begin
        if (!ad_data_rdy & !ad_stop) begin
          ad_raw_data <= {ad_data[191:0], hsd};
        end else begin
          if(ad_stop) begin
            ad_data_rdy <= 1'b1;
          end
			  end else begin
			end
    end
	end

  // data capture
	reg dc_state;
	reg [12:0] dc_counter;
	reg [191:0] dc_data;
	reg [3:0] dc_sel;
	reg [1:0] dc_state;
	parameter dc_count_max = 8000 * 6 * 2;
  parameter dc_s_init = 3'b000;
  parameter dc_s_idle = 3'b001;
  parameter dc_s_wait_data_rdy1 = 3'b010;
  parameter dc_s_wait_data_rdy2 = 3'b011;
  parameter dc_s_data_rdy = 3'b100;
  parameter dc_s_wreq = 3'b101;
  parameter dc_s_wait_wack = 3'b110;
  parameter dc_s_wait_wren = 3'b111;

	always @ (posedge clk or negedge reset_n) begin
		if (!reset_n) begin
      dc_state <= dc_s_init;
		end else begin
      case (dc_state)
        dc_s_init: begin
          dc_counter <= 13'h0000;
  		    u_wadr <= 20'h00000;
  			  dc_sel <= 3'h0;
          dc_state <= dc_s_idle;
        end
        dc_s_idle: if (dc_run) dc_state <= dc_s_wait_data_rdy1;
        dc_s_wait_data_rdy1: if (ad_data_rdy) dc_state <= dc_s_wait_data_rdy2;
        dc_s_wait_data_rdy2: if (!ad_data_rdy) dc_state <= dc_data_rdy;
        dc_s_data_rdy: begin
          if (ad_data_rdy) begin
            dc_data <= ad_data;
            dc_state <= dc_s_wreq;
          end
        end
        dc_s_wreq: begin
          u_wr_da <= dc_data[191:176]
          u_wreq <= 1'b1;
          dc_state <= dc_s_wait_wack;
        end
        dc_s_wait_wack: begin
          if (u_wack) begin
            u_wreq <= 1'b0;
            dc_state <= dc_s_wait_wren;
          end
        end
        dc_s_wait_wren: begin
          if (!u_wr_en) begin
            u_wadr <= u_wadr + 1;
            dc_data <= dc_data << 16;
            if (u_wadr == dc_count_max) begin
              dc_run <= 1'b0;
              dc_state <= dc_s_init;
            end else begin
              if (dc_sel == 5) begin
                dc_sel <= 3'h0
                dc_state <= dc_s_wait_data_rdy2;
              end else begin
            end else dc_state <= dc_s_wreq;
          end
        end
      endcase
		end
  end

  // data read
	reg rd_state;
	reg [12:0] rd_counter;
	reg [191:0] rd_data;
	reg [3:0] rd_sel;
	reg [1:0] rd_state;
	parameter rd_count_max = 8000 * 6 * 2;
  parameter rd_s_init = 3'b000;
  parameter rd_s_idle = 3'b001;
  parameter rd_s_wait_data_rdy1 = 3'b010;
  parameter rd_s_wait_data_rdy2 = 3'b011;
  parameter rd_s_data_rdy = 3'b100;
  parameter rd_s_wreq = 3'b101;
  parameter rd_s_wait_wack = 3'b110;
  parameter rd_s_wait_wren = 3'b111;

	always @ (posedge clk or negedge reset_n) begin
		if (!reset_n) begin
      rd_state <= rd_s_init;
		end else begin
      case (rd_state)
        rd_s_init: begin
          rd_counter <= 13'h0000;
  		    u_radr <= 20'h00000;
  			  //dc_sel <= 3'h0;
          rd_state <= dc_s_idle;
        end
        rd_s_idle: if (dc_run) dc_state <= dc_s_wait_data_rdy1;
        rd_s_wait_data_rdy1: if (ad_data_rdy) dc_state <= dc_s_wait_data_rdy2;
        rd_s_wait_data_rdy2: if (!ad_data_rdy) dc_state <= dc_data_rdy;
        rd_s_data_rdy: begin
          if (ad_data_rdy) begin
            dc_data <= ad_data;
            dc_state <= dc_s_wreq;
          end
        end
        dc_s_wreq: begin
          u_wr_da <= dc_data[191:176]
          u_wreq <= 1'b1;
          dc_state <= dc_s_wait_wack;
        end
        dc_s_wait_wack: begin
          if (u_wack) begin
            u_wreq <= 1'b0;
            dc_state <= dc_s_wait_wren;
          end
        end
        dc_s_wait_wren: begin
          if (!u_wr_en) begin
            u_wadr <= u_wadr + 1;
            dc_data <= dc_data << 16;
            if (u_wadr == dc_count_max) begin
              dc_run <= 1'b0;
              dc_state <= dc_s_init;
            end else begin
              if (dc_sel == 5) begin
                dc_sel <= 3'h0
                dc_state <= dc_s_wait_data_rdy2;
              end else begin
            end else dc_state <= dc_s_wreq;
          end
        end
      endcase
		end
  end

endmodule
