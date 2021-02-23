/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 02_TheRedPixel - draws a blue pixel, obviously. 
 *
 *
 * NOTES:
 * 11/19/20 by JAZ::Design created.
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
GLFWwindow *window;

#include <shader.hpp>

#define PI 3.14159265358979f
#define TAU (PI * 2.0f)

#define POINTS 1000
#define BAR 100

void points(float x, float y, float height, float rotation, float sides, GLfloat* array) {
	for(size_t i = 0; i < sides; i++) {
		array[i*3 + 0] = height * cos(rotation + (float)i * TAU/sides) + x;
		array[i*3 + 1] = height * sin(rotation + (float)i * TAU/sides + PI) + y;
		array[i*3 + 2] = 0.0f;
	}
}

void color(int pt, int sides, GLfloat* array, int ind) {
	for(int i = 0; i < sides; i++) {
		int dist1 = (pt - i) > 0 ? pt - i : i - pt;
		int dist2 = (pt - i + POINTS) > 0 ? pt - i + POINTS : 0;
		int dist3 = (pt - i - POINTS) > 0 ? 0 : i + POINTS - pt;
		
		int dist = dist1 > dist2 ? dist2 : dist1;
		dist = dist > dist3 ? dist3 : dist;
		
		float scale = dist <= BAR ? (float)(BAR - dist) / (float)BAR : 0;
		array[i*3 + ind] = scale;
	}
}

int main()
{

	if (!glfwInit())
	{
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	}

	window = glfwCreateWindow(1920, 1080, "Spinning N-Gons", NULL, NULL);
	if (!window)
	{
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
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders("../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag");

	// Just a single vertex for GL_POINTS to test. Add to this to draw more points
	GLfloat g_vertex_buffer_data[POINTS*3*2];

	// One color (RGB for this) for each vertex.
	GLfloat g_color_buffer_data[POINTS*3*2];
	
	points(0.0f, 0.0f, 0.2f, 0, POINTS, g_vertex_buffer_data);

	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data,  GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data,  GL_STATIC_DRAW);

	// It can be hard to see single pixels at a time.
	//glEnable(GL_PROGRAM_POINT_SIZE);

	int rotation = 0;

	while (glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glUseProgram(programID);
		
		rotation += 7;
		if (rotation > POINTS) rotation = 0;
		
		points(0.0f, 0.0f, 0.2f, 0, POINTS, g_vertex_buffer_data);
		color(rotation, POINTS, g_color_buffer_data, 0);
		color((rotation + POINTS / 3) % POINTS, POINTS, g_color_buffer_data, 1);
		color((rotation + POINTS / 3 * 2) % POINTS, POINTS, g_color_buffer_data, 2);
		
		glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data,  GL_STATIC_DRAW);

		// 1st attribute buffer : vertices
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void *)0);

		// 2nd attribute buffer : colors
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void *)0);

		// Draw the point!
		glDrawArrays(GL_POINTS, 0, POINTS); // 1 index starting at 0

		glDisableVertexAttribArray(0);
		glDisableVertexAttribArray(1);

		glfwPollEvents();
		glfwSwapBuffers(window);
	}

	glfwTerminate();
	return 0;
}


