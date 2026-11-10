extends CanvasLayer

@onready var label_clase = $Control/PanelTop/LabelClase
@onready var bar_vida = $Control/PanelTop/BarVida
@onready var label_vida = $Control/PanelTop/BarVida/LabelVida
@onready var bar_xp = $Control/PanelTop/BarXP
@onready var label_xp = $Control/PanelTop/BarXP/LabelXP
@onready var label_oro = $Control/PanelTop/LabelOro
@onready var label_info = $Control/PanelTop/LabelInfo
@onready var btn_click = $Control/BtnClick
@onready var modal_mejora = $Control/ModalMejora
@onready var btn_opc1 = $Control/ModalMejora/VBox/HBox/BtnOpc1
@onready var btn_opc2 = $Control/ModalMejora/VBox/HBox/BtnOpc2
@onready var btn_opc3 = $Control/ModalMejora/VBox/HBox/BtnOpc3
@onready var panel_jefe = $Control/PanelJefe
@onready var label_nombre_jefe = $Control/PanelJefe/LabelNombreJefe
@onready var bar_vida_jefe = $Control/PanelJefe/BarVidaJefe
@onready var label_vida_jefe = $Control/PanelJefe/BarVidaJefe/LabelVidaJefe

var jugador: Node = null
var tiempo_total: float = 0.0
var oleada: int = 1
var clicks_boton: int = 0
var vel_boton: float = 2.8

func _ready():
	if panel_jefe != null:
		panel_jefe.visible = false
	modal_mejora.visible = false
	if btn_click != null:
		btn_click.visible = false # El combate es 100% automático (estilo Vampire Survivors)
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		jugador.stats_actualizadas.connect(_on_stats_actualizadas)
		jugador.nivel_subido.connect(_on_nivel_subido)
		_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	
	btn_click.pressed.connect(_on_btn_click_pressed)
	btn_opc1.pressed.connect(func(): _elegir_mejora("dano"))
	btn_opc2.pressed.connect(func(): _elegir_mejora("velocidad"))
	btn_opc3.pressed.connect(func(): _elegir_mejora("vida"))
	
	call_deferred("_conectar_boton_movil")

func _conectar_boton_movil():
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null:
		b.click_presionado.connect(_on_click_boton_presionado)
		if "rapidez_movimiento" in b:
			vel_boton = b.rapidez_movimiento

func _on_click_boton_presionado(total: int):
	clicks_boton = total
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null and "rapidez_movimiento" in b:
		vel_boton = b.rapidez_movimiento

func _process(delta):
	tiempo_total += delta
	var minutos = int(tiempo_total) / 60
	var segundos = int(tiempo_total) % 60
	var bajas_cnt = jugador.bajas if (jugador != null and "bajas" in jugador) else 0
	label_info.text = "Oleada %d  |  %02d:%02d  |  Bajas: %d  |  Clics: %d (Vel: %.1f m/s)" % [oleada, minutos, segundos, bajas_cnt, clicks_boton, vel_boton]

func _on_stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas):
	if label_clase != null and jugador != null and "clase" in jugador:
		label_clase.text = "Clase: %s (Nv. %d)" % [jugador.clase, nivel]
	if bar_vida != null:
		bar_vida.max_value = max_vida
		bar_vida.value = vida
		label_vida.text = "%d / %d HP" % [int(vida), int(max_vida)]
	if bar_xp != null:
		bar_xp.max_value = xp_sig
		bar_xp.value = xp
		label_xp.text = "XP: %d / %d" % [xp, xp_sig]
	if label_oro != null:
		label_oro.text = "Oro: %d" % oro

func _on_btn_click_pressed():
	if jugador != null and jugador.has_method("click_attack"):
		jugador.click_attack()

func _on_nivel_subido(nuevo_nivel: int):
	modal_mejora.visible = true

func _elegir_mejora(tipo: String):
	modal_mejora.visible = false
	if jugador != null and jugador.has_method("aplicar_mejora"):
		jugador.aplicar_mejora(tipo)

func mostrar_barra_jefe(nombre: String, max_hp: float, hp_actual: float):
	if panel_jefe != null:
		panel_jefe.visible = true
		if label_nombre_jefe != null:
			label_nombre_jefe.text = nombre
		if bar_vida_jefe != null:
			bar_vida_jefe.max_value = max_hp
			bar_vida_jefe.value = hp_actual
		if label_vida_jefe != null:
			label_vida_jefe.text = "%d / %d HP" % [int(hp_actual), int(max_hp)]

func actualizar_barra_jefe(hp_actual: float):
	if panel_jefe != null and bar_vida_jefe != null:
		bar_vida_jefe.value = hp_actual
		if label_vida_jefe != null:
			label_vida_jefe.text = "%d / %d HP" % [int(hp_actual), int(bar_vida_jefe.max_value)]

func ocultar_barra_jefe():
	if panel_jefe != null:
		panel_jefe.visible = false

