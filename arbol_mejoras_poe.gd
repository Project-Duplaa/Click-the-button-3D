extends CanvasLayer

## ArbolMejorasPoE - Controlador Principal del Árbol Interconectado ("Matriz del Reactor Cero")
## Administra la sincronización del lienzo interactivo, minimapa táctico, enfoque por sector,
## inspector lateral de detalle con medalla SVG/barra de niveles, y Renacimiento Astral.

const AudioManager = preload("res://audio_manager.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const IconosArbol = preload("res://iconos_arbol_habilidades.gd")

signal arbol_cerrado

const COLOR_ORO_IMPERIAL := Color(0.980, 0.800, 0.082, 1.0) # #FACC15
const MINIMAP_BOUNDS := Rect2(-1160.0, -1540.0, 2120.0, 2580.0)

@onready var lienzo: LienzoArbolHabilidades = $Control/LienzoArbol
@onready var header_main_bg: ColorRect = $Control/TopHeader/HeaderMain/Backdrop
@onready var header_actions_bg: ColorRect = $Control/TopHeader/HeaderActions/Backdrop
@onready var minimap_bg: ColorRect = $Control/PanelMinimap/Backdrop
@onready var minimap_canvas: Control = $Control/PanelMinimap/MinimapCanvas
@onready var dock_cam_bg: ColorRect = $Control/DockCamara/Backdrop
@onready var hint_bg: ColorRect = $Control/PanelHint/Backdrop
@onready var panel_detalle: Control = $Control/PanelDetalle
@onready var panel_detalle_bg: ColorRect = $Control/PanelDetalle/Backdrop

# Top Header Main
@onready var lbl_progreso_top: Label = $Control/TopHeader/HeaderMain/HBox/LeftIdentity/PillProgreso/LabelProgreso
@onready var label_oro_top: Label = $Control/TopHeader/HeaderMain/HBox/CenterBank/PanelOro/HBox/LabelOro
@onready var label_clics_top: Label = $Control/TopHeader/HeaderMain/HBox/CenterBank/PanelClics/HBox/LabelClics
@onready var label_esquirlas_top: Label = $Control/TopHeader/HeaderMain/HBox/CenterBank/PanelEsquirlas/HBox/LabelEsquirlas
@onready var label_prestigio_top: Label = $Control/TopHeader/HeaderMain/HBox/RightCluster/PanelPrestigio/HBox/LabelPrestigio
@onready var btn_cerrar_top: Button = $Control/TopHeader/HeaderMain/HBox/RightCluster/BtnCerrar

# Top Header Actions & Quick-Focus Sectors
@onready var btn_renacimiento_astral: Button = $Control/TopHeader/HeaderActions/HBox/LeftActions/BtnRenacimientoAstral
@onready var btn_run_pura: Button = $Control/TopHeader/HeaderActions/HBox/LeftActions/BtnRunPura
@onready var btn_reset_meta: Button = $Control/TopHeader/HeaderActions/HBox/LeftActions/BtnResetMeta
@onready var btn_sector_nucleo: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorNucleo
@onready var btn_sector_cinetico: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorCinetico
@onready var btn_sector_boton: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorBoton
@onready var btn_sector_bastion: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorBastion
@onready var btn_sector_arsenal: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorArsenal
@onready var btn_sector_cosmica: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorCosmica
@onready var btn_sector_todo: Button = $Control/TopHeader/HeaderActions/HBox/RightSectors/BtnSectorTodo

# Camera Dock
@onready var btn_zoom_out: Button = $Control/DockCamara/HBox/BtnZoomOut
@onready var btn_zoom_reset: Button = $Control/DockCamara/HBox/BtnZoomReset
@onready var btn_zoom_in: Button = $Control/DockCamara/HBox/BtnZoomIn
@onready var btn_centrar: Button = $Control/DockCamara/HBox/BtnCentrar
@onready var btn_fit_all: Button = $Control/DockCamara/HBox/BtnFitAll

# Panel Detalle (Inspector)
@onready var medallon_icono: Control = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/MedallonIcono
@onready var tex_nodo_icono: TextureRect = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/MedallonIcono/IconoGrande
@onready var lbl_nodo_rama: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/VBoxInfo/LabelRama
@onready var lbl_nodo_nombre: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/VBoxInfo/LabelNombre
@onready var pill_nivel: PanelContainer = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/PillNivel
@onready var lbl_nodo_nivel: Label = $Control/PanelDetalle/Margin/VBox/HBoxEncabezado/PillNivel/LabelNivel
@onready var barra_pips: Control = $Control/PanelDetalle/Margin/VBox/BarraPips
@onready var lbl_nodo_desc: Label = $Control/PanelDetalle/Margin/VBox/DescWell/LabelDesc
@onready var lbl_nodo_bono: Label = $Control/PanelDetalle/Margin/VBox/TelemetryBox/VBoxTele/LabelBono
@onready var lbl_nodo_estado: Label = $Control/PanelDetalle/Margin/VBox/TelemetryBox/VBoxTele/LabelEstado
@onready var lbl_nodo_prereq: Label = $Control/PanelDetalle/Margin/VBox/TelemetryBox/VBoxTele/LabelPrerequisito
@onready var lbl_nodo_banco: Label = $Control/PanelDetalle/Margin/VBox/RecursosHBox/ChipBanco/LabelBanco
@onready var lbl_nodo_costo: Label = $Control/PanelDetalle/Margin/VBox/RecursosHBox/ChipCosto/LabelCosto
@onready var btn_comprar_nodo: Button = $Control/PanelDetalle/Margin/VBox/BtnComprar

var jugador: CharacterBody3D = null
var diccionario_nodos: Dictionary = {}
var nodo_actual_inspeccionado: SkillNodeData = null

var _confirmar_reset_hasta_ms: int = 0
var _minimap_arrastrando: bool = false
var _color_detalle_actual: Color = Color(0.20, 0.85, 1.0)
var _detalle_es_dorado: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 22
	visible = false

	_conectar_senales_ui()
	_conectar_shaders_paneles()

	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)

	call_deferred("_sincronizar_shaders_paneles")
	call_deferred("_vincular_jugador")

func _conectar_senales_ui():
	btn_cerrar_top.pressed.connect(cerrar)
	btn_renacimiento_astral.pressed.connect(_on_renacimiento_astral_presionado)
	btn_run_pura.pressed.connect(_on_btn_run_pura_presionado)
	btn_reset_meta.pressed.connect(_on_btn_reset_meta_presionado)

	btn_sector_nucleo.pressed.connect(func(): _enfocar_sector(Vector2.ZERO, 0.78))
	btn_sector_cinetico.pressed.connect(func(): _enfocar_sector(Vector2(-480.0, -210.0), 0.62))
	btn_sector_boton.pressed.connect(func(): _enfocar_sector(Vector2(-650.0, 95.0), 0.66))
	btn_sector_bastion.pressed.connect(func(): _enfocar_sector(Vector2(0.0, 520.0), 0.62))
	btn_sector_arsenal.pressed.connect(func(): _enfocar_sector(Vector2(470.0, -240.0), 0.62))
	btn_sector_cosmica.pressed.connect(func(): _enfocar_sector(Vector2(0.0, -1250.0), 0.62))
	btn_sector_todo.pressed.connect(_on_fit_all_presionado)

	btn_zoom_out.pressed.connect(func(): lienzo._aplicar_zoom(0.82, lienzo.size * 0.5))
	btn_zoom_in.pressed.connect(func(): lienzo._aplicar_zoom(1.22, lienzo.size * 0.5))
	btn_zoom_reset.pressed.connect(func():
		var centro_virt := lienzo.to_virtual_pos(lienzo.size * 0.5)
		lienzo.enfocar_posicion(centro_virt, 1.0)
		AudioManager.play("click", 1.05)
	)
	btn_centrar.pressed.connect(_on_centrar_presionado)
	btn_fit_all.pressed.connect(_on_fit_all_presionado)
	btn_comprar_nodo.pressed.connect(_on_btn_comprar_presionado)

	lienzo.nodo_seleccionado.connect(_on_nodo_seleccionado_en_lienzo)
	lienzo.nodo_compra_rapida.connect(_on_nodo_compra_rapida)
	lienzo.camara_cambiada.connect(_on_camara_cambiada)

	minimap_canvas.draw.connect(_on_minimap_draw)
	minimap_canvas.gui_input.connect(_on_minimap_gui_input)
	medallon_icono.draw.connect(_on_medallon_draw)
	barra_pips.draw.connect(_on_barra_pips_draw)

func _conectar_shaders_paneles():
	var bgs: Array[ColorRect] = [header_main_bg, header_actions_bg, minimap_bg, dock_cam_bg, hint_bg, panel_detalle_bg]
	for bg in bgs:
		if bg == null:
			continue
		if bg.material is ShaderMaterial:
			bg.material = (bg.material as ShaderMaterial).duplicate()
		if not bg.resized.is_connected(_sincronizar_shaders_paneles):
			bg.resized.connect(_sincronizar_shaders_paneles)

func _sincronizar_shaders_paneles():
	var bgs: Array[ColorRect] = [header_main_bg, header_actions_bg, minimap_bg, dock_cam_bg, hint_bg, panel_detalle_bg]
	for bg in bgs:
		if bg != null and bg.material is ShaderMaterial and bg.size.x > 4.0 and bg.size.y > 4.0:
			(bg.material as ShaderMaterial).set_shader_parameter("panel_size", bg.size)

func _process(_delta: float):
	if visible:
		minimap_canvas.queue_redraw()

func _enfocar_sector(pos: Vector2, z: float):
	lienzo.enfocar_posicion(pos, z)
	AudioManager.play("click", 1.1)

func _on_fit_all_presionado():
	lienzo.ajustar_vista_completa()
	AudioManager.play("click", 1.1)

func _on_camara_cambiada(zoom_actual: float):
	if btn_zoom_reset != null:
		btn_zoom_reset.text = "%d%%" % int(round(zoom_actual * 100.0))
	if minimap_canvas != null:
		minimap_canvas.queue_redraw()

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
		var est := ArbolInterconectadoDatos.obtener_estado_nodo(nodo_actual_inspeccionado, diccionario_nodos)
		_actualizar_panel_detalle(nodo_actual_inspeccionado, est)

func _on_btn_reset_meta_presionado():
	if _en_combate_activo():
		return
	var ahora_ms: int = Time.get_ticks_msec()
	if ahora_ms > _confirmar_reset_hasta_ms:
		_confirmar_reset_hasta_ms = ahora_ms + 4000
		if btn_reset_meta != null:
			btn_reset_meta.text = "¿Confirmar?"
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
	var nodo_sel: SkillNodeData = diccionario_nodos.get("nodo_origen", null)
	if nodo_actual_inspeccionado != null and diccionario_nodos.has(nodo_actual_inspeccionado.id):
		nodo_sel = diccionario_nodos[nodo_actual_inspeccionado.id]
	if nodo_sel != null:
		nodo_actual_inspeccionado = nodo_sel
		var est := ArbolInterconectadoDatos.obtener_estado_nodo(nodo_sel, diccionario_nodos)
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
	minimap_canvas.queue_redraw()

func _unhandled_input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_U or event.keycode == KEY_B:
			cerrar()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if not btn_comprar_nodo.disabled:
				_on_btn_comprar_presionado()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_on_fit_all_presionado()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			_on_centrar_presionado()
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
	_sincronizar_shaders_paneles()
	_actualizar_barra_economia()

	var nodo_inicial: SkillNodeData = diccionario_nodos.get("clk_fuerza_1", diccionario_nodos.get("nodo_origen"))
	if nodo_actual_inspeccionado != null and diccionario_nodos.has(nodo_actual_inspeccionado.id):
		nodo_inicial = diccionario_nodos[nodo_actual_inspeccionado.id]
	if nodo_inicial != null:
		lienzo.nodo_seleccionado_id = nodo_inicial.id
		_on_nodo_seleccionado_en_lienzo(nodo_inicial, ArbolInterconectadoDatos.obtener_estado_nodo(nodo_inicial, diccionario_nodos))
	_on_camara_cambiada(lienzo.zoom)

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
			var estado := ArbolInterconectadoDatos.obtener_estado_nodo(nodo_actual_inspeccionado, diccionario_nodos)
			_actualizar_panel_detalle(nodo_actual_inspeccionado, estado)

func _contar_niveles_normales_y_desbloqueados() -> Dictionary:
	var comprados := 0
	var niveles_normales := 0
	for id in diccionario_nodos.keys():
		var n: SkillNodeData = diccionario_nodos[id]
		if n.nivel_actual > 0:
			comprados += 1
			if not id.begins_with("inf_") and not id.begins_with("cosm_"):
				niveles_normales += n.nivel_actual
	return {"nodos": comprados, "niveles_normales": niveles_normales}

func _actualizar_barra_economia():
	MetaprogresoManager.asegurar_inicializado()
	var en_combate: bool = _en_combate_activo()
	var oro_cnt: int = MetaprogresoManager.oro_banco
	var clk_disp: int = MetaprogresoManager.clics_banco

	var stats := _contar_niveles_normales_y_desbloqueados()
	lbl_progreso_top.text = "%d / %d Nodos" % [int(stats["nodos"]), diccionario_nodos.size()]

	label_oro_top.text = "%s Oro" % MetaprogresoManager.formatear_numero(float(oro_cnt))
	label_clics_top.text = "%s Clics" % MetaprogresoManager.formatear_numero(float(clk_disp))
	label_esquirlas_top.text = "%s Esquirlas" % MetaprogresoManager.formatear_numero(float(MetaprogresoManager.esquirlas_astrales))

	var bonus_pct := 0 if MetaprogresoManager.modo_run_pura else int(round(float(MetaprogresoManager.nivel_prestigio) * 15.0))
	label_prestigio_top.text = "Prestigio Nv. %d (+%d%%)" % [MetaprogresoManager.nivel_prestigio, bonus_pct]

	var puede_prestigio: bool = MetaprogresoManager.puede_hacer_prestigio() and not en_combate
	var esquirlas_est: int = MetaprogresoManager.calcular_esquirlas_prestigio()
	if en_combate:
		btn_renacimiento_astral.text = "RENACIMIENTO (Combate)"
	elif puede_prestigio:
		btn_renacimiento_astral.text = "RENACIMIENTO (+%d Esq)" % esquirlas_est
	else:
		var nv_norm := int(stats["niveles_normales"])
		btn_renacimiento_astral.text = "RENACIMIENTO (%d/45 Nv)" % mini(nv_norm, 45)
	btn_renacimiento_astral.disabled = not puede_prestigio
	_aplicar_estilo_boton(btn_renacimiento_astral, Color(0.58, 0.28, 0.92) if puede_prestigio else Color(0.24, 0.28, 0.36), puede_prestigio)

	btn_run_pura.text = "Run Pura: ON" if MetaprogresoManager.modo_run_pura else "Run Pura: OFF"
	btn_run_pura.disabled = en_combate
	_aplicar_estilo_boton(btn_run_pura, Color(0.95, 0.62, 0.16) if MetaprogresoManager.modo_run_pura else Color(0.22, 0.72, 0.90), not en_combate)

	if Time.get_ticks_msec() > _confirmar_reset_hasta_ms:
		btn_reset_meta.text = "Reset Meta"
	btn_reset_meta.disabled = en_combate

func _on_renacimiento_astral_presionado():
	if _en_combate_activo():
		return
	if not MetaprogresoManager.puede_hacer_prestigio():
		return
	MetaprogresoManager.ejecutar_renacimiento_astral()
	AudioManager.play("victoria", 1.3, 3.0)

	diccionario_nodos = ArbolInterconectadoDatos.generar_arbol()
	lienzo.configurar_nodos(diccionario_nodos)
	_sincronizar_niveles_desde_jugador()
	if jugador != null and is_instance_valid(jugador):
		MetaprogresoManager.aplicar_a_personaje(jugador)
	_actualizar_barra_economia()

	if nodo_actual_inspeccionado != null and diccionario_nodos.has(nodo_actual_inspeccionado.id):
		var n_act: SkillNodeData = diccionario_nodos[nodo_actual_inspeccionado.id]
		var est := ArbolInterconectadoDatos.obtener_estado_nodo(n_act, diccionario_nodos)
		_actualizar_panel_detalle(n_act, est)

# ==============================================================================
# INSPECTOR DE DETALLE LATERAL
# ==============================================================================
func _on_nodo_seleccionado_en_lienzo(nodo: SkillNodeData, estado: String):
	nodo_actual_inspeccionado = nodo
	_actualizar_panel_detalle(nodo, estado)
	AudioManager.play("click", 1.15)
	minimap_canvas.queue_redraw()

func _on_nodo_compra_rapida(nodo: SkillNodeData):
	nodo_actual_inspeccionado = nodo
	_intentar_comprar_nodo(nodo)

func _obtener_info_rama(rama: String) -> Dictionary:
	match rama:
		"verde":
			return {"tag": "BIOCONTENCIÓN & TANQUE", "col": Color(0.28, 0.96, 0.52)}
		"dorada":
			return {"tag": "ARSENAL ÁUREO & ECONOMÍA", "col": Color(1.0, 0.80, 0.26)}
		"hibrido":
			return {"tag": "SINERGIA CUÁNTICA HÍBRIDA", "col": Color(0.86, 0.56, 1.0)}
		"cosmico":
			return {"tag": "CORONA CÓSMICA ASTRAL", "col": Color(0.92, 0.68, 1.0)}
		"boton":
			return {"tag": "INGENIERÍA DEL NÚCLEO MÓVIL", "col": Color(1.0, 0.62, 0.25)}
		"central":
			return {"tag": "NÚCLEO DEL REACTOR CERO", "col": Color(0.35, 1.0, 0.72)}
		_:
			return {"tag": "SECTOR CINÉTICO · CLICS", "col": Color(0.28, 0.88, 1.0)}

func _actualizar_panel_detalle(nodo: SkillNodeData, estado: String):
	var info_rama := _obtener_info_rama(nodo.rama)
	var col_rama: Color = info_rama["col"]
	var es_max_finito := (estado == "maxeado" and nodo.nivel_max < 999)
	_detalle_es_dorado = nodo.es_keystone or es_max_finito
	_color_detalle_actual = col_rama

	# Tinte dinámico del backdrop shader del inspector
	if panel_detalle_bg != null and panel_detalle_bg.material is ShaderMaterial:
		var mat := panel_detalle_bg.material as ShaderMaterial
		var col_borde_panel := COLOR_ORO_IMPERIAL if _detalle_es_dorado else col_rama
		mat.set_shader_parameter("border_color", Color(col_borde_panel.r, col_borde_panel.g, col_borde_panel.b, 0.94))
		mat.set_shader_parameter("glow_color", Color(col_rama.r, col_rama.g, col_rama.b, 0.42))
		mat.set_shader_parameter("top_accent_color", Color(COLOR_ORO_IMPERIAL.r, COLOR_ORO_IMPERIAL.g, COLOR_ORO_IMPERIAL.b, 0.90 if _detalle_es_dorado else 0.55))

	# Icono SVG en medallón (cero emojis)
	var tex := IconosArbol.obtener_icono(nodo.id, nodo.rama)
	tex_nodo_icono.texture = tex
	tex_nodo_icono.modulate = IconosArbol.obtener_color_icono(nodo.id, col_rama, estado, nodo.rama)
	medallon_icono.queue_redraw()
	barra_pips.queue_redraw()

	var tag_rama: String = str(info_rama["tag"])
	if nodo.es_keystone:
		tag_rama += " · PROTOCOLO"
	elif nodo.nivel_max >= 999:
		tag_rama += " · INFINITA"
	lbl_nodo_rama.text = tag_rama
	lbl_nodo_rama.add_theme_color_override("font_color", COLOR_ORO_IMPERIAL if _detalle_es_dorado else col_rama)

	lbl_nodo_nombre.text = nodo.nombre
	lbl_nodo_desc.text = nodo.descripcion
	lbl_nodo_bono.text = nodo.obtener_texto_bono()

	if nodo.id == "nodo_origen":
		lbl_nodo_nivel.text = "NÚCLEO"
	elif nodo.nivel_max >= 999:
		lbl_nodo_nivel.text = "∞ Nv. %d" % nodo.nivel_actual
	elif es_max_finito:
		lbl_nodo_nivel.text = "MAX"
	else:
		lbl_nodo_nivel.text = "Nv. %d/%d" % [nodo.nivel_actual, nodo.nivel_max]
	lbl_nodo_nivel.add_theme_color_override("font_color", COLOR_ORO_IMPERIAL if _detalle_es_dorado else Color(0.95, 0.97, 1.0))

	# Estado & Prerequisito inline cuando está bloqueado
	lbl_nodo_prereq.visible = false
	match estado:
		"maxeado":
			lbl_nodo_estado.text = "Módulo saturado: capacidad máxima operativa."
			lbl_nodo_estado.add_theme_color_override("font_color", COLOR_ORO_IMPERIAL)
		"comprado":
			lbl_nodo_estado.text = "Módulo activo: flujo de reactor estable."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.32, 0.96, 0.58))
		"desbloqueable":
			lbl_nodo_estado.text = "Circuito enlazado: listo para inyección."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.34, 0.88, 1.0))
		_:
			if nodo.es_keystone:
				lbl_nodo_estado.text = "🔒 Bloqueado: exige un nodo adyacente al MÁXIMO."
			else:
				lbl_nodo_estado.text = "🔒 Bloqueado: sube un nodo adyacente al 60% de su nivel máximo."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(0.94, 0.40, 0.42))
			var nombres_req: Array[String] = []
			for vec_id in nodo.nodos_conectados:
				if diccionario_nodos.has(vec_id):
					nombres_req.append(str(diccionario_nodos[vec_id].nombre))
			if nombres_req.size() > 0:
				var lista_str := ", ".join(nombres_req.slice(0, 3))
				if nombres_req.size() > 3:
					lista_str += " (+%d)" % (nombres_req.size() - 3)
				lbl_nodo_prereq.text = "Prerequisito: %s" % lista_str
				lbl_nodo_prereq.visible = true

	# Banco vs Costo + Botón CTA codificado por color
	MetaprogresoManager.asegurar_inicializado()
	var oro_actual: int = MetaprogresoManager.oro_banco
	var clics_actuales: int = MetaprogresoManager.clics_banco
	var esquirlas_actuales: int = MetaprogresoManager.esquirlas_astrales
	if nodo.tipo_moneda == "oro":
		lbl_nodo_banco.text = "Banco: %s Oro" % MetaprogresoManager.formatear_numero(float(oro_actual))
	elif nodo.tipo_moneda == "clics":
		lbl_nodo_banco.text = "Banco: %s Clics" % MetaprogresoManager.formatear_numero(float(clics_actuales))
	else:
		lbl_nodo_banco.text = "%s O · %s C" % [MetaprogresoManager.formatear_numero(float(oro_actual)), MetaprogresoManager.formatear_numero(float(clics_actuales))]

	if nodo.id == "nodo_origen":
		lbl_nodo_costo.text = "Costo: Integrado"
		lbl_nodo_costo.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72))
		btn_comprar_nodo.text = "NÚCLEO PRIMORDIAL"
		btn_comprar_nodo.disabled = true
		_aplicar_estilo_boton(btn_comprar_nodo, Color(0.22, 0.65, 0.52), false)
	elif es_max_finito:
		lbl_nodo_costo.text = "Costo: Saturado"
		lbl_nodo_costo.add_theme_color_override("font_color", COLOR_ORO_IMPERIAL)
		btn_comprar_nodo.text = "MÓDULO SATURADO ★"
		btn_comprar_nodo.disabled = true
		_aplicar_estilo_boton(btn_comprar_nodo, COLOR_ORO_IMPERIAL, false)
	else:
		var en_combate: bool = _en_combate_activo()
		var niveles_tot: int = ArbolInterconectadoDatos.contar_niveles_comprados(diccionario_nodos)
		var costos := nodo.calcular_costo(niveles_tot)
		var c_oro := int(costos.get("oro", 0))
		var c_clk := int(costos.get("clics", 0))
		var c_esq := int(costos.get("esquirlas", 0))
		var txt_costo: Array[String] = []
		if c_oro > 0:
			txt_costo.append("%s Oro" % MetaprogresoManager.formatear_numero(float(c_oro)))
		if c_clk > 0:
			txt_costo.append("%s Clics" % MetaprogresoManager.formatear_numero(float(c_clk)))
		if c_esq > 0:
			txt_costo.append("%d Esquirlas" % c_esq)
			lbl_nodo_banco.text += " · %d Esq" % esquirlas_actuales
		var txt_recargo := (" (+%d%% sobrecarga)" % int(round(float(niveles_tot) * 4.5))) if niveles_tot > 0 else ""
		lbl_nodo_costo.text = ("Costo: " + (" + ".join(txt_costo) if txt_costo.size() > 0 else "Gratis")) + txt_recargo

		var puede_pagar := (oro_actual >= c_oro) and (clics_actuales >= c_clk) and (esquirlas_actuales >= c_esq)
		lbl_nodo_costo.add_theme_color_override("font_color", Color(0.98, 0.86, 0.42) if puede_pagar else Color(0.96, 0.44, 0.44))

		if en_combate:
			lbl_nodo_estado.text = "Combate activo: mejoras bloqueadas hasta finalizar la oleada."
			lbl_nodo_estado.add_theme_color_override("font_color", Color(1.0, 0.72, 0.30))
			btn_comprar_nodo.text = "SOLO PRE-COMBATE"
			btn_comprar_nodo.disabled = true
			_aplicar_estilo_boton(btn_comprar_nodo, Color(0.75, 0.48, 0.18), false)
		elif estado == "bloqueado":
			btn_comprar_nodo.text = "SIN CONEXIÓN"
			btn_comprar_nodo.disabled = true
			_aplicar_estilo_boton(btn_comprar_nodo, Color(0.32, 0.36, 0.44), false)
		elif not puede_pagar:
			btn_comprar_nodo.text = "FALTAN RECURSOS"
			btn_comprar_nodo.disabled = true
			_aplicar_estilo_boton(btn_comprar_nodo, Color(0.76, 0.24, 0.28), false)
		else:
			btn_comprar_nodo.text = "INYECTAR NV. %d [Espacio]" % (nodo.nivel_actual + 1)
			btn_comprar_nodo.disabled = false
			_aplicar_estilo_boton(btn_comprar_nodo, col_rama, true)

func _aplicar_estilo_boton(btn: Button, color_borde: Color, activo: bool):
	if btn == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = color_borde.darkened(0.68 if activo else 0.78)
	sb.bg_color.a = 0.95 if activo else 0.72
	sb.border_color = color_borde if activo else color_borde.darkened(0.35)
	sb.set_border_width_all(1)
	sb.border_width_bottom = 2 if activo else 1
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)

	var sb_hov := sb.duplicate() as StyleBoxFlat
	sb_hov.bg_color = color_borde.darkened(0.52)
	sb_hov.border_color = color_borde.lightened(0.20)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0) if activo else Color(0.72, 0.76, 0.84))
	btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.76, 0.84))

func _on_btn_comprar_presionado():
	if nodo_actual_inspeccionado != null:
		_intentar_comprar_nodo(nodo_actual_inspeccionado)

func _intentar_comprar_nodo(nodo: SkillNodeData):
	if _en_combate_activo() or nodo == null or nodo.id == "nodo_origen":
		return

	var estado := ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	if estado == "bloqueado" or (nodo.esta_maxeado() and nodo.nivel_max < 999):
		return

	var niveles_tot: int = ArbolInterconectadoDatos.contar_niveles_comprados(diccionario_nodos)
	var costos := nodo.calcular_costo(niveles_tot)
	MetaprogresoManager.asegurar_inicializado()
	var c_oro := int(costos.get("oro", 0))
	var c_clk := int(costos.get("clics", 0))
	var c_esq := int(costos.get("esquirlas", 0))
	if MetaprogresoManager.oro_banco < c_oro or MetaprogresoManager.clics_banco < c_clk or MetaprogresoManager.esquirlas_astrales < c_esq:
		return

	MetaprogresoManager.oro_banco -= c_oro
	MetaprogresoManager.clics_banco -= c_clk
	MetaprogresoManager.esquirlas_astrales -= c_esq
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

	lienzo.reproducir_efecto_compra(nodo)
	_actualizar_barra_economia()
	var nuevo_estado := ArbolInterconectadoDatos.obtener_estado_nodo(nodo, diccionario_nodos)
	_actualizar_panel_detalle(nodo, nuevo_estado)
	lienzo.queue_redraw()
	minimap_canvas.queue_redraw()

# ==============================================================================
# CUSTOM DRAW: MEDALLÓN DEL INSPECTOR, BARRA DE PIPS Y MINIMAPA TÁCTICO
# ==============================================================================
func _on_medallon_draw():
	var sz := medallon_icono.size
	var c := sz * 0.5
	var r := minf(sz.x, sz.y) * 0.5 - 2.0
	var col_ring := COLOR_ORO_IMPERIAL if _detalle_es_dorado else _color_detalle_actual
	medallon_icono.draw_circle(c, r, Color(0.02, 0.04, 0.075, 0.96))
	medallon_icono.draw_arc(c, r, 0.0, TAU, 36, Color(col_ring.r, col_ring.g, col_ring.b, 0.92), 2.0, true)
	medallon_icono.draw_arc(c, r - 5.0, 0.0, TAU, 32, Color(_color_detalle_actual.r, _color_detalle_actual.g, _color_detalle_actual.b, 0.55), 1.3, true)

func _on_barra_pips_draw():
	if nodo_actual_inspeccionado == null:
		return
	var n := nodo_actual_inspeccionado
	var sz := barra_pips.size
	var col := COLOR_ORO_IMPERIAL if _detalle_es_dorado else _color_detalle_actual

	if n.nivel_max == 1:
		var activo := n.nivel_actual >= 1
		var rect_u := Rect2(Vector2(0, 2), Vector2(sz.x, sz.y - 4))
		barra_pips.draw_rect(rect_u, col if activo else Color(0.10, 0.14, 0.20, 0.90), true)
		barra_pips.draw_rect(rect_u, Color(col.r, col.g, col.b, 0.75), false, 1.0)
		return

	var total_pips := 10 if n.nivel_max >= 999 else clampi(n.nivel_max, 1, 16)
	var llenos := (n.nivel_actual % 10) if n.nivel_max >= 999 else n.nivel_actual
	if n.nivel_max >= 999 and n.nivel_actual > 0 and llenos == 0:
		llenos = 10
	var gap := 4.0
	var pip_w := maxf((sz.x - gap * float(total_pips - 1)) / float(total_pips), 4.0)
	for i in range(total_pips):
		var rx := float(i) * (pip_w + gap)
		var r_pip := Rect2(Vector2(rx, 2.0), Vector2(pip_w, sz.y - 4.0))
		var encendido := i < llenos
		barra_pips.draw_rect(r_pip, col if encendido else Color(0.08, 0.12, 0.18, 0.92), true)
		barra_pips.draw_rect(r_pip, Color(col.r, col.g, col.b, 0.85 if encendido else 0.35), false, 1.0)

func _world_to_minimap(pos_v: Vector2, mini_sz: Vector2) -> Vector2:
	var pad := 8.0
	var inner := Vector2(maxf(mini_sz.x - pad * 2.0, 10.0), maxf(mini_sz.y - pad * 2.0, 10.0))
	var nx := (pos_v.x - MINIMAP_BOUNDS.position.x) / MINIMAP_BOUNDS.size.x
	var ny := (pos_v.y - MINIMAP_BOUNDS.position.y) / MINIMAP_BOUNDS.size.y
	return Vector2(pad + nx * inner.x, pad + ny * inner.y)

func _minimap_to_world(pos_m: Vector2, mini_sz: Vector2) -> Vector2:
	var pad := 8.0
	var inner := Vector2(maxf(mini_sz.x - pad * 2.0, 10.0), maxf(mini_sz.y - pad * 2.0, 10.0))
	var nx := clampf((pos_m.x - pad) / inner.x, 0.0, 1.0)
	var ny := clampf((pos_m.y - pad) / inner.y, 0.0, 1.0)
	return MINIMAP_BOUNDS.position + Vector2(nx * MINIMAP_BOUNDS.size.x, ny * MINIMAP_BOUNDS.size.y)

func _on_minimap_draw():
	var sz := minimap_canvas.size
	if sz.x < 16.0 or sz.y < 16.0 or diccionario_nodos.is_empty():
		return

	minimap_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.015, 0.028, 0.052, 0.85), true)

	MetaprogresoManager.asegurar_inicializado()
	var oro_b := MetaprogresoManager.oro_banco
	var clk_b := MetaprogresoManager.clics_banco
	var esq_b := MetaprogresoManager.esquirlas_astrales
	var niveles_tot := ArbolInterconectadoDatos.contar_niveles_comprados(diccionario_nodos)
	var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)

	# 1. Aristas
	var vistas: Dictionary = {}
	for id_a in diccionario_nodos.keys():
		var na: SkillNodeData = diccionario_nodos[id_a]
		var pa := _world_to_minimap(na.posicion, sz)
		for id_b in na.nodos_conectados:
			if not diccionario_nodos.has(id_b):
				continue
			var s_a: String = str(id_a)
			var s_b: String = str(id_b)
			var par: String = (s_a + "_" + s_b) if s_a < s_b else (s_b + "_" + s_a)
			if vistas.has(par):
				continue
			vistas[par] = true
			var nb: SkillNodeData = diccionario_nodos[id_b]
			var pb := _world_to_minimap(nb.posicion, sz)
			var activa := na.esta_comprado() and nb.esta_comprado()
			var col_e := Color(0.30, 0.85, 0.95, 0.55) if activa else Color(0.18, 0.26, 0.36, 0.42)
			minimap_canvas.draw_line(pa, pb, col_e, 1.1 if activa else 0.8, true)

	# 2. Nodos
	for id in diccionario_nodos.keys():
		var n: SkillNodeData = diccionario_nodos[id]
		var pm := _world_to_minimap(n.posicion, sz)
		var est := ArbolInterconectadoDatos.obtener_estado_nodo(n, diccionario_nodos)
		var pal: Dictionary = LienzoArbolHabilidades.COLORES_RAMA.get(n.rama, LienzoArbolHabilidades.COLORES_RAMA["dorada"])
		var col_n: Color = pal["brillo"]
		var r := 3.2 if n.es_keystone else 2.0

		if est == "bloqueado":
			col_n = Color(0.28, 0.34, 0.42, 0.65)
		elif est == "desbloqueable":
			var c_n := n.calcular_costo(niveles_tot)
			var pagable := oro_b >= int(c_n.get("oro", 0)) and clk_b >= int(c_n.get("clics", 0)) and esq_b >= int(c_n.get("esquirlas", 0))
			if pagable:
				minimap_canvas.draw_circle(pm, r + 2.0 * pulso, Color(col_n.r, col_n.g, col_n.b, 0.45))

		minimap_canvas.draw_circle(pm, r, col_n)
		if id == lienzo.nodo_seleccionado_id:
			minimap_canvas.draw_arc(pm, r + 2.6, 0.0, TAU, 16, COLOR_ORO_IMPERIAL, 1.3, true)

	# 3. Retícula del Viewport de Cámara
	var tl_v := lienzo.to_virtual_pos(Vector2.ZERO)
	var br_v := lienzo.to_virtual_pos(lienzo.size)
	var tl_m := _world_to_minimap(tl_v, sz)
	var br_m := _world_to_minimap(br_v, sz)
	var rect_cam := Rect2(tl_m, br_m - tl_m).intersection(Rect2(Vector2.ZERO, sz))
	if rect_cam.size.x > 2.0 and rect_cam.size.y > 2.0:
		minimap_canvas.draw_rect(rect_cam, Color(0.24, 0.90, 1.0, 0.08), true)
		minimap_canvas.draw_rect(rect_cam, Color(0.28, 0.92, 1.0, 0.88), false, 1.3)

func _on_minimap_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_minimap_arrastrando = event.pressed
		if event.pressed:
			var wp := _minimap_to_world(event.position, minimap_canvas.size)
			lienzo.centrar_en_minimapa(wp)
			minimap_canvas.queue_redraw()
		minimap_canvas.accept_event()
	elif event is InputEventMouseMotion and _minimap_arrastrando:
		var wp := _minimap_to_world(event.position, minimap_canvas.size)
		lienzo.centrar_en_minimapa(wp)
		minimap_canvas.queue_redraw()
		minimap_canvas.accept_event()
