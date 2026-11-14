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
var _badge_layer: CanvasLayer = null
var _badge_label: Label = null

func _configurar_santuario() -> void:
	nombre_santuario = "Pacto de Marte"
	costo_denarios = 0
	radio_interaccion = 5.5
	un_solo_uso = false
	activacion_por_clic = true
	color_luz = Color(1.0, 0.16, 0.22)
	altura_etiqueta = 3.45

func _construir_visual() -> void:
	var mat_basalto := _crear_material(Color(0.14, 0.10, 0.12), Color(0.4, 0.04, 0.08), 0.25, 0.2, 0.65)
	var mat_sangre := _crear_material(Color(0.95, 0.12, 0.18), Color(1.0, 0.14, 0.20), 1.9, 0.55, 0.2)

	# Altar oscuro octogonal
	var altar := MeshInstance3D.new()
	var m_altar := CylinderMesh.new()
	m_altar.top_radius = 0.85
	m_altar.bottom_radius = 1.15
	m_altar.height = 0.55
	m_altar.radial_segments = 8
	m_altar.material = mat_basalto
	altar.mesh = m_altar
	altar.position = Vector3(0.0, 0.275, 0.0)
	visual_root.add_child(altar)

	# Obelisco carmesí central
	var obelisco := MeshInstance3D.new()
	var m_obe := BoxMesh.new()
	m_obe.size = Vector3(0.58, 1.85, 0.58)
	m_obe.material = mat_basalto
	obelisco.mesh = m_obe
	obelisco.position = Vector3(0.0, 1.38, 0.0)
	visual_root.add_child(obelisco)

	# Anillo runico sangriento alrededor del obelisco
	var aro := MeshInstance3D.new()
	var m_aro := TorusMesh.new()
	m_aro.inner_radius = 0.68
	m_aro.outer_radius = 0.82
	m_aro.rings = 28
	m_aro.ring_segments = 10
	m_aro.material = mat_sangre
	aro.mesh = m_aro
	aro.position = Vector3(0.0, 1.25, 0.0)
	visual_root.add_child(aro)

	# Lanza / punta de Marte girando encima
	_espada_flotante = MeshInstance3D.new()
	var m_punta := PrismMesh.new()
	m_punta.size = Vector3(0.55, 0.95, 0.55)
	m_punta.material = mat_sangre
	_espada_flotante.mesh = m_punta
	_espada_flotante.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	_espada_flotante.position = Vector3(0.0, 2.7, 0.0)
	visual_root.add_child(_espada_flotante)

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
		if not _consumido and _espada_flotante != null:
			_espada_flotante.rotate_y(delta * 1.6)
			_espada_flotante.position.y = 2.7 + sin(Time.get_ticks_msec() * 0.005) * 0.1
		return

	var pj := _obtener_jugador()
	if pj == null or ("_muerto_definitivo" in pj and pj._muerto_definitivo):
		_finalizar_sin_recompensa()
		return

	_tiempo_restante = maxf(0.0, _tiempo_restante - delta)
	if _badge_label != null:
		_badge_label.text = "⚔️ PACTO DE MARTE: %ds" % ceili(_tiempo_restante)

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
	_badge_layer = CanvasLayer.new()
	_badge_layer.layer = 18
	get_tree().root.add_child(_badge_layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(28.0, 94.0)
	panel.add_theme_stylebox_override("panel", _crear_panel_style(Color(0.95, 0.22, 0.28), Color(0.14, 0.03, 0.05, 0.90), 2, 10))
	_badge_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)

	_badge_label = Label.new()
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label.text = "⚔️ PACTO DE MARTE: 60s"
	_badge_label.add_theme_font_size_override("font_size", 16)
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
	if _badge_layer != null and is_instance_valid(_badge_layer):
		_badge_layer.queue_free()
	_badge_layer = null
	_badge_label = null

func _exit_tree() -> void:
	_limpiar_badge()
