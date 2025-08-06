// Versão C-compliant do shader CRT, baseada em https://github.com/wessles/GLSL-CRT/blob/master/shader.frag

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

const vec3 VIB_RGB_BALANCE = vec3(1.0, 1.0, 1.0);
const float VIB_VIBRANCE = 0.40;

void main() {
    vec2 tc = vec2(v_texcoord.x, v_texcoord.y);

    // Distância do centro
    float dx = abs(0.5 - tc.x);
    float dy = abs(0.5 - tc.y);

    // Suaviza as bordas
    dx = dx * dx;
    dy = dy * dy;

    tc.x = tc.x - 0.5;
    tc.x = tc.x * (1.0 + (dy * 0.05));
    tc.x = tc.x + 0.5;

    tc.y = tc.y - 0.5;
    tc.y = tc.y * (1.0 + (dx * 0.18));
    tc.y = tc.y + 0.5;

    // Pega texel e adiciona scanline
    vec4 cta = texture2D(tex, vec2(tc.x, tc.y));
    cta.rgb = cta.rgb + (sin(tc.y * 1250.0) * 0.02);

    // Cutoff
    if (tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0) {
        cta = vec4(0.0, 0.0, 0.0, 0.0);
    }

    // RGB
    vec3 color = vec3(cta.r, cta.g, cta.b);

    // Coeficientes de luminância
    vec3 VIB_coefLuma = vec3(0.212656, 0.715158, 0.072186);

    float luma = dot(VIB_coefLuma, color);

    float max_color = max(color.r, max(color.g, color.b));
    float min_color = min(color.r, min(color.g, color.b));

    float color_saturation = max_color - min_color;

    vec3 VIB_coeffVibrance = VIB_RGB_BALANCE * -VIB_VIBRANCE;
    vec3 p_col = (sign(VIB_coeffVibrance) * color_saturation - 1.0) * VIB_coeffVibrance + 1.0;

    cta.r = mix(luma, color.r, p_col.r);
    cta.g = mix(luma, color.g, p_col.g);
    cta.b = mix(luma, color.b, p_col.b);

    // Aplica resultado
    gl_FragColor = cta;
}