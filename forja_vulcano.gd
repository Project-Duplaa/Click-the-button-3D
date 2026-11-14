extends "res://santuario_base.gd"
class_name ForjaVulcano

## ForjaVulcano - Yunque ardiente del Coliseo que duplica una reliquia poseída.
## Si el héroe no tiene reliquias, no cobra ni se consume. Si tiene >1, abre un modal
## para elegir cuál duplicar (cancelar deja la forja intacta).

var _modal_layer: CanvasLayer = null
var _nucleo_brasa: MeshInstance3D = null
var _mordaza_superior: MeshInstance3D = null
var _aro_magnetico: MeshInstance3D = null

func _configurar_santuario() -> void:
	nombre_santuario = "Forja de Vulcano"
	costo_denarios = 5
	radio_interaccion = 5.5
	un_solo_uso = true
	activacion_por_clic = true
	color_luz = BunkerVisualKit.COL_PLASMA_ORANGE
	altura_etiqueta = 3.15

func _construir_visual() -> void:
	# Anillo táctico de suelo
	var ring := BunkerVisualKit.create_hazard_ground_ring(
		1.45,
		BunkerVisualKit.COL_PLASMA_ORANGE,
		BunkerVisualKit.COL_HAZARD_YELLOW,
		0.80,
		0.95,
		0.35
	)
	var ring_mat := ring.material_override as ShaderMaterial
	if ring_mat != null:
		ring_mat.set_shader_parameter("progress", 1.0)
	visual_root.add_child(ring)

	# Bancada industrial pesada
	BunkerVisualKit.make_box(
		visual_root,
		"BancadaIndustrial",
		Vector3(1.65, 0.38, 1.35),
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.19, 0.0)
	)

	# Faldón perimetral con franjas hazard naranja plasma / acero carbono
	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_PLASMA_ORANGE,
		BunkerVisualKit.COL_CARBON_STEEL,
		10.0
	)
	BunkerVisualKit.make_box(
		visual_root,
		"FaldonHazard",
		Vector3(1.72, 0.14, 1.42),
		mat_hazard,
		Vector3(0.0, 0.36, 0.0)
	)

	# 2 columnas hidráulicas cromadas laterales
	for sx in [-0.62, 0.62]:
		BunkerVisualKit.make_cylinder(
			visual_root,
			"ColumnaHidraulica_%s" % ("L" if sx < 0.0 else "R"),
			0.11,
			0.13,
			1.52,
			BunkerVisualKit.get_chrome_mat(),
			Vector3(sx, 1.12, 0.0),
			14
		)
		BunkerVisualKit.make_cylinder(
			visual_root,
			"BujeColumna_%s" % ("L" if sx < 0.0 else "R"),
			0.16,
			0.16,
			0.22,
			BunkerVisualKit.get_armor_grey_mat(),
			Vector3(sx, 0.52, 0.0),
			12
		)

	# Travesaño superior fijo
	BunkerVisualKit.make_box(
		visual_root,
		"TravesanoSuperior",
		Vector3(1.56, 0.24, 0.62),
		BunkerVisualKit.get_armor_grey_mat(),
		Vector3(0.0, 1.88, 0.0)
	)

	# Mordaza hidráulica superior móvil en Y = 1.42
	_mordaza_superior = BunkerVisualKit.make_box(
		visual_root,
		"MordazaSuperior",
		Vector3(0.96, 0.22, 0.64),
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 1.42, 0.0)
	)
	BunkerVisualKit.make_cylinder(
		_mordaza_superior,
		"PistonCentral",
		0.14,
		0.14,
		0.42,
		BunkerVisualKit.get_chrome_mat(),
		Vector3(0.0, 0.28, 0.0),
		12
	)

	# Crisol inferior de tungsteno
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CrisolTungsteno",
		0.48,
		0.56,
		0.32,
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 0.54, 0.0),
		12
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"LechoIncandescente",
		0.38,
		0.38,
		0.06,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_PLASMA_ORANGE, 2.2),
		Vector3(0.0, 0.71, 0.0),
		12
	)

	# 3 bobinas toroidales de cobre rodeando la cámara de inducción
	for i in range(3):
		BunkerVisualKit.make_torus(
			visual_root,
			"BobinaInduccion_%d" % i,
			0.42,
			0.50,
			BunkerVisualKit.get_copper_coil_mat(),
			Vector3(0.0, 0.80 + float(i) * 0.20, 0.0)
		)

	# Núcleo de plasma en Y = 1.02 + aro magnético rotatorio
	_nucleo_brasa = MeshInstance3D.new()
	_nucleo_brasa.name = "NucleoPlasma"
	var m_brasa := SphereMesh.new()
	m_brasa.radius = 0.26
	m_brasa.height = 0.52
	_nucleo_brasa.mesh = m_brasa
	_nucleo_brasa.material_override = BunkerVisualKit.create_hologram_material(
		BunkerVisualKit.COL_PLASMA_ORANGE,
		Color(1.0, 0.85, 0.4),
		2.8
	)
	_nucleo_brasa.position = Vector3(0.0, 1.02, 0.0)
	visual_root.add_child(_nucleo_brasa)

	_aro_magnetico = BunkerVisualKit.make_torus(
		visual_root,
		"AroMagnetico",
		0.30,
		0.35,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_HAZARD_YELLOW, 2.0),
		Vector3(0.0, 1.02, 0.0),
		Vector3(35.0, 0.0, 20.0)
	)

	_actualizar_etiqueta("Duplica 1 Reliquia")

func _process(delta: float) -> void:
	if _consumido or _nucleo_brasa == null:
		return
	_nucleo_brasa.rotate_y(delta * 1.8)
	_nucleo_brasa.position.y = 1.02 + sin(Time.get_ticks_msec() * 0.005) * 0.05
	if _aro_magnetico != null:
		_aro_magnetico.rotate_y(-delta * 2.4)
		_aro_magnetico.rotate_x(delta * 1.5)

func _animar_golpe_prensa() -> void:
	if _mordaza_superior != null and is_instance_valid(_mordaza_superior):
		var tw := create_tween()
		tw.tween_property(_mordaza_superior, "position:y", 1.05, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_mordaza_superior, "position:y", 1.42, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	BunkerVisualKit.spawn_shockwave_ring(
		get_parent(),
		global_position,
		0.6,
		2.8,
		BunkerVisualKit.COL_PLASMA_ORANGE,
		0.32
	)

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
		_animar_golpe_prensa()
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
	_animar_golpe_prensa()
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
