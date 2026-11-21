shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 main_color : source_color = vec4(0.35, 0.88, 1.00, 1.0);
uniform vec4 core_color : source_color = vec4(1.00, 0.98, 0.95, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy : hint_range(0.5, 8.0) = 3.4;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.1;
uniform float noise_scale = 5.5;

void fragment() {
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(clamp(1.0 - ndotv, 0.0, 1.0), fresnel_power);

	float n1 = sin(UV.x * noise_scale * 6.2831853 + TIME * 4.0) * cos(UV.y * noise_scale * 6.2831853 - TIME * 3.2);
	float n2 = sin((UV.x + UV.y) * noise_scale * 9.5 - TIME * 5.5) * cos((UV.x - UV.y) * noise_scale * 7.5 + TIME * 4.2);
	float n3 = sin(NORMAL.x * 8.0 + NORMAL.z * 8.0 + TIME * 6.0);
	float plasma_val = clamp((n1 * 0.5 + n2 * 0.35 + n3 * 0.15) * 0.5 + 0.5, 0.0, 1.0);

	float dissolve_edge = progress * 1.15;
	float plasma_dissolve = smoothstep(dissolve_edge - 0.18, dissolve_edge + 0.18, plasma_val + rim * 0.55);
	float early_flash = (1.0 - smoothstep(0.0, 0.35, progress)) * 0.65;
	float life_out = 1.0 - smoothstep(0.60, 1.0, progress);

	float alpha = clamp(max(rim * 0.92, early_flash) * plasma_dissolve * life_out, 0.0, 1.0);
	float core_mix = clamp(rim * 0.78 + early_flash * 0.75, 0.0, 1.0);
	vec3 col = mix(main_color.rgb, core_color.rgb, core_mix) * energy;

	ALBEDO = col;
	ALPHA = alpha;
}
