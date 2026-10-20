shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.28, 0.52, 0.28);
uniform vec3 leaf_dark : source_color = vec3(0.12, 0.28, 0.14);
uniform float wind_strength = 0.11;
uniform float wind_speed = 0.95;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.58;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.28, 0.0, 1.2);
	float sway = sin(t + VERTEX.x * 0.5 + VERTEX.z * 0.4) * wind_strength * mask;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.8 + VERTEX.z * 0.35) * wind_strength * 0.65 * mask;
}

void fragment() {
	vec3 tex = texture(leaf_tex, UV * 1.8).rgb;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.15, 1.0, 0.2))), 0.0, 1.0);
	ndl = (ndl + 0.4) / 1.4;
	// 上面を明るく、下面を濃く（樹冠に立体感）
	float up = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.2 + ndl * 0.55 + up * 0.25);
	vec3 col = mix(base, tex * leaf_color * 1.25, 0.35);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.8);
	col += vec3(0.12, 0.18, 0.06) * rim;
	col += leaf_color * 0.1 * (1.0 - ndl);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.1;
}
