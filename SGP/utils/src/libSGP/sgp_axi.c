/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_axi.c - provides data types and helper functions for generating data
 * to be passed through an MM2S_Mapper AXI interface. See PG102 - AXI Memory
 * Mapped to Stream Mapper v1.1 IP documentation from Xilinx for the data
 * packing, and the AXI4 protocol specification for an explanation of each 
 * data field. 
 *
 *
 * NOTES:
 * 11/2/20 by JAZ::Design created.
 *****************************************************************************/

#include "sgp_axi.h"
#include <stdio.h>

// Helper function to generate write packets of a certain type, length, and with reasonable defaults.
size_t SGP_AXI_gen_writerequest(uint16_t burstlength, SGP_writerequest_t *writerequest) {

    uint16_t i;

    // We can consider more detailed checks here. 
    if ((burstlength < 1) || (burstlength > AXI_MAXBURST)) {
        return 0;
    }

    // 2 bytes for the SGP_header, 4 for the AWHeader, and 5 bytes of WDATA per burst
    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t)+burstlength*sizeof(WDATA_t);

    // Initialize the header. We don't count the SGP_header bytes
    writerequest->SGP_header.rw = SGP_WRITE;
    writerequest->SGP_header.trans_length = (uint16_t)(packet_length-sizeof(SGP_header_t));

    // Initialize the AwHeader
    writerequest->AWHeader.AxPROT = AxPROT_DEFAULT;
    writerequest->AWHeader.AxSIZE = AxSIZE_4BYTES;
    writerequest->AWHeader.AxBURST = AxBURST_INCR;
    writerequest->AWHeader.AxCACHE = AxCACHE_DEFAULT;
    writerequest->AWHeader.AxLEN1 = (burstlength-1)&0x0F;
    writerequest->AWHeader.AxLEN2 = ((burstlength-1)&0xF0) >> 4;
    writerequest->AWHeader.AxLOCK = AxLOCK_NORMAL;
    writerequest->AWHeader.AxID = AxID_DEFAULT;
    writerequest->AWHeader.AxQOS = AxQOS_DEFAULT;
    writerequest->AWHeader.AxUSER = AxUSER_DEFAULT;

    // Initialize the WDATAs. Set WLAST for the final beat in the burst
    for (i = 0; i < burstlength; i++) {
        writerequest->WDATA[i].WUSER = WUSER_DEFAULT;
        writerequest->WDATA[i].WSTRB = WSTRB_DEFAULT;
        writerequest->WDATA[i].WLAST = WLAST_NO;
    }
    writerequest->WDATA[burstlength-1].WLAST = WLAST_YES;

    return packet_length;
}


// Helper function to generate read packets of a certain type, length, and with reasonable defaults.
size_t SGP_AXI_gen_readrequest(uint16_t burstlength, SGP_readrequest_t *readrequest) {

    // We can consider more detailed checks here. 
    if ((burstlength < 1) || (burstlength > AXI_MAXBURST)) {
        return 0;
    }

    // 2 bytes for the SGP_header, 4 for the ARHeader
    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t);

    // Initialize the header. We don't count the SGP_header bytes
    readrequest->SGP_header.rw = SGP_READ;
    readrequest->SGP_header.trans_length = (uint16_t)(packet_length-sizeof(SGP_header_t));

    // Initialize the ARHeader
    readrequest->ARHeader.AxPROT = AxPROT_DEFAULT;
    readrequest->ARHeader.AxSIZE = AxSIZE_4BYTES;
    readrequest->ARHeader.AxBURST = AxBURST_INCR;
    readrequest->ARHeader.AxCACHE = AxCACHE_DEFAULT;
    readrequest->ARHeader.AxLEN1 = (burstlength-1)&0x0F;
    readrequest->ARHeader.AxLEN2 = ((burstlength-1)&0xF0) >> 4;
    readrequest->ARHeader.AxLOCK = AxLOCK_NORMAL;
    readrequest->ARHeader.AxID = AxID_DEFAULT;
    readrequest->ARHeader.AxQOS = AxQOS_DEFAULT;
    readrequest->ARHeader.AxUSER = AxUSER_DEFAULT;


    return packet_length;
}


// Helper function to print out the data in an AXI write request
void SGP_AXI_print_writerequest(uint16_t burstlength, SGP_writerequest_t *writerequest) {

    uint16_t i;

    printf("\nSGP_writerequest:\n");
    printf("      SGP_header:            rw: 0x%01x\n", writerequest->SGP_header.rw);
    printf("                   trans_length: 0x%02x\n", writerequest->SGP_header.trans_length);
    printf("      AWHeader:          AxAddr: 0x%08x\n", writerequest->AWHeader.AxAddr.i);
    printf("                         AxPROT: 0x%01x\n", writerequest->AWHeader.AxPROT);
    printf("                         AxSIZE: 0x%01x\n", writerequest->AWHeader.AxSIZE);
    printf("                        AxBURST: 0x%01x\n", writerequest->AWHeader.AxBURST);
    printf("                        AxCACHE: 0x%01x\n", writerequest->AWHeader.AxCACHE);
    printf("                          AxLEN: 0x%01x%01x\n", writerequest->AWHeader.AxLEN2, writerequest->AWHeader.AxLEN1);
    printf("                         AxLOCK: 0x%01x\n", writerequest->AWHeader.AxLOCK);
    printf("                           AxID: 0x%01x\n", writerequest->AWHeader.AxID);
    printf("                          AxQOS: 0x%01x\n", writerequest->AWHeader.AxQOS);
    printf("                         AxUSER: 0x%01x\n", writerequest->AWHeader.AxUSER);

    for (i = 0; i < burstlength; i++) {
        printf("      WDATA[%03d]: AWData: 0x%08x, WSTRB: 0x%01x, WLAST: 0x%01x, WUSER: 0x%01x\n", i, writerequest->WDATA[i].AWData.i, 
                                        writerequest->WDATA[i].WSTRB, writerequest->WDATA[i].WLAST, writerequest->WDATA[i].WUSER);
    }

    return;
}

// Helper function to print out the data in an AXI read request
void SGP_AXI_print_readrequest(SGP_readrequest_t *readrequest) {

    printf("\nSGP_readrequest:\n");
    printf("     SGP_header:            rw: 0x%01x\n", readrequest->SGP_header.rw);
    printf("                  trans_length: 0x%02x\n", readrequest->SGP_header.trans_length);
    printf("       ARHeader:        AxAddr: 0x%08x\n", readrequest->ARHeader.AxAddr.i);
    printf("                        AxPROT: 0x%01x\n", readrequest->ARHeader.AxPROT);
    printf("                        AxSIZE: 0x%01x\n", readrequest->ARHeader.AxSIZE);
    printf("                       AxBURST: 0x%01x\n", readrequest->ARHeader.AxBURST);
    printf("                       AxCACHE: 0x%01x\n", readrequest->ARHeader.AxCACHE);
    printf("                         AxLEN: 0x%01x%01x\n", readrequest->ARHeader.AxLEN2, readrequest->ARHeader.AxLEN1);
    printf("                        AxLOCK: 0x%01x\n", readrequest->ARHeader.AxLOCK);
    printf("                          AxID: 0x%01x\n", readrequest->ARHeader.AxID);
    printf("                         AxQOS: 0x%01x\n", readrequest->ARHeader.AxQOS);
    printf("                        AxUSER: 0x%01x\n", readrequest->ARHeader.AxUSER);

    return;


}

// Helper function to print out the data in an AXI write response
void SGP_AXI_print_writeresponse(SGP_writeresponse_t *writeresponse) {

    printf("\nSGP_writeresponse:\n");
    printf("            BRESP: 0x%01x ", writeresponse->BRESP);
    if (writeresponse->BRESP == RESP_OKAY) {
        printf("(BRESP_OKAY)\n");
    }
    else if (writeresponse->BRESP == RESP_EXOKAY) {
        printf("(BRESP_EXOKAY)\n");
    } 
    else if (writeresponse->BRESP == RESP_SLVERR) {
        printf("(BRESP_SLV_ERR)\n");
    } 
    else if (writeresponse->BRESP == RESP_DECERR) {
        printf("(BRESP_DECERR)\n");
    }
    else {
        printf("\n");
    }
    printf("              BID: 0x%01x\n", writeresponse->BID);
    printf("            BUSER: 0x%01x\n", writeresponse->BUSER);

    return;

}


// Helper function to print out the data in an AXI read response
void SGP_AXI_print_readresponse(uint16_t burstlength, SGP_readresponse_t *readresponse) {

    uint16_t i;

    printf("\nSGP_readresponse:\n");
    for (i = 0; i < burstlength; i++) {
        printf("     RDATA[%03d]:  ARData: 0x%08x, ", i, readresponse->RDATA[i].ARData.i);
        printf("RRESP: 0x%01x ", readresponse->RDATA[i].RRESP);
        if (readresponse->RDATA[i].RRESP == RESP_OKAY) {
            printf("(RRESP_OKAY), ");
        }
        else if (readresponse->RDATA[i].RRESP == RESP_EXOKAY) {
            printf("(RRESP_EXOKAY), ");
        } 
        else if (readresponse->RDATA[i].RRESP == RESP_SLVERR) {
            printf("(RRESP_SLV_ERR), ");
        } 
        else if (readresponse->RDATA[i].RRESP == RESP_DECERR) {
            printf("(RRESP_DECERR), ");
        }
        else {
            printf("(), ");
        }
        printf("RLAST: 0x%01x, RID: 0x%01x, RUSER: 0x%01x\n", readresponse->RDATA[i].RLAST, readresponse->RDATA[i].RID, readresponse->RDATA[i].RUSER);
    }

}

// Helper function that returns the burstlength value for an AXI writerequest. 
uint16_t SGP_AXI_get_writeburstlength(SGP_writerequest_t *writerequest) {
	uint16_t burstlength = (writerequest->AWHeader.AxLEN2 << 4) | (writerequest->AWHeader.AxLEN1);

    // We generally want the value that the AxLEN field represents, which is the burstlength-1
    burstlength++;

    return burstlength;
}

// Helper function that sets the burstlength value for an AXI writerequest. 
size_t SGP_AXI_set_writeburstlength(uint16_t burstlength, SGP_writerequest_t *writerequest) {

    static uint16_t last_burstlength = 1;

    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t)+burstlength*sizeof(WDATA_t);

    // We can consider more detailed checks here. 
    if ((burstlength < 1) || (burstlength > AXI_MAXBURST)) {
        return 0;
    }

    // Set the total transaction length appropriately
    writerequest->SGP_header.trans_length = (uint16_t)(packet_length-sizeof(SGP_header_t));

    // Set the AXI transaction length fields
    writerequest->AWHeader.AxLEN1 = (burstlength-1)&0x0F;
    writerequest->AWHeader.AxLEN2 = ((burstlength-1)&0xF0) >> 4;

    // We update the WLAST fields based on what was previously the burst length and what the 
    // length is now
    writerequest->WDATA[last_burstlength-1].WLAST = WLAST_NO;
    writerequest->WDATA[burstlength-1].WLAST = WLAST_YES;
    last_burstlength = burstlength;

    return packet_length;
}

// Helper function that returns the burstlength value for an AXI readrequest. 
uint16_t SGP_AXI_get_readburstlength(SGP_readrequest_t *readrequest) {
	uint16_t burstlength = (readrequest->ARHeader.AxLEN2 << 4) | (readrequest->ARHeader.AxLEN1);

    // We generally want the value that the AxLEN field represents, which is the burstlength-1
    burstlength++;

    return burstlength;
}

// Helper function that sets the burstlength value for an AXI readrequest. 
size_t SGP_AXI_set_readburstlength(uint16_t burstlength, SGP_readrequest_t *readrequest) {

    size_t packet_length = sizeof(SGP_header_t)+sizeof(AxHeader_t);

    // We can consider more detailed checks here. 
    if ((burstlength < 1) || (burstlength > AXI_MAXBURST)) {
        return 0;
    }

    readrequest->ARHeader.AxLEN1 = (burstlength-1)&0x0F;
    readrequest->ARHeader.AxLEN2 = ((burstlength-1)&0xF0) >> 4;

    return packet_length;
}