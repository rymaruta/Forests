shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.34, 0.58, 0.32);
uniform vec3 leaf_dark : source_color = vec3(0.16, 0.34, 0.18);
uniform float wind_strength = 0.14;
uniform float wind_speed = 1.05;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.62;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.32, 0.0, 1.4);
	float sway = sin(t + VERTEX.x * 0.55 + VERTEX.z * 0.42) * wind_strength * mask;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.86 + VERTEX.z * 0.38) * wind_strength * 0.72 * mask;
	VERTEX.y += sin(t * 0.55 + VERTEX.x * 0.8) * wind_strength * 0.18 * mask;
}

void fragment() {
	vec3 tex = texture(leaf_tex, UV * 2.0).rgb;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.18, 1.0, 0.22))), 0.0, 1.0);
	ndl = (ndl + 0.35) / 1.35;
	float shade = smoothstep(0.12, 0.9, ndl);
	vec3 base = mix(leaf_dark, leaf_color, 0.22 + shade * 0.78);
	vec3 col = mix(base, tex * leaf_color * 1.4, 0.42);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	col += vec3(0.16, 0.22, 0.08) * rim;
	col += leaf_color * 0.12 * (1.0 - ndl);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.12;
}
