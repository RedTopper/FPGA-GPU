#ifndef SGP_SURFACE_SGP_HPP
#define SGP_SURFACE_SGP_HPP

#include "Core/Surface.hpp"

#include <GL/glew.h>

#include <vector>

struct GLFWwindow;
namespace SuperHaxagon {
	struct OpenGLColor {
		float r;
		float g;
		float b;
		float a;
	};

	class Platform;
	class SurfaceGameSGP;
	class SurfaceSGP : public Surface {
	public:
		explicit SurfaceSGP(Platform& platform);
		~SurfaceSGP() override = default;

		void drawPolyAbsolute(const Color& color, const std::vector<Vec2f>& points) override;

		Vec2f getScreenDim() const override;
		void screenBegin() override;
		void screenFinalize() override;

		void addSurface(SurfaceGameSGP* surface);
		GLFWwindow* getWindow() const;

		static GLuint compile(Platform& platform, GLenum type, const char* source);

	private:
		std::vector<SurfaceGameSGP*> _surfaces;
		GLFWwindow* _window;
	};
}

#endif //SGP_SURFACE_SGP_HPP
