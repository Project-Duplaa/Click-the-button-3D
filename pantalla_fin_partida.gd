extends CanvasLayer

## PantallaFinPartida — Expediente Táctico de Fin de Run y Metaprogresión (Industrial Sci-Fi / Roguelike)
## Transfiere recursos al Banco Permanente sin duplicación, visualiza tasas de extracción (45%/50% vs 100%),
## muestra telemetría del Gladiador y conecta con la Matriz del Reactor (Árbol PoE) y el Códice 3D.

class_name PantallaFinPartida

const AudioManager = preload("res://audio_manager.gd")
const ArbolMejorasPoEEscena = preload("res://arbol_mejoras_poe.tscn")
const ArbolInterconectadoDatos = preload("res://arbol_interconectado_datos.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

const ICON_SKULL = preload("res://ui_assets/icon_skull_hades.svg")
const ICON_VICTORY = preload("res://ui_assets/icon_victory_hades.svg")
const ICON_BOOK = preload("res://ui_assets/icon_book_cyber.svg")
const ICON_SHIELD = preload("res://ui_assets/icon_shield_hades.svg")
const ICON_PRISM = preload("res://ui_assets/icon_prism_hades.svg")

const NOMBRES_CHASIS := {
	"estandar": "Chasis Estándar",
	"termico": "Chasis Térmico",
	"gravitatorio": "Chasis Gravitatorio",
	" sobrecarga": "Chasis de Sobrecarga",
	"sobrecarga": "Chasis de Sobrecarga",
	"cuantico": "Chasis Cuántico",
}

const ACCENTOS_CLASE := {
	"Novato": Color(0.28, 0.94, 0.56),
	"Guerrero": Color(0.98, 0.36, 0.32),
	"Cazador": Color(0.24, 0.92, 0.62),
	"Arquero": Color(0.98, 0.55, 0.18),
	"Mago": Color(0.66, 0.46, 1.00),
}

@onready var panel_fondo: Panel = $Control/Fondo
@onready var backdrop_shader: ColorRect = find_child("BackdropShader", true, false)
@onready var telon_tactico_canvas: Control = find_child("TelonTacticoCanvas", true, false)
@onready var marco_tactico_canvas: Control = find_child("MarcoTacticoCanvas", true, false)
@onready var medallon_crest: Control = find_child("MedallonCrest", true, false)
@onready var divider_top: Control = find_child("DividerTop", true, false)
@onready var barra_ext_oro: Control = find_child("BarraExtraccionOro", true, false)
@onready var barra_ext_clics: Control = find_child("BarraExtraccionClicks", true, false)
@onready var barra_progreso_matriz: Control = find_child("BarraProgresoMatriz", true, false)

@onready var texture_crest: TextureRect = find_child("TextureCrest", true, false)
@onready var label_kicker: Label = find_child("LabelKicker", true, false)
@onready var label_titulo: Label = find_child("LabelTitulo", true, false)
@onready var label_motivo: Label = find_child("LabelMotivo", true, false)
@onready var panel_motivo: PanelContainer = find_child("PanelMotivo", true, false)
@onready var label_rango_run: Label = find_child("LabelRangoRun", true, false)

@onready var label_tiempo: Label = find_child("LabelValTiempo", true, false)
@onready var label_sub_tiempo: Label = find_child("LabelSubTiempo", true, false)
@onready var label_clicks: Label = find_child("LabelValClicks", true, false)
@onready var label_detalle_clicks: Label = find_child("LabelDetalleClicks", true, false)
@onready var label_bajas: Label = find_child("LabelValBajas", true, false)
@onready var label_sub_bajas: Label = find_child("LabelSubBajas", true, false)
@onready var label_nivel: Label = find_child("LabelValNivel", true, false)
@onready var label_subclase: Label = find_child("LabelSubclase", true, false)
@onready var label_build_resumen: Label = find_child("LabelBuildResumen", true, false)
@onready var label_oleada: Label = find_child("LabelValOleada", true, false)
@onready var label_sub_oleada: Label = find_child("LabelSubOleada", true, false)
@onready var label_historial: Label = find_child("LabelValHistorial", true, false)
@onready var label_sub_historial: Label = find_child("LabelSubHistorial", true, false)

@onready var label_tasa_extraccion: Label = find_child("LabelTasaExtraccion", true, false)
@onready var label_oro: Label = find_child("LabelValOro", true, false)
@onready var label_detalle_oro: Label = find_child("LabelDetalleOro", true, false)
@onready var label_intento: Label = find_child("LabelValIntento", true, false)
@onready var label_banco: Label = find_child("LabelValBanco", true, false)
@onready var label_banco_oro: Label = find_child("LabelBancoOro", true, false)
@onready var label_banco_clics: Label = find_child("LabelBancoClics", true, false)
@onready var label_banco_esquirlas: Label = find_child("LabelBancoEsquirlas", true, false)
@onready var label_estado_matriz: Label = find_child("LabelEstadoMatriz", true, false)

@onready var meta_dock_row: HBoxContainer = find_child("MetaDockRow", true, false)
@onready var btn_arbol_meta: Button = find_child("BtnArbolMeta", true, false)
@onready var btn_reintentar: Button = find_child("BtnReintentar", true, false)
@onready var btn_salir: Button = find_child("BtnSalir", true, false)

var arbol_instancia: CanvasLayer = null
var btn_codice_meta: Button = null
var btn_run_pura_fin: Button = null
var _recursos_transferidos: bool = false
var _es_victoria_actual: bool = false
var _fase_anim: float = 0.0
var _progreso_barras: float = 1.0
var _ratio_oro_actual: float = 0.45
var _ratio_clics_actual: float = 0.50
var _oro_run_cache: int = 0
var _oro_banco_gan_cache: int = 0
var _clics_run_cache: int = 0
var _clics_banco_gan_cache: int = 0
var _pct_oro_cache: int = 45
var _pct_clics_cache: int = 50
var _ratio_prestigio_matriz: float = 0.0

func _ready() -> void:
	add_to_group("pantalla_fin_partida")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if backdrop_shader != null and backdrop_shader.material is ShaderMaterial:
		backdrop_shader.material = (backdrop_shader.material as ShaderMaterial).duplicate()
		if not backdrop_shader.resized.is_connected(_sincronizar_shader_panel):
			backdrop_shader.resized.connect(_sincronizar_shader_panel)

	if telon_tactico_canvas != null:
		telon_tactico_canvas.draw.connect(_on_telon_tactico_draw)
	if marco_tactico_canvas != null:
		marco_tactico_canvas.draw.connect(_on_marco_tactico_draw)
	if medallon_crest != null:
		medallon_crest.draw.connect(_on_medallon_crest_draw)
	if divider_top != null:
		divider_top.draw.connect(_on_divider_top_draw)
	if barra_ext_oro != null:
		barra_ext_oro.draw.connect(_on_barra_oro_draw)
	if barra_ext_clics != null:
		barra_ext_clics.draw.connect(_on_barra_clics_draw)
	if barra_progreso_matriz != null:
		barra_progreso_matriz.draw.connect(_on_barra_matriz_draw)

	if btn_reintentar != null:
		btn_reintentar.pressed.connect(_on_btn_reintentar_pressed)
	if btn_salir != null:
		btn_salir.pressed.connect(_on_btn_salir_pressed)
	if btn_arbol_meta != null:
		btn_arbol_meta.icon = ICON_PRISM
		btn_arbol_meta.expand_icon = true
		btn_arbol_meta.add_theme_constant_override("icon_max_width", 18)
		btn_arbol_meta.add_theme_constant_override("h_separation", 8)
		btn_arbol_meta.pressed.connect(_on_btn_arbol_meta_pressed)

	_crear_boton_codice_meta()
	_crear_boton_run_pura()
	_aplicar_tema_botones_accion(false)
	call_deferred("_sincronizar_shader_panel")

func _process(delta: float) -> void:
	if not visible:
		return
	_fase_anim += delta
	if medallon_crest != null:
		medallon_crest.queue_redraw()
	if telon_tactico_canvas != null:
		telon_tactico_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if arbol_instancia != null and is_instance_valid(arbol_instancia) and arbol_instancia.visible:
		return
	var codice = get_tree().get_first_node_in_group("codice_gladiador_ui") if get_tree() != null else null
	if codice != null and "visible" in codice and codice.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_on_btn_reintentar_pressed()

func _sincronizar_shader_panel() -> void:
	if backdrop_shader != null and backdrop_shader.material is ShaderMaterial and backdrop_shader.size.x > 16.0:
		(backdrop_shader.material as ShaderMaterial).set_shader_parameter("panel_size", backdrop_shader.size)
	if marco_tactico_canvas != null:
		marco_tactico_canvas.queue_redraw()

func _crear_boton_codice_meta() -> void:
	var contenedor: Node = meta_dock_row if meta_dock_row != null else find_child("VBox", true, false)
	if contenedor == null:
		return

	btn_codice_meta = Button.new()
	btn_codice_meta.name = "BtnCodiceFin"
	btn_codice_meta.custom_minimum_size = Vector2(0, 42)
	btn_codice_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_codice_meta.size_flags_stretch_ratio = 1.0
	btn_codice_meta.text = "CÓDICE & BESTIARIO 3D"
	btn_codice_meta.icon = ICON_BOOK
	btn_codice_meta.expand_icon = true
	btn_codice_meta.add_theme_constant_override("icon_max_width", 18)
	btn_codice_meta.add_theme_constant_override("h_separation", 8)
	btn_codice_meta.focus_mode = Control.FOCUS_NONE
	btn_codice_meta.add_theme_font_size_override("font_size", 12)

	_estilizar_boton_tactico(
		btn_codice_meta,
		Color(0.11, 0.08, 0.22, 0.95),
		Color(0.64, 0.44, 0.98, 0.90),
		Color(0.92, 0.86, 1.0)
	)
	btn_codice_meta.pressed.connect(_on_btn_codice_meta_pressed)
	contenedor.add_child(btn_codice_meta)

func _crear_boton_run_pura() -> void:
	var contenedor: Node = meta_dock_row if meta_dock_row != null else find_child("VBox", true, false)
	if contenedor == null:
		return

	btn_run_pura_fin = Button.new()
	btn_run_pura_fin.name = "BtnRunPuraFin"
	btn_run_pura_fin.custom_minimum_size = Vector2(0, 42)
	btn_run_pura_fin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_run_pura_fin.size_flags_stretch_ratio = 0.92
	btn_run_pura_fin.icon = ICON_SHIELD
	btn_run_pura_fin.expand_icon = true
	btn_run_pura_fin.add_theme_constant_override("icon_max_width", 18)
	btn_run_pura_fin.add_theme_constant_override("h_separation", 8)
	btn_run_pura_fin.focus_mode = Control.FOCUS_NONE
	btn_run_pura_fin.add_theme_font_size_override("font_size", 12)
	btn_run_pura_fin.pressed.connect(_on_btn_run_pura_fin_pressed)

	contenedor.add_child(btn_run_pura_fin)
	_actualizar_texto_run_pura()

func _estilizar_boton_tactico(btn: Button, bg: Color, borde: Color, col_texto: Color) -> void:
	if btn == null:
		return
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg
	sb_normal.set_border_width_all(1)
	sb_normal.border_width_bottom = 2
	sb_normal.border_color = borde
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_left = 12.0
	sb_normal.content_margin_right = 12.0
	sb_normal.content_margin_top = 6.0
	sb_normal.content_margin_bottom = 6.0
	sb_normal.shadow_color = Color(borde.r, borde.g, borde.b, 0.22)
	sb_normal.shadow_size = 8

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg.lightened(0.16)
	sb_hover.border_color = borde.lightened(0.24)
	sb_hover.shadow_size = 14

	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = bg.darkened(0.15)
	sb_pressed.border_color = borde.lightened(0.30)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", col_texto)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

func _aplicar_tema_botones_accion(es_victoria: bool) -> void:
	_estilizar_boton_tactico(
		btn_arbol_meta,
		Color(0.03, 0.24, 0.20, 0.96),
		Color(0.18, 0.94, 0.70, 0.95),
		Color(0.92, 1.0, 0.96)
	)
	if es_victoria:
		_estilizar_boton_tactico(
			btn_reintentar,
			Color(0.32, 0.22, 0.04, 0.96),
			Color(0.98, 0.80, 0.18, 0.98),
			Color(1.0, 0.97, 0.86)
		)
	else:
		_estilizar_boton_tactico(
			btn_reintentar,
			Color(0.34, 0.06, 0.14, 0.96),
			Color(0.96, 0.26, 0.38, 0.98),
			Color(1.0, 0.94, 0.96)
		)
	_estilizar_boton_tactico(
		btn_salir,
		Color(0.05, 0.08, 0.14, 0.92),
		Color(0.30, 0.42, 0.58, 0.65),
		Color(0.76, 0.84, 0.94)
	)

func _actualizar_texto_run_pura() -> void:
	if btn_run_pura_fin == null:
		return
	MetaprogresoManager.asegurar_inicializado()
	if MetaprogresoManager.modo_run_pura:
		btn_run_pura_fin.text = "RUN PURA: ACTIVA (0% META)"
		_estilizar_boton_tactico(
			btn_run_pura_fin,
			Color(0.05, 0.22, 0.30, 0.96),
			Color(0.25, 0.92, 1.0, 0.96),
			Color(0.65, 0.98, 1.0)
		)
	else:
		btn_run_pura_fin.text = "RUN PURA: OFF (CON MATRIZ)"
		_estilizar_boton_tactico(
			btn_run_pura_fin,
			Color(0.05, 0.10, 0.18, 0.94),
			Color(0.24, 0.56, 0.78, 0.72),
			Color(0.78, 0.88, 0.96)
		)

func _on_btn_run_pura_fin_pressed() -> void:
	AudioManager.play("click", 1.15)
	MetaprogresoManager.asegurar_inicializado()
	MetaprogresoManager.establecer_modo_run_pura(not MetaprogresoManager.modo_run_pura)
	_actualizar_texto_run_pura()

func _on_btn_codice_meta_pressed() -> void:
	AudioManager.play("click", 1.2)
	var codice = get_tree().get_first_node_in_group("codice_gladiador_ui")
	if codice == null and ResourceLoader.exists("res://codice_gladiador_ui.gd"):
		var scr = load("res://codice_gladiador_ui.gd")
		if scr != null:
			codice = scr.new()
			codice.name = "CodiceGladiadorUI"
			codice.add_to_group("codice_gladiador_ui")
			if "layer" in codice:
				codice.layer = 30
			var root = get_tree().root if get_tree() != null else get_parent()
			if root != null:
				root.add_child(codice)
	if codice != null and codice.has_method("toggle"):
		if "layer" in codice:
			codice.layer = 30
		codice.toggle()

func _formatear_num(n: Variant) -> String:
	return str(MetaprogresoManager.formatear_numero(n))

func _aplicar_estetica_resultado(es_victoria: bool, motivo: String) -> void:
	_es_victoria_actual = es_victoria
	_aplicar_tema_botones_accion(es_victoria)

	var mat_sh: ShaderMaterial = backdrop_shader.material as ShaderMaterial if backdrop_shader != null else null
	var sb_motivo := StyleBoxFlat.new()
	sb_motivo.set_corner_radius_all(5)
	sb_motivo.border_width_left = 3
	sb_motivo.border_width_top = 1
	sb_motivo.border_width_right = 1
	sb_motivo.border_width_bottom = 1
	sb_motivo.content_margin_left = 12.0
	sb_motivo.content_margin_right = 12.0
	sb_motivo.content_margin_top = 4.0
	sb_motivo.content_margin_bottom = 4.0

	if es_victoria:
		if mat_sh != null:
			mat_sh.set_shader_parameter("bg_top", Color(0.035, 0.075, 0.125, 0.96))
			mat_sh.set_shader_parameter("bg_bot", Color(0.014, 0.030, 0.060, 0.98))
			mat_sh.set_shader_parameter("border_color", Color(0.98, 0.80, 0.18, 0.98))
			mat_sh.set_shader_parameter("glow_color", Color(0.98, 0.72, 0.12, 0.45))
			mat_sh.set_shader_parameter("top_accent_color", Color(0.35, 0.96, 1.0, 0.95))
		if texture_crest != null:
			texture_crest.texture = ICON_VICTORY
		if label_kicker != null:
			label_kicker.text = "// PROTOCOLO DE ASCENSIÓN COMPLETADO · EXTRACCIÓN ÍNTEGRA 100% //"
			label_kicker.add_theme_color_override("font_color", Color(0.38, 0.95, 1.0, 0.96))
		if label_titulo != null:
			label_titulo.text = "¡VICTORIA GLORIOSA EN EL COLISEO!"
			label_titulo.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90))
			label_titulo.add_theme_color_override("font_outline_color", Color(0.72, 0.48, 0.04, 1.0))
		sb_motivo.bg_color = Color(0.16, 0.12, 0.03, 0.85)
		sb_motivo.border_color = Color(0.98, 0.80, 0.20, 0.85)
		if panel_motivo != null:
			panel_motivo.add_theme_stylebox_override("panel", sb_motivo)
		if label_motivo != null:
			label_motivo.text = "🏆 " + ("Has conquistado la arena y dominado la anomalía del Núcleo." if motivo == "" else motivo)
			label_motivo.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62, 1.0))
		if label_tasa_extraccion != null:
			label_tasa_extraccion.text = "BONO DE VICTORIA: EXTRACCIÓN 100%"
			label_tasa_extraccion.add_theme_color_override("font_color", Color(0.32, 0.98, 0.72, 1.0))
		if btn_reintentar != null:
			btn_reintentar.text = "⚔️ SIGUIENTE ARENA DEL COLISEO [ESPACIO]"
	else:
		if mat_sh != null:
			mat_sh.set_shader_parameter("bg_top", Color(0.045, 0.052, 0.105, 0.96))
			mat_sh.set_shader_parameter("bg_bot", Color(0.016, 0.022, 0.048, 0.98))
			mat_sh.set_shader_parameter("border_color", Color(0.957, 0.247, 0.369, 0.96))
			mat_sh.set_shader_parameter("glow_color", Color(0.957, 0.16, 0.30, 0.45))
			mat_sh.set_shader_parameter("top_accent_color", Color(1.0, 0.42, 0.52, 0.92))
		if texture_crest != null:
			texture_crest.texture = ICON_SKULL
		if label_kicker != null:
			label_kicker.text = "// TELEMETRÍA DE BIOCONTENCIÓN · REPORTE TÁCTICO DE FIN DE RUN //"
			label_kicker.add_theme_color_override("font_color", Color(0.98, 0.44, 0.54, 0.95))
		if label_titulo != null:
			label_titulo.text = "HAS CAÍDO EN COMBATE"
			label_titulo.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
			label_titulo.add_theme_color_override("font_outline_color", Color(0.75, 0.08, 0.22, 1.0))
		sb_motivo.bg_color = Color(0.15, 0.035, 0.075, 0.85)
		sb_motivo.border_color = Color(0.957, 0.247, 0.369, 0.75)
		if panel_motivo != null:
			panel_motivo.add_theme_stylebox_override("panel", sb_motivo)
		if label_motivo != null:
			label_motivo.text = "💀 " + ("Tus fuerzas sucumbieron ante la horda del coliseo." if motivo == "" else ("Causa: " + motivo))
			label_motivo.add_theme_color_override("font_color", Color(0.99, 0.70, 0.74, 1.0))
		if label_tasa_extraccion != null:
			label_tasa_extraccion.text = "EXTRACCIÓN DE EMERGENCIA: 45% ORO · 50% CLICS"
			label_tasa_extraccion.add_theme_color_override("font_color", Color(0.98, 0.62, 0.36, 1.0))
		if btn_reintentar != null:
			btn_reintentar.text = "⚔️ DESPLEGAR SIGUIENTE RUN [ESPACIO]"

	if divider_top != null:
		divider_top.queue_redraw()
	if medallon_crest != null:
		medallon_crest.queue_redraw()
	if marco_tactico_canvas != null:
		marco_tactico_canvas.queue_redraw()
	if telon_tactico_canvas != null:
		telon_tactico_canvas.queue_redraw()

func _calcular_evaluacion_tactica(es_victoria: bool, bajas: int, nivel: int, oleada: int) -> Dictionary:
	var score: int = bajas * 2 + nivel * 25 + oleada * 45 + (350 if es_victoria else 0)
	if es_victoria and score >= 750:
		return {"grado": "S+", "titulo": "SOBERANO DEL NÚCLEO", "color": Color(1.0, 0.86, 0.24)}
	elif es_victoria or score >= 520:
		return {"grado": "S", "titulo": "CAMPEÓN DE BIOCONTENCIÓN", "color": Color(0.32, 0.96, 1.0)}
	elif score >= 320:
		return {"grado": "A", "titulo": "VETERANO DE FOSO", "color": Color(0.28, 0.95, 0.66)}
	elif score >= 160:
		return {"grado": "B", "titulo": "COMBATIENTE TÁCTICO", "color": Color(0.65, 0.84, 1.0)}
	return {"grado": "C", "titulo": "RECLUTA EN PRUEBA", "color": Color(0.82, 0.76, 0.88)}

func mostrar(es_victoria: bool, motivo: String = "") -> void:
	visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true

	if es_victoria:
		AudioManager.play("victoria", 1.0, 2.0)
	else:
		AudioManager.play("derrota", 1.0, 2.0)

	_aplicar_estetica_resultado(es_victoria, motivo)

	var pj = get_tree().get_first_node_in_group("jugador") if get_tree() != null else null
	if pj == null:
		var root_nodo = get_tree().root if get_tree() != null else get_parent()
		if root_nodo != null:
			pj = root_nodo.find_child("Personaje", true, false)
	var hud = get_tree().get_first_node_in_group("hud") if get_tree() != null else null
	if hud == null and get_parent() != null:
		hud = get_parent().get_node_or_null("ClickHUD")
	var partida = get_tree().get_first_node_in_group("partida") if get_tree() != null else null
	var spawner = get_tree().get_first_node_in_group("oleadas_spawner") if get_tree() != null else null

	var tiempo_s: float = 0.0
	var clicks_cnt: int = 0
	var bajas_cnt: int = 0
	var nivel_num: int = 1
	var clase_str: String = "Novato"
	var subclase_str: String = ""
	var oro_cnt: int = 0
	var num_intento: int = 1
	var es_abismo: bool = false
	var oleada_num: int = 1
	var cant_reliquias: int = 0
	var cant_sinergias: int = 0

	if hud != null:
		if "tiempo_total" in hud:
			tiempo_s = float(hud.tiempo_total)
		if "clicks_boton" in hud:
			clicks_cnt = int(hud.clicks_boton)
	if pj != null:
		bajas_cnt = int(pj.bajas) if "bajas" in pj else 0
		nivel_num = int(pj.nivel) if "nivel" in pj else 1
		clase_str = str(pj.clase) if "clase" in pj else "Novato"
		oro_cnt = int(pj.oro) if "oro" in pj else 0
		if "clics_disponibles" in pj:
			clicks_cnt = int(pj.clics_disponibles)
		if "subclase_tier2" in pj and str(pj.subclase_tier2) != "":
			subclase_str = str(pj.subclase_tier2)
		elif "subclase_tier1" in pj and str(pj.subclase_tier1) != "":
			subclase_str = str(pj.subclase_tier1)
		if "bendiciones_run" in pj and pj.bendiciones_run is Dictionary:
			cant_reliquias = (pj.bendiciones_run as Dictionary).size()
		if "sinergias_activas" in pj:
			if pj.sinergias_activas is Array:
				cant_sinergias = (pj.sinergias_activas as Array).size()
			elif pj.sinergias_activas is Dictionary:
				cant_sinergias = (pj.sinergias_activas as Dictionary).size()
	if partida != null:
		if "intentos" in partida:
			num_intento = int(partida.intentos)
		if "modo_abismo" in partida:
			es_abismo = bool(partida.modo_abismo)
	if spawner != null and "oleada_actual" in spawner:
		oleada_num = maxi(1, int(spawner.oleada_actual))

	var min_val: int = int(tiempo_s) / 60
	var seg_val: int = int(tiempo_s) % 60

	if label_tiempo != null:
		label_tiempo.text = "%02d:%02d min" % [min_val, seg_val]
	if label_sub_tiempo != null:
		if es_abismo:
			label_sub_tiempo.text = "Modo Abismo Infinito (x4 Botín)"
		elif es_victoria:
			label_sub_tiempo.text = "Supervivencia completa confirmada"
		else:
			label_sub_tiempo.text = "Duración total del despliegue"

	if label_bajas != null:
		label_bajas.text = "%s enemigos" % _formatear_num(bajas_cnt)
	if label_sub_bajas != null:
		var kpm: float = (float(bajas_cnt) / maxf(tiempo_s / 60.0, 0.25)) if bajas_cnt > 0 else 0.0
		label_sub_bajas.text = "Cadencia táctica: %.1f bajas/min" % kpm

	if label_nivel != null:
		label_nivel.text = "%s (Nv. %d)" % [clase_str, nivel_num]
		var col_c: Color = ACCENTOS_CLASE.get(clase_str, Color(0.28, 0.95, 0.68))
		label_nivel.add_theme_color_override("font_color", col_c)

	MetaprogresoManager.asegurar_inicializado()
	var chasis_id: String = str(MetaprogresoManager.chasis_equipado)
	var chasis_nom: String = str(NOMBRES_CHASIS.get(chasis_id, "Chasis Estándar"))
	if label_subclase != null:
		var asc_txt: String = subclase_str if subclase_str != "" else ("Especialidad " + clase_str)
		label_subclase.text = "Ascensión: %s  ·  %s" % [asc_txt, chasis_nom]

	if label_build_resumen != null:
		var modo_txt: String = "Run Pura (0% Meta)" if MetaprogresoManager.modo_run_pura else "Matriz Activa"
		label_build_resumen.text = "%d Bendiciones  ·  %d Sinergias  ·  %s" % [cant_reliquias, cant_sinergias, modo_txt]

	if label_oleada != null:
		label_oleada.text = "Oleada %d%s" % [oleada_num, " · ABISMO" if es_abismo else ""]
	if label_sub_oleada != null:
		var fm = get_tree().root.get_node_or_null("FortunaManager") if (get_tree() != null and get_tree().root != null) else null
		if fm != null and "presagio_nombre" in fm and str(fm.presagio_nombre) != "":
			label_sub_oleada.text = "Presagio: " + str(fm.presagio_nombre)
		else:
			label_sub_oleada.text = "Sector: Coliseo Reactor Cero"

	if label_intento != null:
		label_intento.text = "#%d" % num_intento

	var eval_info: Dictionary = _calcular_evaluacion_tactica(es_victoria, bajas_cnt, nivel_num, oleada_num)
	if label_rango_run != null:
		label_rango_run.text = "RANGO %s · %s" % [str(eval_info["grado"]), str(eval_info["titulo"])]
		label_rango_run.add_theme_color_override("font_color", eval_info["color"])

	if label_clicks != null:
		label_clicks.text = "+%s clics" % _formatear_num(clicks_cnt)
	if label_oro != null:
		label_oro.text = "+%s monedas" % _formatear_num(oro_cnt)

	# Metaprogresión Roguelike: depositar ganancias de la run en la cuenta permanente
	if not _recursos_transferidos:
		_recursos_transferidos = true
		# activar_modo_abismo() ya contó MetaprogresoManager.victorias += 1 al entrar al Abismo
		var victoria_para_meta := es_victoria and not es_abismo
		var transfer := MetaprogresoManager.transferir_recursos_run(oro_cnt, clicks_cnt, bajas_cnt, victoria_para_meta)
		var oro_banco_gan := int(transfer.get("oro_transferido", oro_cnt))
		var clics_banco_gan := int(transfer.get("clics_transferidos", clicks_cnt))
		_ratio_oro_actual = float(transfer.get("ratio_oro", 1.0 if victoria_para_meta else 0.45))
		_ratio_clics_actual = float(transfer.get("ratio_clics", 1.0 if victoria_para_meta else 0.50))
		var pct_oro := int(round(_ratio_oro_actual * 100.0))
		var pct_clics := int(round(_ratio_clics_actual * 100.0))

		_oro_run_cache = oro_cnt
		_oro_banco_gan_cache = oro_banco_gan
		_clics_run_cache = clicks_cnt
		_clics_banco_gan_cache = clics_banco_gan
		_pct_oro_cache = pct_oro
		_pct_clics_cache = pct_clics

		if label_oro != null:
			label_oro.text = "+%s/%s banco (%d%%)" % [_formatear_num(oro_banco_gan), _formatear_num(oro_cnt), pct_oro]
		if label_clicks != null:
			label_clicks.text = "+%s/%s banco (%d%%)" % [_formatear_num(clics_banco_gan), _formatear_num(clicks_cnt), pct_clics]
		if label_detalle_oro != null:
			var perdido_oro: int = maxi(0, oro_cnt - oro_banco_gan)
			if victoria_para_meta:
				label_detalle_oro.text = "Recolectado en arena: %s · Extraído sin pérdidas (100%%)" % _formatear_num(oro_cnt)
			else:
				label_detalle_oro.text = "Recolectado: %s · Depositado: +%s · Disipado al caer: -%s" % [
					_formatear_num(oro_cnt), _formatear_num(oro_banco_gan), _formatear_num(perdido_oro)
				]
		if label_detalle_clicks != null:
			var perdido_clk: int = maxi(0, clicks_cnt - clics_banco_gan)
			if victoria_para_meta:
				label_detalle_clicks.text = "Descargas en arena: %s · Extraído sin pérdidas (100%%)" % _formatear_num(clicks_cnt)
			else:
				label_detalle_clicks.text = "En arena: %s · Depositado: +%s · Disipado al caer: -%s" % [
					_formatear_num(clicks_cnt), _formatear_num(clics_banco_gan), _formatear_num(perdido_clk)
				]

		if pj != null:
			pj.oro = 0
			pj.clics_disponibles = 0
			if pj.has_signal("economia_actualizada"):
				pj.emit_signal("economia_actualizada", 0, 0, pj.clics_totales)

		var logros = get_tree().get_first_node_in_group("logros_manager") if get_tree() != null else null
		if logros != null and logros.has_method("registrar_fin_partida"):
			logros.registrar_fin_partida(es_victoria or es_abismo, bajas_cnt, clicks_cnt, nivel_num)

		# Registro de récord diario si la run era el desafío del día (3 argumentos exactos)
		var fm_autoload = get_tree().root.get_node_or_null("FortunaManager") if (get_tree() != null and get_tree().root != null) else null
		if fm_autoload != null and "es_run_diaria" in fm_autoload and fm_autoload.es_run_diaria:
			MetaprogresoManager.actualizar_record_diario(fm_autoload.fecha_seed_diaria, bajas_cnt, tiempo_s)

	if label_historial != null:
		label_historial.text = "%d Victorias · %d Runs" % [
			int(MetaprogresoManager.victorias),
			maxi(1, int(MetaprogresoManager.runs_jugadas))
		]
	if label_sub_historial != null:
		var mult_p: float = MetaprogresoManager.obtener_multiplicador_prestigio()
		label_sub_historial.text = "Prestigio Nv. %d (x%.2f Poder Global)" % [
			int(MetaprogresoManager.nivel_prestigio),
			mult_p
		]

	_actualizar_labels_banco()
	_actualizar_texto_run_pura()
	_sincronizar_shader_panel()
	_animar_entrada_expediente()

func _animar_entrada_expediente() -> void:
	_progreso_barras = 0.0
	if barra_ext_oro != null:
		barra_ext_oro.queue_redraw()
	if barra_ext_clics != null:
		barra_ext_clics.queue_redraw()

	if panel_fondo != null:
		panel_fondo.pivot_offset = panel_fondo.size * 0.5
		panel_fondo.scale = Vector2(0.90, 0.90)
		panel_fondo.modulate = Color(1, 1, 1, 0)

	var tw := create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if panel_fondo != null:
		tw.tween_property(panel_fondo, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel_fondo, "modulate", Color.WHITE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_actualizar_anim_extraccion, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _actualizar_anim_extraccion(t: float) -> void:
	_progreso_barras = clampf(t, 0.0, 1.0)
	if barra_ext_oro != null:
		barra_ext_oro.queue_redraw()
	if barra_ext_clics != null:
		barra_ext_clics.queue_redraw()
	if barra_progreso_matriz != null:
		barra_progreso_matriz.queue_redraw()

func _contar_niveles_normales_prestigio() -> int:
	var niveles_normales: int = 0
	for k in MetaprogresoManager.mejoras_arbol.keys():
		var id_str := str(k)
		if id_str == "nodo_origen":
			continue
		if not id_str.begins_with("inf_") and not id_str.begins_with("cosm_"):
			niveles_normales += maxi(0, int(MetaprogresoManager.mejoras_arbol[k]))
	return niveles_normales

func _contar_nodos_comprables_en_matriz() -> int:
	var nodos: Dictionary = ArbolInterconectadoDatos.generar_arbol()
	for id_n in MetaprogresoManager.mejoras_arbol.keys():
		if nodos.has(id_n):
			nodos[id_n].nivel_actual = int(MetaprogresoManager.mejoras_arbol[id_n])
	var comprables: int = 0
	for k in nodos.keys():
		if str(k) == "nodo_origen":
			continue
		var nd: SkillNodeData = nodos[k]
		if ArbolInterconectadoDatos.es_nodo_desbloqueable(nd, nodos) and MetaprogresoManager.puede_comprar(nd):
			comprables += 1
	return comprables

func _actualizar_labels_banco() -> void:
	MetaprogresoManager.asegurar_inicializado()
	var oro_b: int = int(MetaprogresoManager.oro_banco)
	var clics_b: int = int(MetaprogresoManager.clics_banco)
	var esquirlas: int = int(MetaprogresoManager.esquirlas_astrales)

	if label_banco != null:
		label_banco.text = "%s Monedas | %s Clics | %d Esquirlas" % [
			_formatear_num(oro_b),
			_formatear_num(clics_b),
			esquirlas
		]
	if label_banco_oro != null:
		label_banco_oro.text = "%s Oro" % _formatear_num(oro_b)
	if label_banco_clics != null:
		label_banco_clics.text = "%s Clics" % _formatear_num(clics_b)
	if label_banco_esquirlas != null:
		label_banco_esquirlas.text = "%d Esquirlas" % esquirlas

	var nv_arbol: int = _contar_niveles_normales_prestigio()
	_ratio_prestigio_matriz = clampf(float(nv_arbol) / 45.0, 0.0, 1.0)
	if barra_progreso_matriz != null:
		barra_progreso_matriz.queue_redraw()
	var comprables: int = _contar_nodos_comprables_en_matriz()

	if label_estado_matriz != null:
		if MetaprogresoManager.puede_hacer_prestigio():
			label_estado_matriz.text = "🌟 ¡RENACIMIENTO ASTRAL DISPONIBLE EN LA MATRIZ! (%d/45 Nv.)" % nv_arbol
			label_estado_matriz.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30, 1.0))
		elif comprables > 0:
			label_estado_matriz.text = "⚡ %d nodos disponibles para desbloquear/mejorar ahora · Progreso Prestigio: %d/45 Nv." % [comprables, nv_arbol]
			label_estado_matriz.add_theme_color_override("font_color", Color(0.32, 0.98, 0.72, 1.0))
		else:
			label_estado_matriz.text = "✦ Matriz del Reactor: %d/45 Nv. comprados para Prestigio Astral" % nv_arbol
			label_estado_matriz.add_theme_color_override("font_color", Color(0.58, 0.76, 0.90, 0.92))

	if btn_arbol_meta != null:
		if comprables > 0:
			btn_arbol_meta.text = "MATRIZ DEL REACTOR (%d MEJORAS DISPONIBLES) · %s Oro | %s Clics" % [
				comprables,
				_formatear_num(oro_b),
				_formatear_num(clics_b)
			]
		else:
			btn_arbol_meta.text = "MATRIZ DEL REACTOR (ÁRBOL DE HABILIDADES) · %s Oro | %s Clics" % [
				_formatear_num(oro_b),
				_formatear_num(clics_b)
			]

# ==============================================================================
# DIBUJO PROCEDURAL SCI-FI (MEDALLÓN, MARCO TÁCTICO Y BARRAS DE EXTRACCIÓN)
# ==============================================================================
func _on_telon_tactico_draw() -> void:
	if telon_tactico_canvas == null:
		return
	var sz: Vector2 = telon_tactico_canvas.size
	if sz.x < 32.0 or sz.y < 32.0:
		return
	var c: Vector2 = sz * 0.5
	var col_accent: Color = Color(0.98, 0.78, 0.18) if _es_victoria_actual else Color(0.96, 0.22, 0.36)
	var pulse: float = 0.5 + 0.5 * sin(_fase_anim * 2.2)

	# Anillos sutiles de radar en el fondo
	telon_tactico_canvas.draw_arc(c, 370.0 + pulse * 8.0, 0.0, TAU, 72, Color(col_accent.r, col_accent.g, col_accent.b, 0.08), 1.5, true)
	telon_tactico_canvas.draw_arc(c, 460.0 - pulse * 6.0, 0.0, TAU, 72, Color(0.18, 0.82, 1.0, 0.06), 1.0, true)

	# Líneas de escaneo horizontales tenues
	var step_y: float = 36.0
	var y: float = fmod(_fase_anim * 14.0, step_y)
	while y < sz.y:
		telon_tactico_canvas.draw_line(Vector2(0.0, y), Vector2(sz.x, y), Color(0.15, 0.75, 0.98, 0.025), 1.0)
		y += step_y

func _on_marco_tactico_draw() -> void:
	if marco_tactico_canvas == null:
		return
	var sz: Vector2 = marco_tactico_canvas.size
	if sz.x < 64.0 or sz.y < 64.0:
		return
	var col_b: Color = Color(0.98, 0.82, 0.22, 0.78) if _es_victoria_actual else Color(0.96, 0.28, 0.40, 0.78)
	var col_c: Color = Color(0.22, 0.88, 1.0, 0.55)
	var pad: float = 16.0
	var b_len: float = 24.0

	# Escuadras tácticas internas en las 4 esquinas
	# TL
	marco_tactico_canvas.draw_line(Vector2(pad, pad + b_len), Vector2(pad, pad + 8.0), col_c, 1.6)
	marco_tactico_canvas.draw_line(Vector2(pad + 8.0, pad), Vector2(pad + b_len, pad), col_c, 1.6)
	# TR
	marco_tactico_canvas.draw_line(Vector2(sz.x - pad - b_len, pad), Vector2(sz.x - pad - 8.0, pad), col_c, 1.6)
	marco_tactico_canvas.draw_line(Vector2(sz.x - pad, pad + 8.0), Vector2(sz.x - pad, pad + b_len), col_c, 1.6)
	# BL
	marco_tactico_canvas.draw_line(Vector2(pad, sz.y - pad - b_len), Vector2(pad, sz.y - pad - 8.0), col_b, 1.6)
	marco_tactico_canvas.draw_line(Vector2(pad + 8.0, sz.y - pad), Vector2(pad + b_len, sz.y - pad), col_b, 1.6)
	# BR
	marco_tactico_canvas.draw_line(Vector2(sz.x - pad - b_len, sz.y - pad), Vector2(sz.x - pad - 8.0, sz.y - pad), col_b, 1.6)
	marco_tactico_canvas.draw_line(Vector2(sz.x - pad, sz.y - pad - 8.0), Vector2(sz.x - pad, sz.y - pad - b_len), col_b, 1.6)

func _on_medallon_crest_draw() -> void:
	if medallon_crest == null:
		return
	var sz: Vector2 = medallon_crest.size
	var c: Vector2 = sz * 0.5
	var r: float = minf(sz.x, sz.y) * 0.5 - 3.0
	var col_main: Color = Color(0.98, 0.80, 0.18) if _es_victoria_actual else Color(0.96, 0.24, 0.37)
	var col_sec: Color = Color(0.25, 0.92, 1.0) if _es_victoria_actual else Color(1.0, 0.52, 0.32)

	# Fondo oscuro del medallón
	medallon_crest.draw_circle(c, r, Color(0.02, 0.04, 0.08, 0.95))
	medallon_crest.draw_circle(c, r * 0.76, Color(col_main.r, col_main.g, col_main.b, 0.14))

	# Anillo exterior e interior
	medallon_crest.draw_arc(c, r, 0.0, TAU, 48, Color(col_main.r, col_main.g, col_main.b, 0.92), 2.2, true)
	medallon_crest.draw_arc(c, r - 6.0, 0.0, TAU, 40, Color(col_sec.r, col_sec.g, col_sec.b, 0.45), 1.2, true)

	# Arcos tácticos rotatorios
	var a0: float = _fase_anim * 1.4
	medallon_crest.draw_arc(c, r - 3.0, a0, a0 + 1.15, 16, Color(col_sec.r, col_sec.g, col_sec.b, 0.95), 2.4, true)
	medallon_crest.draw_arc(c, r - 3.0, a0 + PI, a0 + PI + 1.15, 16, Color(col_sec.r, col_sec.g, col_sec.b, 0.95), 2.4, true)

func _on_divider_top_draw() -> void:
	if divider_top == null:
		return
	var sz: Vector2 = divider_top.size
	var y: float = sz.y * 0.5
	var cx: float = sz.x * 0.5
	var col_line: Color = Color(0.98, 0.80, 0.20, 0.55) if _es_victoria_actual else Color(0.96, 0.25, 0.37, 0.55)
	var col_cyan: Color = Color(0.22, 0.88, 1.0, 0.75)

	divider_top.draw_line(Vector2(0.0, y), Vector2(cx - 18.0, y), col_line, 1.4)
	divider_top.draw_line(Vector2(cx + 18.0, y), Vector2(sz.x, y), col_line, 1.4)

	var pts := PackedVector2Array([
		Vector2(cx, y - 4.0),
		Vector2(cx + 8.0, y),
		Vector2(cx, y + 4.0),
		Vector2(cx - 8.0, y)
	])
	divider_top.draw_colored_polygon(pts, col_cyan)

func _dibujar_barra_extraccion(ctrl: Control, ratio_objetivo: float, col_fill: Color, col_glow: Color) -> void:
	if ctrl == null:
		return
	var sz: Vector2 = ctrl.size
	if sz.x < 16.0 or sz.y < 4.0:
		return
	var rect_bg := Rect2(Vector2.ZERO, sz)
	ctrl.draw_rect(rect_bg, Color(0.015, 0.025, 0.05, 0.95), true)

	var fill_ratio: float = clampf(ratio_objetivo * _progreso_barras, 0.0, 1.0)
	var fill_w: float = sz.x * fill_ratio
	if fill_w > 1.0:
		var rect_fill := Rect2(Vector2.ZERO, Vector2(fill_w, sz.y))
		ctrl.draw_rect(rect_fill, col_fill, true)
		var rect_top := Rect2(Vector2.ZERO, Vector2(fill_w, maxf(2.0, sz.y * 0.32)))
		ctrl.draw_rect(rect_top, col_glow, true)

	# Divisiones de segmento cada 10%
	for i in range(1, 10):
		var tx: float = sz.x * (float(i) * 0.1)
		ctrl.draw_line(Vector2(tx, 0.0), Vector2(tx, sz.y), Color(0.02, 0.04, 0.08, 0.65), 1.0)

	ctrl.draw_rect(rect_bg, Color(col_fill.r, col_fill.g, col_fill.b, 0.65), false, 1.0)

func _on_barra_oro_draw() -> void:
	_dibujar_barra_extraccion(
		barra_ext_oro,
		_ratio_oro_actual,
		Color(0.96, 0.76, 0.14, 0.92),
		Color(1.0, 0.94, 0.55, 0.85)
	)

func _on_barra_clics_draw() -> void:
	_dibujar_barra_extraccion(
		barra_ext_clics,
		_ratio_clics_actual,
		Color(0.14, 0.80, 0.98, 0.92),
		Color(0.68, 0.96, 1.0, 0.85)
	)

func _on_barra_matriz_draw() -> void:
	var listo_prestigio: bool = MetaprogresoManager.puede_hacer_prestigio()
	var col_f: Color = Color(0.98, 0.82, 0.18, 0.94) if listo_prestigio else Color(0.18, 0.90, 0.66, 0.92)
	var col_g: Color = Color(1.0, 0.96, 0.65, 0.88) if listo_prestigio else Color(0.62, 1.0, 0.86, 0.85)
	_dibujar_barra_extraccion(
		barra_progreso_matriz,
		1.0 if listo_prestigio else _ratio_prestigio_matriz,
		col_f,
		col_g
	)

# ==============================================================================
# NAVEGACIÓN A MATRIZ POÉ, REINTENTO Y SALIDA
# ==============================================================================
func _on_btn_arbol_meta_pressed() -> void:
	AudioManager.play("click", 1.2)
	if arbol_instancia == null:
		arbol_instancia = ArbolMejorasPoEEscena.instantiate()
		arbol_instancia.layer = 25
		var root = get_tree().root if get_tree() != null else get_parent()
		if root != null:
			root.add_child(arbol_instancia)
		else:
			add_child(arbol_instancia)
		arbol_instancia.arbol_cerrado.connect(_on_arbol_cerrado)
	arbol_instancia.abrir()

func _on_arbol_cerrado() -> void:
	_actualizar_labels_banco()
	_actualizar_texto_run_pura()

func _on_btn_reintentar_pressed() -> void:
	AudioManager.play("click", 1.2)
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
		var partida = get_tree().get_first_node_in_group("partida")
		if partida != null and "intentos" in partida:
			partida.intentos += 1
		get_tree().reload_current_scene()

func _on_btn_salir_pressed() -> void:
	AudioManager.play("click", 1.2)
	if is_inside_tree() and get_tree() != null:
		get_tree().quit()
