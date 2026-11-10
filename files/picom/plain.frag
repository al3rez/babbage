#version 330
// no edge effect: what picom draws without a shader (fullscreen windows, picom.conf)
in vec2 texcoord;
uniform sampler2D tex;
vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    return default_post_processing(texture(tex, texcoord / vec2(textureSize(tex, 0))));
}
