
struct Uniforms {
  projection: mat4x4f,
  view: mat4x4f,
  model: mat4x4f,
  color: vec3f,
  time: f32,
}

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var albedo: texture_2d<f32>;

struct VertexInput {
  @location(0) position: vec3f,
  @location(1) normal: vec3f,
  @location(2) uv: vec2f
}

struct VertexOutput {
  @builtin(position) position: vec4f,
  @location(0) normal: vec3f,
  @location(1) uv: vec2f,
  
}

@vertex fn vertex_main(in: VertexInput) -> VertexOutput {
  var out: VertexOutput;
  
  out.position = uniforms.projection * uniforms.view * uniforms.model * vec4f(in.position, 1.0);
  out.uv = in.uv;
  out.normal = normalize(uniforms.model * vec4f(in.normal, 0.0)).xyz;
  return out;
}

const one_over_root_3 = 0.57735026919;
const light_dir = vec3f(one_over_root_3, -one_over_root_3, one_over_root_3);

fn cel_range(x: f32) -> f32 {
  return smoothstep(0.05, 0.06, x);
}


@fragment fn fragment_main(in: VertexOutput) -> @location(0) vec4f {
  let intensity = clamp(cel_range(dot(in.normal, light_dir)), 0.1, 1.0);
  // let intensity = 1.0;
  let texelCoords = vec2u(in.uv * vec2f(textureDimensions(albedo)));
  let color =  textureLoad(albedo, texelCoords, 0).rgb;
  return vec4f(intensity * color , 1.0);
}