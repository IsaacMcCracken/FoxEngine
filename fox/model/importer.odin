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
  index_count: u32,
  reserved: u32,
}

import "core:os"
import "core:mem"
import "core:slice"
import "core:fmt"

load_s3d :: proc(filename: string, allocator := context.allocator) -> (model: Model, ok: bool) {
  context.allocator = allocator

  
  data, err := os.read_entire_file_from_filename(filename)
  fmt.println("error", err)
  header_backing := data[:size_of(Header)]

  header := transmute(^Header)raw_data(header_backing)

  fmt.println(header)

  vertex_end := size_of(Header) + size_of(Vertex) * header.vertex_count
  vertices := slice.reinterpret([]Vertex, data[size_of(header):vertex_end])

  indices := slice.reinterpret([]u16, data[vertex_end:])

  assert(u32(len(vertices)) == header.vertex_count)
  assert(u32(len(indices)) == header.index_count)

  ok = true

  model.indices = indices
  model.vertices = vertices

  return
}