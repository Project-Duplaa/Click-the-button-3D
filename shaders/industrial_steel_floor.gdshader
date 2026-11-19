shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D micro_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grate_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grate_orm_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

uniform float plate_size : hint_range(2.0, 8.0) = 4.0;
uniform float micro_uv_scale : hint_range(0.1, 2.0) = 0.36;
uniform float normal_strength : hint_range(0.2, 2.0) = 0.48;

uniform vec4 col_steel_dark : source_color = vec4(0.220, 0.255, 0.305, 1.0);
uniform vec4 col_steel_mid : source_color = vec4(0.295, 0.340, 0.400, 1.0);
uniform vec4 col_steel_petroleum : source_color = vec4(0.205, 0.260, 0.325, 1.0);
uniform vec4 col_edge_wear : source_color = vec4(0.450, 0.505, 0.575, 1.0);
uniform vec4 col_stencil_paint : source_color = vec4(0.580, 0.640, 0.715, 1.0);
uniform vec4 cyan_accent : source_color = vec4(0.000, 0.941, 1.000, 1.0);
uniform vec4 amber_hazard : source_color = vec4(1.000, 0.718, 0.012, 1.0);

varying vec3 v_world_pos;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = rot * p * 2.03 + vec2(17.1, 31.7);
		a *= 0.5;
	}
	return v;
}

float sd_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

float stencil_A(vec2 q) {
	float d = sd_seg(q, vec2(-0.34, 0.45), vec2(0.0, -0.45));
	d = min(d, sd_seg(q, vec2(0.34, 0.45), vec2(0.0, -0.45)));
	d = min(d, sd_seg(q, vec2(-0.20, 0.14), vec2(0.20, 0.14)));
	return d;
}

float stencil_dash(vec2 q) {
	return sd_seg(q, vec2(-0.22, 0.0), vec2(0.22, 0.0));
}

float stencil_0(vec2 q) {
	float d = sd_seg(q, vec2(-0.26, -0.42), vec2(0.26, -0.42));
	d = min(d, sd_seg(q, vec2(0.26, -0.42), vec2(0.26, 0.42)));
	d = min(d, sd_seg(q, vec2(0.26, 0.42), vec2(-0.26, 0.42)));
	d = min(d, sd_seg(q, vec2(-0.26, 0.42), vec2(-0.26, -0.42)));
	return d;
}

float stencil_1(vec2 q) {
	float d = sd_seg(q, vec2(0.04, -0.45), vec2(0.04, 0.45));
	d = min(d, sd_seg(q, vec2(-0.18, -0.26), vec2(0.04, -0.45)));
	d = min(d, sd_seg(q, vec2(-0.22, 0.45), vec2(0.24, 0.45)));
	return d;
}

float stencil_label_A01(vec2 pos, vec2 origin, float char_scale) {
	// En mundo Godot con cámara en +Z mirando a -Z: +X = derecha, +Z = abajo
	vec2 q = (pos - origin) / char_scale;
	float d = 10.0;
	d = min(d, stencil_A(q - vec2(-1.40, 0.0)));
	d = min(d, stencil_dash(q - vec2(-0.50, 0.0)));
	d = min(d, stencil_0(q - vec2(0.42, 0.0)));
	d = min(d, stencil_1(q - vec2(1.28, 0.0)));
	float alpha_txt = 1.0 - smoothstep(0.095, 0.145, d);

	vec2 b = q - vec2(-0.05, 0.90);
	float in_band = step(abs(b.x), 1.65) * step(abs(b.y), 0.21);
	float diag = fract((b.x - b.y * 0.85) * 1.45);
	float stripe = step(0.45, diag) * in_band;
	return clamp(max(alpha_txt, stripe * 0.88), 0.0, 1.0);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = vec3(0.0, 1.0, 0.0);
	TANGENT = vec3(1.0, 0.0, 0.0);
	BINORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 p = v_world_pos.xz;

	// Macro grid asimétrico en espacio mundo
	vec2 mc = floor(p / plate_size);
	vec2 f = fract(p / plate_size);
	float h0 = hash21(mc);

	vec2 sub_uv = f;
	vec2 sub_id = mc * 10.0;
	vec2 sub_dims = vec2(1.0, 1.0);

	if (h0 < 0.28) {
		sub_uv = f;
		sub_id = mc * 10.0;
		sub_dims = vec2(1.0, 1.0);
	} else if (h0 < 0.56) {
		sub_uv = vec2(fract(f.x * 2.0), f.y);
		sub_id = mc * 10.0 + vec2(floor(f.x * 2.0), 0.0);
		sub_dims = vec2(0.5, 1.0);
	} else if (h0 < 0.84) {
		sub_uv = vec2(f.x, fract(f.y * 2.0));
		sub_id = mc * 10.0 + vec2(0.0, floor(f.y * 2.0));
		sub_dims = vec2(1.0, 0.5);
	} else {
		sub_uv = fract(f * 2.0);
		sub_id = mc * 10.0 + floor(f * 2.0);
		sub_dims = vec2(0.5, 0.5);
	}

	vec2 plate_m = plate_size * sub_dims;
	vec2 local_m = sub_uv * plate_m;
	vec2 edge_m = min(local_m, plate_m - local_m);
	float d_seam = min(edge_m.x, edge_m.y);

	float h_plate = hash21(sub_id + vec2(3.7, 9.1));
	float h_oil = fbm(p * 0.22 + vec2(4.2, -7.8));
	float h_grime = fbm(p * 0.65 + vec2(-11.3, 5.4));
	float h_fine = vnoise(p * 3.8 + sub_id);

	vec3 base_metal = mix(col_steel_dark.rgb, col_steel_mid.rgb, smoothstep(0.15, 0.85, h_plate));
	base_metal = mix(base_metal, col_steel_petroleum.rgb, smoothstep(0.55, 0.95, hash21(sub_id + vec2(19.4, 2.3))) * 0.55);

	vec2 micro_uv = (h_plate > 0.5 ? p.xy : p.yx) * micro_uv_scale + vec2(h_plate * 0.37, h_plate * 0.61);
	vec3 n_micro_tex = texture(micro_normal_tex, micro_uv).xyz * 2.0 - 1.0;
	vec2 n_xy = n_micro_tex.xy * (0.42 * normal_strength);

	// Junta biselada (~3.5 cm) + borde biselado más claro (~6 cm)
	float seam_groove = 1.0 - smoothstep(0.012, 0.024, d_seam);
	float bevel_t = smoothstep(0.018, 0.068, d_seam);
	float bevel_slope = (1.0 - bevel_t) * (1.0 - seam_groove);
	vec2 seam_dir = vec2(0.0);
	if (edge_m.x < edge_m.y) {
		seam_dir = vec2(local_m.x < plate_m.x * 0.5 ? 1.0 : -1.0, 0.0);
	} else {
		seam_dir = vec2(0.0, local_m.y < plate_m.y * 0.5 ? 1.0 : -1.0);
	}
	n_xy -= seam_dir * (bevel_slope * 0.72 * normal_strength);

	float edge_bevel = smoothstep(0.085, 0.025, d_seam) * smoothstep(0.012, 0.028, d_seam);

	// 4 remaches metálicos en esquinas
	vec2 corner_vec = edge_m - vec2(0.14, 0.14);
	float d_bolt = length(corner_vec);
	float bolt_head = 1.0 - smoothstep(0.032, 0.044, d_bolt);
	float bolt_ring = smoothstep(0.028, 0.042, d_bolt) * (1.0 - smoothstep(0.042, 0.060, d_bolt));
	if (d_bolt < 0.07) {
		vec2 bdir = corner_vec / max(d_bolt, 0.0001);
		n_xy -= bdir * (bolt_ring * 0.58 * normal_strength);
	}

	float ao = 1.0 - seam_groove * 0.78 - bolt_ring * 0.35 - (1.0 - h_grime) * 0.12;
	float oil_patch = smoothstep(0.46, 0.68, h_oil);
	float rough = mix(0.68, 0.22, oil_patch);
	rough = mix(rough, 0.42, h_fine * 0.25);
	rough = mix(rough, 0.32, edge_bevel * 0.75);
	rough = mix(rough, 0.30, bolt_head * 0.80);
	rough = mix(rough, 0.90, seam_groove);

	// Metalizado moderado (0.28..0.42) para conservar luz difusa clara en gl_compatibility
	float metal = mix(0.28, 0.42, oil_patch * 0.6 + h_plate * 0.25);
	metal = mix(metal, 0.48, max(edge_bevel, bolt_head) * 0.65);
	metal = mix(metal, 0.12, seam_groove);

	vec3 albedo = base_metal;
	albedo *= mix(0.84, 1.14, h_grime * 0.65 + h_fine * 0.35);
	albedo = mix(albedo, col_edge_wear.rgb, edge_bevel * 0.62);
	albedo = mix(albedo, col_edge_wear.rgb * 1.15, bolt_head * 0.85);
	albedo = mix(albedo, vec3(0.022, 0.026, 0.034), seam_groove);
	albedo *= mix(1.0, 0.82, oil_patch);

	// 2 rejillas cuadradas empotradas discretas en primer plano
	float d_grate1 = sd_box(p - vec2(-7.8, 6.4), vec2(0.95, 0.95));
	float d_grate2 = sd_box(p - vec2(7.8, 6.6), vec2(0.85, 0.85));
	float d_grate = min(d_grate1, d_grate2);
	if (d_grate < 0.13) {
		if (d_grate > 0.0) {
			if (d_grate2 < 0.14 && p.x > 8.50) {
				float stripe_pat = step(0.5, fract((p.x + p.y) * 2.6));
				albedo = mix(vec3(0.05, 0.06, 0.07), amber_hazard.rgb * 0.88, stripe_pat);
				rough = 0.48;
				metal = 0.25;
			} else {
				albedo = col_steel_dark.rgb * 0.72;
				rough = 0.45;
				metal = 0.38;
			}
		} else {
			vec2 g_uv = p * 1.35;
			vec3 gn = texture(grate_normal_tex, g_uv).xyz * 2.0 - 1.0;
			vec3 gorm = texture(grate_orm_tex, g_uv).rgb;
			n_xy = mix(n_xy, gn.xy * 0.90, 0.90);
			ao *= gorm.r;
			rough = mix(0.85, 0.30, gorm.b);
			metal = clamp(gorm.b * 0.50, 0.12, 0.44);
			albedo = mix(vec3(0.02, 0.025, 0.032), vec3(0.28, 0.33, 0.40), gorm.b);
		}
	}

	// Esténcil "A-01" + ///// en zona visible inferior derecha junto al jugador
	float stencil_mask = stencil_label_A01(p, vec2(9.6, 3.3), 0.58);
	if (stencil_mask > 0.01) {
		float scuff = smoothstep(0.18, 0.45, h_grime) * (1.0 - seam_groove);
		float s_amt = stencil_mask * scuff;
		albedo = mix(albedo, col_stencil_paint.rgb, s_amt * 0.86);
		rough = mix(rough, 0.62, s_amt * 0.75);
		metal = mix(metal, 0.16, s_amt * 0.75);
	}

	// 2 barras LED cian cortas empotradas con marco oscuro biselado
	float d_led1 = sd_box(p - vec2(-7.2, 4.4), vec2(0.90, 0.05));
	float d_led2 = sd_box(p - vec2(8.8, -0.4), vec2(0.90, 0.05));
	float d_led = min(d_led1, d_led2);
	float fresnel = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 2.2);
	vec3 emission = albedo * 0.14 + fresnel * (1.0 - rough) * vec3(0.025, 0.055, 0.085) * 0.25;

	if (d_led < 0.045) {
		if (d_led > 0.0) {
			albedo = vec3(0.04, 0.05, 0.065);
			rough = 0.72;
			metal = 0.35;
			ao = 0.35;
		} else {
			float soft_core = smoothstep(0.0, -0.028, d_led);
			albedo = mix(vec3(0.06, 0.25, 0.32), cyan_accent.rgb, soft_core);
			emission = cyan_accent.rgb * (0.9 + 1.4 * soft_core);
			rough = 0.18;
			metal = 0.10;
		}
	}

	ALBEDO = albedo;
	METALLIC = clamp(metal * 0.65, 0.0, 0.34);
	ROUGHNESS = clamp(max(rough, 0.36), 0.36, 0.90);
	SPECULAR = 0.48;
	AO = clamp(ao, 0.10, 1.0);
	NORMAL_MAP = vec3(clamp(0.5 + n_xy.x * 0.5, 0.0, 1.0), clamp(0.5 + n_xy.y * 0.5, 0.0, 1.0), 1.0);
	NORMAL_MAP_DEPTH = 0.52;
	EMISSION = emission;
}
