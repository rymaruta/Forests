shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform vec3 tip_color : source_color = vec3(0.55, 0.72, 0.38);
uniform vec3 root_color : source_color = vec3(0.22, 0.40, 0.22);
uniform float wind_strength = 0.15;
uniform float wind_speed = 1.4;

void vertex() {
	float h = COLOR.r; // packed height mask 0-1 via vertex color
	float t = TIME * wind_speed;
	float sway = sin(t + NODE_POSITION_WORLD.x * 0.8 + NODE_POSITION_WORLD.z * 0.5) * wind_strength * h;
	VERTEX.x += sway;
	VERTEX.z += cos(t * 0.85 + NODE_POSITION_WORLD.z * 0.6) * wind_strength * 0.55 * h;
}

void fragment() {
	float h = COLOR.r;
	vec3 col = mix(root_color, tip_color, h);
	float ndl = clamp(dot(NORMAL, vec3(0.2, 1.0, 0.15)), 0.25, 1.0);
	ALBEDO = col * (0.75 + ndl * 0.35);
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}
