shader_type canvas_item;

uniform vec2 view_size = vec2(1280.0, 720.0);
uniform vec2 pan_offset = vec2(0.0, 0.0);
uniform float zoom = 0.75;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float star_layer(vec2 uv_coord, float scale, float density, float t_speed, float time_val) {
	vec2 gv = fract(uv_coord * scale) - 0.5;
	vec2 id = floor(uv_coord * scale);
	float rnd = hash21(id);
	if (rnd < density) {
		return 0.0;
	}
	vec2 offset = vec2(hash21(id + 17.3) - 0.5, hash21(id + 41.9) - 0.5) * 0.65;
	float d = length(gv - offset);
	float size_factor = mix(0.025, 0.075, hash21(id + 93.7));
	float core = smoothstep(size_factor, 0.0, d);
	float twinkle = 0.62 + 0.38 * sin(time_val * t_speed + rnd * 42.0);
	return core * twinkle;
}

void fragment() {
	vec2 vs = max(view_size, vec2(64.0));
	float z = max(zoom, 0.1);
	vec2 wp = (UV * vs - vs * 0.5 - pan_offset) / z;

	// Base abyss vertical gradient (#04070D -> #07101D)
	vec3 col_top = vec3(0.016, 0.027, 0.051);
	vec3 col_bot = vec3(0.027, 0.063, 0.114);
	float grad_t = clamp(UV.y * 0.85 + 0.10, 0.0, 1.0);
	vec3 col = mix(col_top, col_bot, grad_t);

	// World-anchored radial sector nebulae
	// Core (0, 0): Emerald-Cyan
	float d_core = length(wp - vec2(0.0, 0.0));
	col += vec3(0.03, 0.28, 0.20) * exp(-d_core / 340.0) * 0.36;

	// NW (-460, -260): Cherenkov Cyan (azul)
	float d_nw = length(wp - vec2(-460.0, -260.0));
	col += vec3(0.03, 0.26, 0.42) * exp(-d_nw / 420.0) * 0.34;

	// W (-620, 90): Thermal Copper (boton)
	float d_w = length(wp - vec2(-620.0, 90.0));
	col += vec3(0.36, 0.15, 0.04) * exp(-d_w / 380.0) * 0.28;

	// S (0, 520): Bio-Uranium Green (verde)
	float d_s = length(wp - vec2(0.0, 520.0));
	col += vec3(0.04, 0.29, 0.14) * exp(-d_s / 450.0) * 0.32;

	// NE (460, -260): Isotope Amber (dorada)
	float d_ne = length(wp - vec2(460.0, -260.0));
	col += vec3(0.38, 0.24, 0.04) * exp(-d_ne / 420.0) * 0.32;

	// N (0, -1260): Astral Nebula Violet (cosmico)
	float d_n = length(wp - vec2(0.0, -1260.0));
	col += vec3(0.24, 0.10, 0.42) * exp(-d_n / 460.0) * 0.42;

	// Subtle nebula filament modulation
	float neb_wave = 0.85 + 0.15 * sin(wp.x * 0.0045 + wp.y * 0.0032 + TIME * 0.12);
	col *= neb_wave;

	// 2-layer parallax twinkling starfield
	vec2 star_uv1 = (UV * vs - pan_offset * 0.18) / 1400.0;
	vec2 star_uv2 = (UV * vs - pan_offset * 0.36) / 950.0;
	float s1 = star_layer(star_uv1, 18.0, 0.86, 1.4, TIME);
	float s2 = star_layer(star_uv2, 26.0, 0.90, 2.3, TIME);
	col += vec3(0.65, 0.82, 0.98) * s1 * 0.45;
	col += vec3(0.92, 0.88, 1.00) * s2 * 0.55;

	// Outer screen-space vignette for >7:1 HUD chrome contrast
	vec2 v_uv = UV - 0.5;
	float vig = dot(v_uv, v_uv);
	float vig_mask = smoothstep(0.16, 0.68, vig);
	col = mix(col, vec3(0.010, 0.016, 0.028), vig_mask * 0.72);

	COLOR = vec4(col, 1.0);
}
