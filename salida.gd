extends Area3D

## Salida — Portal de Ascensión Místico y Obelisco del Abismo Carmesí
## Inicia completamente SELLADO en tonalidad violeta oscura.
## Se desbloquea únicamente al abatir a La Parca Roja o superar la prueba.
## Al desbloquearse transmuta en esmeralda radiante y activa el Obelisco del Abismo Carmesí (+5.5m)
## para que el jugador elija entre ascender triunfante o entrar en Modo Abismo Infinito (x4 Recompensas).

const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var portal_abierto: bool = false

var _label_info: Label3D = null
var _luz_portal: OmniLight3D = null
var _mesh_portal: MeshInstance3D = null
var _obelisco_abismo: Node3D = null
var _modo_esencial: bool = false
var _modal_decision: CanvasLayer = null

func actualizar_modo_esencial(activo: bool) -> void:
	_modo_esencial = activo
	_actualizar_estado_visual()

func _ready():
	add_to_group("portal_ascension")
	add_to_group("indicadores_tacticos")
	body_entered.connect(_al_entrar)
	_configurar_componentes_visuales()
	_actualizar_estado_visual()
	call_deferred("_reubicar_salida_aleatoria_run")

func _reubicar_salida_aleatoria_run() -> void:
	ArenaColiseo._asegurar_cache()
	var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
	var caras_validas: Array[int] = [0, 1, 2, 3, 9, 10, 11]
	var elegido := Vector3.ZERO
	var rad_dir := Vector3.FORWARD
	var tang_dir := Vector3.RIGHT

	for _intento in range(32):
		var idx_k: int = int(caras_validas[int(rng.randi() % caras_validas.size())])
		var theta: float = float(idx_k) * (TAU / float(ArenaColiseo.NUM_LADOS))
		var n := Vector2(sin(theta), -cos(theta))
		var t := Vector2(cos(theta), sin(theta))
		var r_wall: float = ArenaColiseo.APOTEMA_EXTERIOR - 3.6
		var lat: float = rng.randf_range(-6.0, 6.0)
		var cand := Vector3(n.x * r_wall + t.x * lat, 0.0, n.y * r_wall + t.y * lat)
		if not ArenaColiseo.esta_dentro(cand, 2.4):
			continue
		if ArenaColiseo.esta_en_pendiente(cand.x, cand.z, 1.0):
			continue
		if not ArenaColiseo.punto_libre_de_obstaculos(cand, 3.2):
			continue
		elegido = ArenaColiseo.clamping_y_ajustar_a_suelo(cand, 2.4, 0.0)
		rad_dir = Vector3(n.x, 0.0, n.y).normalized()
		tang_dir = Vector3(t.x, 0.0, t.y).normalized()
		break

	if elegido == Vector3.ZERO:
		var excl_fb: Array[Vector2] = [Vector2(0.0, 0.0)]
		elegido = ArenaColiseo.punto_seguro_con_exclusiones(ArenaColiseo.APOTEMA_FOSO + 2.5, ArenaColiseo.APOTEMA_EXTERIOR - 3.0, excl_fb, 12.0, rng, 0.0, false, false)
		rad_dir = Vector3(elegido.x, 0.0, elegido.z).normalized()
		if rad_dir.length_squared() < 0.01:
			rad_dir = Vector3.FORWARD
		tang_dir = Vector3(-rad_dir.z, 0.0, rad_dir.x)

	global_position = elegido
	rotation.y = atan2(-elegido.x, -elegido.z)

	var parent_node: Node = get_parent()
	if parent_node != null:
		var deco: Node = parent_node.get_node_or_null("DecoracionesArena")
		if deco != null:
			var bl: Node3D = deco.get_node_or_null("Salida_BarreraL") as Node3D
			var br: Node3D = deco.get_node_or_null("Salida_BarreraR") as Node3D
			var sc: Node3D = deco.get_node_or_null("Salida_Caja") as Node3D
			if bl != null:
				var p_bl: Vector3 = ArenaColiseo.clamping_y_ajustar_a_suelo(elegido - tang_dir * 2.3 + rad_dir * 0.4, 2.0, 0.0)
				bl.global_position = p_bl
				bl.rotation.y = atan2(-p_bl.x, -p_bl.z) - 0.25
			if br != null:
				var p_br: Vector3 = ArenaColiseo.clamping_y_ajustar_a_suelo(elegido + tang_dir * 2.3 + rad_dir * 0.4, 2.0, 0.0)
				br.global_position = p_br
				br.rotation.y = atan2(-p_br.x, -p_br.z) + 0.25
			if sc != null:
				var p_sc: Vector3 = ArenaColiseo.clamping_y_ajustar_a_suelo(elegido + tang_dir * 3.1 - rad_dir * 0.6, 2.0, 0.0)
				sc.global_position = p_sc
				sc.rotation.y = atan2(-p_sc.x, -p_sc.z) + 0.5

func _configurar_componentes_visuales():
	_mesh_portal = get_node_or_null("MeshInstance3D")

	_luz_portal = get_node_or_null("LuzPortal")
	if _luz_portal == null:
		_luz_portal = OmniLight3D.new()
		_luz_portal.name = "LuzPortal"
		_luz_portal.omni_range = 6.0
		add_child(_luz_portal)

	_label_info = get_node_or_null("LabelPortal")
	if _label_info == null:
		_label_info = Label3D.new()
		_label_info.name = "LabelPortal"
		_label_info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label_info.no_depth_test = true
		_label_info.outline_size = 10
		_label_info.font_size = 40
		_label_info.position = Vector3(0.0, 2.4, 0.0)
		add_child(_label_info)

func _process(_delta: float):
	if not portal_abierto:
		var partida = get_tree().get_first_node_in_group("partida")
		if partida != null:
			var parca_muerta = ("parca_derrotada" in partida and partida.parca_derrotada)
			var tiempo_agotado = ("tiempo" in partida and partida.tiempo <= 0.001)
			if parca_muerta or (tiempo_agotado and _sin_jefes_vivos()):
				desbloquear_portal()

func _sin_jefes_vivos() -> bool:
	var jefes = get_tree().get_nodes_in_group("jefes")
	if jefes.is_empty():
		jefes = get_tree().get_nodes_in_group("bosses")
	return jefes.is_empty()

func desbloquear_portal():
	if portal_abierto:
		return
	portal_abierto = true
	_actualizar_estado_visual()

	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_letrero_temporal"):
		hud.mostrar_letrero_temporal("portal_abierto", "🌀 ¡PORTAL DE ASCENSIÓN ABIERTO!", "Entra al portal para reclamar tu Victoria o desafiar el Modo Abismo Infinito.", Color(0.25, 1.0, 0.6))

	var dopamina = get_tree().get_first_node_in_group("audio_dopamina")
	if dopamina != null and dopamina.has_method("play_level_up"):
		dopamina.play_level_up()

	# Activa el Obelisco del Abismo Carmesí anexo
	_activar_obelisco_abismo()

func _actualizar_estado_visual():
	if _label_info != null:
		if _modo_esencial:
			_label_info.text = "PORTAL DE ASCENSIÓN" if portal_abierto else "PORTAL SELLADO"
			_label_info.modulate = Color(0.25, 1.0, 0.55) if portal_abierto else Color(0.75, 0.35, 1.0)
		elif portal_abierto:
			_label_info.text = "¡PORTAL DE ASCENSIÓN ABIERTO!\n[Pisa para elegir Victoria o Abismo]"
			_label_info.modulate = Color(0.25, 1.0, 0.55)
		else:
			_label_info.text = "PORTAL DE ASCENSIÓN\n[Derrota a La Parca Roja en Oleada 15]"
			_label_info.modulate = Color(0.75, 0.35, 1.0)

	if _luz_portal != null:
		if portal_abierto:
			_luz_portal.light_color = Color(0.2, 1.0, 0.5)
			_luz_portal.light_energy = 4.5
		else:
			_luz_portal.light_color = Color(0.45, 0.15, 0.75)
			_luz_portal.light_energy = 2.0

func _activar_obelisco_abismo():
	if _obelisco_abismo != null and is_instance_valid(_obelisco_abismo):
		return

	_obelisco_abismo = Area3D.new()
	_obelisco_abismo.name = "ObeliscoAbismoCarmesi"
	get_parent().add_child(_obelisco_abismo)
	_obelisco_abismo.global_position = ArenaColiseo.punto_aleatorio(11.0, 20.0, ArenaColiseo._obtener_rng_run(self), 0.0)

	var col = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(2.0, 3.5, 2.0)
	col.shape = box_col
	col.position = Vector3(0, 1.75, 0)
	_obelisco_abismo.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.4, 3.4, 1.4)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 1.7, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.01, 0.02)
	mat.metallic = 0.90
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.12, 0.18)
	mat.emission_energy_multiplier = 3.8
	mesh_inst.material_override = mat
	_obelisco_abismo.add_child(mesh_inst)

	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.15, 0.22)
	luz.light_energy = 4.5
	luz.omni_range = 6.5
	luz.position = Vector3(0, 2.2, 0)
	_obelisco_abismo.add_child(luz)

	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 38
	lbl.position = Vector3(0, 3.8, 0)
	lbl.modulate = Color(1.0, 0.25, 0.3)
	lbl.text = "🔥 MODO ABISMO INFINITO [E / CLIC]\n💀 Recompensas x4 · Dificultad Extrema\n[PISA O HAZ CLIC PARA ENTRAR]"
	_obelisco_abismo.add_child(lbl)

	_obelisco_abismo.input_ray_pickable = true
	_obelisco_abismo.input_event.connect(func(_cam, ev, _p, _n, _s):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_detonar_entrada_abismo()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if _obelisco_abismo != null and is_instance_valid(_obelisco_abismo):
			var pj = get_tree().get_first_node_in_group("jugador")
			if pj == null:
				pj = get_tree().get_first_node_in_group("player")
			if pj != null and pj.global_position.distance_to(_obelisco_abismo.global_position) <= 4.5:
				_detonar_entrada_abismo()

func _detonar_entrada_abismo() -> void:
	if _obelisco_abismo == null or not is_instance_valid(_obelisco_abismo):
		return

	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and partida.has_method("activar_modo_abismo"):
		partida.activar_modo_abismo()

	var tw = _obelisco_abismo.create_tween()
	tw.tween_property(_obelisco_abismo, "scale", Vector3(0.05, 0.05, 0.05), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if is_instance_valid(_obelisco_abismo):
			_obelisco_abismo.queue_free()
			_obelisco_abismo = null
	)

func _al_entrar(cuerpo: Node3D):
	if not (cuerpo.is_in_group("player") or cuerpo.is_in_group("jugador")):
		return

	if not portal_abierto:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud != null and hud.has_method("mostrar_letrero_temporal"):
			hud.mostrar_letrero_temporal("portal_sellado", "🔒 PORTAL DE ASCENSIÓN SELLADO", "Derrota al Jefe Final (La Parca Roja en Oleada 15) para desbloquear la salida.", Color(0.85, 0.45, 1.0))
		var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
		if pool_dano != null and pool_dano.has_method("mostrar_texto"):
			pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), "🔒 ¡Portal Sellado! Elimina la amenaza colosal.", Color(1.0, 0.3, 0.3), 1.2)
		return

	_mostrar_modal_decision_victoria()

func _mostrar_modal_decision_victoria() -> void:
	if _modal_decision != null and is_instance_valid(_modal_decision):
		return

	_modal_decision = CanvasLayer.new()
	_modal_decision.layer = 25
	_modal_decision.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_modal_decision)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.02, 0.04, 0.82)
	_modal_decision.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -140.0
	panel.offset_bottom = 140.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.12, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.25, 0.95, 0.65, 0.9)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", sb)
	dimmer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var lbl_tit := Label.new()
	lbl_tit.text = "🏆 ¡EL COLISEO HA SIDO DOMINADO!"
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.add_theme_font_size_override("font_size", 14)
	lbl_tit.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	vbox.add_child(lbl_tit)

	var lbl_sub := Label.new()
	lbl_sub.text = "¿Deseas ascender victorioso o desafiar el Abismo Infinito con recompensas x4?"
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 10)
	lbl_sub.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	vbox.add_child(lbl_sub)

	var hbox_btns := HBoxContainer.new()
	hbox_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_btns.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox_btns)

	var btn_ganar := Button.new()
	btn_ganar.text = "👑 RECLAMAR VICTORIA"
	btn_ganar.custom_minimum_size = Vector2(170, 34)
	btn_ganar.focus_mode = Control.FOCUS_NONE
	btn_ganar.pressed.connect(func():
		if is_instance_valid(_modal_decision):
			_modal_decision.queue_free()
		var partida = get_tree().get_first_node_in_group("partida")
		if partida != null and partida.has_method("ganar"):
			partida.ganar()
	)
	hbox_btns.add_child(btn_ganar)

	var btn_abismo := Button.new()
	btn_abismo.text = "🔥 MODO ABISMO (x4)"
	btn_abismo.custom_minimum_size = Vector2(170, 34)
	btn_abismo.focus_mode = Control.FOCUS_NONE
	btn_abismo.pressed.connect(func():
		if is_instance_valid(_modal_decision):
			_modal_decision.queue_free()
		_detonar_entrada_abismo()
	)
	hbox_btns.add_child(btn_abismo)

	var btn_cancelar := Button.new()
	btn_cancelar.text = "✖ Continuar en la Arena"
	btn_cancelar.custom_minimum_size = Vector2(130, 26)
	btn_cancelar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cancelar.focus_mode = Control.FOCUS_NONE
	btn_cancelar.pressed.connect(func():
		if is_instance_valid(_modal_decision):
			_modal_decision.queue_free()
	)
	vbox.add_child(btn_cancelar)
