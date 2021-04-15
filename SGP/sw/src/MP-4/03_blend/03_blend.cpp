/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 01_TheRedTriangle - draws a blue triangle, obviously. 
 *
 *
 * NOTES:
 * 12/09/20 by JAZ::Design created.
 *****************************************************************************/

#include <cstdio>
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <shader.hpp>

GLFWwindow* window;

int main() {

	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	}

	window = glfwCreateWindow(1280, 1024, "Blender", nullptr, nullptr);
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

	// Dark blue background
	glClearColor(1, 1, 1, 1);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	glEnable(GL_BLEND);
	glDepthRange(0.0, 1.0);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders("../common/shaders/passthrougha.vert", "../common/shaders/passthrough.frag");

	// Just a single triangle for GL_TRIANGLES to test. Add to this to draw more points
	static const GLfloat g_vertex_buffer_data[] = {
			-0.6f, -0.6f, 1.0f, //bl
			 0.0f,  0.6f, 0.0f, //top
			 0.6f, -0.6f, 1.0f, //br

			-0.95f,  0.95f, 1.0f, //tl
			 0.95f,  0.95f, 1.0f, //tr
			 0.0f, -0.95f, 0.0f, //bot
	};

	// One color (RGB for this) for each vertex.
	static const GLfloat g_color_buffer_data[] = {
			1.0f, 0.0f, 0.0f, 1,
			0.0f, 1.0f, 0.0f, 1,
			0.0f, 0.0f, 1.0f, 1,

			0.57f, 0.08f, 0.47f, 0,
			0.57f, 0.08f, 0.47f, 0,
			0, 0, 0, 1,
	};

	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);


	while (glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0) {

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glUseProgram(programID);

		// 1st attribute buffer : vertices
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*) nullptr);

		// 2nd attribute buffer : colors
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, (void*) nullptr);

		// Draw the triangle!
		glDrawArrays(GL_TRIANGLES, 0, 6); // 3 index starting at 0

		glDisableVertexAttribArray(0);
		glDisableVertexAttribArray(1);

		glfwPollEvents();
		glfwSwapBuffers(window);
	}

	glfwTerminate();
	return 0;

}
