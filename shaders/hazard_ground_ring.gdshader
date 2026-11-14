shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform float inner_radius : hint_range(0.0, 1.0) = 0.80;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.96;
uniform float edge_softness : hint_range(0.001, 0.25) = 0.025;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float segment_count : hint_range(1.0, 64.0) = 24.0;
uniform float rotation_speed = 0.45;
uniform float segment_duty_cycle : hint_range(0.05, 1.0) = 0.68;
uniform vec4 base_color : source_color = vec4(1.0, 0.718, 0.012, 1.0);
uniform vec4 active_color : source_color = vec4(0.0, 0.941, 1.0, 1.0);
uniform float active_state : hint_range(0.0, 1.0) = 0.0;
uniform float track_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_frequency = 2.5;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 0.25;
uniform float inner_fill_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float emission_strength : hint_range(0.1, 6.0) = 1.65;
uniform float overall_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);

	float outer_edge = 1.0 - smoothstep(outer_radius - edge_softness, outer_radius + edge_softness, r);
	float inner_edge = smoothstep(inner_radius - edge_softness, inner_radius + edge_softness, r);
	float ring_mask = clamp(inner_edge * outer_edge, 0.0, 1.0);

	// 12 o'clock (-Z => p = (0.0, -1.0)) clockwise [0.0 .. 1.0)
	float angle = atan(p.x, -p.y);
	if (angle < 0.0) {
		angle += 6.28318530718;
	}
	float norm_angle = clamp(angle / 6.28318530718, 0.0, 0.999999);

	// Rotating segmented tactical ticks
	float rot_angle = norm_angle + (TIME * rotation_speed) / 6.28318530718;
	float seg_phase = fract(rot_angle * segment_count);
	float seg_edge = 0.06;
	float dash_mask = smoothstep(0.0, seg_edge, seg_phase) * (1.0 - smoothstep(segment_duty_cycle - seg_edge, segment_duty_cycle, seg_phase));
	float seg_mask = mix(dash_mask, 1.0, smoothstep(0.95, 0.995, segment_duty_cycle));

	// Thin crisp perimeter guide rails so full boundary radius stays readable even at progress == 0.0
	float outer_rail = smoothstep(outer_radius - edge_softness * 1.4, outer_radius - edge_softness * 0.35, r) * outer_edge;
	float inner_rail = inner_edge * (1.0 - smoothstep(inner_radius + edge_softness * 0.35, inner_radius + edge_softness * 1.4, r));
	float rail_mask = clamp(max(outer_rail, inner_rail), 0.0, 1.0);

	// Clockwise progress sector from -Z (12 o'clock)
	float progress_mask = step(0.001, progress) * (1.0 - step(progress, norm_angle));

	float pulse = max(0.2, 1.0 + sin(TIME * pulse_frequency * 2.0) * pulse_intensity);

	// Track layer always visible across entire 360-degree perimeter
	float track_pattern = max(seg_mask, rail_mask * 0.55);
	float track_layer = ring_mask * track_pattern * track_alpha;

	// Active/filled layer highlights filled arc or full active state
	float active_mix = clamp(max(active_state, progress_mask), 0.0, 1.0);
	float active_pattern = max(seg_mask, rail_mask * 0.75);
	float active_layer = ring_mask * active_pattern * active_mix * max(track_alpha + 0.45, 0.85);

	// Optional soft interior halo / proximity fill glow
	float inner_area = 1.0 - smoothstep(inner_radius - edge_softness * 1.5, inner_radius + edge_softness * 0.5, r);
	float norm_r = clamp(r / max(inner_radius, 0.001), 0.0, 1.0);
	float inner_halo = inner_area * mix(0.22, 0.95, norm_r * norm_r) * inner_fill_alpha;
	float inner_boost = inner_area * progress_mask * inner_fill_alpha * 0.65;

	vec3 ring_col = mix(base_color.rgb, active_color.rgb, active_mix);
	vec3 fill_col = mix(base_color.rgb, active_color.rgb, clamp(active_state + progress_mask * 0.85, 0.0, 1.0));

	float total_alpha = clamp((max(track_layer, active_layer) + inner_halo + inner_boost) * overall_alpha, 0.0, 1.0);
	vec3 final_col = mix(fill_col, ring_col, clamp(ring_mask * 1.5, 0.0, 1.0)) * emission_strength * pulse;

	ALBEDO = final_col;
	ALPHA = total_alpha;
}
