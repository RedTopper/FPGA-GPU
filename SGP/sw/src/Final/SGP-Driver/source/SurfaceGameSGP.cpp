#include "SurfaceGameSGP.hpp"

#include "Core/Platform.hpp"

static const char* vertex_shader = R"text(
#version 330 core

layout(location = 0) in vec3 v_position;
layout(location = 1) in vec4 v_color;

out vec4 f_color;

void main() {
	gl_Position = vec4(v_position.x, v_position.y, v_position.z, 1.0);
	f_color = v_color;
}
)text";

static const char* fragment_shader = R"text(
#version 330 core

layout(location = 0) out vec4 color;

in vec4 f_color;

void main() {
	color = f_color;
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
		glBufferData(GL_ARRAY_BUFFER, static_cast<GLsizei>(_count * sizeof(Vec3f)), _pos.data(), GL_DYNAMIC_DRAW);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);

		glEnableVertexAttribArray(1);
		glBindBuffer(GL_ARRAY_BUFFER, _vboColor);
		glBufferData(GL_ARRAY_BUFFER, static_cast<GLsizei>(_count * sizeof(OpenGLColor)), _colors.data(), GL_DYNAMIC_DRAW);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, nullptr);

		glDrawArrays(GL_TRIANGLES, 0, static_cast<GLsizei>(_count));
		_count = 0;
	}

	void SurfaceGameSGP::drawPolyGame(const Color& color, std::vector<Vec2f>& points) {
		if (_count + points.size() * 3 - 6 > SIZE) {
			// We're full, go home.
			return;
		}

		OpenGLColor col {
			static_cast<float>(color.r) / 255.0f,
			static_cast<float>(color.g) / 255.0f,
			static_cast<float>(color.b) / 255.0f,
			static_cast<float>(color.a) / 255.0f
		};

		for (size_t i = 1; i < points.size() - 1; i++) {
			_pos[_count] = {points[0].x, points[0].y, 0};
			_pos[_count + 1] = {points[i].x, points[i].y, 0};
			_pos[_count + 2] = {points[i + 1].x, points[i + 1].y, 0};
			_colors[_count] = col;
			_colors[_count + 1] = col;
			_colors[_count + 2] = col;
			_count += 3;
		}
	}
}
