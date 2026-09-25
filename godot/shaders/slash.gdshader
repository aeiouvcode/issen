shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
#include "res://shaders/common.gdshaderinc"
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
// C60: per-swing params ride INSTANCE_CUSTOM so all curtains share one MultiMesh
varying vec4 cust;
void vertex() {
	cust = INSTANCE_CUSTOM;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float prog = cust.x;
	float life = cust.y;
	float flip = cust.z;
	float tint = cust.w;
	vec2 uv = UV;
	if (flip > 0.5) uv.x = 1.0 - uv.x;
	// rotate around the arc centre so the wet leading edge travels with prog
	vec2 c = vec2(0.5, 1.02);
	vec2 p = (uv - c) * vec2(2.0, 1.0);
	float a = (1.0 - prog) * 1.3;
	p = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p;
	vec2 suv = p / vec2(2.0, 1.0) + c;
	vec4 t = texture(tex, suv);
	float inside = step(0.0, suv.x) * step(suv.x, 1.0) * step(0.0, suv.y) * step(suv.y, 1.0);
	// soft quad border so the rotated sweep never shows a hard cut
	vec2 bq = min(UV, 1.0 - UV);
	inside *= smoothstep(0.0, 0.08, min(bq.x * 0.5, bq.y));
	// sweep reveal: wash appears behind the travelling rim
	inside *= smoothstep(0.0, 0.25, prog);
	float n = vnoise(UV * vec2(40.0, 9.0));
	float d = t.a - (1.0 - life) * (0.85 + 0.6 * n);
	// translucent grey wash body, dense ink only where the texture is dense (wet rim)
	float dense = smoothstep(0.62, 0.92, t.a);
	vec3 wash = mix(vec3(0.52, 0.5, 0.47), t.rgb, dense);
	ALBEDO = mix(wash, vec3(0.62, 0.07, 0.08), tint);
	ALPHA = clamp(d * 1.6, 0.0, 1.0) * mix(0.38, 0.95, dense) * inside;
}
