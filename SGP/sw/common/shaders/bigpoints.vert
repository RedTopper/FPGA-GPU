#version 430 core
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 color;

// location 0 is gl_Position
layout (location = 1) out vec4 vColor;

void main() {
  gl_Position = vec4(position, 1.0);
  gl_PointSize = 4.0; //Make this as large as you need
  vColor = vec4(color, 0.0);
}
