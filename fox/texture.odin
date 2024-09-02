package fox

import "vendor:wgpu"
import "base:builtin"
import "core:fmt"

Texture :: struct {
  width, height: u32,
  handle: wgpu.Texture,
}

load_texture_from_image :: proc(img: Image) -> (tex: Texture, ok: bool) {
  using app.render
  
  desc := wgpu.TextureDescriptor{
    dimension = ._2D,
    format = .RGBA8Unorm,
    mipLevelCount = 1,
    sampleCount = 1,
    size = {img.width, img.height, 1},
    usage = {.TextureBinding, .CopyDst},
  }

  handle := wgpu.DeviceCreateTexture(device, &desc)

  dest := wgpu.ImageCopyTexture{
    texture = handle,
  }

  src := wgpu.TextureDataLayout{
    bytesPerRow = 4 * desc.size.width,
    rowsPerImage = desc.size.height,
  }

  wgpu.QueueWriteTexture(queue, &dest, raw_data(img.data), len(img.data), &src, &desc.size)
  // fmt.println("Texture Descriptor:", desc)


  // buffer := wgpu.DeviceCreateBufferWithData(
  //   device, 
  //   &{
  //     label = "Temp Buffer",
  //     usage = {.CopySrc}
  //   },
  //   img.data
  // )
  // defer wgpu.BufferRelease(buffer)

  // handle := wgpu.DeviceCreateTexture(device, &desc)

  // encoder := wgpu.DeviceCreateCommandEncoder(device, &{label="Texture Buffer Copy Encoder"})
  // defer wgpu.CommandEncoderRelease(encoder)
  // fmt.println("Encoder:", encoder)

  // wgpu.CommandEncoderCopyBufferToTexture(
  //   encoder, 
  //   &wgpu.ImageCopyBuffer{
  //     buffer = buffer,
  //     layout = wgpu.TextureDataLayout{
  //       offset = 0,
  //       bytesPerRow = 4 * img.width * img.width,
  //       rowsPerImage = img.height
  //     }
  //   },
  //   &wgpu.ImageCopyTexture{
  //     texture = handle,
  //     mipLevel = 0,
  //   },
  //   &desc.size
  // )

  // cmd := wgpu.CommandEncoderFinish(encoder)
  // wgpu.RawQueueSubmit(queue, 1, &cmd)

  tex = Texture {
    width = img.width,
    height = img.height,
    handle = handle,
  }


  return tex, true
}


load_texture_from_filename :: proc(filename: string, allocator:=context.allocator) -> (tex: Texture, ok: bool) {
  context.allocator = allocator
  img: Image
  img, ok = load_image_from_filename(filename)
  if !ok do return  

  defer delete(img.data)

  tex, ok = load_texture_from_image(img)

  return 
}

// write_mip_maps :: proc(texture: Texture, data: []byte) {
//   dest := wgpu.ImageCopyTexture{
//     texture = texture.handle,
//     mipLevel = 0,
//     origin = {0, 0, 0},
//     aspect = .All,
//   }

//   src := wgpu.TextureDataLayout{
//     offset = 0,
//     bytesPerRow = 4 * texture.width,
//     rowsPerImage = texture.height,
//   }

//   fmt.println(len(data), "==", 4 * texture.height * texture.width)

  
//   // wgpu.QueueWriteTexture(app.render.queue, &dest, raw_data(data), uint(len(data)), &src, &{texture.width, texture.height, 1})
// }