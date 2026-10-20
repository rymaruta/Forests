shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.40, 0.48, 0.32);
uniform vec3 leaf_dark : source_color = vec3(0.28, 0.36, 0.24);
uniform float wind_strength = 0.02;
uniform float wind_speed = 0.3;
uniform float roughness_val : hint_range(0.0, 1.0) = 1.0;
uniform float flock_mix : hint_range(0.0, 1.0) = 0.12;

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
	float mask = clamp(h * 0.06, 0.0, 0.35);
	VERTEX.x += sin(t + VERTEX.x * 0.2) * wind_strength * mask;
	VERTEX.z += cos(t * 0.5 + VERTEX.z * 0.15) * wind_strength * 0.25 * mask;
}

void fragment() {
	// フェルト：ほぼベタ塗り＋極細の等方ノイズ。陰影は極弱（房の継ぎ目を黒くしない）
	float flock = _vnoise(v_world * 36.0) * 0.55 + _vnoise(v_world * 72.0) * 0.45;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.05, 1.0, 0.08))), 0.0, 1.0);
	ndl = mix(0.94, 1.0, ndl);
	float up = clamp(NORMAL.y * 0.12 + 0.88, 0.82, 1.0);
	vec3 base = mix(leaf_dark, leaf_color, 0.62 + ndl * 0.1 + up * 0.05);
	base *= mix(0.98, 1.02, flock);
	ALBEDO = mix(base, leaf_color, flock_mix * 0.5);
	ROUGHNESS = roughness_val;
	SPECULAR = 0.0;
}
