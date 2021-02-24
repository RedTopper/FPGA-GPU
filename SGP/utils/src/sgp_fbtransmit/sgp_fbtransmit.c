/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_fbtransmit.c - copies .bmp files to/from SGP memory. Useful for system
 * video out testing without having a monitor.
 *
 *
 * NOTES:
 * 11/10/20 by JAZ::Design created.
 *****************************************************************************/

#include <stdio.h>

#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"
#include "sgp_axi.h"
#include "sgp.h"
#include "sgp_fbtransmit.h"

int main(int argc, char **argv) {

  bmp_file_info bmp;
  sglu_config_type *config;

  unsigned int **pixels;


  /* Initialize the SGLU configuration datatype using default values */
  config = sglu_init_config();
  config->width = WIDTH_DEFAULT;
  config->height = HEIGHT_DEFAULT;
  config->depth = DEPTH_DEFAULT;
  
  /* Parse the command line and modify configuration info if necessary */
  read_command_line(config, argc, argv);

  /* Check to see that the values are valid */
  check_config(config);
  
  /* If the debug level > 0 then print out the configuration information */
  if (config->debug_level > 0) {
    print_config(config);
  }

  // Setup access to the SGP driver infrastructure
  sgp_config *SGPconfig;
  int returnValue;
    
  // Initialize the SGP configuration
  returnValue = SGP_configInit(&SGPconfig);
  if (returnValue != 0) {
    raise_error(config, ERR_DRIVER);
  }

  // Initialize the SGP graphics components
  //returnValue = SGP_graphicsInit(SGPconfig);

  if (returnValue != 0) {
    printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
  }

  // Default operation is framebuffer --> bmp, unless we specify we want a read
  if (config->read == 1) {

    sglu_init_bmp(config, &bmp);
    pixels = sglu_bmp_to_array(config, &bmp);
    if (config->debug_level > 0) {
      sglu_bmp_info(&bmp);
    }

    // Grab the current framebuffer via the VDMA parkptr and read that frame. Note that we don't want to change the state of the system,
    // so instead of calling SGP_graphicsInit() we will manually set the buffer address. 
    uint8_t cur_buffer = SGP_getactivebuffer(SGPconfig);
    uint32_t baseaddr = SGP_graphicsmap[SGP_COLORBUFFER_1+cur_buffer].baseaddr + SGP_systemmap[SGP_MEM_INTERFACE].baseaddr;
    for (int row = 0; row < config->height; row++) {

      uint16_t burstlength = 256;
      SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
      uint8_t numbursts = config->width/burstlength;
      for (int col = 0; col < numbursts; col++) {
        SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr+burstlength*4*col+1920*4*row;
        // Copy the pixel object into the write request
        for (int i = 0; i < burstlength; i++) {
          SGPconfig->writerequest.WDATA[i].AWData.i = pixels[row][burstlength*col+i];
        }
        SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
      }

      // Check if we have leftover bytes to request
      if (config->width % burstlength != 0) {
        SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr+burstlength*4*(numbursts)+1920*4*row;
        burstlength = config->width % burstlength;
        SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
        // Copy the pixel object into the write request
        for (int i = 0; i < burstlength; i++) {
          SGPconfig->writerequest.WDATA[i].AWData.i = pixels[row][256*(config->width/256)+i];
        }
        SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
      }

    }
  }
  else {

    // Grab the pixels from the framebuffer and store in a bmp file
    sglu_init_bmp(config, &bmp);
    pixels = sglu_allocate_pixel_array(config->width, config->height);

    // Grab the current framebuffer via the VDMA parkptr and read that frame. Note that we don't want to change the state of the system,
    // so instead of calling SGP_graphicsInit() we will manually set the buffer address.
    uint8_t cur_buffer = SGP_getactivebuffer(SGPconfig);
    uint32_t baseaddr = SGP_graphicsmap[SGP_COLORBUFFER_1+cur_buffer].baseaddr + SGP_systemmap[SGP_MEM_INTERFACE].baseaddr;
    for (int row = 0; row < config->height; row++) {

      uint16_t burstlength = 256;
      SGP_AXI_set_readburstlength(burstlength, &(SGPconfig->readrequest));
      uint8_t numbursts = config->width/burstlength;
      for (int col = 0; col < numbursts; col++) {
        SGPconfig->readrequest.ARHeader.AxAddr.i = baseaddr+burstlength*4*col+1920*4*row;
        SGP_sendRead(SGPconfig, &(SGPconfig->readrequest), &(SGPconfig->readresponse), SGP_WAITFORRESPONSE);

        // Copy the data back to the pixel object
        for (int i = 0; i < burstlength; i++) {
          pixels[row][burstlength*col+i] = SGPconfig->readresponse.RDATA[i].ARData.i;
        }
      }

      // Check if we have leftover bytes to request
      if (config->width % burstlength != 0) {
        SGPconfig->readrequest.ARHeader.AxAddr.i = baseaddr+burstlength*4*(numbursts)+1920*4*row;
        burstlength = config->width % burstlength;
        SGP_AXI_set_readburstlength(burstlength, &(SGPconfig->readrequest));
        SGP_sendRead(SGPconfig, &(SGPconfig->readrequest), &(SGPconfig->readresponse), SGP_WAITFORRESPONSE);
        // Copy the data back to the pixel object
        for (int i = 0; i < burstlength; i++) {
          pixels[row][256*(config->width/256)+i] = SGPconfig->readresponse.RDATA[i].ARData.i;
        }
      }

    }
    sglu_array_to_bmp(config, pixels, &bmp);
    if (config->debug_level > 0) {
      sglu_bmp_info(&bmp);
    }

  }
    
  return 0;
}




/*****************************************************************************
 * Function: check_config                                    
 * Description: Checks to make sure that the configuration values are valid.
 *****************************************************************************/
void check_config(sglu_config_type *config) {

  /* Value of width must be between WIDTH_MIN and WIDTH_MAX */
  if ((config->width < WIDTH_MIN) || (config->width > WIDTH_MAX)) {
    raise_error(config, ERR_BADWIDTH);
  }

  /* Value of height must be between HEIGHT_MIN and HEIGHT_MAX */
  if ((config->height < HEIGHT_MIN) || (config->height > HEIGHT_MAX)) {
    raise_error(config, ERR_BADHEIGHT);
  }

  /* Color depth should be 1, 4, 8, 16, 24, or 32 */
  if ((config->depth != 1) && (config->depth != 4) && (config->depth != 8) && 
      (config->depth != 16) && (config->depth != 24) && 
      (config->depth != 32)) {
    raise_error(config, ERR_BADDEPTH);
  }

  /* Value of debug_level should be > 0 */
  if (config->debug_level < 0) {
    raise_error(config, ERR_BADDEBUG);
  }
  
  return;
}



/*****************************************************************************
 * Function: print_config                                    
 * Description: Prints the configuration information for debug purposes.
 *****************************************************************************/
void print_config(sglu_config_type *config) {

  fprintf(stderr, "Printing (%s) configuration information:\n", EXEC_NAME);
  fprintf(stderr, "   width         - %d\n", config->width);
  fprintf(stderr, "   height        - %d\n", config->height);  
  fprintf(stderr, "   depth         - %d\n", config->depth);
  fprintf(stderr, "   debug_level   - %d\n", config->debug_level);
  fprintf(stderr, "   read          - %d\n", config->read);
  fprintf(stderr, "   infile_name   - %s\n", config->infile_name);
  fprintf(stderr, "   outfile_name  - %s\n", config->outfile_name);

  
  return;
}

