#ifndef TRIANGLE_H
#define TRIANGLE_H

#include "Shader.h"
#include "Utility.h"

namespace cpre480_ex
{

class Triangle
{

public:
	Triangle()  {}
	~Triangle() {}

public:
				
	void Init()		;
	void Render()	;
	void Shutdown()	;


private:
	void init_shader();
	void init_buffer();
	void init_vertexArray();

private:

	GLuint vao     = cpre480_ex::OGL_VALUE;
	GLuint vbo     = cpre480_ex::OGL_VALUE;
	GLuint program = cpre480_ex::OGL_VALUE;

	ogl::Shader TriangleShader ={"Triangle Shader"};
	GLuint m_VertexCount = 0;
};


}
#endif