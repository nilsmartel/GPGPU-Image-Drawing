use wgpu::*;

use crate::shaders::Shaders;

pub struct ComputeState {
    pub pipeline: ComputePipeline,
    pub bind_group: BindGroup,
    pub output_view: TextureView,
}

impl ComputeState {
    pub fn new(device: &Device, shaders: &Shaders, width: u32, height: u32) -> Self {
        let output_texture = device.create_texture(&TextureDescriptor {
            label: Some("Compute Output Texture"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: TextureDimension::D2,
            format: TextureFormat::Rgba8Unorm,
            usage: TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let output_view = output_texture.create_view(&TextureViewDescriptor::default());

        let bind_group_layout = device.create_bind_group_layout(&BindGroupLayoutDescriptor {
            label: Some("Compute Bind Group Layout"),
            entries: &[BindGroupLayoutEntry {
                binding: 0,
                visibility: ShaderStages::COMPUTE,
                ty: BindingType::StorageTexture {
                    access: StorageTextureAccess::WriteOnly,
                    format: TextureFormat::Rgba8Unorm,
                    view_dimension: TextureViewDimension::D2,
                },
                count: None,
            }],
        });

        let bind_group = device.create_bind_group(&BindGroupDescriptor {
            label: Some("Compute Bind Group"),
            layout: &bind_group_layout,
            entries: &[BindGroupEntry {
                binding: 0,
                resource: BindingResource::TextureView(&output_view),
            }],
        });

        let pipeline = device.create_compute_pipeline(&ComputePipelineDescriptor {
            compilation_options: Default::default(),
            label: Some("Compute Pipeline"),
            layout: Some(&device.create_pipeline_layout(&PipelineLayoutDescriptor {
                label: Some("Compute Pipeline Layout"),
                bind_group_layouts: &[&bind_group_layout],
                push_constant_ranges: &[],
            })),
            module: &shaders.compute,
            entry_point: "main",
        });

        Self {
            pipeline,
            bind_group,
            output_view,
        }
    }

    pub fn dispatch(&self, encoder: &mut wgpu::CommandEncoder, width: u32, height: u32) {
        let mut compute_pass = encoder.begin_compute_pass(&wgpu::ComputePassDescriptor {
            timestamp_writes: None,
            label: Some("Compute Pass"),
        });

        compute_pass.set_pipeline(&self.pipeline);
        compute_pass.set_bind_group(0, &self.bind_group, &[]);
        compute_pass.dispatch_workgroups(width / 8, height / 8, 1);
    }
}
