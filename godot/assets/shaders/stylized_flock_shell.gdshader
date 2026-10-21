shader_type spatial;
// 冠の縁だけ葉色の薄い半透明毛羽。白ハロー・discardディザ禁止。
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.52, 0.56, 0.34);
uniform float density : hint_range(0.0, 1.0) = 0.62;
uniform float shell_tint : hint_range(0.5, 1.2) = 0.96;

varying vec3 v_world;
varying vec3 v_n;

float _hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	float lift = 0.010 + _hash31(VERTEX * 28.0) * 0.008;
	VERTEX += NORMAL * lift;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float facing = abs(dot(normalize(v_n), VIEW));
	float edge = pow(1.0 - facing, 1.25);
	float mask = smoothstep(0.12, 0.92, edge);
	float n1 = _hash31(v_world * 48.0);
	float n2 = _hash31(v_world * 96.0 + 1.7);
	float pile = n1 * 0.5 + n2 * 0.5;
	float a = mask * density * (0.45 + pile * 0.40);
	if (a < 0.05) {
		discard;
	}
	vec3 tex = texture(leaf_tex, v_world.xz * 3.2).rgb;
	float tex_l = dot(tex, vec3(0.3, 0.5, 0.2));
	// 本体より少し暗い葉色のみ。白縁を出さない
	vec3 base = leaf_color * (0.82 + tex_l * 0.12) * shell_tint;
	ALBEDO = base;
	ALPHA = clamp(a * 0.55, 0.0, 0.40);
}
