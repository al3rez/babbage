#version 330
// Glass gloss on window edges, lit from the top-left like macOS:
//  * a bright specular glint that wraps the top-left corner and fades out along both edges,
//    with a softer reflected glint at the bottom-right; straight edges stay clean
//  * on dark content: the glint glows into the glass (bloom + sheen)
//  * on light content (a white glint can't show on white): a soft refraction shadow just
//    inside the glint, so the edge still reads as glass
// picom's default_post_processing still does the rounding, focus dimming and opacity.
// Tuned on real windows with a numpy model of this exact math (dark, mixed and light apps).
in vec2 texcoord;              // fragment position in window pixels
uniform sampler2D tex;         // window contents (premultiplied alpha)
uniform vec2 effective_size;   // window size in pixels
uniform float corner_radius;   // pixels; 0 for fullscreen and other square windows

vec4 default_post_processing(vec4 c);

const vec2  LIGHT    = vec2(-0.7071, -0.7071); // towards the light: top-left
const float SHARP    = 3.0;   // specular exponent: lower = glint spreads to the top-right corner too
const float BACK     = 0.35;  // reflected glint at the opposite (bottom-right) corner
const float LENGTH   = 90.0;  // px along each edge over which a glint fades out
const float CORE     = 0.75;  // white mix of the glint line
const float CORE_W   = 0.75;  // glint line width (px) away from the corner...
const float WIDEN    = 1.4;   // ...and how much wider it is at the corner
const float BLOOM    = 0.32;  // glow inward from the line
const float BLOOM_W  = 3.0;   // glow falloff (px)
const float SHEEN    = 0.10;  // broad light inside the lit corner (dark content only)
const float SHEEN_W  = 12.0;  // sheen falloff (px)
const float BAND     = 0.12;  // refraction shadow inside the glint (light content only)
const float BAND_AT  = 2.0;   // its distance past the glint line (px)
const float BAND_W   = 2.6;   // its width (px)

vec4 window_shader() {
    vec4 c = texture(tex, texcoord / vec2(textureSize(tex, 0)));
    if (corner_radius <= 0.0) {
        return default_post_processing(c);
    }
    vec2 half_size = effective_size / 2.0;
    vec2 p = texcoord - half_size;
    vec2 q = abs(p) - half_size + vec2(corner_radius);   // > 0 on both axes: inside a corner arc
    vec2 qp = max(q, 0.0);
    float arc = length(qp);
    float inside = corner_radius - arc - min(max(q.x, q.y), 0.0);  // px from the edge, >= 0 inside

    // outward normal of the nearest edge (radial on the arcs, axis-aligned on straight edges)
    vec2 n = (q.x > 0.0 && q.y > 0.0) ? qp / max(arc, 1e-4)
           : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    n *= sign(p);
    float facing = dot(n, LIGHT);
    float taper = exp(-(max(-q.x, 0.0) + max(-q.y, 0.0)) / LENGTH);   // fades away from corners
    float spec = (pow(max(facing, 0.0), SHARP) + BACK * pow(max(-facing, 0.0), SHARP)) * taper;

    float width = CORE_W * (1.0 + WIDEN * taper);
    float line = exp(-pow((inside - 1.0) / width, 2.0));
    float glow = exp(-max(inside - 1.0, 0.0) / BLOOM_W);
    float lum = dot(c.rgb / max(c.a, 1e-4), vec3(0.2126, 0.7152, 0.0722));
    float sheen = exp(-inside / SHEEN_W) * taper * taper * pow(max(facing, 0.0), 1.5);
    float highlight = clamp(spec * (CORE * line + BLOOM * glow) + SHEEN * sheen * (1.0 - lum), 0.0, 1.0);
    float band = exp(-pow((inside - BAND_AT - width) / BAND_W, 2.0)) * spec * BAND * lum;

    c.rgb *= 1.0 - band;                         // refraction shadow (premultiplied-safe)
    c.rgb += (vec3(c.a) - c.rgb) * highlight;    // toward white, keeping alpha
    return default_post_processing(c);
}
