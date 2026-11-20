shader_type canvas_item;

uniform vec2 panel_size = vec2(360.0, 94.0);
uniform float glow_pad = 8.0;
uniform float corner_radius : hint_range(0.0, 12.0) = 3.5;
uniform float border_thickness : hint_range(0.5, 4.0) = 1.6;

// Slope in pixels: +val indents bottom edge inward (\ on left, / on right); -val indents top edge inward
uniform float slope_left = 0.0;
uniform float slope_right = 0.0;
uniform float chamfer_tl : hint_range(0.0, 32.0) = 0.0;
uniform float chamfer_tr : hint_range(0.0, 32.0) = 0.0;
uniform float chamfer_bl : hint_range(0.0, 32.0) = 0.0;
uniform float chamfer_br : hint_range(0.0, 32.0) = 0.0;

uniform vec4 bg_top : source_color = vec4(0.035, 0.075, 0.141, 0.92);
uniform vec4 bg_bot : source_color = vec4(0.016, 0.035, 0.075, 0.95);
uniform vec4 border_color : source_color = vec4(0.133, 0.800, 1.000, 0.96);
uniform vec4 glow_color : source_color = vec4(0.039, 0.620, 1.000, 0.50);
uniform vec4 top_accent_color : source_color = vec4(0.961, 0.722, 0.239, 0.0);
uniform float top_accent_width : hint_range(0.0, 1.0) = 0.0;
uniform float bottom_corner_flare : hint_range(0.0, 1.0) = 0.0;
uniform float flare_side : hint_range(-1.0, 1.0) = 0.0;
uniform float overdrive_pulse : hint_range(0.0, 1.0) = 0.0;

float sd_poly8(vec2 p, vec2 v[8]) {
	float d = dot(p - v[0], p - v[0]);
	float s = 1.0;
	for (int i = 0; i < 8; i++) {
		int j = (i + 1) % 8;
		vec2 a = v[i];
		vec2 b = v[j];
		vec2 e = b - a;
		float l2 = dot(e, e);
		if (l2 < 0.001) {
			continue;
		}
		vec2 w = p - a;
		vec2 q = w - e * clamp(dot(w, e) / l2, 0.0, 1.0);
		d = min(d, dot(q, q));
		bvec3 c = bvec3(p.y >= a.y, p.y < b.y, e.x * w.y > e.y * w.x);
		if (all(c) || all(not(c))) {
			s *= -1.0;
		}
	}
	return s * sqrt(d);
}

void fragment() {
	vec2 sz = max(panel_size, vec2(32.0));
	vec2 p = UV * sz;

	float x0 = glow_pad + corner_radius;
	float x1 = sz.x - glow_pad - corner_radius;
	float y0 = glow_pad + corner_radius;
	float y1 = sz.y - glow_pad - corner_radius;

	vec2 TL = vec2(x0 + max(-slope_left, 0.0), y0);
	vec2 BL = vec2(x0 + max(slope_left, 0.0), y1);
	vec2 TR = vec2(x1 - max(-slope_right, 0.0), y0);
	vec2 BR = vec2(x1 - max(slope_right, 0.0), y1);

	vec2 dir_l = normalize(BL - TL);
	vec2 dir_r = normalize(BR - TR);

	vec2 v[8];
	v[0] = TL + vec2(chamfer_tl, 0.0);
	v[1] = TR - vec2(chamfer_tr, 0.0);
	v[2] = TR + dir_r * chamfer_tr;
	v[3] = BR - dir_r * chamfer_br;
	v[4] = BR - vec2(chamfer_br, 0.0);
	v[5] = BL + vec2(chamfer_bl, 0.0);
	v[6] = BL - dir_l * chamfer_bl;
	v[7] = TL + dir_l * chamfer_tl;

	float d = sd_poly8(p, v) - corner_radius;

	// Interior smoked obsidian gradient + subtle top specular glass sheen
	float gy = clamp((p.y - glow_pad) / max(sz.y - glow_pad * 2.0, 1.0), 0.0, 1.0);
	vec4 fill_col = mix(bg_top, bg_bot, pow(gy, 0.85));
	float inner_sheen = (1.0 - smoothstep(0.0, 16.0, p.y - glow_pad)) * 0.13;
	fill_col.rgb += border_color.rgb * inner_sheen;

	// Subtle bottom inner cyan bounce
	float bottom_bounce = (1.0 - smoothstep(0.0, 14.0, (sz.y - glow_pad) - p.y)) * 0.09;
	fill_col.rgb += border_color.rgb * bottom_bounce;

	// Overdrive magenta pulse shift
	vec3 od_col = vec3(0.98, 0.28, 0.74);
	float od_wave = 0.5 + 0.5 * sin(TIME * 7.0);
	vec3 active_border = mix(border_color.rgb, od_col, overdrive_pulse * (0.65 + 0.35 * od_wave));
	vec3 active_glow = mix(glow_color.rgb, od_col, overdrive_pulse * 0.85);

	// Crisp perimeter border + warm gold top energy flare + bottom-corner cyan hotspots
	float half_b = border_thickness * 0.5;
	float rim_mask = 1.0 - smoothstep(half_b - 0.65, half_b + 0.65, abs(d));
	vec3 rim_rgb = active_border * mix(0.76, 1.12, gy);

	// Top gold energy streak (used on center trapezoid)
	float top_glow_boost = 0.0;
	if (top_accent_color.a > 0.01 && top_accent_width > 0.01) {
		float cx = abs(UV.x - 0.5) / max(top_accent_width * 0.5, 0.01);
		float flare_x = 1.0 - smoothstep(0.28, 1.0, cx);
		float flare_y = 1.0 - smoothstep(0.0, 8.0, abs(p.y - glow_pad));
		float accent_amt = flare_x * flare_y * top_accent_color.a;
		rim_rgb = mix(rim_rgb, top_accent_color.rgb * 1.32, accent_amt);
		top_glow_boost = accent_amt;
		// Subtle warm gold spill onto top interior glass
		float inner_gold = flare_x * (1.0 - smoothstep(0.0, 18.0, max(p.y - glow_pad, 0.0))) * 0.16;
		fill_col.rgb += top_accent_color.rgb * inner_gold;
	}

	// Bright cyan specular hotspots near acute inner bottom corners
	if (bottom_corner_flare > 0.01) {
		float dist_bl = length(p - BL);
		float dist_br = length(p - BR);
		float dist_corner = min(dist_bl, dist_br);
		if (flare_side < -0.5) {
			dist_corner = dist_bl;
		} else if (flare_side > 0.5) {
			dist_corner = dist_br;
		}
		float hot = (1.0 - smoothstep(0.0, 42.0, dist_corner)) * bottom_corner_flare;
		rim_rgb = mix(rim_rgb, vec3(0.62, 0.95, 1.0), hot * 0.90);
	}

	// Soft outer bloom (reaches strictly zero at glow_pad edge)
	float outer_t = clamp(1.0 - max(d, 0.0) / max(glow_pad, 0.1), 0.0, 1.0);
	float outer_glow = pow(outer_t, 2.35) * glow_color.a * (1.0 + overdrive_pulse * 0.45);
	vec3 outer_rgb = mix(active_glow, top_accent_color.rgb, top_glow_boost * 0.85);

	float fill_alpha = (1.0 - smoothstep(-0.7, 0.7, d)) * fill_col.a;
	vec3 final_rgb = fill_col.rgb;
	float final_a = fill_alpha;

	if (d > 0.0) {
		final_rgb = outer_rgb;
		final_a = outer_glow;
	}

	final_rgb = mix(final_rgb, rim_rgb, rim_mask);
	final_a = max(final_a, rim_mask * border_color.a);

	COLOR = vec4(final_rgb, clamp(final_a, 0.0, 1.0));
}
