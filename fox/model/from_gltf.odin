package fox_model

import "core:os"
import "core:fmt"
import gltf "shared:glTF2"



Model :: struct {
  offset, size: u32,
  data: []Vertex,

}

main :: proc() {
  data, gltf_err := gltf.load_from_file("witch.glb")

  position_accesor: ^gltf.Accessor
  normal_accesor: ^gltf.Accessor
  uv_accesor: ^gltf.Accessor


  for mesh in data.meshes {
    for prim in mesh.primitives {
      fmt.println(prim)
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

  it_positions := gltf.buf_iter_make(vec3, position_accesor, data)
  it_normals := gltf.buf_iter_make(vec3, normal_accesor, data)
  it_uvs := gltf.buf_iter_make(vec2, uv_accesor, data)


  for pos in gltf.buf_iter_elem(&it_positions) {
    append(&positions, pos)
  }

  for norm in gltf.buf_iter_elem(&it_normals) {
    append(&normals, norm)
  }

  for uv in gltf.buf_iter_elem(&it_uvs) {
    append(&uvs, uv)
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

  fmt.println(verts)

 
}