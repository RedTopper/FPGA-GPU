#include "SurfaceSGP.hpp"

#include "PlatformSGP.hpp"

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <cstdio>
#include <cstdlib>
#include <sstream>

namespace SuperHaxagon {
	SurfaceSGP::SurfaceSGP(Platform& platform) {
		platform.message(Dbg::INFO, "platform", "booting");

		if (!glfwInit()) {
			fprintf(stderr, "ERROR: could not start GLFW3\n");
			exit(1);
		}

		_window = glfwCreateWindow(640, 480, "Super Haxagon", nullptr, nullptr);

		if (!_window) {
			fprintf(stderr, "ERROR: could not open window with GLFW3\n");
			glfwTerminate();
			exit(1);
		}

		glfwMakeContextCurrent(_window);

		// start GLEW extension handler
		glewExperimental = GL_TRUE;
		glewInit();

		// Ensure we can capture the escape key being pressed below
		glfwSetInputMode(_window, GLFW_STICKY_KEYS, GL_TRUE);

		// blue background
		glClearColor(0, 0, 1.0f, 0);

		glEnable(GL_DEBUG_OUTPUT);
		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_GREATER);
		glDepthRange(0.0f, 1.0f);
		glClearDepth(12.0f);

		glEnableVertexAttribArray(0);
		glEnableVertexAttribArray(1);
		glEnableVertexAttribArray(2);

		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), reinterpret_cast<void*>(offsetof(Vertex, pos)));
		glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), reinterpret_cast<void*>(offsetof(Vertex, color)));
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), reinterpret_cast<void*>(offsetof(Vertex, uv)));
	}

	void SurfaceSGP::drawPolyAbsolute(const Color& color, const std::vector<Vec2f>& points) {

	}

	Vec2f SurfaceSGP::getScreenDim() const {
		int width, height;
		glfwGetWindowSize(_window, &width, &height);
		Vec2f point(static_cast<float>(width), static_cast<float>(height));
		return point;
	}

	void SurfaceSGP::screenBegin() {
		_z = 0.0f;
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	}

	void SurfaceSGP::screenFinalize() {
		glfwPollEvents();
		glfwSwapBuffers(_window);
	}

	GLFWwindow* SurfaceSGP::getWindow() const {
		return _window;
	}

	float SurfaceSGP::getAndIncrementZ() {
		const auto step = 0.00001f;
		const auto z = _z;
		_z += step;
		return z;
	}
}
