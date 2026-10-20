shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.6;
uniform float uv_scale_y = 2.8;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float ang = atan(v_world.z, v_world.x);
	// Bench距離でも読める縦溝（コントラスト強め）
	// わずかにねじれた縦溝（完全な規則配管禁止）
	float twist = v_world.y * 0.55 + sin(v_world.y * 1.7) * 0.35;
	float g1 = 0.5 + 0.5 * sin(ang * 10.0 + twist);
	float g2 = 0.5 + 0.5 * sin(ang * 17.0 + twist * 1.3 + 1.2);
	float world_groove = mix(g1, g2, 0.34);
	world_groove = smoothstep(0.22, 0.82, world_groove);
	float groove = mix(tex.r * 0.6 + 0.15, world_groove, 0.88);
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.78, 1.0, ndl);
	vec3 base = mix(bark_dark, bark_color, 0.28 + groove * 0.55);
	base *= 0.90 + ndl * 0.14;
	ALBEDO = base;
	ROUGHNESS = 0.99;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
