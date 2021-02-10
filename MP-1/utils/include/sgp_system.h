/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_system.h - provides definitions for all the memory-mapped peripherals
 * in the SGP implementation, as well as some helper functions to access them
 * Add to this file to define any new address spaces or peripherals. 
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once

#include "sgp.h"
#include "sgp_transmit.h"

#include <stdint.h>

// System memory map data structure. 
typedef struct {
    uint32_t baseaddr;
    uint32_t highaddr;
    char name[32];
    char desc[64];
} SGP_systemmap_t;

// Enum representing components in the system memory map. These need to be manually updated from Vivado if 
// the system changes.
enum SGP_SYSTEM_COMPONENTS {SGP_AXI_UARTLITE_0=0, SGP_MEMORY_DMA, SGP_SYSTEM_DMA, SGP_AXI_DYNCLK_0, SGP_AXI_VDMA_0, 
                            SGP_V_TC_0, SGP_MEM_INTERFACE, SGP_SYSTEM_NUMCOMPONENTS};

extern SGP_systemmap_t SGP_systemmap[SGP_SYSTEM_NUMCOMPONENTS];

// Data structure representing various HDMI video modes
typedef struct {
	char label[16];     // Label describing the resolution 
	uint32_t width;     // Width of the active video frame
	uint32_t height;    // Height of the active video frame
	uint32_t hps;       // Start time of Horizontal sync pulse, in pixel clocks (active width + H. front porch)
	uint32_t hpe;       // End time of Horizontal sync pulse, in pixel clocks (active width + H. front porch + H. sync width)
	uint32_t hmax;      // Total number of pixel clocks per line (active width + H. front porch + H. sync width + H. back porch)
	uint32_t hpol;      // hsync pulse polarity
	uint32_t vps;       // Start time of Vertical sync pulse, in lines (active height + V. front porch)
	uint32_t vpe;       // End time of Vertical sync pulse, in lines (active height + V. front porch + V. sync width)
	uint32_t vmax;      // Total number of lines per frame (active height + V. front porch + V. sync width + V. back porch)
	uint32_t vpol;      // vsync pulse polarity
	double freq;        // Pixel Clock frequency
    uint32_t dynclk_0;  // Hard-coded values for the dynamic clock generator IP core
    uint32_t dynclk_fb;
    uint32_t dynclk_frac;
    uint32_t dynclk_div;
    uint32_t dynclk_lock;
    uint32_t dynclk_fltr;
} SGP_videomode_t;

enum SGP_VIDEOMODES {VMODE_640x480=0, VMODE_800x600, VMODE_1280x1024, VMODE_1280x720, VMODE_1920x1080, SGP_NUMVIDEOMODES};

extern SGP_videomode_t SGP_videomodes[SGP_NUMVIDEOMODES];

#define SGP_DMA_REGULAR 0x00000000
#define SGP_DMA_KEYHOLEREAD 0x00000010
#define SGP_DMA_KEYHOLEWRITE 0x00000020

#define SGP_SYSTEM_WAITIDLE 0x000000001


int SGP_systemInit(sgp_config *config);
int SGP_setVideoMode(sgp_config *config, enum SGP_VIDEOMODES videomode);
void SGP_print_systemmap();
int SGP_DMArequest(sgp_config *config, uint32_t srcaddress, uint32_t destaddress, uint32_t numbytes, uint32_t SGP_dmatype);
void SGP_DMAwaitidle(sgp_config *config);
void SGP_setactivebuffer(sgp_config *config, uint8_t buffer);
uint8_t SGP_getactivebuffer(sgp_config *config);
uint8_t SGP_getbackbuffer(sgp_config *config);



// Register offsets for IP that have documented offsets. This may change from Vivado 
// version to version, so don't upgrade the project's Vivado version without checking these first. 
// VDMA registers
#define SGP_AXI_VDMA_MM2S_VDMACR      0x00 // MM2S_VDMACR 			MM2S VDMA Control Register 
#define SGP_AXI_VDMA_MM2S_VDMASR      0x04 // MM2S_VDMASR 			MM2S VDMA Status Register
#define SGP_AXI_VDMA_MM2S_REG_INDEX   0x14 // MM2S_REG_INDEX 		MM2S Register Index
#define SGP_AXI_VDMA_PARK_PTR_REG     0x28 // PARK_PTR_REG 		    MM2S and S2MM Park Pointer Register
#define SGP_AXI_VDMA_VERSION          0x2c // VDMA_VERSION 		    Video DMA Version Register
#define SGP_AXI_VDMA_S2MM_VDMACR 	  0x30 // S2MM_VDMACR           S2MM VDMA Control Register
#define SGP_AXI_VDMA_S2MM_VDMASR      0x34 // S2MM_VDMASR 			S2MM VDMA Status Register
#define SGP_AXI_VDMA_MM2S_VSIZE       0x50 // MM2S_VSIZE 			MM2S Vertical Size Register
#define SGP_AXI_MM2S_HSIZE            0x54 // MM2S_HSIZE 			MM2S Horizontal Size Register
#define SGP_AXI_MM2S_FRMDLY00_STRIDE  0x58 // MM2S_FRMDLY00_STRIDE 	MM2S Frame Delay and Stride Register
#define SGP_AXI_MM2S_START_ADDRESS1   0x5C // MM2S_START_ADDRESS    MM2S Start Address, framebuffer 1  
#define SGP_AXI_MM2S_START_ADDRESS2   0x60 // MM2S_START_ADDRESS    MM2S Start Address, framebuffer 2
#define SGP_AXI_MM2S_START_ADDRESS3   0x64 // MM2S_START_ADDRESS    MM2S Start Address, framebuffer 3

// axi_dynclk_0 registers. This core has 0 documentation, but the source is available
#define SGP_AXI_DYNCLK_CTRL_REG       0x00 // CTRL_REG     <= slv_reg0;
#define SGP_AXI_DYNCLK_STAT_REG       0x04 // slv_reg1     <= STAT_REG; (read-only)
#define SGP_AXI_DYNCLK_CLK_0_REG      0x08 // CLK_O_REG    <= slv_reg2;
#define SGP_AXI_DYNCLK_CLK_FB_REG     0x0C // CLK_FB_REG   <= slv_reg3;
#define SGP_AXI_DYNCLK_CLK_FRAC_REG   0x10 // CLK_FRAC_REG <= slv_reg4;
#define SGP_AXI_DYNCLK_CLK_DIV_REG    0x14 // CLK_DIV_REG  <= slv_reg5;
#define SGP_AXI_DYNCLK_CLK_LOCK_REG   0x18 // CLK_LOCK_REG <= slv_reg6;
#define SGP_AXI_DYNCLK_CLK_FLTR_REG   0x1C // CLK_FLTR_REG <= slv_reg7;    

// v_tc_0 registers
#define SGP_AXI_VTC_CTL          0x0000 // 0x0000 (XVTC_CTL) R/W Yes 0 General Control
#define SGP_AXI_VTC_GASIZE_F0    0x0060 // 0x0060 ACTIVE_SIZE (XVTC_GASIZE_F0) R/W Yes Specified via GUI Horizontal and Vertical Frame Size (without blanking) for field 0.
#define SGP_AXI_XVTC_GPOL        0x006C // POLARITY (XVTC_GPOL) R/W Yes Specified via GUI Blank, Sync polarities
#define SGP_AXI_XVTC_GFENC       0x0068 // ENCODING (XVTC_GFENC) R/W Yes Specified via GUI Frame encoding
#define SGP_AXI_XVTC_GHSIZE      0x0070 // HSIZE (XVTC_GHSIZE) R/W Yes Specified via GUI Horizontal Frame Size (with blanking)
#define SGP_AXI_XVTC_GVSIZE      0x0074 // VSIZE (XVTC_GVSIZE) R/W Yes Specified via GUI Vertical Frame Size (with blanking)
#define SGP_AXI_XVTC_GHSYNC      0x0078 // HSYNC (XVTC_GHSYNC) R/W Yes Specified via GUI Start and end cycle index of HSync
#define SGP_AXI_XVTC_GVBHOFF     0x007C // F0_VBLANK_H (XVTC_GVBHOFF) R/W Yes Specified via GUI Start and end cycle index of VBlank for field 0.
#define SGP_AXI_XVTC_GVSYNC      0x0080 // F0_VSYNC_V (XVTC_GVSYNC) R/W Yes Specified via GUI Start and end line index of VSync for field 0.
#define SGP_AXI_XVTC_GVSHOFF     0x0084 // F0_VSYNC_H (XVTC_GVSHOFF) R/W Yes Specified via GUI Start and end cycle index of VSync for field 0.
#define SGP_AXI_XVTC_GVBHOFF_F1  0x0088 // F1_VBLANK_H (XVTC_GVBHOFF_F1) R/W Yes Specified via GUI Start and end cycle index of VBlank for field 1.
#define SGP_AXI_XVTC_GVSYNC_F1   0x008C // F1_VSYNC_V (XVTC_GVSYNC_F1) R/W Yes Specified via GUI Start and end line index of VSync for field 1.
#define SGP_AXI_XVTC_GVSHOFF_F1  0x0090 // F1_VSYNC_H (XVTC_GVSHOFF_F1) R/W Yes Specified via GUI Start and end cycle index of VSync for field 1.
#define SGP_AXI_XVTC_GASIZE_F1   0x0094 // ACTIVE_SIZE (XVTC_GASIZE_F1) R/W Yes Specified via GUI Horizontal and Vertical Frame size for field 1.

// axi_cdma registers
#define SGP_AXI_CDMA_CR          0x0000 // 0x0000 - CDMA Ctrl 
#define SGP_AXI_CDMA_SR          0x0004 // 0x0004 - CDMA Status
#define SGP_AXI_CDMA_SRCADDR     0x0018 // 0x0018 - Source Address
#define SGP_AXI_CDMA_DSTADDR     0x0020 // 0x0020 - Destination Address
#define SGP_AXI_CDMA_BTT         0x0028 // 0x0028 - Bytes to Transfer
