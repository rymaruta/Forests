shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec3 tip_color : source_color = vec3(0.5, 0.64, 0.34);
uniform vec3 root_color : source_color = vec3(0.28, 0.4, 0.24);
uniform float wind_strength = 0.16;
uniform float wind_speed = 1.15;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = COLOR.r;
	float t = TIME * wind_speed;
	float sway = sin(t + world_pos.x * 0.7 + world_pos.z * 0.45) * wind_strength * h;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.85 + world_pos.z * 0.5) * wind_strength * 0.55 * h;
}

void fragment() {
	float h = COLOR.r;
	vec3 col = mix(root_color, tip_color, pow(h, 0.8));
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = (ndl + 0.55) / 1.55;
	ALBEDO = col * (0.78 + ndl * 0.32);
	ROUGHNESS = 0.9;
	SPECULAR = 0.05;
}
