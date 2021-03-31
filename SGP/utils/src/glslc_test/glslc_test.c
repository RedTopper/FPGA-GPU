/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * glslc_test.c - a standalone test application for GLSL shader to SGP 
 * compilers. Does not interface with the board.
 *
 *
 * NOTES:
 * 1/16/21 by JAZ::Design created.
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "sgp_shaders.h"
#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"
#include "sgp_axi.h"
#include "sgp.h"

// Don't know if this is needed?
// sgp_config *SGPconfig;

int SGP_inittest() {

    int returnValue;
    
    // Initialize the SGP configuration
    returnValue = SGP_configInit(&SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
        return returnValue;
    }

    // Always turn off any transmit information. 
    SGPconfig->driverMode = 0;

    // Initialize the SGP system IP
    returnValue = SGP_systemInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
        return returnValue;
    }

    // Initialize the SGP graphics IP and memory map
    returnValue = SGP_graphicsInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
        return returnValue;
    }

    // Initialize the SGP shaders IP and memory map
    returnValue = SGP_shadersInit(SGPconfig);
    if (returnValue != 0) {
        printf("%s: Error setting up SGP driver infrastructure.\n", __FILE__);
        return returnValue;
    }

    return 0;
}


int SGP_shadertest(char *vert_shader_fname, char *frag_shader_fname, int debugValue) {

    FILE *vert_shader_file, *frag_shader_file;
    long vert_shader_length, frag_shader_length;
    char *vert_shader_src, *frag_shader_src;
    int returnVal;

    if (debugValue == 1)
        SGPconfig->driverMode |= SGP_STDOUT;

    // Open up both files
    vert_shader_file = fopen(vert_shader_fname, "rt");
    if (!vert_shader_file) {
        if (debugValue == 1) {
            printf("Cannot open file %s for reading\n", vert_shader_fname);
        }
        return 1;
    }
    frag_shader_file = fopen(frag_shader_fname, "rt");
    if (!frag_shader_file) {
        if (debugValue == 1) {
            printf("Cannot open file %s for reading\n", frag_shader_fname);
        }
        return 1;
    }

    // Find the length of each file and allocate a (null-terminated) string
    fseek(vert_shader_file, 0, SEEK_END);
    vert_shader_length = ftell(vert_shader_file);
    fseek(vert_shader_file, 0, SEEK_SET);
    vert_shader_src = (char *)malloc(vert_shader_length + 1);
    vert_shader_src[vert_shader_length] = '\0';
    fread(vert_shader_src, 1, vert_shader_length, vert_shader_file);
    fclose(vert_shader_file);

    fseek(frag_shader_file, 0, SEEK_END);
    frag_shader_length = ftell(frag_shader_file);
    fseek(frag_shader_file, 0, SEEK_SET);
    frag_shader_src = (char *)malloc(frag_shader_length + 1);
    frag_shader_src[frag_shader_length] = '\0';
    fread(frag_shader_src, 1, frag_shader_length, frag_shader_file);
    fclose(frag_shader_file);

    // Create a program [0] with 2 shader objects [0, 1]
    returnVal = SGP_glCreateProgram(0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glCreateProgram\n");
        }
        return returnVal;
    }

    returnVal = SGP_glCreateShader(GL_VERTEX_SHADER, 0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glCreateShader(%d, %d)\n", GL_VERTEX_SHADER, 0);
        }
        return returnVal;
    }

    returnVal = SGP_glCreateShader(GL_FRAGMENT_SHADER, 1);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glCreateShader(%d, %d)\n", GL_FRAGMENT_SHADER, 1);
        }
        return returnVal;
    }

    returnVal = SGP_glShaderSource(0, 1, (const GLchar* const*) &vert_shader_src, 0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glShaderSource(%d)\n", 0);
        }
        return returnVal;
    }

    returnVal = SGP_glShaderSource(1, 1, (const GLchar* const*) &frag_shader_src, 0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glShaderSource(%d)\n", 1);
        }
        return returnVal;
    }

    returnVal = SGP_glCompileShader(0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glCompileShader(%d)\n", 0);
        }
        return returnVal;
    }

    returnVal = SGP_glCompileShader(1);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glCompileShader(%d)\n", 1);
        }
        return returnVal;
    }

    returnVal = SGP_glAttachShader(0, 0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glAttachShader(%d)\n", 0);
        }
        return returnVal;
    }

    returnVal = SGP_glAttachShader(0, 1);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_glAttachShader(%d)\n", 1);
        }
        return returnVal;
    }

    returnVal = SGP_glLinkProgram(0);
    if (returnVal) {
        if (debugValue == 1) {
            printf("Error in SGP_LinkProgram\n");
        }
        return returnVal;
    }

    return 0;
}
  

// Usage: glslc_test shader1.vert shader2.frag [-d]
int main(int argc, char **argv) {

    int debugValue = 0;
    int returnValue;
    if (argc == 4) {
        if (!strcmp(argv[3], "-d")) {
            debugValue = 1;
        }
        else {
            printf("Usage: glslc_test shader1.vert shader2.frag [-d]\n");
            return 1;
        }

    }

    else if (argc != 3) {
        printf("Usage: glslc_test vertex_shader_fragment_shader [-d]\n");
        return 1;      
    }

    returnValue = SGP_inittest();
    if (returnValue) {
        return returnValue;
    }

    returnValue = SGP_shadertest(argv[1], argv[2], debugValue);
    SGP_configClose(SGPconfig);

    return returnValue;
}

