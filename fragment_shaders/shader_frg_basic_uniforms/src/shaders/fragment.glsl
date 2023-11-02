varying vec2 v_uv;
uniform float u_time;

void main() {
  vec3 color = 0.5 + 0.5*cos(u_time + v_uv.xyx + vec3(0.0,2.0,4.0));
  gl_FragColor = vec4(color, 1.0);
}