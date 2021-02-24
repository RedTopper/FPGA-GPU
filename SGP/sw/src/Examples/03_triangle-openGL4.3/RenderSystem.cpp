#include "RenderSystem.h"

namespace cpre480_ex
{


void RenderSystem::v_InitInfo()
{
	windowInfo.title += "Triangle";
}

void RenderSystem::v_Init()
{
	m_Triangle.Init();
}

void RenderSystem::v_Render()
{
	static const glm::vec4 bgColor(0.2f, 0.4f, 0.5f, 1.0f);
	glClearBufferfv(GL_COLOR, 0, &bgColor[0]);

	m_Triangle.Render();
}

void RenderSystem::v_Shutdown()
{
	m_Triangle.Shutdown();
}


}
