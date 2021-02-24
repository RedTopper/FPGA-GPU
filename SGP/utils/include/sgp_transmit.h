/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_transmit.h - provides interface data types and helper functions for 
 * transmitting data to the SGP design via UDP over Ethernet.
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/


#pragma once

#include "sgp.h"
#include "sgp_axi.h"

#ifdef _WIN32
#include <WinSock2.h>
#else
#include <termios.h>
#include <fcntl.h>
#include <sys/types.h> 
#include <netinet/in.h> 
#include <netdb.h> 
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

#define closesocket close

#endif

#define SGP_WAITFORRESPONSE 0x01


int SGP_sendWrite(sgp_config *config, SGP_writerequest_t *writerequest, SGP_writeresponse_t *writeresponse, uint8_t waitforresponse);
int SGP_sendRead(sgp_config *config, SGP_readrequest_t *readrequest, SGP_readresponse_t *readresponse, uint8_t waitforresponse);
int SGP_write32(sgp_config *config, uint32_t writeaddress, uint32_t writedata);
uint32_t SGP_read32(sgp_config *config, uint32_t readaddress);

// Cleaner functions for code that is ported to/from Xilinx SDK
#define Xil_Out32(X, Y) SGP_write32(config, X, Y)
#define Xil_In32(X) SGP_read32(config, X)

void ClearWinSock();

