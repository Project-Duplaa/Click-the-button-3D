@tool
extends Node3D
class_name EvolucionRadial

## EvolucionRadial (Controlador 3D In-World a los pies del Personaje)
## Administra el Sprite3D con SubViewport para desplegar el menú radial,
## proyecta la posición del ratón al plano del suelo, procesa el stick del gamepad,
## emite señales de preview y confirmación, y anima aperturas / cierres con Tween.

signal evolucion_seleccionada(nombre_clase: String)
signal clase_preview_cambiada(nombre_clase: String)

@export var radio_activacion_min: float = 0.35 # Distancia mínima al centro para considerar apuntado
@export var radio_activacion_max: float = 2.80 # Distancia máxima al centro
@export var altura_suelo_offset: float = 0.03 # Altura sobre el suelo para evitar Z-fighting
@export var escala_abierto: Vector3 = Vector3(1.0, 1.0, 1.0)

@onready var sprite_radial: Sprite3D = $Sprite3D
@onready var subviewport: SubViewport = $SubViewport
@onready var control_radial: ControlRadial = $SubViewport/ControlRadial
@onready var luz_flash: OmniLight3D = $LuzFlash

var activo: bool = false
var personaje_padre: CharacterBody3D = null
var camara_3d: Camera3D = null

func _ready():
	visible = false
	scale = Vector3.ZERO
	position.y = altura_suelo_offset
	
	if luz_flash != null:
		luz_flash.light_energy = 0.0
	
	if control_radial != null:
		control_radial.clase_resaltada.connect(_on_clase_resaltada)
		control_radial.clase_confirmada.connect(confirmar_evolucion)
		
	call_deferred("_vincular_con_personaje")

func _vincular_con_personaje():
	if get_parent() is CharacterBody3D:
		personaje_padre = get_parent() as CharacterBody3D
	else:
		personaje_padre = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		
	if get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()

## Abre el menú radial escalando suavemente de 0 a 1 mediante Tween
func abrir():
	if activo:
		return
	activo = true
	visible = true
	scale = Vector3.ZERO
	position.y = altura_suelo_offset
	
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", escala_abierto, 0.30)
	
	# Asegurar que la cámara esté actualizada
	if (camara_3d == null or not is_instance_valid(camara_3d)) and get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()

## Cierra el menú radial con Tween rápido
func cerrar():
	if not activo:
		return
	activo = false
	
	if control_radial != null:
		control_radial.ocultar_tooltip()
		
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.18)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ZERO
	)

func _process(_delta: float):
	if not activo:
		return
		
	_procesar_input_direccion()

func _unhandled_input(event: InputEvent):
	if not activo:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if control_radial != null and control_radial.clase_seleccionada != "":
				confirmar_evolucion(control_radial.clase_seleccionada)
				get_viewport().set_input_as_handled()
				
	elif event.is_action_pressed("ui_accept"):
		if control_radial != null and control_radial.clase_seleccionada != "":
			confirmar_evolucion(control_radial.clase_seleccionada)
			get_viewport().set_input_as_handled()

func _procesar_input_direccion():
	# 1. Prioridad: Stick del mando (controlador analógico)
	var stick = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if stick.length() > 0.35:
		# En espacio 3D de cámara top-down / isométrica:
		# stick.x es derecha (+X), stick.y es abajo (+Z hacia la cámara)
		# En polar: rad_to_deg(atan2(-stick.y, stick.x))
		var ang_rad = atan2(-stick.y, stick.x)
		var ang_deg = fposmod(rad_to_deg(ang_rad), 360.0)
		if control_radial != null:
			control_radial.actualizar_por_angulo(ang_deg)
		return
		
	# 2. Entrada de Mouse (Raycasting al plano del suelo del personaje)
	if get_viewport() == null:
		return
	if camara_3d == null or not is_instance_valid(camara_3d):
		camara_3d = get_viewport().get_camera_3d()
		if camara_3d == null:
			return
			
	var mouse_screen = get_viewport().get_mouse_position()
	var ray_orig = camara_3d.project_ray_origin(mouse_screen)
	var ray_norm = camara_3d.project_ray_normal(mouse_screen)
	
	if abs(ray_norm.y) > 0.0001:
		var d = (global_position.y - ray_orig.y) / ray_norm.y
		var hit_world = ray_orig + ray_norm * d
		var offset_local = hit_world - global_position
		
		# Distancia al centro en el plano XZ
		var dist_suelo = Vector2(offset_local.x, offset_local.z).length()
		
		if dist_suelo >= radio_activacion_min and dist_suelo <= radio_activacion_max:
			# -offset_local.z corresponde a la dirección "atrás/adelante" en el plano
			var ang_rad = atan2(-offset_local.z, offset_local.x)
			var ang_deg = fposmod(rad_to_deg(ang_rad), 360.0)
			if control_radial != null:
				control_radial.actualizar_por_angulo(ang_deg)

func _on_clase_resaltada(nombre_clase: String):
	emit_signal("clase_preview_cambiada", nombre_clase)
	
	# Preview visual en el personaje (simular equipamiento o aura de clase)
	if personaje_padre != null and personaje_padre.has_method("mostrar_preview_clase"):
		personaje_padre.mostrar_preview_clase(nombre_clase)

func confirmar_evolucion(nombre_clase: String):
	if not activo:
		return
		
	activo = false
	emit_signal("evolucion_seleccionada", nombre_clase)
	
	# Efecto de destello (Flash luminoso) con el color de la clase elegida
	if luz_flash != null and control_radial != null:
		var info = control_radial.CONFIG_CLASES.get(nombre_clase, {})
		luz_flash.light_color = info.get("color", Color.WHITE)
		luz_flash.light_energy = 3.5
		var tw_flash = create_tween()
		tw_flash.tween_property(luz_flash, "light_energy", 0.0, 0.35)
	
	# Desvanecer y escalar a 0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if control_radial != null and control_radial.tooltip_flotante != null:
		tw.tween_property(control_radial.tooltip_flotante, "modulate:a", 0.0, 0.15)
		
	tw.chain().tween_callback(func():
		visible = false
		scale = Vector3.ZERO
		# Notificar al FSM de EvolucionManager para completar la metamorfosis
		if personaje_padre != null and "evolucion_manager" in personaje_padre:
			var em = personaje_padre.evolucion_manager
			if em != null and em.has_method("evolucionar_a"):
				em.evolucionar_a(nombre_clase)
	)
