/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 02_cubeflyby - Different view angles of a color cube  
 *
 *
 * NOTES:
 * 01/06/20 by JAZ::Design created.
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <cstring>
#include <vector>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
GLFWwindow* window;

// Include GLM
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
using namespace glm;

#include <shader.hpp>

GLuint MatrixID;

float eyeX = 4.0, eyeY = 3.0, eyeZ = -3.0;

void setViewMatrix() {

	glm::vec3 _eye(eyeX, eyeY, eyeZ), _center(0, 0, 0), _up(0, 1, 0);
	glm::mat4 viewMatrix = glm::lookAt(_eye, _center, _up);
	glm::mat4 projectionMatrix = glm::perspective(glm::radians(45.0f), 4.0f / 3.0f, 0.1f, 100.0f);

 	glm::mat4 MVP = projectionMatrix * viewMatrix;

	// Send our uniforms to the currently bound shader
	glUniformMatrix4fv(MatrixID, 1, GL_FALSE, &MVP[0][0]);
}


void keypress(GLFWwindow* window, int key, int scancode, int action, int mods) {
	
    switch(key) {
    	case GLFW_KEY_UP:
			eyeY += 0.1;
			break;
		case GLFW_KEY_DOWN:
			eyeY -= 0.1;
			break;
		case GLFW_KEY_LEFT:
			eyeX -= 0.1;
			break;
		case GLFW_KEY_RIGHT:
			eyeX += 0.1;
			break;
		case GLFW_KEY_MINUS:
			eyeZ -= 0.1;
			break;
		case GLFW_KEY_EQUAL:
			eyeZ += 0.1;
			break;

		default:
        	break;
	}

	setViewMatrix();

}

int main( void ) {
  
	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 

	window = glfwCreateWindow(1280, 1024, "Cube Flyby", NULL, NULL);
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
	glfwSetKeyCallback(window, keypress);

    // Hide the mouse and enable unlimited mouvement
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    
    glfwPollEvents();

	// Dark blue background
	glClearColor(0.0f, 0.0f, 0.4f, 0.0f);

	// Enable depth test
	glEnable(GL_DEPTH_TEST);
	// Accept fragment if it closer to the camera than the former one
	glDepthFunc(GL_LESS); 

	// Cull triangles which normal is not towards the camera
	glEnable(GL_CULL_FACE);

	GLuint VertexArrayID;
	glGenVertexArrays(1, &VertexArrayID);
	glBindVertexArray(VertexArrayID);

	// Create and compile our GLSL program from the shaders
	GLuint programID = LoadShaders( "../common/shaders/mvp_transform.vert", "../common/shaders/passthrough.frag" );
	glUseProgram(programID);
	MatrixID = glGetUniformLocation(programID, "MVP");

	static const GLfloat g_vertex_buffer_data[] = {
    	-1.0f,-1.0f,-1.0f, // triangle 1 : begin
    	-1.0f,-1.0f, 1.0f,
    	-1.0f, 1.0f, 1.0f, // triangle 1 : end
    	1.0f, 1.0f,-1.0f, // triangle 2 : begin
    	-1.0f,-1.0f,-1.0f,
    	-1.0f, 1.0f,-1.0f, // triangle 2 : end
    	1.0f,-1.0f, 1.0f,
    	-1.0f,-1.0f,-1.0f,
    	1.0f,-1.0f,-1.0f,
    	1.0f, 1.0f,-1.0f,
    	1.0f,-1.0f,-1.0f,
    	-1.0f,-1.0f,-1.0f,
    	-1.0f,-1.0f,-1.0f,
    	-1.0f, 1.0f, 1.0f,
    	-1.0f, 1.0f,-1.0f,
    	1.0f,-1.0f, 1.0f,
    	-1.0f,-1.0f, 1.0f,
    	-1.0f,-1.0f,-1.0f,
    	-1.0f, 1.0f, 1.0f,
    	-1.0f,-1.0f, 1.0f,
    	1.0f,-1.0f, 1.0f,
    	1.0f, 1.0f, 1.0f,
    	1.0f,-1.0f,-1.0f,
    	1.0f, 1.0f,-1.0f,
    	1.0f,-1.0f,-1.0f,
    	1.0f, 1.0f, 1.0f,
    	1.0f,-1.0f, 1.0f,
    	1.0f, 1.0f, 1.0f,
    	1.0f, 1.0f,-1.0f,
    	-1.0f, 1.0f,-1.0f,
    	1.0f, 1.0f, 1.0f,
    	-1.0f, 1.0f,-1.0f,
    	-1.0f, 1.0f, 1.0f,
    	1.0f, 1.0f, 1.0f,
    	-1.0f, 1.0f, 1.0f,
    	1.0f,-1.0f, 1.0f
		};

	static const GLfloat g_color_buffer_data[] = {
    	0.583f,  0.771f,  0.014f,
    	0.609f,  0.115f,  0.436f,
    	0.327f,  0.483f,  0.844f,
    	0.822f,  0.569f,  0.201f,
    	0.435f,  0.602f,  0.223f,
    	0.310f,  0.747f,  0.185f,
    	0.597f,  0.770f,  0.761f,
    	0.559f,  0.436f,  0.730f,
    	0.359f,  0.583f,  0.152f,
    	0.483f,  0.596f,  0.789f,
    	0.559f,  0.861f,  0.639f,
    	0.195f,  0.548f,  0.859f,
    	0.014f,  0.184f,  0.576f,
    	0.771f,  0.328f,  0.970f,
    	0.406f,  0.615f,  0.116f,
    	0.676f,  0.977f,  0.133f,
    	0.971f,  0.572f,  0.833f,
    	0.140f,  0.616f,  0.489f,
    	0.997f,  0.513f,  0.064f,
    	0.945f,  0.719f,  0.592f,
    	0.543f,  0.021f,  0.978f,
    	0.279f,  0.317f,  0.505f,
    	0.167f,  0.620f,  0.077f,
    	0.347f,  0.857f,  0.137f,
    	0.055f,  0.953f,  0.042f,
    	0.714f,  0.505f,  0.345f,
    	0.783f,  0.290f,  0.734f,
    	0.722f,  0.645f,  0.174f,
    	0.302f,  0.455f,  0.848f,
    	0.225f,  0.587f,  0.040f,
    	0.517f,  0.713f,  0.338f,
    	0.053f,  0.959f,  0.120f,
    	0.393f,  0.621f,  0.362f,
    	0.673f,  0.211f,  0.457f,
    	0.820f,  0.883f,  0.371f,
    	0.982f,  0.099f,  0.879f
	};

	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);

	GLuint colorbuffer;
	glGenBuffers(1, &colorbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	glEnableVertexAttribArray(1);
	glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	setViewMatrix();

	// Enable depth test
	glEnable(GL_DEPTH_TEST);
	// Accept fragment if it closer to the camera than the former one
	glDepthFunc(GL_LESS);


	while( glfwGetKey(window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 ) {

		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		glDrawArrays(GL_TRIANGLES, 0, 12*3);

    	glfwPollEvents();
    	glfwSwapBuffers(window);
  	}

	glfwTerminate();

	return 0;
}

