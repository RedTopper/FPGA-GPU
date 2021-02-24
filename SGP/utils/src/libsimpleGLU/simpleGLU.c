/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * simpleGLU.c - provides some utility functions for the SGP driver
 *
 *
 * NOTES:
 * 11/10/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "simpleGLU.h"


/*****************************************************************************
 * Function: sglu_bmp_to_array                            
 * Description: Converts a bmp file to an equivalent 2D array of integer
 * values representing pixels.
 *****************************************************************************/
unsigned int **sglu_bmp_to_array(sglu_config_type *config, bmp_file_info *bmp) {

  int num_colors, twidth, theight, rowbytes, i, j;
  unsigned int extra_pixels[4];
  unsigned char *tpixels;
  unsigned int **pixels;

  // Open up the file, and read the header information
  config->infile = fopen(config->infile_name, "rb"); 
  if (!config->infile) {
    sglu_raise_error(config, SGLU_ERR_NOFILE1);
  }

  // Allocate memory for the bmp_file_info variable
  bmp->h1 = (bmp_magic *)malloc(sizeof(bmp_magic));
  bmp->h2 = (bmp_header *)malloc(sizeof(bmp_header));
  bmp->h3 = (dib_header *)malloc(sizeof(dib_header));

  if ((!bmp->h1) || (!bmp->h2) || (!bmp->h3)) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }


  if (config->debug_level > 3) {
    fprintf(stderr, "Reading bmp header information from %s\n", 
	    config->infile_name);
  }
    
	size_t temp;
  temp = fread(bmp->h1, sizeof(bmp_magic), 1, config->infile);
  temp = fread(bmp->h2, sizeof(bmp_header), 1, config->infile);
  temp = fread(bmp->h3, sizeof(dib_header), 1, config->infile);


  // Check that configuration matches what we expect
  if ((bmp->h3->bitspp != config->depth) || 
      (bmp->h3->height != config->height) || 
      (bmp->h3->width != config->width)) {
    fprintf(stderr, "Warning: %s configuration and header information in %s ", LIB_NAME, config->infile_name);
    fprintf(stderr, "do not match. Using bmp header values.\n");
    config->depth = bmp->h3->bitspp;
    config->height = bmp->h3->height;
    config->width = bmp->h3->width;
  }


  // If using 16-bit color or higher, there is no color palette
  if (bmp->h3->bitspp < 16) {

    if (config->debug_level > 3) {
      fprintf(stderr, "Reading color palette\n");
    }

    // If the size of the color pallete is set as 0, there should be 
    // 2^bitspp entries in the pallete. 
    if (bmp->h3->ncolors == 0) {
      num_colors = pow(2, bmp->h3->bitspp);
    }
    else {
      num_colors = bmp->h3->ncolors;
    }

    bmp->h4 = (unsigned int *)malloc(num_colors*sizeof(unsigned int));
    if (!bmp->h4) {
      sglu_raise_error(config, SGLU_ERR_NOMEM);
    }     
    temp = fread(bmp->h4, sizeof(unsigned int), num_colors, config->infile);
  }


  twidth = bmp->h3->width;
  theight = bmp->h3->height;
 

  // Allocate memory for the 2D array
  pixels = sglu_allocate_pixel_array(twidth, theight);
 
  // Allocate memory for each temporary row from the file
  rowbytes = (int)ceil(twidth * bmp->h3->bitspp / 8.0);
  tpixels = (unsigned char *)malloc(rowbytes*sizeof(unsigned char));
  if (!tpixels) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }

  // Read from the file and copy things over. Note that
  // each row must have land on a 4-byte boundary. Read
  // (and ignore) those bytes as necessary. 
  for (i = 0; i < theight; i++) {
    temp = fread(tpixels, 1, rowbytes, config->infile);

    // The storage in pixels[][] is dependent on the bitspp
    // BMP files are in reverse raster scan order
    switch (bmp->h3->bitspp) {
      case 1:
	      for (j = 0; j < twidth; j++) {
      	  pixels[theight-i-1][j] = (tpixels[j/8] >> (7-(j%8))) & 0x1;
      	}
      	break;
      case 4:
	      for (j = 0; j < twidth; j++) {
	        pixels[theight-i-1][j] = (tpixels[j/2] >> (16*((1-j%2)))) & 0xF;
      	}
      	break;
      case 8:
	      for (j = 0; j < twidth; j++) {
	        pixels[theight-i-1][j] = tpixels[j];
      	}
	      break;
      case 16:
	      for (j = 0; j < twidth; j++) {
	        pixels[theight-i-1][j] = (tpixels[2*j] << 0) | (tpixels[2*j+1] << 8);
    	  }
	      break;
      case 24:
      	for (j = 0; j < twidth; j++) {
	        pixels[theight-i-1][j] = (tpixels[3*j] << 8) | 
	                                 (tpixels[3*j+1] << 0) | 
	                                 (tpixels[3*j+2] << 16);
      	}
      	break;
      case 32:
	      for (j = 0; j < twidth; j++) {
	        pixels[theight-i-1][j] = (tpixels[4*j] << 0) | 
	                                 (tpixels[4*j+1] << 24) | 
	                                 (tpixels[4*j+2] << 16) |
	                                 (tpixels[4*j+3] << 8);
      	}
      	break;
      default:
      	break;
    }

    if (rowbytes % 4 != 0) {
      temp = fread(extra_pixels, 1, 4-(rowbytes%4), config->infile);
    }

  }
     
  fclose(config->infile);
 
  return pixels;
}

/*****************************************************************************
 * Function: bmp_info                            
 * Description: Print out some statistics about the bmp file, for debug
 * purposes
 *****************************************************************************/
void sglu_bmp_info(bmp_file_info *bmp) {

  printf("Printing bmp file information:\n");
  printf("   Magic number is %x%x\n", bmp->h1->magic[1], bmp->h1->magic[0]);
  printf("   File size is %d\n", bmp->h2->filesz);
  printf("   Header size is %d\n", bmp->h3->header_sz);
  printf("   Color depth is %d\n", bmp->h3->bitspp);
  printf("   Width = %d, Height = %d\n", bmp->h3->width, bmp->h3->height);
  printf("   Number of pixel bytes = %d\n", bmp->h3->bmp_bytesz);

  return;
}


/*****************************************************************************
 * Function: array_to_bmp                            
 * Description: Converts a 2D array of pixels to a .bmp file format
 *****************************************************************************/
void sglu_array_to_bmp(sglu_config_type *config, unsigned int **pixels, bmp_file_info *bmp) {

  int num_colors, theight, twidth, rowbytes, i, j, k;
  unsigned char *tpixels;
  unsigned char extra_pixels[4] = {0x77, 0x78, 0x79, 0x80};

  config->outfile = fopen(config->outfile_name, "wb");
  if (!config->outfile) {
    sglu_raise_error(config, SGLU_ERR_NOFILE2);
  }


  if (config->debug_level > 3) {
    fprintf(stderr, "Writing bmp header information to %s\n", 
	    config->outfile_name);
  }  
  fwrite(bmp->h1, sizeof(bmp_magic), 1, config->outfile);
  fwrite(bmp->h2, sizeof(bmp_header), 1, config->outfile);
  fwrite(bmp->h3, sizeof(dib_header), 1, config->outfile);

  // If using 16-bit color or higher, there is no color palette
  if (bmp->h3->bitspp < 16) {

    if (config->debug_level > 3) {
      fprintf(stderr, "Writing color palette\n");
    }

    // If the size of the color pallete is set as 0, there should be 
    // 2^bitspp entries in the pallete. 
    if (bmp->h3->ncolors == 0) {
      num_colors = pow(2, bmp->h3->bitspp);
    }
    else {
      num_colors = bmp->h3->ncolors;
    }

    if (bmp->h4) {
      fwrite(bmp->h4, sizeof(int), num_colors, config->outfile);
    }

  }

  twidth = bmp->h3->width;
  theight = bmp->h3->height;

  rowbytes = (int)ceil(twidth * bmp->h3->bitspp / 8.0);
  tpixels = (unsigned char *)malloc(rowbytes*sizeof(unsigned char));
  if (!tpixels) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }

  // Read from the array and copy things over. Note that
  // each row must have land on a 4-byte boundary. Write
  // empty bytes as necessary. 
  for (i = 0; i < theight; i++) {
 
    // The storage in pixels[][] is dependent on the bitspp
    // BMP files are in reverse raster scan order
    switch (bmp->h3->bitspp) {
      case 1:
	      for (j = 0; j < rowbytes; j++) {
	        tpixels[j] = 0;
	        for (k = 0; k < 8; k++) {
	          tpixels[j] |= (pixels[theight-i-1][8*j+k] << (7-k));
      	  }
      	}
      	break;
      case 4:
	      for (j = 0; j < rowbytes; j++) {
	        tpixels[j] = (pixels[theight-i-1][2*j] << 16) | 
	                      pixels[theight-i-1][2*j+1];
      	}
       	break;
      case 8:
	      for (j = 0; j < rowbytes; j++) {
	        tpixels[j] = pixels[theight-i-1][j];
      	}
      	break;
      case 16:
	      for (j = 0; j < rowbytes; j+=2) {
	        tpixels[j] = (pixels[theight-i-1][j/2] >> 16) & 0xFF;
	        tpixels[j+1] = (pixels[theight-i-1][j/2] >> 8) & 0xFF;
      	}
	      break;
      case 24:
	      for (j = 0; j < rowbytes; j+=3) {
	        tpixels[j] = (pixels[theight-i-1][j/3] >> 8) & 0xFF;
	        tpixels[j+1] = (pixels[theight-i-1][j/3] >> 0) & 0xFF;
	        tpixels[j+2] = (pixels[theight-i-1][j/3] >> 16) & 0xFF;
      	}
      	break;
      case 32:
	      for (j = 0; j < rowbytes; j+=4) {
	        tpixels[j] = (pixels[theight-i-1][j/3] >> 0) & 0xFF;
	        tpixels[j+1] = (pixels[theight-i-1][j/3] >> 24) & 0xFF;
	        tpixels[j+2] = (pixels[theight-i-1][j/3] >> 16) & 0xFF;
	        tpixels[j+3] = (pixels[theight-i-1][j/3] >> 8) & 0xFF;
      	}
      	break;
      default:
      	break;
    }

    fwrite(tpixels, 1, rowbytes, config->outfile);

    if (rowbytes % 4 != 0) {
      fwrite(extra_pixels, 1, 4-(rowbytes%4), config->outfile);
    }
  }


  fclose(config->outfile);
  return;
}



/*****************************************************************************
 * Function: sglu_init_bmp                            
 * Description: Creates a bmp header based on config information
 *****************************************************************************/
void sglu_init_bmp(sglu_config_type *config, bmp_file_info *bmp) {

  int num_colors, rowbytes;

  // Allocate memory for the bmp_file_info variable
  bmp->h1 = (bmp_magic *)malloc(sizeof(bmp_magic));
  bmp->h2 = (bmp_header *)malloc(sizeof(bmp_header));
  bmp->h3 = (dib_header *)malloc(sizeof(dib_header));

  if ((!bmp->h1) || (!bmp->h2) || (!bmp->h3)) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }


  // Create a default color table. The actual palette will be app-specific
  // and can't be reproduced here. 
  num_colors = 0;
  bmp->h4 = NULL;
  /*if (config->depth < 16) {
   * num_colors = pow(2, config->depth);
   * bmp->h4 = (unsigned int *)malloc(num_colors*sizeof(unsigned int));
   * if (!bmp->h4) {
   *   sglu_raise_error(config, SGLU_ERR_NOMEM);
   * }     
   * for (i = 0; i < num_colors; i++) {
   *   bmp->h4[i] = i*i%2;
   * }
   *}
   */  


  rowbytes = (int)ceil(config->width * config->depth / 8.0);


  bmp->h1->magic[0] = 'B';
  bmp->h1->magic[1] = 'M';

  bmp->h2->filesz = 14+40+num_colors*4+config->height*rowbytes;
  if (rowbytes % 4 != 0) {
    bmp->h2->filesz += config->height*(4-rowbytes%4);
  }
  bmp->h2->creator1 = 0;
  bmp->h2->creator2 = 0;
  bmp->h2->bmp_offset = 14+40+num_colors*4;

  bmp->h3->header_sz = 40;
  bmp->h3->width = config->width;
  bmp->h3->height = config->height;
  bmp->h3->nplanes = 1;
  bmp->h3->bitspp = config->depth;
  bmp->h3->compress_type = 0;
  bmp->h3->bmp_bytesz = bmp->h2->filesz - 14 - 40 - num_colors*4;
  bmp->h3->hres = 1;
  bmp->h3->vres = 1;
  bmp->h3->ncolors = 0;
  bmp->h3->nimpcolors = 0;

  return;

}

/*****************************************************************************
 * Function: sglu_allocate_pixel_array
 * Description: Dynamically allocates a 2D array of pixels
 *****************************************************************************/
unsigned int **sglu_allocate_pixel_array(int width, int height) {

  unsigned int **pixels;
  int i;
 
  pixels = (unsigned int **)malloc(height*sizeof(unsigned int *)); 

  for (i = 0; i < height; i++) {
      pixels[i] = (unsigned int *)malloc(width*sizeof(unsigned int));
  }

  return pixels;
}



/*****************************************************************************
 * Function: sglu_init_config                                    
 * Description: Allocates memory for and initializes the configuration 
 * datatype using the default values
 *****************************************************************************/
sglu_config_type *sglu_init_config() {
  sglu_config_type *config;

  /* Allocate memory for the configuration datatype */
  config = (sglu_config_type *)malloc(sizeof(sglu_config_type));
  if (!config) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }

  /* Set everything to its default value */
  config->height = SGLU_HEIGHT_DEFAULT;
  config->width = SGLU_WIDTH_DEFAULT;
  config->depth = SGLU_DEPTH_DEFAULT;
  config->debug_level = SGLU_DEBUG_DEFAULT;
  config->read = 0;
  
  /* Allocate space for the file names, even though we might need more
   * or less space after parsing the command line arguments. */
  config->outfile_name = (char *)malloc(strlen(SGLU_OUTFILE_DEFAULT1)+1);
  if (!config->outfile_name) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }
  strcpy(config->outfile_name, SGLU_OUTFILE_DEFAULT1);

  config->infile_name = (char *)malloc(strlen(SGLU_INFILE_DEFAULT1)+1);
  if (!config->infile_name) {
    sglu_raise_error(config, SGLU_ERR_NOMEM);
  }
  strcpy(config->infile_name, SGLU_INFILE_DEFAULT1);


  config->infile = NULL;
  config->outfile = NULL;

  return config;
}



/*****************************************************************************
 * Function: sglu_raise_error                                    
 * Description: Prints out an error message determined by   
 * the condition and exits the program.                     
 *****************************************************************************/
void sglu_raise_error(sglu_config_type *config, int error_num) {

  fprintf(stderr, "\n");
  switch(error_num) {
    case SGLU_ERR_NOFILE1:
      fprintf(stderr, "Error: file %s not found\n", config->infile_name);
      break;
    case SGLU_ERR_BADFILE:
      fprintf(stderr, "Error: file %s not in correct format\n", config->infile_name);
      break;
    case SGLU_ERR_NOMEM:
      fprintf(stderr, "Error: application ran out of memory\n");
      break;
    case SGLU_ERR_NOFILE2:
      fprintf(stderr, "Error: cannot open file %s for writing\n", config->outfile_name);
      break;
    case SGLU_ERR_UNDEFINED:
    default:
      fprintf(stderr, "Error: undefined error\n");
      break;
  }
  fprintf(stderr, "%s exited with error code %d\n", LIB_NAME, error_num); 
  exit(error_num);
}