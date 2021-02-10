/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 04_Fractals - Calculates a fractal image using a simple colormap. 
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
GLFWwindow* window;

#include <shader.hpp>


#define FRACTAL_WIDTH 1280
#define FRACTAL_HEIGHT 1024

// A point per pixel of resolution
GLfloat g_vertex_buffer_data[3*FRACTAL_WIDTH*FRACTAL_HEIGHT]; 

// One color (RGB for this) for each vertex.
GLfloat g_color_buffer_data[3*FRACTAL_WIDTH*FRACTAL_HEIGHT];

// Fractal init data
double xaxis[2] = {-2.0, 0.7};
double yaxis[2] = {-1.0, 1.0};

// Have our buffer objects be global
GLuint vertexbuffer, colorbuffer;

void update_fractal() {
 
  // Matlab default colormap. Feel free to modify
  double cmap[64][3] = {{0.0000, 0.0000, 0.5625}, 
			{0.0000, 0.0000, 0.6250},
			{0.0000, 0.0000, 0.6875},
			{0.0000, 0.0000, 0.7500},
			{0.0000, 0.0000, 0.8125},
			{0.0000, 0.0000, 0.8750},
			{0.0000, 0.0000, 0.9375},
			{0.0000, 0.0000, 1.0000},
			{0.0000, 0.0625, 1.0000},
			{0.0000, 0.1250, 1.0000},
			{0.0000, 0.1875, 1.0000},
			{0.0000, 0.2500, 1.0000},
			{0.0000, 0.3125, 1.0000},
			{0.0000, 0.3750, 1.0000},
			{0.0000, 0.4375, 1.0000},
			{0.0000, 0.5000, 1.0000},
			{0.0000, 0.5625, 1.0000},
			{0.0000, 0.6250, 1.0000},
			{0.0000, 0.6875, 1.0000},
			{0.0000, 0.7500, 1.0000},
			{0.0000, 0.8125, 1.0000},	
			{0.0000, 0.8750, 1.0000},		
			{0.0000, 0.9375, 1.0000},
			{0.0000, 1.0000, 1.0000},
			{0.0625, 1.0000, 0.9375},
			{0.1250, 1.0000, 0.8750},
			{0.1875, 1.0000, 0.8125},
			{0.2500, 1.0000, 0.7500},
			{0.3125, 1.0000, 0.6875},
			{0.3750, 1.0000, 0.6250},
			{0.4375, 1.0000, 0.5625},
			{0.5000, 1.0000, 0.5000},
			{0.5625, 1.0000, 0.4375},
			{0.6250, 1.0000, 0.3750},
			{0.6875, 1.0000, 0.3125},
			{0.7500, 1.0000, 0.2500},
			{0.8125, 1.0000, 0.1875},
			{0.8750, 1.0000, 0.1250},
			{0.9375, 1.0000, 0.0625},
			{1.0000, 1.0000, 0.0000},
			{1.0000, 0.9375, 0.0000},
			{1.0000, 0.8750, 0.0000},
			{1.0000, 0.8125, 0.0000},
			{1.0000, 0.7500, 0.0000},
			{1.0000, 0.6875, 0.0000}, 
			{1.0000, 0.6250, 0.0000}, 
			{1.0000, 0.5625, 0.0000},
			{1.0000, 0.5000, 0.0000}, 
			{1.0000, 0.4375, 0.0000},
			{1.0000, 0.3750, 0.0000},
			{1.0000, 0.3125, 0.0000},
			{1.0000, 0.2500, 0.0000},
			{1.0000, 0.1875, 0.0000},
			{1.0000, 0.1250, 0.0000},
			{1.0000, 0.0625, 0.0000},
			{1.0000, 0.0000, 0.0000},
			{0.9375, 0.0000, 0.0000},
			{0.8750, 0.0000, 0.0000},
			{0.8125, 0.0000, 0.0000},
			{0.7500, 0.0000, 0.0000},
			{0.6875, 0.0000, 0.0000},
			{0.6250, 0.0000, 0.0000},
			{0.5625, 0.0000, 0.0000},
			{0.5000, 0.0000, 0.0000}};

  int max_iter = 256, iter;
  double crow, delta;
  int i, j;
  float R, G, B;
  double x0, y0, x, y, xtemp;

	for (int i = 0; i < FRACTAL_HEIGHT; i++) {
    	for (int j = 0; j < FRACTAL_WIDTH; j++) {

			x0 = (xaxis[1] - xaxis[0]) / FRACTAL_WIDTH * j + xaxis[0];
			y0 = (yaxis[1] - yaxis[0]) / FRACTAL_HEIGHT * i + yaxis[0];
			x = 0.0;
			y = 0.0;
			iter = 0;
			while (((x*x + y*y) <= 4.0) && (iter < max_iter)) {
				xtemp = x*x - y*y + x0;
				y = 2.0*x*y + y0;
				x = xtemp;
				iter++;
			}
			if (iter == max_iter) {
				iter = 0;
			}

		  	// Scale color based on max value and interpolated color map
		  	crow =  (iter*63)/(max_iter-1);
	  		delta = crow - floor(crow);
	
			R = (cmap[(int)crow][0] + (cmap[(int)crow][0] - cmap[(int)crow+1][0]) * delta);
			G = (cmap[(int)crow][1] + (cmap[(int)crow][1] - cmap[(int)crow+1][1]) * delta);
			B = (cmap[(int)crow][2] + (cmap[(int)crow][2] - cmap[(int)crow+1][2]) * delta);

    		g_color_buffer_data[3*(FRACTAL_WIDTH*i+j)] = R;
    		g_color_buffer_data[3*(FRACTAL_WIDTH*i+j)+1] = G;
    		g_color_buffer_data[3*(FRACTAL_WIDTH*i+j)+2] = B;
    	}
    }


	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);

}



void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {


	double xpos_screen, ypos_screen;
	double xpos_dev, ypos_dev;
	double xaxis_width, yaxis_width;
	double xaxis_center, yaxis_center;


//double xaxis[2] = {-2.0, 0.7};
//double yaxis[2] = {-1.0, 1.0};


    if (((button == GLFW_MOUSE_BUTTON_LEFT) || (button == GLFW_MOUSE_BUTTON_RIGHT)) && action == GLFW_PRESS) {
        glfwGetCursorPos(window, &xpos_screen, &ypos_screen);        

        // Center these on the current axis
        xaxis_width = xaxis[1] - xaxis[0];
        yaxis_width = yaxis[1] - yaxis[0];
        xaxis_center = xaxis[0]+xaxis_width/2;
        yaxis_center = yaxis[0]+yaxis_width/2;

        // Normalized device coordinate equivalent
        xpos_dev = 2*xpos_screen/FRACTAL_WIDTH-1.0;
        ypos_dev = 2*ypos_screen/FRACTAL_HEIGHT-1.0;

        // Shift to current x, y axes
        xpos_dev = xaxis_width/2*xpos_dev+xaxis_center;
        ypos_dev = yaxis_width/2*ypos_dev+yaxis_center;

        // Zoom in our out
		if (button == GLFW_MOUSE_BUTTON_RIGHT) {

	        xaxis[0] = xpos_dev - .55*xaxis_width;
    	    xaxis[1] = xpos_dev + .55*xaxis_width;

        	yaxis[0] = ypos_dev - .55*yaxis_width;
        	yaxis[1] = ypos_dev + .55*yaxis_width;
        }

        else {
	        xaxis[0] = xpos_dev - .45*xaxis_width;
    	    xaxis[1] = xpos_dev + .45*xaxis_width;

        	yaxis[0] = ypos_dev - .45*yaxis_width;
        	yaxis[1] = ypos_dev + .45*yaxis_width;
        }


        update_fractal();
    }

}



int main() {
  
  if (!glfwInit()) {
    fprintf(stderr, "ERROR: could not start GLFW3\n");
    return 1;
  } 

  window = glfwCreateWindow(FRACTAL_WIDTH, FRACTAL_HEIGHT, "Fractals", NULL, NULL);
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

	// Capture mouse clicks
	glfwSetMouseButtonCallback(window, mouse_button_callback);

	// Black background
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/passthrough.vert", "../common/shaders/passthrough.frag" );


	// The vertex locations are a constant, we just would (potentially) change the colors based on interaction
	// with the fractal
    for (int i = 0; i < FRACTAL_HEIGHT; i++) {
    	for (int j = 0; j < FRACTAL_WIDTH; j++) {
    		g_vertex_buffer_data[3*(FRACTAL_WIDTH*i+j)] = j*2.0/FRACTAL_WIDTH-1.0;  // x-pos
            g_vertex_buffer_data[3*(FRACTAL_WIDTH*i+j)+1] = i*2.0/FRACTAL_HEIGHT-1.0; // y-pos
            g_vertex_buffer_data[3*(FRACTAL_WIDTH*i+j)+2] = 0.0f;
            //printf("Fractal at [%d,%d] is {%f, %f}\n", j, i, j*1.0/FRACTAL_WIDTH, i*1.0/FRACTAL_HEIGHT);
        }
    }


	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);


	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);

	update_fractal(); // This function does the glBufferData call


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
		glDrawArrays(GL_POINTS, 0, FRACTAL_HEIGHT*FRACTAL_WIDTH); 

		glDisableVertexAttribArray(0);
		glDisableVertexAttribArray(1);

    glfwPollEvents();
    glfwSwapBuffers(window);

  }

  glfwTerminate();
  return 0;

}
