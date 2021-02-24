/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 03_Sierpinski - draws a 2D Sierpinski gasket. 
 *
 *
 * NOTES:
 * 11/19/20 by JAZ::Design created.
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

  window = glfwCreateWindow(1280, 1024, "Sierpinski", NULL, NULL);
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

	// Black background
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/bigpoints.vert", "../common/shaders/passthrough.frag" );

	#define TOTAL_POINTS 75000
	static GLfloat g_vertex_buffer_data[3*TOTAL_POINTS]; 

	// One color (RGB for this) for each vertex.
	static GLfloat g_color_buffer_data[3*TOTAL_POINTS];


       static const GLfloat initial_points[12] = {
                -1.0, -1.0, 0.0,
                0.0, 1.0, 0.0,
                1.0, -1.0, 0.0,
                0.5, 0.5, 0.0};
        static const GLfloat initial_colors[3] = {
                0.0, .98, 0.0};

        int i, j;
        for (i = 0; i < 12; i++) {
                g_vertex_buffer_data[i] = initial_points[i];
                g_color_buffer_data[i] = initial_colors[i%3];
        }

        for (i = 4; i < TOTAL_POINTS; i++) {
                j = rand()%3;
                g_vertex_buffer_data[3*i] = (initial_points[3*j]+g_vertex_buffer_data[3*(i-1)])/2;
                g_vertex_buffer_data[3*i+1] = (initial_points[3*j+1]+g_vertex_buffer_data[3*(i-1)+1])/2;
                g_vertex_buffer_data[3*i+2] = 0.0f;
                g_color_buffer_data[3*i] = g_color_buffer_data[0];
                g_color_buffer_data[3*i+1] = g_color_buffer_data[1];
                g_color_buffer_data[3*i+2] = g_color_buffer_data[2];
	}




	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);

	// It can be hard to see single pixels at a time.
	glEnable(GL_PROGRAM_POINT_SIZE);


	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
   
    		glClear(GL_COLOR_BUFFER_BIT);
		glUseProgram(programID);

		// 1st attribute buffer : vertices
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// 2nd attribute buffer : colors
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// Draw the points
		glDrawArrays(GL_POINTS, 0, TOTAL_POINTS); // TOTAL_POINTS points starting at 0

		glDisableVertexAttribArray(0);
		glDisableVertexAttribArray(1);

    glfwPollEvents();
    glfwSwapBuffers(window);

  }

  glfwTerminate();
  return 0;

}
