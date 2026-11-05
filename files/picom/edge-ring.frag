#version 330
// macOS window edge, "ring" style (Sonoma background windows): a 1pt near-black outline on
// the window's outer edge and, just inside it, a 1pt light rim of the same brightness all
// around (1.5px each at the desktop's 1.5x). On light content the light rim disappears and the
// dark outline does the work.
// picom's default_post_processing still does the rounding, focus dimming and opacity.
in vec2 texcoord;              // fragment position in window pixels
uniform sampler2D tex;         // window contents (premultiplied alpha)
uniform vec2 effective_size;   // window size in pixels
uniform float corner_radius;   // pixels; 0 for fullscreen and other square windows

vec4 default_post_processing(vec4 c);

const float OUTLINE = 0.60;    // darkening of the outer line
const float RIM = 0.18;        // white mix of the line inside it
const float OUTLINE_W = 1.5;   // px: macOS draws 1pt lines, and the desktop is at 1.5x
const float RIM_W = 1.5;

vec4 window_shader() {
    vec4 c = texture(tex, texcoord / vec2(textureSize(tex, 0)));
    if (corner_radius <= 0.0) {
        return default_post_processing(c);
    }
    vec2 half_size = effective_size / 2.0;
    vec2 q = abs(texcoord - half_size) - half_size + vec2(corner_radius);
    float inside = corner_radius - length(max(q, 0.0)) - min(max(q.x, q.y), 0.0);   // px from the edge

    // how much of this pixel ([inside - 0.5, inside + 0.5]) each band covers
    float outer = clamp(OUTLINE_W - (inside - 0.5), 0.0, 1.0);
    float rim = clamp(inside + 0.5 - OUTLINE_W, 0.0, 1.0) * clamp(OUTLINE_W + RIM_W - (inside - 0.5), 0.0, 1.0);
    c.rgb += (vec3(c.a) - c.rgb) * RIM * rim;
    c.rgb *= 1.0 - OUTLINE * outer;
    return default_post_processing(c);
}
