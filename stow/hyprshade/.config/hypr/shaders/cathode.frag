#version 300 es

precision mediump float;
in vec2 v_texcoord;

uniform sampler2D tex;
uniform float time;
out vec4 fragColor;

void main() {
    vec2 tc = vec2(v_texcoord.x, v_texcoord.y);

    // Distância do centro
    float dx = abs(0.5 - tc.x);
    float dy = abs(0.5 - tc.y);

    // Suaviza as bordas
    dx *= dx;
    dy *= dy;

    tc.x -= 0.5;
    tc.x *= 1.0 + (dy * 0.03);
    tc.x += 0.5;

    tc.y -= 0.5;
    tc.y *= 1.0 + (dx * 0.03);
    tc.y += 0.5;

    // RGB offset para efeito retrô
    vec2 r_tc = tc + vec2(0.001, 0.0);
    vec2 g_tc = tc;
    vec2 b_tc = tc - vec2(0.001, 0.0);

    vec4 color;
    color.r = texture(tex, r_tc).r;
    color.g = texture(tex, g_tc).g;
    color.b = texture(tex, b_tc).b;
    color.a = 1.0;

    // Scanlines
    float scanline = sin(tc.y * 1500.0) * 0.05;
    color.rgb += scanline;

    // Ruído
    float noise = (fract(sin(dot(tc.xy + vec2(time), vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.04;
    color.rgb += noise;

    // Vinheta
    float vignette = smoothstep(0.8, 0.2, dx + dy);
    color.rgb *= vignette;

    // Linhas verticais CRT
    float lines = sin((tc.y + time * 0.1) * 40.0) * 0.02;
    color.rgb *= 1.0 - lines;

    // Transformação retrô laranja
    vec3 retroColor = vec3(
        color.r * 1.2,
        color.g * 1.0,
        color.b * 0.8
    );
    color.rgb = retroColor;

    // Cutoff
    if (tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0)
        color = vec4(0.0);

    fragColor = color;
}
