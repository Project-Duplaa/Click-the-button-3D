extends Area3D

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var rapidez: float = 5.5
@export var dano: float = 11.0
@export var tiempo_vida: float = 4.0
@export var seguir_terreno: bool = false

var direccion: Vector3 = Vector3.FORWARD
var _tiempo: float = 0.0
var _impactado: bool = false

@onready var mesh_flecha: MeshInstance3D = $MeshInstance3D
@onready var luz: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready():
	add_to_group("proyectiles_enemigos")
	collision_mask = 2 | 4
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float = 11.0, vel_in: float = 5.5):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	rapidez = vel_in
	_mirar_hacia(direccion)

func _mirar_hacia(dir: Vector3):
	if dir.length_squared() > 0.001 and absf(dir.dot(Vector3.UP)) < 0.999:
		look_at(global_position + dir, Vector3.UP)

func _physics_process(delta):
	if _impactado:
		return
	global_position += direccion * rapidez * delta
	if seguir_terreno:
		var y_obj := ArenaColiseo.obtener_altura_suelo(global_position.x, global_position.z) + 1.0
		global_position.y = lerpf(global_position.y, y_obj, minf(1.0, delta * 14.0))
	elif global_position.y < ArenaColiseo.obtener_altura_suelo(global_position.x, global_position.z) - 0.15:
		_impactar_obstaculo()
		return
	_tiempo += delta
	if _tiempo >= tiempo_vida or not ArenaColiseo.esta_dentro(global_position, 0.0):
		queue_free()

func _on_body_entered(body):
	if _impactado:
		return
	if body.is_in_group("enemigos"):
		return
		
	if body.is_in_group("jugador"):
		_impactar_jugador(body)
	elif body is StaticBody3D:
		_impactar_obstaculo()

func _on_area_entered(area):
	if _impactado:
		return
	if area.is_in_group("boton_movil"):
		# El botón móvil absorbe o desvía el proyectil con una onda
		_impactar_obstaculo()

func _impactar_jugador(jugador: Node):
	_impactado = true
	AudioManager.play("impacto_flecha", 0.95)
	
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)
	elif jugador.has_node("Salud"):
		jugador.get_node("Salud").recibir_golpe(int(dano))
		
	_desaparecer_con_efecto()

func _impactar_obstaculo():
	_impactado = true
	AudioManager.play("impacto_flecha", 1.25)
	_desaparecer_con_efecto()

func _desaparecer_con_efecto():
	# Destello final y remoción
	if luz != null:
		var tw = create_tween()
		tw.tween_property(luz, "light_energy", 0.0, 0.12)
	if mesh_flecha != null:
		var tw_m = create_tween()
		tw_m.tween_property(mesh_flecha, "scale", Vector3.ZERO, 0.12)
		tw_m.chain().tween_callback(queue_free)
	else:
		queue_free()
