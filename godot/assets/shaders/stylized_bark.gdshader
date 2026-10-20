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

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float ang = atan(v_world.z, v_world.x);
	float y = v_world.y;

	// 有機縦溝：角度を強く曲げ、規則 sin 帯を抑える（機械柱・ゼブラ禁止）
	// 裾・趾は溝を弱め（マウンドを壊さない）、幹中腹で読む
	// 裾でも色を落とさない（暗い趾カラー＝幹との継ぎ目に見える）
	// 溝だけ幹中腹で強く、趾は浅い彫刻
	float groove_mask = smoothstep(0.06, 0.38, y);
	float warp = _n2(vec2(ang * 0.7, y * 0.42)) * 1.55
		+ _n2(vec2(ang * 1.8 + 2.4, y * 0.95)) * 0.85
		+ _n2(vec2(y * 0.55, ang * 0.55)) * 0.55;
	float a01 = ang / 6.2831853 + warp * 0.12;
	float gN = _n2(vec2(a01 * 6.5 + warp, y * 1.15));
	float gN2 = _n2(vec2(a01 * 11.0 - warp * 0.8, y * 2.2 + 1.3));
	float gA = 0.5 + 0.5 * sin((a01 * 2.7 + warp * 0.9) * 6.2831853);
	float groove = gN * 0.48 + gN2 * 0.30 + gA * 0.22;
	groove = smoothstep(0.30, 0.72, groove) * groove_mask;
	float grain = _n2(vec2(ang * 4.2, y * 3.1));
	groove = mix(groove, groove * (0.72 + grain * 0.55), 0.55);
	float break_y = smoothstep(0.25, 0.55, _n2(vec2(a01 * 3.0, y * 0.65)));
	groove *= mix(0.55, 1.0, break_y);

	float tex_g = tex.r * 0.55 + 0.22;
	groove = mix(tex_g * groove_mask, groove, 0.42);

	vec3 n = NORMAL;
	vec3 t_ang = normalize(cross(NORMAL, vec3(0.0, 1.0, 0.0)));
	if (length(t_ang) < 1e-3) {
		t_ang = vec3(1.0, 0.0, 0.0);
	}
	n += t_ang * (groove - 0.5) * 0.62 * groove_mask;
	n = normalize(n);
	float ndl = clamp(dot(n, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.84, 1.0, ndl);
	// 基調は幹色。溝で暗く彫る（趾を別色にしない）
	vec3 base = mix(bark_color * 1.08, bark_dark * 0.85, groove * 0.88);
	base *= 0.88 + ndl * 0.16;
	ALBEDO = base;
	ROUGHNESS = 0.99;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
