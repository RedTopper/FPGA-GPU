#ifndef SGP_SURFACE_SGP_HPP
#define SGP_SURFACE_SGP_HPP

#include "Core/Surface.hpp"

struct GLFWwindow;
namespace SuperHaxagon {
	struct Vertex {
		Vec3f pos;
		Vec3f color;
		Vec2f uv;
	};

	class Platform;
	class SurfaceSGP : public Surface {
	public:
		explicit SurfaceSGP(Platform& platform);
		~SurfaceSGP() override = default;

		void drawPolyAbsolute(const Color& color, const std::vector<Vec2f>& points) override;

		Vec2f getScreenDim() const override;
		void screenBegin() override;
		void screenFinalize() override;
		GLFWwindow* getWindow() const;
		float getAndIncrementZ();

	private:
		GLFWwindow* _window;
		float _z = 0.0f;
	};
}

#endif //SGP_SURFACE_SGP_HPP
