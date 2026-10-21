shader_type spatial;
// フェルト雲：unshadedでパイル粒を潰さない。立体は包み込み＋谷AOで読む。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.36, 0.44, 0.30);
uniform vec3 leaf_dark : source_color = vec3(0.22, 0.30, 0.20);
uniform float wind_strength = 0.012;
uniform float wind_speed = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.55;

varying vec3 v_world;
varying vec3 v_obj;
varying vec3 v_n;

float _hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float _vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = _hash31(i);
	float n100 = _hash31(i + vec3(1,0,0));
	float n010 = _hash31(i + vec3(0,1,0));
	float n110 = _hash31(i + vec3(1,1,0));
	float n001 = _hash31(i + vec3(0,0,1));
	float n101 = _hash31(i + vec3(1,0,1));
	float n011 = _hash31(i + vec3(0,1,1));
	float n111 = _hash31(i + vec3(1,1,1));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	return mix(mix(nx00, nx10, f.y), mix(nx01, nx11, f.y), f.z);
}

void vertex() {
	// ごく短い柔らかい毛羽（輪郭ジャギーを出さない）
	float fuzz = _hash31(VERTEX * 18.0 + 2.7) * 0.012
		+ _hash31(VERTEX * 36.0) * 0.006;
	VERTEX += NORMAL * fuzz;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_obj = VERTEX;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.04, 0.0, 0.22);
	VERTEX.x += sin(t + VERTEX.x * 0.14) * wind_strength * mask;
	VERTEX.z += cos(t * 0.45 + VERTEX.z * 0.11) * wind_strength * 0.18 * mask;
}

void fragment() {
	// 柔らかい大粒パイル（砂粒ディザ禁止）
	vec3 tex_a = texture(leaf_tex, v_world.xz * 1.8).rgb;
	vec3 tex_b = texture(leaf_tex, v_world.xy * 1.8).rgb;
	vec3 tex_c = texture(leaf_tex, v_world.zy * 1.8).rgb;
	vec3 wn = abs(v_n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	vec3 tex = tex_a * wn.y + tex_b * wn.z + tex_c * wn.x;

	float pile = _vnoise(v_world * 5.5 + 0.4);
	float fiber = _vnoise(v_world * 12.0 + 2.1);
	float fiber2 = _vnoise(v_world * 22.0 + 7.4);
	float flock = pile * 0.50 + fiber * 0.35 + fiber2 * 0.15;

	// 参照：房の陰影が主。パイルはごく薄い面ノイズ。
	float crevice = clamp(1.0 - v_n.y * 0.90, 0.0, 1.0);
	crevice = pow(crevice, 1.35);
	float lobe_ao = mix(1.0, 0.55, crevice);

	vec3 L = normalize(vec3(0.28, 0.92, 0.24));
	float ndl = clamp(dot(v_n, L) * 0.5 + 0.5, 0.0, 1.0);
	float wrap = mix(0.84, 1.16, ndl);
	float up = clamp(v_n.y * 0.28 + 0.82, 0.78, 1.12);

	float tex_l = dot(tex, vec3(0.30, 0.52, 0.18));
	vec3 base = mix(leaf_dark, leaf_color, 0.48 + up * 0.18 + ndl * 0.12);
	base = mix(base, leaf_color * (0.92 + tex_l * 0.16), flock_mix * 0.55);
	base *= mix(0.97, 1.04, flock);
	base *= lobe_ao * wrap;
	base *= mix(0.99, 1.015, fiber2);

	float under = clamp(0.18 - v_obj.y * 0.12, 0.0, 0.12);
	base *= 1.0 - under;

	ALBEDO = base;
}
