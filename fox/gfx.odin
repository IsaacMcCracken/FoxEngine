package fox 

import "core:fmt"

import "vendor:wgpu"
import "vendor:glfw"

import "math"

vec3 :: math.vec3


Render_Pipeline_Entry :: struct {
  pipeline: wgpu.RenderPipeline,
  layout: wgpu.PipelineLayout,
}

Vertex :: struct {
  position: vec3,
}

vertex_buff: wgpu.Buffer
vertex_count :: len(vertex_data)
vertex_data := [?]Vertex{
  {position = {-0.5, -0.5, 0}},
  {position = {+0.5, -0.5, 0}},
  {position = {+0.0, +0.5, 0}}
}


// probably put that somewhere else
get_window_size :: proc() -> (width, height: u32) {
  w, h := glfw.GetWindowSize(app.window)
  return u32(w), u32(h)
}

window_resize :: proc "c" () {
  using app.render
  
  context = app.callback_data.ctx

  config.width, config.height = get_window_size()
  wgpu.SurfaceConfigure(surface, &config)
}

begin_drawing :: proc() -> (ok: bool) {
  using app.render
  surface_texture := wgpu.SurfaceGetCurrentTexture(surface)

  switch surface_texture.status {
    case .Success:
    case .Timeout, .Outdated, .Lost:
      if surface_texture.texture != nil {
        wgpu.TextureRelease(surface_texture.texture)
      }
      window_resize()
      return false
    case .DeviceLost, .OutOfMemory:
      fmt.panicf("Could Not Get Next Surface Texture: (%v)", surface_texture.status)
  }

  target_view := wgpu.TextureCreateView(
    surface_texture.texture,
    &{
      label = "Surface Texture View",
      format = format,
      baseMipLevel = 0,
      mipLevelCount = 1,
      baseArrayLayer = 0,
      arrayLayerCount = 1,
      aspect = .All,
      dimension = ._2D,
    })


  encoder := wgpu.DeviceCreateCommandEncoder(device, nil)

  renderpass := wgpu.CommandEncoderBeginRenderPass(
    encoder, 
    &wgpu.RenderPassDescriptor{
      colorAttachmentCount = 1,
      colorAttachments = &wgpu.RenderPassColorAttachment{
        view = target_view,
        loadOp = .Clear,
        storeOp = .Store,
        clearValue = { 0.9, 0.1, 0.2, 1.0 },
      }
  })
  defer wgpu.RenderPassEncoderRelease(renderpass)
  

  
  wgpu.RenderPassEncoderSetPipeline(renderpass, pipelines["default3d"])
  wgpu.RenderPassEncoderSetVertexBuffer(renderpass, 0, vertex_buff, 0, wgpu.BufferGetSize(vertex_buff))
  
  wgpu.RenderPassEncoderDraw(renderpass, vertex_count, 1, 0, 0)

  wgpu.RenderPassEncoderEnd(renderpass)
  append(&draw.commands, wgpu.CommandEncoderFinish(encoder))


  
  draw_stuff: {
    draw.encoder = encoder
    draw.texture = surface_texture
    draw.view = target_view
  }

  return true
}

end_drawing :: proc() {
  using app.render
  
  wgpu.QueueSubmit(queue, draw.commands[:])
  wgpu.SurfacePresent(surface)
  release: {
    for cmd in draw.commands do wgpu.CommandBufferRelease(cmd)
    clear(&draw.commands)
    wgpu.CommandEncoderRelease(draw.encoder)
    wgpu.TextureRelease(draw.texture.texture)
    wgpu.TextureViewRelease(draw.view)
  }
} 


create_default3D_pipeline :: proc() -> (pipeline: wgpu.RenderPipeline) {
  using app.render

  vertex_buffer_layout := wgpu.VertexBufferLayout{
    attributeCount = 1,
    attributes = &wgpu.VertexAttribute{
      format = .Float32x3,
      offset = 0,
      shaderLocation = 0,
    },
    arrayStride = u64(size_of(Vertex)),
    stepMode = .Vertex,
  }

  vertex_buff = wgpu.DeviceCreateBuffer(device, &{usage = {.Vertex, .CopyDst}, label = "Vertex Buff", size = u64(size_of(vertex_data))})

  wgpu.QueueWriteBuffer(queue, vertex_buff, 0, &vertex_data[0], size_of(vertex_data))

  shader_code_desc := wgpu.ShaderModuleWGSLDescriptor{
    sType = .ShaderModuleWGSLDescriptor,
    code = default_3d_shader_code,
  }


  default_module := wgpu.DeviceCreateShaderModule(
    app.render.device,
    &{
      label = "Default 3D Shader Module",
      nextInChain = &wgpu.ShaderModuleWGSLDescriptor{
        sType = .ShaderModuleWGSLDescriptor,
        code = default_3d_shader_code,
      }
    }
  )
  defer wgpu.ShaderModuleRelease(default_module)

  blend_state := wgpu.BlendState{
    color = {
      srcFactor = .SrcAlpha,
      dstFactor = .OneMinusSrcAlpha,
      operation = .Add
    },
    alpha = {
      srcFactor = .Zero,
      dstFactor = .One,
      operation = .Add
    }
  }

  desc := wgpu.RenderPipelineDescriptor{
    label = "The most basic render pipline",
    fragment = &wgpu.FragmentState{
      module = default_module,
      entryPoint = "fs_main",
      targetCount = 1,
      targets = &wgpu.ColorTargetState{
        format = app.render.format,
        blend = &wgpu.BlendState{
          color = {
            srcFactor = .SrcAlpha,
            dstFactor = .OneMinusSrcAlpha,
            operation = .Add,
          },
          alpha = {
            srcFactor = .Zero,
            dstFactor = .One,
            operation = .Add,
          },

        },
        writeMask = wgpu.ColorWriteMaskFlags_All
      },
    },
    vertex = wgpu.VertexState{
      module = default_module,
      entryPoint = "vs_main",
      bufferCount = 1,
      buffers = &vertex_buffer_layout,
    },
    primitive = wgpu.PrimitiveState{
      topology = .TriangleList,
      stripIndexFormat = .Undefined,
      frontFace = .CCW,
      cullMode = .None,
    },
    multisample = wgpu.MultisampleState{
      count = 1,
      mask = ~u32(0),
      alphaToCoverageEnabled = false,
    },
  }


  return wgpu.DeviceCreateRenderPipeline(app.render.device, &desc)
}


load_pipelines :: proc() {
  app.render.pipelines["default3d"] = create_default3D_pipeline()
}