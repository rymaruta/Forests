shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.36, 0.52, 0.3);
uniform vec3 leaf_dark : source_color = vec3(0.22, 0.36, 0.2);
uniform float wind_strength = 0.12;
uniform float wind_speed = 0.9;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.68;

void vertex() {
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.22, 0.0, 1.0);
	float sway = sin(t + VERTEX.x * 0.45 + VERTEX.z * 0.35) * wind_strength * mask;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.75 + VERTEX.z * 0.3) * wind_strength * 0.55 * mask;
}

void fragment() {
	vec3 tex = texture(leaf_tex, UV * 1.6).rgb;
	// 柔らかい半影：プラスチック半球にしない
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.25, 1.0, 0.2))), 0.0, 1.0);
	ndl = mix(0.55, 1.0, ndl);
	float up = clamp(NORMAL.y * 0.35 + 0.65, 0.4, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.45 + ndl * 0.3 + up * 0.15);
	vec3 col = mix(base, tex * leaf_color * 1.1, 0.32);
	float mottled = fract(sin(dot(UV, vec2(12.7, 78.2))) * 43758.5);
	col *= 0.94 + mottled * 0.1;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.2);
	col += leaf_color * 0.06 * rim;
	col = max(col, leaf_dark * 0.9);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.05;
}
