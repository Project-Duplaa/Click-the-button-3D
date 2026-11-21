shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

// Shader aditivo Fresnel + flujo rúnico sutil para armaduras ascendidas (Tier 2 / Tier 3).
// Diseñado como next_pass sobre StandardMaterial3D clonados para preservar 100% las texturas
// horneadas del modelo .glb con costo mínimo en gl_compatibility.

uniform vec4 rim_color : source_color = vec4(1.0, 0.88, 0.45, 1.0);
uniform vec4 energy_color : source_color = vec4(1.0, 0.68, 0.16, 1.0);
uniform float rim_power : hint_range(0.8, 6.0) = 2.6;
uniform float rim_intensity : hint_range(0.0, 3.0) = 0.88;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.4;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.26;
uniform float rune_flow_speed : hint_range(-5.0, 5.0) = 1.25;
uniform float rune_intensity : hint_range(0.0, 1.5) = 0.30;

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float ndotv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, rim_power);

	// Pulso energético suave controlado por TIME
	float pulse = (1.0 - pulse_amount * 0.5) + (pulse_amount * 0.5) * sin(TIME * pulse_speed);

	// Venas de energía ascendentes a lo largo de la armadura sin depender de UVs
	float wave = sin(v_local_pos.y * 34.0 - TIME * rune_flow_speed * 3.0 + sin(v_local_pos.x * 18.0 + v_local_pos.z * 14.0) * 1.25);
	float rune_glint = smoothstep(0.74, 0.98, wave) * rune_intensity;

	vec3 col = mix(energy_color.rgb, rim_color.rgb, clamp(fresnel * 1.25, 0.0, 1.0));
	float strength = (fresnel * rim_intensity + rune_glint * (0.28 + 0.72 * fresnel)) * pulse;

	ALBEDO = col * strength;
	ALPHA = clamp(strength, 0.0, 0.90);
}
