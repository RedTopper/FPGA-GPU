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
