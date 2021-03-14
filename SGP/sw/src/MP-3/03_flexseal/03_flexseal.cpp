/*****************************************************************************
 * Joseph Zambreno               
 * Department of Electrical and Computer Engineering
 * Iowa State University
 *****************************************************************************/

/*****************************************************************************
 * 03_flexseal - loads a happy baby seal. Inspired by Tessa.  
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

bool loadOBJ2 (const char * path, std::vector<glm::vec3> & out_vertices, std::vector<glm::vec3> & out_normals) {
	printf("Loading OBJ file %s...\n", path);

	std::vector<unsigned int> vertexIndices, normalIndices;
	std::vector<glm::vec3> temp_vertices; 
	std::vector<glm::vec2> temp_uvs; 
	std::vector<glm::vec3> temp_normals;

	FILE * file = fopen(path, "r");
	if( file == NULL ){
		printf("File %s not found\n", path);
		return false;
	}

	while(true) {

		char lineHeader[128];
		// read the first word of the line
		int res = fscanf(file, "%s", lineHeader);
		if (res == EOF)
			break; // EOF = End Of File. Quit the loop.

		// else : parse lineHeader
		int temp;
		if ( strcmp( lineHeader, "v" ) == 0 ){
			glm::vec3 vertex;
			temp = fscanf(file, "%f %f %f\n", &vertex.x, &vertex.y, &vertex.z );
			temp_vertices.push_back(vertex);
		} else if ( strcmp( lineHeader, "vt" ) == 0 ){
			glm::vec2 uv;
			temp = fscanf(file, "%f %f\n", &uv.x, &uv.y );
			uv.y = -uv.y; // Invert V coordinate since we will only use DDS texture, which are inverted. Remove if you want to use TGA or BMP loaders.
			temp_uvs.push_back(uv);
		} else if ( strcmp( lineHeader, "vn" ) == 0 ){
			glm::vec3 normal;
			temp = fscanf(file, "%f %f %f\n", &normal.x, &normal.y, &normal.z );
			temp_normals.push_back(normal);
		} else if ( strcmp( lineHeader, "f" ) == 0 ){
			unsigned int vertexIndex[3], uvIndex[3], normalIndex[3];
			int matches = fscanf(file, "%d//%d %d//%d %d//%d\n", &vertexIndex[0], &normalIndex[0], &vertexIndex[1], &normalIndex[1], &vertexIndex[2], &normalIndex[2]);
			if (matches != 6) {
				printf("Invalid face specification\n");
				fclose(file);
				return false;
			}
			vertexIndices.push_back(vertexIndex[0]);
			vertexIndices.push_back(vertexIndex[1]);
			vertexIndices.push_back(vertexIndex[2]);
			normalIndices.push_back(normalIndex[0]);
			normalIndices.push_back(normalIndex[1]);
			normalIndices.push_back(normalIndex[2]);
		} else{
			// Probably a comment, eat up the rest of the line
			char stupidBuffer[1000];
			char *temp;
			temp = fgets(stupidBuffer, 1000, file);
		}

	}

	// For each vertex of each triangle
	for(unsigned int i=0; i < vertexIndices.size(); i++ ) {

		// Get the indices of its attributes
		unsigned int vertexIndex = vertexIndices[i];
		unsigned int normalIndex = normalIndices[i];
		
		// Get the attributes thanks to the index
		glm::vec3 vertex = temp_vertices[ vertexIndex-1 ];
		glm::vec3 normal = temp_normals[ normalIndex-1 ];
		
		// Put the attributes in buffers
		out_vertices.push_back(vertex);
		out_normals .push_back(normal);
	
	}
	fclose(file);
	return true;
}



int main( void ) {
  
	if (!glfwInit()) {
		fprintf(stderr, "ERROR: could not start GLFW3\n");
		return 1;
	} 

	window = glfwCreateWindow(1280, 1024, "Flexseal", NULL, NULL);
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

    // Hide the mouse and enable unlimited mouvement
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    
    // Set the mouse at the center of the screen
    glfwPollEvents();
    glfwSetCursorPos(window, 1280/2, 1024/2);

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
	GLuint programID = LoadShaders( "../common/shaders/flat_shader.vert", "../common/shaders/passthrough.frag" );
	glUseProgram(programID);


	// Get a handle for our uniforms
	GLuint ModelViewID = glGetUniformLocation(programID, "ModelView");
	GLuint ProjectionID = glGetUniformLocation(programID, "Projection");
	GLuint AmbientProductID = glGetUniformLocation(programID, "AmbientProduct"); 
	GLuint DiffuseProductID = glGetUniformLocation(programID, "DiffuseProduct"); 
	GLuint SpecularProductID = glGetUniformLocation(programID, "SpecularProduct"); 
	GLuint LightPositionID = glGetUniformLocation(programID, "LightPosition"); 


	// Read our .obj file
	std::vector<glm::vec3> vertices;
	std::vector<glm::vec3> normals; 
	bool res = loadOBJ2("../common/models/seal.obj", vertices, normals);

	// Load it into a VBO
	GLuint vertexbuffer;
	glGenBuffers(1, &vertexbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(glm::vec3), &vertices[0], GL_STATIC_DRAW);

	GLuint normalbuffer;
	glGenBuffers(1, &normalbuffer);
	glBindBuffer(GL_ARRAY_BUFFER, normalbuffer);
	glBufferData(GL_ARRAY_BUFFER, normals.size() * sizeof(glm::vec3), &normals[0], GL_STATIC_DRAW);

	// 1st attribute buffer : vertices
	glEnableVertexAttribArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	// 2nd attribute buffer : normals
	glEnableVertexAttribArray(1);
	glBindBuffer(GL_ARRAY_BUFFER, normalbuffer);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);

	// Initial values for viewing and lighting
	glm::vec3 const& Translate = glm::vec3(0.0f,0.0f,-10.0f);
 	glm::vec3 Rotate = glm::vec3(-3.14/6.0f,3.14/3.0f,0.0f);
	glm::mat4 Projection = glm::perspective(45.0f, 4.0f / 3.0f, 0.1f, 100.f);
	glm::mat4 ViewTranslate = glm::translate(glm::mat4(1.0f), Translate);
 	glm::mat4 ViewRotateX = glm::rotate(ViewTranslate, Rotate.y, glm::vec3(-1.0f, 0.0f, 0.0f));
 	glm::mat4 View = glm::rotate(ViewRotateX, Rotate.x, glm::vec3(0.0f, 1.0f, 0.0f));
 	glm::mat4 Model = glm::scale(glm::mat4(1.0f), glm::vec3(1.0f));

	glm::mat4 ModelView = View * Model;


	glm::vec4 light_position(0.0, 0.0, 1.0, 0.0);
	glm::vec4 light_ambient(0.2, 0.2, 0.2, 1.0);
	glm::vec4 light_diffuse(1.0, 1.0, 1.0, 1.0);
	glm::vec4 light_specular(1.0, 1.0, 1.0, 1.0);

	glm::vec4 material_ambient(1.0, 1.0, 1.0, 1.0);
	glm::vec4 material_diffuse(1.0, 1.0, 1.0, 1.0);
	glm::vec4 material_specular(1.0, 1.0, 1.0, 1.0);

	glm::vec4 ambient_product = light_ambient * material_ambient;
	glm::vec4 diffuse_product = light_diffuse * material_diffuse;
	glm::vec4 specular_product = light_specular * material_specular;

	// Send our uniforms to the currently bound shader
	glUniformMatrix4fv(ModelViewID, 1, GL_FALSE, &ModelView[0][0]);
	glUniformMatrix4fv(ProjectionID, 1, GL_FALSE, &Projection[0][0]);
	glUniform4fv(LightPositionID, 1, &light_position[0]);
	glUniform4fv(AmbientProductID, 1, &ambient_product[0]);
	glUniform4fv(DiffuseProductID, 1, &diffuse_product[0]);
	glUniform4fv(SpecularProductID, 1, &specular_product[0]);

	int frame_count = 0;
	float rotate_amount = 3.14/60;
	float diffuse_amount = -0.1;
	int diffuse_offset = 0;
	do {


		// Update values for viewing and lighting
		frame_count++;

		if (frame_count % 10 == 0) {
	 		Rotate[0] += rotate_amount;
 			ViewRotateX = glm::rotate(ViewTranslate, Rotate.y, glm::vec3(-1.0f, 0.0f, 0.0f));
 			View = glm::rotate(ViewRotateX, Rotate.x, glm::vec3(0.0f, 1.0f, 0.0f));
			ModelView = View * Model;
			glUniformMatrix4fv(ModelViewID, 1, GL_FALSE, &ModelView[0][0]);
		}

		if (frame_count % 200 == 0) {
			rotate_amount *= -1.0;
		}

		if (frame_count % 400 == 0) {
			diffuse_product[diffuse_offset] += diffuse_amount;
			if (diffuse_product[diffuse_offset] <= 0.0) {
				diffuse_product[diffuse_offset] = 0.0;
				diffuse_amount *= -1.0;
			}
			if (diffuse_product[diffuse_offset] >= 1.0) {
				diffuse_amount *= -1.0;
				diffuse_offset++;
				diffuse_offset %= 3;
			}
			glUniform4fv(DiffuseProductID, 1, &diffuse_product[0]);
		}

		// Clear the screen
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);



		// Draw the seal!
		glDrawArrays(GL_TRIANGLES, 0, vertices.size());		

		// Swap buffers
		glfwSwapBuffers(window);
		glfwPollEvents();




	} while( glfwGetKey(window, GLFW_KEY_ESCAPE ) != GLFW_PRESS && glfwWindowShouldClose(window) == 0 );
	
	glfwTerminate();

	return 0;
}

