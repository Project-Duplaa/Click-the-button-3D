extends CanvasLayer

# Pantalla de Fin de Partida y Metaprogresión Roguelike (Estilo Hades / Roguelite Neón)
# Desarrollado por: Juan Camilo Angulo Camelo
# Despliega el resumen analítico detallado de la run (Victoria o Derrota),
# deposita las ganancias en el Banco Permanente y permite abrir el Árbol de Habilidades estilo PoE
# para comprar mejoras permanentes que persisten en todas las futuras partidas.

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

func mostrar(es_victoria: bool, motivo: String = ""):
	visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	
	# Audio y Estilo Temático Hades (Victoria Oro vs Derrota Carmesí)
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
		
	# Recopilar métricas analíticas de la partida
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
	var clase_str: String = "Guerrero"
	var oro_cnt: int = 0
	var num_intento: int = 1
	
	if hud != null:
		tiempo_s = hud.tiempo_total
		clicks_cnt = hud.clicks_boton
	if pj != null:
		bajas_cnt = pj.bajas
		nivel_num = pj.nivel
		clase_str = pj.clase
		oro_cnt = pj.oro
		if "clics_disponibles" in pj and pj.clics_disponibles > clicks_cnt:
			clicks_cnt = pj.clics_disponibles
	if partida != null and "intentos" in partida:
		num_intento = partida.intentos
		
	var min = int(tiempo_s) / 60
	var seg = int(tiempo_s) % 60
	
	if label_tiempo != null:
		label_tiempo.text = "%02d:%02d min" % [min, seg]
	if label_clicks != null:
		label_clicks.text = "+%d clics" % clicks_cnt
	if label_bajas != null:
		label_bajas.text = "%d enemigos" % bajas_cnt
	if label_nivel != null:
		label_nivel.text = "%s (Nv. %d)" % [clase_str, nivel_num]
	if label_oro != null:
		label_oro.text = "+%d monedas" % oro_cnt
	if label_intento != null:
		label_intento.text = "#%d" % num_intento
	
	# Metaprogresión Roguelike: depositar ganancias de la run en la cuenta permanente
	if not _recursos_transferidos:
		_recursos_transferidos = true
		MetaprogresoManager.transferir_recursos_run(oro_cnt, clicks_cnt, bajas_cnt, es_victoria)
		
	_actualizar_labels_banco()
	
	# Efecto de entrada con Tween fluido y pulso
	if panel_fondo != null:
		panel_fondo.scale = Vector2(0.85, 0.85)
		panel_fondo.modulate = Color(1, 1, 1, 0)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(panel_fondo, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel_fondo, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _actualizar_labels_banco():
	MetaprogresoManager.asegurar_inicializado()
	if label_banco != null:
		label_banco.text = "%d 🧪 Isótopos | %d ⚡ Clics" % [MetaprogresoManager.oro_banco, MetaprogresoManager.clics_banco]
	if btn_arbol_meta != null:
		btn_arbol_meta.text = "☢️ MATRIZ DE BIOCONTENCIÓN (MEJORAS DEL REACTOR) · %d 🧪 | %d ⚡" % [MetaprogresoManager.oro_banco, MetaprogresoManager.clics_banco]

func _on_btn_arbol_meta_pressed():
	AudioManager.play("click", 1.2)
	if arbol_instancia == null:
		arbol_instancia = ArbolMejorasPoEEscena.instantiate()
		arbol_instancia.layer = 25 # Capa superior para quedar visible sobre la pantalla de fin de partida
		var root = get_tree().root if get_tree() != null else get_parent()
		if root != null:
			root.add_child(arbol_instancia)
		else:
			add_child(arbol_instancia)
		arbol_instancia.arbol_cerrado.connect(_on_arbol_cerrado)
	arbol_instancia.abrir()

func _on_arbol_cerrado():
	_actualizar_labels_banco()

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
