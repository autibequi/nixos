precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {

  vec4 pixColor = texture2D(tex, v_texcoord);

  // calculate the perceived brightness (https://www.101computing.net/colour-luminance-and-contrast-ratio/)
  vec4 luminance = pixColor * vec4(0.2126, 0.7152, 0.0722, 1.0);
  float mono = luminance[0] + luminance[1] + luminance[2];

  // red
  pixColor[0] = mono;
  // green
  pixColor[1] = mono - 0.2126;
  // blue
  pixColor[2] = mono - 0.2126;

  gl_FragColor = pixColor;
}