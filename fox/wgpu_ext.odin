package fox

import "base:runtime"

import "core:fmt"

import "vendor:wgpu"


Callback_Data :: struct {
  ctx: runtime.Context
 
}

wgpu_create_adapter :: proc(instance: wgpu.Instance) -> (adapter: wgpu.Adapter) {
  Data :: struct {
    ctx: runtime.Context,
    adapter: wgpu.Adapter
  }

  request_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message: cstring, /* NULLABLE */ userdata: rawptr) {
    data := transmute(^Data)userdata

    context = data.ctx

    if status != .Success {
      fmt.panicf("Could not get adapter: (%v) %v", status, message)
    }


    data.adapter = adapter
  }

  data := Data{ctx = context}

  wgpu.InstanceRequestAdapter(instance, &{}, request_adapter, &data)

  return data.adapter
}

wgpu_create_device :: proc(adapter: wgpu.Adapter) -> (device: wgpu.Device) {
  Data :: struct {
    ctx: runtime.Context,
    device: wgpu.Device,
  }

  request_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: cstring, /* NULLABLE */ userdata: rawptr) {
    data := transmute(^Data)userdata
    context = data.ctx

    if status != .Success {
      fmt.panicf("Could not get Device: (%v) %v", status, message)
    }

    data.device = device
  }

  data := Data{ctx = context}

  wgpu.AdapterRequestDevice(adapter, &{label="Device",deviceLostCallback = device_lost_callback, deviceLostUserdata = &app.callback_data}, request_device, &data)

  return data.device
}

device_lost_callback :: proc "c" (reason: wgpu.DeviceLostReason, message: cstring, userdata: rawptr) {
  data := transmute(^Callback_Data)userdata
  context = data.ctx

  fmt.panicf("Device Lost: (%v) %v", reason, message)
}

device_error_callback :: proc "c" (type: wgpu.ErrorType, message: cstring, userdata: rawptr) {
  data := transmute(^Callback_Data)userdata
  context = data.ctx
  if type != .NoError {
    fmt.println("Cum", message)
    fmt.panicf("Device Error: (%v) %v", type, message)
  }
}

