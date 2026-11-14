shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 holo_color : source_color = vec4(0.0, 0.941, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.75, 0.98, 1.0, 1.0);
uniform float energy : hint_range(0.0, 6.0) = 2.2;
uniform float scanline_frequency = 34.0;
uniform float scanline_speed = 2.5;
uniform float fresnel_power : hint_range(0.2, 6.0) = 2.0;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.08;
uniform float alpha_base : hint_range(0.0, 1.0) = 0.72;

void fragment() {
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float fresnel = pow(1.0 - clamp(ndotv, 0.0, 1.0), fresnel_power);

	// Animated holographic scanlines
	float scan_wave = sin((UV.y * scanline_frequency - TIME * scanline_speed) * 6.2831853);
	float scanlines = mix(0.62, 1.0, 0.5 + 0.5 * scan_wave);

	// Subtle horizontal holographic interference / micro-glitch
	float band = floor(UV.y * 22.0 + TIME * 3.5);
	float glitch_gate = step(0.90, fract(sin(floor(TIME * 8.0) * 12.9898) * 43758.5453));
	float band_noise = fract(sin(band * 78.233) * 43758.5453);
	float interference = 1.0 - glitch_intensity * 0.45 * glitch_gate * band_noise;

	float pulse = 0.92 + 0.08 * sin(TIME * 3.8);

	vec3 col = mix(holo_color.rgb, rim_color.rgb, clamp(fresnel * 0.85, 0.0, 1.0));
	float alpha = clamp((0.38 + 0.62 * fresnel) * alpha_base * scanlines * interference, 0.0, 1.0);

	ALBEDO = col * energy * scanlines * interference * pulse;
	ALPHA = alpha;
}
