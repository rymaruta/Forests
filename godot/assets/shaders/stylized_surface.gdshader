shader_type spatial;
// 小屋表面：トリプラナー＋包み光＋フェルト微粒。漆喰／石／瓦で共用。
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 base_color : source_color = vec3(0.88, 0.84, 0.74);
uniform vec3 shadow_color : source_color = vec3(0.62, 0.58, 0.50);
uniform float uv_scale = 2.4;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.55;
uniform float nap_scale = 18.0;
uniform float tex_mix : hint_range(0.0, 1.0) = 0.55;
uniform float wrap_soft = 0.55;
uniform float exposure = 1.0;
uniform vec3 warm_bias = vec3(1.0, 1.0, 1.0);

varying vec3 v_world;
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
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z
	);
}

vec3 _triplanar_col(sampler2D tex, vec3 wpos, vec3 n, float scale) {
	vec3 a = texture(tex, wpos.yz * scale).rgb;
	vec3 b = texture(tex, wpos.xz * scale).rgb;
	vec3 c = texture(tex, wpos.xy * scale).rgb;
	vec3 wn = abs(n);
	wn = wn / max(wn.x + wn.y + wn.z, 1e-4);
	return a * wn.x + b * wn.y + c * wn.z;
}

void vertex() {
	// 漆喰の粗いナプ：頂点を押し出して影が乗る（参照のざらつき）
	float fuzz = _vnoise(VERTEX * 14.0 + 1.3) * 0.016
		+ _vnoise(VERTEX * 36.0 + 4.2) * 0.008
		+ _vnoise(VERTEX * 80.0 + 7.7) * 0.0035;
	VERTEX += NORMAL * fuzz;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 tex = _triplanar_col(albedo_tex, v_world, v_n, uv_scale);
	float pile = _vnoise(v_world * nap_scale);
	float grit = _vnoise(v_world * nap_scale * 2.4 + 3.1);
	float flock = pile * 0.62 + grit * 0.38;

	vec3 L = normalize(vec3(0.32, 0.92, 0.22));
	float ndl = clamp(dot(normalize(v_n), L) * wrap_soft + (1.0 - wrap_soft), 0.0, 1.0);

	vec3 base = mix(shadow_color, base_color, ndl);
	base = mix(base, tex * base_color / max(vec3(0.55), vec3(0.08)), tex_mix);
	base *= mix(1.0 - flock_mix * 0.18, 1.0 + flock_mix * 0.14, flock);
	base *= exposure;
	base *= warm_bias;

	ALBEDO = base;
}
