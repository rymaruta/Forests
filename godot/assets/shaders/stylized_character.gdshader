shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.3, 0.55, 0.5);
uniform vec3 shadow_color : source_color = vec3(0.16, 0.32, 0.28);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;
uniform float rim_strength = 0.04;
uniform float flock_amt : hint_range(0.0, 1.0) = 0.38;

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
	return mix(mix(mix(n000,n100,f.x), mix(n010,n110,f.x), f.y),
			   mix(mix(n001,n101,f.x), mix(n011,n111,f.x), f.y), f.z);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.28, 0.95, 0.22))), 0.0, 1.0);
	ndl = mix(0.62, 1.0, ndl);
	float shade = smoothstep(0.10, 0.90, ndl);
	vec3 col = mix(shadow_color, base_color, shade);
	// フェルト／織り微粒（布と麦わらで読ませる）
	float flock = _vnoise(v_world * 40.0) * 0.50 + _vnoise(v_world * 88.0 + 2.1) * 0.35 + _vnoise(v_world * 160.0) * 0.15;
	col *= mix(1.0 - flock_amt * 0.16, 1.0 + flock_amt * 0.14, flock);
	// 縦糸っぽい筋（ワンピ）＋麦わら向けの横帯織り
	float weave = _vnoise(vec3(v_world.x * 28.0, v_world.y * 9.0, v_world.z * 28.0));
	float straw = _vnoise(vec3(v_world.x * 8.0, v_world.y * 70.0, v_world.z * 8.0));
	float straw2 = _vnoise(vec3(v_world.x * 22.0, v_world.y * 18.0, v_world.z * 22.0) + 3.1);
	col *= mix(0.96, 1.04, weave);
	float straw_mix = clamp(flock_amt * 1.35, 0.0, 1.0);
	col *= mix(1.0, mix(0.86, 1.10, straw * 0.7 + straw2 * 0.3), straw_mix);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col += vec3(1.0, 0.95, 0.85) * rim * rim_strength;
	ALBEDO = col;
	ROUGHNESS = max(roughness_val, 0.95);
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
