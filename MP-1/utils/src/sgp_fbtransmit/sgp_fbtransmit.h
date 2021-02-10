/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_fbtransmit.h - copies .bmp files to/from SGP memory. Useful for system
 * video out testing without having a monitor.
 *
 *
 * NOTES:
 * 11/10/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once

#include "simpleGLU.h"

#define EXEC_NAME "sgp_fbtransmit"

#define ERR_USAGE 1
#define ERR_NOMEM 4
#define ERR_BADHEIGHT 6
#define ERR_BADWIDTH 7
#define ERR_BADDEPTH 8
#define ERR_BADDEBUG 9
#define ERR_DRIVER 10
#define ERR_UNDEFINED 100

#define WIDTH_DEFAULT 1920
#define HEIGHT_DEFAULT 1080
#define DEPTH_DEFAULT 24
#define DEBUG_DEFAULT 10

#define WIDTH_MIN 320
#define WIDTH_MAX 1920
#define HEIGHT_MIN 240
#define HEIGHT_MAX 1080


/* Function prototypes (main.c) */
void check_config(sglu_config_type *);
void print_config(sglu_config_type *);


/* Function prototypes (utils.c) */
void print_help();
void read_command_line(sglu_config_type *, int, char **);
void raise_error(sglu_config_type *, int);
