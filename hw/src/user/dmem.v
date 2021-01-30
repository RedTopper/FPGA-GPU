//----------------------------------------------------------------------
// Joseph Zambreno, additionally group 4
// Department of Electrical and Computer Engineering
// Iowa State University
//----------------------------------------------------------------------


// dmem.v
//-----------------------------------------------------------------------
// DESCRIPTION: This file contains an implementation of a 32-bit
// dual-port BlockRAM in read-first mode with two write ports. See the
// Xilinx Vivado Synthesis User Guide (ug901), starting at page 99.
//
// NOTES:
// 12/16/20 by JAZ::Design created.
//----------------------------------------------------------------------



module dmem (i_CLKa,
             i_CLKb,
             i_ENa,
             i_ENb,
             i_ENc,
             i_ENd,
             i_ENe,
             i_ENf,
             i_ENg,
             i_ENh,
             i_WEa,
             i_WEb,
             i_ADDRa,
             i_ADDRb,
             i_ADDRc,
             i_ADDRd,
             i_ADDRe,
             i_ADDRf,
             i_ADDRg,
             i_ADDRh,
             i_WDATAa,
             i_WDATAb,
             o_RDATAa,
             o_RDATAb,
             o_RDATAc,
             o_RDATAd,
             o_RDATAe,
             o_RDATAf,
             o_RDATAg,
             o_RDATAh);
	
	parameter data_width = 32;
	parameter addr_width = 15; // 2^15 32-bit values
	
	input i_CLKa, i_CLKb, i_ENa, i_ENb, i_ENc, i_ENd, i_ENe, i_ENf, i_ENg, i_ENh, i_WEa, i_WEb;
	input [(addr_width-1):0] i_ADDRa, i_ADDRb, i_ADDRc, i_ADDRd, i_ADDRe, i_ADDRf, i_ADDRg, i_ADDRh;
	input [(data_width-1):0] i_WDATAa, i_WDATAb;
	
	output reg [(data_width-1):0] o_RDATAa, o_RDATAb, o_RDATAc, o_RDATAd, o_RDATAe, o_RDATAf, o_RDATAg, o_RDATAh;
	
	// Register for the memory contents
	reg [data_width-1:0] ram[0:2**addr_width-1];
	
	// Read the memory contents from a file using readmemh
	initial begin
		$readmemh("dmem.dat", ram);
	end
	
	
	// Simple process for memory read/write
	always @(posedge i_CLKa) begin
		if (i_ENa) begin
			if (i_WEa) begin
				ram[i_ADDRa] <= i_WDATAa;
				o_RDATAa     <= ram[i_ADDRa];
			end
		end
	end
	
	always @ (posedge i_CLKb) begin
		if (i_ENb) begin
			if (i_WEb) begin
				ram[i_ADDRb] <= i_WDATAb;
				o_RDATAb     <= ram[i_ADDRb];
			end
		end
	end
	
	always @ (posedge i_CLKa) begin
		if (i_ENc) begin
			o_RDATAc <= ram[i_ADDRc];
		end
	end
	
	always @ (posedge i_CLKb) begin
		if (i_ENd) begin
			o_RDATAd <= ram[i_ADDRd];
		end
	end
	
	always @ (posedge i_CLKa) begin
		if (i_ENc) begin
			o_RDATAc <= ram[i_ADDRc];
		end
	end
	
	always @ (posedge i_CLKb) begin
		if (i_ENd) begin
			o_RDATAd <= ram[i_ADDRd];
		end
	end
	
	always @ (posedge i_CLKa) begin
		if (i_ENe) begin
			o_RDATAe <= ram[i_ADDRe];
		end
	end
	
	always @ (posedge i_CLKb) begin
		if (i_ENf) begin
			o_RDATAf <= ram[i_ADDRf];
		end
	end
	
	always @ (posedge i_CLKa) begin
		if (i_ENg) begin
			o_RDATAg <= ram[i_ADDRg];
		end
	end
	
	always @ (posedge i_CLKb) begin
		if (i_ENh) begin
			o_RDATAh <= ram[i_ADDRh];
		end
	end
	
endmodule
