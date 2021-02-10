#ifndef RENDERSYSTEM_H
#define RENDERSYSTEM_H

#include "App.h"
#include "triangle.h"

namespace cpre480_ex
{


class RenderSystem : public cpre480_ex::ogl::App
{
public:
	RenderSystem()  {}
	~RenderSystem() {}


public:
	void v_InitInfo() override;
	void v_Init()     override;
	void v_Render()   override;
	void v_Shutdown() override;

private:

	cpre480_ex::Triangle m_Triangle;
};


}
#endif