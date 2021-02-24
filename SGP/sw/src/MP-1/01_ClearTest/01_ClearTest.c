/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 01_ClearTest.c - tests functionality of glClearColor*() and glClear() 
 *
 *
 * NOTES:
 * 11/19/20 by JAZ::Design created.
 *****************************************************************************/



#include <GL/glew.h> 
#include <GLFW/glfw3.h> 
#include <stdio.h>
#include <stdlib.h>

int main() {
  
  if (!glfwInit()) {
    fprintf(stderr, "ERROR: could not start GLFW3\n");
    return 1;
  } 

  GLFWwindow* window = glfwCreateWindow(1920, 1080, "ClearTest", NULL, NULL);
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


	// Start with a medium blue background
  GLfloat red = 0.0f, green = 0.0f, blue = 0.7f, alpha = 0.0f;

  // State to keep track of press / up events
  int pressed = 0;

	glClearColor(red, green, blue, alpha);
  while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {
   
    glClear(GL_COLOR_BUFFER_BIT);
    glfwPollEvents();
    glfwSwapBuffers(window);

    // Press the spacebar to randomize the glClearColor. Manually debounce
    if ((glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS) && (pressed == 0)) {
      pressed = 1;
      red = rand() / (RAND_MAX + 1.);
      green = rand() / (RAND_MAX + 1.);
      blue = rand() / (RAND_MAX + 1.);
    }

    if ((glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_RELEASE) && (pressed == 1)) {
      pressed = 0;
    	glClearColor(red, green, blue, alpha);
    }

  }

  glfwTerminate();
  return 0;

}
