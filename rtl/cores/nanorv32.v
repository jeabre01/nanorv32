//****************************************************************************/
//  nanorv32 CPU
//  RTL IMPLEMENTATION, Synchronous Version
//
//  Copyright (C) yyyy  Ronan Barzic - rbarzic@gmail.com
//  Date            :  Tue Jan 19 20:28:48 2016
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,MA 02110-1301,USA.
//
//
//  Filename        :  nanorv32.v
//
//  Description     :   Nanorv32 CPU top file
//
//
//
//****************************************************************************/
`define AHB_IF
`ifdef AHB_IF
`define AHB_ISIDE_IF
`define AHB_DSIDE_IF
`endif

module nanorv32 (/*AUTOARG*/
   // Outputs
   illegal_instruction, 

   // Inputs
   rst_n, clk, 
   `ifdef AHB_ISIDE_IF
   hrdatai, hrespi, hreadyi, haddri, hproti, hsizei, htransi,
   hmasteri,   hmasterlocki,   hbursti,   hwdatai,   hwritei, 
   `else
   codeif_cpu_rdata, codeif_cpu_early_ready,
   cpu_codeif_addr, cpu_codeif_req,
   cpu_dataif_addr, cpu_dataif_wdata, cpu_dataif_bytesel,
   cpu_dataif_req,
   `endif
   `ifdef AHB_DSIDE_IF
   hrdatad, hrespd, hreadyd, haddrd, hprotd, hsized, hmasterd,
   hmasterlockd, hburstd, hwdatad,  hwrited, htransd, 
   `else
   codeif_cpu_ready_r, dataif_cpu_rdata, dataif_cpu_early_ready,
   dataif_cpu_ready_r
   `endif
   );

`include "nanorv32_parameters.v"


   input                     rst_n;
   input                     clk;

   output                    illegal_instruction;


   // Code memory interface
   `ifdef AHB_ISIDE_IF
   input  [NANORV32_DATA_MSB:0] hrdatai; 
   input                        hrespi;
   input                        hreadyi; 
   output [NANORV32_DATA_MSB:0] haddri;
   output [3:0]                 hproti;
   output [2:0]                 hsizei;
   output                       hmasteri;
   output                       hmasterlocki;
   output [2:0]                 hbursti;
   output [NANORV32_DATA_MSB:0] hwdatai;
   output                       hwritei; 
   output                       htransi; 
   `else
   output [NANORV32_DATA_MSB:0] cpu_codeif_addr;
   output                    cpu_codeif_req;
   input  [NANORV32_DATA_MSB:0] codeif_cpu_rdata;
   input                     codeif_cpu_early_ready;
   input                    codeif_cpu_ready_r;     // From U_ARBITRER of nanorv32_tcm_arbitrer.v
   `endif 
   // Data memory interface

   `ifdef AHB_DSIDE_IF
   input  [NANORV32_DATA_MSB:0] hrdatad; 
   input                        hrespd;
   input                        hreadyd; 
   output [NANORV32_DATA_MSB:0] haddrd;
   output [3:0]                 hprotd;
   output [2:0]                 hsized;
   output                       hmasterd;
   output                       hmasterlockd;
   output [2:0]                 hburstd;
   output [NANORV32_DATA_MSB:0] hwdatad;
   output                       hwrited; 
   output                       htransd; 
   `else 
   output [NANORV32_DATA_MSB:0] cpu_dataif_addr;
   output [NANORV32_DATA_MSB:0] cpu_dataif_wdata;
   output [3:0]              cpu_dataif_bytesel;
   output                    cpu_dataif_req;
   input [NANORV32_DATA_MSB:0]  dataif_cpu_rdata;
   input                     dataif_cpu_early_ready;
   input                     dataif_cpu_ready_r;
   `endif 

   /*AUTOINPUT*/
   /*AUTOOUTPUT*/

   /*AUTOREG*/
   /*AUTOWIRE*/
   `ifdef AHB_ISIDE_IF
   wire  [NANORV32_DATA_MSB:0] codeif_cpu_rdata = hrdatai;
   wire                        codeif_cpu_ready_r = hreadyi;     // From U_ARBITRER of nanorv32_tcm_arbitrer.v
   `endif
   `ifdef AHB_DSIDE_IF
   reg  [1:0] cpu_dataif_addr;
   reg  [NANORV32_DATA_MSB:0] cpu_dataif_wdata;
   reg  [3:0]              cpu_dataif_bytesel;
   wire                    cpu_dataif_req;
   wire [NANORV32_DATA_MSB:0]  dataif_cpu_rdata;
   wire                     dataif_cpu_early_ready = hreadyd;
   wire                     dataif_cpu_ready_r;
   wire [1:0]               read_byte_sel;
   `endif
   
   wire [NANORV32_DATA_MSB:0]                instruction_r;

   //@begin[mux_select_declarations]

    reg  [NANORV32_MUX_SEL_PC_NEXT_MSB:0] pc_next_sel;
    reg  [NANORV32_MUX_SEL_ALU_OP_MSB:0] alu_op_sel;
    reg  [NANORV32_MUX_SEL_ALU_PORTB_MSB:0] alu_portb_sel;
    reg  [NANORV32_MUX_SEL_ALU_PORTA_MSB:0] alu_porta_sel;
    reg  [NANORV32_MUX_SEL_DATAMEM_SIZE_READ_MSB:0] datamem_size_read_sel;
    reg  [NANORV32_MUX_SEL_DATAMEM_WRITE_MSB:0] datamem_write_sel;
    reg  [NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_MSB:0] datamem_size_write_sel;
    reg  [NANORV32_MUX_SEL_DATAMEM_READ_MSB:0] datamem_read_sel;
    reg  [NANORV32_MUX_SEL_REGFILE_SOURCE_MSB:0] regfile_source_sel;
    reg  [NANORV32_MUX_SEL_REGFILE_WRITE_MSB:0] regfile_write_sel;
   //@end[mux_select_declarations]

   //@begin[instruction_fields]

    wire [NANORV32_INST_FORMAT_OPCODE1_MSB:0] dec_opcode1  = instruction_r[NANORV32_INST_FORMAT_OPCODE1_OFFSET +: NANORV32_INST_FORMAT_OPCODE1_SIZE];
    wire [NANORV32_INST_FORMAT_FUNC3_MSB:0] dec_func3  = instruction_r[NANORV32_INST_FORMAT_FUNC3_OFFSET +: NANORV32_INST_FORMAT_FUNC3_SIZE];
    wire [NANORV32_INST_FORMAT_FUNC7_MSB:0] dec_func7  = instruction_r[NANORV32_INST_FORMAT_FUNC7_OFFSET +: NANORV32_INST_FORMAT_FUNC7_SIZE];
    wire [NANORV32_INST_FORMAT_RD_MSB:0] dec_rd  = instruction_r[NANORV32_INST_FORMAT_RD_OFFSET +: NANORV32_INST_FORMAT_RD_SIZE];
    wire [NANORV32_INST_FORMAT_RS1_MSB:0] dec_rs1  = instruction_r[NANORV32_INST_FORMAT_RS1_OFFSET +: NANORV32_INST_FORMAT_RS1_SIZE];
    wire [NANORV32_INST_FORMAT_RS2_MSB:0] dec_rs2  = instruction_r[NANORV32_INST_FORMAT_RS2_OFFSET +: NANORV32_INST_FORMAT_RS2_SIZE];
    wire [NANORV32_INST_FORMAT_IMM12_MSB:0] dec_imm12  = instruction_r[NANORV32_INST_FORMAT_IMM12_OFFSET +: NANORV32_INST_FORMAT_IMM12_SIZE];
    wire [NANORV32_INST_FORMAT_IMM12HI_MSB:0] dec_imm12hi  = instruction_r[NANORV32_INST_FORMAT_IMM12HI_OFFSET +: NANORV32_INST_FORMAT_IMM12HI_SIZE];
    wire [NANORV32_INST_FORMAT_IMM12LO_MSB:0] dec_imm12lo  = instruction_r[NANORV32_INST_FORMAT_IMM12LO_OFFSET +: NANORV32_INST_FORMAT_IMM12LO_SIZE];
    wire [NANORV32_INST_FORMAT_IMMSB2_MSB:0] dec_immsb2  = instruction_r[NANORV32_INST_FORMAT_IMMSB2_OFFSET +: NANORV32_INST_FORMAT_IMMSB2_SIZE];
    wire [NANORV32_INST_FORMAT_IMMSB1_MSB:0] dec_immsb1  = instruction_r[NANORV32_INST_FORMAT_IMMSB1_OFFSET +: NANORV32_INST_FORMAT_IMMSB1_SIZE];
    wire [NANORV32_INST_FORMAT_IMM20_MSB:0] dec_imm20  = instruction_r[NANORV32_INST_FORMAT_IMM20_OFFSET +: NANORV32_INST_FORMAT_IMM20_SIZE];
    wire [NANORV32_INST_FORMAT_IMM20UJ_MSB:0] dec_imm20uj  = instruction_r[NANORV32_INST_FORMAT_IMM20UJ_OFFSET +: NANORV32_INST_FORMAT_IMM20UJ_SIZE];
    wire [NANORV32_INST_FORMAT_SHAMT_MSB:0] dec_shamt  = instruction_r[NANORV32_INST_FORMAT_SHAMT_OFFSET +: NANORV32_INST_FORMAT_SHAMT_SIZE];
    wire [NANORV32_INST_FORMAT_FUNC4_MSB:0] dec_func4  = instruction_r[NANORV32_INST_FORMAT_FUNC4_OFFSET +: NANORV32_INST_FORMAT_FUNC4_SIZE];
    wire [NANORV32_INST_FORMAT_FUNC12_MSB:0] dec_func12  = instruction_r[NANORV32_INST_FORMAT_FUNC12_OFFSET +: NANORV32_INST_FORMAT_FUNC12_SIZE];
   //@end[instruction_fields]

   reg                                       write_rd;
   reg                                       datamem_read;
   reg                                       datamem_write;


   reg [NANORV32_DATA_MSB:0]                next_pc;


   wire [NANORV32_DATA_MSB:0]               rf_porta;
   wire [NANORV32_DATA_MSB:0]               rf_portb;
   reg [NANORV32_DATA_MSB:0]                rd;

   reg [NANORV32_DATA_MSB:0]                alu_porta;
   reg [NANORV32_DATA_MSB:0]                alu_portb;
   wire [NANORV32_DATA_MSB:0]               alu_res;


   reg [NANORV32_DATA_MSB:0]               pc_next;
   reg [NANORV32_DATA_MSB:0]               pc_fetch_r;
   reg [NANORV32_DATA_MSB:0]               pc_exe_r;  // Fixme - we track the PC for the exe stage explicitly
                                                       // this may not be optimal in term of size

   reg [NANORV32_PSTATE_MSB:0]             pstate_next;
   reg [NANORV32_PSTATE_MSB:0]             pstate_r;

   reg                                     branch_taken;
   reg                                     inst_valid_fetch;


   wire                                    alu_cond;

   reg                                     illegal_instruction;

   reg [NANORV32_DATA_MSB:0]              mem2regfile;

   wire                                     stall_exe;
   wire                                     stall_fetch;
   reg                                      force_stall_pstate;
   reg                                      force_stall_pstate2;


   reg                                      output_new_pc;
   wire                                      cpu_codeif_req;
   reg                                       valid_inst;

   //===========================================================================
   // Immediate value reconstruction
   //===========================================================================

   wire [NANORV32_DATA_MSB:0]                   imm12_sext;
   wire [NANORV32_DATA_MSB:0]                   imm12hilo_sext;
   wire [NANORV32_DATA_MSB:0]                   imm12sb_sext;
   wire [NANORV32_DATA_MSB:0]                   imm20u_sext;
   wire [NANORV32_DATA_MSB:0]                   imm20uj_sext;

   assign imm12_sext = {{20{dec_imm12 [11]}},dec_imm12[11:0]};
   assign imm12hilo_sext = {{20{dec_imm12hi[6]}},dec_imm12hi[6:0],dec_imm12lo[4:0]};
   assign imm12sb_sext = {{20{dec_immsb2[6]}},dec_immsb2[6],dec_immsb1[0],dec_immsb2[5:0],dec_immsb1[4:1],1'b0};

   // Fixme - incomplete/wrong


   assign imm20u_sext = {dec_imm20uj[19:0],12'b0};

   assign imm20uj_sext = {{12{dec_imm20uj[19]}},
                        dec_imm20uj[19],
                        dec_imm20uj[7:3],
                        dec_imm20uj[2:0],
                        dec_imm20uj[8],
                        dec_imm20uj[18:13],
                        dec_imm20uj[12:9],
                        1'b0};




   //===========================================================================
   // Instruction register / decoding
   //===========================================================================
   reg force_stall_reset;
   `define INSTRUCTION_QUEUE
   `ifdef INSTRUCTION_QUEUE 
   reg  write_data;
   wire  branch_req_tmp;
   wire  next_inst_en_tmp; 
   wire  htransi_tmp; 
   wire [31:0] branch_target_tmp = pc_next;
   wire [31:0]  haddri_tmp;
   reg  [31:0]  haddri_r;
   reg  [1:0] wr_pt_r , rd_pt_r;
   wire  [2:0] wr_pt_r_plus1 = wr_pt_r + 1;
   wire fifo_full = wr_pt_r_plus1[1:0] == rd_pt_r[1:0] & pstate_r != NANORV32_PSTATE_BRANCH;
   reg  [31:0] iq [3:0];
   wire inst_ret = (!(stall_exe | force_stall_reset));
   reg  branch_taken_reg;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         branch_taken_reg <= 1'b0;
         /*AUTORESET*/
      end
      else begin
         if(hreadyi) 
           branch_taken_reg <= branch_taken & hreadyi & ~reset_over &  pstate_r != NANORV32_PSTATE_BRANCH;
      end
   end
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         write_data <= 1'b0;
         /*AUTORESET*/
      end
      else begin
         if(hreadyi) 
           write_data <= htransi & hreadyi;
      end
   end
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         wr_pt_r <= 2'b00;
         /*AUTORESET*/
      end
      else begin
         if(write_data | branch_taken & ~ignore_branch)
           wr_pt_r <= branch_taken & ~ignore_branch &  pstate_r != NANORV32_PSTATE_BRANCH ? 2'b00 : wr_pt_r + 1;
      end
   end 
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         rd_pt_r <= 2'b00;
         /*AUTORESET*/
      end
      else begin
         if(inst_ret & ~reset_over)
           rd_pt_r <= branch_taken_reg ? 2'b00 : rd_pt_r + 1;
      end
   end
   wire  cancel_data = branch_req_tmp;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           iq[0] <= NANORV32_J0_INSTRUCTION;
         /*AUTORESET*/
      end
      else begin
         if(wr_pt_r == 0 & write_data & ~cancel_data) 
           iq[0] <= codeif_cpu_rdata;
      end
   end
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           iq[1] <= NANORV32_J0_INSTRUCTION;
         /*AUTORESET*/
      end
      else begin
         if(wr_pt_r == 1 & write_data & ~cancel_data) 
           iq[1] <= codeif_cpu_rdata;
      end
   end
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           iq[2] <= NANORV32_J0_INSTRUCTION;
         /*AUTORESET*/
      end
      else begin
         if(wr_pt_r == 2 & write_data & ~cancel_data) 
           iq[2] <= codeif_cpu_rdata;
      end
   end
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           iq[3] <= NANORV32_J0_INSTRUCTION;
         /*AUTORESET*/
      end
      else begin
         if(wr_pt_r == 3 & write_data & ~cancel_data) 
           iq[3] <= codeif_cpu_rdata;
      end
   end
   reg  reset_over;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           reset_over <= 1'b1;
         /*AUTORESET*/
      end
      else begin
         if( force_stall_reset | reset_over & write_data) 
           reset_over <= force_stall_reset; 
      end
   end
   reg  ignore_branch;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
           ignore_branch <= 1'b1;
         /*AUTORESET*/
      end
      else begin
         if(write_data & reset_over ) 
           ignore_branch <= ~write_data; 
      end
   end

   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
          haddri_r  <= 32'b0;
         /*AUTORESET*/
      end
      else if ((next_inst_en_tmp | branch_req_tmp & ~force_stall_reset) & hreadyi) begin
          haddri_r <= haddri_tmp;
      end
   end
   assign branch_req_tmp =  branch_taken & ~ignore_branch & pstate_r != NANORV32_PSTATE_BRANCH;
   assign next_inst_en_tmp = ~force_stall_reset & ~fifo_full; 
   assign htransi_tmp  = (next_inst_en_tmp | branch_req_tmp) & ~force_stall_reset ; 
   assign haddri_tmp  = branch_req_tmp & ~reset_over ? branch_target_tmp : {32{~(force_stall_reset | reset_over & htransi_tmp & ~write_data)}} & (haddri_r + 4);
   
 
 
   assign instruction_r = iq[rd_pt_r];
   `else
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         instruction_r <= NANORV32_J0_INSTRUCTION;
         /*AUTORESET*/
      end
      else begin
         if(!(stall_fetch | force_stall_reset))
           instruction_r <= codeif_cpu_rdata;
      end
   end
   `endif
   event evt_dbg1;


   always @* begin
      illegal_instruction = 0;
      casez(instruction_r[NANORV32_INSTRUCTION_MSB:0])
        //@begin[instruction_decoder]
    NANORV32_DECODE_AND: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_AND;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LBU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE_UNSIGNED;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_YES;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_FENCE: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOOP;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SW: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12HILO;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_YES;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_BLTU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_UNSIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_XOR: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_XOR;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SLTU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_UNSIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_ANDI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_AND;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_JALR: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_ALU_RES;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_PC_EXE_PLUS_4;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_BLT: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_SIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SCALL: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOOP;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_FENCE_I: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOOP;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_JAL: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_ALU_RES;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM20UJ;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_PC_EXE;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_PC_EXE_PLUS_4;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LH: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_YES;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LW: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_YES;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_ADD: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_AUIPC: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM20U;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_PC_EXE;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_WORD;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LUI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOP;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM20U;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_WORD;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_BNE: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NEQ;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SBREAK: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOOP;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_BGEU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_GE_UNSIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SLTIU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_UNSIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SRAI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ARSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_SHAMT;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_ORI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_OR;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_XORI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_XOR;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LB: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_YES;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SUB: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_SUB;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SRA: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ARSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_BGE: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_GE_SIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SLT: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_SIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SRLI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_RSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_SHAMT;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SLTI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LT_SIGNED;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SRL: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_RSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SLL: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_LHU: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD_UNSIGNED;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_YES;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SH: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12HILO;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_YES;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_HALFWORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_SLLI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_LSHIFT;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_SHAMT;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_ADDI: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
    NANORV32_DECODE_SB: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_ADD;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_IMM12HILO;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_YES;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_BYTE;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_BEQ: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_EQ;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
    end
    NANORV32_DECODE_OR: begin
        pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
        alu_op_sel = NANORV32_MUX_SEL_ALU_OP_OR;
        alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
        alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
        datamem_size_read_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD;
        datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
        datamem_size_write_sel = NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD;
        datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
        regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
        regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_YES;
    end
        //@end[instruction_decoder]
        default begin
           illegal_instruction = 1;

           pc_next_sel = NANORV32_MUX_SEL_PC_NEXT_PLUS4;
           alu_op_sel = NANORV32_MUX_SEL_ALU_OP_NOP;
           alu_portb_sel = NANORV32_MUX_SEL_ALU_PORTB_RS2;
           alu_porta_sel = NANORV32_MUX_SEL_ALU_PORTA_RS1;
           datamem_write_sel = NANORV32_MUX_SEL_DATAMEM_WRITE_NO;
           datamem_read_sel = NANORV32_MUX_SEL_DATAMEM_READ_NO;
           regfile_source_sel = NANORV32_MUX_SEL_REGFILE_SOURCE_ALU;
           regfile_write_sel = NANORV32_MUX_SEL_REGFILE_WRITE_NO;
        end
      endcase // casez (instruction[NANORV32_INSTRUCTION_MSB:0])
   end


   //===========================================================================
   // ALU input selection
   //===========================================================================
   always @* begin
      case(alu_portb_sel)
        NANORV32_MUX_SEL_ALU_PORTB_IMM20U: begin
           alu_portb = imm20u_sext;
        end
        NANORV32_MUX_SEL_ALU_PORTB_SHAMT: begin
           alu_portb = {{NANORV32_SHAMT_FILL{1'b0}},dec_shamt};
        end
        NANORV32_MUX_SEL_ALU_PORTB_IMM12: begin
           alu_portb = imm12_sext;
        end
        NANORV32_MUX_SEL_ALU_PORTB_RS2: begin
           alu_portb = rf_portb;
        end
        NANORV32_MUX_SEL_ALU_PORTB_IMM20UJ: begin
           alu_portb = imm20uj_sext;
        end
        NANORV32_MUX_SEL_ALU_PORTB_IMM12HILO: begin
           alu_portb = imm12hilo_sext;
        end
        default begin
           alu_portb = rf_portb;
        end
      endcase
   end

   always @* begin
      case(alu_porta_sel)
        NANORV32_MUX_SEL_ALU_PORTA_PC_EXE: begin
           alu_porta = pc_exe_r;
        end
        NANORV32_MUX_SEL_ALU_PORTA_RS1: begin
           alu_porta = rf_porta;
        end// Mux definitions for datamem
      default begin
         alu_porta = rf_porta;
      end  // default:
      endcase
   end

   //===========================================================================
   // Register file write-back
   //===========================================================================
   always @* begin
      case(regfile_source_sel)
        NANORV32_MUX_SEL_REGFILE_SOURCE_PC_EXE_PLUS_4:begin
           rd <= pc_exe_r + 4;
        end
        NANORV32_MUX_SEL_REGFILE_SOURCE_ALU: begin
           rd <= alu_res;
        end
        NANORV32_MUX_SEL_REGFILE_SOURCE_DATAMEM: begin
           rd <= mem2regfile ;
        end
        default begin
           rd <= alu_res;
        end
      endcase
   end // always @ *

   always @* begin
      case(regfile_write_sel)
        NANORV32_MUX_SEL_REGFILE_WRITE_YES: begin
           write_rd = (!stall_exe) & valid_inst & ~(datamem_read);
        end
        NANORV32_MUX_SEL_REGFILE_WRITE_NO: begin
           write_rd = 1'b0;
        end
        default begin
           write_rd = 1'b0;
        end
        // default:
      endcase // case (regfile_write)

   end
   `define PIPELINE_DSIDE
   `ifdef PIPELINE_DSIDE
   reg [NANORV32_INST_FORMAT_RD_MSB:0] dec_rd2; 
   reg write_rd2;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         write_rd2 <= 1'b0;
         dec_rd2   <= {NANORV32_INST_FORMAT_RD_SIZE{1'b0}}; 
         // End of automatics
      end
      else begin
         if ((datamem_write || datamem_read) & ~force_stall_pstate2)
           begin
           write_rd2 <= write_rd;
           dec_rd2   <= dec_rd; 
           end
      end
   end
   wire [31:0]  rd2 = mem2regfile;
   `endif

   //===========================================================================
   // Data memory interface
   //===========================================================================

   always @* begin
      case(datamem_read_sel)
        NANORV32_MUX_SEL_DATAMEM_READ_YES: begin
           datamem_read = valid_inst;
        end
        NANORV32_MUX_SEL_DATAMEM_READ_NO: begin
           datamem_read = 1'b0;
        end
        default begin
           datamem_read = 1'b0;
        end
      endcase
   end

   always @* begin
      case(datamem_write_sel)
        NANORV32_MUX_SEL_DATAMEM_WRITE_YES: begin
           datamem_write = valid_inst;
        end
        NANORV32_MUX_SEL_DATAMEM_WRITE_NO: begin
           datamem_write = 0;
        end
        default begin
           datamem_write = 1'b0;
        end
      endcase
   end



   //===========================================================================
   // PC management
   //===========================================================================
   always @* begin


      case(pc_next_sel)
        NANORV32_MUX_SEL_PC_NEXT_COND_PC_PLUS_IMMSB: begin
           pc_next = (alu_cond & output_new_pc ) ? (pc_exe_r + imm12sb_sext) : (pc_fetch_r + 4);
           // branch_taken = alu_cond & !stall_exe;
           branch_taken = alu_cond;
        end
        NANORV32_MUX_SEL_PC_NEXT_PLUS4: begin
           if(!stall_exe & !stall_fetch) begin
              pc_next = pc_fetch_r + 4; // Only 32-bit instruction for now
              branch_taken = 0;
           end
           else begin
              pc_next = pc_fetch_r; // Only 32-bit instruction for now
              branch_taken = 0;
           end

        end
        NANORV32_MUX_SEL_PC_NEXT_ALU_RES: begin
           // The first cycle of a branch instruction, we need to output the
           // pc - but once we have fetch the new instruction, we need to start
           // fetching  the n+1 instruction
           // Fixme - this may not be valid if there is some wait-state
           pc_next = output_new_pc  ? alu_res & 32'hFFFFFFFE : (pc_fetch_r + 4);


           branch_taken = 1;
        end// Mux definitions for alu
        default begin
           pc_next = pc_fetch_r + 4;
           branch_taken = 0;
        end
      endcase
   end

   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         pc_exe_r <= {(1+(NANORV32_DATA_MSB)){1'b0}};
         pc_fetch_r <= {(1+(NANORV32_DATA_MSB)){1'b0}};
         // End of automatics
      end
      else begin
         if(inst_ret)
           pc_fetch_r <= {32{~reset_over}} & pc_next;

         if(inst_ret) begin

            pc_exe_r  <=  {32{~reset_over}} & pc_next;
         end
      end
   end

   //===========================================================================
   // Flow management
   //===========================================================================

   assign cpu_codeif_req = 1'b1;
   reg data_access_cycle; // Indicate when it is ok to access data space
   reg data_started;
   // (the first cycle normally)

   always @* begin


      pstate_next =  NANORV32_PSTATE_CONT;
      force_stall_pstate = 0;
      force_stall_reset = 0;
      output_new_pc = 0;
      valid_inst = 1;
      data_access_cycle = 0;
 

      case(pstate_r)

        NANORV32_PSTATE_RESET: begin
           force_stall_pstate = 1;
           force_stall_pstate2 = 1;
           force_stall_reset = 1;
           pstate_next =  NANORV32_PSTATE_CONT;

        end
        NANORV32_PSTATE_CONT: begin
           if(branch_taken) begin
              force_stall_pstate = 1;
              force_stall_pstate2 = 0;
              pstate_next =  NANORV32_PSTATE_BRANCH;
              output_new_pc = 1;
           end
           else if((datamem_write || datamem_read))
             begin
                // we use an early "ready",
                // so we move to state WAITLD when the memory is ready
                force_stall_pstate = 0;
                force_stall_pstate2 = 1;
                data_access_cycle  = 1; 
                pstate_next = NANORV32_PSTATE_WAITLD;
             end
        end

        NANORV32_PSTATE_BRANCH: begin
           output_new_pc = 1;
          if (codeif_cpu_ready_r) begin
              force_stall_pstate = 1'b0;
              force_stall_pstate2 = 0;
              pstate_next =  NANORV32_PSTATE_CONT;
           end
           else begin
              force_stall_pstate = 1'b1;
              force_stall_pstate2 = 0;
              pstate_next =  NANORV32_PSTATE_BRANCH;
           end
        end
        NANORV32_PSTATE_STALL: begin
           valid_inst = 0;
           if (codeif_cpu_ready_r)
             begin
              force_stall_pstate = 1'b0;
              force_stall_pstate2 = 0;
              pstate_next =  NANORV32_PSTATE_CONT ;
           end
           else begin
              force_stall_pstate = 1'b1;
              force_stall_pstate2 = 0;
              pstate_next =  NANORV32_PSTATE_STALL;
           end
        end // case: NANORV32_PSTATE_STALL
        NANORV32_PSTATE_WAITLD: begin
           //if (!dataif_cpu_early_ready)
           //  begin
           //     force_stall_pstate = 1'b1;
           //     pstate_next =  NANORV32_PSTATE_WAITLD;
           //  end
           //else begin
              data_started        = 1; 
              if(hreadyd) begin
                 if((datamem_write || datamem_read))
                 begin
                  // we use an early "ready",
                  // so we move to state WAITLD when the memory is ready
                  force_stall_pstate = 0;
                  force_stall_pstate2 = 1;
                  data_access_cycle  = 1; 
                  pstate_next = NANORV32_PSTATE_WAITLD;
                end else begin 
                  pstate_next =  NANORV32_PSTATE_CONT;
                  force_stall_pstate = 1'b0;
                  force_stall_pstate2 = 0;
                  data_access_cycle  = 0; 
                end
              end
              else begin
                 pstate_next =  NANORV32_PSTATE_WAITLD;
                 force_stall_pstate = 1'b1;
                 force_stall_pstate2 = 1;
              end
           // end
        end // case: NANORV32_PSTATE_WAITLD
        default begin

           pstate_next =  NANORV32_PSTATE_CONT;
           force_stall_pstate = 0;
           force_stall_pstate2 = 0;
           force_stall_reset = 0;
           output_new_pc = 0;
        end
     endcase // case (pstate_r)
   end // always @ *

   always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0) begin
         pstate_r <= NANORV32_PSTATE_RESET;
         // instruction_r - so it must be valid
         /*AUTORESET*/
      end
      else begin
         pstate_r <= pstate_next;

      end
   end


   nanorv32_regfile #(.NUM_REGS(32))
   U_REG_FILE (
               .porta          (rf_porta[NANORV32_DATA_MSB:0]),
               .portb          (rf_portb[NANORV32_DATA_MSB:0]),
               // Inputs
               .sel_porta               (dec_rs1[NANORV32_RF_PORTA_MSB:0]),
               .sel_portb               (dec_rs2[NANORV32_RF_PORTB_MSB:0]),
               .sel_rd                  (dec_rd[NANORV32_RF_PORTRD_MSB:0]),
               .sel_rd2                 (dec_rd2[NANORV32_RF_PORTRD_MSB:0]),
               .rd                      (rd[NANORV32_DATA_MSB:0]),
               .rd2                     (rd2[NANORV32_DATA_MSB:0]),
               .write_rd                (write_rd),
               .write_rd2               (write_rd2),
               .clk                     (clk),
               .rst_n                   (rst_n));



   nanorv32_alu U_ALU (

                       // Outputs
                       .alu_res         (alu_res[NANORV32_DATA_MSB:0]),
                       .alu_cond        (alu_cond),
                       // Inputs
                       .alu_op_sel      (alu_op_sel[NANORV32_MUX_SEL_ALU_OP_MSB:0]),
                       .alu_porta       (alu_porta[NANORV32_DATA_MSB:0]),
                       .alu_portb       (alu_portb[NANORV32_DATA_MSB:0]));


   // Code memory interface
   `ifdef AHB_ISIDE_IF
   assign haddri       = haddri_tmp;  // addr is the next PC
   assign htransi      = hreadyi & ~force_stall_reset & ~fifo_full;  // request is the AHB is free
   assign hsizei       = 3'b010;   // word request
   assign hproti       = 4'b0001;  // instruction data
   assign hbursti      = 3'b000;   // Burst not supported
   assign hmasteri     = 1'b0;     // Core is the 0 master ID
   assign hmasterlocki = 1'b0;     // Master lock is not used
   assign hwritei      = 1'b0;     // Iside is doing only reads
   assign hwdatai      = 32'h0;    // Write data is not supported on Iside
   wire   unused       = hrespi;
   `else 
   assign cpu_codeif_addr = pc_next;
   `endif

   // data memory interface
 `ifdef AHB_DSIDE_IF  
   assign haddrd = alu_res;
   always @ (posedge clk or negedge rst_n) begin
   if (rst_n == 1'b0) 
      cpu_dataif_addr <= 2'b00;
   else if (hreadyd & htransd) 
      cpu_dataif_addr <= alu_res[1:0];
   end
 `else
   assign cpu_dataif_addr = alu_res;
 `endif



   // assign mem2regfile = dataif_cpu_rdata;
   // assign cpu_dataif_wdata = rf_portb;

   assign cpu_dataif_req = (datamem_write || datamem_read) & data_access_cycle;
   // assign stall_fetch = !codeif_cpu_early_ready  | force_stall_pstate | !codeif_cpu_ready_r;
   assign stall_fetch = force_stall_pstate | !codeif_cpu_ready_r;
   assign stall_exe = force_stall_pstate;
   assign read_byte_sel = cpu_dataif_addr[1:0];
   wire  [2:0] hsized_tmp = (datamem_size_read_sel == NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD_UNSIGNED | 
                             datamem_size_read_sel == NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD) & 3'b001 |
                             (datamem_size_read_sel == NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE_UNSIGNED |
                             datamem_size_read_sel == NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE) & 3'b000 |
                             datamem_size_read_sel == NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD & 3'b010;
   
   always @* begin
      case(datamem_size_read_sel)
        NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD_UNSIGNED: begin
           case(cpu_dataif_addr[1])
             1'b0: begin
                mem2regfile =  {16'b0,dataif_cpu_rdata[15:0]};
             end
             1'b1: begin
                mem2regfile =  {16'b0,dataif_cpu_rdata[31:16]};
             end
           endcase

        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_READ_HALFWORD: begin
           case(cpu_dataif_addr[1])
             1'b0: begin
                mem2regfile =  {{16{dataif_cpu_rdata[15]}},dataif_cpu_rdata[15:0]};
             end
             1'b1: begin
                mem2regfile =  {{16{dataif_cpu_rdata[31]}},dataif_cpu_rdata[31:16]};
             end
           endcase
        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_READ_WORD: begin
           mem2regfile = dataif_cpu_rdata ;
        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE: begin
           case(cpu_dataif_addr[1:0])
             2'b00: begin
                mem2regfile =  {{24{dataif_cpu_rdata[7]}},dataif_cpu_rdata[7:0]};
             end
             2'b01: begin
                mem2regfile =  {{24{dataif_cpu_rdata[15]}},dataif_cpu_rdata[15:8]};
             end
             2'b10: begin
                mem2regfile =  {{24{dataif_cpu_rdata[23]}},dataif_cpu_rdata[23:16]};
             end
             2'b11: begin
                mem2regfile =  {{24{dataif_cpu_rdata[31]}},dataif_cpu_rdata[31:24]};
             end
           endcase
        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_READ_BYTE_UNSIGNED: begin
           case(cpu_dataif_addr[1:0])
             2'b00: begin
                mem2regfile =  {24'b0,dataif_cpu_rdata[7:0]};
             end
             2'b01: begin
                mem2regfile =  {24'b0,dataif_cpu_rdata[15:8]};
             end
             2'b10: begin
                mem2regfile =  {24'b0,dataif_cpu_rdata[23:16]};
             end
             2'b11: begin
                mem2regfile =  {24'b0,dataif_cpu_rdata[31:24]};
             end
           endcase
        end
        default begin
           mem2regfile =  dataif_cpu_rdata;
        end // UNMATCHED !!
      endcase
   end

   // fixme - we don't need to mux zeros in unwritten bytes
   always @* begin
      case(datamem_size_write_sel)
        NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_BYTE: begin

           case(haddrd[1:0])
             2'b00: begin
                cpu_dataif_wdata =  {24'b0,rf_portb[7:0]};
                cpu_dataif_bytesel = {3'b0,datamem_write};
             end
             2'b01: begin
                cpu_dataif_wdata =  {16'b0,rf_portb[7:0],8'b0};
                cpu_dataif_bytesel = {2'b0,datamem_write,1'b0};
             end
             2'b10: begin
                cpu_dataif_wdata =  {8'b0,rf_portb[7:0],16'b0};
                cpu_dataif_bytesel = {1'b0,datamem_write,2'b0};
             end
             2'b11: begin
                cpu_dataif_wdata =  {rf_portb[7:0],24'b0};
                cpu_dataif_bytesel = {datamem_write,3'b0};
             end
             default begin
                cpu_dataif_bytesel = {4{datamem_write}};
                cpu_dataif_wdata =  rf_portb;
             end
           endcase
        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_HALFWORD: begin
           case(haddrd[1])
             1'b0: begin
                cpu_dataif_wdata =  {16'b0,rf_portb[15:0]};
                cpu_dataif_bytesel = {2'b0,datamem_write,datamem_write};
             end
             1'b1: begin
                cpu_dataif_wdata =  {rf_portb[15:0],16'b0};
                cpu_dataif_bytesel = {datamem_write,datamem_write,2'b0};
             end

             default begin
                cpu_dataif_bytesel = {4{datamem_write}};
                cpu_dataif_wdata =  rf_portb;
             end
           endcase

        end
        NANORV32_MUX_SEL_DATAMEM_SIZE_WRITE_WORD: begin
           cpu_dataif_wdata = rf_portb;
           cpu_dataif_bytesel = {4{datamem_write}};
        end
        default begin
           cpu_dataif_wdata = rf_portb;
           cpu_dataif_bytesel = {4{datamem_write}};
        end
      endcase
   end

   `ifdef AHB_DSIDE_IF
   reg [31:0] cpu_dataif_wdata_reg;
   always @ (posedge clk or negedge rst_n) begin
   if (rst_n == 1'b0) 
      cpu_dataif_wdata_reg <= 31'b00;
   else if (hreadyd & htransd) 
      cpu_dataif_wdata_reg <= cpu_dataif_wdata;
   end
     
   assign hwdatad          = cpu_dataif_wdata_reg;
   assign htransd          = cpu_dataif_req; 
   assign hwrited          = datamem_write; 
   assign hsized           = datamem_write ? datamem_size_write_sel : hsized_tmp ; 
   assign hburstd          = 3'b000 ; 
   assign hmasterd         = 1'b0 ; 
   assign hmasterlockd     = 1'b0 ;
   assign hprotd           = 4'b0000; 
   assign dataif_cpu_rdata = hrdatad; 
   `endif 

endmodule // nanorv32
/*
 Local Variables:
 verilog-library-directories:(
 "."
 )
 End:
 */
