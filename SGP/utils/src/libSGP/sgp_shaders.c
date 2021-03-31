/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * sgp_shaders.c - provides functions for managing vertex and fragment 
 * shaders in the SGP design.  
 *
 *
 * NOTES:
 * 12/31/20 by JAZ::Design created.
 *****************************************************************************/

#include "sgp_shaders.h"
#include "sgp_graphics.h"
#include "sgp_system.h"
#include "sgp_transmit.h"


// Global shaders state. 
SGP_shadersstate_t SGP_shadersstate;


// Shader driver state initialization. 
int SGP_shadersInit(sgp_config* config) {

	// Initialize the shaderstate data structure
	SGP_shadersstate.num_uniforms = 0;
	SGP_shadersstate.num_shaders = 0;
	SGP_shadersstate.num_programs = 0;
	for (int i = 0; i < SGP_SHADERS_MAX_PROGRAMS; i++) {
		SGP_shadersstate.programs[i].num_shaders = 0;
		SGP_shadersstate.programs[i].status = 0;
	}
	for (int i = 0; i < SGP_SHADERS_MAX_SHADERS; i++) {
		SGP_shadersstate.shaders[i].status = 0;
		SGP_shadersstate.shaders[i].glsl_src = NULL;
		SGP_shadersstate.shaders[i].sgp_bin_len = 0;
	}
	for (int i = 0; i < SGP_SHADERS_MAX_UNIFORMS; i++) {
		SGP_shadersstate.uniforms[i].status = 0;
	}

	SGP_shadersstate.uniform_baseaddr = SGP_graphicsmap[SGP_UNIFORMS].baseaddr;
	SGP_shadersstate.program_baseaddr = SGP_graphicsmap[SGP_SHADERS].baseaddr;

	return 0;
}

// Create a program object. Here, we take as input the result of glCreateProgram so we
// can use that ID for future program calls
int SGP_glCreateProgram(GLuint gl_programID) {

	if (SGP_shadersstate.num_programs >= SGP_SHADERS_MAX_PROGRAMS) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCreateProgram warning: already have SGP_SHADERS_MAX_PROGRAMS (%d), not creating new program %d\n",
			       SGP_SHADERS_MAX_PROGRAMS, (int) gl_programID);
		}
		return 1;
	}

	uint8_t cur_program_index = SGP_shadersstate.num_programs;
	SGP_shadersstate.programs[cur_program_index].status |= SGP_SHADERS_PROGRAM_CREATED;
	SGP_shadersstate.programs[cur_program_index].gl_programID = gl_programID;

	SGP_shadersstate.num_programs++;

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glCreateProgram: created program object (index=%d) with gl_programID=%d\n", cur_program_index, (int) gl_programID);
	}

	return 0;
}


// Create a shader object. Here, we take as input the result of glCreateShader so we
// can use that ID for future shader calls
int SGP_glCreateShader(GLenum gl_type, GLuint gl_shaderID) {

	if (SGP_shadersstate.num_shaders >= SGP_SHADERS_MAX_SHADERS) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCreateShader warning: already have SGP_SHADERS_MAX_SHADERS (%d), not creating new shader %d\n",
			       SGP_SHADERS_MAX_SHADERS, (int) gl_shaderID);
		}
		return 1;
	}

	uint8_t cur_shader_index = SGP_shadersstate.num_shaders;
	SGP_shadersstate.shaders[cur_shader_index].status |= SGP_SHADERS_SHADER_CREATED;
	SGP_shadersstate.shaders[cur_shader_index].gl_type = gl_type;
	SGP_shadersstate.shaders[cur_shader_index].gl_shaderID = gl_shaderID;

	SGP_shadersstate.num_shaders++;

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glCreateShader: created shader object (index=%d) of type=%d, gl_shaderID=%d\n", cur_shader_index, (int) gl_type, (int) gl_shaderID);
	}

	return 0;
}

// Associate the shader with the created program
int SGP_glAttachShader(GLuint gl_programID, GLuint gl_shaderID) {

	int32_t cur_program_index, cur_shader_index;

	cur_shader_index = SGP_lookupShader(gl_shaderID);
	if (cur_shader_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glAttachShader: called with gl_shaderID=%d which is not a valid gl_shaderID\n", (int) gl_shaderID);
		}
		return 1;
	}
	cur_program_index = SGP_lookupProgram(gl_programID);
	if (cur_program_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glAttachShader: called with gl_programID=%d which is not a valid gl_programID\n", (int) gl_programID);
		}
		return 1;
	}

	SGP_shadersstate.programs[cur_program_index].status |= SGP_SHADERS_PROGRAM_ATTACHED;

	SGP_shadersstate.programs[cur_program_index].attached_shader_index[SGP_shadersstate.programs[cur_program_index].num_shaders] = cur_shader_index;
	SGP_shadersstate.programs[cur_program_index].num_shaders++;

	SGP_shadersstate.shaders[cur_shader_index].status |= SGP_SHADERS_SHADER_ATTACHED;
	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glAttachShader: Attached shader (index %d) to program (index %d)\n", cur_shader_index, cur_program_index);
	}

	return 0;
}


// Compile shader from source to SPIR-V disassembly to SGP assembly and binary
int SGP_glCompileShader(GLuint gl_shaderID) {

	int32_t cur_shader_index;

	cur_shader_index = SGP_lookupShader(gl_shaderID);
	if (cur_shader_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: called with gl_shaderID=%d which is not a valid gl_shaderID\n", (int) gl_shaderID);
		}
		return 1;
	}

	// Interface with the shaderc compiler to generate SPIR-V dissassembly
	shaderc_shader_kind shader_kind;
	char shader_name[] = "main.vert";
	if (SGP_shadersstate.shaders[cur_shader_index].gl_type == GL_VERTEX_SHADER) {
		shader_kind = shaderc_glsl_vertex_shader;
	} else if (SGP_shadersstate.shaders[cur_shader_index].gl_type == GL_FRAGMENT_SHADER) {
		shader_kind = shaderc_glsl_fragment_shader;
		strcpy(shader_name, "main.frag");
	} else {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: called with gl_type=%d which is not a supported shader type\n", SGP_shadersstate.shaders[cur_shader_index].gl_type);
		}
		return 1;
	}

	shaderc_compiler_t compiler = shaderc_compiler_initialize();
	shaderc_compile_options_t compiler_options = shaderc_compile_options_initialize();
	shaderc_compile_options_set_target_env(compiler_options, shaderc_target_env_opengl, 0);
	shaderc_compile_options_set_auto_map_locations(compiler_options, true);

	shaderc_compilation_result_t result = shaderc_compile_into_spv_assembly(
			compiler, SGP_shadersstate.shaders[cur_shader_index].glsl_src,
			strlen(SGP_shadersstate.shaders[cur_shader_index].glsl_src),
			shader_kind, shader_name, "main", compiler_options);
	shaderc_compilation_status status = shaderc_result_get_compilation_status(result);
	if (status != shaderc_compilation_status_success) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: error compiling shader\n");
		}
		return 1;
	}

	// Copy the SPIR-V assembly to the shader object for debugging purposes
	SGP_shadersstate.shaders[cur_shader_index].spv_dis = (char*) malloc(strlen(shaderc_result_get_bytes(result)) + 1);
	strcpy(SGP_shadersstate.shaders[cur_shader_index].spv_dis, shaderc_result_get_bytes(result));

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glCompileShader: SPIR-V disassembly:\n%s\n", SGP_shadersstate.shaders[cur_shader_index].spv_dis);
	}

	// Our compiler is found in a lua script in /utils/src/libSGP/spv_to_sgp.lua. This code interfaces by
	// passing globals to that script. 
	char filepathname[1024];
	strcpy(filepathname, getenv("CDIR"));
	strcat(filepathname, "/utils/src/libSGP/spv_to_sgp.lua");

	lua_State* L = luaL_newstate();
	luaL_openlibs(L);

	lua_pushstring(L, SGP_shadersstate.shaders[cur_shader_index].spv_dis);
	lua_setglobal(L, "source");

	lua_pushinteger(L, SGP_shadersstate.uniform_baseaddr);
	lua_setglobal(L, "uniformBase");

	lua_pushinteger(L, SGP_graphicsstate.gpu_mem_free_ptr);
	lua_setglobal(L, "memoryBase");

	if (SGPconfig->driverMode & SGP_STDOUT) {
		lua_pushboolean(L, 1);
		lua_setglobal(L, "debugValue");
	}

	int luaResult = luaL_dofile(L, filepathname);

	// Also, update the data (uniforms, assembly, binary) returned by the shader compiler
	if (luaResult != LUA_OK) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: error compiling shader\n");
			printf("\tscript returned: %s\n", lua_tostring(L, -1));
		}
		return 1;
	}

	// Grab the SGP assembly text
	lua_getglobal(L, "assemblyText");
	const char* assembly_text = lua_tostring(L, -1);
	if (!assembly_text) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: error compiling shader\n");
			printf("\tscript returned empty SGP assembly string\n");
		}
		return 1;
	}
	SGP_shadersstate.shaders[cur_shader_index].sgp_src = (char*) malloc(strlen(assembly_text) + 1);
	strcpy(SGP_shadersstate.shaders[cur_shader_index].sgp_src, assembly_text);
	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("\nSGP_glCompileShader: SGP assembly:\n%s\n", SGP_shadersstate.shaders[cur_shader_index].sgp_src);
	}


	// Grab the binary output from the .lua script, and copy into sgp_bin	
	lua_getglobal(L, "binary");
	size_t num_bytes_in_binary = lua_rawlen(L, -1);
	if (num_bytes_in_binary == 0) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glCompileShader: error compiling shader\n");
			printf("\tscript returned binary of size 0\n");
		}
		return 1;
	}

	const char* binary = lua_tostring(L, -1);
	SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len = (int32_t) num_bytes_in_binary;
	SGP_shadersstate.shaders[cur_shader_index].sgp_bin = (uint32_t*) malloc(num_bytes_in_binary);
	memcpy((char*) SGP_shadersstate.shaders[cur_shader_index].sgp_bin, binary, num_bytes_in_binary);

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP binary (length %d bytes):\n", num_bytes_in_binary);
		printf("Addr: Instruction\n");
		for (int i = 0; i < num_bytes_in_binary / 4; i++) {
			printf("%04x: %08x\n", i, SGP_shadersstate.shaders[cur_shader_index].sgp_bin[i]);
		}
		printf("\n");
	}

	lua_getglobal(L, "uniforms");
	size_t num_uniforms = lua_rawlen(L, -1);
	if (num_uniforms) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP Uniforms:             name |   baseaddr | size (bytes)\n");
		}
		for (int i = 1; i <= num_uniforms; i++) {
			lua_geti(L, -1, i);
			lua_getfield(L, -1, "name");
			const char* uniform_name = lua_tostring(L, -1);
			lua_getfield(L, -2, "location");
			const uint32_t uniform_baseaddr = lua_tointeger(L, -1);
			lua_getfield(L, -3, "size");
			const uint32_t uniform_size = lua_tointeger(L, -1);
			lua_pop(L, 4);
			if (SGPconfig->driverMode & SGP_STDOUT) {
				printf("              %16s | 0x%08x | %d\n", uniform_name, uniform_baseaddr, uniform_size);
			}

			// Copy the data into the shader state
			uint32_t uniform_index = SGP_shadersstate.num_uniforms;
			SGP_shadersstate.num_uniforms++;
			if (SGP_shadersstate.num_uniforms >= SGP_SHADERS_MAX_UNIFORMS) {
				if (SGPconfig->driverMode & SGP_STDOUT) {
					printf("SGP_glCompileShader: error compiling shader\n");
					printf("\tMaximum uniform count reached\n");
				}
				return 1;
			}

			SGP_shadersstate.uniforms[uniform_index].status = SGP_SHADERS_UNIFORM_VALID;
			strcpy(SGP_shadersstate.uniforms[uniform_index].name, uniform_name);
			SGP_shadersstate.uniforms[uniform_index].size = uniform_size;
			SGP_shadersstate.uniforms[uniform_index].gl_uniformID = 0;
			SGP_shadersstate.uniforms[uniform_index].sgp_loc = uniform_index;
			SGP_shadersstate.uniforms[uniform_index].baseaddr = uniform_baseaddr;

		}
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("\n");
		}

	}

	// Update the gpu_mem_free_ptr if we allocated buffer memory for the shader
	lua_getglobal(L, "memoryBase");
	SGP_graphicsstate.gpu_mem_free_ptr = lua_tointeger(L, -1);

	lua_close(L);
	shaderc_result_release(result);
	shaderc_compiler_release(compiler);

	SGP_shadersstate.shaders[cur_shader_index].status |= SGP_SHADERS_SHADER_COMPILED;
	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glCompileShader: compiled shader (index=%d)\n", cur_shader_index);
	}

	return 0;
}


// For each attached and compiled shader, copy the SGP binary to the program memory space. 
int SGP_glLinkProgram(GLuint gl_programID) {

	int32_t cur_program_index;

	cur_program_index = SGP_lookupProgram(gl_programID);
	if (cur_program_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glLinkProgram: called with gl_programID=%d which is not a valid gl_programID\n", (int) gl_programID);
		}
		return 1;
	}

	for (int i = 0; i < SGP_shadersstate.programs[cur_program_index].num_shaders; i++) {
		int32_t cur_shader_index = SGP_shadersstate.programs[cur_program_index].attached_shader_index[i];
		if ((SGP_shadersstate.shaders[cur_shader_index].status & SGP_SHADERS_SHADER_COMPILED) == 0) {
			if (SGPconfig->driverMode & SGP_STDOUT) {
				printf("SGP_glLinkProgram: warning, cannot link program with uncompiled shaders\n");
			}
			return 1;
		}
	}

	// For each shader, copy the sgp_bin to the base address in memory, and update the starting PC (baseaddr)
	uint32_t baseaddr = SGP_shadersstate.program_baseaddr;//SGP_graphicsmap[SGP_SHADERS].baseaddr;
	uint32_t shader_ptr_offset = 0;
	for (int i = 0; i < SGP_shadersstate.programs[cur_program_index].num_shaders; i++) {
		int32_t cur_shader_index = SGP_shadersstate.programs[cur_program_index].attached_shader_index[i];
		if (SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len == 0) {
			if (SGPconfig->driverMode & SGP_STDOUT) {
				printf("SGP_glLinkProgram: warning, cannot link program with shader binary of length 0\n");
			}
			return 1;
		}

		// This should be done via burst requests, vs sending the data over word by word. sgp_bin_len is measured in words
#define MAX_SHADER_PROGRAM_BURST 256
		uint32_t num_bursts = ((uint32_t) SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len) / MAX_SHADER_PROGRAM_BURST;
		uint32_t burst_length = MAX_SHADER_PROGRAM_BURST;
		uint32_t last_burst_length = ((uint32_t) SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len) % MAX_SHADER_PROGRAM_BURST;
		if (last_burst_length != 0) {
			num_bursts++;
		}

		for (uint32_t ii = 0; ii < num_bursts; ii++) {
			if ((last_burst_length != 0) && (ii == num_bursts - 1)) {
				burst_length = last_burst_length;
			}
			SGP_AXI_set_writeburstlength(burst_length, &(SGPconfig->writerequest));
			SGPconfig->writerequest.AWHeader.AxAddr.i = baseaddr + shader_ptr_offset + 4 * ii * MAX_SHADER_PROGRAM_BURST;

			for (uint32_t j = 0; j < burst_length; j++) {
				SGPconfig->writerequest.WDATA[j].AWData.i = SGP_shadersstate.shaders[cur_shader_index].sgp_bin[j + ii * MAX_SHADER_PROGRAM_BURST];
			}
			SGP_sendWrite(SGPconfig, &(SGPconfig->writerequest), &(SGPconfig->writeresponse), SGP_WAITFORRESPONSE);
		}
		SGP_shadersstate.shaders[cur_shader_index].baseaddr = baseaddr + shader_ptr_offset;
		SGP_shadersstate.program_baseaddr += (uint32_t) SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len * 4;
		shader_ptr_offset += (uint32_t) SGP_shadersstate.shaders[cur_shader_index].sgp_bin_len * 4;
	}

	SGP_shadersstate.programs[cur_program_index].status |= SGP_SHADERS_PROGRAM_LINKED;

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glLinkProgram: Linked program (index=%d)\n", cur_program_index);
	}

	return 0;
}

// Let the vertex and fragment shader cores know to get started
int SGP_glUseProgram(GLuint gl_programID) {

	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VERTEXSHADER].baseaddr + SGP_AXI_VERTEXSHADER_IFLUSH, 69);
	SGP_write32(SGPconfig, SGP_graphicsmap[SGP_VERTEXSHADER].baseaddr + SGP_AXI_VERTEXSHADER_IFLUSH, 0);

	int32_t cur_program_index;

	cur_program_index = SGP_lookupProgram(gl_programID);
	if (cur_program_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glUseProgram: called with ID %d which is not a valid gl_programID\n", (int) gl_programID);
		}
		return 1;
	}

	// Update the vertex shader core PC value.
	for (int i = 0; i < SGP_shadersstate.programs[cur_program_index].num_shaders; i++) {
		int32_t cur_shader_index = SGP_shadersstate.programs[cur_program_index].attached_shader_index[i];
		if (SGP_shadersstate.shaders[cur_shader_index].gl_type == GL_VERTEX_SHADER) {
			uint32_t baseaddr = SGP_graphicsmap[SGP_VERTEXSHADER].baseaddr;
			if (SGPconfig->driverMode & SGP_STDOUT) {
				printf("SGP_glUseProgram: setting vertex shader starting PC to 0x%08x\n", SGP_shadersstate.shaders[cur_shader_index].baseaddr);
			}
			SGP_write32(SGPconfig, baseaddr + SGP_AXI_VERTEXSHADER_PC, SGP_shadersstate.shaders[cur_shader_index].baseaddr);
			break;
		}
	}

	SGP_shadersstate.programs[cur_program_index].status |= SGP_SHADERS_PROGRAM_USED;

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glUseProgram: Used program (index=%d)\n", cur_program_index);
	}

	return 0;
}


// Store the shader source into a single string in the shader object
int SGP_glShaderSource(GLuint gl_shaderID, GLsizei count, const GLchar* const* string, const GLint* length) {

	int32_t cur_shader_index = SGP_lookupShader(gl_shaderID);
	if (cur_shader_index == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glShaderSource: called with ID %d which is not a valid gl_shaderID\n", (int) gl_shaderID);
		}
		return 1;
	}

	// There are several options with how the source strings could be presented. From the OpenGL spec:
	/* ~The number of strings in the array is specified by count. If length is NULL, each string is assumed to be 
	 * null terminated. If length is a value other than NULL, it points to an array containing a string length for
	 * each of the corresponding elements of string. Each element in the length array may contain the length of the
	 * corresponding string (the null character is not counted as part of the string length) or a value less than 
	 * 0 to indicate that the string is null terminated.~
	 */
	uint32_t cur_string_length;
	uint32_t tot_string_length = 0;
	uint8_t glsl_string_nullterm = 0;
	if (length == NULL) {
		glsl_string_nullterm = 1;
	}

	for (int i = 0; i < (int) count; i++) {
		if (glsl_string_nullterm == 1) {
			cur_string_length = strlen(string[i]);
		} else {
			if (length[i] < 0) {
				cur_string_length = strlen(string[i]);
			} else {
				cur_string_length = length[i];
			}
		}
		tot_string_length += cur_string_length;
		SGP_shadersstate.shaders[cur_shader_index].glsl_src = (char*) realloc(SGP_shadersstate.shaders[cur_shader_index].glsl_src, tot_string_length);
		strcpy(SGP_shadersstate.shaders[cur_shader_index].glsl_src + tot_string_length - cur_string_length, string[i]);
	}

	SGP_shadersstate.shaders[cur_shader_index].status |= SGP_SHADERS_SHADER_SOURCED;

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glShaderSource: Loaded GLSL source: \n%s\n", SGP_shadersstate.shaders[cur_shader_index].glsl_src);
	}

	return 0;
}

// We have to use the gl_GetUniformLocation results which future cals to glUniform* will be expecting
int SGP_glGetUniformLocation(GLuint gl_programID, GLint gl_uniformID, const GLchar* name) {

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glGetUniformLocation: associating in uniformID %d with uniform %s in program (%d)\n", gl_uniformID, name, gl_programID);
	}

	for (int32_t i = 0; i < SGP_shadersstate.num_uniforms; i++) {
		if (!strcmp(SGP_shadersstate.uniforms[i].name, name)) {
			SGP_shadersstate.uniforms[i].gl_uniformID = gl_uniformID;
			return 0;
		}
	}

	if (SGPconfig->driverMode & SGP_STDOUT) {
		printf("SGP_glGetUniformLocation: called with gl_uniformID=%d which is not a valid gl_uniformID\n", (int) gl_uniformID);
	}
	return -1;
}


// Update the uniform at location (in the shader). Note that this function does not take uniform cache into consideration
void SGP_glUniform1f(GLint location, GLfloat v0) {
	int32_t sgp_uniform_loc = SGP_lookupUniform(location);
	if (sgp_uniform_loc == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glUniform1f: called with location=%d which is not a valid uniform location\n", (int) location);
		}
		return;
	}

	uint32_t baseaddr = SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr;
	sglu_fixed_t v0_fixed = sglu_float_to_fixed(v0, 16);

	if (SGPconfig->driverMode & SGP_DEEP) {
		printf("SGP_glUniform1f: updating uniform %s at address 0x%08x with value %f = 0x%08x\n",
		       SGP_shadersstate.uniforms[sgp_uniform_loc].name,
		       SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr,
		       v0,
		       v0_fixed);
	}

	SGP_write32(SGPconfig, baseaddr, (uint32_t) v0_fixed);
}


// Update the uniform at location (in the shader). Note that this function does not take uniform cache into consideration
void SGP_glUniform4fv(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3) {

	int32_t sgp_uniform_loc = SGP_lookupUniform(location);
	if (sgp_uniform_loc == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glUniform4fv: called with location=%d which is not a valid uniform location\n", (int) location);
		}
		return;
	}


	uint32_t baseaddr = SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr;
	sglu_fixed_t v0_fixed = sglu_float_to_fixed(v0, 16);
	sglu_fixed_t v1_fixed = sglu_float_to_fixed(v1, 16);
	sglu_fixed_t v2_fixed = sglu_float_to_fixed(v2, 16);
	sglu_fixed_t v3_fixed = sglu_float_to_fixed(v3, 16);

	if (SGPconfig->driverMode & SGP_DEEP) {
		printf("SGP_glUniform4fv: updating uniform %s at address 0x%08x with value [%f = 0x%08x, %f = 0x%08x, %f = 0x%08x, %f = 0x%08x]\n",
		       SGP_shadersstate.uniforms[sgp_uniform_loc].name,
		       SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr,
		       v0,
		       v0_fixed,
		       v1,
		       v1_fixed,
		       v2,
		       v2_fixed,
		       v3,
		       v3_fixed);
	}

	SGP_write32(SGPconfig, baseaddr + 0, (uint32_t) v0_fixed);
	SGP_write32(SGPconfig, baseaddr + 1, (uint32_t) v1_fixed);
	SGP_write32(SGPconfig, baseaddr + 2, (uint32_t) v2_fixed);
	SGP_write32(SGPconfig, baseaddr + 3, (uint32_t) v3_fixed);
}

// Update the uniform at location (in the shader). Note that this function does not take uniform cache into consideration
void SGP_glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value) {

	int32_t sgp_uniform_loc = SGP_lookupUniform(location);
	if (sgp_uniform_loc == -1) {
		if (SGPconfig->driverMode & SGP_STDOUT) {
			printf("SGP_glUniformMatrix4fv: called with location=%d which is not a valid uniform location\n", (int) location);
		}
		return;
	}

	uint32_t baseaddr = SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr;
	for (int i = 0; i < 16 * count; i++) {
		SGP_write32(SGPconfig, baseaddr + i, (uint32_t) sglu_float_to_fixed(value[i], 16));
	}

	if (SGPconfig->driverMode & SGP_DEEP) {
		printf("SGP_glUniformMatrix4fv: updating uniform %s at address 0x%08x\n",
		       SGP_shadersstate.uniforms[sgp_uniform_loc].name,
		       SGP_shadersstate.uniforms[sgp_uniform_loc].baseaddr);
	}
}

// Utility function - lookup which index corresponds to the OpenGL program ID. Returns -1 if no match
int32_t SGP_lookupProgram(GLuint gl_programID) {

	for (int32_t i = 0; i < SGP_shadersstate.num_programs; i++) {
		if (SGP_shadersstate.programs[i].gl_programID == gl_programID) {
			return i;
		}
	}
	return -1;
}


// Utility function - lookup which index corresponds to the OpenGL shader ID. Returns -1 if no match
int32_t SGP_lookupShader(GLuint gl_shaderID) {

	for (int32_t i = 0; i < SGP_shadersstate.num_shaders; i++) {
		if (SGP_shadersstate.shaders[i].gl_shaderID == gl_shaderID) {
			return i;
		}
	}
	return -1;
}


// Utility function - lookup which index corresponds to the OpenGL uniform ID. Returns -1 if no match
int32_t SGP_lookupUniform(GLuint gl_uniformID) {

	for (int32_t i = 0; i < SGP_shadersstate.num_uniforms; i++) {
		if (SGP_shadersstate.uniforms[i].gl_uniformID == gl_uniformID) {
			return i;
		}
	}
	return -1;
}
