#version 330
// macOS window edge, "hairline" style (Sonoma key window): one 1px line on the window's own
// edge, lighter than the content, brightest along the top and faint down the sides and bottom.
// On light content a light line can't show, so it darkens slightly instead.
// picom's default_post_processing still does the rounding, focus dimming and opacity.
in vec2 texcoord;              // fragment position in window pixels
uniform sampler2D tex;         // window contents (premultiplied alpha)
uniform vec2 effective_size;   // window size in pixels
uniform float corner_radius;   // pixels; 0 for square windows

vec4 default_post_processing(vec4 c);

const float TOP = 0.32;        // white mix of the line along the top
const float SIDES = 0.10;      // ... down the sides and along the bottom
const float ON_LIGHT = 0.12;   // darkening instead, where the content is light

vec4 window_shader() {
    vec4 c = texture(tex, texcoord / vec2(textureSize(tex, 0)));
    // corner_radius 0 (square corners) measures from a plain rectangle; fullscreen windows get
    // plain.frag instead (picom.conf), so they never show an edge
    vec2 half_size = effective_size / 2.0;
    vec2 p = texcoord - half_size;
    vec2 q = abs(p) - half_size + vec2(corner_radius);
    vec2 qp = max(q, 0.0);
    float arc = length(qp);
    float inside = corner_radius - arc - min(max(q.x, q.y), 0.0);   // px from the edge

    // outward normal of the nearest edge; its upward part decides how bright the line is
    vec2 n = (q.x > 0.0 && q.y > 0.0) ? qp / max(arc, 1e-4)
           : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    n *= sign(p);
    float up = max(-n.y, 0.0);

    float line = 1.0 - smoothstep(0.5, 1.5, inside);                // the outermost pixel
    float lum = dot(c.rgb / max(c.a, 1e-4), vec3(0.2126, 0.7152, 0.0722));
    if (lum < 0.55) {
        c.rgb += (vec3(c.a) - c.rgb) * mix(SIDES, TOP, up) * line;
    } else {
        c.rgb *= 1.0 - ON_LIGHT * line;
    }
    return default_post_processing(c);
}
