shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec3 tip_color : source_color = vec3(0.58, 0.76, 0.36);
uniform vec3 root_color : source_color = vec3(0.22, 0.42, 0.22);
uniform float wind_strength = 0.18;
uniform float wind_speed = 1.25;
uniform float soft_wrap = 0.45;

void vertex() {
	float h = COLOR.r;
	float t = TIME * wind_speed;
	float sway = sin(t + NODE_POSITION_WORLD.x * 0.75 + NODE_POSITION_WORLD.z * 0.48) * wind_strength * h;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.9 + NODE_POSITION_WORLD.z * 0.55) * wind_strength * 0.6 * h;
}

void fragment() {
	float h = COLOR.r;
	vec3 col = mix(root_color, tip_color, pow(h, 0.85));
	float ndl = dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15)));
	ndl = clamp((ndl + soft_wrap) / (1.0 + soft_wrap), 0.0, 1.0);
	ALBEDO = col * (0.7 + ndl * 0.4);
	ROUGHNESS = 0.88;
	SPECULAR = 0.08;
}
