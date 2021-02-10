/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp.c - provides configuration data types and helper functions for the
 * interface(s) of the SGP implementation. 
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/


#include "sgp.h"
#include "sgp_transmit.h"

sgp_config *SGPconfig;

// Allocate and initialize the main SGP configuration data structure
int SGP_configInit(sgp_config **config_in) {

	sgp_config *config;

	*config_in = (sgp_config *)malloc(1*sizeof(sgp_config));
	config = *config_in;

	// To-do: consider whether .ini is a better config approach than env-vars
	config->sgp_transmit = getenv("SGP_TRANSMIT");
	config->sgp_trace = getenv("SGP_TRACE");
	config->sgp_dest = getenv("SGP_DEST");
	config->sgp_name = getenv("SGP_NAME");

	config->driverMode = 0;
	config->traceFile = NULL;
	config->biosFile = NULL;

	if (config->sgp_trace == NULL) {
		printf("%s: SGP_TRANSMIT is not specified.\n", __FILE__);
		return -1;
	}

	// If SGP_TRACE is set to FILE, open up a binary trace file
	if (strcmp(config->sgp_trace, "FILE") == 0) {
		if (config->sgp_name == NULL) {
			config->traceFile = fopen("trace.sgb", "wb");
		}
		else {
			config->traceFile = fopen(config->sgp_name, "wb");
		}
        config->driverMode |= SGP_FILE;
    }

    // If SGP_TRACE is set to VBIOS, open up a hex trace file
    if (strcmp(config->sgp_trace, "VBIOS") == 0) {
    	if (config->sgp_name == NULL) {
			config->biosFile = fopen("trace.dat", "w");
        }
        else {
        	config->biosFile = fopen(config->sgp_name, "w");
        }
        fprintf(config->biosFile, "memory_initialization_radix=16;\nmemory_initialization_vector=\n");
        config->driverMode |= SGP_VBIOS;
    }

    // If SGP_TRACE is set to STDOUT, take note of that
    if (strcmp(config->sgp_trace, "STDOUT") == 0) {
        config->driverMode |= SGP_STDOUT;
    }

    // If SGP_TRACE is set to DEEP, take note of that
    if (strcmp(config->sgp_trace, "DEEP") == 0) {
        config->driverMode |= SGP_STDOUT;
        config->driverMode |= SGP_DEEP;
    }


    // If SGP_TRANSMIT is set to ETH, open up an ethernet port
    if (strcmp(config->sgp_transmit, "ETH") == 0) {

		#ifdef _WIN32
	    // Initialize Winsock version 2.2
    	if (WSAStartup(MAKEWORD(2,2), &(config->wsaData)) != 0) {
        	printf("%s: WSAStartup failed\n", __FILE__);
        	WSACleanup();
        	return -1;
	    }
		#endif

    	// Socket creation
	    config->sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
		if (config->sockfd < 0) {
			printf("%s: socket creation failed.\n", __FILE__);
			closesocket(config->sockfd);
			ClearWinSock();
			return -1;
		}

    	// Socket information of receiver destination
		memset(&(config->client_addr), 0, sizeof(config->client_addr));
    	config->client_addr.sin_family = AF_INET;
    	config->client_addr.sin_port = htons(PROTOPORT);
		if (config->sgp_dest == NULL) {
			config->client_addr.sin_addr.s_addr = inet_addr("192.168.1.128");
		}
		else {
			config->client_addr.sin_addr.s_addr = inet_addr(config->sgp_dest);
		}

    	// Socket information of sender source
		memset(&(config->server_addr), 0, sizeof(config->server_addr));
    	config->server_addr.sin_family = AF_INET;
    	config->server_addr.sin_port = htons(PROTOPORT);
    	config->server_addr.sin_addr.s_addr = INADDR_ANY;

    	// Bind port to this program and let OS know to route packets to me
    	if(bind(config->sockfd,(struct sockaddr *)&(config->server_addr),
                        sizeof(struct sockaddr))== -1) {
			printf("%s: socket bind failed.\n", __FILE__);
			closesocket(config->sockfd);
			ClearWinSock();
        	return 0;
		}

        config->driverMode |= SGP_ETH;
    }

	// Create a read and a write packet of maximum size, there is no harm in allocating the max amount
    SGP_AXI_gen_writerequest(AXI_MAXBURST, &config->writerequest);
    SGP_AXI_gen_readrequest(AXI_MAXBURST, &config->readrequest);

	return 0;
}

// Close up shop
void SGP_configClose(sgp_config *config) {

	if (config->driverMode & SGP_ETH) {
		closesocket(config->sockfd);
		ClearWinSock();
    }

    if (config->driverMode & SGP_FILE) {
		fclose(config->traceFile);
    }

    if (config->driverMode & SGP_VBIOS) {
		fprintf(config->biosFile, "00000002;");
		fclose(config->biosFile);
    }

}
