/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp.h - provides configuration data types and helper functions for the
 * interface(s) of the SGP implementation. 
 * 
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/


#pragma once


#include "sgp_axi.h"


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

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
#endif

// Data structures --------------------------------------------
// Structure to hold configuration information
typedef struct {
    char *sgp_transmit;
    char *sgp_trace;
    char *sgp_dest;
    char *sgp_name;
    uint32_t driverMode;
    FILE *traceFile;
    FILE *biosFile;

#ifdef _WIN32
    WSADATA wsaData;
    int client_addr_size;
#else
    socklen_t client_addr_size; 
#endif

    int sockfd;
    struct sockaddr_in server_addr;
    struct sockaddr_in client_addr;

    // Default read/write packets. User can also create their own and send those instead.
    SGP_writerequest_t writerequest;
    SGP_writeresponse_t writeresponse;
    SGP_readrequest_t readrequest;
    SGP_readresponse_t readresponse;


} sgp_config;


// Singleton
extern sgp_config *SGPconfig;



// Functions to initialize and close down shared resources
int SGP_configInit(sgp_config **config_in);
void SGP_configClose(sgp_config *config);

// SGP Driver Modes
#define SGP_ETH    0x00000001
#define SGP_FILE   0x00000002
#define SGP_STDOUT 0x00000004
#define SGP_DEEP   0x00000010
#define SGP_VBIOS  0x00000008


#define PROTOPORT 1234
