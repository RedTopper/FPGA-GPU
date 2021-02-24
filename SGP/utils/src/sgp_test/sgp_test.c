/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_test.c - provides examples of how to interface with the SGP driver
 * utilities for creating packets. 
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"
#include "sgp_axi.h"
#include "sgp.h"

sgp_config *SGPconfig;

void SGP_udptest() {

    int returnValue;
    
    // Initialize the SGP configuration
    returnValue = SGP_configInit(&SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }

    // Initialize the SGP system IP
    returnValue = SGP_systemInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }

    // Initialize the SGP graphics IP and memory map
    returnValue = SGP_graphicsInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }



    SGP_AXI_set_writeburstlength(256, &(SGPconfig->writerequest));
    for (int i = 0; i < 256; i++) {
        SGPconfig->writerequest.WDATA[i].AWData.i = 0x00808000;
    }

    uint32_t baseaddr = 0x80000000;
    for (int row = 0; row < 1080; row++) {

        // This has a rounding bug in it. 
        for (int col = 0; col < 1920/256; col++) {
            SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr+256*4*col+1920*4*row;
            SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
        }
    }


    SGP_AXI_set_readburstlength(4, &(SGPconfig->readrequest));
    SGPconfig->readrequest.ARHeader.AxAddr.i = 0x80000000;
    SGP_sendRead(SGPconfig, &(SGPconfig->readrequest), &(SGPconfig->readresponse), SGP_WAITFORRESPONSE);

    printf("Value at 0x80000000 is %08x\n", SGP_read32(SGPconfig, 0x80000000));


    SGP_configClose(SGPconfig);

    return;
}
  

void SGP_systemtest() {

    int returnValue;
    
    // Initialize the SGP configuration
    returnValue = SGP_configInit(&SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }


    // Initialize the SGP graphics components
    returnValue = SGP_graphicsInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }


    // Initialize the rest of the SGP system components
    returnValue = SGP_systemInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
    }



    // Example CDMA code.  
//    SGP_DMArequest(SGPconfig, SGP_systemmap[SGP_MEM_INTERFACE].baseaddr+COLORBUFFER_2, SGP_systemmap[SGP_MEM_INTERFACE].baseaddr+COLORBUFFER_1, 1920*1080*4, SGP_DMA_REGULAR);
    SGP_DMArequest(SGPconfig, SGP_graphicsmap[SGP_COLORBUFFER_2].baseaddr, SGP_graphicsmap[SGP_COLORBUFFER_1].baseaddr, 1920*1080*4, SGP_DMA_REGULAR);



/*    uint32_t pixel_addr = SGP_systemmap[SGP_MEM_INTERFACE].baseaddr+0x10000000;
    Xil_Out32(pixel_addr, 0xFFFFFFFF);
    printf("Value at addr 0x%08x is 0x%08x\n", pixel_addr, Xil_In32(pixel_addr));
    sleep(2);
    SGP_DMArequest(SGPconfig, pixel_addr, SGP_systemmap[SGP_MEM_INTERFACE].baseaddr+COLORBUFFER_1, 1920*1080*4, SGP_DMA_KEYHOLEREAD);
*/

    // Example buffer changing code
    /*while (1) {
        sleep(3);
        SGP_setactivebuffer(SGPconfig, 1);
        sleep(3);
        SGP_setactivebuffer(SGPconfig, 2);
        sleep(3);
        SGP_setactivebuffer(SGPconfig, 0);
    }*/

    // Example resolution changing code
    /*while (1) {
        sleep(25);
        SGP_setVideoMode(SGPconfig, VMODE_640x480);
        sleep(25);
        SGP_setVideoMode(SGPconfig, VMODE_800x600);
        sleep(25);
        SGP_setVideoMode(SGPconfig, VMODE_1280x1024);
        sleep(25);
        SGP_setVideoMode(SGPconfig, VMODE_1280x720);
        sleep(25);
        SGP_setVideoMode(SGPconfig, VMODE_1920x1080);
        sleep(25);

    }*/
}

int main() {


//    SGP_udptest();
   SGP_systemtest();
    return 0;
}

