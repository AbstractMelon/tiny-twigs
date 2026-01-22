shader_type canvas_item;

uniform float dissolve_value : hint_range(0.0, 1.1) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.1) = 0.02;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Use screen-space or local coords for noise to make it "pixelated"
    vec2 grid_uv = floor(UV * 32.0) / 32.0;
    float noise = random(grid_uv);
    
    if (noise < dissolve_value) {
        discard;
    }
    
    float edge = step(noise, dissolve_value + edge_width);
    vec3 final_color = mix(tex_color.rgb, edge_color.rgb, edge * step(dissolve_value, noise));
    
    COLOR = vec4(final_color, tex_color.a);
}
