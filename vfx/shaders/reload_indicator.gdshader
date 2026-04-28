shader_type canvas_item;

uniform float reload_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 reload_color : source_color = vec4(1.0, 1.0, 1.0, 0.3);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    // Left to right slide
    if (UV.x > reload_progress) {
        COLOR = tex_color * reload_color;
    } else {
        COLOR = tex_color;
    }
}
