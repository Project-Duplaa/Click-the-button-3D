shader_type canvas_item;

uniform vec4 backdrop_core : source_color = vec4(0.078, 0.176, 0.322, 1.0);
uniform vec4 backdrop_edge : source_color = vec4(0.020, 0.047, 0.102, 1.0);
uniform vec4 class_aura : source_color = vec4(0.141, 0.722, 1.000, 1.0);
uniform vec4 steel_dark : source_color = vec4(0.075, 0.169, 0.271, 1.0);
uniform vec4 steel_mid : source_color = vec4(0.298, 0.486, 0.639, 1.0);
uniform vec4 steel_spec : source_color = vec4(0.722, 0.922, 1.000, 1.0);
uniform vec4 glow_color : source_color = vec4(0.102, 0.776, 1.000, 0.85);
uniform float hex_inradius : hint_range(0.28, 0.44) = 0.390;
uniform float corner_radius : hint_range(0.0, 0.08) = 0.032;
uniform float border_width : hint_range(0.03, 0.14) = 0.066;
uniform float glow_extent : hint_range(0.01, 0.10) = 0.052;
uniform float overdrive_pulse : hint_range(0.0, 1.0) = 0.0;

float sd_hex_pointy(vec2 p, float r, float cr) {
	const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
	vec2 q = abs(p.yx);
	float rc = r - cr;
	q -= 2.0 * min(dot(k.xy, q), 0.0) * k.xy;
	q -= vec2(clamp(q.x, -k.z * rc, k.z * rc), rc);
	return length(q) * sign(q.y) - cr;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = sd_hex_pointy(p, hex_inradius, corner_radius);

	if (d > glow_extent) {
		discard;
	}

	float aa = max(fwidth(d), 0.006);
	float angle = atan(p.y, p.x);

	vec3 od_col = vec3(1.0, 0.32, 0.82);
	float od_wave = 0.5 + 0.5 * sin(TIME * 7.0 + angle * 2.0);
	vec3 active_glow = mix(glow_color.rgb, mix(od_col, class_aura.rgb, od_wave), overdrive_pulse * 0.72);

	// 1. Soft electric cyan outer glow outside hexagonal perimeter
	if (d > aa) {
		float g = pow(clamp(1.0 - d / max(glow_extent, 0.001), 0.0, 1.0), 2.25) * glow_color.a * (1.0 + overdrive_pulse * 0.45);
		COLOR = vec4(active_glow, clamp(g, 0.0, 1.0));
	} else {
		// 2. Deep sci-fi radial backdrop behind transparent 3D portrait render
		float inner_span = max(hex_inradius - border_width, 0.05);
		float radial = clamp((-d - border_width) / inner_span, 0.0, 1.0);
		float aura_mix = pow(clamp(1.0 - abs(UV.y - 0.60) * 1.65, 0.0, 1.0), 1.55) * 0.30;
		vec3 bg = mix(backdrop_edge.rgb, backdrop_core.rgb, pow(radial, 0.72));
		bg = mix(bg, class_aura.rgb, aura_mix * (0.50 + radial * 0.50));

		// Sample 3D avatar render and composite cleanly over backdrop
		vec4 tex = texture(TEXTURE, UV);
		vec3 portrait_rgb = mix(bg, tex.rgb, clamp(tex.a, 0.0, 1.0));

		// Inner lens vignette + subtle cyan rim light inside bezel
		float inner_vig = 1.0 - smoothstep(0.0, 0.14, -d - border_width);
		portrait_rgb = mix(portrait_rgb, backdrop_edge.rgb * 0.55, inner_vig * 0.55);
		portrait_rgb += active_glow * (1.0 - smoothstep(0.0, 0.055, -d - border_width)) * (0.24 + overdrive_pulse * 0.32);

		// 3. Sculpted cyan-steel hexagonal bezel
		float ring_t = smoothstep(-border_width - aa, -border_width + aa, d);
		float ring_pos = clamp((d + border_width) / max(border_width, 0.001), 0.0, 1.0);
		float directional = clamp(cos(angle + 2.35619) * 0.5 + 0.5, 0.0, 1.0);
		float bevel_peak = smoothstep(0.18, 0.48, ring_pos) * (1.0 - smoothstep(0.56, 0.88, ring_pos));

		vec3 ring_col = mix(active_glow * 1.10, steel_dark.rgb, smoothstep(0.04, 0.22, ring_pos));
		ring_col = mix(ring_col, steel_mid.rgb, smoothstep(0.20, 0.45, ring_pos));
		ring_col = mix(ring_col, steel_spec.rgb, bevel_peak * (0.45 + 0.55 * directional));
		ring_col = mix(ring_col, active_glow * 1.25, smoothstep(0.76, 0.98, ring_pos));

		if (overdrive_pulse > 0.01) {
			ring_col = mix(ring_col, mix(od_col, class_aura.rgb, od_wave), overdrive_pulse * 0.48);
		}

		vec3 body_rgb = mix(portrait_rgb, ring_col, ring_t);

		// Smooth outer perimeter blend into glow
		float body_mask = 1.0 - smoothstep(-aa, aa, d);
		float edge_glow = pow(clamp(1.0 - max(d, 0.0) / max(glow_extent, 0.001), 0.0, 1.0), 2.25) * glow_color.a;
		vec3 final_rgb = mix(active_glow, body_rgb, body_mask);
		float final_a = max(body_mask, edge_glow);

		COLOR = vec4(final_rgb, clamp(final_a, 0.0, 1.0));
	}
}
