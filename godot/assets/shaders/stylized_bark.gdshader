shader_type spatial;
// フェルト樹皮：トリプラナー繊維＋包み光＋頂点AO。ベイクOBJでもUV不要。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.44, 0.32, 0.22);
uniform vec3 bark_dark : source_color = vec3(0.24, 0.16, 0.10);
uniform float uv_scale_x = 1.10;
uniform float uv_scale_y = 1.85;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.78;
uniform float nap_scale = 3.4;
// 趾パーツだけ 1.0：接地影。幹は 0 で組み立て色割れを防ぐ
uniform float ground_contact : hint_range(0.0, 1.0) = 0.0;
// 全体樹シート向け暖茶（部品Benchのクール木部は 0）
uniform float sheet_warm : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world;
varying vec3 v_obj;
varying vec3 v_n;
varying float v_ao;
varying float v_y01;

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

vec3 _triplanar_col(sampler2D tex, vec3 wpos, vec3 n, float scale) {
	// 縦繊維優先：側面（YZ/XY）を強く、上面グリッドを抑える
	vec3 a = texture(tex, wpos.yz * scale * vec2(uv_scale_x, uv_scale_y)).rgb;
	vec3 b = texture(tex, wpos.xz * scale * vec2(uv_scale_x * 0.55, uv_scale_y * 1.35)).rgb;
	vec3 c = texture(tex, wpos.xy * scale * vec2(uv_scale_x, uv_scale_y)).rgb;
	vec3 wn = abs(n);
	wn.y *= 0.35;
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	return a * wn.x + b * wn.y + c * wn.z;
}

void vertex() {
	float fuzz = _vnoise(VERTEX * 28.0 + 2.1) * 0.007
		+ _vnoise(VERTEX * 64.0 + 5.4) * 0.004;
	VERTEX += NORMAL * fuzz;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_obj = VERTEX;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_ao = clamp(COLOR.r, 0.35, 1.0);
	if (v_ao < 0.01) {
		v_ao = 1.0;
	}
	// ワールド高さで勾配（部品結合時のローカルY割れ＝幹薄茶/趾濃茶を防ぐ）
	v_y01 = clamp(v_world.y / 1.70, 0.0, 1.0);
}

void fragment() {
	vec3 tex = _triplanar_col(bark_tex, v_world, v_n, nap_scale);
	float tex_luma = dot(tex, vec3(0.32, 0.50, 0.18));
	float grain = clamp((0.52 - tex_luma) * 1.20, 0.0, 1.0);

	// 縦繊維を強め（参照の刷毛筋）。横モトルは弱く。
	float vert = _vnoise(vec3(v_world.x * 48.0, v_world.y * 7.5, v_world.z * 48.0) + 0.4);
	float vert2 = _vnoise(vec3(v_world.x * 92.0, v_world.y * 14.0, v_world.z * 92.0) + 1.7);
	float pile = _vnoise(v_world * 22.0 + 0.3);
	float fiber = _vnoise(v_world * 64.0 + 2.2);
	float grit = _vnoise(v_world * 140.0 + 7.1);
	float flock = vert * 0.38 + vert2 * 0.18 + pile * 0.12 + fiber * 0.20 + grit * 0.12;

	vec3 L = normalize(vec3(0.36, 0.90, 0.18));
	float ndl = clamp(dot(normalize(v_n), L) * 0.5 + 0.5, 0.0, 1.0);
	float wrap = mix(0.88, 1.10, ndl);

	vec3 ridge = bark_color * 1.04;
	vec3 valley = bark_dark * 0.62;
	vec3 base = mix(ridge, valley, grain * 0.55 + vert * 0.38 + vert2 * 0.18);
	// テクスチャは刷毛筋だけ。明るい布地にしない
	base = mix(base, tex * (bark_color / max(vec3(0.42, 0.32, 0.22), vec3(0.08))), 0.22);
	base *= mix(0.88, 1.08, flock);
	base = mix(base, base * mix(0.94, 1.05, flock), flock_mix * 0.70);

	// 股AO：ベイク＋内向き法線で参照級の深い谷（対比を残す）
	float inward = clamp(-v_n.y * 0.40 + (1.0 - abs(v_n.x)) * 0.30, 0.0, 1.0);
	float crotch = smoothstep(0.52, 0.95, v_y01) * inward;
	float crease = mix(0.20, 1.0, pow(v_ao, 0.66)) * mix(1.0, 0.24, crotch);
	base *= crease * wrap;
	base *= 0.90 + 0.12 * (1.0 - v_y01 * 0.45);
	// 趾だけ接地影（幹は掛けない＝組み立ての二色割れ禁止）
	float ground = mix(0.66, 1.0, smoothstep(0.02, 0.40, v_y01));
	base *= mix(1.0, ground, ground_contact);
	// 幹：クール木部 156/145/128。趾：やや暖寄り。シート：全体樹の暖茶
	base *= mix(1.86, 1.76, ground_contact);
	vec3 cool = vec3(0.94, 1.18, 1.62);
	vec3 warm_toe = vec3(1.07, 1.01, 0.93);
	vec3 warm_sheet = vec3(1.04, 0.98, 0.82);
	base *= mix(cool, warm_toe, ground_contact * 0.70);
	// シート木部：参照全体樹 mean≈98/94/62 帯へ一段落とす
	base = mix(base, base * warm_sheet * 0.68, sheet_warm);
	// ごく弱い高さグラデ（組み立てでも滑らか）
	base *= mix(0.96, 1.03, smoothstep(0.05, 0.75, v_y01));

	ALBEDO = base;
}
