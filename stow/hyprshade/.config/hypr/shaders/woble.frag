// needs damage tracking to be 0

precision mediump float;

varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

uniform vec2 resolution;

float PHI = 1.6180339887498948;  // Φ = Golden Ratio

highp float rand(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main() {
    vec2 uv = v_texcoord;

    float randtime = rand(vec2(0.01,4200.0)) * 44.0;

    uv.x += sin(uv.y * 7.0 + (time * randtime)) * 0.005;
    uv.y += sin(uv.x * 24.0 + (time * randtime)) * 0.005;
    vec4 pixel = texture2D(tex, uv);

    gl_FragColor = pixel;
}

// vim: ft=glsl