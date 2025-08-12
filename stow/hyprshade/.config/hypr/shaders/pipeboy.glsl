#version 300 es

precision mediump float;

// Pip-Boy Effect Fragment Shader
// by Gemini

in vec2 v_texCoord;
uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform float u_time;

// --- Customization Uniforms ---
uniform vec3 u_pipboyColor;
uniform float u_vignetteIntensity;
uniform float u_scanlineIntensity;
uniform float u_distortion;
uniform float u_noiseIntensity;

out vec4 fragColor;

// Gerador de ruído simples
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    // 1. Distorção de barril (curvatura)
    vec2 centeredCoord = (v_texCoord - 0.5) * 2.0;
    float aspect = u_resolution.y / u_resolution.x;
    centeredCoord.x *= aspect;
    float dist = length(centeredCoord);
    vec2 distortedCoord = centeredCoord * (1.0 - dist * u_distortion);
    distortedCoord.x /= aspect;
    vec2 finalCoord = distortedCoord * 0.5 + 0.5;

    // 2. Amostra da textura
    vec4 baseColor = vec4(0.0);
    if (finalCoord.x >= 0.0 && finalCoord.x <= 1.0 && finalCoord.y >= 0.0 && finalCoord.y <= 1.0) {
        baseColor = texture(u_texture, finalCoord);
    }

    // 3. Monocromático
    float luminance = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 monochromeColor = luminance * u_pipboyColor;

    // 4. Scanlines
    float scanlineEffect = sin(v_texCoord.y * u_resolution.y * 2.0) * u_scanlineIntensity + (1.0 - u_scanlineIntensity);
    vec3 colorWithScanlines = monochromeColor * scanlineEffect;

    // 5. Vignette
    float vignetteEffect = 1.0 - smoothstep(0.4, 1.2, length(centeredCoord)) * u_vignetteIntensity;
    vec3 colorWithVignette = colorWithScanlines * vignetteEffect;

    // 6. Ruído/flicker
    float noise = (random(v_texCoord + u_time) - 0.5) * u_noiseIntensity;
    vec3 finalColor = colorWithVignette + noise;

    fragColor = vec4(finalColor, baseColor.a);
}
