#version 400

uniform struct LightInfo {
    vec4 Position;
    vec3 Intensity;
} Light;

in vec3 Position;
in vec3 Normal;
in vec2 TexCoord;

layout (location = 0) out vec4 FragColor;

uniform sampler2D AOTex;
uniform sampler2D DiffTex;

vec3 phongModelDiffuse()
{
    vec3 n = Normal;
    vec3 s = normalize(vec3(Light.Position) - Position);
    float sDotN = max( dot(s,n), 0.0 );
    vec3 diffColor = texture(DiffTex, TexCoord).rgb;
    return Light.Intensity * diffColor * sDotN;
}

void main() {
    vec3 diffuse = phongModelDiffuse();

    vec4 aoFactor = texture(AOTex, TexCoord);

    FragColor = vec4( diffuse * aoFactor.r, 1.0);
}
