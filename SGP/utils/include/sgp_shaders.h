/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_shaders.h - provides functions for managing vertex and fragment 
 * shaders in the SGP design.  
 *
 *
 * NOTES:
 * 12/31/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once

#include "sgp_shaders.h"
#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"

#include <GL/gl.h>
#include <GL/glext.h>

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <shaderc/shaderc.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


#define SGP_SHADERS_UNIFORM_VALID 0x01
#define SGP_SHADERS_MAX_UNIFORMS 256

#define SGP_SHADERS_SHADER_CREATED 0x01
#define SGP_SHADERS_SHADER_SOURCED 0x02
#define SGP_SHADERS_SHADER_COMPILED 0x04
#define SGP_SHADERS_SHADER_ATTACHED 0x08
#define SGP_SHADERS_MAX_SHADERS 16

#define SGP_SHADERS_PROGRAM_CREATED 0x01
#define SGP_SHADERS_PROGRAM_ATTACHED 0x02
#define SGP_SHADERS_PROGRAM_LINKED 0x04
#define SGP_SHADERS_PROGRAM_USED 0x08
#define SGP_SHADERS_MAX_PROGRAMS 2


// sgp_vertexshader registers
#define SGP_AXI_VERTEXSHADER_PC         0x0000
#define SGP_AXI_VERTEXSHADER_NUMVERTEX  0x0004
#define SGP_AXI_RASTERIZER_STATUS       0x0038
#define SGP_AXI_RASTERIZER_DEBUG        0x003C



// Uniform data structure
typedef struct {
    uint8_t status;
    char name[256];
    uint8_t size;
    GLint gl_uniformID;
    uint32_t sgp_loc;
    uint32_t baseaddr;    
} SGP_uniform_t;


// Shader data structure
typedef struct {
    uint8_t status;
    GLenum gl_type;
    GLuint gl_shaderID;
    char *glsl_src;
    char *spv_dis;
    char *sgp_src;
    uint32_t *sgp_bin;
    int32_t sgp_bin_len;
    uint32_t baseaddr;
} SGP_shader_t;


// Shader program data structure
typedef struct {
    uint8_t status;
    GLuint gl_programID;
    int32_t attached_shader_index[SGP_SHADERS_MAX_SHADERS];
    uint8_t num_shaders;
} SGP_program_t;


// Shaders state data structure
typedef struct {
    SGP_uniform_t uniforms[SGP_SHADERS_MAX_UNIFORMS];
    SGP_shader_t shaders[SGP_SHADERS_MAX_SHADERS];
    SGP_program_t programs[SGP_SHADERS_MAX_PROGRAMS];
    uint32_t program_baseaddr;
    uint32_t uniform_baseaddr;
    uint8_t num_uniforms;
    uint8_t num_shaders;
    uint8_t num_programs;
} SGP_shadersstate_t;

extern SGP_shadersstate_t SGP_shadersstate;


// Initialization functions
int SGP_shadersInit(sgp_config *config);

// Implementation of driver callbacks. Put these in sgp_shaders.c to avoid having to update glxtrace.cpp that often
int SGP_glCreateProgram(GLuint gl_programID);
int SGP_glCreateShader(GLenum gl_type, GLuint gl_shaderID);
int SGP_glCompileShader(GLuint gl_shaderID); 
int SGP_glAttachShader(GLuint gl_programID, GLuint gl_shaderID);
int SGP_glLinkProgram(GLuint gl_programID);
int SGP_glUseProgram(GLuint gl_programID);
int SGP_glShaderSource(GLuint gl_shaderID, GLsizei count, const GLchar * const * string, const GLint * length);
int SGP_glGetUniformLocation(GLuint gl_programID, GLint gl_uniformID, const GLchar * name);
void SGP_glUniform1f(GLint location, GLfloat v0);
void SGP_glUniform4fv(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void SGP_glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat * value);


// Utility functions for program/shader/uniform ID match
int32_t SGP_lookupProgram(GLuint gl_programID);
int32_t SGP_lookupShader(GLuint gl_shaderID);
int32_t SGP_lookupUniform(GLuint gl_uniformID);
