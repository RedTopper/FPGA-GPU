#version 400

layout (location = 0 ) in vec3 VertexPosition;
layout (location = 2) in vec2 VertexTexCoord;

out vec2 TexCoord;

uniform mat4 MVP;

void main()
{
    TexCoord = VertexTexCoord;
    gl_Position = MVP * vec4(VertexPosition, 1.0);
}
