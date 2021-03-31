/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_graphics.h - provides definitions for the predetermined data memory
 * regions on the SGP design. Add to this file to define any static memory 
 * regions. Helper functions would be responsible for any dynamic regions. 
 *
 *
 *
 * NOTES:
 * 11/18/20 by JAZ::Updated to include base addresses for graphics state.
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/

#pragma once

#include "sgp.h"
#include "sgp_transmit.h"
#include <GL/gl.h>
#include <GL/glext.h>

#include <stdint.h>

// Graphics memory map data structure. 
typedef struct {
    uint32_t baseaddr;
    uint32_t highaddr;
    char name[32];
    char desc[64];
    uint8_t system_offset;
    uint32_t debug_register;
    uint32_t status_register;
} SGP_graphicsmap_t;

// Manually determined values. Add as needed
enum SGP_GRAPHICS_COMPONENTS {SGP_COLORBUFFER_1=0, SGP_COLORBUFFER_2, SGP_COLORBUFFER_3, SGP_DEPTHBUFFER_1, SGP_CLEARBUFFER_1, SGP_ARRAYBUFFERS,
                            SGP_SHADERS, SGP_UNIFORMS, 
                            SGP_VERTEX_FETCH, SGP_VIEWPORT, SGP_RENDER_OUTPUT, SGP_RASTERIZER, SGP_VERTEXSHADER, SGP_FRAGMENTSHADER,
                            SGP_GRAPHICS_NUMCOMPONENTS};
// An easy way to distinguish memory offsets from system offsets
#define SGP_GRAPHICS_SYSTEM_OFFSET 0x0
#define SGP_GRAPHICS_MEMORY_OFFSET 0x1
#define SGP_GRAPHICS_NO_DEBUG      0x0
#define SGP_GRAPHICS_NO_STATUS     0x0


extern SGP_graphicsmap_t SGP_graphicsmap[SGP_GRAPHICS_NUMCOMPONENTS];


// vertexFetch commands and registers
#define SGP_AXI_VERTEXFETCH_START 0x0001

#define SGP_AXI_VERTEXFETCH_TLR        0x00014 // Transmit Length Register
#define SGP_AXI_VERTEXFETCH_TDR        0x0002C // Transmit Destination Register
#define SGP_AXI_VERTEXFETCH_TDFD       0x10000 // Transmit FIFO Data Write Port

#define SGP_AXI_VERTEXFETCH_CTRL       0x20000
#define SGP_AXI_VERTEXFETCH_STATUS     0x20004 
#define SGP_AXI_VERTEXFETCH_NUMVERTEX  0x20008
#define SGP_AXI_VERTEXFETCH_NUMATTRIB  0x2000C
#define SGP_AXI_VERTEXFETCH_ATTRIB_000_SIZE 0x20010
#define SGP_AXI_VERTEXFETCH_ATTRIB_001_SIZE 0x20014
#define SGP_AXI_VERTEXFETCH_ATTRIB_010_SIZE 0x20018
#define SGP_AXI_VERTEXFETCH_ATTRIB_011_SIZE 0x2001C

// viewPort registers
#define SGP_AXI_VIEWPORT_X_REG          0x0000
#define SGP_AXI_VIEWPORT_Y_REG          0x0004
#define SGP_AXI_VIEWPORT_WIDTH_REG      0x0008
#define SGP_AXI_VIEWPORT_HEIGHT_REG     0x000C
#define SGP_AXI_VIEWPORT_NEARVAL_REG    0x0010
#define SGP_AXI_VIEWPORT_FARVAL_REG     0x0014
#define SGP_AXI_VIEWPORT_DEBUG          0x003C

// rasterizer registers
#define SGP_AXI_RASTERIZER_PRIMTYPE_REG  0x0000
#define SGP_AXI_RASTERIZER_STATUS        0x0038
#define SGP_AXI_RASTERIZER_DEBUG         0x003C

#define SGP_GL_POINTS           0
#define SGP_GL_LINES            1
#define SGP_GL_LINE_LOOP        2
#define SGP_GL_LINE_STRIP       3
#define SGP_GL_TRIANGLES        4
#define SGP_GL_TRIANGLE_STRIP   5
#define SGP_GL_TRIANGLE_FAN     6


// renderOutput registers
#define SGP_AXI_RENDEROUTPUT_COLORBUFFER 0x0000
#define SGP_AXI_RENDEROUTPUT_DEPTHBUFFER 0x0004
#define SGP_AXI_RENDEROUTPUT_CACHECTRL   0x0008
#define SGP_AXI_RENDEROUTPUT_STRIDE      0x000C
#define SGP_AXI_RENDEROUTPUT_HEIGHT      0x0010
#define SGP_AXI_RENDEROUTPUT_STATUS      0x0038
#define SGP_AXI_RENDEROUTPUT_DEBUG       0x003C


// cache configuration flags
#define DCACHE_CTRL_CACHEABLE_FLAG       0x0001
#define DCACHE_CTRL_INVALIDATE_FLAG      0x0002
#define DCACHE_CTRL_WRITEBACK_FLAG       0x0004
#define DCACHE_CTRL_FLUSH_FLAG           0x0008

//Oh golly we're making our own now
#define SGP_AXI_VERTEXSHADER_FLUSH       0x0010
#define SGP_AXI_VERTEXSHADER_IFLUSH      0x0014




// Graphics buffer object data structure
typedef struct {
	GLuint buffer;
	GLenum target;
	GLsizeiptr size;
	const void *cpu_ptr;
	uint32_t gpu_ptr;
	GLenum usage;
	uint8_t status;
} SGP_buffer_t;

// Vertex attribute data structure
typedef struct {
    SGP_buffer_t *vertex_buffer_object;
    GLuint index;
    GLint size;
    GLenum type;
    GLboolean normalized;
    GLsizei stride;
    const GLvoid *pointer;
    uint8_t status;
} SGP_vertex_attrib_t;


#define SGP_GRAPHICS_BUFFER_COPIED 0x01
#define SGP_GRAPHICS_ATTRIB_VALID 0x01
#define SGP_GRAPHICS_MAX_VERTEX_BUFFER_OBJECTS 256
#define SGP_GRAPHICS_MAX_VERTEX_ATTRIB 4

// Graphics state data structure
typedef struct {
    SGP_buffer_t vertex_buffer_objects[SGP_GRAPHICS_MAX_VERTEX_BUFFER_OBJECTS];
    SGP_vertex_attrib_t vertex_attributes[SGP_GRAPHICS_MAX_VERTEX_ATTRIB];
    uint32_t num_vertex_buffer_objects;
    uint32_t num_vertex_attributes;
    uint32_t cur_vertex_buffer_object;
    uint32_t gpu_mem_free_ptr;

    GLint viewport_x;
    GLint viewport_y;
    GLsizei viewport_width;
    GLsizei viewport_height;

} SGP_graphicsstate_t;

extern SGP_graphicsstate_t SGP_graphicsstate;

// Initialization functions
int SGP_graphicsInit(sgp_config *config);
void SGP_print_debugregs();
void SGP_print_graphicsmap();

// Implementation of driver callbacks. Put these in sgp_graphics.c to avoid having to update glxtrace.cpp that often
void SGP_glDrawArrays(GLenum mode, GLint first, GLsizei count);
void SGP_glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
void SGP_glGenBuffers(GLsizei n, GLuint *buffers);
void SGP_glBindBuffer(GLenum target, GLuint buffer);
void SGP_glBufferData(GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
void SGP_glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void SGP_glClear(GLbitfield mask);
void SGP_glxSwapBuffers(uint32_t flag);
void SGP_glViewport(GLint x, GLint y, GLsizei width, GLsizei height);

void SGP_setprimtype(GLenum mode);

// Helper functions. These should probably go in SGLU but that codebase is a bit of a mess. 
typedef uint32_t sglu_fixed_t;
uint32_t sglu_color_float_to_int(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
sglu_fixed_t sglu_float_to_fixed(GLfloat float_val, uint8_t fixed_point_frac_bits);
