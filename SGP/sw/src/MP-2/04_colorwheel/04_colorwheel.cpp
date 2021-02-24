/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 04_colorwheel - interactive color choosing wheel application. Similar to 
 * the color finder utility in the GIMP graphics editor. 
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




#define PI 3.1415927
#define O_RADIUS 0.975
#define I_RADIUS 0.775
#define C_RADIUS 0.015
#define NUM_POINTS 128
#define INIT_WIDTH 1024
#define INIT_HEIGHT 1024


float angle = 0.0;

int mouse = 0;
int window_width = INIT_WIDTH;
int window_height = INIT_HEIGHT;

// 2*(NUM_POINTS+1) points for the wheel, +3 for the center triangle, +50 for the little ring
const int total_points = 2*(NUM_POINTS+1)+3+50;
static GLfloat g_vertex_buffer_data[2*total_points]; 

// One color (RGB for this) for each vertex.
static GLfloat g_color_buffer_data[3*total_points];

GLuint vertexbuffer;
GLuint colorbuffer;

void updateBuffers();

void myMotionMouse(GLFWwindow* window, double xpos, double ypos) {

	int x = (int)xpos;
	int y = (int)ypos;
	
	int midpos_x, midpos_y;


	// If the left-button is held, calculate the angle we are at (note that
	// technically x and y can be negative)
	if (mouse == 1) {
		midpos_x = window_width / 2;
		midpos_y = window_height / 2;
		if (x == midpos_x) {
			angle = -PI / 2;
		}
		else {
			angle = atan(1.0*(midpos_y - y) / (x - midpos_x)) - PI / 2;
		}

		if (x < midpos_x) {
			angle += PI;
		}
		updateBuffers();
	}
}


void myMouse(GLFWwindow* window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
		if (action == GLFW_PRESS) {
	        mouse = 1;
			double xpos, ypos;
	        glfwGetCursorPos(window, &xpos, &ypos);
			myMotionMouse(window, xpos, ypos);        
		}
		else {
			mouse = 0;
		} 
	}
}


void updateBuffers() {


	// Provide values for g_vertex_buffer_data and g_color_buffer_data
	// Draw the external ring (fixed)
	float ang = 0.0;
	float red = 1.0; float green = 0.0; float blue = 0.0;
	float x1, y1, x2, y2;
	for (int i = 0; i < NUM_POINTS+1; i++) {

    	// Start from red to yellow
    	if (ang < PI/3) {
			green += 6.0/NUM_POINTS;
		}
    	// Go from yellow to green
    	else if (ang < 2*PI/3) {
			red -= 6.0/NUM_POINTS;
	    }
    	// Go from green to cyan
    	else if (ang < PI) {
    	  	blue += 6.0/NUM_POINTS;
	    }
    	// Go from cyan to blue
    	else if (ang < 4*PI/3) {
      		green -= 6.0/NUM_POINTS;
    	}
    	// Go from blue to magenta
    	else if (ang < 5*PI/3) {
      		red += 6.0/NUM_POINTS;
    	}
    	// Go from magenta to red
    	else {
      		blue -= 6.0/NUM_POINTS;
    	}

		g_color_buffer_data[6*i] = red;
		g_color_buffer_data[6*i+1] = green;
		g_color_buffer_data[6*i+2] = blue;
		g_color_buffer_data[6*i+3] = red;
		g_color_buffer_data[6*i+4] = green;
		g_color_buffer_data[6*i+5] = blue;

		x1 = I_RADIUS*sin(ang);
		y1 = I_RADIUS*cos(ang);
    	x2 = O_RADIUS*sin(ang);
    	y2 = O_RADIUS*cos(ang);
		g_vertex_buffer_data[4*i] =   x1;
		g_vertex_buffer_data[4*i+1] = y1;
		g_vertex_buffer_data[4*i+2] = x2;
		g_vertex_buffer_data[4*i+3] = y2;

		ang += 2*PI/NUM_POINTS;
	}


	// The color triangle is dependent on the global angle. Similar color calculation
	red = 0.0, green = 0.0, blue = 0.0;
	if (angle <= 0) {
		ang = -angle;
  	}
  	else {
    	ang = 2*PI-angle;
  	}	  
	// Start from red to yellow
	if (ang < PI/3) {
		red = 1.0;
		green = ang*3/PI;
	}
	// Go from yellow to green
	else if (ang < 2*PI/3) {
		green = 1.0;
		red = 1.0-(ang-PI/3)*3/PI;
	}
	// Go from green to cyan
	else if (ang < PI) {
		green = 1.0;
		blue = (ang-2*PI/3)*3/PI;
	}
	// Go from cyan to blue
	else if (ang < 4*PI/3) {
		blue = 1.0;
		green = 1-(ang-PI)*3/PI;
	}
	// Go from blue to magenta
	else if (ang < 5*PI/3) {
		blue = 1.0;
		red = (ang-4*PI/3)*3/PI;
	}
    // Go from magenta to red
	else {
		red = 1.0;
		blue = 1-(ang-5*PI/3)*3/PI;
	}

	int index = 2*(NUM_POINTS+1);
	g_color_buffer_data[3*index] = red;
	g_color_buffer_data[3*index+1] = green;
	g_color_buffer_data[3*index+2] = blue;
	g_vertex_buffer_data[2*index] =  -I_RADIUS*sin(angle+0.0);
	g_vertex_buffer_data[2*index+1] = I_RADIUS*cos(angle+0.0);


	// Make the second vertex white
	index++;
	g_color_buffer_data[3*index] = 1.0;
	g_color_buffer_data[3*index+1] = 1.0;
	g_color_buffer_data[3*index+2] = 1.0;
	g_vertex_buffer_data[2*index] =  -I_RADIUS*sin(angle+2*PI/3);
	g_vertex_buffer_data[2*index+1] = I_RADIUS*cos(angle+2*PI/3);

	// Make the third vertex black
	index++;
	g_color_buffer_data[3*index] = 0.0;
	g_color_buffer_data[3*index+1] = 0.0;
	g_color_buffer_data[3*index+2] = 0.0;
	g_vertex_buffer_data[2*index] =  -I_RADIUS*sin(angle+4*PI/3);
	g_vertex_buffer_data[2*index+1] = I_RADIUS*cos(angle+4*PI/3);


	// Draw a position circle
	index++;
	ang = 0.0;
	for (int i = 0; i < 25; i++) {

		g_color_buffer_data[3*(index+2*i)] = 1.0;
		g_color_buffer_data[3*(index+2*i)+1] = 1.0;
		g_color_buffer_data[3*(index+2*i)+2] = 1.0;
		g_color_buffer_data[3*(index+2*i)+3] = 1.0;
		g_color_buffer_data[3*(index+2*i)+4] = 1.0;
		g_color_buffer_data[3*(index+2*i)+5] = 1.0;

		x1 = C_RADIUS*cos(ang) - (O_RADIUS-I_RADIUS)/2*sin(angle) - I_RADIUS*sin(angle);
		y1 = C_RADIUS*sin(ang) + (O_RADIUS-I_RADIUS)/2*cos(angle) + I_RADIUS*cos(angle);
    	x2 = 1.45*C_RADIUS*cos(ang) - (O_RADIUS-I_RADIUS)/2*sin(angle) - I_RADIUS*sin(angle);
    	y2 = 1.45*C_RADIUS*sin(ang) + (O_RADIUS-I_RADIUS)/2*cos(angle) + I_RADIUS*cos(angle);

		g_vertex_buffer_data[2*(index+2*i)] =   x1;
		g_vertex_buffer_data[2*(index+2*i)+1] = y1;
		g_vertex_buffer_data[2*(index+2*i)+2] = x2;
		g_vertex_buffer_data[2*(index+2*i)+3] = y2;
	    ang += 2*PI/24;


	}

	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);


	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);
	glEnableVertexAttribArray(1);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);


	return;
}

int main() {
  
	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 

	window = glfwCreateWindow(INIT_WIDTH, INIT_HEIGHT, "Color Chooser", NULL, NULL);
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


	// Light gray background
	glClearColor(0.706f, 0.706f, 0.706f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag" );
	glUseProgram(programID);


	glGenBuffers(1, &vertexbuffer);
	glGenBuffers(1, &colorbuffer);


	updateBuffers();




	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
   
    	glClear(GL_COLOR_BUFFER_BIT);


		glDrawArrays(GL_TRIANGLE_STRIP, 0, 2*(NUM_POINTS+1)); 
		glDrawArrays(GL_TRIANGLES, 2*(NUM_POINTS+1), 3); 
		glDrawArrays(GL_TRIANGLE_STRIP, 2*(NUM_POINTS+1)+3, 50); 
    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

  	glfwTerminate();
  	return 0;

}
