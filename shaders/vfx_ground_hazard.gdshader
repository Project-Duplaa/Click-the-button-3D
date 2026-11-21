shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 color_primary : source_color = vec4(0.55, 0.15, 0.95, 1.0);
uniform vec4 color_secondary : source_color = vec4(0.20, 0.05, 0.55, 1.0);
uniform vec4 color_core : source_color = vec4(0.95, 0.75, 1.00, 1.0);
uniform float mode : hint_range(0.0, 2.0) = 0.0;
uniform float energy : hint_range(0.5, 6.0) = 2.6;
uniform float alpha_mult : hint_range(0.0, 1.0) = 1.0;
uniform float spin_speed = 2.2;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float ang = atan(p.y, p.x);

	float outer_falloff = 1.0 - smoothstep(0.75, 1.0, r);
	vec3 final_col = color_primary.rgb;
	float final_alpha = 0.0;

	if (mode < 0.5) {
		// Void Spiral Accretion Vortex
		float spiral = sin(ang * 4.0 + log(max(r, 0.03)) * 5.0 + TIME * spin_speed * 2.5) * 0.5 + 0.5;
		float spiral_tight = smoothstep(0.32, 0.85, spiral);
		float hole = smoothstep(0.16, 0.25, r);
		float photon_ring = smoothstep(0.18, 0.27, r) * (1.0 - smoothstep(0.29, 0.42, r));
		float rim_pulse = smoothstep(0.68, 0.82, r) * (1.0 - smoothstep(0.84, 0.96, r)) * (0.75 + 0.25 * sin(TIME * 5.0));

		float glow = max(spiral_tight * hole * 0.78, max(photon_ring * 1.15, rim_pulse * 0.90));
		final_col = mix(color_secondary.rgb, color_primary.rgb, spiral_tight);
		final_col = mix(final_col, color_core.rgb, clamp(photon_ring * 1.2 + rim_pulse * 0.45, 0.0, 1.0));
		final_alpha = glow * outer_falloff;
	} else if (mode < 1.5) {
		// Cracked Molten Magma Pool
		float c1 = abs(sin(p.x * 5.5 + sin(p.y * 4.2 + TIME * 1.4)) + cos(p.y * 5.2 - sin(p.x * 4.6 - TIME * 1.2)));
		float c2 = abs(sin((p.x + p.y) * 4.8 - TIME * 1.1) + cos((p.x - p.y) * 4.4 + TIME * 0.9));
		float fissures = 1.0 - smoothstep(0.06, 0.48, min(c1, c2));
		float heat_rim = smoothstep(0.62, 0.84, r) * (1.0 - smoothstep(0.86, 0.98, r)) * (0.80 + 0.20 * sin(TIME * 4.5));
		float ember_base = 0.28 + 0.14 * sin(r * 10.0 - TIME * 2.8);

		final_col = mix(color_secondary.rgb, color_primary.rgb, clamp(ember_base + heat_rim, 0.0, 1.0));
		final_col = mix(final_col, color_core.rgb, clamp(fissures * 1.05 + heat_rim * 0.35, 0.0, 1.0));
		final_alpha = clamp(max(ember_base, max(fissures * 0.95, heat_rim * 0.85)), 0.0, 1.0) * outer_falloff;
	} else {
		// Electric Voltaic Field
		float spoke = abs(sin(ang * 6.0 + sin(r * 14.0 - TIME * 8.0) * 1.4));
		float arcs = smoothstep(0.84, 0.99, spoke) * (1.0 - smoothstep(0.75, 0.96, r));
		float rings = smoothstep(0.72, 0.98, sin(r * 22.0 - TIME * 7.5) * 0.5 + 0.5) * 0.65;
		float rim = smoothstep(0.72, 0.84, r) * (1.0 - smoothstep(0.86, 0.98, r));

		final_col = mix(color_secondary.rgb, color_primary.rgb, clamp(rings + rim, 0.0, 1.0));
		final_col = mix(final_col, color_core.rgb, clamp(arcs * 0.95 + rim * 0.45, 0.0, 1.0));
		final_alpha = clamp(max(arcs, max(rings * 0.6, rim * 0.95)), 0.0, 1.0) * outer_falloff;
	}

	ALBEDO = final_col * energy;
	ALPHA = clamp(final_alpha * alpha_mult, 0.0, 1.0);
}
