package fox

import "base:runtime"
import "base:intrinsics"
import "core:reflect"

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

vertex_format_float :: proc(size, n: int) -> wgpu.VertexFormat {
  switch size {
    case 2: switch n {
      case 2: return .Float16x2
      case 4: return .Float16x4
      case: return .Undefined
    }
    case 4: switch n {
      case 1: return .Float32
      case 2: return .Float32x2
      case 3: return .Float32x3
      case 4: return .Float32x4
      case: return .Undefined
    }
    case: return .Undefined
  }
}

vertex_format_int :: proc(size, n: int, signed: bool) -> wgpu.VertexFormat {
  if signed {
    switch size {
      case 1: switch n {
        case 2: return .Sint8x2
        case 4: return .Sint8x4
        case: return .Undefined
      }
      case 2: switch n {
        case 2: return .Sint16x2
        case 4: return .Sint16x4
        case: return .Undefined
      }
      case 4: switch n {
        case 1: return .Sint32
        case 2: return .Sint32x2
        case 3: return .Sint32x3
        case 4: return .Sint32x4
        case: return . Undefined
      }
    }
  } else {
    switch size {
      case 1: switch n {
        case 2: return .Uint8x2
        case 4: return .Uint8x4
        case: return .Undefined
      }
      case 2: switch n {
        case 2: return .Uint16x2
        case 4: return .Uint16x4
        case: return .Undefined
      }
      case 4: switch n {
        case 1: return .Uint32
        case 2: return .Uint32x2
        case 3: return .Uint32x3
        case 4: return .Uint32x4
        case: return . Undefined
      }
    }
  }

  return .Undefined
}

type_to_vertex_format :: proc(info: ^runtime.Type_Info) -> wgpu.VertexFormat {
  #partial switch type in info.variant {   
    case runtime.Type_Info_Float:
      return vertex_format_float(info.size, 1)
    case runtime.Type_Info_Integer:
      return vertex_format_int(info.size, 1, type.signed)   
    case runtime.Type_Info_Array:
      size := type.elem_size
      count := type.count
      #partial switch sub in type.elem.variant {
        case runtime.Type_Info_Float: return vertex_format_float(size, count)
        case runtime.Type_Info_Integer: return vertex_format_int(size, count, sub.signed)
        case: return.Undefined
      }   
    case runtime.Type_Info_Named: 
      return type_to_vertex_format(type.base)
      
    case: 
      return .Undefined
  }

  return.Undefined
}


create_vertex_buffer_layout :: proc($T: typeid, allocator := context.allocator) -> wgpu.VertexBufferLayout 
  where intrinsics.type_is_struct(T) {

  count := intrinsics.type_struct_field_count(T)
  attributes := make([]wgpu.VertexAttribute, count, allocator)
  type_infos := reflect.struct_field_types(T)
  offsets := reflect.struct_field_offsets(T)
  

  for &attrib, i in attributes {
    attrib.format = type_to_vertex_format(type_infos[i])
    attrib.offset = u64(offsets[i])
    attrib.shaderLocation = u32(i)
  }

  return wgpu.VertexBufferLayout{
    arrayStride = size_of(T),
    stepMode = .Vertex,
    attributeCount = uint(len(attributes)),
    attributes = raw_data(attributes)
  }
}