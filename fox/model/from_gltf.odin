package fox_model

import "core:os"
import "core:mem"
import "core:slice"
import "core:strings"
import "core:fmt"
import gltf "shared:glTF2"



Model :: struct {
  vertices: []Vertex,
  indices: []u16
}

main :: proc() {
  data, gltf_err := gltf.load_from_file("witch.glb")

  position_accesor: ^gltf.Accessor
  normal_accesor: ^gltf.Accessor
  uv_accesor: ^gltf.Accessor
  index_accessor: ^gltf.Accessor


  fmt.println("Accessor Count:", len(data.accessors))

  for mesh in data.meshes {
    for prim in mesh.primitives {
      fmt.println(prim)
      index_accessor = &data.accessors[prim.indices.?]
      for name, index in prim.attributes {
        switch name {
          case "POSITION": position_accesor = &data.accessors[index]
          case "NORMAL": normal_accesor     = &data.accessors[index]
          case "TEXCOORD_0": uv_accesor     = &data.accessors[index]
          case: fmt.println("Unkown attribute")
        }
      }
    }
  }
  

  positions := make([dynamic]vec3)
  normals := make([dynamic]vec3)
  uvs := make([dynamic]vec2)
  indices := make([dynamic]u16)

  it_positions := gltf.buf_iter_make(vec3, position_accesor, data)
  it_normals := gltf.buf_iter_make(vec3, normal_accesor, data)
  it_uvs := gltf.buf_iter_make(vec2, uv_accesor, data)
  it_indices := gltf.buf_iter_make(u16, index_accessor, data)


  for pos in gltf.buf_iter_elem(&it_positions) {
    append(&positions, pos)
  }

  for norm in gltf.buf_iter_elem(&it_normals) {
    append(&normals, norm)
  }

  for uv in gltf.buf_iter_elem(&it_uvs) {
    append(&uvs, uv)
  } 

  for index in gltf.buf_iter_elem(&it_indices) {
    append(&indices, index)
  }

  assert(len(normals) == len(positions))
  assert(len(positions) == len(uvs))

  n := len(positions)

  verts := make_slice([]Vertex, n)

  for i in 0..<n {
    verts[i] = Vertex{
      position = positions[i],
      normal = normals[i],
      uv = uvs[i]
    }
  }

  cwd := os.get_current_directory()
  scrubgle := [2]string{cwd, "/witch.s3d"}
  filepath, joggoele := strings.concatenate(scrubgle[:])
  file, f_err := os.open(filepath, os.O_CREATE)
  fmt.println(file, f_err)

  header := Header {
    magic_num = transmute(u32)[4]u8{'S', 'E', 'X', 'Y'},
    index_count = u32(len(indices)),
    vertex_count = u32(n)
  }

  os.write(file, mem.any_to_bytes(header))
  os.write(file, slice.to_bytes(verts))
  os.write(file, slice.to_bytes(indices[:]))

  f_err = os.close(file)
  fmt.println(f_err)
  fmt.println(free_all())

  load_s3d(filepath)
}