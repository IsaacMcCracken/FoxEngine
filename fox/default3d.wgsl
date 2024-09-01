
struct Uniforms {
  projection: mat4x4f,
  model: mat4x4f,
  time: f32
}

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

struct VertexInput {
  @location(0) position: vec3f,
  @location(1) normal: vec3f,
  @location(2) uv: vec2f
}

struct VertexOutput {
  @builtin(position) position: vec4f,
  @location(0) color: vec3f,
}

@vertex fn vertex_main(in: VertexInput) -> VertexOutput {
  var out: VertexOutput;
  out.color = in.normal;
  
  out.position = uniforms.projection * uniforms.model * vec4f(in.position, 1.0);
  return out;
}



@fragment fn fragment_main(in: VertexOutput) -> @location(0) vec4f {
  return vec4f(in.color, 1.0);

  // return vec4f((0.5*sin(uniforms.time)+0.5)*in.color, 1.0);
}