//----------------------------------------------------------------------
// Joseph Zambreno
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



module dmem (i_CLKa, i_CLKb, i_ENa, i_ENb, i_WEa, i_WEb, i_ADDRa, i_ADDRb,
	     i_WDATAa, i_WDATAb, o_RDATAa, o_RDATAb);

   parameter data_width = 32;
   parameter addr_width = 15; // 2^15 32-bit values

   input i_CLKa, i_CLKb, i_ENa, i_ENb, i_WEa, i_WEb;
   input [(addr_width-1):0] i_ADDRa, i_ADDRb;
   input [(data_width-1):0] i_WDATAa, i_WDATAb;

   output reg [(data_width-1):0] o_RDATAa, o_RDATAb;

   // Register for the memory contents
   reg [data_width-1:0] ram[0:2**addr_width-1];

   // Read the memory contents from a file using readmemh
   initial begin 
      $readmemh("dmem.dat", ram);
   end
   

   // Simple process for memory read/write
   always @ (posedge i_CLKa) begin		 
      if (i_ENa) begin
         if (i_WEa)  
             ram[i_ADDRa] <= i_WDATAa;
         o_RDATAa <= ram[i_ADDRa];
      end
   end

   always @ (posedge i_CLKb) begin		 
      if (i_ENb) begin
         if (i_WEb)  
             ram[i_ADDRb] <= i_WDATAb;
         o_RDATAb <= ram[i_ADDRb];
      end
   end


endmodule
