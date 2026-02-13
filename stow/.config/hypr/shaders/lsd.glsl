#version 300 es

precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
uniform mediump float time;
out vec4 fragColor;

// Deforma fortemente, causando distorção lenta e "lag"
void warpco(inout vec2 tc) {
    tc -= 0.5;
    float l = length(tc);
    tc *= (l * 2.5 + sin(time * 0.2 + l * 8.0) * 0.7);
    tc += 0.5;
}

// Ruído 1D exagerado
float rand1d(float seed) {
   return sin(seed * 1454.0 + time * 0.1) * 0.5 + 0.5;
}

// Ruído 2D exagerado
float rand2d(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453 + time * 0.2);
}

// RGB com deslocamento exagerado e lento
vec3 rgb(in vec2 tc, float freq, float amp, inout vec4 centre) {
    float slow = sin(time * 0.3) * 0.5 + 0.5;
    vec2 off = vec2(1.0 / 200.0, 0.0) * sin(tc.t * freq * 0.2 + time * 0.2) * amp * slow;
    vec2 off2 = vec2(1.0 / 200.0, 0.0) * sin(tc.t * freq * 0.2 - time * 0.3) * amp * slow;
    centre = texture(tex, tc);
    return vec3(texture(tex, tc - off * 2.0).r, centre.g, texture(tex, tc + off2 * 2.0).b);
}

void main() {
    vec2 tc = v_texcoord;
    warpco(tc);

    // Mistura lenta e exagerada
    float jank = sin(time * 0.5) * 0.2 + 0.2 * rand2d(tc * 10.0 + time * 0.1);
    tc = mix(v_texcoord, tc, jank);

    // Ruído horizontal lento e forte
    tc.x += rand2d(floor(tc * 10.0 + floor(time * 0.5))) * 0.04;
    tc.x += rand1d(floor(tc.x * 10.0)) * 0.02 * rand1d(time * 0.0005);

    // "Lag" vertical
    tc.y += sin(tc.x * 0.5 + time * 0.2) * 0.07;

    vec4 centre;
    vec3 bent = rgb(tc, 30.0, 15.0, centre);
    vec3 col = mix(centre.rgb, bent, sin(time * 0.2));

    // Simula "jank" com flicker
    float flicker = 0.8 + 0.2 * rand1d(tc.x * 100.0 + time * 0.5);
    fragColor = vec4(col * flicker, centre.a);
}
