shader_type canvas_item;

uniform vec2 bar_size = vec2(184.0, 20.0);
uniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float trail_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float shield_ratio : hint_range(0.0, 1.0) = 0.0;
uniform int segment_notches : hint_range(0, 8) = 0;
uniform float phase_mark_1 : hint_range(0.0, 1.0) = 0.0;
uniform float phase_mark_2 : hint_range(0.0, 1.0) = 0.0;

uniform vec4 color_bg : source_color = vec4(0.090, 0.024, 0.043, 0.96);
uniform vec4 color_hp_top : source_color = vec4(0.969, 0.224, 0.329, 1.0);
uniform vec4 color_hp_bot : source_color = vec4(0.580, 0.043, 0.129, 1.0);
uniform vec4 color_trail : source_color = vec4(0.988, 0.914, 0.541, 0.96);
uniform vec4 color_shield_top : source_color = vec4(0.49, 0.83, 0.99, 0.96);
uniform vec4 color_shield_bot : source_color = vec4(0.05, 0.48, 0.78, 0.92);
uniform vec4 border_color : source_color = vec4(0.271, 0.361, 0.478, 0.90);

float sd_pill(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec2 sz = max(bar_size, vec2(20.0, 8.0));
	vec2 p_px = (UV - vec2(0.5)) * sz;
	float r = sz.y * 0.5 - 0.5;
	float d = sd_pill(p_px, sz * 0.5 - vec2(0.5), r);

	float outer_a = 1.0 - smoothstep(-0.7, 0.7, d);
	if (outer_a <= 0.001) {
		discard;
	}

	float x = UV.x;
	float y = UV.y;

	vec3 col = color_bg.rgb;
	// Subtle sunken capsule groove gradient
	col *= mix(0.75, 1.14, y);

	// 1. Delayed white-amber damage catch-up bar
	if (x <= trail_ratio) {
		float trail_grad = mix(1.08, 0.82, y);
		col = color_trail.rgb * trail_grad;
	}

	// 2. Primary Vitality Crimson HP bar with sculpted convex glass bevel
	if (x <= hp_ratio) {
		vec3 hp_grad = mix(color_hp_top.rgb, color_hp_bot.rgb, pow(y, 0.90));
		float gloss = smoothstep(0.46, 0.04, y) * 0.34;
		col = mix(hp_grad, vec3(1.0, 0.84, 0.88), gloss);
		// Soft bottom bounce highlight inside capsule
		float bot_bounce = smoothstep(0.76, 1.0, y) * 0.14;
		col += vec3(0.45, 0.06, 0.12) * bot_bounce;
	}

	// 3. Soul Shield Cyan Overlay (stacks flush from right side of HP or caps cleanly inside bar)
	if (shield_ratio > 0.001) {
		float sh_end = min(1.0, hp_ratio + shield_ratio);
		float sh_start = max(0.0, sh_end - shield_ratio);
		if (x >= sh_start && x <= sh_end) {
			float hatch = step(0.58, fract(x * 26.0 - y * 1.4 - TIME * 0.95));
			vec3 sh_col = mix(color_shield_top.rgb, color_shield_bot.rgb, y);
			sh_col = mix(sh_col, vec3(0.92, 0.98, 1.0), hatch * 0.35);
			float blend_amt = (x > hp_ratio) ? 0.95 : 0.72;
			col = mix(col, sh_col, blend_amt);
		}
	}

	// 4. Optional brass boss phase dividers (uniform segment_notches o umbrales exactos 60% / 25%)
	if (segment_notches > 1) {
		float step_x = 1.0 / float(segment_notches);
		for (int i = 1; i < 8; i++) {
			if (i >= segment_notches) {
				break;
			}
			float tick_pos = float(i) * step_x;
			float dist_tick = abs(x - tick_pos);
			if (dist_tick < 0.004 && (y < 0.34 || y > 0.66)) {
				col = mix(col, border_color.rgb, 0.9);
			}
		}
	}
	if (phase_mark_1 > 0.01 && phase_mark_1 < 0.99) {
		float d1 = abs(x - phase_mark_1);
		if (d1 < 0.0045) {
			float strength1 = (y < 0.30 || y > 0.70) ? 0.96 : 0.48;
			col = mix(col, vec3(1.0, 0.88, 0.45), strength1);
		}
	}
	if (phase_mark_2 > 0.01 && phase_mark_2 < 0.99) {
		float d2 = abs(x - phase_mark_2);
		if (d2 < 0.0045) {
			float strength2 = (y < 0.30 || y > 0.70) ? 0.98 : 0.55;
			col = mix(col, vec3(1.0, 0.42, 0.24), strength2);
		}
	}

	// 5. Crisp cool-steel capsule rim
	float rim = 1.0 - smoothstep(0.45, 1.45, abs(d + 0.75));
	col = mix(col, border_color.rgb, rim * border_color.a);

	COLOR = vec4(col, outer_a);
}
