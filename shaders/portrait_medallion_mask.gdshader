shader_type canvas_item;

uniform vec4 backdrop_core : source_color = vec4(0.11, 0.13, 0.21, 1.0);
uniform vec4 backdrop_edge : source_color = vec4(0.03, 0.04, 0.07, 1.0);
uniform vec4 class_aura : source_color = vec4(0.88, 0.74, 0.38, 1.0);
uniform vec4 bronze_dark : source_color = vec4(0.32, 0.22, 0.09, 1.0);
uniform vec4 bronze_mid : source_color = vec4(0.79, 0.64, 0.35, 1.0);
uniform vec4 bronze_spec : source_color = vec4(1.0, 0.90, 0.64, 1.0);
uniform float border_width : hint_range(0.03, 0.18) = 0.085;
uniform float overdrive_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;

	if (d > 1.0) {
		discard;
	}

	float aa = max(fwidth(d), 0.012);
	float outer_alpha = 1.0 - smoothstep(1.0 - aa, 1.0, d);

	// 1. Sculpted dark backdrop behind transparent SubViewport pixels
	float radial = clamp(1.0 - d / (1.0 - border_width), 0.0, 1.0);
	float aura_mix = pow(clamp(1.0 - abs(UV.y - 0.58) * 1.6, 0.0, 1.0), 1.6) * 0.26;
	vec3 bg = mix(backdrop_edge.rgb, backdrop_core.rgb, radial);
	bg = mix(bg, class_aura.rgb, aura_mix * (0.55 + radial * 0.45));

	// 2. Sample 3D portrait render and composite over backdrop
	vec4 tex = texture(TEXTURE, UV);
	vec3 portrait_rgb = mix(bg, tex.rgb, clamp(tex.a, 0.0, 1.0));

	// Subtle inner rim vignette inside medallion lens
	float inner_r = 1.0 - border_width;
	float vig = smoothstep(inner_r - 0.24, inner_r, d);
	portrait_rgb = mix(portrait_rgb, backdrop_edge.rgb * 0.55, vig * 0.62);
	portrait_rgb += class_aura.rgb * smoothstep(inner_r - 0.10, inner_r, d) * (0.18 + overdrive_pulse * 0.35);

	// 3. Carved metallic bezel ring (inner shadow -> mid bronze -> specular top-left bevel -> outer rim)
	float ring_t = smoothstep(inner_r - aa, inner_r + aa, d);
	float ring_pos = clamp((d - inner_r) / max(border_width, 0.001), 0.0, 1.0);

	float angle = atan(p.y, p.x);
	float directional = clamp(cos(angle + 2.35619) * 0.5 + 0.5, 0.0, 1.0);
	float bevel_peak = smoothstep(0.15, 0.42, ring_pos) * (1.0 - smoothstep(0.55, 0.92, ring_pos));

	vec3 ring_col = mix(bronze_dark.rgb, bronze_mid.rgb, smoothstep(0.0, 0.35, ring_pos));
	ring_col = mix(ring_col, bronze_spec.rgb, bevel_peak * (0.40 + 0.60 * directional));
	// Inner engraved shadow & outer dark containment hairline
	ring_col *= mix(0.55, 1.0, smoothstep(0.0, 0.16, ring_pos));
	ring_col = mix(ring_col, vec3(0.03, 0.03, 0.05), smoothstep(0.84, 1.0, ring_pos));

	// Overdrive pulsing tint along bezel
	if (overdrive_pulse > 0.01) {
		float wave = 0.5 + 0.5 * sin(TIME * 7.0 + angle * 2.0);
		ring_col = mix(ring_col, mix(vec3(1.0, 0.35, 0.85), class_aura.rgb, wave), overdrive_pulse * 0.45);
	}

	vec3 final_rgb = mix(portrait_rgb, ring_col, ring_t);
	COLOR = vec4(final_rgb, outer_alpha);
}
