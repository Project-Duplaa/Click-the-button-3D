shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 main_color : source_color = vec4(0.20, 0.90, 1.00, 1.0);
uniform vec4 core_color : source_color = vec4(1.00, 0.98, 0.95, 1.0);
uniform vec4 edge_color : source_color = vec4(0.08, 0.35, 0.95, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float energy : hint_range(0.5, 8.0) = 3.2;
uniform float alpha_mult : hint_range(0.0, 1.0) = 1.0;
uniform float sweep_mode : hint_range(0.0, 1.0) = 0.0;
uniform float flip_dir : hint_range(-1.0, 1.0) = 1.0;
uniform float streaks : hint_range(2.0, 32.0) = 10.0;

void fragment() {
	float u = flip_dir < 0.0 ? (1.0 - UV.x) : UV.x;
	float v = clamp(UV.y, 0.0, 1.0);

	float rim_mask = smoothstep(0.08, 0.78, v) * (1.0 - smoothstep(0.92, 1.0, v));
	float razor_edge = smoothstep(0.70, 0.90, v) * (1.0 - smoothstep(0.92, 1.0, v));
	float mask = 0.0;
	float core_factor = 0.0;

	if (sweep_mode < 0.5) {
		float head = clamp(progress * 1.45, 0.0, 1.05);
		float tail = clamp((progress - 0.16) * 1.32, 0.0, 1.02);
		float lead = 1.0 - smoothstep(head - 0.08, head + 0.02, u);
		float wake = smoothstep(tail - 0.30, tail + 0.04, u);
		float taper = pow(clamp(sin(clamp(u, 0.0, 1.0) * 3.14159265), 0.0, 1.0), 0.52);
		float striation = 0.68 + 0.32 * sin((v * streaks - progress * 5.0) * 6.2831853 + u * 8.0);
		float life_fade = 1.0 - smoothstep(0.68, 1.0, progress);

		mask = lead * wake * taper * rim_mask * striation * life_fade;
		float head_hot = smoothstep(head - 0.22, head, u) * lead;
		core_factor = clamp(razor_edge * 0.85 + head_hot * 0.55, 0.0, 1.0);
	} else {
		float angle_u = fract(u + TIME * 2.4 + progress * 1.8);
		float arc_a = smoothstep(0.15, 0.65, sin(angle_u * 6.2831853) * 0.5 + 0.5);
		float arc_b = smoothstep(0.30, 0.85, sin((angle_u * 2.0 + v * 0.65) * 6.2831853) * 0.5 + 0.5);
		float wind_ribbon = max(arc_a * 0.88, arc_b * 0.72);
		float striation = 0.72 + 0.28 * sin((v * streaks + angle_u * 4.0) * 6.2831853);
		float life_in = smoothstep(0.0, 0.12, progress);
		float life_out = 1.0 - smoothstep(0.54, 1.0, progress);

		mask = wind_ribbon * rim_mask * striation * life_in * life_out;
		core_factor = clamp(razor_edge * 0.90 + arc_b * 0.35, 0.0, 1.0);
	}

	vec3 col_body = mix(edge_color.rgb, main_color.rgb, smoothstep(0.15, 0.75, v));
	vec3 final_col = mix(col_body, core_color.rgb, core_factor) * energy;

	ALBEDO = final_col;
	ALPHA = clamp(mask * alpha_mult, 0.0, 1.0);
}
