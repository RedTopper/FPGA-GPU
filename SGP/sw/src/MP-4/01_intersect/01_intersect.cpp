#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string>
#include <cstring>
#include <vector>

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <shader.hpp>

GLFWwindow* window;

int main() {
	if (!glfwInit()) {
		const char* error;
		glfwGetError(&error);
		fprintf(stderr, "ERROR: could not start GLFW3: %s\n", error);
		return 1;
	} 

	window = glfwCreateWindow(1280, 1024, "Intersect", nullptr, nullptr);
	if (!window) {
		fprintf(stderr, "ERROR: could not open window with GLFW3\n");
		glfwTerminate();
		return 1;
	}
	glfwMakeContextCurrent(window);

	// start GLEW extension handler
	glewExperimental = GL_TRUE;
	glewInit();

	// Ensure we can capture the escape key being pressed below
	glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);

    glfwPollEvents();

	// Dark blue background
	glClearColor(0.0f, 0.0f, 0.1f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/vertexshifter.vert", "../common/shaders/passthrough.frag" );
	glUseProgram(programID);

	// Just a single triangle for GL_TRIANGLES to test. Add to this to draw more points
	static const GLfloat g_vertex_buffer_data[] = { 
		 -0.25f, -0.25f, 0.0f,
		 0.0f, 0.25f, 0.0f,
		 0.25f, -0.25f, 0.0f,
	};

	// One color (RGB for this) for each vertex.
	static const GLfloat g_color_buffer_data[] = { 
		1.0f, 0.0f, 0.0f,
		1.0f, 0.0f, 0.0f,
		1.0f, 0.0f, 0.0f,
	};

	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)nullptr);

	glEnableVertexAttribArray(1);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)nullptr);


	// Get a handle for our uniforms
	GLuint xoffsetID = glGetUniformLocation(programID, "xoffset");
	GLuint yoffsetID = glGetUniformLocation(programID, "yoffset");
	GLuint xscaleID = glGetUniformLocation(programID, "xscale"); 
	GLuint yscaleID = glGetUniformLocation(programID, "yscale"); 

	int frame_count = 0;
	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {

		// Set value for uniforms
		float xoffset = 0.75*sin(frame_count*M_PI/60);
		float yoffset = 0.75*sin(frame_count*M_PI/30);
		float xscale = cos(frame_count*M_PI/200);
		float yscale = cos(frame_count*M_PI/400);

		if (xscale < 0.05)
			xscale = 0.05;

		if (yscale < 0.05)
			yscale = 0.05;


		frame_count++;

		// Send our uniforms to the currently bound shader
		glUniform1f(xoffsetID, xoffset);
		glUniform1f(yoffsetID, yoffset);
		glUniform1f(xscaleID, xscale);
		glUniform1f(yscaleID, yscale);

    	glClear(GL_COLOR_BUFFER_BIT);

		glDrawArrays(GL_TRIANGLES, 0, 3);

    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

	glfwTerminate();

	return 0;
}

