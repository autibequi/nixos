#version 300 es
precision mediump float;

uniform float CRT_CURVE_AMNTx; // curve amount on x
uniform float CRT_CURVE_AMNTy; // curve amount on y
uniform float CRT_TUBE_AMNT;    // tube bulge (convex cathode curve), e.g. 0.2
#define CRT_CORNER_PINCH 0.18  // corner pull-in so edges follow convex glass
#define CRT_CASE_BORDR 0.0125
#define SCAN_LINE_MULT 1250.0
#define SCAN_LINE_DARK  0.38   // scanline strength (higher = more visible)

in vec2 v_texcoord;

uniform sampler2D tex;

out vec4 fragColor;

void main() {
    vec2 tc = vec2(v_texcoord.x, v_texcoord.y);

    // --- Convex cathode tube: sample so the flat quad looks like curved glass ---
    vec2 uv = tc - 0.5;
    float r = length(uv);
    float r2 = r * r;
    // Convex = center "magnified", so sample from smaller radius at edges (divide)
    float rScale = 1.0 + CRT_TUBE_AMNT * r2;
    uv /= rScale;
    // Corner: slight pull-in so the bezel follows the curve
    float corner = 4.0 * abs(uv.x) * abs(uv.y);
    uv /= 1.0 + CRT_CORNER_PINCH * corner;
    tc = uv + 0.5;

    // Get texel
    vec4 cta = texture(tex, vec2(tc.x, tc.y));

    // Cutoff
    if (tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0)
        cta = vec4(0.0);

    // Scanlines (darker, more visible)
    float scanline = 0.5 + 0.5 * sin(tc.y * SCAN_LINE_MULT);
    cta.rgb *= 1.0 - SCAN_LINE_DARK * scanline;

    // Luminance
    float lum = dot(cta.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Amber phosphor (cool-retro-term style): bright amber text on dark warm brown
    vec3 darkWarm = vec3(0.09, 0.045, 0.02);
    vec3 brightAmber = vec3(1.0, 0.68, 0.15);
    vec3 phosphor = mix(darkWarm, brightAmber, lum);

    // Vignette (darker edges)
    vec2 vc = v_texcoord - 0.5;
    float vignette = 1.0 - 0.45 * dot(vc, vc);
    phosphor *= vignette;

    fragColor = vec4(phosphor, cta.a);
}
