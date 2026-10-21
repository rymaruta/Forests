shader_type spatial;
// フェルト雲（部品・冠）：アルベドパイル＋ノーマルパイル＋頂点AO＋縁ディザ柔縁。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded, depth_prepass_alpha;

// ミップでフェルト粒が消えないよう線形のみ
uniform sampler2D leaf_tex : source_color, filter_linear, repeat_enable;
uniform sampler2D leaf_n_tex : hint_normal, filter_linear, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.50, 0.56, 0.38);
uniform vec3 leaf_dark : source_color = vec3(0.30, 0.36, 0.22);
uniform float wind_strength = 0.012;
uniform float wind_speed = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.86;
uniform float nap_scale = 4.6;
uniform float nap_strength = 1.20;

varying vec3 v_world;
varying vec3 v_obj;
varying vec3 v_n;
varying float v_ao;

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
	vec3 a = texture(tex, wpos.yz * scale).rgb;
	vec3 b = texture(tex, wpos.xz * scale).rgb;
	vec3 c = texture(tex, wpos.xy * scale).rgb;
	vec3 wn = abs(n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	return a * wn.x + b * wn.y + c * wn.z;
}

vec3 _triplanar_nrm(sampler2D tex, vec3 wpos, vec3 n, float scale) {
	vec3 nx = texture(tex, wpos.yz * scale).rgb * 2.0 - 1.0;
	vec3 ny = texture(tex, wpos.xz * scale).rgb * 2.0 - 1.0;
	vec3 nz = texture(tex, wpos.xy * scale).rgb * 2.0 - 1.0;
	vec3 wn = abs(n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	vec3 px = vec3(0.0, nx.x, nx.y);
	vec3 py = vec3(ny.x, 0.0, ny.y);
	vec3 pz = vec3(nz.x, nz.y, 0.0);
	return normalize(n + (px * wn.x + py * wn.y + pz * wn.z) * nap_strength);
}

	void vertex() {
	// 短いフェルト毛羽。連続ノイズで縁を崩す（参照の柔毛）
	float fuzz = _vnoise(VERTEX * 22.0 + 1.3) * 0.016
		+ _vnoise(VERTEX * 44.0 + 4.7) * 0.009
		+ _vnoise(VERTEX * 11.0 + 9.1) * 0.005;
	VERTEX += NORMAL * fuzz;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_obj = VERTEX;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// ベイク頂点色 = 谷AO（無い場合は1）
	v_ao = clamp(COLOR.r, 0.32, 1.0);
	if (v_ao < 0.01) {
		v_ao = 1.0;
	}
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.04, 0.0, 0.22);
	VERTEX.x += sin(t + VERTEX.x * 0.14) * wind_strength * mask;
	VERTEX.z += cos(t * 0.45 + VERTEX.z * 0.11) * wind_strength * 0.18 * mask;
}

void fragment() {
	vec3 tex = _triplanar_col(leaf_tex, v_world, v_n, nap_scale);
	vec3 n = _triplanar_nrm(leaf_n_tex, v_world, v_n, nap_scale * 1.10);

	// 超高周波のみ。中周波モトル（斑）禁止 — 細かいフェルト粒
	float pile = _vnoise(v_world * 28.0 + 0.4);
	float fiber = _vnoise(v_world * 64.0 + 2.1);
	float fiber2 = _vnoise(v_world * 120.0 + 7.4);
	float flock = pile * 0.18 + fiber * 0.42 + fiber2 * 0.40;

	// ベイクAO＋法線谷。房間の深い柔らかい影（p10≈77）
	float crevice = clamp(1.0 - v_n.y * 0.88, 0.0, 1.0);
	crevice = pow(crevice, 1.25);
	// 谷だけ深く（p10≈77）、高台は明るく保つ
	// 大房の谷は広く柔らかく（細かいポップコーン影禁止）
	float lobe_ao = mix(1.0, 0.44, pow(crevice, 1.10)) * mix(0.66, 1.0, v_ao);

	vec3 L = normalize(vec3(0.32, 0.92, 0.22));
	float ndl = clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0);
	float wrap = mix(0.90, 1.14, ndl);
	float up = clamp(n.y * 0.24 + 0.86, 0.84, 1.12);

	float tex_l = dot(tex, vec3(0.30, 0.52, 0.18));
	vec3 base = mix(leaf_dark, leaf_color, 0.50 + up * 0.16 + ndl * 0.14);
	base = mix(base, mix(leaf_dark * 0.96, leaf_color * 1.05, tex_l), flock_mix * 0.55);
	// 細い均一フェルト。振幅は参照 hp_std≈3.7（対比控えめ）
	base *= mix(0.88, 1.12, flock);
	float grit = _vnoise(v_world * 280.0 + 1.7);
	float grit2 = _vnoise(v_world * 480.0 + 4.2);
	float grit3 = _vnoise(v_world * 720.0 + 9.1);
	base *= mix(0.88, 1.12, grit * 0.30 + grit2 * 0.35 + grit3 * 0.35);
	base *= lobe_ao * wrap;
	// 露出：mean≈147 / rb/g≈0.22
	base *= 1.82;
	base *= vec3(0.98, 1.005, 0.995);

	float facing = clamp(dot(normalize(n), VIEW) * 0.5 + 0.5, 0.0, 1.0);
	// 縁だけフェルト溶かし。本体は洗わない
	float soft_rim = pow(1.0 - facing, 1.45) * 0.62;
	float rim_mask = smoothstep(0.30, 0.92, soft_rim);
	base += leaf_color * soft_rim * (0.38 + flock * 0.20) * rim_mask;
	base += vec3(0.028, 0.026, 0.014) * soft_rim * rim_mask;
	float edge_fuzz = rim_mask * (0.28 + _vnoise(v_world * 80.0) * 0.20);
	base = mix(base, vec3(0.92, 0.90, 0.86), edge_fuzz);

	// 下側の重い帯を抑え、参照の柔らかい裾に
	float under = clamp(0.10 - v_obj.y * 0.08, 0.0, 0.08);
	base *= 1.0 - under;

	// シルエット柔縁：縁帯のみ細かくディザ discard（本体は残す）
	float edge = pow(1.0 - facing, 1.25);
	float dither = _vnoise(v_world * 140.0 + 3.1) * 0.50
		+ _vnoise(v_world * 280.0 + 8.7) * 0.50;
	float cut = smoothstep(0.40, 0.95, edge) * (0.50 + dither * 0.50);
	if (cut > 0.62) {
		discard;
	}

	ALBEDO = base;
	ALPHA = 1.0;
}
