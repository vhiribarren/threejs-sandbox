varying vec2 v_uv;

void main() {
  vec3 color = vec3(v_uv.x);
  gl_FragColor = vec4(color, 1.0);
}