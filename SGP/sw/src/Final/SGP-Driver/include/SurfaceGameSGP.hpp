#ifndef SGP_SURFACE_GAME_SGP_HPP
#define SGP_SURFACE_GAME_SGP_HPP

#include "Core/SurfaceGame.hpp"

#include "SurfaceSGP.hpp"

#include <array>

namespace SuperHaxagon {
	const int SIZE = 8192 * 4;
	class Platform;
	class SurfaceGameSGP : public SurfaceGame {
	public:
		SurfaceGameSGP(Platform& platform, Surface* surface);
		~SurfaceGameSGP() override;

		void drawPolyGame(const Color& color, std::vector<Vec2f>& points) override;

		void render();

	private:
		size_t _count = 0;
		GLuint _program = 0;
		GLuint _vao = 0;
		GLuint _vbo = 0;
		std::array<Vertex, SIZE> _vertities{};
	};
}

#endif //SGP_SURFACE_GAME_SGP_HPP
