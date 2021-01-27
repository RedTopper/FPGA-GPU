/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * mvmac.c - performs 4x4 matrix vector mutliplication on an array of
 * randomly generated 16-bit integer vectors. 
 * Define GEN_FILEs and it will also recreate the BlockRAM initialization 
 * files needed for MP0.
 *
 *
 * NOTES:
 * 12/16/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <math.h>

#define NUM_VECTORS 10000   // Number of arrays to generate and multiply
#define RANDOM 0            // Set to 1 for more random vector generation

#define GEN_FILE1 1         // Generate the dmem.dat matrix+vector file
#define GEN_FILE2 1         // Generate the outmem.dat UART text file

int main(int argc, char **argv) {

  FILE *gen_file1;            // For dmem.dat
  FILE *gen_file2;            // For outmem.dat
  int file1_cnt, file2_cnt;   // Counters for output files

  uint16_t A[4][4];           // Matrix A
  uint16_t **x;               // Array of vectors x
  uint64_t y[4];              // Output y += A*x_i, for all i

  struct timeval start, end;  // For estimated timing of SW app
  uint64_t time_ns;



  int i, j, k;

  // String to hold output.dat data
  char output_str[22][8] = {"\nCalcula", "ted resu", "lt is:\r\n",
			    "y[0]: 0x", "00000000", "00000000", "      \r\n",
			    "y[1]: 0x", "11111111", "11111111", "      \r\n",
			    "y[2]: 0x", "22222222", "22222222", "      \r\n",
			    "y[3]: 0x", "33333333", "33333333", "      \r\n",
			    "Time: 0x", "ffffffff", " ns.\n\n\r\n"};
 
  // We will typically not want to randomize the vectors, so that we can 
  // repeat and compare results with the HW implementation. 
  if (RANDOM == 1) {
    srand(time(0));
  }
  else {
    srand(42);
  }

  // Allocate memory for x
  x = (uint16_t **)malloc(4*sizeof(uint16_t *));
  for (i = 0; i < 4; i ++) {
    x[i] = (uint16_t *)malloc(NUM_VECTORS*sizeof(uint16_t));
  }

  // Initialize A (random), x (random), and y (all 0s)
  for (i = 0; i < 4; i++) {
    y[i] = 0;
    for (j = 0; j < 4; j++) {
      A[i][j] = rand() % UINT16_MAX;
      //printf("A[%d][%d] = %d\n", i, j, A[i][j]);
    }
    for (j = 0; j < NUM_VECTORS; j++) {
      x[i][j] = rand() % UINT16_MAX;
      //printf("x[%d][%d] = %d\n", i, j, x[i][j]);
    }
  }


  // Dump the dmem.dat memory file
  if (GEN_FILE1 == 1) {
    
    file1_cnt = 0;
    gen_file1 = fopen("dmem.dat", "w");
    if (gen_file1 == NULL) {
      printf("Error opening dmem.dat.\n");
      return -1;
    }

    // Write the A matrix first. We assume a 32-bit memory file
    for (i = 0; i < 4; i++) {
      for (j = 0; j < 4; j+=2) {
	      fprintf(gen_file1, "%04x%04x\n", A[i][j], A[i][j+1]);
	      file1_cnt++;
      }
    }

    // Write the x vectors next. 
    for (i = 0; i < NUM_VECTORS; i++) {
      for (j = 0; j < 4; j+=2) {
	      fprintf(gen_file1, "%04x%04x\n", x[j][i], x[j+1][i]);
	      file1_cnt++;
      }
    }

    // We need the files to be full, i.e. there must be 2^n rows
    for (i = file1_cnt; i < exp2(ceil(log2((double)file1_cnt))); i++) {
      fprintf(gen_file1, "%08x\n", 0);
    }

    fclose(gen_file1);

  }



  // Dump the output.dat memory file
  if (GEN_FILE2 == 1) {

    file2_cnt = 0;
    gen_file2 = fopen("outmem.dat", "w");
    if (gen_file2 == NULL) {
      printf("Error opening outmem.dat.\n");
      return -1;
    }  

    // Output.dat is a 64-bit memory file
    for (i = 0; i < 22; i++) {
      for (j = 0; j < 8; j++) {
	      fprintf(gen_file2, "%02x", (int)output_str[i][j]);
      }
      fprintf(gen_file2, "\n");
      file2_cnt++;
    }

    // Same as above, force the output to 2^n rows
    for (i = file2_cnt; i< exp2(ceil(log2((double)file2_cnt))); i++) {
      fprintf(gen_file2, "%08x%08x\n", 0, 0);
    }

    fclose(gen_file2);
  }


  // Start the timer
  gettimeofday(&start, NULL);


  // Perform the accumulate operation
  for (i = 0; i < NUM_VECTORS; i++) {
    for (j = 0; j < 4; j++) {
      for (k = 0; k < 4; k++) {
	      y[j] += (uint64_t)A[j][k] * x[k][i];
      }
    }
  }


  // We want the time in nanoseconds for direct comparison with HW
  gettimeofday(&end, NULL);
  time_ns = ((end.tv_sec * 1000000 + end.tv_usec) - 
	     (start.tv_sec * 1000000 + start.tv_usec)) * 1000;


  printf("\n\nCalculated result is:\n");
  printf("y[0]: 0x%016lx\n", y[0]);
  printf("y[1]: 0x%016lx\n", y[1]);
  printf("y[2]: 0x%016lx\n", y[2]);
  printf("y[3]: 0x%016lx\n", y[3]);  
  printf("Time: 0x%08x ns.\n\n\n\n", (uint32_t)time_ns);

  return 0;
}
