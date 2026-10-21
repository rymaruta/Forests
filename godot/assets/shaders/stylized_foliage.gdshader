shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.36, 0.44, 0.30);
uniform vec3 leaf_dark : source_color = vec3(0.22, 0.30, 0.20);
uniform float wind_strength = 0.012;
uniform float wind_speed = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.55;

varying vec3 v_world;
varying vec3 v_obj;

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
	// 短く密なパイル。長いジャギー禁止
	// 短く密なパイル。高周波ジャギーは抑えてフェルトへ
	float fuzz = _hash31(VERTEX * 36.0 + 2.7) * 0.022
		+ _hash31(VERTEX * 72.0) * 0.012
		+ _hash31(VERTEX * 140.0 + 1.1) * 0.005;
	VERTEX += NORMAL * fuzz;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_obj = VERTEX;
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.04, 0.0, 0.22);
	VERTEX.x += sin(t + VERTEX.x * 0.14) * wind_strength * mask;
	VERTEX.z += cos(t * 0.45 + VERTEX.z * 0.11) * wind_strength * 0.18 * mask;
}

void fragment() {
	// フェルト：柔らかい短パイル＋リム散乱。砂粒ノイズ禁止。
	vec3 tex_a = texture(leaf_tex, v_world.xz * 1.8).rgb;
	vec3 tex_b = texture(leaf_tex, v_world.xy * 1.8).rgb;
	vec3 tex_c = texture(leaf_tex, v_world.zy * 1.8).rgb;
	vec3 wn = abs(NORMAL);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	vec3 tex = tex_a * wn.y + tex_b * wn.z + tex_c * wn.x;

	float pile = _vnoise(v_world * 10.0 + 0.4);
	float fiber = _vnoise(v_world * 28.0 + 2.1);
	float fiber2 = _vnoise(v_world * 56.0 + 7.4);
	float flock = pile * 0.32 + fiber * 0.44 + fiber2 * 0.24;

	// 房の谷は柔らかく（黒穴の球接合に見せない）
	float crevice = clamp(1.0 - NORMAL.y * 0.98, 0.0, 1.0);
	crevice = pow(crevice, 1.9);
	float lobe_ao = mix(1.0, 0.82, crevice);

	vec3 n = NORMAL;
	vec3 t1 = normalize(cross(NORMAL, vec3(0.17, 0.93, 0.31)));
	vec3 t2 = normalize(cross(NORMAL, t1));
	n += (fiber - 0.5) * 0.42 * t1;
	n += (fiber2 - 0.5) * 0.26 * t2;
	n += (pile - 0.5) * 0.22 * t1;
	n = normalize(n);

	float ndl = clamp(dot(n, normalize(vec3(0.18, 0.95, 0.22))), 0.0, 1.0);
	ndl = clamp(ndl * 0.22 + 0.78, 0.0, 1.0);
	float up = clamp(n.y * 0.18 + 0.82, 0.78, 1.0);
	float fiber_catch = mix(0.92, 1.10, flock) * ndl;

	float facing = clamp(dot(n, VIEW) * 0.5 + 0.5, 0.0, 1.0);
	float rim = pow(1.0 - facing, 1.45) * 0.78;

	vec3 base = mix(leaf_dark, leaf_color, 0.44 + fiber_catch * 0.32 + up * 0.16);
	base = mix(base, leaf_color * (0.92 + tex.g * 0.12), flock_mix * 0.48);
	base *= mix(0.99, 1.018, flock);
	base *= lobe_ao;
	base += leaf_color * rim * 1.15;
	base *= mix(0.992, 1.012, fiber2);

	float under = clamp(0.20 - v_obj.y * 0.14, 0.0, 0.14);
	base *= 1.0 - under;

	ALBEDO = base;
	ROUGHNESS = max(roughness_val, 0.99);
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
