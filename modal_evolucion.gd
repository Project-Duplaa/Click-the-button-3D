class_name ModalEvolucion
extends CanvasLayer

## ModalEvolucion - Modal 2D Dinámico de Respaldo (Tier 1, Tier 2 y Tier 3)
## Comparte la misma fuente de verdad que EvolucionRadial / ControlRadial y
## construye dinámicamente las tarjetas de evolución sin nodos hardcodeados.

signal clase_seleccionada(nombre_clase: String)

const SELLO_GRACIA_INICIAL_MS: int = 850
const SELLO_REBOTE_SPAM_MS: int = 350
const SELLO_MAX_TOTAL_MS: int = 1900

const COLOR_ORO_BORDE: Color = Color(0.95, 0.78, 0.36, 1.0)

const TIER_ESTILOS: Dictionary = {
	1: {
		"titulo": "⚡ METAMORFOSIS DE CLASE — TIER 1 ⚡",
		"subtitulo": "Has superado el rango de Recluta. Elige tu clase y estilo de combate:",
		"color_acento": Color(0.95, 0.78, 0.36, 1.0),
		"color_fondo": Color(0.06, 0.08, 0.13, 0.96),
		"verbo_boton": "⚡ Evolucionar"
	},
	2: {
		"titulo": "⚔️ ASCENSIÓN DE SUBCLASE — TIER 2 ⚔️",
		"subtitulo": "Arquetipo %s dominado. Selecciona tu especialización de la arena:",
		"color_acento": Color(1.0, 0.82, 0.22, 1.0),
		"color_fondo": Color(0.08, 0.06, 0.14, 0.97),
		"verbo_boton": "⚔️ Ascender"
	},
	3: {
		"titulo": "👑 ASCENSIÓN DEFINITIVA — TIER 3 👑",
		"subtitulo": "Pináculo de %s alcanzado. Desata tu forma suprema definitiva:",
		"color_acento": Color(0.42, 0.88, 1.0, 1.0),
		"color_fondo": Color(0.05, 0.07, 0.16, 0.98),
		"verbo_boton": "👑 Trascender"
	}
}

var tier_actual: int = 1
var clase_base_actual: String = "Murmillo"
var opciones_activas: Array[String] = []

var _custom_configs: Dictionary = {}
var _abierto: bool = false
var _apertura_msec: int = 0
var _bloqueado_hasta_msec: int = 0
var _pausado_previo: bool = false
var _gestiono_pausa: bool = false
var _estado_sello_bloqueado_prev: bool = false
var _tween_entrada: Tween = null
var _botones_tarjetas: Array[Dictionary] = []

var _panel_principal: Panel = null
var _lbl_titulo: Label = null
var _lbl_subtitulo: Label = null
var _hbox_cartas: HBoxContainer = null
var _lbl_hint_teclas: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_asegurar_referencias_ui()
	if opciones_activas.is_empty():
		configurar_modo_tier(tier_actual, clase_base_actual)
	else:
		_reconstruir_ui()
	if not _abierto:
		visible = false

func _exit_tree() -> void:
	if _tween_entrada != null and _tween_entrada.is_valid():
		_tween_entrada.kill()
		_tween_entrada = null
	_restaurar_pausa_segura()

func _asegurar_referencias_ui() -> bool:
	if _panel_principal == null:
		_panel_principal = get_node_or_null("Control/Panel") as Panel
	if _lbl_titulo == null:
		_lbl_titulo = get_node_or_null("Control/Panel/Margin/VBox/Titulo") as Label
	if _lbl_subtitulo == null:
		_lbl_subtitulo = get_node_or_null("Control/Panel/Margin/VBox/Subtitulo") as Label
	if _hbox_cartas == null:
		_hbox_cartas = get_node_or_null("Control/Panel/Margin/VBox/HBoxCartas") as HBoxContainer
	if _lbl_hint_teclas == null:
		_lbl_hint_teclas = get_node_or_null("Control/Panel/Margin/VBox/HintTeclas") as Label
	return _hbox_cartas != null

## Interfaz polimórfica idéntica a EvolucionRadial
func configurar_modo_tier(tier: int, clase_base: String = "Murmillo") -> void:
	tier_actual = maxi(1, tier)
	clase_base_actual = _normalizar_clase_base(clase_base)
	var lista := _resolver_opciones_por_tier(tier_actual, clase_base_actual)
	opciones_activas.clear()
	for op in lista:
		var nombre := str(op).strip_edges()
		if not nombre.is_empty():
			opciones_activas.append(nombre)
	if _asegurar_referencias_ui():
		_reconstruir_ui()

## Interfaz polimórfica idéntica a EvolucionRadial (soporta 2, 3 o más opciones)
func configurar_opciones(lista_opciones: Array, configs: Dictionary = {}) -> void:
	opciones_activas.clear()
	for op in lista_opciones:
		var nombre := str(op).strip_edges()
		if not nombre.is_empty():
			opciones_activas.append(nombre)
	for k in configs.keys():
		_custom_configs[str(k)] = configs[k]
	if _asegurar_referencias_ui():
		_reconstruir_ui()

func abrir() -> void:
	_asegurar_referencias_ui()
	if opciones_activas.is_empty():
		configurar_modo_tier(tier_actual, clase_base_actual)
	elif _hbox_cartas != null and _hbox_cartas.get_child_count() == 0:
		_reconstruir_ui()

	_apertura_msec = Time.get_ticks_msec()
	_bloqueado_hasta_msec = _apertura_msec + SELLO_GRACIA_INICIAL_MS
	_estado_sello_bloqueado_prev = false

	var tree := get_tree()
	if tree != null and not _gestiono_pausa:
		_pausado_previo = tree.paused
		_gestiono_pausa = true
		tree.paused = true

	_abierto = true
	visible = true
	_actualizar_estado_botones_sello(true)
	_animar_entrada()

func cerrar() -> void:
	if _tween_entrada != null and _tween_entrada.is_valid():
		_tween_entrada.kill()
		_tween_entrada = null
	_abierto = false
	visible = false
	_restaurar_pausa_segura()

func _restaurar_pausa_segura() -> void:
	if not _gestiono_pausa:
		return
	_gestiono_pausa = false
	var tree := get_tree()
	if tree != null:
		tree.paused = _pausado_previo

func _process(_delta: float) -> void:
	if not _abierto:
		return
	_actualizar_estado_botones_sello(false)

func _input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := _indice_desde_tecla(event.keycode)
		if idx >= 0 and idx < opciones_activas.size():
			_on_seleccionar(opciones_activas[idx])
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ahora := Time.get_ticks_msec()
		if ahora < _bloqueado_hasta_msec:
			_registrar_rebote_spam(ahora)
			_actualizar_estado_botones_sello(true)
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()

func _indice_desde_tecla(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return int(keycode) - int(KEY_1)
	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return int(keycode) - int(KEY_KP_1)
	return -1

func _registrar_rebote_spam(ahora: int) -> void:
	if ahora >= _apertura_msec + 140:
		_bloqueado_hasta_msec = mini(
			_apertura_msec + SELLO_MAX_TOTAL_MS,
			maxi(_bloqueado_hasta_msec, ahora + SELLO_REBOTE_SPAM_MS)
		)

func _on_seleccionar(clase: String) -> void:
	if not _abierto:
		return
	var ahora := Time.get_ticks_msec()
	if ahora < _bloqueado_hasta_msec:
		_registrar_rebote_spam(ahora)
		_actualizar_estado_botones_sello(true)
		return
	cerrar()
	emit_signal("clase_seleccionada", clase)

func _actualizar_estado_botones_sello(forzar_estilos: bool) -> void:
	var ahora := Time.get_ticks_msec()
	var bloqueado := ahora < _bloqueado_hasta_msec
	var restante_seg := maxf(0.1, float(_bloqueado_hasta_msec - ahora) / 1000.0)
	var txt_bloqueo := "🛡 Espera %.1fs..." % restante_seg

	for entry in _botones_tarjetas:
		var btn: Button = entry["boton"]
		if not is_instance_valid(btn):
			continue
		if bloqueado:
			btn.text = txt_bloqueo
			if forzar_estilos or not _estado_sello_bloqueado_prev:
				var sb_bloq: StyleBoxFlat = entry["style_bloqueado"]
				btn.add_theme_stylebox_override("normal", sb_bloq)
				btn.add_theme_stylebox_override("hover", sb_bloq)
				btn.add_theme_stylebox_override("pressed", sb_bloq)
				btn.add_theme_color_override("font_color", Color(0.76, 0.78, 0.84, 0.9))
				btn.add_theme_color_override("font_hover_color", Color(0.76, 0.78, 0.84, 0.9))
				btn.add_theme_color_override("font_pressed_color", Color(0.76, 0.78, 0.84, 0.9))
		elif forzar_estilos or _estado_sello_bloqueado_prev:
			btn.text = str(entry["texto_activo"])
			btn.add_theme_stylebox_override("normal", entry["style_normal"])
			btn.add_theme_stylebox_override("hover", entry["style_hover"])
			btn.add_theme_stylebox_override("pressed", entry["style_pressed"])
			btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.95, 0.95, 1.0))

	_estado_sello_bloqueado_prev = bloqueado

func _animar_entrada() -> void:
	if _panel_principal == null:
		return
	if _tween_entrada != null and _tween_entrada.is_valid():
		_tween_entrada.kill()
	_panel_principal.modulate.a = 0.0
	_tween_entrada = create_tween()
	_tween_entrada.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_entrada.tween_property(_panel_principal, "modulate:a", 1.0, 0.16)

func _normalizar_clase_base(clase_base: String) -> String:
	var limpia := clase_base.strip_edges()
	if limpia == "Arquero":
		return "Sagittario"
	if limpia.is_empty() or limpia == "Novato" or limpia == "Recluta del Coliseo":
		return "Murmillo"
	if EvolucionManager.OPCIONES_TIER2.has(limpia) or EvolucionManager.OPCIONES_TIER3.has(limpia):
		return limpia
	if EvolucionManager.SUBCLASES_TIER2.has(limpia):
		return str(EvolucionManager.SUBCLASES_TIER2[limpia].get("clase_base", "Murmillo"))
	if EvolucionManager.SUBCLASES_TIER3.has(limpia):
		return str(EvolucionManager.SUBCLASES_TIER3[limpia].get("clase_base", "Murmillo"))
	return limpia

func _resolver_opciones_por_tier(tier: int, clase_base: String) -> Array:
	if tier <= 1:
		return EvolucionManager.OPCIONES_TIER1

	if tier == 2:
		if EvolucionManager.OPCIONES_TIER2.has(clase_base):
			return EvolucionManager.OPCIONES_TIER2[clase_base]
		return EvolucionManager.OPCIONES_TIER2.get(
			"Murmillo",
			["Secutor Radiante", "Provocator Sangriento", "Custodio del Núcleo"]
		)

	if EvolucionManager.OPCIONES_TIER3.has(clase_base):
		return EvolucionManager.OPCIONES_TIER3[clase_base]
	return EvolucionManager.OPCIONES_TIER3.get(
		"Murmillo",
		["Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Titán Supremo del Núcleo"]
	)

func _reconstruir_ui() -> void:
	if not _asegurar_referencias_ui():
		return

	_aplicar_estilo_encabezado_y_panel()
	_ajustar_tamano_panel()
	_limpiar_cartas()

	for i in range(opciones_activas.size()):
		var nombre_opcion := opciones_activas[i]
		var cfg := _obtener_config_opcion(nombre_opcion)
		var card := _crear_tarjeta_opcion(nombre_opcion, cfg, i)
		_hbox_cartas.add_child(card)

	_actualizar_hint_teclas()
	if _abierto:
		_actualizar_estado_botones_sello(true)

func _obtener_estilo_tier(tier: int) -> Dictionary:
	var clave := clampi(tier, 1, 3)
	return TIER_ESTILOS.get(clave, TIER_ESTILOS[1])

func _aplicar_estilo_encabezado_y_panel() -> void:
	var estilo := _obtener_estilo_tier(tier_actual)
	var col_acento: Color = estilo["color_acento"]
	var col_fondo: Color = estilo["color_fondo"]

	if _lbl_titulo != null:
		_lbl_titulo.text = str(estilo["titulo"])
		_lbl_titulo.add_theme_color_override("font_color", col_acento.lerp(Color.WHITE, 0.25))

	if _lbl_subtitulo != null:
		var sub_tpl: String = str(estilo["subtitulo"])
		if sub_tpl.contains("%s"):
			_lbl_subtitulo.text = sub_tpl % clase_base_actual
		else:
			_lbl_subtitulo.text = sub_tpl

	if _panel_principal != null:
		var sb_panel := StyleBoxFlat.new()
		sb_panel.bg_color = col_fondo
		sb_panel.border_color = col_acento
		sb_panel.set_border_width_all(3)
		sb_panel.set_corner_radius_all(18)
		sb_panel.shadow_color = Color(col_acento.r, col_acento.g, col_acento.b, 0.32)
		sb_panel.shadow_size = 24
		_panel_principal.add_theme_stylebox_override("panel", sb_panel)

func _ajustar_tamano_panel() -> void:
	if _panel_principal == null:
		return
	var num_ops := maxi(1, opciones_activas.size())
	var ancho_objetivo: float = 1000.0
	if num_ops == 1:
		ancho_objetivo = 460.0
	elif num_ops == 2:
		ancho_objetivo = 740.0
	elif num_ops == 3:
		ancho_objetivo = 1000.0
	else:
		ancho_objetivo = minf(1180.0, 275.0 * float(num_ops) + 80.0)

	var medio_ancho := ancho_objetivo * 0.5
	_panel_principal.offset_left = -medio_ancho
	_panel_principal.offset_right = medio_ancho
	_panel_principal.offset_top = -270.0
	_panel_principal.offset_bottom = 270.0

func _actualizar_hint_teclas() -> void:
	if _lbl_hint_teclas == null:
		return
	var teclas: PackedStringArray = PackedStringArray()
	var max_teclas := mini(9, opciones_activas.size())
	for i in range(max_teclas):
		teclas.append("[%d]" % (i + 1))
	if teclas.is_empty():
		_lbl_hint_teclas.text = "Haz clic en una tarjeta para confirmar tu evolución"
	else:
		_lbl_hint_teclas.text = "⌨️ Atajos rápidos: teclas %s o haz clic en tu elección" % " ".join(teclas)

func _limpiar_cartas() -> void:
	_botones_tarjetas.clear()
	if _hbox_cartas == null:
		return
	var hijos := _hbox_cartas.get_children()
	for hijo in hijos:
		_hbox_cartas.remove_child(hijo)
		hijo.queue_free()

func _obtener_datos_fallback_manager(nombre_opcion: String) -> Dictionary:
	if EvolucionManager.SUBCLASES_TIER3.has(nombre_opcion):
		return EvolucionManager.SUBCLASES_TIER3[nombre_opcion]
	if EvolucionManager.SUBCLASES_TIER2.has(nombre_opcion):
		return EvolucionManager.SUBCLASES_TIER2[nombre_opcion]
	if EvolucionManager.STATS_CLASE.has(nombre_opcion):
		return EvolucionManager.STATS_CLASE[nombre_opcion]
	return {}

func _obtener_config_opcion(nombre_opcion: String) -> Dictionary:
	var cfg_primaria: Dictionary = {}
	if _custom_configs.has(nombre_opcion) and _custom_configs[nombre_opcion] is Dictionary:
		cfg_primaria = _custom_configs[nombre_opcion]
	elif ControlRadial.CONFIG_CLASES.has(nombre_opcion):
		cfg_primaria = ControlRadial.CONFIG_CLASES[nombre_opcion]

	var fallback: Dictionary = _obtener_datos_fallback_manager(nombre_opcion)
	var estilo_tier := _obtener_estilo_tier(tier_actual)

	var col_defecto: Color = estilo_tier["color_acento"]
	var color_acento: Color = cfg_primaria.get("color", _color_fallback_por_base(fallback, col_defecto))
	var icono_tex: Texture2D = cfg_primaria.get("icono_tex", _icono_fallback_por_base(nombre_opcion, fallback))
	var titulo: String = str(cfg_primaria.get("titulo", str(fallback.get("nombre", nombre_opcion)).to_upper()))
	var rol_badge: String = str(cfg_primaria.get("rol_badge", fallback.get("rol", "Evolución Tier %d" % tier_actual)))
	var subtitulo: String = str(cfg_primaria.get("subtitulo", ""))
	var stats_bbcode: String = str(cfg_primaria.get("stats_bbcode", ""))
	if stats_bbcode.strip_edges().is_empty():
		stats_bbcode = _construir_stats_bbcode_fallback(fallback)
	var accion: String = str(cfg_primaria.get("accion", estilo_tier["verbo_boton"]))

	return {
		"titulo": titulo,
		"rol_badge": rol_badge,
		"subtitulo": subtitulo,
		"color": color_acento,
		"icono_tex": icono_tex,
		"stats_bbcode": stats_bbcode,
		"accion": accion
	}

func _color_fallback_por_base(fallback: Dictionary, color_defecto: Color) -> Color:
	var base := str(fallback.get("clase_base", ""))
	match base:
		"Guerrero", "Murmillo":
			return Color(0.95, 0.30, 0.28, 1.0)
		"Cazador", "Sagittario":
			return Color(0.18, 0.88, 0.76, 1.0)
		"Mago", "Arúspice":
			return Color(0.36, 0.58, 1.0, 1.0)
		"Universal":
			return Color(0.24, 0.94, 0.86, 1.0)
		_:
			return color_defecto

func _icono_fallback_por_base(nombre_opcion: String, fallback: Dictionary) -> Texture2D:
	var base := str(fallback.get("clase_base", nombre_opcion))
	match base:
		"Cazador", "Arquero", "Sagittario":
			return ControlRadial.TEX_ARCO
		"Mago", "Arúspice":
			return ControlRadial.TEX_BASTON
		_:
			return ControlRadial.TEX_ESPADA

func _construir_stats_bbcode_fallback(datos: Dictionary) -> String:
	if datos.is_empty():
		return "• [color=#FFD166]Evolución Especial[/color]\n• [color=#56E39F]Mejora integral de combate[/color]"

	var lineas: PackedStringArray = PackedStringArray()
	var desc := str(datos.get("descripcion", "")).strip_edges()
	if not desc.is_empty():
		lineas.append("[color=#E2E8F0]%s[/color]" % desc)

	if datos.has("vida_maxima"):
		lineas.append("• [color=#56E39F]Salud Máxima:[/color] %d HP" % int(datos["vida_maxima"]))
	if datos.has("dano"):
		lineas.append("• [color=#FFD166]Daño Base:[/color] %d" % int(datos["dano"]))
	if datos.has("rango_ataque"):
		lineas.append("• [color=#72EFDD]Alcance:[/color] %.1fm" % float(datos["rango_ataque"]))
	if datos.has("cadencia_ataque"):
		lineas.append("• [color=#72EFDD]Cadencia:[/color] %.2fs" % float(datos["cadencia_ataque"]))
	if datos.has("speed_correr"):
		lineas.append("• [color=#72EFDD]Velocidad Carrera:[/color] %.1f m/s" % float(datos["speed_correr"]))

	if datos.has("bonus_vida"):
		lineas.append("• [color=#56E39F]+%d HP Máxima[/color]" % int(datos["bonus_vida"]))
	if datos.has("mult_dano"):
		var pct_dano := roundi((float(datos["mult_dano"]) - 1.0) * 100.0)
		lineas.append("• [color=#FFD166]+%d%% Daño[/color]" % pct_dano)
	if datos.has("mult_cadencia"):
		var mult_cad := float(datos["mult_cadencia"])
		if mult_cad < 1.0:
			var pct_vel := roundi((1.0 - mult_cad) * 100.0)
			lineas.append("• [color=#72EFDD]+%d%% Cadencia de Ataque[/color]" % pct_vel)
	if datos.has("bonus_armadura"):
		lineas.append("• [color=#56E39F]+%d Armadura[/color]" % int(datos["bonus_armadura"]))
	if datos.has("proyectiles_extra"):
		lineas.append("• [color=#72EFDD]+%d Proyectil(es) Extra[/color]" % int(datos["proyectiles_extra"]))
	if datos.has("bonus_aoe"):
		lineas.append("• [color=#FFD166]Área de Efecto:[/color] x%.1f" % float(datos["bonus_aoe"]))

	return "\n".join(lineas)

func _crear_tarjeta_opcion(nombre_opcion: String, cfg: Dictionary, idx: int) -> PanelContainer:
	var col: Color = cfg["color"]
	var icono_tex: Texture2D = cfg["icono_tex"]
	var estilo_tier := _obtener_estilo_tier(tier_actual)

	var card := PanelContainer.new()
	card.name = "CardOpcion_%d" % idx
	card.set_meta("opcion_nombre", nombre_opcion)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var sb_card := StyleBoxFlat.new()
	sb_card.bg_color = Color(0.07 + col.r * 0.05, 0.08 + col.g * 0.05, 0.13 + col.b * 0.05, 0.96)
	sb_card.border_color = col.lerp(COLOR_ORO_BORDE, 0.28)
	sb_card.set_border_width_all(2)
	sb_card.set_corner_radius_all(12)
	sb_card.content_margin_left = 14.0
	sb_card.content_margin_right = 14.0
	sb_card.content_margin_top = 14.0
	sb_card.content_margin_bottom = 14.0
	sb_card.shadow_color = Color(col.r, col.g, col.b, 0.25)
	sb_card.shadow_size = 10
	card.add_theme_stylebox_override("panel", sb_card)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Medallón con ícono de clase
	var fila_icono := CenterContainer.new()
	fila_icono.name = "CentroIcono"
	vbox.add_child(fila_icono)

	var medallon := PanelContainer.new()
	medallon.name = "MedallonIcono"
	medallon.custom_minimum_size = Vector2(58.0, 58.0)
	var sb_medallon := StyleBoxFlat.new()
	sb_medallon.bg_color = Color(col.r * 0.20, col.g * 0.20, col.b * 0.20, 0.94)
	sb_medallon.border_color = col.lerp(Color.WHITE, 0.30)
	sb_medallon.set_border_width_all(2)
	sb_medallon.set_corner_radius_all(29)
	sb_medallon.content_margin_left = 9.0
	sb_medallon.content_margin_right = 9.0
	sb_medallon.content_margin_top = 9.0
	sb_medallon.content_margin_bottom = 9.0
	medallon.add_theme_stylebox_override("panel", sb_medallon)
	fila_icono.add_child(medallon)

	var tex_rect := TextureRect.new()
	tex_rect.name = "Icono"
	tex_rect.texture = icono_tex
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(36.0, 36.0)
	tex_rect.modulate = col.lerp(Color.WHITE, 0.42)
	medallon.add_child(tex_rect)

	# Título de la opción
	var lbl_nombre := Label.new()
	lbl_nombre.name = "Nombre"
	lbl_nombre.text = str(cfg["titulo"])
	lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_nombre.add_theme_font_size_override("font_size", 17)
	lbl_nombre.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.26))
	vbox.add_child(lbl_nombre)

	# Badge de rol
	var badge_panel := PanelContainer.new()
	badge_panel.name = "BadgeRol"
	var sb_badge := StyleBoxFlat.new()
	sb_badge.bg_color = Color(col.r, col.g, col.b, 0.16)
	sb_badge.border_color = Color(col.r, col.g, col.b, 0.48)
	sb_badge.set_border_width_all(1)
	sb_badge.set_corner_radius_all(6)
	sb_badge.content_margin_left = 8.0
	sb_badge.content_margin_right = 8.0
	sb_badge.content_margin_top = 3.0
	sb_badge.content_margin_bottom = 3.0
	badge_panel.add_theme_stylebox_override("panel", sb_badge)
	vbox.add_child(badge_panel)

	var lbl_rol := Label.new()
	lbl_rol.name = "Rol"
	lbl_rol.text = str(cfg["rol_badge"])
	lbl_rol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_rol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_rol.add_theme_font_size_override("font_size", 11)
	lbl_rol.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.45))
	badge_panel.add_child(lbl_rol)

	# Subtítulo opcional
	var sub_txt := str(cfg["subtitulo"]).strip_edges()
	if not sub_txt.is_empty():
		var lbl_sub := Label.new()
		lbl_sub.name = "SubtituloOpcion"
		lbl_sub.text = sub_txt
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.add_theme_font_size_override("font_size", 11)
		lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.78, 0.86, 0.9))
		vbox.add_child(lbl_sub)

	# Separador sutil
	var sep := ColorRect.new()
	sep.name = "Separador"
	sep.custom_minimum_size = Vector2(0.0, 1.0)
	sep.color = Color(col.r, col.g, col.b, 0.35)
	vbox.add_child(sep)

	# Stats con BBCode (RichTextLabel)
	var rich_stats := RichTextLabel.new()
	rich_stats.name = "StatsBBCode"
	rich_stats.bbcode_enabled = true
	rich_stats.fit_content = false
	rich_stats.scroll_active = true
	rich_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich_stats.mouse_filter = Control.MOUSE_FILTER_PASS
	rich_stats.add_theme_font_size_override("normal_font_size", 12)
	rich_stats.add_theme_font_size_override("bold_font_size", 12)
	rich_stats.add_theme_color_override("default_color", Color(0.90, 0.92, 0.96, 1.0))
	rich_stats.text = str(cfg["stats_bbcode"])
	vbox.add_child(rich_stats)

	# Botón de elección
	var btn := Button.new()
	btn.name = "BtnElegir"
	btn.custom_minimum_size = Vector2(0.0, 40.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 13)

	var prefijo_tecla := "[%d] " % (idx + 1) if idx < 9 else ""
	var verbo := str(estilo_tier["verbo_boton"])
	var texto_activo := "%s%s" % [prefijo_tecla, verbo]
	btn.text = texto_activo

	var sb_norm := _crear_style_boton(
		Color(col.r * 0.38, col.g * 0.38, col.b * 0.38, 0.95),
		col.lerp(COLOR_ORO_BORDE, 0.35),
		2
	)
	var sb_hover := _crear_style_boton(
		Color(col.r * 0.58, col.g * 0.58, col.b * 0.58, 1.0),
		col.lerp(Color.WHITE, 0.55),
		2
	)
	var sb_press := _crear_style_boton(
		Color(col.r * 0.28, col.g * 0.28, col.b * 0.28, 1.0),
		col,
		2
	)
	var sb_bloqueado := _crear_style_boton(
		Color(0.14, 0.15, 0.20, 0.92),
		Color(0.42, 0.45, 0.52, 0.65),
		1
	)

	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94, 1.0))
	btn.pressed.connect(_on_seleccionar.bind(nombre_opcion))
	vbox.add_child(btn)

	_botones_tarjetas.append({
		"boton": btn,
		"nombre": nombre_opcion,
		"texto_activo": texto_activo,
		"indice": idx,
		"style_normal": sb_norm,
		"style_hover": sb_hover,
		"style_pressed": sb_press,
		"style_bloqueado": sb_bloqueado,
		"color": col
	})

	return card

func _crear_style_boton(bg: Color, borde: Color, ancho_borde: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = borde
	sb.set_border_width_all(ancho_borde)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb
