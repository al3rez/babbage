// Curved screen, nothing else: the terminal bulges slightly like a CRT tube and the corners
// darken a little, while text stays sharp (no scanlines, shadow mask or blur, which make
// 10pt text unreadable). What falls outside the curved screen takes the terminal's own
// background colour, read from the window padding at the top-left corner.
const float WARP = 0.035;      // bulge: 0 = flat, 0.08 = strong
const float VIGNETTE = 0.22;   // corner darkening: 0 = none

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 c = uv * 2.0 - 1.0;                      // -1..1 from the centre
    c.x *= 1.0 + WARP * c.y * c.y;
    c.y *= 1.0 + WARP * c.x * c.x;
    vec2 src = c * 0.5 + 0.5;
    vec4 bg = texture(iChannel0, vec2(2.0, 2.0) / iResolution.xy);
    if (any(lessThan(src, vec2(0.0))) || any(greaterThan(src, vec2(1.0)))) {
        fragColor = bg;
        return;
    }
    vec4 color = texture(iChannel0, src);
    float edge = dot(c, c) * 0.5;                 // 0 centre .. 1 corners
    color.rgb = mix(color.rgb, bg.rgb, VIGNETTE * edge * edge);
    fragColor = color;
}
