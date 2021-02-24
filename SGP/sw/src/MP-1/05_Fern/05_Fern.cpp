/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 05_Fern - draws a fern, using fractal patterns. Adapted from the original
 * by Mike "Steve" Steffen and Mat Wymore. 
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


#define WINDOW_WIDTH 1280
#define WINDOW_HEIGHT 1024

#define MAX_VERTS 1339634
static GLfloat g_vertex_buffer_data[2*MAX_VERTS]; 
static GLfloat g_color_buffer_data[2*MAX_VERTS];


int numIterations;
int numVerts;
float greenLevel = 1.0;


void glInit() {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glPointSize(1.0f);
}

//drawLine function: Given start and end points, draws a line
void drawLine(int x1,int y1,int x2,int y2) {
  int yDiff = y2 - y1;
  int xDiff = x2 - x1;
  float numPixels = (float)sqrt(yDiff * yDiff + xDiff * xDiff);
  int i;
  for(i = 0; i < numPixels; i++){
    int x, y;
    x = (int)(x1+xDiff * (i / numPixels));
    y = (int)(y1+yDiff * (i / numPixels));

    // We can just set x,y, and r, g since z=0.0 and b=0.0 for this application
    g_vertex_buffer_data[2*numVerts] = 2.0*x/WINDOW_WIDTH-1.0;
    g_vertex_buffer_data[2*numVerts+1] = 2.0*(WINDOW_HEIGHT-y)/WINDOW_HEIGHT-1.0;
//    g_vertex_buffer_data[3*numVerts+2] = 0.0;
    g_color_buffer_data[2*numVerts] = 0.0;
    g_color_buffer_data[2*numVerts+1] = greenLevel;
//    g_color_buffer_data[3*numVerts+2] = 0.0;

    numVerts++;
  }
}

//Simple min function.  Returns minimum of two numbers.
int min(int n1, int n2) {
  if (n1 <= n2)
    return n1;
  else return n2;
}


float pi = 3.14159;
float branchRatio = 0.4;
float branchAngle = 44;
float bendAngle = 7;
float trunkRatio = 0.1;
float antiTrunkRatio = 0.9; //antiTrunkRatio = 1-trunkRatio
float startAngle = -90;
float heightScale = 1.5;


void createFern(float startx, float starty, float a, float rad, float level) {
	float cx = startx + cos(a*pi/180)*rad*trunkRatio;
	float cy = starty + sin(a*pi/180)*rad*trunkRatio;
  greenLevel = (255-(200*level/(numIterations)))/255.0;
	drawLine(startx, starty, cx, cy);
	if(level > 0)
	{
		level--;
		a += bendAngle;
		createFern(cx,cy,a-branchAngle,rad*branchRatio,level);	  
		createFern(cx,cy,a+branchAngle,rad*branchRatio,level);	  
		createFern(cx,cy,a,rad*antiTrunkRatio,level);
	}
}



int main(int argc, char **argv) {
  
  if (argc != 2) {
    printf("Setting numIterations to 10\n");
    numIterations = 10;
  }
  else {
    numIterations = atoi(argv[1]);
    if (numIterations < 0) {
      printf("Warning, numIterations must be [0-15], setting to 1\n");
      numIterations = 1;
    }
    if (numIterations > 15) {
      printf("Warning, numIterations must be [0-15], setting to 15\n");
      numIterations = 15;
    }
  }



  if (!glfwInit()) {
    fprintf(stderr, "ERROR: could not start GLFW3\n");
    return 1;
  } 

  window = glfwCreateWindow(1280, 1024, "RecursiveFractalFern", NULL, NULL);
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
	glUseProgram(programID);


  numVerts = 0;
	createFern(WINDOW_WIDTH/2, WINDOW_HEIGHT, startAngle, WINDOW_HEIGHT*heightScale, numIterations);


	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
  glBufferData(GL_ARRAY_BUFFER, 2*numVerts*sizeof(float), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, 2*numVerts*sizeof(float), g_color_buffer_data, GL_STATIC_DRAW);

	// It can be hard to see single pixels at a time.
	glEnable(GL_PROGRAM_POINT_SIZE);

  glInit();


	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
    
    glClear(GL_COLOR_BUFFER_BIT);

		// 1st attribute buffer : vertices. Note these are only vec2 for this app
		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// 2nd attribute buffer : colors. Note these are only vec2 for this app
		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
		glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, (void*)0);

		// Draw the points
		glDrawArrays(GL_POINTS, 0, numVerts);


    glfwPollEvents();
    glfwSwapBuffers(window);

  }

  glfwTerminate();
  return 0;

}
