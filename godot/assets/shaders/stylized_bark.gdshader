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
	// UV が薄い場合でも読めるワールド縦溝
	// 正面からも縦溝が読めるよう角周波数を高め、高さ依存は弱く
	float ang = atan(v_world.z, v_world.x);
	float world_groove = 0.5 + 0.5 * sin(ang * 11.0 + v_world.y * 0.8);
	world_groove = world_groove * world_groove;
	world_groove = mix(world_groove, 0.5 + 0.5 * sin(ang * 19.0), 0.4);
	float groove = mix(tex.r, world_groove, 0.92);
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.72, 1.0, ndl);
	vec3 base = mix(bark_dark, bark_color, 0.35 + groove * 0.48);
	base *= 0.86 + ndl * 0.20;
	ALBEDO = base;
	ROUGHNESS = 0.97;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
