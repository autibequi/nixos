// needs damage tracking to be 0

precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;
uniform vec2 resolution;
out vec4 fragColor;

const float PHI = 1.6180339887498948;  // Φ = Golden Ratio

float rand(vec2 co) {
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

void main() {
    vec2 uv = v_texcoord;

    float randtime = rand(vec2(0.01, 4200.0)) * 44.0;

    uv.x += sin(uv.y * 7.0 + (time * randtime)) * 0.005;
    uv.y += sin(uv.x * 24.0 + (time * randtime)) * 0.005;
    vec4 pixel = texture(tex, uv);

    fragColor = pixel;
}

// vim: ft=glsl