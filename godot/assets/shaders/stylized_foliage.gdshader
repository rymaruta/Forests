shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.40, 0.62, 0.34);
uniform vec3 leaf_dark : source_color = vec3(0.20, 0.38, 0.22);
uniform float wind_strength = 0.12;
uniform float wind_speed = 1.15;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.7;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.35, 0.0, 1.5);
	float sway = sin(t + VERTEX.x * 0.65 + VERTEX.z * 0.48) * wind_strength * mask;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.88 + VERTEX.z * 0.42) * wind_strength * 0.7 * mask;
	VERTEX.y += sin(t * 0.6 + VERTEX.x) * wind_strength * 0.15 * mask;
}

void fragment() {
	vec3 tex = texture(leaf_tex, UV * 2.2 + TIME * 0.002).rgb;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.25))), 0.0, 1.0);
	float shade = smoothstep(0.15, 0.85, ndl);
	vec3 base = mix(leaf_dark, leaf_color, 0.25 + shade * 0.75);
	vec3 col = mix(base, tex * leaf_color * 1.35, 0.48);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	col += vec3(0.14, 0.2, 0.08) * rim;
	// soft subsurface-ish lift
	col += leaf_color * 0.08 * (1.0 - ndl);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.16;
}
