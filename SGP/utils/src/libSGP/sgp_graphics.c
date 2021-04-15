/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_graphics.c - provides definitions for the predetermined data memory
 * regions on the SGP design. Add to this file to define any static memory 
 * regions. Helper functions would be responsible for any dynamic regions. 
 *
 *
 * NOTES:
 * 11/4/20 by JAZ::Design created.
 *****************************************************************************/

#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"

// Manually determined values. Add as needed. Note that the color buffers need to be aligned for VDMA
// operations to work properly. 
SGP_graphicsmap_t SGP_graphicsmap[SGP_GRAPHICS_NUMCOMPONENTS] = {
		[SGP_COLORBUFFER_1] = {0x00000000, 0x007E8FFC, "SGP_COLORBUFFER_1 ", "Frame (color) buffer for video out - 1", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_COLORBUFFER_2] = {0x007E9000, 0x00FD1FFC, "SGP_COLORBUFFER_2 ", "Frame (color) buffer for video out - 2", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_COLORBUFFER_3] = {0x00FD2000, 0x017BAFFC, "SGP_COLORBUFFER_3 ", "Frame (color) buffer for video out - 3", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_DEPTHBUFFER_1] = {0x017BB000, 0x01FA3FFC, "SGP_DEPTHBUFFER_1 ", "Depth buffer                          ", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_CLEARBUFFER_1] = {0x01FA4000, 0x0278CFFC, "SGP_CLEARBUFFER_1 ", "Clear buffer                          ", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_ARRAYBUFFERS] =  {0x0278D000, 0x0678CFFC, "SGP_ARRAYBUFFERS  ", "Vertex array buffer region            ", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_SHADERS] =       {0x0678D000, 0x06F8CFFC, "SGP_SHADERS       ", "Shader instruction memory region      ", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_UNIFORMS] =      {0x06F8D000, 0x0778CFFC, "SGP_UNIFORMS      ", "Shader uniform data memory region     ", SGP_GRAPHICS_MEMORY_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_VERTEX_FETCH] =  {0x44A50000, 0x44A5FFFC, "SGP_VERTEX_FETCH  ", "Vertex fetch unit config and FIFOs    ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_AXI_VERTEXFETCH_STATUS},
		[SGP_VIEWPORT] =      {0x44A80000, 0x44A8FFFC, "SGP_VIEWPORT      ", "Viewport transformation config        ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_AXI_VIEWPORT_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_RENDER_OUTPUT] = {0x44A90000, 0x44A9FFFC, "SGP_RENDER_OUTPUT ", "Render Output (ROP) config            ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_AXI_RENDEROUTPUT_DEBUG, SGP_AXI_RENDEROUTPUT_STATUS},
		[SGP_RASTERIZER]  =   {0x44AA0000, 0x44AAFFFC, "SGP_RASTERIZER    ", "Rasterization unit config             ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_AXI_RASTERIZER_DEBUG, SGP_AXI_RASTERIZER_STATUS},
		[SGP_VERTEXSHADER]  = {0x44AB0000, 0x44ABFFFC, "SGP_VERTEXSHADER  ", "Vertex shader control and config      ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS},
		[SGP_FRAGMENTSHADER] ={0x44AC0000, 0x44ACFFFC, "SGP_FRAGMENTSHADER", "Fragment shader control and config    ", SGP_GRAPHICS_SYSTEM_OFFSET,
		                       SGP_GRAPHICS_NO_DEBUG, SGP_GRAPHICS_NO_STATUS}
};


// Global graphics state. This is likely replicating much of the work in apitrace, but tighter integration of the two codebases is a lot to ask
SGP_graphicsstate_t SGP_graphicsstate;


// Our implementation of glDrawArrays. Kicks off DMA transactions and tells the vertex fetch unit to get started
void SGP_glDrawArrays(GLenum mode, GLint first, GLsizei count) {


	// The rasterizer needs to be aware of the primitive type.
	SGP_setprimtype(mode);

	// Tell the vertex fetch unit that it can get started
	uint32_t baseaddr = SGP_graphicsmap[SGP_VERTEX_FETCH].baseaddr;
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_NUMVERTEX, count);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_CTRL, SGP_AXI_VERTEXFETCH_START);

	// Check status and see if it has gotten started
	uint32_t status = SGP_read32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_STATUS);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_CTRL, 0);

	// We have to update our offset(s) based on the first input. Ignore this for now
	if (first != 0) {
		//printf("SGP_glDrawArrays warning: first value of %d ignored\n", first);
	}


	// We need to limit our burst length to 256 vertex attributes of a single index at a time so that the shared 
	// buffer object FIFO doesn't get full, preventing us from sending in the rest of the attributes. 
#define MAX_VERTEX_ATTRIBUTE_BURST 256
	uint32_t num_bursts = count / MAX_VERTEX_ATTRIBUTE_BURST;
	uint32_t burst_length = MAX_VERTEX_ATTRIBUTE_BURST;
	uint32_t last_burst_length = count % MAX_VERTEX_ATTRIBUTE_BURST;

	if (last_burst_length != 0) {
		num_bursts++;
	}

	for (uint32_t i = 0; i < num_bursts; i++) {

		if ((last_burst_length != 0) && (i == num_bursts - 1)) {
			burst_length = last_burst_length;
		}


		for (uint32_t j = 0; j < SGP_graphicsstate.num_vertex_attributes; j++) {
			SGP_vertex_attrib_t cur_vertex_attribute = SGP_graphicsstate.vertex_attributes[j];

			// If this attribute has a non-zero stride, we probably can't use DMA at all. This is something that can be 
			// implemented later. 
			if (cur_vertex_attribute.stride != 0) {
				if (SGPconfig->driverMode != 0) {
					printf("SGP_glDrawArrays warning: ignoring attribute with stride value of %d\n", cur_vertex_attribute.stride);
				}
				break;
			}


			// Set the TDEST (via the FIFO TDR register) so that we know which attribute this burst corresponds to
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_TDR, j);

			// We want to copy size*burst_length*4 bytes from the GPU pointer at the appropriate offset to our FIFO
			// This is a "keyhole write" transaction, so we only care about the single destination address			
			SGP_DMArequest(SGPconfig, cur_vertex_attribute.vertex_buffer_object->gpu_ptr + i * MAX_VERTEX_ATTRIBUTE_BURST * cur_vertex_attribute.size * 4,
			               baseaddr + SGP_AXI_VERTEXFETCH_TDFD,
			               burst_length * cur_vertex_attribute.size * 4,
			               SGP_DMA_KEYHOLEWRITE);

			// The documentation isn't clear, but it is suggested to wait until all the data is copied before setting the length register
			SGP_DMAwaitidle(SGPconfig);

			// Specify the length to kick off the FIFO output (or in cut-through mode, to complete the FIFO transmission)
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_TLR, burst_length * cur_vertex_attribute.size * 4);
		}
	}
}


// Sets the primitive type in the sgp_rasterizer component.  We could probably use the built-in declaration but then would have to manually modify the sgp_types.vhd.
void SGP_setprimtype(GLenum mode) {


	uint32_t sgp_primtype = SGP_GL_POINTS;
	uint32_t baseaddr = SGP_graphicsmap[SGP_RASTERIZER].baseaddr;
	switch (mode) {

		case GL_POINTS:
			sgp_primtype = SGP_GL_POINTS;
			break;
		case GL_LINES:
			sgp_primtype = SGP_GL_LINES;
			break;
		case GL_LINE_LOOP:
			sgp_primtype = SGP_GL_LINE_LOOP;
			break;
		case GL_LINE_STRIP:
			sgp_primtype = SGP_GL_LINE_STRIP;
			break;
		case GL_TRIANGLES:
			sgp_primtype = SGP_GL_TRIANGLES;
			break;
		case GL_TRIANGLE_STRIP:
			sgp_primtype = SGP_GL_TRIANGLE_STRIP;
			break;
		case GL_TRIANGLE_FAN:
			sgp_primtype = SGP_GL_TRIANGLE_FAN;
			break;
			// The actual modes supported is OpenGL version-specific. Fall back to SGP_GL_POINTS
		default:
			sgp_primtype = SGP_GL_POINTS;
	}

	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RASTERIZER_PRIMTYPE_REG, sgp_primtype);
}


// Our implementation of glVertexAttribPointer. We need to update the vertex fetch unit to know how to fetch data, and kick off DMA
// requests to stream data into that unit. If this is the first call for this buffer, convert and copy the data. 
void SGP_glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* pointer) {


	// Set the current attribute based on index. If there are no valid attributes yet, allocate one. A linear search is ok for now.
	// Since Attrib and AttribPointer don't have to be called in attribute index order, we should separately store the index mapping


	// We have a maximum number of supported attributes
	if (index >= SGP_GRAPHICS_MAX_VERTEX_ATTRIB) {
		if (SGPconfig->driverMode != 0) {
			printf("SGP_glVertexAttribPointer warning: used maximum vertex attributes, ignoring attribute %d\n", index);
		}
		return;
	}

	uint32_t cur_vertex_attribute = (uint32_t) index;


	// Update all the parameters of the current attribute. Many of these will be redundant copies, which is ok. 
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].index = index;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].size = size;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].type = type;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].normalized = normalized;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].stride = stride;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].pointer = pointer;
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].vertex_buffer_object = &SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object];
	SGP_graphicsstate.vertex_attributes[cur_vertex_attribute].status |= SGP_GRAPHICS_ATTRIB_VALID;

	// Have we copied the VBO data into GPU memory already? If not, we certainly have to do so now. Ideally we would do so in SGP_glBufferData, but 
	// we only now know how to best convert the data before copying it over. 
	if ((SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].status & SGP_GRAPHICS_BUFFER_COPIED) == 0) {

		uint32_t gpu_ptr = SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].gpu_ptr;
		float* cpu_ptr = (float*) SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].cpu_ptr;

		if (SGPconfig->driverMode != 0) {
			printf("SGP_glVertexAttribPointer test: copying %d bytes from pointer 0x%08x\n",
			       SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].size, cpu_ptr);
		}

		// If the data is not NULL, the data store is initialized with data from the previously stored pointer
		// We want fixed-point data in the buffer, so convert based on the type requested currently.
		if (cpu_ptr) {
			SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].status |= SGP_GRAPHICS_BUFFER_COPIED;

			// This should be done via burst requests, vs sending the data over word by word
#define MAX_VERTEX_BUFFER_BURST 256
			uint32_t num_bursts =
					((uint32_t) SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].size / 4) / MAX_VERTEX_BUFFER_BURST;
			uint32_t burst_length = MAX_VERTEX_BUFFER_BURST;
			uint32_t last_burst_length =
					((uint32_t) SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].size / 4) % MAX_VERTEX_BUFFER_BURST;

			if (last_burst_length != 0) {
				num_bursts++;
			}

			for (uint32_t i = 0; i < num_bursts; i++) {
				if ((last_burst_length != 0) && (i == num_bursts - 1)) {
					burst_length = last_burst_length;
				}
				SGP_AXI_set_writeburstlength(burst_length, &(SGPconfig->writerequest));
				SGPconfig->writerequest.AWHeader.AxAddr.i = gpu_ptr + 4 * i * MAX_VERTEX_BUFFER_BURST;

				for (uint32_t j = 0; j < burst_length; j++) {
					uint32_t val = (uint32_t) cpu_ptr[j + i * MAX_VERTEX_BUFFER_BURST];
					// Convert GL_FLOATS to 16.16 or 2.30 depending if they're normalized or not
					if (type == GL_FLOAT) {
						if (normalized == GL_TRUE) {
							if (SGPconfig->driverMode != 0) {
								printf("SGP_glVertexAttribPointer warning: normalized GL_FLOAT input converted to Q2.30 format. This is not (yet) supported in hardware.\n");
							}
							val = sglu_float_to_fixed(cpu_ptr[j + i * MAX_VERTEX_BUFFER_BURST], 30);
						} else {
							val = sglu_float_to_fixed(cpu_ptr[j + i * MAX_VERTEX_BUFFER_BURST], 16);
						}
					}
					SGPconfig->writerequest.WDATA[j].AWData.i = val;

				}
				SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
			}

		}
	}

	// Update the vertex fetch unit with the attribute meta-data
	uint32_t baseaddr = SGP_graphicsmap[SGP_VERTEX_FETCH].baseaddr;

	// Is this a previously uninitialized attribute? Update the total in the corresponding register
	// Note: this does not assume ordered attributes, but does assume that if attrib 4 is initialized, attribs [0-3] are eventually coming
	uint32_t num_attrib = index + 1;
	if (num_attrib > SGP_graphicsstate.num_vertex_attributes) {
		SGP_graphicsstate.num_vertex_attributes = num_attrib;
		SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_NUMATTRIB, num_attrib);
	}

	// Update the attribute size information. We could also do this in DrawArrays() instead
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXFETCH_ATTRIB_000_SIZE + 4 * cur_vertex_attribute, size);
}


// Our implementation of glBufferData. This tells us how much memory to allocate but not what types are being used (yet).
// We can assume all data is coming in 32-bit chunks to make our life easier, but shouldn't copy until 
// the first time that glVertexAttribPointer() is called and we know the types. 
void SGP_glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage) {

	// We know our CPU ptr (data), our GPU ptr (the current gpu_mem_free_ptr), and can copy the objects at this point
	SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].usage = usage;
	SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].cpu_ptr = data;
	SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].gpu_ptr = SGP_graphicsstate.gpu_mem_free_ptr;
	SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].size = size;
	SGP_graphicsstate.vertex_buffer_objects[SGP_graphicsstate.cur_vertex_buffer_object].status = 0;

	SGP_graphicsstate.gpu_mem_free_ptr += size;
}


// Our implementation of glBindBuffer. Update the current buffer and target
void SGP_glBindBuffer(GLenum target, GLuint buffer) {

	// Set the current buffer based on the specified buffer generated by glGenBuffers. A linear search is ok for now.
	for (uint32_t i = 0; i < SGP_graphicsstate.num_vertex_buffer_objects; i++) {
		if (SGP_graphicsstate.vertex_buffer_objects[i].buffer == buffer) {
			SGP_graphicsstate.cur_vertex_buffer_object = i;
			SGP_graphicsstate.vertex_buffer_objects[i].target = target;
			break;
		}
	}
}

// Our implementation of glGenBuffers. 
void SGP_glGenBuffers(GLsizei n, GLuint* buffers) {

	uint32_t num_vertex_buffer_objects = SGP_graphicsstate.num_vertex_buffer_objects;
	for (uint32_t i = 0; i < n; i++) {
		SGP_graphicsstate.vertex_buffer_objects[num_vertex_buffer_objects + i].buffer = buffers[i];
	}
	SGP_graphicsstate.num_vertex_buffer_objects += n;

	if (SGP_graphicsstate.num_vertex_buffer_objects > SGP_GRAPHICS_MAX_VERTEX_BUFFER_OBJECTS) {
		printf("SGP_glGenBuffers warning: more buffers than statically allowed in SGP driver, crash imminent\n");
	}
}


void SGP_glViewport(GLint x, GLint y, GLsizei width, GLsizei height) {

	// Update our graphics state
	SGP_graphicsstate.viewport_x = x;
	SGP_graphicsstate.viewport_y = y;
	SGP_graphicsstate.viewport_width = width;
	SGP_graphicsstate.viewport_height = height;

	// Store the updated values in the viewPort registers
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VIEWPORT].baseaddr + SGP_AXI_VIEWPORT_X_REG, x);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VIEWPORT].baseaddr + SGP_AXI_VIEWPORT_Y_REG, y);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VIEWPORT].baseaddr + SGP_AXI_VIEWPORT_WIDTH_REG, width);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VIEWPORT].baseaddr + SGP_AXI_VIEWPORT_HEIGHT_REG, height);
}


// Our implementation of glClearColor. This function needs to 1) convert the Glfloats to our
// fixed color buffer format (32-bit ARGB), 2) fill up the entire SGP_CLEARBUFFER with
// that value. This is very inefficient, but will make for the presumably much more common
// SGP_glClear() calls to be more efficient.
void SGP_glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {

	// Hard-coded window. Arguably this is ok, as we don't have an actual window on the SGP
	uint16_t window_width = 1920;
	uint16_t window_height = 1080;

	// We are overwriting the CLEARBUFFER
	uint32_t baseaddr = SGP_graphicsmap[SGP_CLEARBUFFER_1].baseaddr;


	// Calculate what our equivalent pixel should be. Replaced with call to sglu_color_float_to_int()
	uint32_t pixel_val = sglu_color_float_to_int(red, green, blue, alpha);

	// Copy the pixel object into the write request. We have a constant color, so only 
	// have to do this once. 
	uint16_t burstlength = 256;
	for (int i = 0; i < burstlength; i++) {
		SGPconfig->writerequest.WDATA[i].AWData.i = pixel_val;
	}

	// This could be made much faster if we replaced it with CDMA calls vs all these 256-entry writes
	for (int row = 0; row < window_height; row++) {
		burstlength = 256;
		SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
		uint8_t numbursts = window_width / burstlength;
		for (int col = 0; col < numbursts; col++) {
			SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr + burstlength * 4 * col + 1920 * 4 * row;
			SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
		}

		// Check if we have leftover bytes to request
		if (window_width % burstlength != 0) {
			SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr + burstlength * 4 * (numbursts) + 1920 * 4 * row;
			burstlength = window_width % burstlength;
			SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
			SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
		}
	}
}


// Our implementation of glClear(). 
void SGP_glClear(GLbitfield mask) {
	if (mask & GL_COLOR_BUFFER_BIT) {
		// Grab the current backbuffer via the VDMA parkptr and use that frame
		uint8_t cur_buffer = SGP_getbackbuffer(SGPconfig);
		uint32_t destaddr = SGP_graphicsmap[SGP_COLORBUFFER_1 + cur_buffer].baseaddr;

		SGP_DMArequest(SGPconfig, SGP_graphicsmap[SGP_CLEARBUFFER_1].baseaddr, destaddr, 1920 * 1080 * 4, SGP_DMA_REGULAR);

	} else if (mask & GL_DEPTH_BUFFER_BIT) {
		SGP_DMArequest(SGPconfig, SGP_graphicsmap[SGP_COLORBUFFER_3].baseaddr, SGP_graphicsmap[SGP_DEPTHBUFFER_1].baseaddr, 1920 * 1080 * 4, SGP_DMA_REGULAR);
	}
}

// Our implementation of glxSwapBuffers
void SGP_glxSwapBuffers(uint32_t flag) {

	static int framecount = 0;

	// SwapBuffers is a reasonable place to synchronize all the previous draw calls. 
	if (flag & SGP_SYSTEM_WAITIDLE) {
		SGP_DMAwaitidle(SGPconfig);

		// For each component in the pipeline that has a status register, check it and wait until it is =0. Only do this if we're in a transmit mode. 
		// Loop until all components are done at the same time. 
		if (SGPconfig->driverMode & SGP_ETH) {
			uint32_t numTimes = 0;
			uint32_t idle;
			uint32_t rastStatus;
			uint32_t vertexStatus;
			uint32_t renderStatus = 0;

			// /SGP_AXI_VERTEXFETCH_STATUS
			do {
				rastStatus = SGP_read32(SGPconfig, SGP_graphicsmap[SGP_RASTERIZER].baseaddr + SGP_AXI_RASTERIZER_STATUS);
				vertexStatus = SGP_read32(SGPconfig, SGP_graphicsmap[SGP_VERTEX_FETCH].baseaddr + SGP_AXI_VERTEXFETCH_STATUS);
				// Still haven't quite figured this one out
				//renderStatus = SGP_read32(SGPconfig, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_STATUS);
				idle = rastStatus == 0 && vertexStatus == 0 && renderStatus == 0;
				if (idle) {
					numTimes++;
				} else {
					numTimes = 0;
				}

				//printf("%d %d %d %d\n", rastStatus, vertexStatus, renderStatus, numTimes);
			} while (numTimes != 2);
		}
	}

	uint8_t backbuffer = SGP_getbackbuffer(SGPconfig);
	SGP_setactivebuffer(SGPconfig, backbuffer);

	// Let the renderOutput module know where the backbuffer currently is
	uint32_t buffer_addr = SGP_graphicsmap[SGP_COLORBUFFER_1].baseaddr;
	// uint8_t cur_buffer = 0;
	if (backbuffer == 0) {
		buffer_addr = SGP_graphicsmap[SGP_COLORBUFFER_2].baseaddr;
	}

	//Flush our renderoutput cache
	uint32_t flags = SGP_read32(SGPconfig, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_CACHECTRL);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_CACHECTRL, DCACHE_CTRL_FLUSH_FLAG | flags);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_CACHECTRL, flags);

	
	//set the new buffer
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_COLORBUFFER, buffer_addr);

	//flush the vertexShader
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VERTEXSHADER].baseaddr + SGP_AXI_SHADER_FLUSH, 99);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VERTEXSHADER].baseaddr + SGP_AXI_SHADER_FLUSH, 0);

	//flush the fragment shader
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_FRAGMENTSHADER].baseaddr + SGP_AXI_SHADER_FLUSH, 99);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_FRAGMENTSHADER].baseaddr + SGP_AXI_SHADER_FLUSH, 0);

	framecount++;
	if (framecount % 100 == 0) {
		if (SGPconfig->driverMode != 0) {
			printf("\n\n\n\n\n\nFramecount - \x1B[32m%d\n\x1B[0m\n\n\n\n\n", framecount);
		}
	}
}


// Converts a GLfloat to a fixed-point value
sglu_fixed_t sglu_float_to_fixed(GLfloat float_val, uint8_t fixed_point_frac_bits) {
	return (sglu_fixed_t) (float_val * (1 << fixed_point_frac_bits));
}

// Converts a .rgba float-point value to our fixedc color buffer format (32-bit ARGB)
uint32_t sglu_color_float_to_int(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {

	uint32_t pixel_val = 0x00000000;
	pixel_val |= ((uint8_t) (alpha * 256) << 24);
	pixel_val |= ((uint8_t) (red * 256) << 16);
	pixel_val |= ((uint8_t) (blue * 256) << 8);
	pixel_val |= ((uint8_t) (green * 256) << 0);

	return pixel_val;
}


// Graphics initialization. Configures the various IP in the system for video output
int SGP_graphicsInit(sgp_config* config) {

	int i;

	// Update the address map for components that are actually sitting in main memory
	for (i = 0; i < SGP_GRAPHICS_NUMCOMPONENTS; i++) {
		if (SGP_graphicsmap[i].system_offset == SGP_GRAPHICS_MEMORY_OFFSET) {
			SGP_graphicsmap[i].baseaddr += SGP_systemmap[SGP_MEM_INTERFACE].baseaddr;
			SGP_graphicsmap[i].highaddr += SGP_systemmap[SGP_MEM_INTERFACE].baseaddr;
		}
	}

	// Print out the memory map if SGP_STDOUT
	if (config->driverMode & SGP_STDOUT) {
		SGP_print_graphicsmap();
	}

	// Initialize the graphics state
	SGP_graphicsstate.num_vertex_buffer_objects = 0;
	SGP_graphicsstate.num_vertex_attributes = 0;
	SGP_graphicsstate.cur_vertex_buffer_object = 0;
	SGP_graphicsstate.gpu_mem_free_ptr = SGP_graphicsmap[SGP_ARRAYBUFFERS].baseaddr;

	// Set each buffer to have a status of 0x0, to note they are unitialized
	for (i = 0; i < SGP_GRAPHICS_MAX_VERTEX_BUFFER_OBJECTS; i++) {
		SGP_graphicsstate.vertex_buffer_objects[i].status = 0;
	}

	// Set each attribute to have a status of 0x0, to note they are invalid
	for (i = 0; i < SGP_GRAPHICS_MAX_VERTEX_ATTRIB; i++) {
		SGP_graphicsstate.vertex_attributes[i].status = 0;
	}

	//Set the initial value of the depth buffer
	SGP_write32(SGP_config, SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr + SGP_AXI_RENDEROUTPUT_DEPTHBUFFER, SGP_graphicsmap[SGP_DEPTHBUFFER_1].baseaddr);


	// Set the renderOutput to point to the initial backbuffer and configure it's cache
	uint32_t baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_COLORBUFFER, SGP_graphicsmap[SGP_COLORBUFFER_2].baseaddr);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_CACHECTRL, DCACHE_CTRL_CACHEABLE_FLAG);

	// Also set the resolution stride and height in the renderOutput so it knows how much to multiply incoming y values by
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_STRIDE, SGP_videomodes[VMODE_1920x1080].width * 4);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_HEIGHT, SGP_videomodes[VMODE_1920x1080].height);

	if (SGPconfig->driverMode & SGP_ETH)
		SGP_print_debugregs();

	return 0;
}


void SGP_print_debugregs() {
	printf("\nSGP graphics subsystem debug registers:\n");
	printf("   Name                   Value\n");
	for (int i = 0; i < SGP_GRAPHICS_NUMCOMPONENTS; i++) {
		if (SGP_graphicsmap[i].debug_register != SGP_GRAPHICS_NO_DEBUG) {
			printf("\x1B[32m   %s     0x%08x\n", SGP_graphicsmap[i].name,
			       SGP_read32(SGPconfig, SGP_graphicsmap[i].baseaddr + SGP_graphicsmap[i].debug_register));
		}
	}
	printf("\x1B[0m\n");
}

void SGP_print_graphicsmap() {

	printf("\nSGP graphics subsystem memory map:\n");
	printf("   Name                   BaseAddr       HighAddr     Description\n");
	for (int i = 0; i < SGP_GRAPHICS_NUMCOMPONENTS; i++) {
		printf("   %s     0x%08x     0x%08x     %s\n", SGP_graphicsmap[i].name, SGP_graphicsmap[i].baseaddr, SGP_graphicsmap[i].highaddr,
		       SGP_graphicsmap[i].desc);
	}
}

//Defines how we will blend
void SGP_glBlendFunc(GLenum sfactor, GLenum dfactor) {
	printf("Inside blend func!");
	uint32_t baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_BLENDCTRL_SFACTOR, sfactor);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_BLENDCTRL_DFACTOR, dfactor);
}

//Clears depth to a predefined height, not sure how needed this is but we like to copy
//A blantant copy of proffesor zambrenos SPG_glClearColor
void SGP_glClearDepth(GLdouble depth) {
	printf("Inside clear depth!!\n");
	uint16_t window_width = 1920;
	uint16_t window_height = 1080;

	uint32_t baseaddr = SGP_graphicsmap[SGP_COLORBUFFER_3].baseaddr;
	uint16_t burstlength = 256;
	for (int i = 0; i < burstlength; i++) {
		SGPconfig->writerequest.WDATA[i].AWData.i = depth;
	}

	for (int row = 0; row < window_height; row++) {
		burstlength = 256;
		SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
		uint8_t numbursts = window_width / burstlength;
		for (int col = 0; col < numbursts; col++) {
			SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr + burstlength * 4 * col + 1920 * 4 * row;
			SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
		}
		if (window_width % burstlength != 0) {
			SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr + burstlength * 4 * (numbursts) + 1920 * 4 * row;
			burstlength = window_width % burstlength;
			SGP_AXI_set_writeburstlength(burstlength, &(SGPconfig->writerequest));
			SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
		}
	}
}

//Defines how we will do depth testing
void SGP_glDepthFunc(GLenum func) {
	printf("Inside depth Func!!\n");
	uint32_t baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_DEPTHCTRL, func);
}

//Used to enable blending and depth testing
void SGP_glEnable(GLenum cap) {
	printf("Inside enable!!\n");
	uint32_t baseaddr;
	switch (cap) {
		case GL_BLEND:
			baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_BLENDENA, 1);
			break;
		case GL_DEPTH_TEST:
			baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_DEPTHENA, 1);
			break;
		default:
			return;
	}
}

//Used to disable blending and depth testing
void SGP_glDisable(GLenum cap) {
	printf("Inside disable!!\n");
	uint32_t baseaddr;
	switch (cap) {
		case GL_BLEND:
			baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_BLENDENA, 0);
			break;
		case GL_DEPTH_TEST:
			baseaddr = SGP_graphicsmap[SGP_RENDER_OUTPUT].baseaddr;
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_RENDEROUTPUT_DEPTHENA, 0);
			break;
		default:
			return;
	}
}

//Used to set the depth at which we will range our depths.
void SGP_glDepthRange(GLdouble zNear, GLdouble zFar) {
	uint32_t baseaddr = SGP_graphicsmap[SGP_VIEWPORT].baseaddr;
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VIEWPORT_NEARVAL_REG, zNear);
	SGP_write32(SGPconfig, baseaddr + SGP_AXI_VIEWPORT_FARVAL_REG, zFar);
}
