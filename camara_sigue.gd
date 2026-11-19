extends Camera3D

const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var objetivo: Node3D
@export var distancia = Vector3(0, 10.5, 8.2)
@export var suavizado = 4.0
@export var margen_camara: float = 5.5

var _shake_intensidad: float = 0.0

func _ready():
	top_level = true
	add_to_group("camara")
	if objetivo == null:
		objetivo = get_tree().get_first_node_in_group("jugador")
	if objetivo != null:
		var foco_init: Vector3 = ArenaColiseo.clamping_en_arena(objetivo.global_position, margen_camara)
		look_at_from_position(foco_init + distancia, foco_init)

func sacudir(intensidad: float = 0.3):
	_shake_intensidad = maxf(_shake_intensidad, intensidad)

func _physics_process(delta):
	if objetivo == null or not is_instance_valid(objetivo):
		objetivo = get_tree().get_first_node_in_group("jugador")
		if objetivo == null:
			return
	var foco: Vector3 = ArenaColiseo.clamping_en_arena(objetivo.global_position, margen_camara)
	var destino: Vector3 = foco + distancia
	global_position = global_position.lerp(destino, suavizado * delta)
	
	if _shake_intensidad > 0.0:
		var offset_shake = Vector3(
			randf_range(-_shake_intensidad, _shake_intensidad),
			0.0,
			randf_range(-_shake_intensidad, _shake_intensidad)
		)
		global_position += offset_shake
		_shake_intensidad = move_toward(_shake_intensidad, 0.0, delta * 1.5)
