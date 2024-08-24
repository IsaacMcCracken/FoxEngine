package fox


default_3d_shader_code: cstring = `
@vertex
fn vs_main(@location(0) pos: vec3f) -> @builtin(position) vec4f {
    return vec4f(pos, 1.0);
}

@fragment
fn fs_main() -> @location(0) vec4f {
    return vec4f(0.0, 0.4, 1.0, 1.0);
}
`