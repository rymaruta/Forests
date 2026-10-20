shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec3 leaf_color : source_color = vec3(0.32, 0.55, 0.30);
uniform vec3 leaf_dark : source_color = vec3(0.18, 0.36, 0.20);
uniform float wind_strength = 0.08;
uniform float wind_speed = 1.1;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.75;

void vertex() {
	float h = VERTEX.y;
	float t = TIME * wind_speed;
	float sway = sin(t + VERTEX.x * 0.7 + VERTEX.z * 0.5) * wind_strength * clamp(h * 0.35, 0.0, 1.5);
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.9 + VERTEX.z * 0.4) * wind_strength * 0.6 * clamp(h * 0.35, 0.0, 1.5);
}

void fragment() {
	float ndl = clamp(dot(NORMAL, vec3(0.3, 1.0, 0.2)), 0.0, 1.0);
	vec3 col = mix(leaf_dark, leaf_color, 0.35 + ndl * 0.65);
	// soft rim for stylized volume
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	col += vec3(0.08, 0.12, 0.05) * rim;
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.2;
}
