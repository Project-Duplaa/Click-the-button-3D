extends CanvasLayer

# Pantalla de Fin de Partida y Métricas - Clicklike 3D
# Desarrollado por: Juan Camilo Angulo Camelo
# Despliega el resumen analítico detallado de la run (Victoria o Derrota) y permite el reintento instantáneo.

class_name PantallaFinPartida

const AudioManager = preload("res://audio_manager.gd")

@onready var panel_fondo = $Control/Fondo
@onready var label_titulo = $Control/Fondo/VBox/LabelTitulo
@onready var label_motivo = $Control/Fondo/VBox/LabelMotivo
@onready var label_tiempo = $Control/Fondo/VBox/Grid/LabelValTiempo
@onready var label_clicks = $Control/Fondo/VBox/Grid/LabelValClicks
@onready var label_bajas = $Control/Fondo/VBox/Grid/LabelValBajas
@onready var label_nivel = $Control/Fondo/VBox/Grid/LabelValNivel
@onready var label_oro = $Control/Fondo/VBox/Grid/LabelValOro
@onready var label_intento = $Control/Fondo/VBox/Grid/LabelValIntento
@onready var btn_reintentar = $Control/Fondo/VBox/HBoxBotones/BtnReintentar
@onready var btn_salir = $Control/Fondo/VBox/HBoxBotones/BtnSalir

func _ready():
	add_to_group("pantalla_fin_partida")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	btn_reintentar.pressed.connect(_on_btn_reintentar_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)

func mostrar(es_victoria: bool, motivo: String = ""):
	visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	
	# Audio temático
	if es_victoria:
		AudioManager.play("victoria", 1.0, 2.0)
		label_titulo.text = "🏆 ¡VICTORIA GLORIOSA EN EL COLISEO!"
		label_titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		label_motivo.text = "Has conquistado la arena y resistido el poder supremo del Núcleo." if motivo == "" else motivo
	else:
		AudioManager.play("derrota", 1.0, 2.0)
		label_titulo.text = "💀 HAS CAÍDO EN COMBATE"
		label_titulo.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
		label_motivo.text = "Tus fuerzas sucumbieron ante la horda del coliseo." if motivo == "" else ("Motivo: " + motivo)
		
	# Recopilar métricas analíticas de la partida
	var pj = get_tree().get_first_node_in_group("jugador")
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
	if partida != null and "intentos" in partida:
		num_intento = partida.intentos
		
	var min = int(tiempo_s) / 60
	var seg = int(tiempo_s) % 60
	
	label_tiempo.text = "%02d:%02d min" % [min, seg]
	label_clicks.text = "%d clics" % clicks_cnt
	label_bajas.text = "%d enemigos" % bajas_cnt
	label_nivel.text = "%s (Nv. %d)" % [clase_str, nivel_num]
	label_oro.text = "%d monedas" % oro_cnt
	label_intento.text = "#%d" % num_intento
	
	# Efecto de entrada con Tween
	panel_fondo.scale = Vector3.ZERO if panel_fondo is Node3D else Vector2(0.8, 0.8)
	var tw = create_tween()
	tw.tween_property(panel_fondo, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_btn_reintentar_pressed():
	AudioManager.play("click", 1.2)
	get_tree().paused = false
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and "intentos" in partida:
		partida.intentos += 1
	get_tree().reload_current_scene()

func _on_btn_salir_pressed():
	get_tree().quit()
