// WGSL Distance Functions Library
// Comprehensive collection of distance functions for graphics programming

// =============================================================================
// BASIC DISTANCE FUNCTIONS
// =============================================================================

// Euclidean distance (L2 norm) - most common
fn euclidean_distance_2d(a: vec2<f32>, b: vec2<f32>) -> f32 {
    return distance(a, b); // Built-in function
}

fn euclidean_distance_3d(a: vec3<f32>, b: vec3<f32>) -> f32 {
    return distance(a, b);
}

// Manual implementation (equivalent to built-in)
fn euclidean_distance_manual(a: vec2<f32>, b: vec2<f32>) -> f32 {
    return length(b - a);
}

// Squared distance - faster when you don't need the actual distance
fn squared_distance_2d(a: vec2<f32>, b: vec2<f32>) -> f32 {
    let diff = b - a;
    return dot(diff, diff);
}

fn squared_distance_3d(a: vec3<f32>, b: vec3<f32>) -> f32 {
    let diff = b - a;
    return dot(diff, diff);
}

// =============================================================================
// ALTERNATIVE DISTANCE METRICS
// =============================================================================

// Manhattan distance (L1 norm) - taxicab distance
fn manhattan_distance_2d(a: vec2<f32>, b: vec2<f32>) -> f32 {
    let diff = abs(b - a);
    return diff.x + diff.y;
}

fn manhattan_distance_3d(a: vec3<f32>, b: vec3<f32>) -> f32 {
    let diff = abs(b - a);
    return diff.x + diff.y + diff.z;
}

// Chebyshev distance (L∞ norm) - chessboard distance
fn chebyshev_distance_2d(a: vec2<f32>, b: vec2<f32>) -> f32 {
    let diff = abs(b - a);
    return max(diff.x, diff.y);
}

fn chebyshev_distance_3d(a: vec3<f32>, b: vec3<f32>) -> f32 {
    let diff = abs(b - a);
    return max(max(diff.x, diff.y), diff.z);
}

// Minkowski distance with custom p parameter
fn minkowski_distance_2d(a: vec2<f32>, b: vec2<f32>, p: f32) -> f32 {
    let diff = abs(b - a);
    return pow(pow(diff.x, p) + pow(diff.y, p), 1.0 / p);
}

// =============================================================================
// SPECIALIZED DISTANCE FUNCTIONS
// =============================================================================

// Distance from point to line segment
fn distance_point_to_line_segment(point: vec2<f32>, line_start: vec2<f32>, line_end: vec2<f32>) -> f32 {
    let line_vec = line_end - line_start;
    let point_vec = point - line_start;

    let line_length_sq = dot(line_vec, line_vec);
    if (line_length_sq == 0.0) {
        return distance(point, line_start);
    }

    let t = clamp(dot(point_vec, line_vec) / line_length_sq, 0.0, 1.0);
    let projection = line_start + t * line_vec;
    return distance(point, projection);
}

// Distance from point to circle (signed distance)
fn distance_point_to_circle(point: vec2<f32>, circle_center: vec2<f32>, radius: f32) -> f32 {
    return distance(point, circle_center) - radius;
}

// Distance from point to rectangle (signed distance)
fn distance_point_to_rect(point: vec2<f32>, rect_center: vec2<f32>, rect_size: vec2<f32>) -> f32 {
    let d = abs(point - rect_center) - rect_size * 0.5;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

// =============================================================================
// UTILITY FUNCTIONS FOR DISTANCE-BASED EFFECTS
// =============================================================================

// Smooth step based on distance
fn distance_smooth_step(dist: f32, edge0: f32, edge1: f32) -> f32 {
    return smoothstep(edge0, edge1, dist);
}

// Create ripple effect based on distance
fn distance_ripple(dist: f32, frequency: f32, amplitude: f32, phase: f32) -> f32 {
    return sin(dist * frequency + phase) * amplitude;
}

// Radial gradient based on distance
fn distance_radial_gradient(dist: f32, inner_radius: f32, outer_radius: f32) -> f32 {
    return clamp((dist - inner_radius) / (outer_radius - inner_radius), 0.0, 1.0);
}

// Exponential falloff based on distance
fn distance_exponential_falloff(dist: f32, falloff_rate: f32) -> f32 {
    return exp(-dist * falloff_rate);
}

// =============================================================================
// NOISE-BASED DISTANCE MODIFICATIONS
// =============================================================================

// Simple hash function for pseudo-random values
fn hash(p: vec2<f32>) -> f32 {
    let h = dot(p, vec2<f32>(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// Add noise to distance for organic effects
fn distance_with_noise(base_distance: f32, noise_scale: f32, noise_strength: f32) -> f32 {
    let noise = hash(vec2<f32>(base_distance * noise_scale)) * 2.0 - 1.0;
    return base_distance + noise * noise_strength;
}

// =============================================================================
// EXAMPLE USAGE FUNCTIONS
// =============================================================================

// Example: Create concentric circles effect
fn concentric_circles_effect(pos: vec2<f32>, center: vec2<f32>, ring_spacing: f32) -> f32 {
    let dist = distance(pos, center);
    return fract(dist / ring_spacing);
}

// Example: Create voronoi-like cell effect
fn voronoi_distance_effect(pos: vec2<f32>, cell_size: f32) -> f32 {
    let cell_id = floor(pos / cell_size);
    var min_dist = 1000.0;

    for (var y = -1; y <= 1; y++) {
        for (var x = -1; x <= 1; x++) {
            let neighbor = cell_id + vec2<f32>(f32(x), f32(y));
            let point = neighbor * cell_size + vec2<f32>(hash(neighbor) * cell_size, hash(neighbor + vec2<f32>(1.0)) * cell_size);
            let dist = distance(pos, point);
            min_dist = min(min_dist, dist);
        }
    }

    return min_dist;
}

// Example: Distance field for complex shapes
fn complex_shape_distance(pos: vec2<f32>) -> f32 {
    // Combine multiple simple shapes using distance fields
    let circle1 = distance_point_to_circle(pos, vec2<f32>(100.0, 100.0), 50.0);
    let circle2 = distance_point_to_circle(pos, vec2<f32>(200.0, 150.0), 30.0);
    let rect = distance_point_to_rect(pos, vec2<f32>(150.0, 200.0), vec2<f32>(60.0, 40.0));

    // Union (minimum), intersection (maximum), or smooth combinations
    return min(min(circle1, circle2), rect);
}
