extends "res://santuario_base.gd"
class_name PactoMarte

## PactoMarte - Santuario maldito de riesgo/recompensa (60 s).
## Gratis: invoca 3 enemigos élite en la arena e inicia una cuenta atrás visible de 60 s.
## Al sobrevivir sin muerte definitiva: +0.30 Suerte, 1 Reliquia aleatoria y 1 Mejora Épica+.

const DURACION_PACTO: float = 60.0

const STATS_PACTO := [
	{"id": "dano", "titulo": "⚔️ Filo Mortal"},
	{"id": "cadencia", "titulo": "⚡ Furia Veloz"},
	{"id": "vida", "titulo": "🛡️ Vitalidad"},
	{"id": "velocidad", "titulo": "👟 Agilidad"},
	{"id": "critico", "titulo": "🎯 Precisión Letal"},
	{"id": "fortuna", "titulo": "🍀 Fortuna del Coliseo"},
]

var _pacto_activo: bool = false
var _tiempo_restante: float = DURACION_PACTO
var _espada_flotante: MeshInstance3D = null
var _rotor_alerta: MeshInstance3D = null
var _badge_layer: CanvasLayer = null
var _badge_label: Label = null

func _configurar_santuario() -> void:
	nombre_santuario = "Pacto de Marte"
	costo_denarios = 0
	radio_interaccion = 5.5
	un_solo_uso = false
	activacion_por_clic = true
	color_luz = BunkerVisualKit.COL_CRIMSON_ALERT
	altura_etiqueta = 3.55

func _construir_visual() -> void:
	# Anillo de contención roja en el suelo
	var ring := BunkerVisualKit.create_hazard_ground_ring(
		1.55,
		BunkerVisualKit.COL_CRIMSON_ALERT,
		Color(1.0, 0.45, 0.45),
		0.78,
		0.95,
		0.48
	)
	var ring_mat := ring.material_override as ShaderMaterial
	if ring_mat != null:
		ring_mat.set_shader_parameter("progress", 1.0)
		ring_mat.set_shader_parameter("active_state", 1.0)
	visual_root.add_child(ring)

	# Base octogonal blindada de acero carbono
	BunkerVisualKit.make_cylinder(
		visual_root,
		"BaseOctogonalBlindada",
		1.02,
		1.24,
		0.34,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.17, 0.0),
		8
	)

	# Zócalo hazard rojo/negro
	var mat_hazard_rojo := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_CRIMSON_ALERT,
		BunkerVisualKit.COL_CARBON_STEEL,
		12.0
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"ZocaloHazardRojo",
		0.88,
		0.98,
		0.18,
		mat_hazard_rojo,
		Vector3(0.0, 0.43, 0.0),
		8
	)

	# Blindaje carmesí mate para la torreta emisora central
	var mat_blindaje_carmesi := StandardMaterial3D.new()
	mat_blindaje_carmesi.albedo_color = Color(0.48, 0.08, 0.12)
	mat_blindaje_carmesi.metallic = 0.72
	mat_blindaje_carmesi.roughness = 0.36

	BunkerVisualKit.make_cylinder(
		visual_root,
		"TorretaEmisoraBase",
		0.44,
		0.56,
		1.42,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 1.22, 0.0),
		8
	)
	BunkerVisualKit.make_box(
		visual_root,
		"BlindajeCarmesiCentral",
		Vector3(0.66, 1.05, 0.66),
		mat_blindaje_carmesi,
		Vector3(0.0, 1.24, 0.0)
	)

	# 4 postes inclinados formando una jaula Faraday táctica alrededor de la torreta
	for i in range(4):
		var ang_rad: float = (TAU * 0.25) * float(i) + PI * 0.25
		var dir := Vector3(cos(ang_rad), 0.0, sin(ang_rad))
		var poste := BunkerVisualKit.make_box(
			visual_root,
			"PosteFaraday_%d" % i,
			Vector3(0.11, 1.62, 0.14),
			BunkerVisualKit.get_titanium_mat(),
			dir * 0.68 + Vector3(0.0, 1.25, 0.0)
		)
		poste.look_at_from_position(
			dir * 0.68 + Vector3(0.0, 1.25, 0.0),
			Vector3(0.0, 2.08, 0.0),
			Vector3.UP
		)

	# Anillo emisor intermedio
	BunkerVisualKit.make_torus(
		visual_root,
		"AnilloContencionRojo",
		0.58,
		0.68,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_CRIMSON_ALERT, 2.2),
		Vector3(0.0, 1.48, 0.0)
	)

	# Rotor estroboscópico giratorio en la cúspide
	_rotor_alerta = BunkerVisualKit.make_cylinder(
		visual_root,
		"RotorEstroboscopico",
		0.32,
		0.38,
		0.20,
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 2.04, 0.0),
		8
	)
	BunkerVisualKit.make_box(
		_rotor_alerta,
		"BarraEstroboscopica",
		Vector3(0.76, 0.10, 0.16),
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_CRIMSON_ALERT, 2.8),
		Vector3.ZERO
	)

	# Emisor de lanza láser / prisma de sobrecarga invertido (_espada_flotante) + haz corto vertical
	_espada_flotante = MeshInstance3D.new()
	_espada_flotante.name = "PrismaSobrecargaInvertido"
	var m_punta := PrismMesh.new()
	m_punta.size = Vector3(0.54, 0.92, 0.54)
	_espada_flotante.mesh = m_punta
	_espada_flotante.material_override = BunkerVisualKit.create_hologram_material(
		BunkerVisualKit.COL_CRIMSON_ALERT,
		Color(1.0, 0.65, 0.65),
		2.8
	)
	_espada_flotante.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	_espada_flotante.position = Vector3(0.0, 2.72, 0.0)
	visual_root.add_child(_espada_flotante)

	var haz := BunkerVisualKit.make_cylinder(
		_espada_flotante,
		"HazLaserVertical",
		0.14,
		0.22,
		0.95,
		BunkerVisualKit.create_beam_material(
			BunkerVisualKit.COL_CRIMSON_ALERT,
			Color(1.0, 0.78, 0.78),
			2.6,
			0.68
		),
		Vector3(0.0, 0.15, 0.0),
		16,
		false,
		false
	)
	haz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_actualizar_etiqueta("Invoca 3 Élites · Sobrevive 60s")

func _activar(_pj: Node3D) -> bool:
	if _pacto_activo:
		return false

	_pacto_activo = true
	_consumido = true
	_tiempo_restante = DURACION_PACTO

	# Ocultar geometría y desactivar colisión de forma diferida sin destruir el nodo hasta terminar los 60s
	remove_from_group("santuarios")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("input_ray_pickable", false)
	if colision != null:
		colision.set_deferred("disabled", true)
	if visual_root != null:
		visual_root.visible = false
	if etiqueta != null:
		etiqueta.visible = false
	if luz != null:
		luz.visible = false
	BunkerVisualKit.spawn_shockwave_ring(
		get_parent(),
		global_position,
		1.0,
		5.5,
		BunkerVisualKit.COL_CRIMSON_ALERT,
		0.55
	)
	activado.emit(self)

	var spawner := _buscar_spawner()
	if spawner != null and spawner.has_method("invocar_elites"):
		spawner.invocar_elites(3)

	AudioManager.play("jefe_alerta", 1.05)
	_spawn_texto_3d("⚔️ ¡PACTO DE MARTE ACEPTADO!", Color(1.0, 0.22, 0.28))
	_crear_badge_pacto()
	return false

func _process(delta: float) -> void:
	if not _pacto_activo:
		if not _consumido:
			if _espada_flotante != null:
				_espada_flotante.rotate_y(delta * 1.8)
				_espada_flotante.position.y = 2.72 + sin(Time.get_ticks_msec() * 0.005) * 0.09
			if _rotor_alerta != null:
				_rotor_alerta.rotate_y(-delta * 4.2)
		return

	var pj := _obtener_jugador()
	if pj == null or ("_muerto_definitivo" in pj and pj._muerto_definitivo):
		_finalizar_sin_recompensa()
		return

	_tiempo_restante = maxf(0.0, _tiempo_restante - delta)
	var hud: Node = get_tree().get_first_node_in_group("hud") if get_tree() != null else null
	if hud != null and hud.has_method("actualizar_pacto_marte"):
		hud.actualizar_pacto_marte(_tiempo_restante)
	elif _badge_label != null:
		_badge_label.text = "PACTO DE MARTE: %ds" % ceili(_tiempo_restante)

	if _tiempo_restante <= 0.0:
		_completar_pacto(pj)

func _completar_pacto(pj: Node3D) -> void:
	_pacto_activo = false
	if pj != null and is_instance_valid(pj) and not ("_muerto_definitivo" in pj and pj._muerto_definitivo):
		if pj.has_method("sumar_suerte"):
			pj.sumar_suerte(0.30)

		var ids := ReliquiaDatos.obtener_todos_los_ids()
		var nombre_rel := ""
		if not ids.is_empty() and pj.has_method("agregar_reliquia"):
			var id_rel: String = String(ids[FortunaManager.rng.randi_range(0, ids.size() - 1)])
			pj.agregar_reliquia(id_rel, 1)
			nombre_rel = ReliquiaDatos.obtener_nombre(id_rel)

		var r: int = FortunaManager.tirar_rareza(Rareza.EPICO)
		var mult: float = FortunaManager.obtener_multiplicador_rareza(r)
		var stat: Dictionary = STATS_PACTO[FortunaManager.rng.randi_range(0, STATS_PACTO.size() - 1)]
		if pj.has_method("aplicar_mejora"):
			pj.aplicar_mejora(String(stat["id"]), mult)

		AudioManager.play("legendario", 1.05)
		AudioManager.play("jackpot", 1.0)
		_spawn_texto_en(pj.global_position + Vector3(0.0, 2.7, 0.0), "⚔️ ¡PACTO CUMPLIDO! +30%% Suerte", Color(1.0, 0.85, 0.25))
		if nombre_rel != "":
			_spawn_texto_en(pj.global_position + Vector3(0.0, 3.4, 0.0), "🏛️ %s + %s" % [nombre_rel, Rareza.obtener_nombre(r)], Color(0.82, 0.42, 1.0))

	_limpiar_badge()
	queue_free()

func _finalizar_sin_recompensa() -> void:
	_pacto_activo = false
	_limpiar_badge()
	queue_free()

func _buscar_spawner() -> Node:
	if get_tree() == null:
		return null
	var por_grupo := get_tree().get_first_node_in_group("spawner")
	if por_grupo != null:
		return por_grupo
	if get_parent() != null:
		for hijo in get_parent().get_children():
			if hijo.has_method("invocar_elites"):
				return hijo
	return null

func _crear_badge_pacto() -> void:
	_limpiar_badge()
	if get_tree() == null:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("registrar_pacto_marte"):
		hud.registrar_pacto_marte(DURACION_PACTO)
		return

	_badge_layer = CanvasLayer.new()
	_badge_layer.layer = 18
	get_tree().root.add_child(_badge_layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(24.0, 134.0)
	panel.add_theme_stylebox_override("panel", _crear_panel_style(Color(0.95, 0.22, 0.28), Color(0.14, 0.03, 0.05, 0.90), 2, 8))
	_badge_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	_badge_label = Label.new()
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label.text = "PACTO DE MARTE: 60s"
	_badge_label.add_theme_font_size_override("font_size", 14)
	_badge_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	margin.add_child(_badge_label)

func _spawn_texto_en(pos: Vector3, txt: String, color: Color) -> void:
	if get_parent() == null:
		return
	var dn := ESCENA_TEXTO_3D.instantiate()
	get_parent().add_child(dn)
	dn.global_position = pos
	if dn.has_method("iniciar"):
		dn.iniciar(0.0, true, false, txt)
	var lbl := dn.get_node_or_null("Label3D") as Label3D
	if lbl != null:
		lbl.modulate = color
		lbl.font_size = 46

func _limpiar_badge() -> void:
	if is_inside_tree() and get_tree() != null:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("ocultar_pacto_marte"):
			hud.ocultar_pacto_marte()
	if _badge_layer != null and is_instance_valid(_badge_layer):
		_badge_layer.queue_free()
	_badge_layer = null
	_badge_label = null

func _exit_tree() -> void:
	_limpiar_badge()
