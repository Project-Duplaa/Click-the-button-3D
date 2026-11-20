shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// ThreatDecal3D Shader — 100% compatible con gl_compatibility (OpenGL ES 3 / OpenGL 3.3)
// Modos: 0 = CIRCULO, 1 = CARRIL_EMBESTIDA (-Z), 2 = ARCO_CONO (-Z)
uniform int shape_type : hint_range(0, 2) = 0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.95, 0.16, 0.14, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 0.36, 0.14, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.86, 0.38, 1.0);
uniform float warning_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.92;
uniform float aspect_ratio : hint_range(0.1, 20.0) = 1.0;
uniform float arc_angle_deg : hint_range(15.0, 360.0) = 135.0;
uniform float inner_cutoff : hint_range(0.0, 0.8) = 0.12;

void fragment() {
	float prog = clamp(progress, 0.0, 1.0);
	float pulse_freq = mix(5.0, 18.0, warning_pulse);
	float pulse_wave = 0.5 + 0.5 * sin(TIME * pulse_freq);
	float flash_final = smoothstep(0.90, 1.0, prog);

	float shape_mask = 0.0;
	float border_mask = 0.0;
	float fill_mask = 0.0;
	float leading_mask = 0.0;
	float pattern_mask = 0.0;

	if (shape_type == 0) {
		// MODO 0: CIRCULO
		vec2 p = (UV - vec2(0.5)) * 2.0;
		float r = length(p);
		shape_mask = 1.0 - smoothstep(0.975, 1.0, r);

		// Borde perimetral nitido fijo desde progress == 0.0
		float outer_ring = smoothstep(0.915, 0.945, r) * shape_mask;
		float mid_guide = (smoothstep(0.49, 0.502, r) - smoothstep(0.502, 0.514, r)) * 0.35;
		border_mask = clamp(outer_ring + mid_guide, 0.0, 1.0);

		// Franjas sutiles de peligro en el fondo
		float stripe = 0.5 + 0.5 * sin((p.x + p.y) * 24.0 - TIME * 2.4);
		pattern_mask = smoothstep(0.55, 0.85, stripe) * 0.22 * shape_mask;

		// Disco/onda interior llenandose desde r=0 hasta r=0.96 segun progress
		float fill_r = prog * 0.96;
		fill_mask = (1.0 - smoothstep(max(0.001, fill_r - 0.025), fill_r + 0.008, r)) * step(0.002, prog) * shape_mask;
		leading_mask = (smoothstep(max(0.0, fill_r - 0.055), max(0.001, fill_r - 0.008), r) * (1.0 - smoothstep(fill_r - 0.002, fill_r + 0.015, r))) * step(0.02, prog) * shape_mask;
	} else if (shape_type == 1) {
		// MODO 1: CARRIL_EMBESTIDA hacia -Z (UV.y = 1.0 origen jefe, UV.y = 0.0 extremo frontal)
		float fwd = 1.0 - UV.y;
		float lat = abs(UV.x - 0.5) * 2.0;
		shape_mask = 1.0;

		float ar = max(aspect_ratio, 0.35);
		float cap_thick = clamp(0.08 / ar, 0.012, 0.12);
		float side_rail = smoothstep(0.86, 0.92, lat);
		float front_cap = smoothstep(1.0 - cap_thick * 1.4, 1.0 - cap_thick * 0.4, fwd);
		float back_cap = 1.0 - smoothstep(cap_thick * 0.3, cap_thick * 1.1, fwd);
		border_mask = clamp(max(side_rail, max(front_cap, back_cap * 0.65)), 0.0, 1.0);

		// Chevrones direccionales animados hacia adelante (-Z) con compensacion de aspecto
		float chev_phase = fract(fwd * ar * 1.35 - lat * 0.55 - TIME * 2.6);
		float chev_band = smoothstep(0.08, 0.18, chev_phase) * (1.0 - smoothstep(0.32, 0.42, chev_phase));
		float inside_rails = 1.0 - smoothstep(0.78, 0.86, lat);
		pattern_mask = chev_band * inside_rails * 0.45;

		// Llenado longitudinal de 0.0 (jefe) a 1.0 (extremo de embestida)
		float soft_fwd = clamp(0.035 / ar, 0.006, 0.04);
		fill_mask = (1.0 - smoothstep(max(0.001, prog - soft_fwd), prog + 0.006, fwd)) * step(0.002, prog);
		leading_mask = smoothstep(max(0.0, prog - soft_fwd * 2.4), max(0.001, prog - soft_fwd * 0.3), fwd) * (1.0 - smoothstep(prog, prog + soft_fwd * 0.6, fwd)) * step(0.02, prog);
	} else {
		// MODO 2: ARCO_CONO centrado en -Z
		vec2 p = (UV - vec2(0.5)) * 2.0;
		float r = length(p);
		float ang = abs(atan(p.x, -p.y));
		float half_rad = radians(clamp(arc_angle_deg, 15.0, 360.0) * 0.5);
		float cutoff = clamp(inner_cutoff, 0.0, 0.78);

		float outer_m = 1.0 - smoothstep(0.975, 1.0, r);
		float inner_m = smoothstep(max(0.0, cutoff - 0.02), cutoff + 0.015, r);
		float radial_m = outer_m * inner_m;

		float is_full = step(359.0, arc_angle_deg);
		float ang_dist_arc = (half_rad - ang) * max(r, 0.15);
		float sector_m = mix(smoothstep(-0.012, 0.02, ang_dist_arc), 1.0, is_full);
		shape_mask = radial_m * sector_m;

		// Bordes nitidos: arco exterior, arco interior y filos radiales laterales
		float outer_arc = smoothstep(0.915, 0.945, r) * shape_mask;
		float inner_arc = (1.0 - smoothstep(cutoff + 0.01, cutoff + 0.045, r)) * shape_mask * step(0.02, cutoff);
		float side_edge = (1.0 - smoothstep(0.018, 0.052, abs(ang_dist_arc))) * radial_m * sector_m * (1.0 - is_full);
		border_mask = clamp(max(outer_arc, max(inner_arc, side_edge)), 0.0, 1.0);

		// Estrias radiales sutiles de direccion de tajo
		float slash_pat = 0.5 + 0.5 * sin(r * 28.0 - TIME * 4.5);
		pattern_mask = smoothstep(0.65, 0.92, slash_pat) * 0.20 * shape_mask;

		// Llenado radial progresivo desde inner_cutoff hasta 0.96
		float fill_r = mix(cutoff, 0.96, prog);
		fill_mask = (1.0 - smoothstep(max(cutoff, fill_r - 0.025), fill_r + 0.008, r)) * step(0.002, prog) * shape_mask;
		leading_mask = smoothstep(max(cutoff, fill_r - 0.055), max(cutoff + 0.001, fill_r - 0.008), r) * (1.0 - smoothstep(fill_r - 0.002, fill_r + 0.015, r)) * step(0.02, prog) * shape_mask;
	}

	if (shape_mask <= 0.002) {
		discard;
	}

	// Composicion cromatica clara: fondo base + patrones + llenado progresivo + borde nitido + flash final
	float base_alpha = 0.22 + pattern_mask;
	float fill_alpha = fill_mask * mix(0.38, 0.58, prog);
	float border_alpha = border_mask * mix(0.86, 1.0, pulse_wave * warning_pulse);
	float lead_alpha = leading_mask * 0.88;

	vec3 col = base_color.rgb;
	col = mix(col, fill_color.rgb, clamp(fill_mask * 0.85, 0.0, 1.0));
	col = mix(col, edge_color.rgb, clamp(max(border_mask * 0.85, leading_mask), 0.0, 1.0));

	// Pulso acelerado en el ultimo 25% y flash blanco-carmesi en progress > 0.90
	col *= mix(1.0, 1.0 + 0.35 * pulse_wave, warning_pulse);
	vec3 flash_col = mix(vec3(1.0, 0.94, 0.88), vec3(1.0, 0.24, 0.28), 0.25);
	col = mix(col, flash_col, flash_final * 0.68);

	float total_alpha = clamp(max(max(base_alpha, fill_alpha), max(border_alpha, lead_alpha)) + flash_final * 0.22, 0.0, 1.0);
	ALBEDO = col;
	ALPHA = total_alpha * shape_mask * opacity;
}
