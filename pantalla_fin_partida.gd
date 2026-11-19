extends CanvasLayer

# Pantalla de Fin de Partida y Metaprogresión Roguelike (Estilo Hades / Roguelite Neón)
# Transfiere recursos al Banco Permanente sin duplicación y registra estadísticas/hazañas/récord diario.

class_name PantallaFinPartida

const AudioManager = preload("res://audio_manager.gd")
const ArbolMejorasPoEEscena = preload("res://arbol_mejoras_poe.tscn")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

const ICON_SKULL = preload("res://ui_assets/icon_skull_hades.svg")
const ICON_VICTORY = preload("res://ui_assets/icon_victory_hades.svg")

@onready var panel_fondo: Panel = $Control/Fondo
@onready var texture_crest: TextureRect = find_child("TextureCrest", true, false)
@onready var label_titulo: Label = find_child("LabelTitulo", true, false)
@onready var label_motivo: Label = find_child("LabelMotivo", true, false)
@onready var panel_motivo: PanelContainer = find_child("PanelMotivo", true, false)
@onready var label_tiempo: Label = find_child("LabelValTiempo", true, false)
@onready var label_clicks: Label = find_child("LabelValClicks", true, false)
@onready var label_bajas: Label = find_child("LabelValBajas", true, false)
@onready var label_nivel: Label = find_child("LabelValNivel", true, false)
@onready var label_oro: Label = find_child("LabelValOro", true, false)
@onready var label_intento: Label = find_child("LabelValIntento", true, false)
@onready var label_banco: Label = find_child("LabelValBanco", true, false)
@onready var btn_arbol_meta: Button = find_child("BtnArbolMeta", true, false)
@onready var btn_reintentar: Button = find_child("BtnReintentar", true, false)
@onready var btn_salir: Button = find_child("BtnSalir", true, false)

var arbol_instancia: CanvasLayer = null
var btn_codice_meta: Button = null
var btn_run_pura_fin: Button = null
var _recursos_transferidos: bool = false

func _ready():
	add_to_group("pantalla_fin_partida")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if btn_reintentar != null:
		btn_reintentar.pressed.connect(_on_btn_reintentar_pressed)
	if btn_salir != null:
		btn_salir.pressed.connect(_on_btn_salir_pressed)
	if btn_arbol_meta != null:
		btn_arbol_meta.pressed.connect(_on_btn_arbol_meta_pressed)

	_crear_boton_codice_meta()
	_crear_boton_run_pura()

func _crear_boton_codice_meta() -> void:
	var vbox = find_child("VBox", true, false)
	if vbox == null:
		return

	btn_codice_meta = Button.new()
	btn_codice_meta.name = "BtnCodiceFin"
	btn_codice_meta.custom_minimum_size = Vector2(0, 40)
	btn_codice_meta.text = "📖 CÓDICE DEL GLADIADOR (HAZAÑAS & BESTIARIO)"
	btn_codice_meta.focus_mode = Control.FOCUS_NONE
	btn_codice_meta.add_theme_font_size_override("font_size", 13)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.18, 0.10, 0.32, 0.95)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(0.78, 0.55, 1.0, 0.95)
	sb_normal.corner_radius_top_left = 8
	sb_normal.corner_radius_top_right = 8
	sb_normal.corner_radius_bottom_right = 8
	sb_normal.corner_radius_bottom_left = 8
	sb_normal.shadow_color = Color(0.65, 0.35, 0.95, 0.35)
	sb_normal.shadow_size = 8

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.28, 0.16, 0.48, 1.0)
	sb_hover.border_color = Color(0.95, 0.78, 1.0, 1.0)

	btn_codice_meta.add_theme_stylebox_override("normal", sb_normal)
	btn_codice_meta.add_theme_stylebox_override("hover", sb_hover)
	btn_codice_meta.add_theme_stylebox_override("pressed", sb_hover)
	btn_codice_meta.pressed.connect(_on_btn_codice_meta_pressed)

	vbox.add_child(btn_codice_meta)
	if btn_arbol_meta != null:
		vbox.move_child(btn_codice_meta, btn_arbol_meta.get_index())

func _crear_boton_run_pura() -> void:
	var vbox = find_child("VBox", true, false)
	if vbox == null:
		return

	btn_run_pura_fin = Button.new()
	btn_run_pura_fin.name = "BtnRunPuraFin"
	btn_run_pura_fin.custom_minimum_size = Vector2(0, 36)
	btn_run_pura_fin.focus_mode = Control.FOCUS_NONE
	btn_run_pura_fin.add_theme_font_size_override("font_size", 13)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.20, 0.30, 0.95)
	sb_normal.set_border_width_all(1)
	sb_normal.border_color = Color(0.35, 0.82, 1.0, 0.90)
	sb_normal.set_corner_radius_all(8)

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.16, 0.30, 0.44, 1.0)
	sb_hover.border_color = Color(0.65, 0.95, 1.0, 1.0)

	btn_run_pura_fin.add_theme_stylebox_override("normal", sb_normal)
	btn_run_pura_fin.add_theme_stylebox_override("hover", sb_hover)
	btn_run_pura_fin.add_theme_stylebox_override("pressed", sb_hover)
	btn_run_pura_fin.pressed.connect(_on_btn_run_pura_fin_pressed)

	vbox.add_child(btn_run_pura_fin)
	var hbox_bot = find_child("HBoxBotones", true, false)
	if hbox_bot != null:
		vbox.move_child(btn_run_pura_fin, hbox_bot.get_index())
	_actualizar_texto_run_pura()

func _actualizar_texto_run_pura() -> void:
	if btn_run_pura_fin == null:
		return
	MetaprogresoManager.asegurar_inicializado()
	if MetaprogresoManager.modo_run_pura:
		btn_run_pura_fin.text = "🛡️ MODO RUN PURA: ACTIVO (0% Meta)"
		btn_run_pura_fin.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	else:
		btn_run_pura_fin.text = "🛡️ Modo Run Pura: Desactivado (Con Árbol)"
		btn_run_pura_fin.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))

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

func mostrar(es_victoria: bool, motivo: String = ""):
	visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true

	if es_victoria:
		AudioManager.play("victoria", 1.0, 2.0)
		if texture_crest != null:
			texture_crest.texture = ICON_VICTORY
		if label_titulo != null:
			label_titulo.text = "¡VICTORIA GLORIOSA EN EL COLISEO!"
			label_titulo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			label_titulo.add_theme_color_override("font_outline_color", Color(0.92, 0.72, 0.12, 1.0))
		if label_motivo != null:
			label_motivo.text = "🏆 " + ("Has conquistado la arena y resistido el poder supremo del Núcleo." if motivo == "" else motivo)
			label_motivo.add_theme_color_override("font_color", Color(1.0, 0.94, 0.6, 1.0))
		if btn_reintentar != null:
			btn_reintentar.text = "⚔️ Siguiente Arena del Coliseo"
	else:
		AudioManager.play("derrota", 1.0, 2.0)
		if texture_crest != null:
			texture_crest.texture = ICON_SKULL
		if label_titulo != null:
			label_titulo.text = "HAS CAÍDO EN COMBATE"
			label_titulo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			label_titulo.add_theme_color_override("font_outline_color", Color(0.88, 0.11, 0.28, 1.0))
		if label_motivo != null:
			label_motivo.text = "💀 " + ("Tus fuerzas sucumbieron ante la horda del coliseo." if motivo == "" else ("Motivo: " + motivo))
			label_motivo.add_theme_color_override("font_color", Color(0.99, 0.64, 0.68, 1.0))
		if btn_reintentar != null:
			btn_reintentar.text = "⚔️ Comenzar Siguiente Run"

	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		var root_nodo = get_tree().root if get_tree() != null else get_parent()
		if root_nodo != null:
			pj = root_nodo.find_child("Personaje", true, false)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
	var partida = get_tree().get_first_node_in_group("partida")

	var tiempo_s: float = 0.0
	var clicks_cnt: int = 0
	var bajas_cnt: int = 0
	var nivel_num: int = 1
	var clase_str: String = "Novato"
	var oro_cnt: int = 0
	var num_intento: int = 1
	var es_abismo: bool = false

	if hud != null:
		tiempo_s = hud.tiempo_total
		clicks_cnt = hud.clicks_boton
	if pj != null:
		bajas_cnt = pj.bajas
		nivel_num = pj.nivel
		clase_str = pj.clase
		oro_cnt = pj.oro
		if "clics_disponibles" in pj:
			clicks_cnt = pj.clics_disponibles
	if partida != null:
		if "intentos" in partida:
			num_intento = partida.intentos
		if "modo_abismo" in partida:
			es_abismo = bool(partida.modo_abismo)

	var min_val = int(tiempo_s) / 60
	var seg_val = int(tiempo_s) % 60

	if label_tiempo != null:
		label_tiempo.text = "%02d:%02d min" % [min_val, seg_val]
	if label_clicks != null:
		label_clicks.text = "+%s clics" % _formatear_num(clicks_cnt)
	if label_bajas != null:
		label_bajas.text = "%s enemigos" % _formatear_num(bajas_cnt)
	if label_nivel != null:
		label_nivel.text = "%s (Nv. %d)" % [clase_str, nivel_num]
	if label_oro != null:
		label_oro.text = "+%s monedas" % _formatear_num(oro_cnt)
	if label_intento != null:
		label_intento.text = "#%d" % num_intento

	# Metaprogresión Roguelike: depositar ganancias de la run en la cuenta permanente
	if not _recursos_transferidos:
		_recursos_transferidos = true
		# activar_modo_abismo() ya contó MetaprogresoManager.victorias += 1 al entrar al Abismo
		var victoria_para_meta := es_victoria and not es_abismo
		MetaprogresoManager.transferir_recursos_run(oro_cnt, clicks_cnt, bajas_cnt, victoria_para_meta)
		if pj != null:
			pj.oro = 0
			pj.clics_disponibles = 0
			if pj.has_signal("economia_actualizada"):
				pj.emit_signal("economia_actualizada", 0, 0, pj.clics_totales)

		var logros = get_tree().get_first_node_in_group("logros_manager")
		if logros != null and logros.has_method("registrar_fin_partida"):
			logros.registrar_fin_partida(es_victoria or es_abismo, bajas_cnt, clicks_cnt, nivel_num)

		# Registro de récord diario si la run era el desafío del día (3 argumentos exactos)
		if FortunaManager != null and "es_run_diaria" in FortunaManager and FortunaManager.es_run_diaria:
			MetaprogresoManager.actualizar_record_diario(FortunaManager.fecha_seed_diaria, bajas_cnt, tiempo_s)

	_actualizar_labels_banco()
	_actualizar_texto_run_pura()

	if panel_fondo != null:
		panel_fondo.scale = Vector2(0.85, 0.85)
		panel_fondo.modulate = Color(1, 1, 1, 0)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(panel_fondo, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel_fondo, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _actualizar_labels_banco():
	MetaprogresoManager.asegurar_inicializado()
	var esquirlas: int = int(MetaprogresoManager.esquirlas_astrales)

	if label_banco != null:
		label_banco.text = "%s 🧪 | %s ⚡ | %d ✨" % [
			_formatear_num(MetaprogresoManager.oro_banco),
			_formatear_num(MetaprogresoManager.clics_banco),
			esquirlas
		]
	if btn_arbol_meta != null:
		btn_arbol_meta.text = "☢️ MATRIZ DE BIOCONTENCIÓN (MEJORAS) · %s 🧪 | %s ⚡" % [
			_formatear_num(MetaprogresoManager.oro_banco),
			_formatear_num(MetaprogresoManager.clics_banco)
		]

func _on_btn_arbol_meta_pressed():
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

func _on_arbol_cerrado():
	_actualizar_labels_banco()
	_actualizar_texto_run_pura()

func _on_btn_reintentar_pressed():
	AudioManager.play("click", 1.2)
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
		var partida = get_tree().get_first_node_in_group("partida")
		if partida != null and "intentos" in partida:
			partida.intentos += 1
		get_tree().reload_current_scene()

func _on_btn_salir_pressed():
	AudioManager.play("click", 1.2)
	if is_inside_tree() and get_tree() != null:
		get_tree().quit()
