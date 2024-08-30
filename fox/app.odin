package fox

import "core:strings"
import "core:fmt"

import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"

app: App
App :: struct {
  window: glfw.WindowHandle,
  callback_data: Callback_Data,
  render: struct {
    device: wgpu.Device,
    queue: wgpu.Queue,
    surface: wgpu.Surface,
    config: wgpu.SurfaceConfiguration,
    format: wgpu.TextureFormat,
    pipelines: map[string]wgpu.RenderPipeline,
    draw: struct {
      view: wgpu.TextureView,
      encoder: wgpu.CommandEncoder,
      texture: wgpu.SurfaceTexture,
      commands: [dynamic]wgpu.CommandBuffer,
    }
  }
}





app_init :: proc(width, height: i32, title: string) {
  using app
  glfw_init: {
    glfw.Init()
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    window = glfw.CreateWindow(width, height, strings.unsafe_string_to_cstring(title), nil, nil)

    // Set Callbacks
    glfw.SetKeyCallback(window, key_callback)
  }

  wgpu_init: {
    using app.render

    instance := wgpu.CreateInstance(&{})
    defer wgpu.InstanceRelease(instance)

    adapter := wgpu_create_adapter(instance)
    defer wgpu.AdapterRelease(adapter)

    callback_data = {ctx = context}
    device = wgpu_create_device(adapter)
    wgpu.DeviceSetUncapturedErrorCallback(device, device_error_callback, &callback_data)

    queue = wgpu.DeviceGetQueue(device)
    surface = glfwglue.GetSurface(instance, window)

    format = wgpu.SurfaceGetPreferredFormat(surface, adapter)
    fmt.println("Format:", format)    

    surface_config: {
      config.device = device
      config.width = u32(width)
      config.height = u32(height)
      config.presentMode = .Fifo
      config.format = format
      config.usage = {.RenderAttachment}
      config.alphaMode = .Auto
    }

    draw.commands = make_dynamic_array_len_cap([dynamic]wgpu.CommandBuffer, 0, 32)

    
    wgpu.SurfaceConfigure(surface, &config)
    
    fmt.println("Instance", instance, "Adapter", adapter, "Device", device)
    load_pipelines()
    fmt.println(pipelines)


    assert(pipelines["default3d"] != nil)
  }

  limits, ok := wgpu.DeviceGetLimits(app.render.device)
  if ok do fmt.println(limits)
  defaults: {

  }
  


}

app_deinit :: proc() {
  using app

  

  wgpu_deinit: {
    using render
    delete(draw.commands)
    wgpu.QueueRelease(queue)
    wgpu.DeviceRelease(device)
  }

  glfw_deinit: {
    glfw.DestroyWindow(window)
    glfw.Terminate()
  }
}

app_close :: proc() {
  glfw.SetWindowShouldClose(app.window, true)
}

app_running :: proc() -> (ok: bool) {
  return bool(!glfw.WindowShouldClose(app.window))
}
