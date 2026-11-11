extends CanvasLayer

# ArbolMejorasPoE - Controlador Principal del Árbol Interconectado Estilo Path of Exile
# Administra la sincronización del lienzo interactivo, la selección de nodos y el panel de detalle lateral.

const AudioManager = preload("res://audio_manager.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

signal arbol_cerrado

@onready var lienzo: LienzoArbolHabilidades = $Control/LienzoArbol
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
	
	# Construir árbol de datos una sola vez
	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)
	
	call_deferred("_vincular_jugador")

func _vincular_jugador():
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if jugador != null:
		if jugador.has_signal("economia_actualizada"):
			if not jugador.economia_actualizada.is_connected(_on_economia_actualizada):
				jugador.economia_actualizada.connect(_on_economia_actualizada)
		_sincronizar_niveles_desde_jugador()

func _sincronizar_niveles_desde_jugador():
	MetaprogresoManager.asegurar_inicializado()
	var compradas: Dictionary = MetaprogresoManager.mejoras_arbol
	if jugador != null and "mejoras_arbol" in jugador and jugador.mejoras_arbol.size() > 0:
		for k in jugador.mejoras_arbol.keys():
			compradas[k] = jugador.mejoras_arbol[k]
			
	for id in diccionario_nodos.keys():
		var n: SkillNodeData = diccionario_nodos[id]
		if id == "nodo_origen":
			n.nivel_actual = 1
		elif compradas.has(id):
			n.nivel_actual = compradas[id]
		else:
			n.nivel_actual = 0
	lienzo.queue_redraw()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and visible:
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
	
	# Inspeccionar nodo por defecto
	var nodo_inicial = diccionario_nodos.get("clk_dano_1", diccionario_nodos.get("nodo_origen"))
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
	var oro_cnt = MetaprogresoManager.oro_banco
	var clk_disp = MetaprogresoManager.clics_banco
	if jugador != null and is_instance_valid(jugador) and not jugador._muerto_definitivo:
		oro_cnt += jugador.oro
		clk_disp += jugador.clics_disponibles
		
	label_oro_top.text = "🪙 %d Oro (Tesoro Roguelike)" % oro_cnt
	label_clics_top.text = "⚡ %d Clics (Tesoro Roguelike)" % clk_disp

# ==============================================================================
# MANEJO DEL PANEL DETALLE LATERAL (MINIMALIST DARK SLATE PANEL)
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
	
	# Rama Tag y Color
	var tag_rama = "🔵 PODER ACTIVO (CLIC)"
	var col_rama = Color(0.45, 0.73, 0.95)
	match nodo.rama:
		"verde":
			tag_rama = "🟢 SUPERVIVENCIA Y CONTROL"
			col_rama = Color(0.35, 0.78, 0.56)
		"dorada":
			tag_rama = "🟡 AUTOMATIZACIÓN Y ECONOMÍA"
			col_rama = Color(0.96, 0.78, 0.40)
		"hibrido":
			tag_rama = "🟣 SINERGIA CONECTADA"
			col_rama = Color(0.80, 0.55, 0.92)
		"central":
			tag_rama = "💠 ORIGEN DEL COLISEO"
			col_rama = Color(0.60, 0.92, 0.98)
			
	if nodo.es_keystone:
		tag_rama += " [KEYSTONE]"
		
	lbl_nodo_rama.text = tag_rama
	lbl_nodo_rama.add_theme_color_override("font_color", col_rama)
	
	if nodo.id == "nodo_origen":
		lbl_nodo_nivel.text = "[ ACTIVO ]"
	else:
		lbl_nodo_nivel.text = "Nivel %d / %d" % [nodo.nivel_actual, nodo.nivel_max]
	
	# Estado de Conexión en la red
	match estado:
		"maxeado":
			lbl_nodo_estado.text = "⭐ Nodo completado al máximo nivel."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		"comprado":
			lbl_nodo_estado.text = "✓ Activo en tu red de resonancia."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		"desbloqueable":
			lbl_nodo_estado.text = "⚡ Conectado: Listo para ser desbloqueado."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		_:
			lbl_nodo_estado.text = "🔒 Bloqueado: Requiere enlace desde un nodo vecino comprado."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.85, 0.4, 0.4))
			
	# Costos y Botón de Compra
	if nodo.id == "nodo_origen" or estado == "maxeado":
		lbl_nodo_costo.text = "⭐ Nivel Máximo Alcanzado"
		btn_comprar_nodo.text = "Completado"
		btn_comprar_nodo.disabled = true
	else:
		var costos = nodo.calcular_costo()
		var txt_costo = []
		var alcanza_oro = true
		var alcanza_clic = true
		
		MetaprogresoManager.asegurar_inicializado()
		var oro_actual = MetaprogresoManager.oro_banco
		var clics_actuales = MetaprogresoManager.clics_banco
		if jugador != null and is_instance_valid(jugador) and not jugador._muerto_definitivo:
			oro_actual += jugador.oro
			clics_actuales += jugador.clics_disponibles
		
		if costos.oro > 0:
			alcanza_oro = oro_actual >= costos.oro
			txt_costo.append("%d 🪙 Oro" % costos.oro)
		if costos.clics > 0:
			alcanza_clic = clics_actuales >= costos.clics
			txt_costo.append("%d ⚡ Clics" % costos.clics)
			
		lbl_nodo_costo.text = "Costo: " + " + ".join(txt_costo)
		
		var puede_pagar = alcanza_oro and alcanza_clic
		if estado == "bloqueado":
			btn_comprar_nodo.text = "🔒 Bloqueado"
			btn_comprar_nodo.disabled = true
		elif not puede_pagar:
			btn_comprar_nodo.text = "Recursos insuficientes"
			btn_comprar_nodo.disabled = true
		else:
			btn_comprar_nodo.text = "Desbloquear (Nv. %d)" % (nodo.nivel_actual + 1)
			btn_comprar_nodo.disabled = false

func _on_btn_comprar_presionado():
	if nodo_actual_inspeccionado == null:
		return
		
	var nodo = nodo_actual_inspeccionado
	var estado = ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	if estado == "bloqueado" or nodo.esta_maxeado():
		return
		
	var costos = nodo.calcular_costo()
	MetaprogresoManager.asegurar_inicializado()
	
	var oro_disponible = MetaprogresoManager.oro_banco
	var clics_disponibles = MetaprogresoManager.clics_banco
	if jugador != null and is_instance_valid(jugador) and not jugador._muerto_definitivo:
		oro_disponible += jugador.oro
		clics_disponibles += jugador.clics_disponibles
		
	if oro_disponible < costos.oro or clics_disponibles < costos.clics:
		return
		
	# Descontar recursos
	var oro_a_pagar = costos.oro
	if jugador != null and is_instance_valid(jugador) and not jugador._muerto_definitivo:
		var pago_pj_oro = min(jugador.oro, oro_a_pagar)
		jugador.oro -= pago_pj_oro
		oro_a_pagar -= pago_pj_oro
	MetaprogresoManager.oro_banco -= oro_a_pagar
	
	var clics_a_pagar = costos.clics
	if jugador != null and is_instance_valid(jugador) and not jugador._muerto_definitivo:
		var pago_pj_clk = min(jugador.clics_disponibles, clics_a_pagar)
		jugador.clics_disponibles -= pago_pj_clk
		clics_a_pagar -= pago_pj_clk
	MetaprogresoManager.clics_banco -= clics_a_pagar
	
	# Incrementar nivel de nodo y guardar en disco
	nodo.nivel_actual += 1
	MetaprogresoManager.mejoras_arbol[nodo.id] = nodo.nivel_actual
	MetaprogresoManager.guardar()
	
	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
		
	# Feedback sonoro
	if nodo.es_keystone:
		AudioManager.play("victoria", 1.2, 2.0)
	else:
		AudioManager.play("altar_activado", 1.0 + (nodo.nivel_actual * 0.05), -2.0)
		
	# Actualizar vistas
	_actualizar_barra_economia()
	var nuevo_estado = ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	_actualizar_panel_detalle(nodo, nuevo_estado)
	lienzo.queue_redraw()
