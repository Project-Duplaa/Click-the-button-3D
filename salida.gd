extends Area3D

## Salida — Portal de Ascensión Místico y Obelisco del Abismo Carmesí
## Inicia completamente SELLADO en tonalidad violeta oscura.
## Se desbloquea únicamente al abatir a La Parca Roja o superar la prueba.
## Al desbloquearse transmuta en esmeralda radiante y activa el Obelisco del Abismo Carmesí (+5.5m)
## para que el jugador elija entre ascender triunfante o entrar en Modo Abismo Infinito (x4 Recompensas).

@export var portal_abierto: bool = false

var _label_info: Label3D = null
var _luz_portal: OmniLight3D = null
var _mesh_portal: MeshInstance3D = null
var _obelisco_abismo: Node3D = null

func _ready():
	add_to_group("portal_ascension")
	body_entered.connect(_al_entrar)
	_configurar_componentes_visuales()
	_actualizar_estado_visual()

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

	var dopamina = get_tree().get_first_node_in_group("audio_dopamina")
	if dopamina != null and dopamina.has_method("play_level_up"):
		dopamina.play_level_up()

	# Activa el Obelisco del Abismo Carmesí anexo
	_activar_obelisco_abismo()

func _actualizar_estado_visual():
	if _label_info != null:
		if portal_abierto:
			_label_info.text = "¡PORTAL DE ASCENSIÓN ABIERTO!\n[Pisa para ascender a la Gloria]"
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
	_obelisco_abismo.global_position = global_position + Vector3(5.5, 0.0, 0.0)

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
	lbl.text = "🔥 [E] MODO ABISMO INFINITO\n(Recompensas x4 · Dificultad Extrema)"
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
		var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
		if pool_dano != null and pool_dano.has_method("mostrar_texto"):
			pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), "🔒 ¡Portal Sellado! Elimina la amenaza colosal.", Color(1.0, 0.3, 0.3), 1.2)
		return

	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and partida.has_method("ganar"):
		partida.ganar()
