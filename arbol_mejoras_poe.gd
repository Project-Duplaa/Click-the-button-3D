extends CanvasLayer

# ArbolMejorasPoE - Controlador Principal del Árbol Interconectado Estilo Path of Exile
# Administra la sincronización del lienzo interactivo, la selección de nodos, el panel de detalle lateral,
# y la pasarela de Renacimiento Astral (Prestigio) con Esquirlas Astrales.

const AudioManager = preload("res://audio_manager.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

signal arbol_cerrado

@onready var lienzo: LienzoArbolHabilidades = $Control/LienzoArbol
@onready var hbox_top: HBoxContainer = $Control/PanelTop/HBox
@onready var label_oro_top: Label = $Control/PanelTop/HBox/PanelOro/LabelOro
@onready var label_clics_top: Label = $Control/PanelTop/HBox/PanelClics/LabelClics
@onready var btn_cerrar_top: Button = $Control/PanelTop/HBox/BtnCerrar
@onready var btn_centrar: Button = $Control/PanelTop/HBox/BtnCentrar
@onready var btn_zoom_in: Button = $Control/PanelTop/HBox/BtnZoomIn
@onready var btn_zoom_out: Button = $Control/PanelTop/HBox/BtnZoomOut

# Panel Lateral de Detalle (Esquina Inferior Derecha)
@onready var panel_detalle: PanelContainer = $Control/PanelDetalle
@onready var lbl_nodo_nombre: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/VBoxInfo/LabelNombre
@onready var lbl_nodo_rama: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/VBoxInfo/LabelRama
@onready var lbl_nodo_nivel: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/LabelNivel
@onready var lbl_nodo_icono: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/IconoGrande
@onready var lbl_nodo_desc: Label = $Control/PanelDetalle/Margin/VBox/LabelDesc
@onready var lbl_nodo_bono: Label = $Control/PanelDetalle/Margin/VBox/LabelBono
@onready var lbl_nodo_estado: Label = $Control/PanelDetalle/Margin/VBox/LabelEstado
@onready var lbl_nodo_costo: Label = $Control/PanelDetalle/Margin/VBox/HBoxAccion/LabelCosto
@onready var btn_comprar_nodo: Button = $Control/PanelDetalle/Margin/VBox/HBoxAccion/BtnComprar

# Píldoras Dinámicas y Botón de Prestigio construidos por script si no existen en escena
var panel_esquirlas_top: PanelContainer = null
var label_esquirlas_top: Label = null
var panel_prestigio_top: PanelContainer = null
var label_prestigio_top: Label = null
var btn_renacimiento_astral: Button = null
var btn_run_pura: Button = null
var btn_reset_meta: Button = null
var _confirmar_reset_hasta_ms: int = 0

var jugador: CharacterBody3D = null
var diccionario_nodos: Dictionary = {}
var nodo_actual_inspeccionado: SkillNodeData = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 22
	visible = false
	
	btn_cerrar_top.pressed.connect(cerrar)
	btn_centrar.pressed.connect(_on_centrar_presionado)
	btn_zoom_in.pressed.connect(func(): lienzo._aplicar_zoom(1.2, lienzo.size * 0.5))
	btn_zoom_out.pressed.connect(func(): lienzo._aplicar_zoom(0.8, lienzo.size * 0.5))
	btn_comprar_nodo.pressed.connect(_on_btn_comprar_presionado)
	
	lienzo.nodo_seleccionado.connect(_on_nodo_seleccionado_en_lienzo)
	
	_construir_elementos_ui_adicionales()
	
	# Construir árbol de datos
	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)
	
	call_deferred("_vincular_jugador")

func _construir_elementos_ui_adicionales():
	if hbox_top == null:
		return
		
	# 1. Píldora de Esquirlas Astrales
	panel_esquirlas_top = PanelContainer.new()
	panel_esquirlas_top.name = "PanelEsquirlas"
	var sb_esq = StyleBoxFlat.new()
	sb_esq.bg_color = Color(0.12, 0.08, 0.22, 0.90)
	sb_esq.border_color = Color(0.78, 0.45, 1.0, 0.85)
	sb_esq.set_border_width_all(1)
	sb_esq.set_corner_radius_all(6)
	sb_esq.content_margin_left = 10
	sb_esq.content_margin_right = 10
	sb_esq.content_margin_top = 4
	sb_esq.content_margin_bottom = 4
	panel_esquirlas_top.add_theme_stylebox_override("panel", sb_esq)
	
	label_esquirlas_top = Label.new()
	label_esquirlas_top.text = "✨ 0 Esquirlas"
	label_esquirlas_top.add_theme_color_override("font_color", Color(0.92, 0.82, 1.0))
	panel_esquirlas_top.add_child(label_esquirlas_top)
	hbox_top.add_child(panel_esquirlas_top)
	hbox_top.move_child(panel_esquirlas_top, 2)
	
	# 2. Píldora de Nivel de Prestigio
	panel_prestigio_top = PanelContainer.new()
	panel_prestigio_top.name = "PanelPrestigio"
	var sb_pres = StyleBoxFlat.new()
	sb_pres.bg_color = Color(0.18, 0.14, 0.04, 0.90)
	sb_pres.border_color = Color(1.0, 0.80, 0.20, 0.90)
	sb_pres.set_border_width_all(1)
	sb_pres.set_corner_radius_all(6)
	sb_pres.content_margin_left = 10
	sb_pres.content_margin_right = 10
	sb_pres.content_margin_top = 4
	sb_pres.content_margin_bottom = 4
	panel_prestigio_top.add_theme_stylebox_override("panel", sb_pres)
	
	label_prestigio_top = Label.new()
	label_prestigio_top.text = "🌟 Prestigio Nv. 0 (+0%)"
	label_prestigio_top.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45))
	panel_prestigio_top.add_child(label_prestigio_top)
	hbox_top.add_child(panel_prestigio_top)
	hbox_top.move_child(panel_prestigio_top, 3)
	
	# 3. Botón de Renacimiento Astral en PanelTop
	btn_renacimiento_astral = Button.new()
	btn_renacimiento_astral.name = "BtnRenacimientoAstral"
	btn_renacimiento_astral.text = "✨ RENACIMIENTO ASTRAL"
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.35, 0.15, 0.55, 0.95)
	sb_btn.border_color = Color(0.95, 0.80, 1.0, 1.0)
	sb_btn.set_border_width_all(1)
	sb_btn.set_corner_radius_all(6)
	btn_renacimiento_astral.add_theme_stylebox_override("normal", sb_btn)
	btn_renacimiento_astral.add_theme_color_override("font_color", Color(1, 1, 1))
	btn_renacimiento_astral.pressed.connect(_on_renacimiento_astral_presionado)
	hbox_top.add_child(btn_renacimiento_astral)
	hbox_top.move_child(btn_renacimiento_astral, 4)

	# 4. Botón Toggle Modo Run Pura (0% Metaprogreso)
	btn_run_pura = Button.new()
	btn_run_pura.name = "BtnRunPura"
	btn_run_pura.text = "🛡️ Run Pura: OFF"
	var sb_pura = StyleBoxFlat.new()
	sb_pura.bg_color = Color(0.10, 0.22, 0.30, 0.95)
	sb_pura.border_color = Color(0.35, 0.85, 1.0, 0.90)
	sb_pura.set_border_width_all(1)
	sb_pura.set_corner_radius_all(6)
	btn_run_pura.add_theme_stylebox_override("normal", sb_pura)
	btn_run_pura.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	btn_run_pura.pressed.connect(_on_btn_run_pura_presionado)
	hbox_top.add_child(btn_run_pura)
	hbox_top.move_child(btn_run_pura, 5)

	# 5. Botón Resetear Progreso Meta (con confirmación en 2 clics)
	btn_reset_meta = Button.new()
	btn_reset_meta.name = "BtnResetMeta"
	btn_reset_meta.text = "🗑️ Reset Meta"
	var sb_reset = StyleBoxFlat.new()
	sb_reset.bg_color = Color(0.30, 0.10, 0.12, 0.95)
	sb_reset.border_color = Color(0.95, 0.35, 0.35, 0.90)
	sb_reset.set_border_width_all(1)
	sb_reset.set_corner_radius_all(6)
	btn_reset_meta.add_theme_stylebox_override("normal", sb_reset)
	btn_reset_meta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85))
	btn_reset_meta.pressed.connect(_on_btn_reset_meta_presionado)
	hbox_top.add_child(btn_reset_meta)
	hbox_top.move_child(btn_reset_meta, 6)

func _en_combate_activo() -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
	if pantalla_fin != null and pantalla_fin.visible:
		return false
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and "partida_iniciada" in partida and bool(partida.partida_iniciada):
		if "estado" in partida and int(partida.estado) == 0:
			return true
	var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
	if spawner != null and "partida_iniciada" in spawner and bool(spawner.partida_iniciada):
		return true
	return false

func _on_btn_run_pura_presionado():
	if _en_combate_activo():
		return
	MetaprogresoManager.asegurar_inicializado()
	MetaprogresoManager.establecer_modo_run_pura(not MetaprogresoManager.modo_run_pura)
	AudioManager.play("click", 1.15)
	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
		jugador.vida = jugador.vida_maxima
	_actualizar_barra_economia()
	if nodo_actual_inspeccionado != null:
		var est = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_actual_inspeccionado, diccionario_nodos)
		_actualizar_panel_detalle(nodo_actual_inspeccionado, est)

func _on_btn_reset_meta_presionado():
	if _en_combate_activo():
		return
	var ahora_ms: int = Time.get_ticks_msec()
	if ahora_ms > _confirmar_reset_hasta_ms:
		_confirmar_reset_hasta_ms = ahora_ms + 4000
		if btn_reset_meta != null:
			btn_reset_meta.text = "⚠️ ¿Confirmar Reset?"
		AudioManager.play("click", 0.9)
		return

	_confirmar_reset_hasta_ms = 0
	MetaprogresoManager.resetear_todo_para_pruebas()
	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)
	_sincronizar_niveles_desde_jugador()
	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
		jugador.vida = jugador.vida_maxima
	_actualizar_barra_economia()
	var nodo_sel = diccionario_nodos.get("nodo_origen", null)
	if nodo_actual_inspeccionado != null and diccionario_nodos.has(nodo_actual_inspeccionado.id):
		nodo_sel = diccionario_nodos[nodo_actual_inspeccionado.id]
	if nodo_sel != null:
		nodo_actual_inspeccionado = nodo_sel
		var est = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_sel, diccionario_nodos)
		_actualizar_panel_detalle(nodo_sel, est)
	AudioManager.play("escudo_bloqueo", 1.0)

func _vincular_jugador():
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if jugador != null:
		if jugador.has_signal("economia_actualizada"):
			if not jugador.economia_actualizada.is_connected(_on_economia_actualizada):
				jugador.economia_actualizada.connect(_on_economia_actualizada)
		_sincronizar_niveles_desde_jugador()

func _sincronizar_niveles_desde_jugador():
	MetaprogresoManager.asegurar_inicializado()
	var compradas: Dictionary = MetaprogresoManager.mejoras_arbol
			
	for id in diccionario_nodos.keys():
		var n: SkillNodeData = diccionario_nodos[id]
		if id == "nodo_origen":
			n.nivel_actual = 1
		elif compradas.has(id):
			n.nivel_actual = int(compradas[id])
		else:
			n.nivel_actual = 0
	lienzo.queue_redraw()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_ESCAPE or event.keycode == KEY_U or event.keycode == KEY_B) and visible:
			cerrar()
			get_viewport().set_input_as_handled()

func toggle():
	if visible:
		cerrar()
	else:
		abrir()

func abrir():
	_vincular_jugador()
	_sincronizar_niveles_desde_jugador()
	visible = true
	get_tree().paused = true
	AudioManager.play("click", 1.25)
	_actualizar_barra_economia()
	
	var nodo_inicial = diccionario_nodos.get("clk_fuerza_1", diccionario_nodos.get("nodo_origen"))
	if nodo_inicial != null:
		_on_nodo_seleccionado_en_lienzo(nodo_inicial, ArbolInterconectadoDatos.obtener_estado_nodo(nodo_inicial, diccionario_nodos))

func cerrar():
	visible = false
	var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
	if pantalla_fin == null or not pantalla_fin.visible:
		get_tree().paused = false
	AudioManager.play("click", 0.95)
	emit_signal("arbol_cerrado")

func _on_centrar_presionado():
	lienzo._centrar_en_origen()
	AudioManager.play("click", 1.1)

func _on_economia_actualizada(_oro: int, _clics_disp: int, _clics_tot: int):
	if visible:
		_actualizar_barra_economia()
		if nodo_actual_inspeccionado != null:
			var estado = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_actual_inspeccionado, diccionario_nodos)
			_actualizar_panel_detalle(nodo_actual_inspeccionado, estado)

func _actualizar_barra_economia():
	MetaprogresoManager.asegurar_inicializado()
	var en_combate: bool = _en_combate_activo()
	var oro_cnt = MetaprogresoManager.oro_banco
	var clk_disp = MetaprogresoManager.clics_banco

	label_oro_top.text = "🧪 %s Oro (Banco)" % MetaprogresoManager.formatear_numero(float(oro_cnt))
	label_clics_top.text = "⚡ %s Clics (Banco)" % MetaprogresoManager.formatear_numero(float(clk_disp))

	if label_esquirlas_top != null:
		label_esquirlas_top.text = "✨ %s Esquirlas" % MetaprogresoManager.formatear_numero(float(MetaprogresoManager.esquirlas_astrales))

	if label_prestigio_top != null:
		var bonus_pct = 0 if MetaprogresoManager.modo_run_pura else int(round(float(MetaprogresoManager.nivel_prestigio) * 15.0))
		label_prestigio_top.text = "🌟 Prestigio Nv. %d (+%d%%)" % [MetaprogresoManager.nivel_prestigio, bonus_pct]

	if btn_renacimiento_astral != null:
		var puede = MetaprogresoManager.puede_hacer_prestigio() and not en_combate
		var esquirlas_est = MetaprogresoManager.calcular_esquirlas_prestigio()
		if en_combate:
			btn_renacimiento_astral.text = "🔒 Renacimiento (En Combate)"
		else:
			btn_renacimiento_astral.text = "✨ RENACIMIENTO (+%d ✨)" % esquirlas_est if puede else "🔒 Renacimiento (Bloq)"
		btn_renacimiento_astral.disabled = not puede

	if btn_run_pura != null:
		btn_run_pura.text = "🛡️ Run Pura: ON (0% Meta)" if MetaprogresoManager.modo_run_pura else "🛡️ Run Pura: OFF"
		btn_run_pura.disabled = en_combate

	if btn_reset_meta != null:
		if Time.get_ticks_msec() > _confirmar_reset_hasta_ms:
			btn_reset_meta.text = "🗑️ Reset Meta"
		btn_reset_meta.disabled = en_combate

func _on_renacimiento_astral_presionado():
	if _en_combate_activo():
		return
	if not MetaprogresoManager.puede_hacer_prestigio():
		return
	var ganadas = MetaprogresoManager.ejecutar_renacimiento_astral()
	AudioManager.play("victoria", 1.3, 3.0)
	
	# Refrescar árbol de habilidades por completo
	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)
	_sincronizar_niveles_desde_jugador()
	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
	_actualizar_barra_economia()
	
	if nodo_actual_inspeccionado != null:
		var est = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_actual_inspeccionado, diccionario_nodos)
		_actualizar_panel_detalle(nodo_actual_inspeccionado, est)

# ==============================================================================
# MANEJO DEL PANEL DETALLE LATERAL
# ==============================================================================
func _on_nodo_seleccionado_en_lienzo(nodo: SkillNodeData, estado: String):
	nodo_actual_inspeccionado = nodo
	_actualizar_panel_detalle(nodo, estado)
	AudioManager.play("click", 1.15)

func _actualizar_panel_detalle(nodo: SkillNodeData, estado: String):
	lbl_nodo_nombre.text = nodo.nombre
	lbl_nodo_icono.text = nodo.icono
	lbl_nodo_desc.text = nodo.descripcion
	lbl_nodo_bono.text = nodo.obtener_texto_bono()
	
	var tag_rama = "⚡ PODER ACTIVO DE CLIC"
	var col_rama = Color(0.20, 0.85, 1.0)
	match nodo.rama:
		"verde":
			tag_rama = "☣️ BIOCONTENCIÓN & SUPERVIVENCIA"
			col_rama = Color(0.25, 0.95, 0.45)
		"dorada":
			tag_rama = "🧪 ECONOMÍA, ARSENAL & ISÓTOPOS"
			col_rama = Color(1.0, 0.80, 0.25)
		"hibrido":
			tag_rama = "🧬 MUTACIÓN CUÁNTICA // SINERGIA"
			col_rama = Color(0.85, 0.55, 1.0)
		"cosmico":
			tag_rama = "🌌 CONSTELACIÓN CÓSMICA ASTRAL"
			col_rama = Color(0.95, 0.65, 1.0)
		"central":
			tag_rama = "☢️ NÚCLEO DE REACTOR CERO"
			col_rama = Color(0.30, 1.0, 0.70)
			
	if nodo.es_keystone:
		tag_rama += " [PROTOCOLO CRÍTICO]"
	elif nodo.nivel_max >= 999:
		tag_rama += " [MAESTRÍA INFINITA]"
		
	lbl_nodo_rama.text = tag_rama
	lbl_nodo_rama.add_theme_color_override("font_color", col_rama)
	
	if nodo.id == "nodo_origen":
		lbl_nodo_nivel.text = "[ NÚCLEO OPERATIVO ]"
	elif nodo.nivel_max >= 999:
		lbl_nodo_nivel.text = "Nivel %d (Sin Límite)" % nodo.nivel_actual
	else:
		lbl_nodo_nivel.text = "Nivel %d / %d" % [nodo.nivel_actual, nodo.nivel_max]
	
	match estado:
		"maxeado":
			lbl_nodo_estado.text = "⭐ Módulo Saturado: Nivel Máximo Operativo."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		"comprado":
			lbl_nodo_estado.text = "✓ Módulo Activo: Flujo de Energía Estable."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.25, 0.95, 0.5))
		"desbloqueable":
			lbl_nodo_estado.text = "⚡ Circuito Enlazado: Listo para Inyección."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
		_:
			lbl_nodo_estado.text = "🔒 Módulo Bloqueado: Requiere acople desde un módulo adyacente."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
			
	if nodo.id == "nodo_origen" or (estado == "maxeado" and nodo.nivel_max < 999):
		lbl_nodo_costo.text = "⭐ Módulo Completamente Sintetizado"
		btn_comprar_nodo.text = "Completado"
		btn_comprar_nodo.disabled = true
	else:
		var en_combate: bool = _en_combate_activo()
		var costos = nodo.calcular_costo()
		var txt_costo = []
		MetaprogresoManager.asegurar_inicializado()
		var oro_actual = MetaprogresoManager.oro_banco
		var clics_actuales = MetaprogresoManager.clics_banco

		var c_oro = int(costos.get("oro", 0))
		var c_clk = int(costos.get("clics", 0))
		var alcanza_oro = true
		var alcanza_clic = true

		if c_oro > 0:
			alcanza_oro = oro_actual >= c_oro
			txt_costo.append("%s Oro" % MetaprogresoManager.formatear_numero(float(c_oro)))
		if c_clk > 0:
			alcanza_clic = clics_actuales >= c_clk
			txt_costo.append("%s Clics" % MetaprogresoManager.formatear_numero(float(c_clk)))

		lbl_nodo_costo.text = "Costo (Banco): " + (" + ".join(txt_costo) if txt_costo.size() > 0 else "Gratis")

		var puede_pagar = alcanza_oro and alcanza_clic
		if en_combate:
			lbl_nodo_estado.text = "🔒 Combate en curso: mejoras permanentes solo antes de iniciar o al terminar la run."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(1.0, 0.70, 0.28))
			btn_comprar_nodo.text = "🔒 Bloqueado en Combate"
			btn_comprar_nodo.disabled = true
		elif estado == "bloqueado":
			btn_comprar_nodo.text = "🔒 Módulo Bloqueado"
			btn_comprar_nodo.disabled = true
		elif not puede_pagar:
			btn_comprar_nodo.text = "Recursos insuficientes en Banco"
			btn_comprar_nodo.disabled = true
		else:
			btn_comprar_nodo.text = "Inyectar Sobrecarga (Nv. %d)" % (nodo.nivel_actual + 1)
			btn_comprar_nodo.disabled = false

func _on_btn_comprar_presionado():
	if _en_combate_activo() or nodo_actual_inspeccionado == null:
		return

	var nodo = nodo_actual_inspeccionado
	var estado = ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	if estado == "bloqueado" or (nodo.esta_maxeado() and nodo.nivel_max < 999):
		return

	var costos = nodo.calcular_costo()
	MetaprogresoManager.asegurar_inicializado()

	var oro_disponible = MetaprogresoManager.oro_banco
	var clics_disponibles = MetaprogresoManager.clics_banco

	var c_oro = int(costos.get("oro", 0))
	var c_clk = int(costos.get("clics", 0))
	if oro_disponible < c_oro or clics_disponibles < c_clk:
		return

	MetaprogresoManager.oro_banco -= c_oro
	MetaprogresoManager.clics_banco -= c_clk

	nodo.nivel_actual += 1
	MetaprogresoManager.mejoras_arbol[nodo.id] = nodo.nivel_actual
	MetaprogresoManager.guardar()

	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
		jugador.vida = minf(jugador.vida, jugador.vida_maxima)
		
	if nodo.es_keystone:
		AudioManager.play("victoria", 1.2, 2.0)
	else:
		AudioManager.play("altar_activado", 1.0 + (min(nodo.nivel_actual, 10) * 0.05), -2.0)
		
	_actualizar_barra_economia()
	var nuevo_estado = ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	_actualizar_panel_detalle(nodo, nuevo_estado)
	lienzo.queue_redraw()
