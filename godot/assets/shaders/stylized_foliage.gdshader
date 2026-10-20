shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.42, 0.52, 0.34);
uniform vec3 leaf_dark : source_color = vec3(0.28, 0.38, 0.24);
uniform float wind_strength = 0.08;
uniform float wind_speed = 0.7;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.15, 0.0, 0.85);
	VERTEX.x += sin(t + VERTEX.x * 0.35) * wind_strength * mask;
	VERTEX.z += cos(t * 0.65 + VERTEX.z * 0.25) * wind_strength * 0.45 * mask;
}

void fragment() {
	// フェルト／モス質：艶なし・柔らかい半影だけ
	vec3 tex = texture(leaf_tex, UV * 1.25).rgb;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.72, 1.0, ndl); // コントラストを抑える
	float up = clamp(NORMAL.y * 0.25 + 0.75, 0.6, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.55 + ndl * 0.2 + up * 0.1);
	vec3 col = mix(base, tex * leaf_color, 0.18);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.0;
}
