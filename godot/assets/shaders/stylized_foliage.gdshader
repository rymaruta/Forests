shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.36, 0.44, 0.30);
uniform vec3 leaf_dark : source_color = vec3(0.22, 0.30, 0.20);
uniform float wind_strength = 0.012;
uniform float wind_speed = 0.22;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.28;

varying vec3 v_world;

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
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float t = TIME * wind_speed;
	float mask = clamp(h * 0.04, 0.0, 0.22);
	VERTEX.x += sin(t + VERTEX.x * 0.14) * wind_strength * mask;
	VERTEX.z += cos(t * 0.45 + VERTEX.z * 0.11) * wind_strength * 0.18 * mask;
}

void fragment() {
	// フェルト：低周波〜中周波のみ（高周波モアレ禁止）
	vec3 tex = texture(leaf_tex, v_world.xz * 0.35 + v_world.y * 0.12).rgb;
	float flock = _vnoise(v_world * 28.0) * 0.55 + _vnoise(v_world * 56.0 + 1.7) * 0.45;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.1, 1.0, 0.15))), 0.0, 1.0);
	ndl = clamp(ndl * 0.42 + 0.58, 0.0, 1.0);
	float up = clamp(NORMAL.y * 0.2 + 0.8, 0.72, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.52 + ndl * 0.2 + up * 0.1);
	base = mix(base, tex * leaf_color, flock_mix);
	base *= mix(0.97, 1.03, flock);
	ALBEDO = base;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.0;
}
