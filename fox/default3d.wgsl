
struct Uniforms {
  ratio: f32,
  time: f32
}

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexInput {
  @location(0) position: vec3f,
  @location(1) color: vec3f,
}

struct VertexOutput {
  @builtin(position) position: vec4f,
  @location(0) color: vec3f,
}

@vertex fn vertex_main(in: VertexInput) -> VertexOutput {
  var out: VertexOutput;
  out.color = in.color;

  let alpha = cos(uniforms.time);
  let beta = sin(uniforms.time);

  var position = vec3f(
    in.position.x,
    alpha * in.position.y + beta * in.position.z,
    alpha * in.position.z + beta * in.position.y,
  );

 position.x /= position.z;
 position.y /= position.z;

  // out.position = vec4f(in.position, 1.0);
  out.position = vec4f(position.x, position.y * uniforms.ratio, position.z * 0.5 + 0.5, 1.0);
  return out;
}



@fragment fn fragment_main(in: VertexOutput) -> @location(0) vec4f {
  return vec4f((0.5*sin(uniforms.time)+0.5)*in.color, 1.0);
}