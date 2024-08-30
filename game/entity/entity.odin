package entity

import "../../fox/math"
import "core:mem"

vec2 :: math.vec2
vec3 :: math.vec3
vec4 :: math.vec4

mat2 :: math.mat2
mat3 :: math.mat3
mat4 :: math.mat4

quat :: math.quat

Transform :: math.Transform

ID :: u32

Nil_ID :: ~u32(0)

Link :: struct #align(8) {
  next: ID, 
  prev: ID
}

Entity :: struct {
  using link: Link,
  using transform: Transform,
}

List :: struct #align(8) {
  first: ID,
  last: ID
}

Iterator :: struct {
  next: ID,
  curr: ID,
  entities: ^[dynamic]Entity
}

Nil_List :: List{Nil_ID, Nil_ID}



Manager :: struct {
  entities: [dynamic]Entity,
  using list: List,
  free_list: List,
}

make_manager :: proc(allocator := context.allocator, capacity := 64, loc := #caller_location) -> (m: Manager, err: mem.Allocator_Error) {
  m.list = Nil_List
  m.free_list = Nil_List
  m.entities, err = make_dynamic_array_len_cap([dynamic]Entity, 0, capacity, allocator, loc)

  return m, err
}

iterate_list :: proc(l: List, e: ^[dynamic]Entity) -> (iterator: Iterator) {
  iterator.curr = l.first
  if iterator.curr != Nil_ID do iterator.next = e[l.first].next
  iterator.entities = e

  return iterator
}

iterate_manager :: proc(m: ^Manager) -> Iterator {
  return iterate_list(m.list, &m.entities)
}

iter :: proc(iter: ^Iterator) -> (e: ^Entity, ok: bool) {
  if iter.curr != Nil_ID {
    ok = true
    e = &iter.entities[iter.curr]
    iter.curr = iter.next
    iter.next = e.next
  }


  return
}
