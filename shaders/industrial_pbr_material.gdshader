shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D detail_normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_orm_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

// 0=BrushedSteel, 1=PaintedMetal, 2=IndustrialAluminum, 3=TechPolymer, 4=ArmoredCeramic, 5=GrateDeck
uniform int material_family = 0;
uniform vec4 base_color : source_color = vec4(0.18, 0.21, 0.26, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.32, 0.36, 0.42, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.718, 0.012, 1.0);

uniform float triplanar_scale : hint_range(0.1, 8.0) = 0.85;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.40;
uniform float edge_wear_amount : hint_range(0.0, 1.0) = 0.35;
uniform float bottom_grime_amount : hint_range(0.0, 1.0) = 0.35;
uniform float emission_energy : hint_range(0.0, 5.0) = 0.0;
uniform bool enable_hazard_band = false;

varying vec3 v_world_pos;
varying vec3 v_world_norm;

vec4 sample_triplanar(sampler2D tex, vec3 wp, vec3 wn, float sc) {
	vec3 bw = abs(wn);
	bw = pow(bw, vec3(4.0));
	bw /= max(bw.x + bw.y + bw.z, 0.0001);
	vec4 cx = texture(tex, wp.zy * sc);
	vec4 cy = texture(tex, wp.xz * sc);
	vec4 cz = texture(tex, wp.xy * sc);
	return cx * bw.x + cy * bw.y + cz * bw.z;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 orm = sample_triplanar(detail_orm_tex, v_world_pos, v_world_norm, triplanar_scale);
	vec3 dn = sample_triplanar(detail_normal_tex, v_world_pos, v_world_norm, triplanar_scale).xyz;

	float ao = mix(0.72, 1.0, orm.r);
	float rough = clamp(orm.g, 0.28, 0.88);
	float metal = 0.30;
	vec3 albedo = base_color.rgb;

	// Suave desgaste sin derivadas dFdx/dFdy (evita fireflies en gl_compatibility)
	float fresnel = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 2.5);
	float wear_mask = smoothstep(0.42, 0.85, orm.g) * edge_wear_amount * 0.45 + fresnel * edge_wear_amount * 0.25;
	float grime = (1.0 - smoothstep(0.05, 0.65, v_world_pos.y)) * bottom_grime_amount;

	if (material_family == 0) {
		// Acero cepillado
		albedo = mix(base_color.rgb, secondary_color.rgb, orm.r * 0.42);
		metal = mix(0.32, 0.44, orm.b);
		rough = mix(0.32, 0.52, orm.g);
	} else if (material_family == 1) {
		// Metal pintado desgastado
		albedo = mix(base_color.rgb, secondary_color.rgb, wear_mask);
		metal = mix(0.20, 0.42, wear_mask);
		rough = mix(0.42, 0.58, orm.g);
	} else if (material_family == 2) {
		// Aluminio industrial satinado
		albedo = mix(base_color.rgb, secondary_color.rgb, 0.30 + orm.r * 0.25);
		metal = 0.44;
		rough = mix(0.28, 0.44, orm.g);
	} else if (material_family == 3) {
		// Polímero técnico / caucho reforzado
		albedo = base_color.rgb * mix(0.88, 1.06, orm.r);
		metal = 0.05;
		rough = mix(0.60, 0.84, orm.g);
	} else if (material_family == 4) {
		// Cerámica / hormigón blindado
		albedo = mix(base_color.rgb, secondary_color.rgb, orm.r * 0.35 + wear_mask * 0.4);
		metal = mix(0.10, 0.24, wear_mask);
		rough = mix(0.68, 0.88, orm.g);
	} else {
		// Rejilla / plataforma industrial
		albedo = mix(vec3(0.04, 0.045, 0.055), base_color.rgb, orm.b);
		metal = clamp(orm.b * 0.55, 0.12, 0.45);
		rough = clamp(orm.g, 0.30, 0.86);
	}

	if (enable_hazard_band && v_world_pos.y > 0.14 && v_world_pos.y < 0.34) {
		float stripe = step(0.5, fract((v_world_pos.x + v_world_pos.z) * 2.8));
		vec3 haz = mix(vec3(0.06, 0.07, 0.08), accent_color.rgb, stripe);
		albedo = mix(haz, secondary_color.rgb, wear_mask * 0.4);
		rough = 0.48;
	}

	albedo = mix(albedo, vec3(0.05, 0.06, 0.07), grime * 0.55);
	rough = mix(rough, 0.86, grime * 0.55);

	ALBEDO = albedo;
	METALLIC = clamp(metal, 0.0, 0.55);
	ROUGHNESS = clamp(rough, 0.24, 0.92);
	SPECULAR = 0.75;
	AO = clamp(ao * (1.0 - grime * 0.30), 0.20, 1.0);
	NORMAL_MAP = dn;
	NORMAL_MAP_DEPTH = normal_depth;
	EMISSION = accent_color.rgb * emission_energy;
}
