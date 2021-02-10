/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_system.c - provides definitions for all the memory-mapped peripherals
 * in the SGP implementation, as well as some helper functions to access them
 * Add to this file to define any new address spaces or peripherals. 
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/

#include "sgp_system.h"
#include "sgp_transmit.h"
#include "sgp_graphics.h"

// This is manually coded from the Vivado Address Editor view of the SGP system
SGP_systemmap_t SGP_systemmap[SGP_SYSTEM_NUMCOMPONENTS] = {
[SGP_AXI_UARTLITE_0] = { 0x40600000, 0x4060FFFF, "axi_uartlite_0 " , "UART port for serial communication" },
[SGP_MEMORY_DMA]     = { 0x44A30000, 0x44A3FFFF, "memory_dma     " , "CDMA module for mem-mem transfers" },
[SGP_SYSTEM_DMA]     = { 0x44A40000, 0x44A4FFFF, "system_dma     " , "CDMA module for system-wide transfers" },
[SGP_AXI_DYNCLK_0]   = { 0x44A20000, 0x44A2FFFF, "axi_dynclk_0   " , "Pixel clock generator for HDMI out" },
[SGP_AXI_VDMA_0]     = { 0x44A00000, 0x44A0FFFF, "axi_vdma_0     " , "VDMA module for HDMI out" },
[SGP_V_TC_0]         = { 0x44A10000, 0x44A1FFFF, "v_tc_0         " , "Timing controller for HDMI out" },
[SGP_MEM_INTERFACE]  = { 0x80000000, 0x9FFFFFFF, "mem_interface  " , "512MB shared main memory" }
};

// Manually coded video modes. Should not need to change
SGP_videomode_t SGP_videomodes[SGP_NUMVIDEOMODES] = {
[VMODE_640x480] = { .label = "640x480@60Hz", .width = 640, .height = 480, .hps = 656, .hpe = 752, .hmax = 799, .hpol = 0, .vps = 490, .vpe = 492, .vmax = 524, .vpol = 0, .freq = 25.0,
					.dynclk_0 = 0x00000104, .dynclk_fb = 0x00000145, .dynclk_frac = 0x00000000, .dynclk_div = 0x00001041, .dynclk_lock = 0x3E8FA401, .dynclk_fltr = 0x004B00E7},
[VMODE_800x600] = { .label = "800x600@60Hz", .width = 800, .height = 600, .hps = 840, .hpe = 968, .hmax = 1055, .hpol = 1, .vps = 601, .vpe = 605, .vmax = 627, .vpol = 1, .freq = 40.0,
					.dynclk_0 = 0x00800042, .dynclk_fb = 0x000000C3, .dynclk_frac = 0x00000000, .dynclk_div = 0x00001041, .dynclk_lock = 0x7E8FA401, .dynclk_fltr = 0x0073008C},
[VMODE_1280x1024] = { .label = "1280x1024@60Hz", .width = 1280, .height = 1024, .hps = 1328, .hpe = 1440, .hmax = 1687, .hpol = 1, .vps = 1025, .vpe = 1028, .vmax = 1065, .vpol = 1, .freq = 108.0,
					.dynclk_0 = 0x00000041, .dynclk_fb = 0x000006DB, .dynclk_frac = 0x00000000, .dynclk_div = 0x00002083, .dynclk_lock = 0xCFAFA401, .dynclk_fltr = 0x00A300FF},
[VMODE_1280x720] = { .label = "1280x720@60Hz", .width = 1280, .height = 720, .hps = 1390, .hpe = 1430, .hmax = 1649, .hpol = 1, .vps = 725, .vpe = 730, .vmax = 749, .vpol = 1, .freq = 74.25,
					.dynclk_0 = 0x00000041, .dynclk_fb = 0x0000069A, .dynclk_frac = 0x00000000, .dynclk_div = 0x000020C4, .dynclk_lock = 0xCFAFA401, .dynclk_fltr = 0x00A300FF},
[VMODE_1920x1080] = { .label = "1920x1080@60Hz", .width = 1920, .height = 1080, .hps = 2008, .hpe = 2052, .hmax = 2199, .hpol = 1, .vps = 1084, .vpe = 1089, .vmax = 1124, .vpol = 1, .freq = 148.5,
					.dynclk_0 = 0x00400041, .dynclk_fb = 0x0000069A, .dynclk_frac = 0x00000000, .dynclk_div = 0x000020C4, .dynclk_lock = 0xCFAFA401, .dynclk_fltr = 0x00A300FF}
};


// System initialization. Configures the various IP in the system for video output
int SGP_systemInit(sgp_config *config) {

	// Print out the memory map if SGP_STDOUT
	if (config->driverMode & SGP_STDOUT) {
		SGP_print_systemmap();
	}

	int returnval = SGP_setVideoMode(config, VMODE_1920x1080);

	return returnval;
}

// Sets the video mode via direct control of DYCLK, VTC, and VDMA components
int SGP_setVideoMode(sgp_config *config, enum SGP_VIDEOMODES videomode) {

	uint32_t baseaddr;
	uint32_t tempval;

	// Turn off VDMA MM2S (the one we care about) and S2MM interfaces
	baseaddr = SGP_systemmap[SGP_AXI_VDMA_0].baseaddr;
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMACR, 0x00000004);
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMASR, 0x00000004);


	// The DYNCLK configuration is a little bit of a hack, we set the following
	// values and wait for things to settle
	baseaddr = SGP_systemmap[SGP_AXI_DYNCLK_0].baseaddr;

	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_0_REG, SGP_videomodes[videomode].dynclk_0);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FB_REG, SGP_videomodes[videomode].dynclk_fb);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FRAC_REG, SGP_videomodes[videomode].dynclk_frac);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_DIV_REG, SGP_videomodes[videomode].dynclk_div);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_LOCK_REG, SGP_videomodes[videomode].dynclk_lock);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FLTR_REG, SGP_videomodes[videomode].dynclk_fltr);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CTRL_REG, 0x00000001);

	// We can only wait for a return result if this is a live command stream. Consider adding a long padded
	// transaction to slow this part down. 
	if (config->driverMode & SGP_ETH) {
		while(Xil_In32(baseaddr+SGP_AXI_DYNCLK_STAT_REG)==0x00000000);
	}

	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_0_REG, SGP_videomodes[videomode].dynclk_0);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FB_REG, SGP_videomodes[videomode].dynclk_fb);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FRAC_REG, SGP_videomodes[videomode].dynclk_frac);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_DIV_REG, SGP_videomodes[videomode].dynclk_div);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_LOCK_REG, SGP_videomodes[videomode].dynclk_lock);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CLK_FLTR_REG, SGP_videomodes[videomode].dynclk_fltr);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CTRL_REG, 0x00000000);
	Xil_Out32(baseaddr+SGP_AXI_DYNCLK_CTRL_REG, 0x00000001);

	if (config->driverMode & SGP_ETH) {
		while(Xil_In32(baseaddr+SGP_AXI_DYNCLK_STAT_REG)==0x00000000);
	}


	// VTC configuration. Some parts of this are resolution-specific.
	baseaddr = SGP_systemmap[SGP_V_TC_0].baseaddr;
	Xil_Out32(baseaddr+SGP_AXI_VTC_CTL, 0x00000002);
	// XVTC_GPOL, set some seemingly arbitrary polarities
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GPOL, 0x0000007F);
	
	// XVTC_GHSIZE, set horizontal frame size for appropriate hmax
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GHSIZE, SGP_videomodes[videomode].hmax+1);

	// XVTC_GVSIZE, set vertical frame size (and vertical blanking size) to appropriate vmax
	tempval = ((SGP_videomodes[videomode].vmax+1) << 16) | (SGP_videomodes[videomode].vmax+1);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSIZE, tempval);

	// XVTC_GASIZE_F0, generated horizontal and vertical active frame size
	tempval = (SGP_videomodes[videomode].height << 16) | (SGP_videomodes[videomode].width);
	Xil_Out32(baseaddr+SGP_AXI_VTC_GASIZE_F0, tempval);

	// XVTC_GHSYNC, genereated horizontal sync start and end
	tempval = (SGP_videomodes[videomode].hpe << 16) | (SGP_videomodes[videomode].hps);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GHSYNC, tempval);

	// XVTC_GVSYNC, generated vertical sync start and end
	tempval = ((SGP_videomodes[videomode].vpe-1) << 16) | (SGP_videomodes[videomode].vps-1);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSYNC, tempval);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSYNC_F1, tempval);

	// XVTC_GENC, generator encoding register, set to YUV 4:4:4 (this seems wrong but shouldn't matter)
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GFENC, 0x00000002);
	
	// XVTC_GVBHOFF, vertical blank cycle register start and end
	tempval = ((SGP_videomodes[videomode].width) << 16) | (SGP_videomodes[videomode].width);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVBHOFF, tempval);

	// XVTC_GVSHOFF, generator field 0, vertical sync register start and end
	tempval = ((SGP_videomodes[videomode].hps) << 16) | (SGP_videomodes[videomode].hps);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSHOFF, tempval);
	
	// XVTC_GVBHOFF, generator field 1 vertical blank cycle register start and end
	tempval = ((SGP_videomodes[videomode].width) << 16) | (SGP_videomodes[videomode].width);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVBHOFF_F1, tempval);

	// XVTC_GVSHOFF_F1, generator field 1, vertical sync register start and end
	tempval = ((SGP_videomodes[videomode].hps) << 16) | (SGP_videomodes[videomode].hps);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSHOFF_F1, tempval);

	// XVTC_GVBHOFF, vertical blank cycle register start and end
	tempval = ((SGP_videomodes[videomode].width) << 16) | (SGP_videomodes[videomode].width);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVBHOFF, tempval);

	// XVTC_GVSHOFF, generator field 0, vertical sync register start and end
	tempval = ((SGP_videomodes[videomode].hps) << 16) | (SGP_videomodes[videomode].hps);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSHOFF, tempval);

	// XVTC_GVBHOFF, generator field 1 vertical blank cycle register start and end
	tempval = ((SGP_videomodes[videomode].width) << 16) | (SGP_videomodes[videomode].width);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVBHOFF_F1, tempval);

	// XVTC_GVSHOFF_F1, generator field 1, vertical sync register start and end
	tempval = ((SGP_videomodes[videomode].hps) << 16) | (SGP_videomodes[videomode].hps);
	Xil_Out32(baseaddr+SGP_AXI_XVTC_GVSHOFF_F1, tempval);

	// XVTC_CTL, "­0011_1111_0111_1110_1111_0000_0110"
	// GEN_ENABLE=0, DET_ENABLE=1 (JAZ:Should be 0?), Select Horiz and Vert info from generator register,
	Xil_In32(baseaddr+SGP_AXI_VTC_CTL);
	Xil_Out32(baseaddr+SGP_AXI_VTC_CTL, 0x03F7EF02);
	
	// XVTC_CTL, "­0011_1111_0111_1110_1111_0000_0110"
	// GEN_ENABLE=1, DET_ENABLE=1 (JAZ:Should be 0?), Select Horiz and Vert info from generator register,
	Xil_In32(baseaddr+SGP_AXI_VTC_CTL);
	Xil_Out32(baseaddr+SGP_AXI_VTC_CTL, 0x03F7EF06);


	// VDMA again
	// MM2S control register, put in circular park mode (cycle through framebuffers), on just 1 frame
	baseaddr = SGP_systemmap[SGP_AXI_VDMA_0].baseaddr;
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMACR, 0x00010002);

	// MM2S_HSIZE, assuming 4 bytes per pixel
	Xil_Out32(baseaddr+SGP_AXI_MM2S_HSIZE, SGP_videomodes[videomode].width*4);

	// MM2S_FRMDLY_STRIDE, specifying a stride of 5760 bytes to support the largest resolution
	Xil_Out32(baseaddr+SGP_AXI_MM2S_FRMDLY00_STRIDE, SGP_videomodes[VMODE_1920x1080].width*4);

	// Update buffer pointers for up to 3 buffers (can be anywhere in DRAM, but we need to allocate if using SW)
	// MM2S_START_ADDRESS per frame buffer
	Xil_Out32(baseaddr+SGP_AXI_MM2S_START_ADDRESS1, SGP_graphicsmap[SGP_COLORBUFFER_1].baseaddr);
	Xil_Out32(baseaddr+SGP_AXI_MM2S_START_ADDRESS2, SGP_graphicsmap[SGP_COLORBUFFER_2].baseaddr);
	Xil_Out32(baseaddr+SGP_AXI_MM2S_START_ADDRESS3, SGP_graphicsmap[SGP_COLORBUFFER_3].baseaddr);

	// MM2S control register, keep in circular park mode (cycle through framebuffers), on just 1 frame, and start VDMA
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMACR, 0x00010003);

	// MM2S_VSIZE, specifying the number of rows
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VSIZE, SGP_videomodes[videomode].height);

	// PARK_PTR_REG, put everything in buffer 0. 
	Xil_Out32(baseaddr+SGP_AXI_VDMA_PARK_PTR_REG, 0x00000000);

	// MM2S control register, put in park mode, on just 1 frame, and start VDMA. JAZ: Why all these VDMA starts/restarts?
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMACR, 0x00010001);

	return 0;
}

int SGP_DMArequest(sgp_config *config, uint32_t srcaddress, uint32_t destaddress, uint32_t numbytes, uint32_t SGP_dmatype) {

	uint32_t baseaddr;
	uint32_t dma_ctrl_reg;

	// We have two DMAs in the system. Use the memory DMA if both addresses are in the memory's space.
	if ((srcaddress >= SGP_systemmap[SGP_MEM_INTERFACE].baseaddr) && (srcaddress <= SGP_systemmap[SGP_MEM_INTERFACE].highaddr) && (destaddress >= SGP_systemmap[SGP_MEM_INTERFACE].baseaddr) && (destaddress <= SGP_systemmap[SGP_MEM_INTERFACE].highaddr)) {
		baseaddr = SGP_systemmap[SGP_MEMORY_DMA].baseaddr;		
	}
	else {
		baseaddr = SGP_systemmap[SGP_SYSTEM_DMA].baseaddr;
	}

	// Optional reset - set bit 2 (0x00000004 for Ctrl). It is supposed to be a graceful reset.
	Xil_Out32(baseaddr+SGP_AXI_CDMA_CR, 0x00000004);

	// Check status until idle
	if (config->driverMode & SGP_ETH) {
		while((Xil_In32(baseaddr+SGP_AXI_CDMA_SR) & 0x00000002) == 0x00000000);
	}

	// Optionally set bit 4 (for keyhole read) and/or bit 5 (for keyhole write)
	dma_ctrl_reg = SGP_dmatype;
	Xil_Out32(baseaddr+SGP_AXI_CDMA_CR, dma_ctrl_reg);

	// Set read and write address
	Xil_Out32(baseaddr+SGP_AXI_CDMA_SRCADDR, srcaddress);
	Xil_Out32(baseaddr+SGP_AXI_CDMA_DSTADDR, destaddress);

	// Set the number of bytes to transfer. This kicks off the transaction
	Xil_Out32(baseaddr+SGP_AXI_CDMA_BTT, numbytes);

	return 0;
}

// We already have to check if the DMA engine we're using is ready, but we don't check at the very end. Use
// this function to confirm that both DMAs are idle
void SGP_DMAwaitidle(sgp_config *config) {

	uint32_t baseaddr;

	baseaddr = SGP_systemmap[SGP_MEMORY_DMA].baseaddr;

	if (config->driverMode & SGP_ETH) {
		while((Xil_In32(baseaddr+SGP_AXI_CDMA_SR) & 0x00000002) == 0x00000000);
	}

	baseaddr = SGP_systemmap[SGP_SYSTEM_DMA].baseaddr;
	if (config->driverMode & SGP_ETH) {
		while((Xil_In32(baseaddr+SGP_AXI_CDMA_SR) & 0x00000002) == 0x00000000);
	}

	return;
}



// Updates the current active color buffer
void SGP_setactivebuffer(sgp_config *config, uint8_t buffer) {

	uint32_t baseaddr;

	baseaddr = SGP_systemmap[SGP_AXI_VDMA_0].baseaddr;

	// PARK_PTR_REG, put everything in buffer specified by the buffer. 
	Xil_Out32(baseaddr+SGP_AXI_VDMA_PARK_PTR_REG, (uint32_t)buffer&0x0F);

	// MM2S control register, put in park mode, on just 1 frame, and start VDMA.
	Xil_Out32(baseaddr+SGP_AXI_VDMA_MM2S_VDMACR, 0x00010001);

	return;
}

// Returns the current active color buffer
uint8_t SGP_getactivebuffer(sgp_config *config) {

	uint32_t baseaddr;
	uint32_t park_ptr_reg;
	uint8_t buffer;


	baseaddr = SGP_systemmap[SGP_AXI_VDMA_0].baseaddr;

	// PARK_PTR_REG stores the current read buffer number 
	park_ptr_reg = Xil_In32(baseaddr+SGP_AXI_VDMA_PARK_PTR_REG);

//	buffer = (park_ptr_reg & 0x000F0000) >> 16;
	buffer = (uint8_t)(park_ptr_reg & 0x0000000F);


	return buffer;
}

// Returns the current back color buffer. We are assuming two buffers here, even 
// though we have a third to use if we need it. 
uint8_t SGP_getbackbuffer(sgp_config *config) {

	uint8_t buffer = SGP_getactivebuffer(config);

	if (buffer == 1) {
		return 0;
	}
	return 1;

}


void SGP_print_systemmap() {

	int i;

	printf("\nSGP system memory map:\n");
	printf("   Name                BaseAddr       HighAddr     Description\n");
	for (i = 0; i < SGP_SYSTEM_NUMCOMPONENTS; i++) {
		printf("   %s     0x%08x     0x%08x     %s\n", SGP_systemmap[i].name, SGP_systemmap[i].baseaddr, SGP_systemmap[i].highaddr, SGP_systemmap[i].desc);
	}


	return;
}