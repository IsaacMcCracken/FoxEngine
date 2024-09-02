package fox 

import "core:fmt"
import "core:strings"
import "core:encoding/hxa"
import gltf "shared:glTF2"

import "vendor:wgpu"
import "vendor:glfw"

import "math"
import "model"

vec3 :: math.vec3


Render_Pipeline_Entry :: struct {
  pipeline: wgpu.RenderPipeline,
  layout: wgpu.PipelineLayout,
}

Uniforms :: struct #align(16) {
  projection: math.mat4,
  view: math.mat4,
  model: math.mat4,
  color: vec3,
  time: f32
}

uniform_buff: wgpu.Buffer
bindgroup: wgpu.BindGroup
depth_texture_format := wgpu.TextureFormat.Depth24Plus
depth_texture: wgpu.Texture
depth_texture_view: wgpu.TextureView

witch: model.Model
texture: Texture

vertex_buff: wgpu.Buffer
index_buff: wgpu.Buffer



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
  if depth_texture != nil do wgpu.TextureRelease(depth_texture)
  depth_texture = wgpu.DeviceCreateTexture(device, &wgpu.TextureDescriptor{
    dimension = ._2D,
    format = depth_texture_format,
    mipLevelCount = 1,
    sampleCount = 1,
    usage = {.RenderAttachment},
    size = {width = config.width, height = config.height, depthOrArrayLayers = 1},
    viewFormatCount = 1,
    viewFormats = &depth_texture_format,
  })

  if depth_texture_view != nil do wgpu.TextureViewRelease(depth_texture_view)
  depth_texture_view = wgpu.TextureCreateView(depth_texture, &wgpu.TextureViewDescriptor{
    aspect = .DepthOnly,
    baseArrayLayer = 0,
    arrayLayerCount = 1,
    baseMipLevel = 0,
    mipLevelCount = 1,
    dimension = ._2D,
    format = depth_texture_format,
  })
  
  
}


position: vec3
begin_drawing :: proc() -> (ok: bool) {
  using app.render


  if is_key_down(.W) do position.z += 0.1
  if is_key_down(.S) do position.z -= 0.1
  if is_key_down(.A) do position.x += 0.1
  if is_key_down(.D) do position.x -= 0.1
  if is_key_down(.LEFT_SHIFT) do position.y -= 0.1
  if is_key_down(.SPACE) do position.y += 0.1

  h, w := get_window_size()
  uniforms := Uniforms{
    time = f32(glfw.GetTime()),
    model = math.mat_from_transform({orientation = 1, scale = {0.125, 0.125, 0.125}, position = position}),
    // model = 1,
    color = {0.2, 0.7, 0.9},
    
    view = math.look_at({0,0,-1}, {}, {0, -1, 0}),
    projection = math.perspective(80, f32(h)/f32(w), 0.01, 100)

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
  wgpu.RenderPassEncoderSetIndexBuffer(renderpass, index_buff, .Uint16, 0, u64(size_of(u16) * len(witch.indices)))
  wgpu.RenderPassEncoderSetBindGroup(renderpass, 0, bindgroup)
  wgpu.RenderPassEncoderDrawIndexed(renderpass, u32(len(witch.indices)), 1, 0, 0, 0)

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

import "core:os"



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
  
  
  ok: bool
  witch, ok = model.load_s3d("witch.s3d")
  img: Image
  img, ok = load_image_from_filename("typeing_witch.png", context.temp_allocator)
  texture, ok = load_texture_from_image(img)

  fmt.println("hopefully loaded witch:", ok)
  
  vertex_buffer_layout := create_vertex_buffer_layout(model.Vertex)
  fmt.println(vertex_buffer_layout)
  vertex_buff = wgpu.DeviceCreateBufferWithDataSlice(device, &{usage = {.Vertex, .CopyDst}, label = "Witch Vertices"}, witch.vertices)
  index_buff = wgpu.DeviceCreateBufferWithDataSlice(device, &{usage = {.Index, .CopyDst}, label = "Index Buff"}, witch.indices)
  uniform_buff = wgpu.DeviceCreateBuffer(device, &{usage = {.Uniform, .CopyDst}, label = "Uniform Buffer", size = u64(size_of(Uniforms))})
  
  
  
  binding_layout_entries := [?]wgpu.BindGroupLayoutEntry{
    {
      binding = 0,
      visibility = {.Fragment, .Vertex},
      buffer = {
        type = .Uniform,
        minBindingSize = size_of(Uniforms),
      }
      
    },
    {
      binding = 1,
      visibility = {.Fragment},
      texture = {sampleType = .Float, viewDimension = ._2D}
    }
  }
  
  bindgroup_layout_desc := wgpu.BindGroupLayoutDescriptor{
    entryCount = len(binding_layout_entries),
    entries = &binding_layout_entries[0]
  }
  
  bindgroup_layout := wgpu.DeviceCreateBindGroupLayout(device, &bindgroup_layout_desc)
  
  pipeline_layout_desc := wgpu.PipelineLayoutDescriptor{
    bindGroupLayoutCount = 1,
    bindGroupLayouts = &bindgroup_layout,
  }

  fmt.println(texture)
  some_texture_view := wgpu.TextureCreateView(texture.handle, &wgpu.TextureViewDescriptor{
    aspect = .All,
    arrayLayerCount = 1,
    mipLevelCount = 1,
    dimension = ._2D,
    format = .RGBA8Unorm,
  })

  bindgroup_entries := [?]wgpu.BindGroupEntry{
    {
      binding = 0,
      buffer = uniform_buff,
      offset = 0,
      size = size_of(Uniforms),
    },
    {
      binding = 1,
      textureView = some_texture_view,
    }
  }
  
  bindgroup_desc := wgpu.BindGroupDescriptor{
    label = "Bind Gorp",
    layout = bindgroup_layout,
    entryCount = len(bindgroup_entries),
    entries = raw_data(bindgroup_entries[:]),
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