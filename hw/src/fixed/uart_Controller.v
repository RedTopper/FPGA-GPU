//-----------------------------------------------------------------------
// Joseph Zambreno
// Department of Electrical and Computer Engineering
// Iowa State University
//-----------------------------------------------------------------------


// uart_Controller.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file implements the UART interface, connecting
// a 64b->8b FIFO to the UART.
//
// NOTES:
// 12/16/20 by JAZ::Design created.
//-----------------------------------------------------------------------


module uart_Controller(clk100,
                       rst,
                       RxD,
                       TxD,
                       msg_din,
                       msg_wren,
                       msg_afull);
	
	input 		  clk100;
	input 		  rst;
	input         RxD;
	output        TxD;
	input [63:0]  msg_din;
	input         msg_wren;
	output        msg_afull;
	
	wire 			  msg_rden, msg_rden_reg, wr_n;
	wire [7:0]    msg_dout;
	
	reg           msg_rden_reg_d1;
	
	mmu_uart_top UART (.Clk(clk100),
	.Reset_n(!rst),
	.TXD(TxD),
	.RXD(RxD),
	.ck_div(16'd3472),//16'd289 for 115200
	.CE_N(1'b0),
	.WR_N(wr_n),
	.RD_N(1'b1),
	.A0(1'b0),
	.D_IN(msg_dout),
	.D_OUT(),
	.RX_full(),
	.TX_busy_n(tx_busy_n));
	
	fifo MSG_BUFFER (
	.wr_clk(clk100),
	.wr_rst(rst),
	.rd_clk(clk100),
	.rd_rst(rst),
	.din(msg_din),
	.wr_en(msg_wren),
	.rd_en(msg_rden),
	.dout(msg_dout),
	.full(msg_full),
	.almost_full(msg_afull),
	.empty(msg_empty),
	.valid(msg_valid));
	
	assign wr_n         = ~(tx_busy_n & msg_valid);
	assign msg_rden_reg = tx_busy_n & (~msg_empty);
	assign msg_rden     = msg_rden_reg & ~msg_rden_reg_d1;
	
	always @ (posedge clk100) begin
		msg_rden_reg_d1 <= msg_rden_reg;
	end
endmodule
