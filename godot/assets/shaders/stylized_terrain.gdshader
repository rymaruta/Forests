shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.72, 0.82, 0.58);
uniform float uv_scale = 0.05;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.94;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	v += 0.5 * noise(p);
	v += 0.25 * noise(p * 2.1);
	v += 0.125 * noise(p * 4.3);
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = world_pos.xz;
	vec3 g1 = texture(grass_tex, wp * uv_scale).rgb;
	vec3 g2 = texture(grass_tex, wp * uv_scale * 1.65 + vec2(0.31, 0.17)).rgb;
	vec3 g = mix(g1, g2, 0.42);
	vec3 d = texture(dirt_tex, wp * uv_scale * 0.85 + 0.11).rgb;
	float patch = smoothstep(0.38, 0.72, fbm(wp * 0.04));
	vec3 col = mix(g, d, patch * 0.18);
	col *= 0.9 + 0.16 * fbm(wp * 0.2);
	col *= tint;
	// 彩度を落として朝の森っぽく
	float luma = dot(col, vec3(0.3, 0.55, 0.15));
	col = mix(vec3(luma), col, 0.72);
	col *= vec3(0.92, 0.95, 0.82);
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = (ndl + 0.5) / 1.5;
	col *= 0.78 + ndl * 0.28;
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.04;
}
