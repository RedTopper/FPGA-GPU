/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_transmit.c - provides interface data types and helper functions for 
 * transmitting data to the SGP design via UDP over Ethernet.
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/


#include "sgp_transmit.h"
#include <string.h>

void ClearWinSock() {
#ifdef _WIN32
	WSACleanup();
#endif
}

// Generic SGP send function for system write requests. Looks at the writerequest to determine the burstlength.
int SGP_sendWrite(sgp_config *config, SGP_writerequest_t *writerequest, SGP_writeresponse_t *writeresponse, uint8_t waitforresponse) {

	uint16_t burstlength = SGP_AXI_get_writeburstlength(writerequest);

	if (config->driverMode & SGP_FILE) {
		fwrite(&(writerequest->SGP_header), sizeof(SGP_header_t), 1, config->traceFile);
        fwrite(&(writerequest->AWHeader), sizeof(AxHeader_t), 1, config->traceFile);
        fwrite(writerequest->WDATA, sizeof(WDATA_t), burstlength, config->traceFile);
	}

	if (config->driverMode & SGP_VBIOS) {

	}

	if (config->driverMode & SGP_DEEP) {
		SGP_AXI_print_writerequest(burstlength, writerequest);
	}

	if (config->driverMode & SGP_ETH) {
	    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t)+burstlength*sizeof(WDATA_t);
    	if (sendto(config->sockfd, (char *)writerequest, packet_length, 0, (struct sockaddr *)&(config->client_addr), sizeof(config->client_addr)) != packet_length) {
			printf("%s: sendto() sent a different number of bytes than expected.\n", __FILE__);
			closesocket(config->sockfd);
			ClearWinSock();
			return 0;
		}

		if (waitforresponse & SGP_WAITFORRESPONSE) {
			int cur_recv = 0, total_recv = 0;
    		config->client_addr_size = sizeof(config->client_addr);    
			while (total_recv < sizeof(SGP_writeresponse_t)) {
				if ((cur_recv = recvfrom(config->sockfd, (char *)writeresponse, sizeof(writeresponse), 0, (struct sockaddr *)&(config->client_addr), &(config->client_addr_size))) <= 0) {
					printf("%s: recv() failed or connection closed prematurely.\n", __FILE__);
					closesocket(config->sockfd);
					ClearWinSock();
					return 0;
				}
				total_recv += cur_recv;
			}

			// We should print the response received if displaying responses
			if (config->driverMode & SGP_DEEP) {
				SGP_AXI_print_writeresponse(writeresponse);
			}	
		}


	}




	return 0;

}

// Generic SGP send function for system read requests. Looks at the readrequest to determine the burstlength. Typically you would 
// only call this with waitforresponse = SGP_WAITFORRESPONSE
int SGP_sendRead(sgp_config *config, SGP_readrequest_t *readrequest, SGP_readresponse_t *readresponse, uint8_t waitforresponse) {


	if (config->driverMode & SGP_FILE) {
		fwrite(&(readrequest->SGP_header), sizeof(SGP_header_t), 1, config->traceFile);
    	fwrite(&(readrequest->ARHeader), sizeof(AxHeader_t), 1, config->traceFile);   
	}

	if (config->driverMode & SGP_VBIOS) {

	}

	if (config->driverMode & SGP_DEEP) {
		SGP_AXI_print_readrequest(readrequest);
	}

	if (config->driverMode & SGP_ETH) {
	    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t);
    	if (sendto(config->sockfd, (char *)readrequest, packet_length, 0, (struct sockaddr *)&(config->client_addr), sizeof(config->client_addr)) != packet_length) {
			printf("%s: sendto() sent a different number of bytes than expected.\n", __FILE__);
			closesocket(config->sockfd);
			ClearWinSock();
			return 0;
		}

		if (waitforresponse & SGP_WAITFORRESPONSE) {
			int cur_recv = 0, total_recv = 0;
    		config->client_addr_size = sizeof(config->client_addr);    
			uint16_t burstlength = SGP_AXI_get_readburstlength(readrequest);
		    int readresponse_size = burstlength*sizeof(RDATA_t);

			while (total_recv < readresponse_size) {
				if ((cur_recv = recvfrom(config->sockfd, (char *)readresponse, readresponse_size, 0, (struct sockaddr *)&(config->client_addr), &(config->client_addr_size))) <= 0) {
					printf("%s: recv() failed or connection closed prematurely.\n", __FILE__);
					closesocket(config->sockfd);
					ClearWinSock();
					return 0;
				}
				total_recv += cur_recv; // Keep tally of total bytes
			}
			
			// We should print the response received if displaying responses
			if (config->driverMode & SGP_DEEP) {
				SGP_AXI_print_readresponse(burstlength, readresponse);
			}	

		}

	}

	return 0;
}


// Wrapper function that sends a write request for a single 32-bit value
int SGP_write32(sgp_config *config, uint32_t writeaddress, uint32_t writedata) {

    SGP_AXI_set_writeburstlength(1, &(config->writerequest));
    config->writerequest.WDATA[0].AWData.i = writedata;
    config->writerequest.AWHeader.AxAddr.i = writeaddress;
	SGP_sendWrite(config, &(config->writerequest), &(config->writeresponse), SGP_WAITFORRESPONSE);
  
	return 0;

}

// Wrapper function that sends a read request for a single 32-bit value
uint32_t SGP_read32(sgp_config *config, uint32_t readaddress) {
    
	
	SGP_AXI_set_readburstlength(1, &(config->readrequest));
    config->readrequest.ARHeader.AxAddr.i = readaddress;
    SGP_sendRead(config, &(config->readrequest), &(config->readresponse), SGP_WAITFORRESPONSE);

	return config->readresponse.RDATA[0].ARData.i;

}
