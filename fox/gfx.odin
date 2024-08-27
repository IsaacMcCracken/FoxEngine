package fox 

import "core:fmt"
import "core:strings"

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
  color: vec3,
}

Uniforms :: struct {
  ratio: f32,
  time: f32
}


uniform_buff: wgpu.Buffer
bindgroup: wgpu.BindGroup
depth_texture_format := wgpu.TextureFormat.Depth24Plus
depth_texture: wgpu.Texture
depth_texture_view: wgpu.TextureView

vertex_buff: wgpu.Buffer
vertex_count :: len(vertex_data)
vertex_data := [?]Vertex{
  {position = {-0.5, -0.5, -0.3}, color = {1.0, 0.0, 0.0}},
  {position = {+0.5, -0.5, -0.3}, color = {0.0, 1.0, 0.0}},
  {position = {+0.5, +0.5, -0.3}, color = {0.0, 0.0, 1.0}},
  {position = {-0.5, +0.5, -0.3}, color = {0.0, 1.0, 0.0}},
  //tip
  {position = {0, 0, 0.5}, color = {0, 0,0}}
}

index_buff: wgpu.Buffer
index_count :: len(index_data)
index_data := [?]u16{
  // base
  0, 1, 2,
  0, 2, 3,
  // sides
  0, 1, 4,
  1, 2, 4,
  2, 3, 4,
  3, 0, 4,

  mat
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

  h, w := get_window_size()
  uniforms := Uniforms{
    ratio = f32(w)/f32(h),
    time = f32(glfw.GetTime()),
  }

  wgpu.QueueWriteBuffer(queue, uniform_buff, 0, &uniforms, size_of(Uniforms))

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
      },
      depthStencilAttachment = &{
        view = depth_texture_view,
        depthClearValue = 1.0,
        depthLoadOp = .Clear,
        depthStoreOp = .Store,
        depthReadOnly = false,
        stencilClearValue = 0,
        stencilLoadOp = .Clear,
        stencilStoreOp = .Store,
        stencilReadOnly = true,
      }
  })
  defer wgpu.RenderPassEncoderRelease(renderpass)
  

  
  wgpu.RenderPassEncoderSetPipeline(renderpass, pipelines["default3d"])
  wgpu.RenderPassEncoderSetVertexBuffer(renderpass, 0, vertex_buff, 0, wgpu.BufferGetSize(vertex_buff))
  wgpu.RenderPassEncoderSetIndexBuffer(renderpass, index_buff, .Uint16, 0, u64(size_of(u16) * index_count))
  wgpu.RenderPassEncoderSetBindGroup(renderpass, 0, bindgroup)
  wgpu.RenderPassEncoderDrawIndexed(renderpass, index_count, 1, 0, 0, 0)

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

  width, height := get_window_size()

  depth_texture = wgpu.DeviceCreateTexture(device, &wgpu.TextureDescriptor{
    dimension = ._2D,
    format = depth_texture_format,
    mipLevelCount = 1,
    sampleCount = 1,
    usage = {.RenderAttachment},
    size = {width = width, height = height, depthOrArrayLayers = 1},
    viewFormatCount = 1,
    viewFormats = &depth_texture_format,
  })

  depth_texture_view = wgpu.TextureCreateView(depth_texture, &wgpu.TextureViewDescriptor{
    aspect = .DepthOnly,
    baseArrayLayer = 0,
    arrayLayerCount = 1,
    baseMipLevel = 0,
    mipLevelCount = 1,
    dimension = ._2D,
    format = depth_texture_format,
  })
  

  
  
  
  vertex_attributes := [?]wgpu.VertexAttribute{
    {
      format = .Float32x3,
      offset = 0,
      shaderLocation = 0,
    },
    {
      format = .Float32x3,
      offset = u64(size_of(vec3)),
      shaderLocation = 1,
    }
  }
  
  vertex_buffer_layout := wgpu.VertexBufferLayout{
    attributeCount = uint(len(vertex_attributes)),
    attributes = &vertex_attributes[0],
    arrayStride = u64(size_of(Vertex)),
    stepMode = .Vertex,
  }
  
  vertex_buff = wgpu.DeviceCreateBuffer(device, &{usage = {.Vertex, .CopyDst}, label = "Vertex Buff", size = u64(size_of(vertex_data))})
  wgpu.QueueWriteBuffer(queue, vertex_buff, 0, &vertex_data[0], size_of(vertex_data))
  index_buff = wgpu.DeviceCreateBufferWithDataSlice(device, &{usage = {.Index, .CopyDst}, label = "Index Buff"}, index_data[:])
  uniform_buff = wgpu.DeviceCreateBuffer(device, &{usage = {.Uniform, .CopyDst}, label = "Uniform Buffer", size = u64(size_of(Uniforms))})
  
  
  
  binding_layout_entries := wgpu.BindGroupLayoutEntry{
    binding = 0,
    visibility = {.Fragment, .Vertex},
    buffer = {
      type = .Uniform,
      minBindingSize = size_of(Uniforms),
      
    }
  }
  
  bindgroup_layout_desc := wgpu.BindGroupLayoutDescriptor{
    entryCount = 1,
    entries = &binding_layout_entries
  }
  
  bindgroup_layout := wgpu.DeviceCreateBindGroupLayout(device, &bindgroup_layout_desc)
  
  pipeline_layout_desc := wgpu.PipelineLayoutDescriptor{
    bindGroupLayoutCount = 1,
    bindGroupLayouts = &bindgroup_layout,
  }
  
  bindgroup_desc := wgpu.BindGroupDescriptor{
    label = "Bind Gorp",
    layout = bindgroup_layout,
    entryCount = 1,
    entries = &wgpu.BindGroupEntry{
      binding = 0,
      buffer = uniform_buff,
      offset = 0,
      size = size_of(Uniforms),
    },
  }
  
  bindgroup = wgpu.DeviceCreateBindGroup(device, &bindgroup_desc)
  pipeline_layout := wgpu.DeviceCreatePipelineLayout(device, &pipeline_layout_desc)
  
  code := strings.unsafe_string_to_cstring(string(#load("default3d.wgsl")))
  
  default_module := wgpu.DeviceCreateShaderModule(
    app.render.device,
    &{
      label = "Default 3D Shader Module",
      nextInChain = &wgpu.ShaderModuleWGSLDescriptor{
        sType = .ShaderModuleWGSLDescriptor,
        code = code
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
    layout = pipeline_layout,
    fragment = &wgpu.FragmentState{
      module = default_module,
      entryPoint = "fragment_main",
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
      entryPoint = "vertex_main",
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
    depthStencil = &wgpu.DepthStencilState{
      depthCompare = .Less,
      stencilReadMask  = 0,
      stencilWriteMask = 0,
      depthWriteEnabled = true,
      format = depth_texture_format,
      stencilFront = {
        compare = .Always,
        failOp = .Keep,
        depthFailOp =.Keep,
        passOp = .Keep
      },
      stencilBack = {
        compare = .Always,
        failOp = .Keep,
        depthFailOp =.Keep,
        passOp = .Keep
      }
    }

  }


  return wgpu.DeviceCreateRenderPipeline(app.render.device, &desc)
}


load_pipelines :: proc() {
  app.render.pipelines["default3d"] = create_default3D_pipeline()
}