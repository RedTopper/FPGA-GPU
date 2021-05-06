#include "SurfaceGameSGP.hpp"

#include "Core/Platform.hpp"

static const char* vertex_shader = R"text(
#version 430 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;

// location 0 is gl_Position
layout (location = 1) out vec4 vColor;

void main() {
  gl_Position = vec4(position, 1.0);
  vColor = color;
}
)text";

static const char* fragment_shader = R"text(
#version 430 core

// location 0 is gl_FragCoord
layout (location = 1) in vec4 vColor;

// By default, OpenGL draws the 0th output
layout (location = 0) out vec4 fColor;
layout (location = 1) out vec4 fragCoordOut;

void main() {
    fragCoordOut = gl_FragCoord;
    fColor = vColor;
}
)text";

namespace SuperHaxagon {
	SurfaceGameSGP::SurfaceGameSGP(Platform& platform, Surface* surface) : SurfaceGame(surface) {
		glGenVertexArrays(1, &_vao);
		glBindVertexArray(_vao);

		const auto vs = SurfaceSGP::compile(platform, GL_VERTEX_SHADER, vertex_shader);
		const auto fs = SurfaceSGP::compile(platform, GL_FRAGMENT_SHADER, fragment_shader);

		_program = glCreateProgram();
		glAttachShader(_program, vs);
		glAttachShader(_program, fs);
		glLinkProgram(_program);
		glUseProgram(_program);

		glGenBuffers(1, &_vboPos);
		glBindBuffer(GL_ARRAY_BUFFER, _vboPos);

		glGenBuffers(1, &_vboColor);
		glBindBuffer(GL_ARRAY_BUFFER, _vboColor);
	}

	SurfaceGameSGP::~SurfaceGameSGP() {
		glDeleteBuffers(1, &_vboPos);
		glDeleteBuffers(1, &_vboColor);
		glDeleteBuffers(1, &_vao);
		glDeleteProgram(_program);
	}

	void SurfaceGameSGP::render() {
		glUseProgram(_program);
		glBindVertexArray(_vao);

		glEnableVertexAttribArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, _vboPos);
		glBufferData(GL_ARRAY_BUFFER, static_cast<GLsizei>(_pos.size() * sizeof(Vec3f)), _pos.data(), GL_DYNAMIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);

		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, _vboColor);
		glBufferData(GL_ARRAY_BUFFER, static_cast<GLsizei>(_colors.size() * sizeof(OpenGLColor)), _colors.data(), GL_DYNAMIC_DRAW);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, nullptr);

		glDrawArrays(GL_TRIANGLES, 0, static_cast<GLsizei>(_colors.size()));
		_colors.clear();
		_pos.clear();
	}

	void SurfaceGameSGP::drawPolyGame(const Color& color, std::vector<Vec2f>& points) {
		_surface->drawPolyAbsolute(color, points);

		const auto screen = _surface->getScreenDim();
		for(auto& p : points) {
			// Fix aspect ratio
			if (screen.x > screen.y) {
				p.y *= screen.x / screen.y;
			} else {
				p.x *= screen.y / screen.x;
			}
		}

		OpenGLColor col {
			static_cast<float>(color.r) / 255.0f,
			static_cast<float>(color.g) / 255.0f,
			static_cast<float>(color.b) / 255.0f,
			static_cast<float>(color.a) / 255.0f
		};

		for (size_t i = 1; i < points.size() - 1; i++) {
			_pos.emplace_back(points[0].x, points[0].y, 0);
			_pos.emplace_back(points[i].x, points[i].y, 0);
			_pos.emplace_back(points[i + 1].x, points[i + 1].y, 0);
			_colors.push_back(col);
			_colors.push_back(col);
			_colors.push_back(col);
		}
	}
}
