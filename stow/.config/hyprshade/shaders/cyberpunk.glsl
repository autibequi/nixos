// Cyberpunk — sombras ciano, altas luzes magenta, contraste leve.
// Mix 0.35 mantém legibilidade de texto; subir pra 0.5+ se quiser mais neon.

#version 300 es

precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);

    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));

    vec3 shadow = vec3(0.05, 0.85, 1.0);   // ciano
    vec3 high   = vec3(1.0, 0.15, 0.85);   // magenta
    vec3 grade  = mix(shadow, high, l);

    c.rgb = mix(c.rgb, c.rgb * grade * 1.4, 0.35);
    c.rgb = clamp((c.rgb - 0.5) * 1.08 + 0.5, 0.0, 1.0);

    fragColor = c;
}
