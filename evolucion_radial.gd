@tool
extends Node3D
class_name EvolucionRadial

## EvolucionRadial (Controlador 3D In-World a los pies del Personaje)
## Administra el Sprite3D sobre el suelo para desplegar el anillo rúnico (Diseño 3),
## procesa EXCLUSIVAMENTE la posición del cursor del ratón (independiente del movimiento con WASD),
## proyecta el tooltip 2D flotante en CanvasLayer al lado del personaje con cola triangular,
## emite señales de preview y confirmación, y anima aperturas / cierres con Tween.

signal evolucion_seleccionada(nombre_clase: String)
signal clase_preview_cambiada(nombre_clase: String)

# Radios calibrados a la escala real del anillo en metros (RADIO_INTERIOR: 135px, RADIO_EXTERIOR: 250px * 0.0055)
@export var radio_activacion_min: float = 0.68 # Distancia mínima al centro (margen limpio que no intersecta al héroe)
@export var radio_activacion_max: float = 1.50 # Distancia máxima al centro (borde exterior con margen justo)
@export var altura_suelo_offset: float = 0.025 # A ras de suelo sobre la arena (bajo las suelas del héroe)
@export var escala_abierto: Vector3 = Vector3(1.0, 1.0, 1.0)

const COOLDOWN_CONFIRMACION: float = 0.40 # Previene auto-confirmación por clics residuales de combate

@onready var sprite_radial: Sprite3D = $Sprite3D
@onready var subviewport: SubViewport = $SubViewport
@onready var control_radial: ControlRadial = $SubViewport/ControlRadial
@onready var luz_flash: OmniLight3D = $LuzFlash
@onready var capa_ui: CanvasLayer = $CapaUI
@onready var dibujador_cola: Control = $CapaUI/DibujadorCola
@onready var tooltip_flotante: PanelContainer = $CapaUI/TooltipFlotante
@onready var label_titulo: Label = $CapaUI/TooltipFlotante/Margin/VBox/LabelTitulo
@onready var rich_texto_stats: RichTextLabel = $CapaUI/TooltipFlotante/Margin/VBox/RichTextoStats
@onready var label_accion: Label = $CapaUI/TooltipFlotante/Margin/VBox/LabelAccion

var activo: bool = false
var personaje_padre: CharacterBody3D = null
var camara_3d: Camera3D = null

var _tiempo_abierto: float = 0.0
var _cursor_sobre_anillo: bool = false
var _pos_pantalla_sector: Vector2 = Vector2.ZERO

func _ready():
	visible = false
	scale = Vector3.ZERO
	top_level = true # No hereda la rotación del personaje al caminar
	
	if luz_flash != null:
		luz_flash.light_energy = 0.0
		
	if tooltip_flotante != null:
		tooltip_flotante.visible = false
		tooltip_flotante.modulate.a = 0.0
		if not tooltip_flotante.gui_input.is_connected(_on_tooltip_gui_input):
			tooltip_flotante.gui_input.connect(_on_tooltip_gui_input)
		
	if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
		dibujador_cola.ocultar()
	
	if control_radial != null:
		control_radial.clase_resaltada.connect(_on_clase_resaltada)
		control_radial.clase_confirmada.connect(confirmar_evolucion)
		
	_vincular_con_personaje()

func _vincular_con_personaje():
	if get_parent() is CharacterBody3D:
		personaje_padre = get_parent() as CharacterBody3D
	elif get_tree() != null:
		personaje_padre = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		
	if get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()
		
	if sprite_radial != null and subviewport != null:
		sprite_radial.texture = subviewport.get_texture()

## Abre el menú radial escalando suavemente de 0 a 1 mediante Tween
func abrir():
	if activo:
		return
	activo = true
	visible = true
	scale = Vector3.ZERO
	_tiempo_abierto = 0.0
	_cursor_sobre_anillo = false
	
	if personaje_padre == null or not is_instance_valid(personaje_padre):
		_vincular_con_personaje()
	
	if control_radial != null:
		control_radial.deseleccionar()
	_ocultar_tooltip()
	
	if personaje_padre != null and is_instance_valid(personaje_padre):
		global_position = personaje_padre.global_position + Vector3(0, altura_suelo_offset, 0)
		global_rotation = Vector3.ZERO
	else:
		position.y = altura_suelo_offset
		rotation = Vector3.ZERO
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", escala_abierto, 0.35)
	
	if (camara_3d == null or not is_instance_valid(camara_3d)) and get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()

## Cierra el menú radial con Tween rápido
func cerrar():
	if not activo:
		return
	activo = false
	_cursor_sobre_anillo = false
	
	if control_radial != null:
		control_radial.deseleccionar()
	_ocultar_tooltip()
		
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.18)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ZERO
	)

func _process(delta: float):
	if not activo:
		return
		
	_tiempo_abierto += delta
	
	# Seguir la posición del héroe en el piso sin rotar con él
	if personaje_padre != null and is_instance_valid(personaje_padre):
		global_position = personaje_padre.global_position + Vector3(0, altura_suelo_offset, 0)
		global_rotation = Vector3.ZERO
		
	_procesar_input_mouse()
	_actualizar_posicion_tooltip_2d()

## Clics globales: intercepta el clic para confirmar la evolución si y solo si el ratón apunta al anillo
func _input(event: InputEvent):
	if not activo:
		return
		
	# Bloquear confirmaciones residuales de combate durante la animación de apertura
	if _tiempo_abierto < COOLDOWN_CONFIRMACION:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _cursor_sobre_anillo and control_radial != null and control_radial.clase_seleccionada != "":
			confirmar_evolucion(control_radial.clase_seleccionada)
			get_viewport().set_input_as_handled()

## Permite también hacer clic directo sobre el tooltip flotante que dice [Clic para evolucionar]
func _on_tooltip_gui_input(event: InputEvent):
	if not activo or _tiempo_abierto < COOLDOWN_CONFIRMACION:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if control_radial != null and control_radial.clase_seleccionada != "":
			confirmar_evolucion(control_radial.clase_seleccionada)
			get_viewport().set_input_as_handled()

## Selección 100% EXCLUSIVA POR MOUSE:
## No se lee ningún eje de teclado (WASD) ni joystick de movimiento para que el jugador pueda
## desplazarse libremente sin que la dirección de carrera bloquee o cambie la clase elegida.
func _procesar_input_mouse():
	if get_viewport() == null:
		return
	if camara_3d == null or not is_instance_valid(camara_3d):
		camara_3d = get_viewport().get_camera_3d()
		if camara_3d == null:
			return
			
	var pj_pos = personaje_padre.global_position if (personaje_padre != null and is_instance_valid(personaje_padre)) else global_position
	var plano_y = pj_pos.y
	
	var mouse_screen = get_viewport().get_mouse_position()
	var ray_orig = camara_3d.project_ray_origin(mouse_screen)
	var ray_norm = camara_3d.project_ray_normal(mouse_screen)
	
	if abs(ray_norm.y) > 0.0001:
		var d = (plano_y - ray_orig.y) / ray_norm.y
		if d > 0.0:
			var hit_world = ray_orig + ray_norm * d
			var offset_local = hit_world - pj_pos
			
			# Distancia euclídea al centro en el plano del suelo XZ
			var dist_suelo = Vector2(offset_local.x, offset_local.z).length()
			
			# El cursor debe estar estrictamente dentro del grosor del anillo rúnico
			if dist_suelo >= radio_activacion_min and dist_suelo <= radio_activacion_max:
				_cursor_sobre_anillo = true
				var ang_rad = atan2(-offset_local.z, offset_local.x)
				var ang_deg = fposmod(rad_to_deg(ang_rad), 360.0)
				if control_radial != null:
					control_radial.actualizar_por_angulo(ang_deg)
			else:
				_cursor_sobre_anillo = false
				if control_radial != null and control_radial.clase_seleccionada != "":
					control_radial.deseleccionar()

func _on_clase_resaltada(nombre_clase: String):
	emit_signal("clase_preview_cambiada", nombre_clase)
	
	# Preview visual en el personaje (arma en mano con partículas / orbe resplandeciente)
	if personaje_padre != null and personaje_padre.has_method("mostrar_preview_clase"):
		personaje_padre.mostrar_preview_clase(nombre_clase)
		
	if nombre_clase == "":
		_ocultar_tooltip()
	else:
		_mostrar_tooltip_para_clase(nombre_clase)

func _mostrar_tooltip_para_clase(nombre_clase: String):
	if tooltip_flotante == null or control_radial == null:
		return
	var config = control_radial.CONFIG_CLASES.get(nombre_clase, null)
	if config == null:
		return
		
	if label_titulo != null:
		label_titulo.text = config["titulo"]
		label_titulo.add_theme_color_override("font_color", config["color"].lerp(Color.WHITE, 0.25))
	if rich_texto_stats != null:
		rich_texto_stats.text = config["stats_bbcode"]
	if label_accion != null:
		label_accion.text = config["accion"]
		
	tooltip_flotante.visible = true
	var tw = create_tween()
	tw.tween_property(tooltip_flotante, "modulate:a", 1.0, 0.16)

func _ocultar_tooltip():
	if tooltip_flotante != null and tooltip_flotante.visible:
		var tw = create_tween()
		tw.tween_property(tooltip_flotante, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): tooltip_flotante.visible = false)
	if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
		dibujador_cola.ocultar()

func _actualizar_posicion_tooltip_2d():
	if not activo or control_radial == null or control_radial.clase_seleccionada == "":
		if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
			dibujador_cola.ocultar()
		return
		
	if camara_3d == null or not is_instance_valid(camara_3d):
		camara_3d = get_viewport().get_camera_3d()
		if camara_3d == null:
			return
			
	var pj_pos = personaje_padre.global_position if (personaje_padre != null and is_instance_valid(personaje_padre)) else global_position
	
	# Calcular la posición 3D del sector activo en el suelo
	var sector_offset_3d = Vector3.ZERO
	match control_radial.clase_seleccionada:
		"Mago":
			# Al frente (hacia la cámara, +Z)
			sector_offset_3d = Vector3(0.0, 0.0, 1.06)
		"Guerrero":
			# A la izquierda y atrás (-X, -Z)
			sector_offset_3d = Vector3(-0.92, 0.0, -0.53)
		"Cazador":
			# A la derecha y atrás (+X, -Z)
			sector_offset_3d = Vector3(0.92, 0.0, -0.53)
			
	var pos_sector_3d = pj_pos + sector_offset_3d
	_pos_pantalla_sector = camara_3d.unproject_position(pos_sector_3d)
	
	# Posición del tooltip en pantalla 2D al lado del personaje
	var pos_pj_pantalla = camara_3d.unproject_position(pj_pos + Vector3(0, 1.1, 0))
	var tam_tip = tooltip_flotante.size if tooltip_flotante != null else Vector2(240, 110)
	
	var pos_tip = Vector2.ZERO
	var p_origen1 = Vector2.ZERO
	var p_origen2 = Vector2.ZERO
	
	match control_radial.clase_seleccionada:
		"Mago":
			# A la derecha de la cabeza del personaje, cola apuntando abajo-izquierda
			pos_tip = pos_pj_pantalla + Vector2(65.0, -45.0)
			p_origen1 = pos_tip + Vector2(0.0, tam_tip.y - 12.0)
			p_origen2 = pos_tip + Vector2(18.0, tam_tip.y)
		"Guerrero":
			# A la izquierda del personaje
			pos_tip = pos_pj_pantalla + Vector2(-tam_tip.x - 70.0, -50.0)
			p_origen1 = pos_tip + Vector2(tam_tip.x, tam_tip.y - 12.0)
			p_origen2 = pos_tip + Vector2(tam_tip.x - 18.0, tam_tip.y)
		"Cazador":
			# A la derecha y un poco más arriba
			pos_tip = pos_pj_pantalla + Vector2(75.0, -90.0)
			p_origen1 = pos_tip + Vector2(0.0, tam_tip.y - 12.0)
			p_origen2 = pos_tip + Vector2(18.0, tam_tip.y)
			
	if tooltip_flotante != null:
		tooltip_flotante.global_position = tooltip_flotante.global_position.lerp(pos_tip, 0.35)
		
	if dibujador_cola != null and dibujador_cola.has_method("actualizar_cola"):
		dibujador_cola.actualizar_cola(p_origen1, p_origen2, _pos_pantalla_sector, true)

func confirmar_evolucion(nombre_clase: String):
	if not activo:
		return
		
	activo = false
	_cursor_sobre_anillo = false
	_ocultar_tooltip()
	emit_signal("evolucion_seleccionada", nombre_clase)
	
	# Efecto de destello (Flash luminoso) con el color de la clase elegida
	if luz_flash != null and control_radial != null:
		var info = control_radial.CONFIG_CLASES.get(nombre_clase, {})
		luz_flash.light_color = info.get("color", Color.WHITE)
		luz_flash.light_energy = 3.5
		var tw_flash = create_tween()
		tw_flash.tween_property(luz_flash, "light_energy", 0.0, 0.35)
	
	# Desvanecer y escalar a 0
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ZERO
		# Notificar al FSM de EvolucionManager para completar la metamorfosis
		if personaje_padre != null and "evolucion_manager" in personaje_padre:
			var em = personaje_padre.evolucion_manager
			if em != null and em.has_method("evolucionar_a"):
				em.evolucionar_a(nombre_clase)
	)
