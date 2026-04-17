// Versão compatível com ES 3.0, para evitar erro de linkagem entre shaders

#version 300 es

precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
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

    // Busca texel e adiciona scanline
    vec4 cta = texture(tex, vec2(tc.x, tc.y));
    cta.rgb += sin(tc.y * 1250.0) * 0.02;

    // Cutoff
    if(tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0)
        cta = vec4(0.0);

    fragColor = cta;
}
