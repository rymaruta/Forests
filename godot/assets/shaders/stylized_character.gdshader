shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.3, 0.55, 0.5);
uniform vec3 shadow_color : source_color = vec3(0.16, 0.32, 0.28);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;
uniform float rim_strength = 0.04;
uniform float flock_amt : hint_range(0.0, 1.0) = 0.22;

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
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.25, 1.0, 0.2))), 0.0, 1.0);
	ndl = mix(0.72, 1.0, ndl);
	float shade = smoothstep(0.12, 0.92, ndl);
	vec3 col = mix(shadow_color, base_color, shade);
	// フェルト微粒
	float flock = _vnoise(v_world * 36.0) * 0.55 + _vnoise(v_world * 72.0 + 2.1) * 0.45;
	col *= mix(1.0 - flock_amt * 0.12, 1.0 + flock_amt * 0.12, flock);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col += vec3(1.0, 0.95, 0.85) * rim * rim_strength;
	ALBEDO = col;
	ROUGHNESS = max(roughness_val, 0.95);
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
