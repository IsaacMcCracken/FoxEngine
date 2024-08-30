package fox_model

import "../math"

vec2 :: math.vec2
vec3 :: math.vec3
vec4 :: math.vec4

mat2 :: math.mat2
mat3 :: math.mat3
mat4 :: math.mat4

quat :: math.quat

Transform :: math.Transform

Vertex :: struct {
  position: vec3,
  normal: vec3,
  uv: vec2,
}

Header :: struct {
  magic_num: u32,
  vertex_count: u32,
  index_count: u32
}