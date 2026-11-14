extends CanvasLayer

# ClickHUD Modernizado - Dark Fantasy Colosseum Top Bar
# Réplica fiel del banner continuo superior de referencia:
# Marco horizontal continuo con esquinas góticas, busto 3D interactivo en vivo,
# barra de vida rubí con bisel, gemas corazón 3D facetadas, dagas ornamentales,
# oro con moneda 3D, bajas con calavera 3D, y barra de XP estilizada.

const MALLAS_AVATAR = {
	"Novato": preload("res://personaje/character-male-a.glb"),
	"Guerrero": preload("res://personaje/character-male-d.glb"),
	"Cazador": preload("res://personaje/character-female-e.glb"),
	"Mago": preload("res://personaje/character-female-b.glb")
}

const TEX_CORAZON_LLENO = preload("res://ui_assets/hud_gem_heart.png")
const TEX_CORAZON_VACIO = preload("res://ui_assets/hud_gem_heart_empty.png")

# Referencias a la Barra Superior Continua
@onready var label_clase: Label = $Control/BarraSuperior/ContenedorHeroe/LabelClase
@onready var bar_vida: ProgressBar = $Control/BarraSuperior/ContenedorHeroe/BarVida
@onready var label_vida: Label = $Control/BarraSuperior/ContenedorHeroe/BarVida/LabelVida

@onready var avatar_frame: Panel = $Control/BarraSuperior/AvatarFrame
@onready var subviewport_avatar: SubViewport = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport
@onready var modelo_avatar_nodo: Node3D = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport/ModeloAvatar
@onready var camara_avatar: Camera3D = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport/CamaraAvatar

@onready var label_vidas: Label = $Control/BarraSuperior/ContenedorVidas/LabelVidas
@onready var corazon1: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon1
@onready var corazon2: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon2
@onready var corazon3: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon3

@onready var label_oleada: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelOleada
@onready var label_tiempo: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelTiempo
@onready var label_nucleo: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelNucleo

@onready var label_oro: Label = $Control/BarraSuperior/ContenedorEconomia/HBoxOro/LabelOro
@onready var label_bajas: Label = $Control/BarraSuperior/ContenedorEconomia/HBoxBajas/LabelBajas

# XP y Barra
@onready var bar_xp: ProgressBar = $Control/BarXP
@onready var label_xp: Label = $Control/BarXP/LabelXP

# Modales y Paneles
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
		
	_calibrar_avatar()
		
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		jugador.stats_actualizadas.connect(_on_stats_actualizadas)
		jugador.nivel_subido.connect(_on_nivel_subido)
		if jugador.has_signal("economia_actualizada"):
			jugador.economia_actualizada.connect(_on_economia_actualizada)
		_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	
	if btn_opc1 != null:
		btn_opc1.pressed.connect(func(): _elegir_mejora("dano"))
	if btn_opc2 != null:
		btn_opc2.pressed.connect(func(): _elegir_mejora("velocidad"))
	if btn_opc3 != null:
		btn_opc3.pressed.connect(func(): _elegir_mejora("vida"))
	
	call_deferred("_conectar_boton_movil")
	_crear_boton_test_parca()

func _calibrar_avatar():
	if camara_avatar != null:
		camara_avatar.position = Vector3(0.0, 0.44, 0.56)
		camara_avatar.look_at_from_position(Vector3(0.0, 0.44, 0.56), Vector3(0.0, 0.41, 0.0), Vector3.UP)
		camara_avatar.fov = 40.0
	if modelo_avatar_nodo != null:
		modelo_avatar_nodo.rotation_degrees.y = 165.0

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
		label_tiempo.text = "⏱ %02d:%02d" % [minutos, segundos]
		
	if label_nucleo != null:
		label_nucleo.text = "⚡ %d Clics (Vel: %.1f m/s)" % [clicks_boton, vel_boton]
		
	if label_oleada != null:
		label_oleada.text = "⚔️ OLEADA %d" % oleada

func _on_stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas):
	if jugador != null and "clase" in jugador:
		var nombre_clase = str(jugador.clase)
		if label_clase != null:
			label_clase.text = "Clase: %s (Nv. %d)" % [nombre_clase, nivel]
		_actualizar_avatar_clase(nombre_clase)
		
	if jugador != null and "reapariciones" in jugador:
		var vidas_restantes = clampi(jugador.reapariciones + 1, 0, 3)
		if label_vidas != null:
			label_vidas.text = "Vidas: %d/3" % vidas_restantes
		if corazon1 != null:
			corazon1.texture = TEX_CORAZON_LLENO if vidas_restantes >= 1 else TEX_CORAZON_VACIO
		if corazon2 != null:
			corazon2.texture = TEX_CORAZON_LLENO if vidas_restantes >= 2 else TEX_CORAZON_VACIO
		if corazon3 != null:
			corazon3.texture = TEX_CORAZON_LLENO if vidas_restantes >= 3 else TEX_CORAZON_VACIO
				
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
		label_oro.text = "%d" % oro
		
	if label_bajas != null:
		label_bajas.text = "%d Bajas" % bajas

func _on_economia_actualizada(oro_cnt: int, _clics_disp: int, _clics_tot: int):
	if label_oro != null:
		label_oro.text = "%d" % oro_cnt

func _actualizar_avatar_clase(nombre_clase: String):
	if _clase_actual_avatar == nombre_clase or subviewport_avatar == null:
		return
	_clase_actual_avatar = nombre_clase
	
	if MALLAS_AVATAR.has(nombre_clase):
		var escena_malla: PackedScene = MALLAS_AVATAR[nombre_clase]
		if escena_malla != null:
			if is_instance_valid(modelo_avatar_nodo):
				modelo_avatar_nodo.queue_free()
			var nuevo_modelo = escena_malla.instantiate()
			nuevo_modelo.name = "ModeloAvatar"
			nuevo_modelo.rotation_degrees.y = 165.0
			subviewport_avatar.add_child(nuevo_modelo)
			modelo_avatar_nodo = nuevo_modelo

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

func actualizar_barra_jefe(hp_actual: float, texto_nombre: String = ""):
	if panel_jefe != null and bar_vida_jefe != null:
		bar_vida_jefe.value = hp_actual
		if label_vida_jefe != null:
			label_vida_jefe.text = "%d / %d HP" % [int(hp_actual), int(bar_vida_jefe.max_value)]
		if texto_nombre != "" and label_nombre_jefe != null:
			label_nombre_jefe.text = texto_nombre

func ocultar_barra_jefe():
	if panel_jefe != null:
		panel_jefe.visible = false

var _panel_test_jefes: VBoxContainer = null

func _crear_boton_test_parca():
	# Contenedor anclado en la esquina inferior derecha
	var cont = VBoxContainer.new()
	cont.name = "ContenedorTestJefes"
	cont.anchor_left = 1.0
	cont.anchor_top = 1.0
	cont.anchor_right = 1.0
	cont.anchor_bottom = 1.0
	cont.offset_left = -230.0
	cont.offset_top = -240.0
	cont.offset_right = -15.0
	cont.offset_bottom = -15.0
	cont.alignment = BoxContainer.ALIGNMENT_END
	
	# Sub-panel desplegable con la lista de todos los jefes
	_panel_test_jefes = VBoxContainer.new()
	_panel_test_jefes.name = "ListaJefesTest"
	_panel_test_jefes.visible = false
	
	var jefes = [
		{"id": "centurion", "label": "⚔️ W3: Centurión (420 HP)", "color": Color(0.8, 0.45, 0.15)},
		{"id": "gladiador", "label": "🛡️ W6: Gladiador (950 HP)", "color": Color(0.9, 0.55, 0.2)},
		{"id": "maestra", "label": "🏹 W9: Maestra (1800 HP)", "color": Color(0.85, 0.2, 0.6)},
		{"id": "coloso", "label": "🌋 W12: Coloso (3200 HP)", "color": Color(0.95, 0.35, 0.1)}
	]
	
	for j in jefes:
		var b_jefe = Button.new()
		b_jefe.text = j["label"]
		_aplicar_estilo_boton(b_jefe, j["color"])
		var j_id = j["id"]
		b_jefe.pressed.connect(func(): _invocar_jefe_test(j_id))
		_panel_test_jefes.add_child(b_jefe)
		
	cont.add_child(_panel_test_jefes)
	
	# Fila de botones principales
	var hbox_botones = HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_END
	
	var btn_toggle = Button.new()
	btn_toggle.text = "👑 JEFES (▲)"
	_aplicar_estilo_boton(btn_toggle, Color(0.7, 0.5, 0.2))
	btn_toggle.pressed.connect(func():
		_panel_test_jefes.visible = !_panel_test_jefes.visible
		btn_toggle.text = "👑 JEFES (▼)" if _panel_test_jefes.visible else "👑 JEFES (▲)"
	)
	hbox_botones.add_child(btn_toggle)
	
	var btn_parca = Button.new()
	btn_parca.name = "BtnTestParca"
	btn_parca.text = "💀 PROBAR PARCA ROJA"
	btn_parca.tooltip_text = "Invoca al Jefe Final (La Parca Roja) y otorga build de supervivencia"
	_aplicar_estilo_boton(btn_parca, Color(0.95, 0.2, 0.2))
	btn_parca.pressed.connect(func(): _invocar_jefe_test("parca"))
	hbox_botones.add_child(btn_parca)
	
	cont.add_child(hbox_botones)
	$Control.add_child(cont)

func _aplicar_estilo_boton(btn: Button, color_acento: Color):
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color = Color(0.12, 0.05, 0.07, 0.92)
	s_normal.border_color = color_acento
	s_normal.border_width_left = 1
	s_normal.border_width_top = 1
	s_normal.border_width_right = 1
	s_normal.border_width_bottom = 1
	s_normal.corner_radius_top_left = 5
	s_normal.corner_radius_top_right = 5
	s_normal.corner_radius_bottom_right = 5
	s_normal.corner_radius_bottom_left = 5
	
	var s_hover = s_normal.duplicate()
	s_hover.bg_color = Color(0.25, 0.08, 0.12, 0.95)
	s_hover.border_color = color_acento.lightened(0.25)
	
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	btn.add_theme_font_size_override("font_size", 11)

func _invocar_jefe_test(tipo: String):
	print(">>> [HUD] Invocando Jefe de Prueba: ", tipo, " <<<")
	
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		
	# Equipar build adaptada al test
	if jugador != null and jugador.has_method("equipar_build_test_parca"):
		jugador.equipar_build_test_parca()
		
	# Despejar enemigos comunes previos
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e) and not e.is_in_group("jefes"):
			e.queue_free()
			
	var escena_path = ""
	match tipo:
		"centurion":
			escena_path = "res://centurion_corrupto.tscn"
		"gladiador":
			escena_path = "res://mini_jefe.tscn"
		"maestra":
			escena_path = "res://maestra_sanguinaria.tscn"
		"coloso":
			escena_path = "res://coloso_bronce.tscn"
		"parca":
			escena_path = "res://parca_roja.tscn"
			
	if escena_path != "":
		var escena = load(escena_path)
		if escena != null:
			var j = escena.instantiate()
			get_parent().add_child(j)
			j.global_position = Vector3(0, 0, -14)
