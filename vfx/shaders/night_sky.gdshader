shader_type canvas_item;

uniform vec4 sky_color : source_color = vec4(0.01, 0.01, 0.04, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.05, 0.05, 0.1, 1.0);
uniform vec4 grid_color : source_color = vec4(0.0, 1.0, 1.0, 0.2);
uniform float grid_size = 100.0;
uniform float grid_thickness = 1.0;

varying vec2 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Gradient sky
	vec4 color = mix(horizon_color, sky_color, UV.y);
	
	COLOR = vec4(color.rgb, 1.0);
}
