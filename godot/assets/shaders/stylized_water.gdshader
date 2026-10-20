shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.35, 0.72, 0.70);
uniform vec3 deep_color : source_color = vec3(0.12, 0.38, 0.48);
uniform float wave_speed = 0.6;
uniform float wave_scale = 0.35;
uniform float opacity = 0.78;

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

void fragment() {
	vec2 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float w1 = noise(wp * wave_scale + TIME * wave_speed);
	float w2 = noise(wp * wave_scale * 1.7 - TIME * wave_speed * 0.7);
	float waves = mix(w1, w2, 0.5);
	vec3 col = mix(deep_color, shallow_color, waves);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	col = mix(col, vec3(0.85, 0.95, 0.98), fresnel * 0.45);
	ALBEDO = col;
	ALPHA = mix(opacity, 0.92, fresnel);
	ROUGHNESS = 0.08;
	METALLIC = 0.15;
	SPECULAR = 0.7;
}
