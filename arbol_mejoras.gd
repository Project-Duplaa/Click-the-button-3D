extends CanvasLayer

# ArbolMejoras - Interfaz de Comercio y Ascensión Incremental
# Desarrollado para el escalado RPG y progresión incremental por Monedas y Clics.

const ArbolMejorasDatos = preload("res://arbol_mejoras_datos.gd")
const AudioManager = preload("res://audio_manager.gd")

signal arbol_cerrado

@onready var panel_ventana: Panel = $Control/PanelVentana
@onready var btn_cerrar: Button = $Control/PanelVentana/Margin/VBox/HBoxHeader/BtnCerrar

@onready var label_oro_val: Label = $Control/PanelVentana/Margin/VBox/HBoxEconomia/PanelOro/HBox/LabelValOro
@onready var label_clics_val: Label = $Control/PanelVentana/Margin/VBox/HBoxEconomia/PanelClics/HBox/LabelValClics
@onready var label_poder_val: Label = $Control/PanelVentana/Margin/VBox/HBoxEconomia/PanelPoder/HBox/LabelValPoder

@onready var btn_tab_todas: Button = $Control/PanelVentana/Margin/VBox/HBoxFiltros/BtnTodas
@onready var btn_tab_monedas: Button = $Control/PanelVentana/Margin/VBox/HBoxFiltros/BtnMonedas
@onready var btn_tab_clicks: Button = $Control/PanelVentana/Margin/VBox/HBoxFiltros/BtnClicks
@onready var btn_tab_hibrido: Button = $Control/PanelVentana/Margin/VBox/HBoxFiltros/BtnHibrido

@onready var grid_tarjetas: GridContainer = $Control/PanelVentana/Margin/VBox/ScrollContainer/GridTarjetas

var jugador: Node = null
var filtro_actual: String = ArbolMejorasDatos.RAMA_TODAS

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 22
	visible = false
	
	btn_cerrar.pressed.connect(cerrar)
	btn_tab_todas.pressed.connect(func(): _cambiar_filtro(ArbolMejorasDatos.RAMA_TODAS))
	btn_tab_monedas.pressed.connect(func(): _cambiar_filtro(ArbolMejorasDatos.RAMA_MONEDAS))
	btn_tab_clicks.pressed.connect(func(): _cambiar_filtro(ArbolMejorasDatos.RAMA_CLICKS))
	btn_tab_hibrido.pressed.connect(func(): _cambiar_filtro(ArbolMejorasDatos.RAMA_HIBRIDO))
	
	call_deferred("_vincular_jugador")

func _vincular_jugador():
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		if jugador.has_signal("economia_actualizada"):
			if not jugador.economia_actualizada.is_connected(_on_economia_actualizada):
				jugador.economia_actualizada.connect(_on_economia_actualizada)
		if jugador.has_signal("mejora_arbol_comprada"):
			if not jugador.mejora_arbol_comprada.is_connected(_on_mejora_comprada):
				jugador.mejora_arbol_comprada.connect(_on_mejora_comprada)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U or event.keycode == KEY_B:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			cerrar()
			get_viewport().set_input_as_handled()

func toggle():
	if visible:
		cerrar()
	else:
		abrir()

func abrir():
	_vincular_jugador()
	visible = true
	get_tree().paused = true
	AudioManager.play("click", 1.25)
	_actualizar_encabezado_economia()
	_construir_grid_mejoras()
	
	# Animación pop de apertura
	panel_ventana.scale = Vector2(0.9, 0.9)
	var tw = create_tween()
	tw.tween_property(panel_ventana, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func cerrar():
	visible = false
	get_tree().paused = false
	AudioManager.play("click", 0.95)
	emit_signal("arbol_cerrado")

func _cambiar_filtro(nueva_rama: String):
	filtro_actual = nueva_rama
	_actualizar_estilo_tabs()
	_construir_grid_mejoras()
	AudioManager.play("click", 1.1)

func _actualizar_estilo_tabs():
	btn_tab_todas.modulate = Color(1.2, 1.2, 1.2) if filtro_actual == ArbolMejorasDatos.RAMA_TODAS else Color(0.7, 0.7, 0.7)
	btn_tab_monedas.modulate = Color(1.2, 1.1, 0.5) if filtro_actual == ArbolMejorasDatos.RAMA_MONEDAS else Color(0.7, 0.7, 0.7)
	btn_tab_clicks.modulate = Color(0.5, 1.1, 1.2) if filtro_actual == ArbolMejorasDatos.RAMA_CLICKS else Color(0.7, 0.7, 0.7)
	btn_tab_hibrido.modulate = Color(1.2, 0.6, 1.2) if filtro_actual == ArbolMejorasDatos.RAMA_HIBRIDO else Color(0.7, 0.7, 0.7)

func _on_economia_actualizada(_oro: int, _clics_disp: int, _clics_tot: int):
	if visible:
		_actualizar_encabezado_economia()
		_actualizar_botones_compra()

func _on_mejora_comprada(_id: String, _nuevo_lvl: int):
	if visible:
		_actualizar_encabezado_economia()
		_construir_grid_mejoras()

func _actualizar_encabezado_economia():
	if jugador == null:
		return
	var oro_cnt = jugador.oro if "oro" in jugador else 0
	var clk_disp = jugador.clics_disponibles if "clics_disponibles" in jugador else 0
	var clk_tot = jugador.clics_totales if "clics_totales" in jugador else 0
	var dano_actual = jugador.dano if "dano" in jugador else 12.0
	var bonus_pct = int((jugador.bonus_dano_pct if "bonus_dano_pct" in jugador else 0.0) * 100.0)
	
	if label_oro_val != null:
		label_oro_val.text = "%d 🪙" % oro_cnt
	if label_clics_val != null:
		label_clics_val.text = "%d ⚡ (Totales: %d)" % [clk_disp, clk_tot]
	if label_poder_val != null:
		label_poder_val.text = "%.1f DMG (+%d%%)" % [dano_actual, bonus_pct]

func _construir_grid_mejoras():
	for hijo in grid_tarjetas.get_children():
		hijo.queue_free()
		
	var lista_ids = ArbolMejorasDatos.obtener_ids_por_rama(filtro_actual)
	var mejoras_compradas = jugador.mejoras_arbol if (jugador != null and "mejoras_arbol" in jugador) else {}
	var oro_actual = jugador.oro if (jugador != null and "oro" in jugador) else 0
	var clics_actuales = jugador.clics_disponibles if (jugador != null and "clics_disponibles" in jugador) else 0

	for id in lista_ids:
		var datos = ArbolMejorasDatos.MEJORAS[id]
		var lvl_actual = mejoras_compradas.get(id, 0)
		var max_lvl = datos.max_nivel
		var costos = ArbolMejorasDatos.calcular_costo(id, lvl_actual)
		var cumple_req = ArbolMejorasDatos.cumple_requisitos(id, mejoras_compradas)
		var es_max = lvl_actual >= max_lvl
		var alcanza_oro = oro_actual >= costos.monedas
		var alcanza_clic = clics_actuales >= costos.clicks
		var puede_pagar = alcanza_oro and alcanza_clic
		
		var tarjeta = _crear_tarjeta_mejora(id, datos, lvl_actual, max_lvl, costos, cumple_req, es_max, puede_pagar, alcanza_oro, alcanza_clic)
		grid_tarjetas.add_child(tarjeta)

func _crear_tarjeta_mejora(id: String, datos: Dictionary, lvl: int, max_lvl: int, costos: Dictionary, cumple_req: bool, es_max: bool, puede_pagar: bool, alcanza_oro: bool, alcanza_clic: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 160)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Estilos visuales por rama
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_size = 4
	style.shadow_color = Color(0, 0, 0, 0.4)
	
	match datos.rama:
		ArbolMejorasDatos.RAMA_MONEDAS:
			style.bg_color = Color(0.12, 0.11, 0.08, 0.95)
			style.border_color = Color(0.92, 0.78, 0.32, 0.85) if cumple_req else Color(0.4, 0.35, 0.2, 0.6)
		ArbolMejorasDatos.RAMA_CLICKS:
			style.bg_color = Color(0.07, 0.11, 0.16, 0.95)
			style.border_color = Color(0.32, 0.85, 0.95, 0.85) if cumple_req else Color(0.2, 0.35, 0.4, 0.6)
		_: # HÍBRIDO
			style.bg_color = Color(0.13, 0.08, 0.16, 0.95)
			style.border_color = Color(0.85, 0.42, 0.95, 0.9) if cumple_req else Color(0.4, 0.2, 0.45, 0.6)
			
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# 1. Fila de Encabezado: Icono + Nombre + Nivel + Rama Tag
	var hbox_top = HBoxContainer.new()
	vbox.add_child(hbox_top)
	
	var lbl_nombre = Label.new()
	lbl_nombre.text = "%s %s" % [datos.icono, datos.nombre]
	lbl_nombre.add_theme_font_size_override("font_size", 15)
	lbl_nombre.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85) if cumple_req else Color(0.65, 0.65, 0.65))
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(lbl_nombre)
	
	var lbl_nivel = Label.new()
	lbl_nivel.text = "Nv. %d / %d" % [lvl, max_lvl]
	lbl_nivel.add_theme_font_size_override("font_size", 13)
	lbl_nivel.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35) if es_max else Color(0.75, 0.85, 1.0))
	hbox_top.add_child(lbl_nivel)
	
	# 2. Descripción
	var lbl_desc = Label.new()
	lbl_desc.text = datos.descripcion
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 12)
	lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85) if cumple_req else Color(0.5, 0.5, 0.5))
	vbox.add_child(lbl_desc)
	
	# 3. Bono por nivel
	var lbl_bono = Label.new()
	lbl_bono.text = "Efecto: %s" % datos.bono_texto
	lbl_bono.add_theme_font_size_override("font_size", 11)
	lbl_bono.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55) if cumple_req else Color(0.4, 0.6, 0.4))
	vbox.add_child(lbl_bono)
	
	# 4. Requisitos / Bloqueo
	if not cumple_req:
		var lbl_req = Label.new()
		lbl_req.text = "🔒 " + ArbolMejorasDatos.obtener_texto_requisitos(id)
		lbl_req.add_theme_font_size_override("font_size", 11)
		lbl_req.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		vbox.add_child(lbl_req)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# 5. Fila Inferior: Costo y Botón de Acción
	var hbox_bottom = HBoxContainer.new()
	vbox.add_child(hbox_bottom)
	
	var lbl_costo = Label.new()
	var texto_costo = ""
	if es_max:
		texto_costo = "⭐ ¡COMPLETA!"
		lbl_costo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		var partes_costo: Array[String] = []
		if costos.monedas > 0:
			var color_mon = "white" if alcanza_oro else "#ff7777"
			partes_costo.append("%d 🪙" % costos.monedas)
		if costos.clicks > 0:
			var color_clk = "white" if alcanza_clic else "#ff7777"
			partes_costo.append("%d ⚡" % costos.clicks)
		texto_costo = "Costo: " + " + ".join(partes_costo)
		lbl_costo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if puede_pagar else Color(0.85, 0.4, 0.4))
		
	lbl_costo.text = texto_costo
	lbl_costo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_costo.add_theme_font_size_override("font_size", 13)
	hbox_bottom.add_child(lbl_costo)
	
	var btn_comprar = Button.new()
	btn_comprar.custom_minimum_size = Vector2(130, 32)
	
	if es_max:
		btn_comprar.text = "¡MÁXIMO!"
		btn_comprar.disabled = true
	elif not cumple_req:
		btn_comprar.text = "🔒 Bloqueado"
		btn_comprar.disabled = true
	elif not puede_pagar:
		btn_comprar.text = "Faltan recursos"
		btn_comprar.disabled = true
	else:
		btn_comprar.text = "Mejorar (Nv. %d)" % (lvl + 1)
		btn_comprar.disabled = false
		btn_comprar.modulate = Color(1.15, 1.15, 1.0)
		btn_comprar.pressed.connect(func(): _intentar_comprar(id))
		
	hbox_bottom.add_child(btn_comprar)
	return panel

func _actualizar_botones_compra():
	# Si se actualiza la economía sin cambiar niveles, podemos refrescar el grid
	_construir_grid_mejoras()

func _intentar_comprar(id: String):
	if jugador != null and jugador.has_method("comprar_mejora"):
		var exito = jugador.comprar_mejora(id)
		if exito:
			_actualizar_encabezado_economia()
			_construir_grid_mejoras()
