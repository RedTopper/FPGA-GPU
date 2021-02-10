/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_axi.h - provides data types and helper functions for generating data
 * to be passed through an MM2S_Mapper AXI interface. See PG102 - AXI Memory
 * Mapped to Stream Mapper v1.1 IP documentation from Xilinx for the data
 * packing, and the AXI4 protocol specification for an explanation of each 
 * data field. 
 *
 *
 * NOTES:
 * 11/2/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>


// Our own header (not part of AXI).
// 1 bit to specify a read/write transaction (0=read, 1=write), 15 bits for total length. This
// length is counting the bytes after these first two. 
// Note: bit packing is slightly tricky in cross-platform code, see https://gcc.gnu.org/onlinedocs/gcc/x86-Variable-Attributes.html
typedef struct { uint8_t rw:1; uint16_t trans_length:15;} __attribute__((packed, scalar_storage_order("big-endian"))) SGP_header_t;

// 4-byte value to represent the AXI read/write Address. It can in theory be larger, but there
// is no point considering we are connecting to a 32-bit AXI interconnect. 
typedef union {uint32_t i; uint8_t c[4];} AxAddr_t;

// Bytes of the header. AxUSER and AxID are optional, and the MM2S_mapper core would have
// to be modified in Vivado to have these bits. Ultimately, we want to keep the total extra header
// under 4 bytes, so let's assume an AxID field of 3 and an AxUSER of <= 4 bits. 
// NOTE: the packing for these structs is tricky, with endianness considerations and AxLEN splitting two bytes.
typedef struct {AxAddr_t AxAddr;
                uint8_t AxBURST:2; uint8_t AxSIZE:3; uint8_t AxPROT:3;  // byte 0
                uint8_t AxLEN1:4; uint8_t AxCACHE:4;                    // byte 1
                uint8_t AxID:3; uint8_t AxLOCK:1; uint8_t AxLEN2:4;     // byte 2                
                uint8_t AxUSER:4; uint8_t AxQOS:4; } __attribute__((packed, scalar_storage_order("big-endian"))) AxHeader_t;

// 4-byte value to represent the AXI read/write Data. It can in theory be larger, but there
// is no point considering we are connecting to a 32-bit AXI interconnect. 
typedef union {uint32_t i; uint8_t c[4]; } AxData_t;

// Write data packet. 
typedef struct {AxData_t AWData; uint8_t WUSER:3; uint8_t WLAST:1; uint8_t WSTRB:4;} __attribute__((packed, scalar_storage_order("big-endian"))) WDATA_t;

// Write request packet
typedef struct {SGP_header_t SGP_header; AxHeader_t AWHeader; WDATA_t WDATA[256];}  __attribute__((packed, scalar_storage_order("big-endian"))) SGP_writerequest_t;

// Write response packet. There are other possible fields for this.
typedef struct {uint8_t BUSER:3; uint8_t BID:3; uint8_t BRESP:2;} __attribute__((packed, scalar_storage_order("big-endian"))) SGP_writeresponse_t;

// Read data packet. There are other possible fields for this. 
typedef struct {AxData_t ARData; uint8_t RUSER:3; uint8_t RID:2; uint8_t RLAST:1; uint8_t RRESP:2;} __attribute__((packed, scalar_storage_order("big-endian"))) RDATA_t;

// Read request packet
typedef struct {SGP_header_t SGP_header; AxHeader_t ARHeader;}  __attribute__((packed, scalar_storage_order("big-endian"))) SGP_readrequest_t;

// Read response packet. Only a fixed number of these will have valid data in them. 
typedef struct {RDATA_t RDATA[256];}  __attribute__((packed, scalar_storage_order("big-endian"))) SGP_readresponse_t; 


// Helper functions to generate packets of a certain type, length, and with reasonable defaults.
// Don't need helper function to generate response packets, they are just arrays that need
// to be filled. 
size_t SGP_AXI_gen_writerequest(uint16_t burstlength, SGP_writerequest_t *writerequest);
size_t SGP_AXI_gen_readrequest(uint16_t burstlength, SGP_readrequest_t *readrequest);

// Helper functions to display the values in a packet (both send and receive)
void SGP_AXI_print_writerequest(uint16_t burstlength, SGP_writerequest_t *writerequest);
void SGP_AXI_print_readrequest(SGP_readrequest_t *readrequest);
void SGP_AXI_print_writeresponse(SGP_writeresponse_t *writeresponse);
void SGP_AXI_print_readresponse(uint16_t burstlength, SGP_readresponse_t *readresponse);

// Helper functions to set/get the burstlength corresponding to a packet
uint16_t SGP_AXI_get_writeburstlength(SGP_writerequest_t *writerequest);
size_t SGP_AXI_set_writeburstlength(uint16_t burstlength, SGP_writerequest_t *writerequest);
uint16_t SGP_AXI_get_readburstlength(SGP_readrequest_t *readrequest);
size_t SGP_AXI_set_readburstlength(uint16_t burstlength, SGP_readrequest_t *readrequest);

// Encoding for SGP Read vs Write request
#define SGP_READ 0b0
#define SGP_WRITE 0b1

// AxPROT refers to the privilege of the access. The bitmask separately determines privileged, 
// secure, and whether this is a data or an instruction access. 
#define AxPROT_DEFAULT 0b000
#define AxPROT_PRIVILEGED 0b001
#define AxPROT_NONSECURE 0b010
#define AxPROT_INSTRUCTION 0b100

// The number of bytes in a beat of a burst is specified by 2^AxSIZE. We want 4 bytes generally.
// Doing less is fine but sending more will require restructuring the data packets
#define AxSIZE_1BYTES 0b000
#define AxSIZE_2BYTES 0b001
#define AxSIZE_4BYTES 0b010

// There are three burst types, that keep the address fixed (for FIFOs), increment the address
// (normal sequential memory), and wrapping (for cache lines)
#define AxBURST_FIXED 0b00
#define AxBURST_INCR 0b01
#define AxBURST_WRAP 0b10

// AxCACHE is most relevant for caches (obviously). The bitmask separately determines the 
// bufferable, cacheable, and allocate attributes of the transaction
#define AxCACHE_DEFAULT 0b0000
#define AxCACHE_BUFFERABLE 0b0001
#define AxCACHE_CACHEABLE 0b0010
#define AxCACHE_READALLOCATE 0b0100
#define AxCACHE_WRITEALLOCATE 0b1000


// The burst length is equal to AxLEN+1. INCR transactions can have a burst of [1-256], with 
// FIXED limited to [1-16], and WRAP limited to {2,4,8,16}. We can do powers of 2 to simplify the types. 
#define AxLEN_BURST1 0b00000000
#define AxLEN_BURST2 0b00000001
#define AxLEN_BURST4 0b00000011
#define AxLEN_BURST8 0b00000111
#define AxLEN_BURST16 0b00001111
#define AxLEN_BURST32 0b00011111
#define AxLEN_BURST64 0b00111111
#define AxLEN_BURST128 0b01111111
#define AxLEN_BURST256 0b11111111


// AXI4 doesn't implement locked transactions. In theory, with AxLOCK_EXCLUSIVE, no other
// master can access the same slave until a follow-up AxLOCK_NORMAL transaction. 
#define AxLOCK_NORMAL 0b0
#define AxLOCK_EXCLUSIVE 0b1

// We can have AXI IDs for different interconnects and devices to process separately
#define AxID_DEFAULT 0b000

// AXI4 doesn't prescribe an exact use of AxQOS (quality-of-service), other than to specify the default
#define AxQOS_DEFAULT 0b0000

// We can have different AxUSER signals for the different types of transactions. 
#define AxUSER_DEFAULT 0b0000

// Same for the other USER signals
#define WUSER_DEFAULT 0b000
#define RUSER_DEFAULT 0b000
#define BUSER_DEFAULT 0b000

// The write strobe signal specifies which of the bytes in a write are valid. 
#define WSTRB_DEFAULT 0b1111

// WLAST tells the bus this is the last transaction in a burst
#define WLAST_YES 0b1
#define WLAST_NO 0b0

// RRESP and BRESP values
#define RESP_OKAY 0b00
#define RESP_EXOKAY 0b01
#define RESP_SLVERR 0b10
#define RESP_DECERR 0b11

// Max burst length
#define AXI_MAXBURST 256