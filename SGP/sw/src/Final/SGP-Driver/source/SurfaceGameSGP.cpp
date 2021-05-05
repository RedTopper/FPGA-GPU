#include "SurfaceGameSGP.hpp"

static const char* vertex_shader = R"text(
#version 330 core

layout(location = 0) in vec2 v_position;
layout(location = 1) in vec4 v_color;
layout(location = 2) in float v_z;

out vec4 f_color;

uniform float s_width;
uniform float s_height;

void main() {
	float x_norm = (v_position.x / s_width - 0.5) * 2.0;
	float y_norm = (v_position.y / s_height - 0.5) * -2.0;

	gl_Position = vec4(x_norm, y_norm, v_z, 1.0);
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

}
