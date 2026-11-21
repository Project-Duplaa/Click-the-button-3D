shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 beam_color : source_color = vec4(0.15, 0.88, 1.00, 1.0);
uniform vec4 core_color : source_color = vec4(0.95, 0.99, 1.00, 1.0);
uniform float energy : hint_range(0.5, 8.0) = 3.5;
uniform float alpha_mult : hint_range(0.0, 1.0) = 1.0;
uniform float scroll_speed = 4.5;
uniform float noise_freq = 12.0;
uniform float core_width : hint_range(0.05, 0.6) = 0.22;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float end_fade : hint_range(0.0, 0.3) = 0.05;
uniform float use_fresnel : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float along = clamp(UV.y * 2.0, 0.0, 1.0);
	float ends = smoothstep(0.0, max(end_fade, 0.005), along) * (1.0 - smoothstep(1.0 - max(end_fade, 0.005), 1.0, along));

	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float ribbon = 1.0 - abs(UV.x * 2.0 - 1.0);
	float profile = mix(ribbon, ndotv, step(0.5, use_fresnel));
	profile = clamp(profile, 0.0, 1.0);

	float wave_a = sin((along * noise_freq - TIME * scroll_speed) * 6.2831853);
	float wave_b = sin((along * noise_freq * 2.3 + TIME * scroll_speed * 1.35 + UV.x * 6.2831853) * 6.2831853);
	float ripple = clamp(0.76 + 0.16 * wave_a + 0.08 * wave_b, 0.35, 1.15);

	float core_thresh = clamp(1.0 - core_width * (1.0 - dissolve * 0.7), 0.15, 0.96);
	float core_mask = smoothstep(core_thresh - 0.15, core_thresh + 0.08, profile);
	float sheath_mask = pow(profile, 1.35);

	float life_fade = 1.0 - smoothstep(0.25, 1.0, dissolve);
	float alpha = clamp(max(sheath_mask, core_mask) * ends * ripple * life_fade * alpha_mult, 0.0, 1.0);
	vec3 col = mix(beam_color.rgb, core_color.rgb, core_mask) * energy * (0.9 + 0.15 * ripple);

	ALBEDO = col;
	ALPHA = alpha;
}
