shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.40, 0.62, 0.34);
uniform vec3 leaf_dark : source_color = vec3(0.20, 0.38, 0.22);
uniform float wind_strength = 0.1;
uniform float wind_speed = 1.2;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.72;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float sway = sin(t + VERTEX.x * 0.7 + VERTEX.z * 0.5) * wind_strength * clamp(h * 0.4, 0.0, 1.6);
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.9 + VERTEX.z * 0.4) * wind_strength * 0.65 * clamp(h * 0.4, 0.0, 1.6);
}

void fragment() {
	vec3 tex = texture(leaf_tex, UV * 2.5).rgb;
	float ndl = clamp(dot(NORMAL, vec3(0.25, 1.0, 0.2)), 0.0, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.3 + ndl * 0.7);
	vec3 col = mix(base, tex, 0.55);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	col += vec3(0.1, 0.14, 0.06) * rim;
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.18;
}
