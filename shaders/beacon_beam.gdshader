shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 beam_color : source_color = vec4(1.0, 0.118, 0.259, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.80, 0.74, 1.0);
uniform float energy : hint_range(0.0, 6.0) = 2.6;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 0.70;
uniform float fresnel_power : hint_range(0.2, 6.0) = 1.4;
uniform float scroll_speed = 1.8;
uniform float pulse_speed = 4.2;
uniform float band_frequency = 6.0;

void fragment() {
	// Verified in Godot 4.7.2: CylinderMesh with cap_top=false, cap_bottom=false
	// maps UV.y across [0.0 (top) .. 0.5 (bottom)].
	float t_from_bottom = clamp(1.0 - UV.y * 2.0, 0.0, 1.0);

	// Soft bottom contact fade and long atmospheric top fade-out
	float bottom_fade = smoothstep(0.0, 0.08, t_from_bottom);
	float top_fade = 1.0 - smoothstep(0.45, 1.0, t_from_bottom);
	float vertical_mask = bottom_fade * top_fade;

	// Cylindrical Fresnel edge dissolution (eliminates hard vertical cylinder edges)
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float edge_fresnel = pow(clamp(ndotv, 0.0, 1.0), fresnel_power);
	float inner_core = pow(clamp(ndotv, 0.0, 1.0), fresnel_power * 2.5);

	// Upward energy striations and pulse
	float wave = 0.84 + 0.16 * sin((t_from_bottom * band_frequency - TIME * scroll_speed) * 6.2831853);
	float azim = 0.90 + 0.10 * sin(UV.x * 12.5663706 + TIME * scroll_speed * 0.9);
	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);

	vec3 col = mix(beam_color.rgb, core_color.rgb, inner_core * 0.55 * (1.0 - t_from_bottom * 0.6));
	float alpha = clamp(vertical_mask * edge_fresnel * alpha_multiplier * wave * azim, 0.0, 1.0);

	ALBEDO = col * energy * pulse;
	ALPHA = alpha;
}
