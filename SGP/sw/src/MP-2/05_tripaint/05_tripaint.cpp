/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 06_TheRedTriangle - interactive triangle painting application. 
 *
 *
 * NOTES:
 * 12/15/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <GL/glew.h> 
#include <GLFW/glfw3.h> 
GLFWwindow* window;

#include <shader.hpp>


#define WINDOW_WIDTH 1024
#define WINDOW_HEIGHT 800
#define ERR_TOL 0.05


// Define a simple vertex and triangle type
typedef struct vert {
  float pos[2];
  float color[3];
} vert_t;
typedef struct tri {
  vert_t v[3];
} tri_t;

#define MAX_TRIANGLES 1
tri_t triangles[MAX_TRIANGLES];

void updateBuffers();

// Start with a small white triangle
void initTriangle() {
	triangles[0].v[0].pos[0] = -0.3;
	triangles[0].v[0].pos[1] = -0.3;
	triangles[0].v[1].pos[0] = 0.0;
	triangles[0].v[1].pos[1] = 0.3;
	triangles[0].v[2].pos[0] = 0.3;
	triangles[0].v[2].pos[1] = -0.3;

	for (int i = 0; i < 3; i++) {
		triangles[0].v[i].color[0] = 1.0;
		triangles[0].v[i].color[1] = 1.0;
		triangles[0].v[i].color[2] = 1.0;
	}

}

GLfloat g_vertex_buffer_data[6*MAX_TRIANGLES]; 
GLfloat g_color_buffer_data[9*MAX_TRIANGLES];

GLuint vertexbuffer;
GLuint colorbuffer;


int mouse = 0;
int hold_count = 0;
int active_vertex = -1;
int active_triangle = -1;


void myMotionMouse(GLFWwindow* window, double xpos_window, double ypos_window) {

	float xpos = (float)2.0*xpos_window/WINDOW_WIDTH-1.0;
	float ypos = (float)(1.0-2.0*ypos_window/WINDOW_HEIGHT);

	// Move the vertex to the current coordinates in normalized device coordinates

	if ((active_triangle >= 0) && (active_vertex >= 0)) {
		if (mouse == 1) {
			triangles[active_triangle].v[active_vertex].pos[0] = xpos;
			triangles[active_triangle].v[active_vertex].pos[1] = ypos;
		}
		if (mouse == 2) {
			hold_count++;
			int red = (int)triangles[active_triangle].v[active_vertex].color[0]*255;
			int green = (int)triangles[active_triangle].v[active_vertex].color[0]*255;
			int blue = (int)triangles[active_triangle].v[active_vertex].color[0]*255;
			red += hold_count; red %= 255;
			green += 2*hold_count; green %= 255;
			blue += 3*hold_count; blue %= 255;
			triangles[active_triangle].v[active_vertex].color[0] = (red/255.0);
			triangles[active_triangle].v[active_vertex].color[1] = (green/255.0);
			triangles[active_triangle].v[active_vertex].color[2] = (blue/255.0);
		}
		updateBuffers();
	}
}


// Based on our position, see if there is a close enough vertex
void myMouse(GLFWwindow* window, int button, int action, int mods) {

	double xpos_window, ypos_window;

	glfwGetCursorPos(window, &xpos_window, &ypos_window);
	float xpos = (float)2.0*xpos_window/WINDOW_WIDTH-1.0;
	float ypos = (float)(1.0-2.0*ypos_window/WINDOW_HEIGHT);

	int closest_vertex = -1;
	int closest_triangle = -1;
	for (int i = 0; i < MAX_TRIANGLES; i++) {
		for (int j = 0; j < 3; j++) {
			if ((fabs(triangles[i].v[j].pos[0]-xpos) < ERR_TOL) && (fabs(triangles[i].v[j].pos[1]-ypos) < ERR_TOL)) {
				closest_triangle = i;
				closest_vertex = j;
				break;
			}
		}
	}

	// If the left mouse is pressed, we can start moving the active vertex around
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
		if (action == GLFW_PRESS) {
	        mouse = 1;
			active_triangle = closest_triangle;
			active_vertex = closest_vertex;
			myMotionMouse(window, xpos_window, ypos_window);        
		}
		else {
			mouse = 0;
			active_triangle = -1;
			active_vertex = -1;
		} 
	}

	// If the right mouse is pressed, we can start changing the vertex color
    if (button == GLFW_MOUSE_BUTTON_RIGHT) {
		if (action == GLFW_PRESS) {
	        mouse = 2;
			active_triangle = closest_triangle;
			active_vertex = closest_vertex;
			myMotionMouse(window, xpos_window, ypos_window);        
		}
		else {
			mouse = 0;
			hold_count = 0;
			active_triangle = -1;
			active_vertex = -1;
		} 
	}


}



void updateBuffers() {

	int vert_index = 0;
	int color_index = 0;
	for (int i = 0; i < MAX_TRIANGLES; i++) {
		for (int j = 0; j < 3; j++) {
			g_vertex_buffer_data[vert_index++] = triangles[i].v[j].pos[0];
			g_vertex_buffer_data[vert_index++] = triangles[i].v[j].pos[1];
			g_color_buffer_data[color_index++] = triangles[i].v[j].color[0];
			g_color_buffer_data[color_index++] = triangles[i].v[j].color[1];
			g_color_buffer_data[color_index++] = triangles[i].v[j].color[2];
		}
	}


	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);

	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);
	glEnableVertexAttribArray(1);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	return;
}


int main() {
	
	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 

	window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Triangle Paint", NULL, NULL);
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

	// Measure mouse motion and inputs
	glfwSetCursorPosCallback(window, myMotionMouse);
	glfwSetMouseButtonCallback(window, myMouse);


	// Black background
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag" );
	glUseProgram(programID);

	glGenBuffers(1, &vertexbuffer);
	glGenBuffers(1, &colorbuffer);

	initTriangle();
	updateBuffers();

	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
   
    	glClear(GL_COLOR_BUFFER_BIT);

		// Draw the triangle!		
		glDrawArrays(GL_TRIANGLES, 0, 3); 

    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

  	glfwTerminate();
  	return 0;

}
