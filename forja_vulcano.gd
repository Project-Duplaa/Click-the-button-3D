extends "res://santuario_base.gd"
class_name ForjaVulcano

## ForjaVulcano - Yunque ardiente del Coliseo que duplica una reliquia poseída.
## Si el héroe no tiene reliquias, no cobra ni se consume. Si tiene >1, abre un modal
## para elegir cuál duplicar (cancelar deja la forja intacta).

var _modal_layer: CanvasLayer = null
var _nucleo_brasa: MeshInstance3D = null

func _configurar_santuario() -> void:
	nombre_santuario = "Forja de Vulcano"
	costo_denarios = 5
	radio_interaccion = 5.5
	un_solo_uso = true
	activacion_por_clic = true
	color_luz = Color(1.0, 0.45, 0.12)
	altura_etiqueta = 3.1

func _construir_visual() -> void:
	# Plataforma de piedra volcánica
	var base := MeshInstance3D.new()
	var m_base := CylinderMesh.new()
	m_base.top_radius = 1.1
	m_base.bottom_radius = 1.3
	m_base.height = 0.28
	m_base.radial_segments = 8
	m_base.material = _crear_material(Color(0.22, 0.19, 0.18), Color(0.55, 0.18, 0.05), 0.3, 0.2, 0.75)
	base.mesh = m_base
	base.position = Vector3(0.0, 0.14, 0.0)
	visual_root.add_child(base)

	# Tronco / soporte del yunque
	var soporte := MeshInstance3D.new()
	var m_soporte := BoxMesh.new()
	m_soporte.size = Vector3(0.75, 0.72, 0.65)
	m_soporte.material = _crear_material(Color(0.18, 0.18, 0.22), Color.BLACK, 0.0, 0.75, 0.4)
	soporte.mesh = m_soporte
	soporte.position = Vector3(0.0, 0.64, 0.0)
	visual_root.add_child(soporte)

	# Cuerpo del yunque
	var yunque := MeshInstance3D.new()
	var m_yunque := BoxMesh.new()
	m_yunque.size = Vector3(1.25, 0.38, 0.68)
	m_yunque.material = _crear_material(Color(0.28, 0.29, 0.34), Color(0.95, 0.35, 0.08), 0.25, 0.85, 0.28)
	yunque.mesh = m_yunque
	yunque.position = Vector3(0.0, 1.15, 0.0)
	visual_root.add_child(yunque)

	# Cuerno lateral del yunque
	var cuerno := MeshInstance3D.new()
	var m_cuerno := PrismMesh.new()
	m_cuerno.size = Vector3(0.45, 0.62, 0.45)
	m_cuerno.material = _crear_material(Color(0.32, 0.33, 0.38), Color(1.0, 0.42, 0.1), 0.35, 0.9, 0.25)
	cuerno.mesh = m_cuerno
	cuerno.rotation_degrees = Vector3(0.0, 0.0, -90.0)
	cuerno.position = Vector3(0.82, 1.16, 0.0)
	visual_root.add_child(cuerno)

	# Brasa incandescente flotante encima del yunque
	_nucleo_brasa = MeshInstance3D.new()
	var m_brasa := SphereMesh.new()
	m_brasa.radius = 0.28
	m_brasa.height = 0.56
	m_brasa.material = _crear_material(Color(1.0, 0.55, 0.12), Color(1.0, 0.45, 0.08), 2.1, 0.2, 0.2)
	_nucleo_brasa.mesh = m_brasa
	_nucleo_brasa.position = Vector3(0.0, 1.72, 0.0)
	visual_root.add_child(_nucleo_brasa)

	_actualizar_etiqueta("Duplica 1 Reliquia")

func _process(delta: float) -> void:
	if _consumido or _nucleo_brasa == null:
		return
	_nucleo_brasa.rotate_y(delta * 1.6)
	_nucleo_brasa.position.y = 1.72 + sin(Time.get_ticks_msec() * 0.005) * 0.08

func _activar(pj: Node3D) -> bool:
	var reliquias: Dictionary = pj.reliquias if ("reliquias" in pj and pj.reliquias is Dictionary) else {}
	if reliquias.is_empty():
		_spawn_texto_3d("⚒️ Necesitas una reliquia", Color(1.0, 0.58, 0.22))
		AudioManager.play("escudo_bloqueo", 0.95)
		return false

	if reliquias.size() == 1:
		if not _cobrar(pj):
			return false
		var id_unico: String = String(reliquias.keys()[0])
		if pj.has_method("duplicar_reliquia"):
			pj.duplicar_reliquia(id_unico)
		AudioManager.play("jackpot", 1.05)
		_spawn_texto_3d("⚒️ %s x2" % ReliquiaDatos.obtener_nombre(id_unico), Color(1.0, 0.72, 0.25))
		return true

	_abrir_modal_forja(pj, reliquias)
	return false

func _abrir_modal_forja(pj: Node3D, reliquias: Dictionary) -> void:
	if _modal_layer != null and is_instance_valid(_modal_layer):
		return
	AudioManager.play("altar_activado", 0.95)

	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 30
	_modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_layer.add_to_group("modales_santuario")
	get_tree().root.add_child(_modal_layer)

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.03, 0.02, 0.02, 0.72)
	_modal_layer.add_child(fondo)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 440)
	panel.offset_left = -320
	panel.offset_top = -220
	panel.offset_right = 320
	panel.offset_bottom = 220
	panel.add_theme_stylebox_override("panel", _crear_panel_style(Color(1.0, 0.48, 0.14), Color(0.08, 0.06, 0.06, 0.97), 3, 14))
	fondo.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "⚒️ FORJA DE VULCANO (%d Denarios)" % costo_denarios
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	vbox.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Elige qué reliquia deseas duplicar (+1 acumulación)"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 14)
	subtitulo.add_theme_color_override("font_color", Color(0.84, 0.80, 0.78))
	vbox.add_child(subtitulo)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	scroll.add_child(lista)

	for id_rel in reliquias.keys():
		var id_str: String = String(id_rel)
		var cant: int = int(reliquias[id_rel])
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 62)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 15)
		btn.text = "  %s %s (x%d → x%d)\n  %s" % [
			ReliquiaDatos.obtener_icono(id_str),
			ReliquiaDatos.obtener_nombre(id_str),
			cant,
			cant + 1,
			ReliquiaDatos.obtener_descripcion(id_str)
		]
		_aplicar_estilo_boton_modal(btn, Color(1.0, 0.55, 0.18))
		btn.pressed.connect(_confirmar_forja.bind(pj, id_str))
		lista.add_child(btn)

	var btn_cancelar := Button.new()
	btn_cancelar.text = "Cancelar (No gastar Denarios)"
	btn_cancelar.custom_minimum_size = Vector2(240, 40)
	btn_cancelar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_aplicar_estilo_boton_modal(btn_cancelar, Color(0.55, 0.58, 0.65))
	btn_cancelar.pressed.connect(_cerrar_modal)
	vbox.add_child(btn_cancelar)

	_pausar_por_modal()

func _confirmar_forja(pj: Node3D, id_reliquia: String) -> void:
	_cerrar_modal()
	if pj == null or not is_instance_valid(pj):
		return
	if not _cobrar(pj):
		_spawn_texto_3d("Faltan Denarios (%d)" % costo_denarios, Color(1.0, 0.35, 0.35))
		return
	if pj.has_method("duplicar_reliquia"):
		pj.duplicar_reliquia(id_reliquia)
	AudioManager.play("jackpot", 1.05)
	_spawn_texto_3d("⚒️ %s x2" % ReliquiaDatos.obtener_nombre(id_reliquia), Color(1.0, 0.72, 0.25))
	_consumir()

func _cerrar_modal() -> void:
	if _modal_layer != null and is_instance_valid(_modal_layer):
		_modal_layer.visible = false
		_modal_layer.remove_from_group("modales_santuario")
		_modal_layer.queue_free()
		_modal_layer = null
	_restaurar_pausa_segura()

func _exit_tree() -> void:
	if _modal_layer != null and is_instance_valid(_modal_layer):
		_modal_layer.visible = false
		_modal_layer.remove_from_group("modales_santuario")
		_modal_layer.queue_free()
		_modal_layer = null
		_restaurar_pausa_segura()
