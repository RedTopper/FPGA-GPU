#version 430 core

// location 0 is gl_FragCoord
layout (location = 1) in vec4 vColor;
layout (location = 2) in vec2 vUv;

// By default, OpenGL draws the 0th output 
layout (location = 0) out vec4 fColor;
layout (location = 1) out vec4 fragCoordOut;

// Texture
uniform sampler2D _tex;

void main() {
    fragCoordOut = gl_FragCoord;
    fColor = texture2D(_tex, vUv);
}
