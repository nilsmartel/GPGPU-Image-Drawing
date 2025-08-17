use wgpu::{Device, ShaderModule};

pub struct Shaders {
    pub compute: ShaderModule,
    pub render: ShaderModule,
}

impl Shaders {
    pub fn new(device: &Device) -> Self {
        let compute = Self::create_compute_shader(device);
        let render = Self::create_render_shader(device);

        Self { compute, render }
    }

    fn create_compute_shader(device: &Device) -> ShaderModule {
        let shader_src = include_str!("./shaders/drawing.wgsl");

        device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Compute Shader"),
            source: wgpu::ShaderSource::Wgsl(shader_src.into()),
        })
    }

    fn create_render_shader(device: &Device) -> ShaderModule {
        let shader_src = include_str!("./shaders/render_shader.wgsl");
        device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Render Shader"),
            source: wgpu::ShaderSource::Wgsl(shader_src.into()),
        })
    }
}
