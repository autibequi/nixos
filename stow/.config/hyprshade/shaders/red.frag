#version 300 es

precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // Calcula a luminância percebida (https://www.101computing.net/colour-luminance-and-contrast-ratio/)
    float mono = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Realça o canal vermelho, reduz verde e azul
    fragColor = vec4(mono, mono * 0.2, mono * 0.2, pixColor.a);
}