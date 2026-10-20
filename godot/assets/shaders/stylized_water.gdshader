shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.42, 0.78, 0.74);
uniform vec3 deep_color : source_color = vec3(0.14, 0.42, 0.52);
uniform vec3 foam_color : source_color = vec3(0.92, 0.97, 0.98);
uniform float wave_speed = 0.45;
uniform float wave_scale = 0.32;
uniform float opacity = 0.82;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = world_pos.xz;
	float w1 = noise(wp * wave_scale + TIME * wave_speed);
	float w2 = noise(wp * wave_scale * 1.85 - TIME * wave_speed * 0.65);
	float waves = mix(w1, w2, 0.5);
	vec3 col = mix(deep_color, shallow_color, waves);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	col = mix(col, foam_color, fresnel * 0.5);
	float spark = step(0.92, noise(wp * 2.4 + TIME * 0.3));
	col += foam_color * spark * 0.18;
	ALBEDO = col;
	ALPHA = mix(opacity, 0.95, fresnel);
	ROUGHNESS = 0.06;
	METALLIC = 0.12;
	SPECULAR = 0.75;
}
