package fox

import "core:c"
import "core:os"
import "core:image"
import "core:fmt"
Image :: struct {
  width, height: u32,
  data: []byte
}


load_image_from_memory :: proc(data: []byte, allocator:=context.allocator) -> (img: Image, ok: bool) {
  
  context.allocator = allocator
  pic, err := image.load_from_bytes(data, {.alpha_add_if_missing})
   
  img = Image{
    width = u32(pic.width),
    height = u32(pic.height),
    data = pic.pixels.buf[:]
  }

  ok = true

  return  
}

load_image_from_filename :: proc(filename: string, allocator:=context.allocator) -> (img: Image, ok: bool) {
  data: []byte
  data, ok = os.read_entire_file_from_filename(filename, allocator)
  if !ok do return  

  img, ok = load_image_from_memory(data)

  return
}