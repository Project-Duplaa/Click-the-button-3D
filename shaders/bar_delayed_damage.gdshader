shader_type canvas_item;

uniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float trail_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float shield_ratio : hint_range(0.0, 1.0) = 0.0;
uniform int segment_notches : hint_range(0, 8) = 0;

uniform vec4 color_bg : source_color = vec4(0.07, 0.02, 0.04, 0.96);
uniform vec4 color_hp_top : source_color = vec4(0.98, 0.32, 0.42, 1.0);
uniform vec4 color_hp_bot : source_color = vec4(0.58, 0.05, 0.14, 1.0);
uniform vec4 color_trail : source_color = vec4(0.99, 0.92, 0.54, 0.96);
uniform vec4 color_shield_top : source_color = vec4(0.49, 0.83, 0.99, 0.96);
uniform vec4 color_shield_bot : source_color = vec4(0.05, 0.48, 0.78, 0.92);
uniform vec4 border_color : source_color = vec4(0.76, 0.60, 0.32, 0.95);

void fragment() {
	float x = UV.x;
	float y = UV.y;

	vec3 col = color_bg.rgb;
	// Subtle sunken background groove gradient
	col *= mix(0.78, 1.12, y);

	// 1. Delayed white-amber damage catch-up bar
	if (x <= trail_ratio) {
		float trail_grad = mix(1.08, 0.82, y);
		col = color_trail.rgb * trail_grad;
	}

	// 2. Primary Vitality Crimson HP bar with sculpted convex bevel
	if (x <= hp_ratio) {
		vec3 hp_grad = mix(color_hp_top.rgb, color_hp_bot.rgb, pow(y, 0.85));
		// Razor-thin top specular sheen
		float gloss = (1.0 - smoothstep(0.0, 0.24, y)) * 0.38;
		col = mix(hp_grad, vec3(1.0, 0.88, 0.90), gloss);
	}

	// 3. Soul Shield Cyan Overlay (stacks flush from right side of HP or caps cleanly inside bar)
	if (shield_ratio > 0.001) {
		float sh_end = min(1.0, hp_ratio + shield_ratio);
		float sh_start = max(0.0, sh_end - shield_ratio);
		if (x >= sh_start && x <= sh_end) {
			float hatch = step(0.58, fract(x * 26.0 - y * 1.4 - TIME * 0.95));
			vec3 sh_col = mix(color_shield_top.rgb, color_shield_bot.rgb, y);
			sh_col = mix(sh_col, vec3(0.92, 0.98, 1.0), hatch * 0.35);
			// If shield sits directly over active HP (when HP is near 100%), blend translucently; if extending, solid cyan
			float blend_amt = (x > hp_ratio) ? 0.95 : 0.78;
			col = mix(col, sh_col, blend_amt);
		}
	}

	// 4. Optional brass boss phase dividers (e.g. 25%, 50%, 75%)
	if (segment_notches > 1) {
		float step_x = 1.0 / float(segment_notches);
		for (int i = 1; i < 8; i++) {
			if (i >= segment_notches) break;
			float tick_pos = float(i) * step_x;
			float dist_tick = abs(x - tick_pos);
			if (dist_tick < 0.004 && (y < 0.32 || y > 0.68)) {
				col = mix(col, border_color.rgb, 0.9);
			}
		}
	}

	// 5. Crisp inner border frame
	vec2 px_size = fwidth(UV);
	float bx = max(px_size.x * 1.6, 0.005);
	float by = max(px_size.y * 1.6, 0.06);
	float is_border = step(x, bx) + step(1.0 - bx, x) + step(y, by) + step(1.0 - by, y);
	if (is_border > 0.5) {
		col = mix(col, border_color.rgb, 0.92);
	}

	COLOR = vec4(col, 1.0);
}
