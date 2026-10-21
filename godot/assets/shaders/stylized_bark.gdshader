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
	float groove_mask = smoothstep(0.12, 0.40, y);
	// 太い少数溝：ノイズで曲げ、規則柱禁止
	float warp = _n2(vec2(ang * 0.55, y * 0.35)) * 1.4
		+ _n2(vec2(ang * 1.4 + 1.8, y * 0.8)) * 0.7;
	float a01 = ang / 6.2831853 + warp * 0.10;
	float gA = 0.5 + 0.5 * sin((a01 * 3.0 + warp * 0.7) * 6.2831853);
	float gN = _n2(vec2(a01 * 4.5 + warp, y * 0.9));
	float groove = gA * 0.62 + gN * 0.38;
	groove = smoothstep(0.32, 0.68, groove) * groove_mask;
	float grain = _n2(vec2(ang * 3.2, y * 2.4));
	groove = mix(groove, groove * (0.75 + grain * 0.45), 0.40);
	return groove;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float g = _groove_at(v_world);
	VERTEX += NORMAL * (g - 0.40) * 0.024;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float groove = _groove_at(v_world);
	float groove_mask = smoothstep(0.18, 0.48, v_world.y);
	float tex_g = tex.r * 0.40 + 0.32;
	groove = mix(tex_g * groove_mask, groove, 0.62);

	vec3 n = NORMAL;
	vec3 t_ang = normalize(cross(NORMAL, vec3(0.0, 1.0, 0.0)));
	if (length(t_ang) < 1e-3) {
		t_ang = vec3(1.0, 0.0, 0.0);
	}
	// 法線曲げを弱めて金属ハイライト感を消す（マット粘土）
	n += t_ang * (groove - 0.5) * 0.55 * groove_mask;
	n = normalize(n);
	// 完全マット：カスタムN·Lハイライトをやめ、溝の色差だけ
	vec3 base = mix(bark_color * 1.04, bark_dark * 0.70, groove * 1.10);
	base *= 0.97;
	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
