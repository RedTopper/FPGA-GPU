/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * simpleGLU.h - provides some utility functions for the SGP driver
 *
 *
 * NOTES:
 * 11/10/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once 

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define LIB_NAME "simpleGLU"


#define SGLU_ERR_NOFILE1 2
#define SGLU_ERR_BADFILE 3
#define SGLU_ERR_NOMEM 4
#define SGLU_ERR_NOFILE2 5
#define SGLU_ERR_UNDEFINED 100

#define SGLU_WIDTH_DEFAULT 800
#define SGLU_HEIGHT_DEFAULT 600
#define SGLU_DEPTH_DEFAULT 32
#define SGLU_DEBUG_DEFAULT 10
#define SGLU_INFILE_DEFAULT1 "input.bmp"
#define SGLU_OUTFILE_DEFAULT1 "output.bmp"

// Structure to hold configuration information. This is shared across multiple
// applications, so do not remove entries.  
struct sglu_config_type_s {
  int height;
  int width;
  int depth;
  int debug_level;
  int read;
  char *infile_name;
  char *outfile_name;
  FILE *infile;
  FILE *outfile;
}; typedef struct sglu_config_type_s sglu_config_type;


// BMP structures
// The 2 byte magic number, as a separate struct to avoid alignment problems
struct bmp_magic_s {
  unsigned char magic[2];
}; typedef struct bmp_magic_s bmp_magic;

// File size and offset information
struct bmp_header_s {
  unsigned int filesz;
  unsigned short creator1;
  unsigned short creator2;
  unsigned int bmp_offset;
}; typedef struct bmp_header_s bmp_header;
 
// Bitmap information (assumes Windows V3 version)
struct dib_header_s {
  unsigned int header_sz;
  unsigned int width;
  unsigned int height;
  unsigned short nplanes;
  unsigned short bitspp;
  unsigned int compress_type;
  unsigned int bmp_bytesz;
  unsigned int hres;
  unsigned int vres;
  unsigned int ncolors;
  unsigned int nimpcolors;
}; typedef struct dib_header_s dib_header;

// Struct to hold all the metadata, including the color palette
struct bmp_file_info_s {
  bmp_magic *h1;
  bmp_header *h2;
  dib_header *h3;
  unsigned int *h4;
}; typedef struct bmp_file_info_s bmp_file_info;





unsigned int **sglu_bmp_to_array(sglu_config_type *config, bmp_file_info *bmp);
void sglu_bmp_info(bmp_file_info *bmp);
void sglu_array_to_bmp(sglu_config_type *config, unsigned int **pixels, bmp_file_info *bmp);
void sglu_init_bmp(sglu_config_type *config, bmp_file_info *bmp);
unsigned int **sglu_allocate_pixel_array(int width, int height);
sglu_config_type *sglu_init_config();
void sglu_raise_error(sglu_config_type *, int);
