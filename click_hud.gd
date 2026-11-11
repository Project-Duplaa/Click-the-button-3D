extends CanvasLayer

# ClickHUD Modernizado - Clicklike 3D: El Coliseo del Núcleo Móvil
# Fusiona las referencias de interfaz RPG / Coliseo con tarjetas modulares flotantes,
# busto 3D de avatar en vivo, placa ornamental de oleada y barra de XP estilizada.

const MALLAS_AVATAR = {
	"Novato": preload("res://personaje/character-male-a.glb"),
	"Guerrero": preload("res://personaje/character-male-d.glb"),
	"Cazador": preload("res://personaje/character-female-e.glb"),
	"Mago": preload("res://personaje/character-female-b.glb")
}

@onready var label_clase: Label = $Control/TarjetaHeroe/LabelClase
@onready var label_vidas: Label = $Control/TarjetaHeroe/LabelVidas
@onready var bar_vida: ProgressBar = $Control/TarjetaHeroe/BarVida
@onready var label_vida: Label = $Control/TarjetaHeroe/BarVida/LabelVida
@onready var subviewport_avatar: SubViewport = $Control/TarjetaHeroe/AvatarFrame/SubViewportContainer/SubViewport
@onready var modelo_avatar_nodo: Node3D = $Control/TarjetaHeroe/AvatarFrame/SubViewportContainer/SubViewport/ModeloAvatar

@onready var label_oleada: Label = $Control/TarjetaOleada/PlacaOleada/LabelOleada
@onready var label_tiempo: Label = $Control/TarjetaOleada/PanelEstado/LabelTiempo
@onready var label_nucleo: Label = $Control/TarjetaOleada/PanelEstado/LabelNucleo

@onready var label_oro: Label = $Control/TarjetaStats/HBoxOro/LabelOro
@onready var label_bajas: Label = $Control/TarjetaStats/HBoxBajas/LabelBajas

@onready var bar_xp: ProgressBar = $Control/BarXP
@onready var label_xp: Label = $Control/BarXP/LabelXP

@onready var btn_click: Button = $Control/BtnClick
@onready var modal_mejora: Panel = $Control/ModalMejora
@onready var btn_opc1: Button = $Control/ModalMejora/VBox/HBox/BtnOpc1
@onready var btn_opc2: Button = $Control/ModalMejora/VBox/HBox/BtnOpc2
@onready var btn_opc3: Button = $Control/ModalMejora/VBox/HBox/BtnOpc3

@onready var panel_jefe: Panel = $Control/PanelJefe
@onready var label_nombre_jefe: Label = $Control/PanelJefe/LabelNombreJefe
@onready var bar_vida_jefe: ProgressBar = $Control/PanelJefe/BarVidaJefe
@onready var label_vida_jefe: Label = $Control/PanelJefe/BarVidaJefe/LabelVidaJefe

var jugador: Node = null
var tiempo_total: float = 0.0
var oleada: int = 1
var clicks_boton: int = 0
var vel_boton: float = 2.8
var _clase_actual_avatar: String = ""

func _ready():
	if panel_jefe != null:
		panel_jefe.visible = false
	if modal_mejora != null:
		modal_mejora.visible = false
	if btn_click != null:
		btn_click.visible = false # El combate es 100% automático
		
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		jugador.stats_actualizadas.connect(_on_stats_actualizadas)
		jugador.nivel_subido.connect(_on_nivel_subido)
		_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	
	if btn_click != null:
		btn_click.pressed.connect(_on_btn_click_pressed)
	if btn_opc1 != null:
		btn_opc1.pressed.connect(func(): _elegir_mejora("dano"))
	if btn_opc2 != null:
		btn_opc2.pressed.connect(func(): _elegir_mejora("velocidad"))
	if btn_opc3 != null:
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

func _process(delta: float):
	tiempo_total += delta
	var minutos = int(tiempo_total) / 60
	var segundos = int(tiempo_total) % 60
	
	if label_tiempo != null:
		label_tiempo.text = "⌛ %02d:%02d" % [minutos, segundos]
		
	if label_nucleo != null:
		label_nucleo.text = "⚡ %d Clics (Vel: %.1f m/s)" % [clicks_boton, vel_boton]
		
	if label_oleada != null:
		label_oleada.text = "⚔️  OLEADA %d  ⚔️" % oleada

func _on_stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas):
	if jugador != null and "clase" in jugador:
		var nombre_clase = str(jugador.clase)
		if label_clase != null:
			label_clase.text = "Clase: %s (Nv. %d)" % [nombre_clase, nivel]
		_actualizar_avatar_clase(nombre_clase)
		
	if label_vidas != null and jugador != null and "reapariciones" in jugador:
		var vidas_restantes = jugador.reapariciones + 1
		match vidas_restantes:
			3:
				label_vidas.text = "Vidas: 3/3   ❤️❤️❤️"
				label_vidas.modulate = Color(1.0, 1.0, 1.0)
			2:
				label_vidas.text = "Vidas: 2/3   ❤️❤️🖤"
				label_vidas.modulate = Color(1.0, 0.88, 0.35)
			1:
				label_vidas.text = "Vidas: 1/3   ❤️🖤🖤"
				label_vidas.modulate = Color(1.0, 0.40, 0.40)
			_:
				label_vidas.text = "Vidas: 0/3   🖤🖤🖤"
				label_vidas.modulate = Color(0.65, 0.25, 0.25)
				
	if bar_vida != null:
		bar_vida.max_value = max_vida
		bar_vida.value = vida
		if label_vida != null:
			label_vida.text = "%d / %d HP" % [int(vida), int(max_vida)]
			
	if bar_xp != null:
		bar_xp.max_value = max(xp_sig, 1)
		bar_xp.value = xp
		if label_xp != null:
			label_xp.text = "XP: %d / %d" % [xp, xp_sig]
			
	if label_oro != null:
		label_oro.text = "Oro: %d" % oro
		
	if label_bajas != null:
		label_bajas.text = "Bajas: %d" % bajas

func _actualizar_avatar_clase(nombre_clase: String):
	if _clase_actual_avatar == nombre_clase or subviewport_avatar == null:
		return
	_clase_actual_avatar = nombre_clase
	
	if MALLAS_AVATAR.has(nombre_clase):
		var escena_malla: PackedScene = MALLAS_AVATAR[nombre_clase]
		if escena_malla != null:
			# Reemplazar modelo en el SubViewport del Avatar
			if is_instance_valid(modelo_avatar_nodo):
				modelo_avatar_nodo.queue_free()
			var nuevo_modelo = escena_malla.instantiate()
			nuevo_modelo.name = "ModeloAvatar"
			subviewport_avatar.add_child(nuevo_modelo)
			modelo_avatar_nodo = nuevo_modelo

func _on_btn_click_pressed():
	if jugador != null and jugador.has_method("click_attack"):
		jugador.click_attack()

func _on_nivel_subido(_nuevo_nivel: int):
	if modal_mejora != null:
		modal_mejora.visible = true

func _elegir_mejora(tipo: String):
	if modal_mejora != null:
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
