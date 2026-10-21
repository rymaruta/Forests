shader_type spatial;
// 薄いフェルト殻：アルファ切り抜きで縁のパイル厚みを出す
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.40, 0.48, 0.32);
uniform float density : hint_range(0.0, 1.0) = 0.42;
uniform float shell_tint : hint_range(0.5, 1.2) = 1.05;

varying vec3 v_world;
varying vec3 v_n;

float _hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	float lift = 0.018 + _hash31(VERTEX * 40.0) * 0.010;
	VERTEX += NORMAL * lift;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 tex = texture(leaf_tex, v_world.xz * 5.5).rgb;
	float n1 = _hash31(v_world * 48.0);
	float n2 = _hash31(v_world * 96.0 + 3.1);
	float pile = n1 * 0.65 + n2 * 0.35;
	float tex_l = dot(tex, vec3(0.3, 0.5, 0.2));
	float cut = pile * 0.70 + tex_l * 0.30;
	if (cut < density) {
		discard;
	}
	float facing = abs(dot(normalize(v_n), VIEW));
	float edge = pow(1.0 - facing, 1.4);
	vec3 base = leaf_color * (0.92 + tex_l * 0.18) * shell_tint;
	base *= 0.90 + edge * 0.18;
	ALBEDO = base;
	ALPHA = 1.0;
}
