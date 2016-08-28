//*****************************************************************************
// File Name            : sdram_ctrl.v
//-----------------------------------------------------------------------------
// Function             : sdram_ctrl
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo@himwari_co 
//-----------------------------------------------------------------------------
// History
// -.-- 2010/9/22
// -.-- 2010/11/17
// -.-- 2012/1/2
// -.-- 2012/1/17
//*****************************************************************************
module sdram_ctrl (
  clk,
  reset_n, 
  ram_clke,    
  ram_cs_n, 
  ram_cas_n,    
  ram_ras_n,    
  ram_we_n,    
  ram_dqml,    
  ram_dqmu,    
  ram_ba0,    
  ram_ba1,
  ram_adr,
  ram_dq_w,
  ram_dq_r,
  u_wreq,   
  u_wack,    
  u_wr_da_en,    
  u_wadr,    
  u_wr_da,    
  u_rreq,   
  u_rack,    
  u_radr,    
  u_rd_da_en,    
  u_rd_da,
  out_en,
  state
);

  input clk;
  input reset_n;
  output ram_clke;  //sdram clke
  output ram_cs_n;  //sdram cs
  output ram_cas_n; //sdram cas
  output ram_ras_n; //sdram ras
  output ram_we_n;  //sdram write enable
  output ram_dqml;  //sdram data output enable dq[7:0]
  output ram_dqmu;  //sdram data output enable dq[15:8]
  output ram_ba0;   //sdram bank address 0
  output ram_ba1;   //sdram bank address 1
  output [11:0] ram_adr; //sdram address 
  output [15:0] ram_dq_w; //sdram write data 
  input  [15:0] ram_dq_r; //sdram read data 
  input u_wreq;        //user write req
  output u_wack;       //user write ack
  output u_wr_da_en;        //user write enable
  input [19:0]u_wadr; //user write address
  input [15:0]u_wr_da;  //user write data
  input u_rreq;        //user read req
  output u_rack;       //user read ack
  input [19:0]u_radr; //user read address
  output u_rd_da_en;     //user read  enable
  output [15:0]u_rd_da; //user read  data
  output       out_en; 
  output [3:0] state ; //state


  parameter  p_init = 4'b0;   
  parameter  p_idle = 4'b1;   
  parameter  p_dsl  = 4'd2;   
  parameter  p_pall = 4'd4;   
  parameter  p_init_ref1  = 4'd5;
  parameter  p_init_ref2  = 4'd6;
  parameter  p_mrs  = 4'd7;
  parameter  p_rd_act  = 4'd8;
  parameter  p_rd1  = 4'd9;
  parameter  p_wr_act  = 4'd10;
  parameter  p_wr1  = 4'd11;
  parameter  p_ref  = 4'd12;

   
  parameter  t_clear = 16'd0;
  parameter  t_inc   = 16'd1;
  parameter  t_init_end = 16'd35000;
  parameter  t_pall_end = 16'd5;
  parameter  t_ref_end = 16'd15;
  parameter  t_mrs_end = 16'd2;
  parameter  t_wr_act_end = 16'd2;
  parameter  t_rd_act_end = 16'd2;
  parameter  t_rd1_end = 16'd15;
  parameter  t_wr1_end = 16'd10;
  parameter  t_ref_time = 16'd10000;
   
  parameter  t_rd_da_en_on = 16'd5;
  parameter  t_rd_da_en_off = 16'd13;
  parameter  t_act_wr_da_en_on = 16'd0;
  parameter  t_wr_da_en_off = 16'd5;
  parameter  t_wr_dqm_start = 16'd0;
  parameter  t_wr_dqm_end = 16'd7;
  parameter  t_rd_dqm_start = 16'd1;
  parameter  t_rd_dqm_end = 16'd12;
   
  reg [3:0]   state;        //ステートレジスタ
  reg [15:0]  waite_cnt;    //ウェイトカウンタ
  reg [15:0]  ref_cnt;      //リフレッシュカウンタ
  reg         ref_req;      //リフレッシュリクエスト
   
   
  reg ram_clke;  //sdram clke
  reg ram_cs_n;  //sdram cs
  reg ram_cas_n; //sdram cas
  reg ram_ras_n; //sdram ras
  reg ram_we_n;  //sdram write enable
  reg ram_dqml;  //sdram data enable dq[7:0]
  reg ram_dqmu;  //sdram data enable dq[15:8]
  reg ram_ba0;   //sdram bank address 0
  reg ram_ba1;   //sdram bank address 1
  reg [11:0] ram_adr; //sdram address 
  reg [15:0] ram_dq_w; //sdram write data 
  reg [15:0]u_rd_da; //user read  data
  reg  out_en;
  reg  u_wack;
  reg  u_wr_da_en;
  reg  u_rack;
  reg  u_rd_da_en;
   
   
//ステートマシン ウェイトカウンタ  
always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  begin
    state <= p_init;
    waite_cnt <= t_clear;
  end
else
  case (state)
    //-------------------------------------------------
    p_init:begin
        if (waite_cnt==t_init_end) //210us
          begin
            state <= p_pall;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_init;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
    //-------------------------------------------------
    p_pall:begin
        if (waite_cnt==t_pall_end) 
          begin
            state <= p_init_ref1;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_pall;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
    //-------------------------------------------------
    p_init_ref1:begin
        if (waite_cnt==t_ref_end) 
          begin
            state <= p_init_ref2;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_init_ref1;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
    //-------------------------------------------------
    p_init_ref2:begin
        if (waite_cnt==t_ref_end) 
          begin
            state <= p_mrs;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_init_ref2;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
    //-------------------------------------------------
    p_mrs:begin
        if (waite_cnt==t_mrs_end) 
          begin
            state <= p_idle;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_mrs;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
    //-------------------------------------------------
    p_idle:begin
      if (u_rreq==1'b1) 
        state <= p_rd_act;
      else if (u_wreq==1'b1) 
        state <= p_wr_act;
      else if (ref_req == 1'b1)
        state <= p_ref;
      else
        state <= p_idle;
      waite_cnt <= t_clear;
      end // 
    //-------------------------------------------------
    p_rd_act:begin
      if (waite_cnt==t_rd_act_end)
        begin
          state <= p_rd1;
          waite_cnt <= t_clear;
        end
      else
        begin
          state <= p_rd_act;
           waite_cnt <= waite_cnt + t_inc;
        end
      end // 
    //-------------------------------------------------
    p_rd1:begin
      if (waite_cnt==t_rd1_end)
        begin
          //state <= p_rd_i;
          state <= p_idle;
          waite_cnt <= t_clear;
        end
      else
        begin
          state <= p_rd1;
          waite_cnt <= waite_cnt + t_inc;
        end
      end // 
    //-------------------------------------------------
    p_wr_act:begin
      if (waite_cnt==t_wr_act_end)
        begin
          state <= p_wr1;
          waite_cnt <= t_clear;
        end
      else
        begin
          state <= p_wr_act;
           waite_cnt <= waite_cnt + t_inc;
        end
      end // 
    //-------------------------------------------------
    p_wr1:begin
      if (waite_cnt==t_wr1_end)
        begin
          //state <= p_wr_i;
          state <= p_idle;
          waite_cnt <= t_clear;
        end
      else
        begin
          state <= p_wr1;
          waite_cnt <= waite_cnt + t_inc;
        end
      end //
    //-------------------------------------------------
    p_ref:begin
        if (waite_cnt==t_ref_end) 
          begin
            state <= p_idle;
            waite_cnt <= t_clear;
          end
        else
          begin
            state <= p_ref;
            waite_cnt <= waite_cnt + t_inc;
          end
      end // 
  endcase


//リフレッシュカウンタ   
always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  ref_cnt <= 16'h0000;
else
  if (state==p_ref)
    ref_cnt <= 16'h0000;
  else
    if (ref_cnt < t_ref_time)
      ref_cnt <= ref_cnt + 16'h0001;
    else
      ref_cnt <= t_ref_time;
   

always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  ref_req <= 1'h0;
else
  if (state==p_ref)
    ref_req <= 1'b0;
  else
    if (ref_cnt < t_ref_time)
      ref_req <= 1'b0;
    else
      ref_req <= 1'b1;

//出力信号生成
   
always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  begin
    ram_clke <= 1'b1;  //sdram clke
    ram_cs_n <= 1'b1;  //sdram cs
    ram_cas_n <= 1'b0; //sdram cas
    ram_ras_n <= 1'b0; //sdram ras
    ram_we_n <= 1'b0;  //sdram write enable
    ram_dqml <= 1'b1;  //sdram data   enable dq[7:0]
    ram_dqmu <= 1'b1;  //sdram data   enable dq[15:8]
    ram_ba0 <= 1'b0;   //sdram bank address 0
    ram_ba1 <= 1'b0;   //sdram bank address 1
    ram_adr <= 12'b0; //sdram address 
    ram_dq_w <= 16'h0000; //sdram write data
    out_en <= 1'b0;
  end
else
  if (waite_cnt==16'h0000)
  case (state)
    //-------------------------------------------------
    p_init:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b1;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b0;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'b0;   
      ram_dq_w <= 16'h0000;  
      out_en <= 1'b0; 
    end
    //-------------------------------------------------
    p_pall:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b1; 
      ram_we_n <= 1'b0;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h400;   
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_init_ref1:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h000;   
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_init_ref2:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h000;   
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_mrs:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b0;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h33;   
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_idle:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b1;  
      ram_ras_n <= 1'b1; 
      ram_cas_n <= 1'b1; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h000;   
      ram_dq_w <= 16'h0000;  
      out_en <= 1'b0; 
    end
    //-------------------------------------------------
    p_rd_act:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b1; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= u_radr[18];   
      ram_ba1 <= u_radr[19];   
      ram_adr <= u_radr[17:8];
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_rd1:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b1; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= u_radr[18];   
      ram_ba1 <= u_radr[19];   
      ram_adr <= {4'b0100,u_radr[7:0]};   
      ram_dq_w <= 16'h0000; 
      out_en <= 1'b0;   
    end // case: p_rd1
    //-------------------------------------------------
    p_wr_act:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b1; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= u_wadr[18];   
      ram_ba1 <= u_wadr[19];   
      ram_adr <= u_wadr[17:8];
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;   
    end
    //-------------------------------------------------
    p_wr1:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b1; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b0;  
      ram_dqml <= 1'b0;  
      ram_dqmu <= 1'b0;  
      ram_ba0 <= u_wadr[18];   
      ram_ba1 <= u_wadr[19];   
      ram_adr <= {4'b0100,u_wadr[7:0]};   
      ram_dq_w <= u_wr_da; 
      out_en <= 1'b1;    
    end // case: p_wr
    //-------------------------------------------------
    p_ref:
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b0;  
      ram_ras_n <= 1'b0; 
      ram_cas_n <= 1'b0; 
      ram_we_n <= 1'b1;  
      ram_dqml <= 1'b1;  
      ram_dqmu <= 1'b1;  
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h000;   
      ram_dq_w <= 16'h0000;
      out_en <= 1'b0;     
    end
  endcase // case(state)
  else
    begin
      ram_clke <= 1'b1;  
      ram_cs_n <= 1'b1;  
      ram_ras_n <= 1'b1; 
      ram_cas_n <= 1'b1; 
      ram_we_n <= 1'b1;
      if (((state==p_wr1)&&(waite_cnt>=t_wr_dqm_start)&&(waite_cnt<=t_wr_dqm_end))
          ||((state==p_rd1)&&(waite_cnt>=t_rd_dqm_start)&&(waite_cnt<=t_rd_dqm_end)))
        begin   
          ram_dqml <= 1'b0;   
          ram_dqmu <= 1'b0;   
          ram_dq_w <= u_wr_da;
        end
      else
        begin 
          ram_dqml <= 1'b1;  
          ram_dqmu <= 1'b1;
          ram_dq_w <= 16'h0000;  
        end
      ram_ba0 <= 1'b0;   
      ram_ba1 <= 1'b0;   
      ram_adr <= 12'h000;
      if (state==p_wr1)
        out_en <= 1'b1;
      else
        out_en <= 1'b0;              
    end


// user_if signels
   
always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  begin
    u_wack <= 1'b0;
    u_wr_da_en <= 1'b0;
    u_rack <= 1'b0;
    u_rd_da_en <= 1'b0;
  end
else
  begin
    if ((state==p_wr_act)&&(waite_cnt==16'h0000))
      u_wack <= 1'b1;
    else
      u_wack <= 1'b0;
    if ((state==p_wr_act)&&(u_wreq==1'b1)&&(waite_cnt==t_act_wr_da_en_on))
      u_wr_da_en <= 1'b1;
    //else if ((state==p_wr1)&&(waite_cnt==(t_wr1_end-2)))
    else if ((state==p_wr1)&&(waite_cnt==t_wr_da_en_off))
      u_wr_da_en <= 1'b0;
    else
      u_wr_da_en <=  u_wr_da_en;
    if ((state==p_rd_act)&&(waite_cnt==16'h0000))
      u_rack <= 1'b1;
    else
      u_rack <= 1'b0;
    if ((state==p_rd1)&&(waite_cnt==(t_rd_da_en_on)))
      u_rd_da_en <= 1'b1;
    else if ((state==p_rd1)&&(waite_cnt==(t_rd_da_en_off)))
      u_rd_da_en <= 1'b0;
    else
      u_rd_da_en <=  u_rd_da_en;
  end
     
      
always @ (posedge clk or negedge reset_n )
if (reset_n==1'b0)
  u_rd_da <= 16'h0000;
else
  u_rd_da <= ram_dq_r;
   
endmodule








