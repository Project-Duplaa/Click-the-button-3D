class_name AltarTormentoChasis
extends CanvasLayer

## AltarTormentoChasis - Altar Pre-Run de Configuración Táctica
## Permite al gladiador ajustar el Nivel de Tormento (0..10), equipar el Chasis de Núcleo
## (Estándar, Gravitatorio, Cometa) o iniciar el Desafío Diario antes de dar el primer clic al Núcleo.
## Se desvanece de inmediato en cuanto se detecta el primer clic en la arena.

const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const AudioManager = preload("res://audio_manager.gd")

var panel_raiz: PanelContainer = null
var lbl_tormento: Label = null
var btn_tormento_menos: Button = null
var btn_tormento_mas: Button = null

var btn_chasis_estandar: Button = null
var btn_chasis_gravitatorio: Button = null
var btn_chasis_cometa: Button = null

var btn_diaria: Button = null
var lbl_pista_inicio: Label = null

var nivel_tormento: int = 0
var chasis_seleccionado: String = "estandar"
var es_diaria_activa: bool = false
var ya_desvanecido: bool = false

func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("altar_tormento_chasis")

	_leer_estado_inicial()
	_construir_ui()
	_conectar_senales_juego()
	_actualizar_interfaz_completa()

func _process(_delta: float) -> void:
	if ya_desvanecido:
		return
	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null:
		var clicks := 0
		if "total_clicks" in boton:
			clicks = int(boton.total_clicks)
		elif "clics_recibidos" in boton:
			clicks = int(boton.clics_recibidos)
		if clicks > 0:
			_desvanecer_y_ocultar()
			return

	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null and "clicks_boton" in hud and int(hud.clicks_boton) > 0:
		_desvanecer_y_ocultar()
		return

func _leer_estado_inicial() -> void:
	MetaprogresoManager.asegurar_inicializado()
	chasis_seleccionado = str(MetaprogresoManager.chasis_equipado)
	if chasis_seleccionado == "":
		chasis_seleccionado = "estandar"

	var logros = get_tree().get_first_node_in_group("logros_manager")
	if logros != null and logros.has_method("obtener_tormento"):
		nivel_tormento = int(logros.obtener_tormento())
	else:
		nivel_tormento = 0

func _construir_ui() -> void:
	var control_base = Control.new()
	control_base.name = "ControlAltar"
	control_base.set_anchors_preset(Control.PRESET_FULL_RECT)
	control_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control_base)

	panel_raiz = PanelContainer.new()
	panel_raiz.name = "PanelAltarTormento"
	panel_raiz.mouse_filter = Control.MOUSE_FILTER_STOP

	# Centrado en tercio inferior: bottom - 95px a bottom - 25px (ancho 660px)
	panel_raiz.anchor_left = 0.5
	panel_raiz.anchor_right = 0.5
	panel_raiz.anchor_top = 1.0
	panel_raiz.anchor_bottom = 1.0
	panel_raiz.offset_left = -345.0
	panel_raiz.offset_right = 345.0
	panel_raiz.offset_top = -95.0
	panel_raiz.offset_bottom = -25.0
	panel_raiz.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_raiz.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.050, 0.080, 0.94)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.72, 0.56, 0.28, 0.95)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.70)
	sb.shadow_size = 8
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	panel_raiz.add_theme_stylebox_override("panel", sb)
	control_base.add_child(panel_raiz)

	var vbox_interior = VBoxContainer.new()
	vbox_interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_interior.add_theme_constant_override("separation", 4)
	panel_raiz.add_child(vbox_interior)

	# Fila superior de controles interactivos
	var hbox_controles = HBoxContainer.new()
	hbox_controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_controles.add_theme_constant_override("separation", 8)
	hbox_controles.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_interior.add_child(hbox_controles)

	# --- 1. TORMENTO (0..10) ---
	btn_tormento_menos = _crear_boton_mini("-", "Disminuir Tormento")
	btn_tormento_menos.pressed.connect(_on_tormento_menos_pressed)
	hbox_controles.add_child(btn_tormento_menos)

	lbl_tormento = Label.new()
	lbl_tormento.custom_minimum_size = Vector2(185, 24)
	lbl_tormento.add_theme_font_size_override("font_size", 11)
	lbl_tormento.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	lbl_tormento.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.02))
	lbl_tormento.add_theme_constant_override("outline_size", 2)
	lbl_tormento.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tormento.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_tormento.text = "🔥 TORMENTO 0 (+0% Botín)"
	hbox_controles.add_child(lbl_tormento)

	btn_tormento_mas = _crear_boton_mini("+", "Aumentar Tormento (Mayor dificultad, botín y suerte)")
	btn_tormento_mas.pressed.connect(_on_tormento_mas_pressed)
	hbox_controles.add_child(btn_tormento_mas)

	hbox_controles.add_child(_crear_separador_vertical())

	# --- 2. CHASIS DE NÚCLEO (3) ---
	btn_chasis_estandar = _crear_boton_chasis("⚙️ Estándar", "Chasis balanceado con pulsos uniformes de resonancia.")
	btn_chasis_estandar.pressed.connect(func(): _seleccionar_chasis("estandar"))
	hbox_controles.add_child(btn_chasis_estandar)

	btn_chasis_gravitatorio = _crear_boton_chasis("🧲 Gravitatorio", "Atrae orbes y desata pulsos de vacío centrípetos.")
	btn_chasis_gravitatorio.pressed.connect(func(): _seleccionar_chasis("gravitatorio"))
	hbox_controles.add_child(btn_chasis_gravitatorio)

	btn_chasis_cometa = _crear_boton_chasis("☄️ Cometa", "Alta velocidad orbital con estela ígnea que carboniza enemigos.")
	btn_chasis_cometa.pressed.connect(func(): _seleccionar_chasis("cometa"))
	hbox_controles.add_child(btn_chasis_cometa)

	hbox_controles.add_child(_crear_separador_vertical())

	# --- 3. PARTIDA DIARIA ---
	btn_diaria = Button.new()
	btn_diaria.name = "BtnPartidaDiaria"
	btn_diaria.text = "🗓️ DIARIA"
	btn_diaria.custom_minimum_size = Vector2(92, 26)
	btn_diaria.focus_mode = Control.FOCUS_NONE
	btn_diaria.add_theme_font_size_override("font_size", 10)
	btn_diaria.tooltip_text = "Desafío del Día: Semilla fija, chasis y mutador idénticos para todos los gladiadores."
	btn_diaria.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.24, 0.16, 0.36, 0.90), Color(0.68, 0.42, 0.96)))
	btn_diaria.add_theme_stylebox_override("hover", _crear_style_boton(Color(0.36, 0.22, 0.54, 1.0), Color(0.85, 0.60, 1.0)))
	btn_diaria.pressed.connect(_on_btn_diaria_pressed)
	hbox_controles.add_child(btn_diaria)

	# Fila inferior: indicación sutil
	lbl_pista_inicio = Label.new()
	lbl_pista_inicio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_pista_inicio.add_theme_font_size_override("font_size", 9)
	lbl_pista_inicio.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84, 0.75))
	lbl_pista_inicio.text = "Haz clic en el Núcleo Rúnico para bloquear la configuración y comenzar el combate"
	vbox_interior.add_child(lbl_pista_inicio)

func _crear_boton_mini(txt: String, tooltip: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(22, 22)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	btn.tooltip_text = tooltip
	btn.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.12, 0.10, 0.18, 0.95), Color(0.70, 0.54, 0.28)))
	btn.add_theme_stylebox_override("hover", _crear_style_boton(Color(0.22, 0.18, 0.30, 1.0), Color(0.95, 0.78, 0.40)))
	return btn

func _crear_boton_chasis(txt: String, tooltip: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(92, 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 10)
	btn.tooltip_text = tooltip
	btn.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.08, 0.08, 0.12, 0.90), Color(0.40, 0.36, 0.30)))
	btn.add_theme_stylebox_override("hover", _crear_style_boton(Color(0.16, 0.15, 0.22, 1.0), Color(0.75, 0.65, 0.45)))
	return btn

func _crear_separador_vertical() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(6, 20)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sep

func _crear_style_boton(bg: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = borde
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4
	s.content_margin_left = 4.0
	s.content_margin_right = 4.0
	s.content_margin_top = 2.0
	s.content_margin_bottom = 2.0
	return s

func _conectar_senales_juego() -> void:
	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null:
		if boton.has_signal("click_presionado") and not boton.click_presionado.is_connected(_on_primer_clic_detectado):
			boton.click_presionado.connect(_on_primer_clic_detectado)

	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null and pj.has_signal("economia_actualizada"):
		if not pj.economia_actualizada.is_connected(_on_economia_jugador_actualizada):
			pj.economia_actualizada.connect(_on_economia_jugador_actualizada)

func _on_primer_clic_detectado(_total: int) -> void:
	_desvanecer_y_ocultar()

func _on_economia_jugador_actualizada(_oro: int, _clics_disp: int, clics_tot: int) -> void:
	if clics_tot > 0:
		_desvanecer_y_ocultar()

func _desvanecer_y_ocultar() -> void:
	if ya_desvanecido:
		return
	ya_desvanecido = true
	if panel_raiz == null or not is_instance_valid(panel_raiz):
		visible = false
		return

	panel_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in panel_raiz.find_children("", "Control", true, false):
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel_raiz, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(panel_raiz, "position:y", panel_raiz.position.y + 25.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		visible = false
	)

func _on_tormento_menos_pressed() -> void:
	if nivel_tormento > 0:
		AudioManager.play("click", 1.1)
		nivel_tormento -= 1
		_aplicar_tormento()

func _on_tormento_mas_pressed() -> void:
	if nivel_tormento < 10:
		AudioManager.play("click", 1.3)
		nivel_tormento += 1
		_aplicar_tormento()

func _aplicar_tormento() -> void:
	var logros = get_tree().get_first_node_in_group("logros_manager")
	if logros != null and logros.has_method("establecer_tormento"):
		logros.establecer_tormento(nivel_tormento)
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null and pj.has_method("recalcular_stats_incrementales"):
		pj.recalcular_stats_incrementales()
	if FortunaManager != null and FortunaManager.has_method("obtener_suerte_efectiva"):
		FortunaManager.suerte_cambiada.emit(FortunaManager.obtener_suerte_efectiva())
	_actualizar_etiqueta_tormento()

func _actualizar_etiqueta_tormento() -> void:
	if lbl_tormento == null:
		return
	var bonus_oro := nivel_tormento * 25
	var bonus_suerte := nivel_tormento * 20
	if nivel_tormento == 0:
		lbl_tormento.text = "🔥 TORMENTO 0 (+0% Botín)"
		lbl_tormento.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	else:
		lbl_tormento.text = "🔥 TORMENTO %d (+%d%% Oro/⚡ · +%d%% 🍀)" % [nivel_tormento, bonus_oro, bonus_suerte]
		lbl_tormento.add_theme_color_override("font_color", Color(1.0, 0.45 + float(10 - nivel_tormento) * 0.04, 0.20))

func _seleccionar_chasis(id: String) -> void:
	if not _esta_chasis_desbloqueado(id):
		AudioManager.play("click", 0.8)
		return

	AudioManager.play("click", 1.25)
	chasis_seleccionado = id

	MetaprogresoManager.asegurar_inicializado()
	MetaprogresoManager.chasis_equipado = id
	MetaprogresoManager.guardar()

	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null and boton.has_method("aplicar_chasis"):
		boton.aplicar_chasis(id)

	_actualizar_botones_chasis()

func _esta_chasis_desbloqueado(id: String) -> bool:
	if id == "estandar":
		return true
	MetaprogresoManager.asegurar_inicializado()
	var list = MetaprogresoManager.chasis_desbloqueados
	if list is Array and list.has(id):
		return true
	if id == "gravitatorio" and int(MetaprogresoManager.runs_jugadas) >= 1:
		return true
	if id == "cometa" and int(MetaprogresoManager.runs_jugadas) >= 2:
		return true
	return false

func _actualizar_botones_chasis() -> void:
	var mapeo := {
		"estandar": btn_chasis_estandar,
		"gravitatorio": btn_chasis_gravitatorio,
		"cometa": btn_chasis_cometa
	}
	for k in mapeo.keys():
		var id_key: String = str(k)
		var btn: Button = mapeo[k]
		if btn == null:
			continue
		var desbloqueado: bool = _esta_chasis_desbloqueado(id_key) or (es_diaria_activa and id_key == chasis_seleccionado)
		if not desbloqueado:
			btn.disabled = true
			btn.tooltip_text = "🔒 Bloqueado: Completa runs previas para forjar este Chasis."
			btn.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.04, 0.04, 0.06, 0.80), Color(0.20, 0.20, 0.22)))
			continue

		btn.disabled = false
		if id_key == chasis_seleccionado:
			btn.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.20, 0.16, 0.08, 0.95), Color(1.0, 0.84, 0.28)))
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
		else:
			btn.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.08, 0.08, 0.12, 0.90), Color(0.40, 0.36, 0.30)))
			btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))

func _on_btn_diaria_pressed() -> void:
	AudioManager.play("victoria", 1.1)
	es_diaria_activa = true
	var semilla := 0
	if FortunaManager != null and FortunaManager.has_method("iniciar_run_diaria"):
		semilla = FortunaManager.iniciar_run_diaria()
	else:
		var d := Time.get_date_dict_from_system()
		semilla = int(d.get("year", 2026)) * 10000 + int(d.get("month", 1)) * 100 + int(d.get("day", 1))
		if FortunaManager != null:
			FortunaManager.iniciar_run(semilla)
			if "es_run_diaria" in FortunaManager:
				FortunaManager.es_run_diaria = true

	var chasis_opciones := ["estandar", "gravitatorio", "cometa"]
	var chasis_dia: String = chasis_opciones[absi(semilla) % chasis_opciones.size()]
	chasis_seleccionado = chasis_dia
	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null and boton.has_method("aplicar_chasis"):
		boton.aplicar_chasis(chasis_dia)
	_actualizar_botones_chasis()

	var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
	if eventos != null and eventos.has_method("forzar_mutador_diario"):
		eventos.forzar_mutador_diario(semilla)

	if btn_diaria != null:
		btn_diaria.text = "🗓️ DIARIA (%d)" % (semilla % 100000)
		btn_diaria.add_theme_stylebox_override("normal", _crear_style_boton(Color(0.38, 0.18, 0.55, 0.95), Color(1.0, 0.85, 0.30)))
		var tw := btn_diaria.create_tween().set_loops(3)
		tw.tween_property(btn_diaria, "modulate", Color(1.2, 1.2, 1.4), 0.25)
		tw.tween_property(btn_diaria, "modulate", Color.WHITE, 0.25)

func _actualizar_interfaz_completa() -> void:
	_actualizar_etiqueta_tormento()
	_actualizar_botones_chasis()
