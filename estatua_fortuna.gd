extends "res://santuario_base.gd"
class_name EstatuaFortuna

## EstatuaFortuna - Santuario de Carga por Proximidad (Estatua dorada del Coliseo).
## El jugador permanece dentro de su anillo de 3.0 m durante 4.0 s (se reinicia al salir).
## Al completarse, despliega 3 cartas de mejora con rareza sorteada por FortunaManager.

const RADIO_CARGA: float = 3.0
const TIEMPO_CARGA: float = 4.0

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
var _modal_layer: CanvasLayer = null

func _configurar_santuario() -> void:
	nombre_santuario = "Estatua de Fortuna"
	costo_denarios = 0
	radio_interaccion = RADIO_CARGA
	un_solo_uso = true
	activacion_por_clic = false
	color_luz = Color(1.0, 0.86, 0.30)
	altura_etiqueta = 3.6

func _construir_visual() -> void:
	# Base octogonal / escalonada de mármol
	var zocalo := MeshInstance3D.new()
	var m_zocalo := CylinderMesh.new()
	m_zocalo.top_radius = 1.05
	m_zocalo.bottom_radius = 1.25
	m_zocalo.height = 0.35
	m_zocalo.radial_segments = 8
	m_zocalo.material = _crear_material(Color(0.86, 0.82, 0.74), Color(0.2, 0.16, 0.05), 0.15, 0.15, 0.65)
	zocalo.mesh = m_zocalo
	zocalo.position = Vector3(0.0, 0.175, 0.0)
	visual_root.add_child(zocalo)

	# Columna / Obelisco dorado central
	var columna := MeshInstance3D.new()
	var m_col := CylinderMesh.new()
	m_col.top_radius = 0.42
	m_col.bottom_radius = 0.62
	m_col.height = 1.75
	m_col.radial_segments = 8
	m_col.material = _crear_material(Color(0.95, 0.78, 0.25), Color(1.0, 0.82, 0.22), 0.55, 0.75, 0.25)
	columna.mesh = m_col
	columna.position = Vector3(0.0, 1.2, 0.0)
	visual_root.add_child(columna)

	# Corona flotante dorada legible desde arriba
	_cristal_superior = MeshInstance3D.new()
	var m_cris := PrismMesh.new()
	m_cris.size = Vector3(0.75, 0.85, 0.75)
	m_cris.material = _crear_material(Color(1.0, 0.92, 0.35), Color(1.0, 0.88, 0.25), 1.4, 0.85, 0.15)
	_cristal_superior.mesh = m_cris
	_cristal_superior.position = Vector3(0.0, 2.55, 0.0)
	visual_root.add_child(_cristal_superior)

	# Anillo delimitador en el suelo (radio exacto de 3.0 m)
	_anillo_externo = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIO_CARGA - 0.12
	torus.outer_radius = RADIO_CARGA + 0.06
	torus.rings = 40
	torus.ring_segments = 12
	var mat_anillo := _crear_material(Color(1.0, 0.84, 0.25, 0.85), Color(1.0, 0.82, 0.20), 1.2, 0.4, 0.3)
	mat_anillo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = mat_anillo
	_anillo_externo.mesh = torus
	_anillo_externo.position = Vector3(0.0, 0.05, 0.0)
	visual_root.add_child(_anillo_externo)

	# Disco de progreso interior que crece de 0 a 100 %
	_disco_progreso = MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = RADIO_CARGA - 0.15
	disco.bottom_radius = RADIO_CARGA - 0.15
	disco.height = 0.03
	disco.radial_segments = 36
	var mat_disco := _crear_material(Color(1.0, 0.88, 0.28, 0.28), Color(1.0, 0.86, 0.22), 0.9, 0.2, 0.4)
	mat_disco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disco.material = mat_disco
	_disco_progreso.mesh = disco
	_disco_progreso.position = Vector3(0.0, 0.03, 0.0)
	_disco_progreso.scale = Vector3(0.01, 1.0, 0.01)
	_disco_progreso.visible = false
	visual_root.add_child(_disco_progreso)

	_actualizar_etiqueta("Permanece 4s en el círculo")

func _process(delta: float) -> void:
	if _consumido or _modal_abierto:
		return

	if _cristal_superior != null:
		_cristal_superior.rotate_y(delta * 1.4)
		_cristal_superior.position.y = 2.55 + sin(Time.get_ticks_msec() * 0.004) * 0.12

	var pj := _obtener_jugador()
	if pj == null:
		return

	var dist := _distancia_a_jugador(pj)
	if dist <= RADIO_CARGA:
		_progreso = minf(_progreso + delta, TIEMPO_CARGA)
		var frac := clampf(_progreso / TIEMPO_CARGA, 0.02, 1.0)
		if _disco_progreso != null:
			_disco_progreso.visible = true
			_disco_progreso.scale = Vector3(frac, 1.0, frac)
		if luz != null:
			luz.light_energy = 2.4 + frac * 2.8
		_actualizar_etiqueta("⏳ Consagrando... %d%%" % int(round(frac * 100.0)))
		if _progreso >= TIEMPO_CARGA and not _hay_otro_modal_pausa_abierto():
			_abrir_modal_bendiciones(pj)
	elif _progreso > 0.0:
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
	subtitulo.text = "Elige una gracia del Coliseo (escalada por tu Suerte)"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 14)
	subtitulo.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	vbox.add_child(subtitulo)

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

	_pausar_por_modal()

func _elegir_bendicion(pj: Node3D, id_stat: String, titulo_stat: String, mult: float, rareza: int) -> void:
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
