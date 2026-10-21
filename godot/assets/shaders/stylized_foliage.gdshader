shader_type spatial;
// フェルト雲（部品・冠）：アルベドパイル＋ノーマルパイル。円柱ハイライト禁止。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaf_n_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.36, 0.44, 0.30);
uniform vec3 leaf_dark : source_color = vec3(0.22, 0.30, 0.20);
uniform float wind_strength = 0.012;
uniform float wind_speed = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.75;
uniform float nap_scale = 2.8;
uniform float nap_strength = 0.85;

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

vec3 _triplanar_col(sampler2D tex, vec3 wpos, vec3 n, float scale) {
	vec3 a = texture(tex, wpos.yz * scale).rgb;
	vec3 b = texture(tex, wpos.xz * scale).rgb;
	vec3 c = texture(tex, wpos.xy * scale).rgb;
	vec3 wn = abs(n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	return a * wn.x + b * wn.y + c * wn.z;
}

vec3 _triplanar_nrm(sampler2D tex, vec3 wpos, vec3 n, float scale) {
	// sample tangent-space normals and blend by axis weights
	vec3 nx = texture(tex, wpos.yz * scale).rgb * 2.0 - 1.0;
	vec3 ny = texture(tex, wpos.xz * scale).rgb * 2.0 - 1.0;
	vec3 nz = texture(tex, wpos.xy * scale).rgb * 2.0 - 1.0;
	vec3 wn = abs(n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	// remap each to world-ish perturbation along surface
	vec3 px = vec3(0.0, nx.x, nx.y);
	vec3 py = vec3(ny.x, 0.0, ny.y);
	vec3 pz = vec3(nz.x, nz.y, 0.0);
	return normalize(n + (px * wn.x + py * wn.y + pz * wn.z) * nap_strength);
}

void vertex() {
	float fuzz = _hash31(VERTEX * 20.0 + 2.7) * 0.008
		+ _hash31(VERTEX * 40.0) * 0.004;
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
	vec3 tex = _triplanar_col(leaf_tex, v_world, v_n, nap_scale);
	vec3 n = _triplanar_nrm(leaf_n_tex, v_world, v_n, nap_scale);

	float pile = _vnoise(v_world * 6.0 + 0.4);
	float fiber = _vnoise(v_world * 14.0 + 2.1);
	float fiber2 = _vnoise(v_world * 28.0 + 7.4);
	float flock = pile * 0.45 + fiber * 0.38 + fiber2 * 0.17;

	// 房の谷：柔らかい雲影
	float crevice = clamp(1.0 - v_n.y * 0.90, 0.0, 1.0);
	crevice = pow(crevice, 1.70);
	float lobe_ao = mix(1.0, 0.62, crevice);

	vec3 L = normalize(vec3(0.28, 0.92, 0.24));
	float ndl = clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0);
	float wrap = mix(0.84, 1.16, ndl);
	float up = clamp(n.y * 0.24 + 0.84, 0.80, 1.10);

	float tex_l = dot(tex, vec3(0.30, 0.52, 0.18));
	vec3 base = mix(leaf_dark, leaf_color, 0.44 + up * 0.16 + ndl * 0.16);
	// フェルト粒を面全体に焼く
	base = mix(base, mix(leaf_dark * 0.92, leaf_color * 1.10, tex_l), flock_mix * 0.88);
	base *= mix(0.94, 1.07, flock);
	base *= lobe_ao * wrap;
	base *= mix(0.985, 1.02, fiber2);

	float facing = clamp(dot(normalize(n), VIEW) * 0.5 + 0.5, 0.0, 1.0);
	float soft_rim = pow(1.0 - facing, 2.5) * 0.32;
	base += leaf_color * soft_rim * (0.40 + flock * 0.35);

	float under = clamp(0.16 - v_obj.y * 0.12, 0.0, 0.12);
	base *= 1.0 - under;

	ALBEDO = base;
}
