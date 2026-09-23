shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
// soft alpha blend (no scissor) so thin fibres stay feathered
uniform float fade_near = 26.0;
uniform float fade_far = 44.0;
uniform vec3 far_col : source_color = vec3(0.56, 0.53, 0.49);
uniform vec3 ink_tint : source_color = vec3(1.0);
uniform float density = 1.0;
varying float vdist;
varying float vkeep;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.1 + MODEL_MATRIX[3].x * 0.6 + MODEL_MATRIX[3].z * 0.3) * 0.09 * top * top;
	vdist = length(MODEL_MATRIX[3].xyz - CAMERA_POSITION_WORLD);
	vkeep = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
	vec4 t = texture(tex, UV);
	float fade = 1.0 - smoothstep(fade_near, fade_far, vdist);
	// aerial perspective: far swaths go pale grey and thin, near ones keep ink weight
	float far = smoothstep(9.0, 32.0, vdist);
	ALBEDO = mix(t.rgb * ink_tint, far_col, 0.4 + 0.35 * far);
	// thinner swaths in sparse chapters: drop clumps by a stable per-instance hash
	float keep = step(vkeep, density);
	ALPHA = t.a * fade * mix(0.95, 0.6, far) * keep;
}
