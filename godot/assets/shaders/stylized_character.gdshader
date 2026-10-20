shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.3, 0.55, 0.5);
uniform vec3 shadow_color : source_color = vec3(0.16, 0.32, 0.28);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.65;
uniform float rim_strength = 0.12;

void fragment() {
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.25, 1.0, 0.2))), 0.0, 1.0);
	ndl = (ndl + 0.45) / 1.45;
	float shade = smoothstep(0.2, 0.85, ndl);
	vec3 col = mix(shadow_color, base_color, shade);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.8);
	col += vec3(1.0, 0.95, 0.85) * rim * rim_strength;
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.15;
}
