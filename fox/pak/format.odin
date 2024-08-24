package quake_pak


import "core:os"
import "core:strings"
import "core:fmt"
import "core:mem"
import "core:slice"


Pak_Header :: struct {
  id: [4]byte,
  offset: u32, // begining of the file table
  size: u32, // number of files
}

Pak_File_Descriptor :: struct {
  name: [56]byte,
  offset: u32, // offset from begining of the .pak file to the file contents,
  size: u32, // the file size,
}

Pak_Import :: struct {
  lookup: map[string][]byte,
  file_descs: []Pak_File_Descriptor,
  backing: []byte,
}


export_directory :: proc(filename, directory_path: string, max_files_in_folder := 128, max_file_depth := 8) {
  
  dir, file_err := os.open(directory_path)
  defer os.close(dir)
  
  get_pak_file_descriptors :: proc(dir_path: string, file_descs: ^[dynamic]Pak_File_Descriptor, data: ^[dynamic][]byte, path: ^[dynamic]string, max_files: int, depth: int) {
    dir, dir_err := os.open(dir_path)
    defer os.close(dir)
    
    
    if depth <= 0 do return
    
    infos, errno := os.read_dir(dir, max_files)
    
    if errno != os.ERROR_NONE do return
    
    
    for info in infos {
      if info.is_dir {
        append(path, info.name)
        get_pak_file_descriptors(info.fullpath, file_descs, data, path, max_files, depth - 1)
      } else {
        builder: strings.Builder
        strings.builder_init_len_cap(&builder, 0, 56)
        defer strings.builder_destroy(&builder)
        
        for folder_name in path {
          append_string(&builder.buf, folder_name, "/")
        }
        append_string(&builder.buf, info.name)
        
        desc: Pak_File_Descriptor
        mem.copy(&desc.name[0], &builder.buf[0], 56)
        
        append(file_descs, desc)
        
        buf, ok := os.read_entire_file_from_filename(info.fullpath)
        append(data, buf)
      }
    }
    
    
    pop_safe(path)
  }
  
  file_descs := make([dynamic]Pak_File_Descriptor)
  defer delete(file_descs)
  
  data := make([dynamic][]byte)
  defer delete(data)
  
  path := make([dynamic]string)
  defer delete(path)
  
  get_pak_file_descriptors(directory_path, &file_descs, &data, &path, max_files_in_folder, max_file_depth)
  current_offset := u32(len(file_descs) * size_of(Pak_File_Descriptor) + size_of(Pak_Header))
  
  // fill File Descriptors with data
  for &desc, i in file_descs {
    desc.offset = current_offset
    desc.size = u32(len(data[i]))
    current_offset += desc.size
  }
  
  // Describe Header
  header := Pak_Header{
    id = {'P', 'A', 'C', 'K'}, 
    offset = u32(size_of(Pak_Header)),
    size = u32(len(file_descs))
  }

  // 
  file, err := os.open("C:/Users/1saac/projects/foxengine/assets.pak", os.O_CREATE)
  defer os.close(file)
  fmt.println(file, err)

  os.write(file, mem.any_to_bytes(header))
  fmt.println("Size:", size_of(Pak_Header))
  os.write(file, slice.reinterpret([]byte, file_descs[:]))
  for d in data do os.write(file, d)

  fmt.println(file_descs[:])
  fmt.println(data)
}

import_pak :: proc(filename: string, allocator := context.allocator) -> (pak: Pak_Import, ok: bool) {
  backing, okay := os.read_entire_file_from_filename(filename, allocator)

  if !okay do return  

  header := transmute(^Pak_Header)&backing[0]
  fmt.println(header)
  descs := slice.reinterpret([]Pak_File_Descriptor, backing[size_of(Pak_Header): size_of(Pak_Header) + int(header.size) * size_of(Pak_File_Descriptor)])

  lookup := make_map(map[string][]byte, allocator=allocator)
  for &desc in descs {
    name := string(cstring(&desc.name[0]))
    lookup[name] = backing[desc.offset : desc.offset + desc.size]
  }

  return  {lookup = lookup, file_descs = descs, backing = backing}, true
} 


main :: proc() {
  export_directory("assets.pak", "C:/Users/1saac/projects/foxengine/assets")
  pak, ok := import_pak("C:/Users/1saac/projects/foxengine/pak0.pak")

  fmt.println(pak)

}

