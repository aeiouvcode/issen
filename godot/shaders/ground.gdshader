shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform;
#include "res://shaders/common.gdshaderinc"
uniform vec3 paper : source_color = vec3(0.886, 0.816, 0.690);
uniform vec3 fleck : source_color = vec3(0.30, 0.25, 0.20);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = wpos.xz;
	float stain = fbm(p * 0.06) * 0.6 + fbm(p * 0.45 + 3.0) * 0.4;
	vec3 col = paper * (0.9 + 0.14 * stain);
	// stippled flecks: one dab per cell, squashed horizontally like dry brush taps
	// C34: reference ground is mostly clean parchment - sparse round stipple dots that
	// gather in drifting patches, not an all-over dash hatch
	vec2 q = p * 4.2;
	vec2 id = floor(q); vec2 f = fract(q);
	// C46: reference speckle is denser and varied - dots mixed with tiny lying dashes
	float dens = smoothstep(0.35, 0.75, fbm(p * 0.09 + 9.0));
	float dab = 0.0;
	for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
		vec2 n = vec2(float(i), float(j));
		vec2 c = id + n;
		vec2 o = vec2(hash21(c), hash21(c + 17.3));
		vec2 d = n + o - f;
		float r = 0.04 + 0.11 * hash21(c + 5.1);
		float on = step(1.0 - dens * 0.62, hash21(c + 9.7));
		float isdash = step(0.66, hash21(c + 13.7));
		vec2 dd = mix(d, d * vec2(1.0, 2.3), isdash);
		dab = max(dab, on * smoothstep(r, r * 0.45, length(dd)) * (0.55 + 0.45 * hash21(c + 2.2)));
	}
	dab *= (0.35 + 0.65 * dens) * (0.45 + 0.55 * vnoise(p * 16.0));
	float dist = length(wpos - CAMERA_POSITION_WORLD);
	float haze = smoothstep(10.0, 34.0, dist);
	col = mix(col, fleck, dab * 0.8 * (1.0 - haze * 0.85));
	// faint broad wash patches
	col *= 1.0 - 0.08 * smoothstep(0.55, 0.8, fbm(p * 0.035 + 4.0));
	// C46: soft mottled blotches - big faint darker and paler patches like the reference
	col *= 1.0 - 0.10 * smoothstep(0.58, 0.85, fbm(p * 0.5 + 7.0)) * (1.0 - haze);
	col = mix(col, paper * 1.06, 0.09 * smoothstep(0.6, 0.85, fbm(p * 0.33 + 21.0)) * (1.0 - haze));
	col = mix(col, paper * 1.05, haze * 0.75);
	ALBEDO = col;
}
