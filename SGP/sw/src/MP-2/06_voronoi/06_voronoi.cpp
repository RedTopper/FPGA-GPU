/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 06_voronoi - draws a set of randomly colored polygons based on Fortune's
 * Voronoi Diagram algorithm. Don't resize the window :)
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

extern "C" {
#include "simpleGLU.h"
}
#include "VoronoiDiagramGenerator.h"


#define PI 3.1415927

#define INIT_WIDTH 1024
#define INIT_HEIGHT 1024
#define MAX_SITES 1024
#define MAX_VERTS 128
#define POINT_WIDTH 4
#define DIST_TOL 0.25
#define ERR_TOL .001
#define NPOINTS 100

#define DEBUG 1

int window_width = INIT_WIDTH;
int window_height = INIT_HEIGHT;

unsigned char *data;
unsigned short width, height;
int image_mode = 0;

VoronoiDiagramGenerator vdg;

struct poly {
	int nv;
	int nvv;
	float x[MAX_VERTS], y[MAX_VERTS];
	float siteX, siteY;
	float angle[MAX_VERTS];
	unsigned char r, g, b;
};

poly polys[MAX_SITES];	
int np = 0;
int vertex_counter = 0;
int color_counter = 0;


float xValues[MAX_SITES];
float yValues[MAX_SITES];
float siteDist[MAX_SITES];


// Worst case total number of points for static memory allocation
const int max_vertex = MAX_SITES*(MAX_VERTS+4);
static GLfloat g_vertex_buffer_data[2*max_vertex]; 

// One color (RGB for this) for each vertex.
static GLfloat g_color_buffer_data[3*max_vertex];

GLuint vertexbuffer;
GLuint colorbuffer;

void updateBuffers();
void displayFunc();


void doInit() {
	int i;
  
  	glClearColor(0.215, 0.215, 0.215, 1.0);

	if (image_mode == 1) {
		srand(43);
  		for (i = 0; i < MAX_SITES; i++) {
    		polys[i].nv = 0;
			polys[i].nvv = 0;
  		}
		return;
	}
	
	
	int r_mod, g_mod, b_mod;

	xValues[0] = window_width / 2;
	yValues[0] = window_height / 2;
	polys[0].siteX = window_width / 2;
	polys[0].siteY = window_height / 2;
	np = 1;

	srand(42);
	
	// Initialize the polys data structure
	int r_mods[12] = {255, 255, 255, 255, 255, 128,   1,   1,   1,   1, 128, 255};
	int g_mods[12] = {  1,  64, 128, 192, 255, 255, 255, 255, 128,   1,   1,   1};
	int b_mods[12] = {  1,   1,   1,   1,   1,   1,   1, 128, 255, 255, 255, 255};

	for (i = 0; i < MAX_SITES; i++) {
		polys[i].nv = 0;
		r_mod = r_mods[i%12];
		g_mod = g_mods[i%12];
		b_mod = b_mods[i%12];
    	polys[i].r = rand() % r_mod;
    	polys[i].g = rand() % g_mod;
    	polys[i].b = rand() % b_mod;
	}

	return;
}



void loadImage(char* filename, int reload) {

	int i, j, k;
	int x, y;
	float xValue, yValue;
	int unique;


	bmp_file_info bmp;
	sglu_config_type *config;

	static unsigned int **pixels;


	// Only load the image data the first time around
	if (reload == 0) {

		config = sglu_init_config();
		config->infile_name = (char *)realloc(config->infile_name, strlen(filename)+1);
	    strcpy(config->infile_name, filename);	          
    	sglu_init_bmp(config, &bmp);
    	pixels = sglu_bmp_to_array(config, &bmp);
		width = config->width;
		height = config->height;

    	if (DEBUG == 1) {
      		sglu_bmp_info(&bmp);
	    }
	}  

	// Grab np random values from the file
	if (DEBUG == 1)
		printf("Read image of [%d, %d], running for np = %d\n", width, height, np);

	i = 0;
	for (j = 0; j < np; j++) {
		unique = 1;
		x = rand() % width;
    	y = rand() % height;
    	xValue = 1.0*x + (window_width-width)/2;
    	yValue = 1.0*y + (window_height-height)/2;

    	// Warning: each x/y pair must be unique!
    	for (k = 0; k < i; k++) {
      		if ((fabsf(xValue-xValues[k]) < ERR_TOL) && fabsf(yValue-yValues[k]) < ERR_TOL) {
				if (DEBUG == 1)
	 	 			printf("Warning: non-unique point generated. Skipping...\n");
				unique = 0;
				np--;
				break;
		    }
    	}

    	if (unique == 1) {
			xValues[i] = xValue;
			yValues[i] = yValue;
			polys[i].siteX = xValue;
			polys[i].siteY = yValue;
			unsigned int tpixel = pixels[y][x]; 

			polys[i].r = ((tpixel>> 16) & 0xFF);
			polys[i].g = ((tpixel>> 0) & 0xFF);
			polys[i].b = ((tpixel>> 8) & 0xFF);

			i++;
		}
	}
	return;
}




void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {


  	int i, unique;
  	float xValue, yValue;
	double xpos_screen, ypos_screen;

    glfwGetCursorPos(window, &xpos_screen, &ypos_screen);        
	xValue = (float)xpos_screen;
	yValue = (float)ypos_screen;
	if (image_mode == 0) {
		if (action == GLFW_PRESS) {
			if (button == GLFW_MOUSE_BUTTON_LEFT) {
				for (i = 0; i < np; i++) {
					unique = 1;
					if ((fabsf(xValue-xValues[i]) < ERR_TOL) && fabsf(yValue-yValues[i]) < ERR_TOL) {
						if (DEBUG == 1)
	      					printf("Warning: non-unique point generated. Skipping...\n");
	    				unique = 0;
	    				break;	  
		  			}
				}
	
				if (unique == 1) {
	  				xValues[np] = xValue;
	  				yValues[np] = yValue;
	  				polys[np].siteX = xValue;
	  				polys[np].siteY = yValue;
	  				np++;
				}
			}
			else if (button == GLFW_MOUSE_BUTTON_RIGHT) {
				np = 1;				
			}
    	}
		updateBuffers();
	}
	
	else {
		if (action == GLFW_PRESS) {
			if (button == GLFW_MOUSE_BUTTON_LEFT) {
				np = np * 3/2;
			}
			else if (button == GLFW_MOUSE_BUTTON_RIGHT) {
				np = np * 2/3 + 1;
      		}

      		loadImage("", 1);

      		updateBuffers();
	    }
	}
	return;
}



float dist(float x1, float y1, float x2, float y2) {	
	float result;
	result = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
	return result;
}

// Calculate the angle of each vertex, relative to the center site location
void calc_angles(poly &myPoly) {
	int i;
	float x, y, angle;

	for (i = 0; i < myPoly.nv; i++) {
		x = myPoly.x[i] - myPoly.siteX;
		y = myPoly.siteY - myPoly.y[i];
		if (x > 0) {
			if (y >= 0) {
				angle = atan(y/x);
			}
			else {
				angle = atan(y/x) + 2*PI;
			}
    	}
	    if (x == 0) {
			if (y >= 0) {
				angle = 0;
			}
			else {
				angle = 3*PI/2;
			}
    	}
    	if (x < 0) {
			angle = atan(y/x) + PI;
   		}
    	myPoly.angle[i] = angle;
	}
	return;
}



// Finds the nearest site(s) to a given x/y coordinate. Reused multiple time
// throughout the program accessing the global polys variable.
void find_nearest_site(float x1, float y1) {
	int i;
	float minDist = 1640.0;


	// For both end points, calculate the distances to each of the sites
	for (i = 0; i < np; i++) {
		siteDist[i] = dist(x1, y1, xValues[i], yValues[i]);
		if (siteDist[i] < minDist) {
			minDist = siteDist[i];
		}
	}

	// If we're close enough to any of the sites, add this to the vertex array
	// for the corresponding polygon
	for (i = 0; i < np; i++) {
		if (fabsf(siteDist[i]) < (fabsf(minDist) + DIST_TOL)) {
			polys[i].x[polys[i].nv] = x1;
			polys[i].y[polys[i].nv] = y1;
			polys[i].nv++;
		}
	}
	return;
}

void updateBuffers() {

	int i, j, k;
	float temp;
	float x1, x2, y1, y2, xprev, yprev;

	// Run the Voronoi generator and reset the edge data structure
	if (image_mode == 0) {
		vdg.generateVoronoi(xValues, yValues, np, 0, window_width, 0, window_height, 0);
	}
	else {
		vdg.generateVoronoi(xValues, yValues, np, (window_width-width)/2, (window_width+width)/2, (window_height-height)/2, (window_height+height)/2, 0);
	}
	
	vdg.resetIterator();

	// We have to reshape every poly each iteration
	for (i = 0; i < MAX_SITES; i++) {
		polys[i].nv = 0;
	}

	while(vdg.getNext(x1,y1,x2,y2)) {
		find_nearest_site(x1, y1);
		find_nearest_site(x2, y2);
	}

	// Do the same for the four corners as well
	if (image_mode == 0) {
		x1 = 0;y1 = 0;
		find_nearest_site(x1, y1);
		x1 = 0;y1 = window_height;
		find_nearest_site(x1, y1);
		x1 = window_width;y1 = 0;
		find_nearest_site(x1, y1);
		x1 = window_width;y1 = window_height;
		find_nearest_site(x1, y1);
	}
  
  	else {
		  x1 = (window_width-width)/2;y1 = (window_height-height)/2;
		  find_nearest_site(x1, y1);
		  x1 = (window_width-width)/2;y1 = (window_height+height)/2;
		  find_nearest_site(x1, y1);
		  x1 = (window_width+width)/2;y1 = (window_height-height)/2;
		  find_nearest_site(x1, y1);
		  x1 = (window_width+width)/2;y1 = (window_height+height)/2;
		  find_nearest_site(x1, y1);
	}
	
	// We have to sort each polygon's vertices as well
	for (i = 0; i < np; i++) {
		calc_angles(polys[i]);
		for (j = 0; j < polys[i].nv; j++) {
			for (k = 0; k < polys[i].nv; k++) {

				// Perform a local swap of the angle and x/y value
				if (polys[i].angle[j] > polys[i].angle[k]) {
					temp = polys[i].angle[k];
					polys[i].angle[k] = polys[i].angle[j];
					polys[i].angle[j] = temp;
					temp = polys[i].x[k];
					polys[i].x[k] = polys[i].x[j];
					polys[i].x[j] = temp;
					temp = polys[i].y[k];
					polys[i].y[k] = polys[i].y[j];
					polys[i].y[j] = temp;	  
				}
			}
		}
	}


	vertex_counter = 0;
	color_counter = 0;
	if (np > 1) {
		for (i = 0; i < np; i++) {
			int cur_red = polys[i].r;
			int cur_green = polys[i].g;
			int cur_blue = polys[i].b;			

			xprev = -12345678.0;
			yprev = 98765432.0;
			polys[i].nvv = 0;
			for (j = 0; j < polys[i].nv; j++) {

				if ((j > 0) && (fabsf(polys[i].x[j] - xprev) < ERR_TOL) && (fabsf(polys[i].y[j] - yprev) < ERR_TOL)) {
				}
				else {					
					float xpos_screen = polys[i].x[j];
					float ypos_screen = polys[i].y[j];
					g_vertex_buffer_data[vertex_counter++] = xpos_screen*2.0/window_width-1.0;
					g_vertex_buffer_data[vertex_counter++] = 1.0-ypos_screen*2.0/window_height;
					g_color_buffer_data[color_counter++] = cur_red / 255.0;
					g_color_buffer_data[color_counter++] = cur_green / 255.0;
					g_color_buffer_data[color_counter++] = cur_blue / 255.0;
					polys[i].nvv++;
				}
	
				xprev = polys[i].x[j];
				yprev = polys[i].y[j];
      		}
		}
  	}

	// Highlight the mouseclicks with a small grey quad
	if (image_mode == 0) {
	  	for (i = 0; i < np; i++) {
			float xpos_screen = xValues[i];
			float ypos_screen = yValues[i];
			g_vertex_buffer_data[vertex_counter++] = (xpos_screen-POINT_WIDTH)*2.0/window_width-1.0;
			g_vertex_buffer_data[vertex_counter++] = 1.0-(ypos_screen)*2.0/window_height;
			g_vertex_buffer_data[vertex_counter++] = (xpos_screen-POINT_WIDTH)*2.0/window_width-1.0;
			g_vertex_buffer_data[vertex_counter++] = 1.0-(ypos_screen+POINT_WIDTH)*2.0/window_height;
			g_vertex_buffer_data[vertex_counter++] = (xpos_screen)*2.0/window_width-1.0;
			g_vertex_buffer_data[vertex_counter++] = 1.0-(ypos_screen+POINT_WIDTH)*2.0/window_height;
			g_vertex_buffer_data[vertex_counter++] = (xpos_screen)*2.0/window_width-1.0;
			g_vertex_buffer_data[vertex_counter++] =  1.0-(ypos_screen)*2.0/window_height;
			for (int k = 0; k < 12; k++) {
				g_color_buffer_data[color_counter++] = 0.784;
			}
		}
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



int main(int argc, char **argv) {
	
	if (argc > 3) {
		printf("Error: Bad arguments\nUsage: %s [File.bmp] [npoints]\n", argv[0]);
	}

	if (argc > 2) {
		np = atoi(argv[2]);
	}
	else {
    	np = NPOINTS;
	}

	if (argc > 1) {
		loadImage(argv[1], 0);
		image_mode = 1;
	}

	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 


	window = glfwCreateWindow(INIT_WIDTH, INIT_HEIGHT, "Voronoi Diagram", NULL, NULL);
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


	doInit();

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

		int i, vertex_offset;
    	glClear(GL_COLOR_BUFFER_BIT);

		// Draw the polygons
		vertex_offset = 0;
		if (np > 1) {
			for (i = 0; i < np; i++) {
				glDrawArrays(GL_TRIANGLE_FAN, vertex_offset, polys[i].nvv); 
				vertex_offset += polys[i].nvv;
			}
		}

		// Draw the mouseclicks
		if (image_mode == 0) {
	  		for (i = 0; i < np; i++) {
				glDrawArrays(GL_TRIANGLE_FAN, vertex_offset, 4); 
				vertex_offset += 4;
		  	}
		}

    	glfwPollEvents();
    	glfwSwapBuffers(window);

  	}

  	glfwTerminate();
  	return 0;

}
