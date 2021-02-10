/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 06_ViewPorting - Dynamically changes the viewport based on mouse clicks 
 *
 *
 * NOTES:
 * 12/14/20 by JAZ::Design created.
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <GL/glew.h> 
#include <GLFW/glfw3.h> 
GLFWwindow* window;

#include <shader.hpp>

extern "C" {
#include "simpleGLU.h"
}


#define WINDOW_WIDTH 1920
#define WINDOW_HEIGHT 1080

static int clear = 1;
unsigned short img_width, img_height;


void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
	double xpos_screen, ypos_screen;
	static int x0, y0, x1, y1;

	static int wait_for_mouseup = 0;
	// Use the left mouse click to select the edges of a new viewport. Note that press/release will not work well with a slow frame in the SGP
    if (button == GLFW_MOUSE_BUTTON_LEFT) {
        glfwGetCursorPos(window, &xpos_screen, &ypos_screen);        
		if (action == GLFW_PRESS) {
			if (wait_for_mouseup == 0) {
				x0 = (int)xpos_screen;
				y0 = (int)ypos_screen;
				wait_for_mouseup = 1;
			    printf("\tMouse down: [%d, %d]\n", x0, y0);
			}
			else {
				x1 = (int)xpos_screen;
				y1 = (int)ypos_screen;
				wait_for_mouseup = 0;
			    printf("\tSecond mouse down: [%d, %d]\n", x1, y1);
				// Not sure what negative viewports would do, and don't want to find out
				if (((y1-y0) > 0) && (x1-x0) > 0) {
					glViewport(x0, img_height-y1, (x1-x0), (y1-y0));
				}

			}
		}
    }

	// Rightclick to clear the screen on next draw
	if ((button == GLFW_MOUSE_BUTTON_RIGHT) && (action == GLFW_PRESS)) {
		clear = 1;
		printf("\tRight-click: clearing screen\n");
	}

	return;
}



int main(int argc, char **argv) {
	
	if (argc != 2) {
		printf("Usage: 05_ViewPorting filename.bmp\n");
		return 1;
	}


	bmp_file_info bmp;
	sglu_config_type *config;
	unsigned int **pixels;

	// Load input .bmp file into pixel array
	config = sglu_init_config();
	config->infile_name = (char *)realloc(config->infile_name, strlen(argv[1])+1);
    sglu_init_bmp(config, &bmp);
	strcpy(config->infile_name, argv[1]);	          
    pixels = sglu_bmp_to_array(config, &bmp);
    sglu_bmp_info(&bmp);
	img_width = config->width;
	img_height = config->height;


	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 


	window = glfwCreateWindow(img_width, img_height, "Viewport Fun", NULL, NULL);
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
	glUseProgram(programID);


	// A point per pixel of image resolution
	GLfloat *g_vertex_buffer_data = (GLfloat *)malloc(2*img_width*img_height*sizeof(GLfloat));

	// One color (RGB for this) for each vertex.
	GLfloat *g_color_buffer_data = (GLfloat *)malloc(3*img_width*img_height*sizeof(GLfloat));

	// Initialize the data based on the input image pixels
    for (int i = 0; i < img_height; i++) {
    	for (int j = 0; j < img_width; j++) {
    		g_vertex_buffer_data[2*(img_width*i+j)] = j*2.0/img_width-1.0;
            g_vertex_buffer_data[2*(img_width*i+j)+1] = i*2.0/img_height-1.0;
			unsigned int tpixel = pixels[img_height-i-1][j]; 
			g_color_buffer_data[3*(img_width*i+j)] =   ((tpixel>> 16) & 0xFF) / 255.0;
			g_color_buffer_data[3*(img_width*i+j)+1] = ((tpixel>> 0) & 0xFF) / 255.0;
			g_color_buffer_data[3*(img_width*i+j)+2] = ((tpixel>> 8) & 0xFF) / 255.0;
        }
    }

	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, 2*img_width*img_height*sizeof(float), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, 3*img_width*img_height*sizeof(float), g_color_buffer_data, GL_STATIC_DRAW);


	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
    
		if (clear > 0) {
			glClear(GL_COLOR_BUFFER_BIT);
			clear++;
			if (clear > 2) {
				clear = 0;
			}
		}

		// 1st attribute buffer : vertices. Note these are only vec2 for this app
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// 2nd attribute buffer : colors.
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// Draw the points. For slow draw calls on our hardware, we'll want to poll events both before and after the draw
		glfwPollEvents();
		glDrawArrays(GL_POINTS, 0, img_width*img_height);
		glfwPollEvents();

		glfwSwapBuffers(window);
	}

	glfwTerminate();
	return 0;

}

