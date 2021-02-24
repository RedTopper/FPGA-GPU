/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 02_snowflake - implements a Koch snowflake using GL_TRIANGLES. It's 
 * an ugly piece of code - don't try to understand it, just check that the
 * triangles that it spits out are getting rendered properly by your design. 
 *
 *
 * NOTES:
 * 12/13/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <GL/glew.h> 
#include <GLFW/glfw3.h> 
GLFWwindow* window;

#include <shader.hpp>


#define MIN_LENGTH 0.005
#define PI 3.1415927
#define WIDTH 1.6
#define MAX_TRIANGLES 1024

typedef struct {
  float x;
  float y;
} vertex;

typedef struct {
  vertex v[3];
} triangle;
  

int iter_count = 0;
int vertex_ptr = 0;
int color_ptr = 0;
static GLfloat g_vertex_buffer_data[3*MAX_TRIANGLES]; 
static GLfloat g_color_buffer_data[3*MAX_TRIANGLES];


void draw_snowflake(triangle tri, float angle) {

	int i;
	float deltax, deltay, length;
	triangle one, two, three, four, five;
  
  	// Calculate the length of one of the sides. If less than MIN_LENGTH, return 
	deltax = tri.v[0].x - tri.v[1].x;
	deltay = tri.v[0].y - tri.v[1].y;
	length = sqrt(deltax*deltax + deltay*deltay);

	printf("Drawing tri at (%f, %f), (%f, %f), (%f, %f), with length %f\n", tri.v[0].x, 
	tri.v[0].y, tri.v[1].x, tri.v[1].y, tri.v[2].x, tri.v[2].y, length);

	if (length < MIN_LENGTH) {
		return;
  	}

	if ((vertex_ptr % 9) >= MAX_TRIANGLES-1) {
		return;
	}

	// Draw the current triangle
	for (i = 0; i < 3; i++) {
		g_vertex_buffer_data[vertex_ptr++] = tri.v[i].x;
		g_vertex_buffer_data[vertex_ptr++] = tri.v[i].y;
		g_vertex_buffer_data[vertex_ptr++] = 0.0;
		g_color_buffer_data[color_ptr++] = 1.0f;
		g_color_buffer_data[color_ptr++] = 1.0f;
		g_color_buffer_data[color_ptr++] = 1.0f;
	}

	// Otherwise, draw three more triangles of 1/3 the current length
	one.v[0].x = tri.v[0].x + length/3 * cos(angle + PI/3);
	one.v[0].y = tri.v[0].y + length/3 * sin(angle + PI/3);
	one.v[1].x = one.v[0].x + length/3 * cos(angle + 2*PI/3);
	one.v[1].y = one.v[0].y + length/3 * sin(angle + 2*PI/3);
	one.v[2].x = tri.v[0].x + 2*length/3 * cos(angle + PI/3);
	one.v[2].y = tri.v[0].y + 2*length/3 * sin(angle + PI/3);

	two.v[0].x = tri.v[2].x + 2*length/3 * cos(angle + 2*PI/3);
	two.v[0].y = tri.v[2].y + 2*length/3 * sin(angle + 2*PI/3);
	two.v[2].x = tri.v[2].x + length/3 * cos(angle + 2*PI/3);
	two.v[2].y = tri.v[2].y + length/3 * sin(angle + 2*PI/3);
	two.v[1].x = two.v[2].x + length/3 * cos(angle + PI/3);
	two.v[1].y = two.v[2].y + length/3 * sin(angle + PI/3);

	three.v[0].x = tri.v[0].x + 2*length/3 * cos(angle);
	three.v[0].y = tri.v[0].y + 2*length/3 * sin(angle);
	three.v[2].x = tri.v[0].x + length/3 * cos(angle);
	three.v[2].y = tri.v[0].y + length/3 * sin(angle);
	three.v[1].x = three.v[2].x + length/3 * cos(angle + PI/3);
	three.v[1].y = three.v[2].y - length/3 * sin(angle + PI/3);

	if (iter_count++ == 0) {
		draw_snowflake(three, angle-PI); 
		four.v[0] = one.v[1];
		four.v[1] = two.v[1];
		four.v[2] = three.v[1];
		draw_snowflake(four, angle-PI/3);

		five.v[0] = three.v[1];
		five.v[1] = one.v[1];
		five.v[2] = two.v[1];
		draw_snowflake(five, angle+PI/3);
	}
  
  	draw_snowflake(one, angle+PI/3);
	draw_snowflake(two, angle-PI/3);
}


int main() {
  
  	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 

	window = glfwCreateWindow(1280, 1024, "Snowflake", NULL, NULL);
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
	GLuint programID = LoadShaders( "../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag" );


	triangle init;

	init.v[0].x = -WIDTH/2;
	init.v[0].y = -WIDTH/3;
	init.v[1].x = 0;
	init.v[1].y = WIDTH*sqrt(3)/2-WIDTH/3;
	init.v[2].x = WIDTH/2;
	init.v[2].y = -WIDTH/3;

	draw_snowflake(init, 0.0);


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
		glDrawArrays(GL_TRIANGLES, 0, vertex_ptr); 
    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

  	glfwTerminate();
  	return 0;

}
