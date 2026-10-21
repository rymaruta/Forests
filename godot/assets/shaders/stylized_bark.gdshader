shader_type spatial;
// マット粘土樹皮：縦繊維はテクスチャ、溝はアルベド差のみ。円柱ハイライト禁止。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.05;
uniform float uv_scale_y = 2.1;

varying vec3 v_world;
varying float v_y01;

float _hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float _n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = _hash21(i);
	float b = _hash21(i + vec2(1, 0));
	float c = _hash21(i + vec2(0, 1));
	float d = _hash21(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// ごく浅い幾何押し（遠目の溝はテクスチャ任せ）
	float ang = atan(VERTEX.z, VERTEX.x);
	float y = VERTEX.y;
	float warp = _n2(vec2(ang * 0.8, y * 0.35)) * 0.9;
	float g = 0.5 + 0.5 * sin((ang / 6.2831853 * 5.0 + warp) * 6.2831853);
	g = smoothstep(0.35, 0.75, g) * smoothstep(0.04, 0.18, y);
	VERTEX += NORMAL * (g - 0.45) * 0.012;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_y01 = clamp(VERTEX.y / 1.55, 0.0, 1.0);
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	// 縦繊維を強く読む（テクスチャが主、プロシージャルは補助）
	float ang = atan(v_world.z, v_world.x);
	float warp = _n2(vec2(ang * 0.55, v_world.y * 0.28)) * 1.2;
	float a01 = ang / 6.2831853 + warp * 0.10;
	float gA = 0.5 + 0.5 * sin((a01 * 5.0 + warp * 0.35) * 6.2831853);
	float gB = 0.5 + 0.5 * sin((a01 * 9.0 + 0.4) * 6.2831853);
	float soft = smoothstep(0.30, 0.72, gA * 0.7 + gB * 0.3);
	float y_mask = smoothstep(0.03, 0.16, v_world.y) * (1.0 - smoothstep(1.50, 1.72, v_world.y));
	float groove = soft * y_mask * 0.55;

	float tex_luma = dot(tex, vec3(0.32, 0.50, 0.18));
	// 刷毛筋はごく弱く。ゼブラ帯・太い波線禁止。
	float grain = clamp((0.52 - tex_luma) * 1.6, 0.0, 1.0);
	float g = clamp(grain * 0.28 + groove * 0.12, 0.0, 1.0);

	vec3 ridge = bark_color * 1.03;
	vec3 valley = bark_dark * 0.92;
	vec3 base = mix(ridge, valley, g);
	base = mix(base, tex * (bark_color / max(vec3(0.42, 0.32, 0.22), vec3(0.08))), 0.28);
	base *= 0.98 + 0.03 * (1.0 - v_y01);
	ALBEDO = base;
}
