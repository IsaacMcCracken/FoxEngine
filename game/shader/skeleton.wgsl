
struct Skeleton {
  model_matrix: mat4x4f,
  bones: array<mat4x4f, 63>,
}

struct Camera {
  view: mat4x4f,
  projection: mat4x4f,
}

struct VertexInput {
  @location(0) position: vec3f,
  @location(1) normal: vec3f,
  @location(2) uv: vec2f,
  @location(3) weights: array<f32,4>,
  @location(4) weight_indices: array<u32, 4>,
}

struct VertexOutput {
  @builtin(position) position: vec4f,
}

@group(0) @binding(0) var<uniform> camera: Camera;
@group(1) @binding(0) var<uniform> skeleton: Skeleton;


@vertex fn skeleton_main(in: VertexInput) -> VertexOutput {
  var position = vec4f(in.position, 1.0);
  var m: mat4x4f = 0;
  for (var i: i32 = 0; i < 4; i++) {
    let bone_index = in.weight_indices[i];
    m += in.weights[i] * skeleton.bones[bone_index];
  }

  var out: VertexOutput;
  out.position = camera.projection * camera.view * skeleton.model_matrix * m * position;

  return out;
} 