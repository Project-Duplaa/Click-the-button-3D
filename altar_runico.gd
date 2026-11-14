extends Area3D

## Altar Rúnico CoD Zombies — Sistema de Objetivos Secundarios
## Bloquea la activación remota por clic a larga distancia:
## Solo permite activarse si el jugador está a menos de 4.5m (_jugador_cerca == true).

signal activado(id_altar: int)

const AudioManager = preload("res://audio_manager.gd")

@export var id_altar: int = 1
@export var nombre_altar: String = "Altar de la Resonancia"

var activo: bool = false
var _reloj_flotacion: float = 0.0
var _jugador_cerca: bool = false

@onready var runa_cristal: MeshInstance3D = $Pedestal/RunaCristal
@onready var luz_runa: OmniLight3D = $Pedestal/LuzRuna
@onready var columna_mesh: MeshInstance3D = get_node_or_null("Pedestal/Columna")

func _ready():
	add_to_group("altares_runicos")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	input_event.connect(_on_input_event)

func _physics_process(delta: float):
	_reloj_flotacion += delta * (4.0 if activo else 1.8)
	if runa_cristal != null:
		runa_cristal.rotate_y(delta * (3.5 if activo else 1.0))
		runa_cristal.position.y = 1.35 + sin(_reloj_flotacion) * (0.15 if activo else 0.06)
		
	var pj = get_tree().get_first_node_in_group("player") as Node3D
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador") as Node3D
	if pj != null:
		_jugador_cerca = global_position.distance_to(pj.global_position) <= 4.5

func _on_body_entered(body: Node3D):
	if activo:
		return
	if body.is_in_group("player") or body.is_in_group("jugador"):
		_jugador_cerca = true
		activar_altar("Contacto con el custodio")

func _on_body_exited(body: Node3D):
	if body.is_in_group("player") or body.is_in_group("jugador"):
		_jugador_cerca = false

func _on_area_entered(area: Area3D):
	if activo:
		return
	if area.is_in_group("boton_movil"):
		activar_altar("Paso del Núcleo Móvil")

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if activo:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _jugador_cerca:
			_mostrar_aviso_lejos()
			return
		get_viewport().set_input_as_handled()
		activar_altar("Interacción mística directa")

func _mostrar_aviso_lejos():
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), "¡Acércate al Altar para activarlo!", Color(1.0, 0.4, 0.4), 1.1)

func activar_altar(motivo: String = ""):
	if activo:
		return
	activo = true
	
	AudioManager.play("altar_activado", 0.9 + id_altar * 0.15)
	
	if luz_runa != null:
		luz_runa.light_color = Color(0.2, 0.9, 1.0)
		var tw = create_tween()
		tw.tween_property(luz_runa, "light_energy", 3.8, 0.4)
		
	if runa_cristal != null and runa_cristal.mesh != null and runa_cristal.mesh.material != null:
		var mat = runa_cristal.mesh.material as StandardMaterial3D
		if mat != null:
			var tw_mat = create_tween()
			tw_mat.tween_property(mat, "albedo_color", Color(0.2, 0.85, 1.0, 1.0), 0.4)
			tw_mat.parallel().tween_property(mat, "emission", Color(0.3, 0.9, 1.0), 0.4)
			tw_mat.parallel().tween_property(mat, "emission_energy_multiplier", 4.0, 0.4)

	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.2, 0), "⚡ ALTAR ACTIVADO (+%d)" % (id_altar * 100), Color(0.3, 0.9, 1.0), 1.25)
		
	emit_signal("activado", id_altar)
