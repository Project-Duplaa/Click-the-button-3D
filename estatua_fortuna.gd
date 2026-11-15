extends "res://santuario_base.gd"
class_name EstatuaFortuna

## EstatuaFortuna - Santuario de Carga por Proximidad (Estatua dorada del Coliseo).
## El jugador permanece dentro de su anillo de 3.0 m durante 4.0 s (se reinicia al salir).
## Al completarse, despliega 3 cartas de mejora con rareza sorteada por FortunaManager.

const RADIO_CARGA: float = 3.0
const TIEMPO_CARGA: float = 4.0
const SELLO_GRACIA_INICIAL_MS: int = 850
const SELLO_REBOTE_SPAM_MS: int = 360
const SELLO_MAX_TOTAL_MS: int = 2000

const OPCIONES_STAT := [
	{"id": "dano", "titulo": "⚔️ Filo Mortal", "desc": "+%s%% Daño de Ataque", "base": 22.0, "dec": 0},
	{"id": "cadencia", "titulo": "⚡ Furia Veloz", "desc": "+%s%% Vel. de Ataque", "base": 16.0, "dec": 0},
	{"id": "vida", "titulo": "🛡️ Vitalidad", "desc": "+%s Vida Máx y HP", "base": 30.0, "dec": 0},
	{"id": "velocidad", "titulo": "👟 Agilidad", "desc": "+%s%% Vel. Movimiento", "base": 15.0, "dec": 0},
	{"id": "critico", "titulo": "🎯 Precisión Letal", "desc": "+%s%% Prob. Crítico", "base": 8.0, "dec": 0},
	{"id": "iman", "titulo": "🧲 Imán Rúnico", "desc": "+%sm Rango Recolección", "base": 2.0, "dec": 1},
	{"id": "fortuna", "titulo": "🍀 Fortuna del Coliseo", "desc": "+%s Suerte de la run", "base": 0.10, "dec": 2},
]

var _progreso: float = 0.0
var _modal_abierto: bool = false
var _disco_progreso: MeshInstance3D = null
var _anillo_externo: MeshInstance3D = null
var _cristal_superior: MeshInstance3D = null
var _giro_anillo_a: MeshInstance3D = null
var _giro_anillo_b: MeshInstance3D = null
var _modal_layer: CanvasLayer = null
var _modal_apertura_msec: int = 0
var _modal_bloqueado_hasta_msec: int = 0
var _subtitulo_modal: Label = null

func _configurar_santuario() -> void:
	nombre_santuario = "Estatua de Fortuna"
	costo_denarios = 0
	radio_interaccion = RADIO_CARGA
	un_solo_uso = true
	activacion_por_clic = false
	color_luz = BunkerVisualKit.COL_VAULT_GOLD
	altura_etiqueta = 3.65

func _construir_visual() -> void:
	# Zócalo hexagonal de concreto búnker
	BunkerVisualKit.make_cylinder(
		visual_root,
		"ZocaloHexagonal",
		1.25,
		1.45,
		0.36,
		BunkerVisualKit.get_concrete_base_mat(),
		Vector3(0.0, 0.18, 0.0),
		6
	)

	# Collarín hexagonal con franjas hazard doradas/acero
	var mat_hazard_oro := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_VAULT_GOLD,
		BunkerVisualKit.COL_CARBON_STEEL,
		10.0
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CollarinHazard",
		1.02,
		1.14,
		0.18,
		mat_hazard_oro,
		Vector3(0.0, 0.45, 0.0),
		6
	)

	# Torre / mástil central de acero carbono
	BunkerVisualKit.make_cylinder(
		visual_root,
		"MastilCentral",
		0.34,
		0.52,
		1.78,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 1.38, 0.0),
		8
	)

	# Cabezal colector superior de titanio
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CabezalColector",
		0.56,
		0.38,
		0.24,
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 2.18, 0.0),
		6
	)

	# 4 columnas anguladas de telemetría convergiendo hacia el cabezal
	for i in range(4):
		var ang_rad: float = (TAU * 0.25) * float(i) + PI * 0.25
		var dir := Vector3(cos(ang_rad), 0.0, sin(ang_rad))
		var puntal := BunkerVisualKit.make_box(
			visual_root,
			"ColumnaTelemetria_%d" % i,
			Vector3(0.11, 1.68, 0.14),
			BunkerVisualKit.get_titanium_mat(),
			dir * 0.64 + Vector3(0.0, 1.28, 0.0)
		)
		puntal.look_at_from_position(
			dir * 0.64 + Vector3(0.0, 1.28, 0.0),
			Vector3(0.0, 2.18, 0.0),
			Vector3.UP
		)

	# 2 anillos giroscópicos orbitales dorados
	var mat_giro := BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_VAULT_GOLD,
		1.8,
		BunkerVisualKit.COL_VAULT_GOLD,
		0.9,
		0.2
	)
	_giro_anillo_a = BunkerVisualKit.make_torus(
		visual_root,
		"GiroAnilloA",
		0.52,
		0.60,
		mat_giro,
		Vector3(0.0, 2.55, 0.0),
		Vector3(28.0, 0.0, 15.0)
	)
	_giro_anillo_b = BunkerVisualKit.make_torus(
		visual_root,
		"GiroAnilloB",
		0.64,
		0.72,
		mat_giro,
		Vector3(0.0, 2.55, 0.0),
		Vector3(-34.0, 45.0, -18.0)
	)

	# Núcleo de iones holográfico en Y = 2.55
	_cristal_superior = MeshInstance3D.new()
	_cristal_superior.name = "NucleoIonesSuperior"
	var m_cris := SphereMesh.new()
	m_cris.radius = 0.36
	m_cris.height = 0.72
	m_cris.radial_segments = 8
	m_cris.rings = 4
	_cristal_superior.mesh = m_cris
	_cristal_superior.material_override = BunkerVisualKit.create_hologram_material(
		BunkerVisualKit.COL_VAULT_GOLD,
		Color(1.0, 0.96, 0.72),
		2.5
	)
	_cristal_superior.position = Vector3(0.0, 2.55, 0.0)
	visual_root.add_child(_cristal_superior)

	# Anillo delimitador táctico en el suelo (radio exacto de 3.0 m)
	_anillo_externo = BunkerVisualKit.create_hazard_ground_ring(
		RADIO_CARGA,
		BunkerVisualKit.COL_VAULT_GOLD,
		Color(1.0, 0.95, 0.55),
		0.84,
		0.96,
		0.42,
		0.22
	)
	_anillo_externo.position = Vector3(0.0, 0.028, 0.0)
	visual_root.add_child(_anillo_externo)

	# Disco de progreso interior complementario que crece de 0 a 100 %
	_disco_progreso = BunkerVisualKit.make_cylinder(
		visual_root,
		"DiscoProgresoInterior",
		RADIO_CARGA - 0.32,
		RADIO_CARGA - 0.32,
		0.018,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_VAULT_GOLD, 1.1, BunkerVisualKit.COL_VAULT_GOLD, 0.3, 0.3, 0.16),
		Vector3(0.0, 0.022, 0.0),
		36
	)
	_disco_progreso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disco_progreso.scale = Vector3(0.01, 1.0, 0.01)
	_disco_progreso.visible = false

	_actualizar_etiqueta("Permanece 4s en el círculo")

func _process(delta: float) -> void:
	if _consumido or _modal_abierto:
		return

	if _cristal_superior != null:
		_cristal_superior.rotate_y(delta * 1.4)
		_cristal_superior.position.y = 2.55 + sin(Time.get_ticks_msec() * 0.004) * 0.10
	if _giro_anillo_a != null:
		_giro_anillo_a.rotate_y(delta * 2.1)
		_giro_anillo_a.rotate_z(delta * 0.9)
	if _giro_anillo_b != null:
		_giro_anillo_b.rotate_x(delta * 1.6)
		_giro_anillo_b.rotate_y(-delta * 1.3)

	var pj := _obtener_jugador()
	if pj == null:
		return

	var dist := _distancia_a_jugador(pj)
	var ring_mat := _anillo_externo.material_override as ShaderMaterial if _anillo_externo != null else null
	if dist <= RADIO_CARGA:
		_progreso = minf(_progreso + delta, TIEMPO_CARGA)
		var frac := clampf(_progreso / TIEMPO_CARGA, 0.02, 1.0)
		if ring_mat != null:
			ring_mat.set_shader_parameter("progress", clampf(_progreso / TIEMPO_CARGA, 0.0, 1.0))
			ring_mat.set_shader_parameter("active_state", 1.0)
		if _disco_progreso != null:
			_disco_progreso.visible = true
			_disco_progreso.scale = Vector3(frac, 1.0, frac)
		if luz != null:
			luz.light_energy = 2.4 + frac * 2.8
		_actualizar_etiqueta("⏳ Calibrando... %d%%" % int(round(frac * 100.0)))
		if _progreso >= TIEMPO_CARGA and not _hay_otro_modal_pausa_abierto():
			_abrir_modal_bendiciones(pj)
	else:
		if ring_mat != null:
			ring_mat.set_shader_parameter("progress", 0.0)
			ring_mat.set_shader_parameter("active_state", 0.0)
		if _progreso > 0.0:
			_progreso = 0.0
			if _disco_progreso != null:
				_disco_progreso.visible = false
				_disco_progreso.scale = Vector3(0.01, 1.0, 0.01)
			if luz != null:
				luz.light_energy = 2.4
			_actualizar_etiqueta("Permanece 4s en el círculo")

func _al_hacer_clic_pasivo(_pj: Node3D) -> void:
	_spawn_texto_3d("Quédate 4s en el círculo", Color(1.0, 0.88, 0.32))
	AudioManager.play("click", 0.95)

func _abrir_modal_bendiciones(pj: Node3D) -> void:
	if _modal_abierto or _consumido:
		return
	_modal_abierto = true
	AudioManager.play("altar_activado", 1.1)

	# Barajar opciones usando la semilla de FortunaManager
	var pool: Array = OPCIONES_STAT.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j: int = FortunaManager.rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 30
	_modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_layer.add_to_group("modales_santuario")
	get_tree().root.add_child(_modal_layer)

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.02, 0.04, 0.68)
	_modal_layer.add_child(fondo)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 340)
	panel.offset_left = -380
	panel.offset_top = -170
	panel.offset_right = 380
	panel.offset_bottom = 170
	panel.add_theme_stylebox_override("panel", _crear_panel_style(Color(0.95, 0.78, 0.25), Color(0.06, 0.07, 0.11, 0.97), 3, 14))
	fondo.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "🏛️ BENDICIÓN DE FORTUNA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "🛡 Protección anti-clic activa · Espera un instante..."
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 14)
	subtitulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.42))
	vbox.add_child(subtitulo)
	_subtitulo_modal = subtitulo

	_modal_apertura_msec = Time.get_ticks_msec()
	_modal_bloqueado_hasta_msec = _modal_apertura_msec + SELLO_GRACIA_INICIAL_MS
	fondo.gui_input.connect(func(ev: InputEvent):
		if Time.get_ticks_msec() < _modal_bloqueado_hasta_msec and ev is InputEventMouseButton and ev.pressed:
			_registrar_clic_sello_fortuna()
	)

	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	var hay_legendaria := false
	for i in range(3):
		var opc: Dictionary = pool[i]
		var r: int = FortunaManager.tirar_rareza()
		var mult: float = FortunaManager.obtener_multiplicador_rareza(r)
		var color_r: Color = Rareza.obtener_color(r)
		var nombre_r: String = Rareza.obtener_nombre(r)
		if r == Rareza.LEGENDARIO:
			hay_legendaria = true

		var val: float = float(opc["base"]) * mult
		var val_txt: String = String.num(val, int(opc["dec"]))

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(210, 190)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 17)
		btn.text = "[ %s ]\n\n%s\n\n%s\n(x%.1f)" % [
			nombre_r.to_upper(),
			String(opc["titulo"]),
			String(opc["desc"]) % val_txt,
			mult
		]
		_aplicar_estilo_boton_modal(btn, color_r)
		btn.pressed.connect(_elegir_bendicion.bind(pj, String(opc["id"]), String(opc["titulo"]), mult, r))
		hbox.add_child(btn)

	if hay_legendaria:
		AudioManager.play("legendario", 1.0)

	var tw_sello := _modal_layer.create_tween()
	tw_sello.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw_sello.tween_interval(float(SELLO_GRACIA_INICIAL_MS) * 0.001)
	tw_sello.tween_callback(_actualizar_texto_desbloqueo_fortuna)

	_pausar_por_modal()

func _registrar_clic_sello_fortuna() -> void:
	var ahora := Time.get_ticks_msec()
	if ahora >= _modal_apertura_msec + 140:
		var tope := _modal_apertura_msec + SELLO_MAX_TOTAL_MS
		_modal_bloqueado_hasta_msec = mini(tope, maxi(_modal_bloqueado_hasta_msec, ahora + SELLO_REBOTE_SPAM_MS))
	if _subtitulo_modal != null and is_instance_valid(_subtitulo_modal):
		var restante := maxf(0.05, float(_modal_bloqueado_hasta_msec - ahora) * 0.001)
		_subtitulo_modal.text = "⚡ Clic bloqueado por seguridad (%.2fs)..." % restante
		_subtitulo_modal.add_theme_color_override("font_color", Color(1.0, 0.65, 0.42))
	if _modal_layer != null and is_instance_valid(_modal_layer):
		var tw_recheck := _modal_layer.create_tween()
		tw_recheck.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_recheck.tween_interval(maxf(0.05, float(_modal_bloqueado_hasta_msec - Time.get_ticks_msec()) * 0.001 + 0.02))
		tw_recheck.tween_callback(_actualizar_texto_desbloqueo_fortuna)

func _actualizar_texto_desbloqueo_fortuna() -> void:
	if _subtitulo_modal == null or not is_instance_valid(_subtitulo_modal):
		return
	if Time.get_ticks_msec() >= _modal_bloqueado_hasta_msec:
		_subtitulo_modal.text = "✦ Listo — Elige una gracia del Coliseo (escalada por tu Suerte)"
		_subtitulo_modal.add_theme_color_override("font_color", Color(0.76, 0.96, 0.86))

func _elegir_bendicion(pj: Node3D, id_stat: String, titulo_stat: String, mult: float, rareza: int) -> void:
	if Time.get_ticks_msec() < _modal_bloqueado_hasta_msec:
		_registrar_clic_sello_fortuna()
		return
	if _modal_layer != null and is_instance_valid(_modal_layer):
		_modal_layer.visible = false
		_modal_layer.remove_from_group("modales_santuario")
		_modal_layer.queue_free()
		_modal_layer = null
	if pj != null and is_instance_valid(pj) and pj.has_method("aplicar_mejora"):
		pj.aplicar_mejora(id_stat, mult)
	AudioManager.play("puzzle_completo", 1.1)
	_spawn_texto_3d("%s [%s]" % [titulo_stat, Rareza.obtener_nombre(rareza)], Rareza.obtener_color(rareza))
	_restaurar_pausa_segura()
	_consumir()

func _exit_tree() -> void:
	if _modal_layer != null and is_instance_valid(_modal_layer):
		_modal_layer.visible = false
		_modal_layer.remove_from_group("modales_santuario")
		_modal_layer.queue_free()
		_modal_layer = null
		_restaurar_pausa_segura()
