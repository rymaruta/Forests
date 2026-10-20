shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.05;
uniform float uv_scale_y = 2.1;

varying vec3 v_world;

float _hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float _n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = _hash21(i);
	float b = _hash21(i + vec2(1, 0));
	float c = _hash21(i + vec2(0, 1));
	float d = _hash21(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float _groove_at(vec3 wpos) {
	float ang = atan(wpos.z, wpos.x);
	float y = wpos.y;
	// 裾は溝弱め（趾マウンドを壊さない）、中腹で彫刻
	float groove_mask = smoothstep(0.10, 0.42, y);
	float warp = _n2(vec2(ang * 0.65, y * 0.38)) * 1.7
		+ _n2(vec2(ang * 1.7 + 2.1, y * 0.9)) * 0.9
		+ _n2(vec2(y * 0.5, ang * 0.5)) * 0.5;
	float a01 = ang / 6.2831853 + warp * 0.14;
	float gN = _n2(vec2(a01 * 5.8 + warp, y * 1.05));
	float gN2 = _n2(vec2(a01 * 10.0 - warp * 0.7, y * 2.0 + 1.2));
	float gA = 0.5 + 0.5 * sin((a01 * 2.4 + warp * 0.85) * 6.2831853);
	float groove = gN * 0.50 + gN2 * 0.28 + gA * 0.22;
	groove = smoothstep(0.28, 0.70, groove) * groove_mask;
	float grain = _n2(vec2(ang * 3.8, y * 2.9));
	groove = mix(groove, groove * (0.70 + grain * 0.58), 0.55);
	float break_y = smoothstep(0.22, 0.58, _n2(vec2(a01 * 2.8, y * 0.6)));
	groove *= mix(0.50, 1.0, break_y);
	return groove;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// 頂点で溝を彫る（アルベドだけの擬似溝は浮く）
	float g = _groove_at(v_world);
	VERTEX += NORMAL * (g - 0.42) * 0.032;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float groove = _groove_at(v_world);
	float groove_mask = smoothstep(0.10, 0.42, v_world.y);
	float tex_g = tex.r * 0.50 + 0.24;
	groove = mix(tex_g * groove_mask, groove, 0.58);

	vec3 n = NORMAL;
	vec3 t_ang = normalize(cross(NORMAL, vec3(0.0, 1.0, 0.0)));
	if (length(t_ang) < 1e-3) {
		t_ang = vec3(1.0, 0.0, 0.0);
	}
	n += t_ang * (groove - 0.5) * 0.90 * groove_mask;
	n = normalize(n);
	float ndl = clamp(dot(n, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.76, 1.0, ndl);
	// 基調は幹色。溝で暗く彫る（趾を別色にしない）
	vec3 base = mix(bark_color * 1.02, bark_dark * 0.70, groove * 1.05);
	base *= 0.84 + ndl * 0.20;
	ALBEDO = base;
	ROUGHNESS = 0.99;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
