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
             i_ADDR,
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
	
	input i_CLKa, i_CLKb;
	input [(addr_width-1):0] i_ADDR;
	
	output reg [(data_width-1):0] o_RDATAa, o_RDATAb, o_RDATAc, o_RDATAd, o_RDATAe, o_RDATAf, o_RDATAg, o_RDATAh;
	
	// Register for the memory contents
	reg [data_width-1:0] ram[0:2**addr_width-1];
	
	// Read the memory contents from a file using readmemh
	initial begin
		$readmemh("dmem.dat", ram);
	end
	
	
	// Simple process for memory read
	always @(posedge i_CLKa) begin
			o_RDATAa <= ram[i_ADDR];
			o_RDATAb <= ram[i_ADDR + 1];
			o_RDATAc <= ram[i_ADDR + 2];
			o_RDATAd <= ram[i_ADDR + 3];
			o_RDATAe <= ram[i_ADDR + 4];
			o_RDATAf <= ram[i_ADDR + 5];
			o_RDATAg <= ram[i_ADDR + 6];
			o_RDATAh <= ram[i_ADDR + 7];
	end
	
endmodule
