/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 03_rand_triangles - displays a few randomly generated triangles. 
 *
 *
 * NOTES:
 * 12/13/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>

#include <GL/glew.h> 
#include <GLFW/glfw3.h> 
GLFWwindow* window;

#include <shader.hpp>



int main() {
  
  if (!glfwInit()) {
    fprintf(stderr, "ERROR: could not start GLFW3\n");
    return 1;
  } 

  window = glfwCreateWindow(1280, 1024, "Random Triangles", NULL, NULL);
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

	// Light gray background
	glClearColor(0.85f, 0.85f, 0.85f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag" );

	#define NUM_TRIANGLES 256
	static GLfloat g_vertex_buffer_data[9*NUM_TRIANGLES]; 

	// One color (RGB for this) for each vertex.
	static GLfloat g_color_buffer_data[9*NUM_TRIANGLES];

	for (int i = 0; i < NUM_TRIANGLES; i++) {

		for (int j = 0; j < 9; j++) {
			float pos1, col1;

			// Note: if the three points are colinear, this will not work. 
			// This also explicitly sets z=0.0 to not test depth checking. 
			pos1 = (rand()/(float)RAND_MAX)*(1.8) - 0.9;
			col1 = (rand()/(float)RAND_MAX);
			if (j % 3 == 2) {
				g_vertex_buffer_data[9*i+j] = 0.0;
			}
			else {
				g_vertex_buffer_data[9*i+j] = pos1;
			}
			g_color_buffer_data[9*i+j] = col1;
			printf("Pos1 - %f, Col1 - %f\n", pos1, col1);
		}
	}


	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);


	// 1st attribute buffer : vertices
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	// 2nd attribute buffer : colors
	glEnableVertexAttribArray(1);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);


	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
   
    	glClear(GL_COLOR_BUFFER_BIT);
		glUseProgram(programID);
		glDrawArrays(GL_TRIANGLES, 0, 3*NUM_TRIANGLES); 
    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

  	glfwTerminate();
  	return 0;

}
