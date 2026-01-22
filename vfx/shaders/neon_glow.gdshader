shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float glow_size : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	// Calculate glow
	float alpha = original_color.a;
	vec3 glow = glow_color.rgb * glow_intensity * alpha;
	
	// Combine original color with glow
	COLOR = vec4(original_color.rgb + glow, alpha);
}
