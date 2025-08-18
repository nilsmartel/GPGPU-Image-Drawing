// Distance Function Examples for WGSL
// Demonstrates various distance-based effects and techniques

@group(0) @binding(0)
var out_image: texture_storage_2d<rgba8unorm, write>;

// Time uniform for animations
@group(0) @binding(1)
var<uniform> time: f32;

// =============================================================================
// DISTANCE FUNCTIONS
// =============================================================================

fn euclidean_distance(a: vec2<f32>, b: vec2<f32>) -> f32 {
    return distance(a, b);
}

fn manhattan_distance(a: vec2<f32>, b: vec2<f32>) -> f32 {
    let diff = abs(b - a);
    return diff.x + diff.y;
}

fn chebyshev_distance(a: vec2<f32>, b: vec2<f32>) -> f32 {
    let diff = abs(b - a);
    return max(diff.x, diff.y);
}

// Signed distance to circle
fn sdf_circle(pos: vec2<f32>, center: vec2<f32>, radius: f32) -> f32 {
    return distance(pos, center) - radius;
}

// Signed distance to rectangle
fn sdf_rect(pos: vec2<f32>, center: vec2<f32>, size: vec2<f32>) -> f32 {
    let d = abs(pos - center) - size * 0.5;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

// Simple hash for pseudo-random values
fn hash(p: vec2<f32>) -> f32 {
    let h = dot(p, vec2<f32>(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// =============================================================================
// EFFECT FUNCTIONS
// =============================================================================

// Ripple effect
fn ripple_effect(pos: vec2<f32>, center: vec2<f32>, frequency: f32, amplitude: f32, phase: f32) -> f32 {
    let dist = distance(pos, center);
    return sin(dist * frequency + phase) * amplitude * exp(-dist * 0.01);
}

// Concentric rings
fn concentric_rings(pos: vec2<f32>, center: vec2<f32>, spacing: f32) -> f32 {
    let dist = distance(pos, center);
    return smoothstep(0.4, 0.6, fract(dist / spacing));
}

// Voronoi cells
fn voronoi_cells(pos: vec2<f32>, cell_size: f32) -> vec2<f32> {
    let cell = floor(pos / cell_size);
    var min_dist = 1000.0;
    var cell_id = vec2<f32>(0.0);

    for (var y = -1; y <= 1; y++) {
        for (var x = -1; x <= 1; x++) {
            let neighbor = cell + vec2<f32>(f32(x), f32(y));
            let point = neighbor * cell_size + vec2<f32>(
                hash(neighbor) * cell_size * 0.8 + cell_size * 0.1,
                hash(neighbor + vec2<f32>(1.0)) * cell_size * 0.8 + cell_size * 0.1
            );
            let dist = distance(pos, point);
            if (dist < min_dist) {
                min_dist = dist;
                cell_id = neighbor;
            }
        }
    }

    return vec2<f32>(min_dist, hash(cell_id));
}

// Distance field combination
fn complex_shape_sdf(pos: vec2<f32>) -> f32 {
    let circle1 = sdf_circle(pos, vec2<f32>(200.0, 200.0), 80.0);
    let circle2 = sdf_circle(pos, vec2<f32>(300.0, 250.0), 60.0);
    let rect = sdf_rect(pos, vec2<f32>(250.0, 300.0), vec2<f32>(120.0, 80.0));

    // Smooth union
    let k = 20.0;
    let h1 = clamp(0.5 + 0.5 * (circle2 - circle1) / k, 0.0, 1.0);
    let union12 = mix(circle2, circle1, h1) - k * h1 * (1.0 - h1);

    let h2 = clamp(0.5 + 0.5 * (rect - union12) / k, 0.0, 1.0);
    return mix(rect, union12, h2) - k * h2 * (1.0 - h2);
}

// =============================================================================
// MAIN COMPUTE SHADER
// =============================================================================

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
    let resolution = vec2<f32>(512.0, 512.0);
    let pos = vec2<f32>(f32(gid.x), f32(gid.y));
    let uv = pos / resolution;

    // Divide screen into quadrants for different effects
    var color = vec3<f32>(0.0);

    if (uv.x < 0.5 && uv.y < 0.5) {
        // Quadrant 1: Basic distance metrics comparison
        let center = vec2<f32>(128.0, 128.0);
        let euclidean = euclidean_distance(pos, center) / 128.0;
        let manhattan = manhattan_distance(pos, center) / 256.0;
        let chebyshev = chebyshev_distance(pos, center) / 128.0;

        color = vec3<f32>(
            smoothstep(0.8, 0.82, euclidean),
            smoothstep(0.8, 0.82, manhattan),
            smoothstep(0.8, 0.82, chebyshev)
        );
    }
    else if (uv.x >= 0.5 && uv.y < 0.5) {
        // Quadrant 2: Ripple effects
        let center = vec2<f32>(384.0, 128.0);
        let ripple1 = ripple_effect(pos, center, 0.05, 0.5, time);
        let ripple2 = ripple_effect(pos, center + vec2<f32>(50.0, 30.0), 0.08, 0.3, time * 1.5);

        let intensity = (ripple1 + ripple2) * 0.5 + 0.5;
        color = vec3<f32>(intensity, intensity * 0.7, intensity * 0.4);
    }
    else if (uv.x < 0.5 && uv.y >= 0.5) {
        // Quadrant 3: Voronoi cells
        let voronoi = voronoi_cells(pos, 40.0);
        let dist = voronoi.x;
        let cell_hash = voronoi.y;

        // Color based on cell ID and distance to cell center
        color = vec3<f32>(
            sin(cell_hash * 6.28 + time) * 0.5 + 0.5,
            cos(cell_hash * 6.28 + time * 1.3) * 0.5 + 0.5,
            sin(cell_hash * 6.28 + time * 0.7) * 0.5 + 0.5
        ) * (1.0 - smoothstep(0.0, 15.0, dist));

        // Add cell borders
        color += vec3<f32>(1.0) * (1.0 - smoothstep(1.0, 2.0, dist));
    }
    else {
        // Quadrant 4: Complex SDF shapes
        let sdf_pos = pos - vec2<f32>(256.0, 256.0);
        let dist = complex_shape_sdf(sdf_pos + vec2<f32>(256.0, 256.0));

        // Color based on distance field
        let inside = step(dist, 0.0);
        let border = 1.0 - smoothstep(0.0, 3.0, abs(dist));

        color = mix(
            vec3<f32>(0.1, 0.2, 0.4), // Outside color
            vec3<f32>(0.8, 0.4, 0.2), // Inside color
            inside
        ) + vec3<f32>(0.9, 0.9, 0.3) * border;

        // Add some animation
        let animated_dist = dist + sin(time * 2.0) * 5.0;
        let pulse = smoothstep(-2.0, 2.0, sin(animated_dist * 0.1 + time * 3.0));
        color = mix(color, color * 1.5, pulse * inside);
    }

    // Add grid lines to separate quadrants
    let grid_line = 0.0;
    if (abs(pos.x - 256.0) < 1.0 || abs(pos.y - 256.0) < 1.0) {
        color = mix(color, vec3<f32>(1.0), 0.5);
    }

    textureStore(out_image, vec2<i32>(gid.xy), vec4<f32>(color, 1.0));
}
