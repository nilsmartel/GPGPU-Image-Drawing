use std::{process, sync::Arc};
use winit::{event::*, event_loop::EventLoop, window::Window};

use crate::{compute::ComputeState, gpu::GpuState, render::RenderState, shaders::Shaders};

pub const WIDTH: u32 = 512;
pub const HEIGHT: u32 = 512;

/// Initilize GPU, Shaders and Pipelines
/// and run the event loop
pub async fn run_app(event_loop: EventLoop<()>, window: Window) {
    let window = Arc::new(window);
    let gpu_state = GpuState::new(&window, WIDTH, HEIGHT).await;
    let shaders = Shaders::new(&gpu_state.device);
    let compute_state = ComputeState::new(&gpu_state.device, &shaders, WIDTH, HEIGHT);
    let render_state = RenderState::new(
        &gpu_state.device,
        &shaders,
        &compute_state,
        gpu_state.surface_format,
    );

    let app = App {
        gpu_state,
        compute_state,
        render_state,
    };

    app.run(event_loop, Arc::clone(&window));
}

/// Responsible for running the event loop and holding the state required to do so.
pub struct App {
    gpu_state: GpuState,
    compute_state: ComputeState,
    render_state: RenderState,
}

impl App {
    fn run(mut self, event_loop: EventLoop<()>, window: Arc<Window>) {
        event_loop
            .run(|event, _control_flow| match event {
                Event::AboutToWait => {
                    self.render_frame();
                }
                Event::WindowEvent { event, .. } => match event {
                    WindowEvent::CloseRequested => process::exit(0),
                    WindowEvent::Resized(size) => {
                        self.handle_resize(size.width, size.height, &window);
                    }
                    _ => {}
                },
                _ => {}
            })
            .expect("Failed to run event loop");
    }

    fn render_frame(&mut self) {
        // 1. Dispatch compute shader
        let mut encoder =
            self.gpu_state
                .device
                .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                    label: Some("Compute Encoder"),
                });

        self.compute_state.dispatch(&mut encoder, WIDTH, HEIGHT);
        self.gpu_state.queue.submit(Some(encoder.finish()));

        // 2. Render to window
        let frame = match self.gpu_state.surface.get_current_texture() {
            Ok(frame) => frame,
            Err(_) => {
                self.gpu_state.reconfigure_surface();
                self.gpu_state
                    .surface
                    .get_current_texture()
                    .expect("Failed to acquire next swap chain texture")
            }
        };

        let view = frame
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());

        let mut render_encoder =
            self.gpu_state
                .device
                .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                    label: Some("Render Encoder"),
                });

        self.render_state.render(&mut render_encoder, &view);

        self.gpu_state.queue.submit(Some(render_encoder.finish()));
        frame.present();
    }

    fn handle_resize(&mut self, width: u32, height: u32, window: &Window) {
        self.gpu_state.resize(width, height);
        window.request_redraw();
    }
}
