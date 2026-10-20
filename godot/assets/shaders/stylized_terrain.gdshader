shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D grass_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.88, 0.98, 0.82);
uniform float uv_scale = 0.08;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.9;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = world_pos.xz;
	vec2 uv = wp * uv_scale;
	vec3 g = texture(grass_tex, uv).rgb;
	vec3 d = texture(dirt_tex, uv * 0.8 + 0.13).rgb;
	float blend = smoothstep(0.32, 0.78, noise(wp * 0.07));
	float pathish = smoothstep(2.6, 4.2, length(wp - vec2(0.0, 2.5)));
	vec3 col = mix(g, d, blend * 0.28 * pathish);
	col *= 0.9 + 0.18 * noise(wp * 0.4);
	col *= tint;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = (ndl + 0.4) / 1.4;
	col *= 0.72 + ndl * 0.38;
	ALBEDO = col;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.08;
}
