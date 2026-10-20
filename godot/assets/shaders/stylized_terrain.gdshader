shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 grass_color : source_color = vec3(0.45, 0.62, 0.36);
uniform vec3 dirt_color : source_color = vec3(0.55, 0.42, 0.30);
uniform vec3 moss_color : source_color = vec3(0.30, 0.48, 0.34);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.92;
uniform float detail_scale = 0.12;

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
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.05;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float n = fbm(wp * detail_scale);
	float n2 = fbm(wp * detail_scale * 2.7 + 17.0);
	vec3 col = mix(grass_color, moss_color, smoothstep(0.35, 0.75, n));
	col = mix(col, dirt_color, smoothstep(0.7, 0.95, n2) * 0.45);
	// soft highlights like morning dew patches
	col += vec3(0.04, 0.05, 0.03) * smoothstep(0.6, 0.9, n2);
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.15;
}
