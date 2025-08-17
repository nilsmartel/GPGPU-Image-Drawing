mod app;
mod compute;
mod gpu;
mod render;
mod shaders;

use winit::{event_loop::EventLoop, window::WindowBuilder};

fn main() {
    // Set up window and event loop
    let event_loop = EventLoop::new().unwrap();
    let window = WindowBuilder::new()
        .with_title("wgpu compute image")
        .with_inner_size(winit::dpi::LogicalSize::new(app::WIDTH, app::HEIGHT))
        .build(&event_loop)
        .unwrap();

    // Run main loop
    pollster::block_on(app::run_app(event_loop, window));
}
