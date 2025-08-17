// Main shader responsible for visual output
// This was intently written as a compute shader.

@group(0) @binding(0)
var out_image: texture_storage_2d<rgba8unorm, write>;

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
    let color = vec4<f32>(
        sin(
            f32(gid.x) / 512.0
        ),
        cos(f32(gid.y) / 512.0),
        0.5,
        1.0
    );
    textureStore(out_image, vec2<i32>(gid.xy), color);
}
