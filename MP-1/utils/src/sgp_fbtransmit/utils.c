/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * utils.c - utility functions for the sgp_fbcopy application.
 *
 *
 * NOTES:
 * 11/10/12 by JAZ::Design created.
 *****************************************************************************/

#include "sgp_fbtransmit.h"
#include "simpleGLU.h"

/*****************************************************************************
 * Function: print_help                            
 * Description: Prints out the program help message.
 *****************************************************************************/
void print_help() {
  printf("Usage: %s [options]\n\n", EXEC_NAME);
  printf("Main options:\n");
  printf("-w <value>, --width <value>        Pixel width ");
  printf("(default is %d)\n", WIDTH_DEFAULT);

  printf("-h <value>, --height <value>       Pixel height ");
  printf("(default is %d)\n", HEIGHT_DEFAULT);

  printf("-d <value>, --depth <value>        Color depth ");
  printf("(default is %d)\n", DEPTH_DEFAULT);

  printf("-D <value>, --debug <value>        Debug level ");
  printf("(default is %d)\n", DEBUG_DEFAULT);

  printf("-I <file>, --in <file>            Output file name ");
  printf("(default is %s)\n", SGLU_INFILE_DEFAULT1);

  printf("-O <file>, --out <file>            Output file name ");
  printf("(default is %s)\n", SGLU_OUTFILE_DEFAULT1);

  printf("-R, --read                        Read operation ");
  printf("(default is write operation)\n");

  printf("-H, --help                         Print this message\n");
  exit(0);
}



/*****************************************************************************
 * Function: raise_error                                    
 * Description: Prints out an error message determined by   
 * the condition and exits the program.                     
 *****************************************************************************/
void raise_error(sglu_config_type *config, int error_num) {

  fprintf(stderr, "\n");
  switch(error_num) {
    case ERR_USAGE:
      fprintf(stderr, "Usage: %s [-w <n>] [-h <n>] [-d <n>] ", EXEC_NAME);
      fprintf(stderr, "[-D <n>] [-I <file>] [-O <file>] [-R] [-H]\n");
      break;
    case ERR_NOMEM:
      fprintf(stderr, "Error: application ran out of memory\n");
      break;
    case ERR_BADWIDTH:
      fprintf(stderr, "Error: value of width must be between %d and %d\n", 
	      WIDTH_MIN, WIDTH_MAX);
      break;
    case ERR_BADHEIGHT:
      fprintf(stderr, "Error: value of height must be between %d and %d\n", 
	      HEIGHT_MIN, HEIGHT_MAX);
      break;
    case ERR_BADDEPTH:
      fprintf(stderr, "Error: color depth must be 1, 4, 8, 16, 24, or 32\n");
      break;
    case ERR_BADDEBUG:
      fprintf(stderr, "Error: value of debug must be greater than 0\n");
      break;
    case ERR_DRIVER:
      fprintf(stderr, "Error: problem loading libSGP driver infrastructure\n\n");
      break;
    case ERR_UNDEFINED:
    default:
      fprintf(stderr, "Error: undefined error\n");
      break;
  }
  fprintf(stderr, "%s exited with error code %d\n", EXEC_NAME, error_num); 
  exit(error_num);
}



/*****************************************************************************
 * Function: read_command_line                                    
 * Description: Reads in and parses the input command line in order to set 
 * configuration data. 
 *****************************************************************************/
void read_command_line(sglu_config_type *config, int argc, char **argv) {
  int i;

  /* This can run without any arguments on the command line */
  if (argc < 1) {
    raise_error(config, ERR_USAGE);
  }

  /* If the last command-line argument is -h or --help that is ok */
  if (!strncmp(argv[argc-1], "-H", 2) || !strncmp(argv[argc-1], "--help", 6)) {
    print_help();
  }
  
  for (i = 1; i < argc; i++) {
    /* Arguments must begin with '-' or '--' */
    if (argv[i][0] != '-' || strlen(argv[i]) < 2) {
      raise_error(config, ERR_USAGE);
    }
   
    /* Decode the single dash arguments */
    if (argv[i][1] != '-') {
      /* Single dash arguments should have just one character after the dash */
      if (strlen(argv[i]) > 2) {
	      raise_error(config, ERR_USAGE);	
      }
      switch (argv[i][1]) {
        case 'h':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
	        sscanf(argv[++i], "%d", &config->height);
        	break;
        case 'w':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
	        sscanf(argv[++i], "%d", &config->width);
        	break;
        case 'd':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
	        sscanf(argv[++i], "%d", &config->depth);
        	break;
        case 'D':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
        	sscanf(argv[++i], "%d", &config->debug_level);
        	break;
        case 'O':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
        	config->outfile_name = (char *)realloc(config->outfile_name, strlen(argv[++i])+1);
        	if (!config->outfile_name) {
	          raise_error(config, ERR_NOMEM); 
        	}
	        strcpy(config->outfile_name, argv[i]);
          config->read = 0;
      	  break;
        case 'I':
          if (i == argc-1) {
            raise_error(config, ERR_USAGE);
          }
  	      config->infile_name = (char *)realloc(config->infile_name, strlen(argv[++i])+1);
        	if (!config->infile_name) {
	          raise_error(config, ERR_NOMEM); 
    	    }
	        strcpy(config->infile_name, argv[i]);	          
          config->read = 1;
          break;
        case 'R':
      	  config->read = 0;
      	  break;
        case 'H':
      	  print_help();
	        break;
        default:
      	  raise_error(config, ERR_USAGE);
      	  break;
      }
    }
       
    /* Decode the double dash arguments */
    else {
      if (!strncmp(argv[i], "--height", 8)) {
        if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
	      sscanf(argv[++i], "%d", &config->height);	
      }
      else if (!strncmp(argv[i], "--width", 7)) {
       if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
	      sscanf(argv[++i], "%d", &config->width);	
      }
      else if (!strncmp(argv[i], "--depth", 7)) {
       if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
      	sscanf(argv[++i], "%d", &config->depth);	
      }
      else if (!strncmp(argv[i], "--debug", 7)) {
       if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
        sscanf(argv[++i], "%d", &config->debug_level);	
      }
      else if (!strncmp(argv[i], "--out", 5)) {
       if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
	      config->outfile_name = (char *)realloc(config->outfile_name, strlen(argv[++i])+1);
      	if (!config->outfile_name) {
	        raise_error(config, ERR_NOMEM); 
    	  }
	      strcpy(config->outfile_name, argv[i]);
        config->read = 0;	
      }
      else if (!strncmp(argv[i], "--in", 4)) {
       if (i == argc-1) {
          raise_error(config, ERR_USAGE);
        }
	      config->infile_name = (char *)realloc(config->infile_name, strlen(argv[++i])+1);
      	if (!config->infile_name) {
	        raise_error(config, ERR_NOMEM); 
    	  }
	      strcpy(config->infile_name, argv[i]);
      	config->read = 1;
      }

      else if (!strncmp(argv[i], "--read", 9)) {
      	config->read = 1;
      }
      else if (!strncmp(argv[i], "--help", 6)) {
	      print_help();
      }
      else {
      	raise_error(config, ERR_USAGE);
      }
    }
  }
  

  return;
}







