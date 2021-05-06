#ifndef SGP_SURFACE_GAME_SGP_HPP
#define SGP_SURFACE_GAME_SGP_HPP

#include "Core/SurfaceGame.hpp"

#include "SurfaceSGP.hpp"

#include <array>

namespace SuperHaxagon {
	class Platform;
	class SurfaceGameSGP : public SurfaceGame {
	public:
		SurfaceGameSGP(Platform& platform, Surface* surface);
		~SurfaceGameSGP() override;

		void drawPolyGame(const Color& color, std::vector<Vec2f>& points) override;

		void render();

	private:
		GLuint _program = 0;
		GLuint _vao = 0;
		GLuint _vboPos = 0;
		GLuint _vboColor = 0;
		std::vector<Vec3f> _pos{};
		std::vector<OpenGLColor> _colors{};
	};
}

#endif //SGP_SURFACE_GAME_SGP_HPP
