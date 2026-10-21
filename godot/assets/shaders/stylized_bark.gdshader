shader_type spatial;
// マット粘土樹皮：縦繊維はテクスチャのみ。プロシージャル溝＝偽稜線になるので使わない。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.05;
uniform float uv_scale_y = 2.1;

varying float v_y01;

void vertex() {
	v_y01 = clamp(VERTEX.y / 1.55, 0.0, 1.0);
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float tex_luma = dot(tex, vec3(0.32, 0.50, 0.18));
	// ごく弱い刷毛筋だけ。ゼブラ／太い波線禁止。
	float grain = clamp((0.52 - tex_luma) * 1.4, 0.0, 1.0);
	vec3 ridge = bark_color * 1.04;
	vec3 valley = bark_dark * 0.90;
	vec3 base = mix(ridge, valley, grain * 0.32);
	base = mix(base, tex * (bark_color / max(vec3(0.42, 0.32, 0.22), vec3(0.08))), 0.40);
	base *= 0.98 + 0.03 * (1.0 - v_y01);
	ALBEDO = base;
}
