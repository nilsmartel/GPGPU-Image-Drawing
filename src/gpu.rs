use std::sync::Arc;
use wgpu::{Device, Queue, Surface, SurfaceConfiguration, TextureFormat};
use winit::window::Window;

pub struct GpuState {
    pub device: Device,
    pub queue: Queue,
    pub surface: Surface<'static>,
    pub surface_format: TextureFormat,
    pub surface_config: SurfaceConfiguration,
}

impl GpuState {
    pub async fn new(window: &Arc<Window>, width: u32, height: u32) -> Self {
        let instance = wgpu::Instance::default();
        let surface = instance.create_surface(Arc::clone(window)).unwrap();

        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                compatible_surface: Some(&surface),
                ..Default::default()
            })
            .await
            .expect("Failed to find adapter");

        let (device, queue) = adapter
            .request_device(&Default::default(), None)
            .await
            .expect("Failed to create device");

        let surface_format = surface.get_capabilities(&adapter).formats[0];
        let surface_config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface_format,
            width,
            height,
            present_mode: wgpu::PresentMode::Fifo,
            alpha_mode: wgpu::CompositeAlphaMode::Opaque,
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        };

        surface.configure(&device, &surface_config);

        Self {
            device,
            queue,
            surface,
            surface_format,
            surface_config,
        }
    }

    pub fn resize(&mut self, width: u32, height: u32) {
        self.surface_config.width = width;
        self.surface_config.height = height;
        self.surface.configure(&self.device, &self.surface_config);
    }

    pub fn reconfigure_surface(&mut self) {
        self.surface.configure(&self.device, &self.surface_config);
    }
}
