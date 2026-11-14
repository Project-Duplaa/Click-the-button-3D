class_name BalaJugador
extends Area3D

## BalaJugador - Sistema de Proyectiles Balísticos con Perforación, Rebote y Knockback Físico
## Compatible con Godot 4.6

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 16.0
@export var dano: float = 15.0
@export var tiempo_vida: float = 3.0

var direccion: Vector3 = Vector3.FORWARD
var perforaciones_restantes: int = 0
var rebotes_restantes: int = 0
var es_critico: bool = false
var _enemigos_golpeados: Array = []
var _tiempo: float = 0.0

func _ready():
	add_to_group("proyectil")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_crear_malla_si_no_existe()

static var _mesh_flecha_norm: CylinderMesh = null
static var _mesh_flecha_crit: CylinderMesh = null
static var _shape_col_def: SphereShape3D = null


func _crear_malla_si_no_existe():
	if get_node_or_null("MeshInstance3D") != null:
		return
	if _mesh_flecha_norm == null:
		var mat_n := StandardMaterial3D.new()
		mat_n.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_n.albedo_color = Color(0.25, 0.85, 1.0)
		_mesh_flecha_norm = CylinderMesh.new()
		_mesh_flecha_norm.top_radius = 0.03
		_mesh_flecha_norm.bottom_radius = 0.08
		_mesh_flecha_norm.height = 0.95
		_mesh_flecha_norm.material = mat_n
	if _mesh_flecha_crit == null:
		var mat_c := StandardMaterial3D.new()
		mat_c.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		mat_c.albedo_color = Color(1.0, 0.85, 0.2)
		_mesh_flecha_crit = CylinderMesh.new()
		_mesh_flecha_crit.top_radius = 0.03
		_mesh_flecha_crit.bottom_radius = 0.08
		_mesh_flecha_crit.height = 0.95
		_mesh_flecha_crit.material = mat_c
	if _shape_col_def == null:
		_shape_col_def = SphereShape3D.new()
		_shape_col_def.radius = 0.45

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_inst.mesh = _mesh_flecha_crit if es_critico else _mesh_flecha_norm
	mesh_inst.rotation_degrees.x = 90.0
	add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	col.shape = _shape_col_def
	add_child(col)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float, rapidez_in: float = 16.0, perforaciones_in: int = 0, es_crit: bool = false):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	rapidez = rapidez_in
	perforaciones_restantes = perforaciones_in
	es_critico = es_crit
	if direccion.length_squared() > 0.001 and absf(direccion.dot(Vector3.UP)) < 0.999:
		look_at(global_position + direccion, Vector3.UP)

func _physics_process(delta: float):
	global_position += direccion * rapidez * delta
	_tiempo += delta
	if _tiempo >= tiempo_vida:
		queue_free()

func _on_body_entered(body: Node):
	_procesar_impacto(body)

func _on_area_entered(area: Area3D):
	_procesar_impacto(area)

func _procesar_impacto(target: Node):
	if target == null or not is_instance_valid(target):
		return
	if target in _enemigos_golpeados:
		return
	if target.is_in_group("player") or target.is_in_group("jugador") or target.is_in_group("proyectil") or target.is_in_group("boton_movil"):
		return
		
	if target.is_in_group("enemies") or target.is_in_group("enemigos") or target.has_method("recibir_dano"):
		_enemigos_golpeados.append(target)
		
		if target.has_method("recibir_dano"):
			target.recibir_dano(int(dano))
			
		if target.has_method("aplicar_knockback"):
			target.aplicar_knockback(direccion * 5.5)
		elif "velocity" in target:
			target.velocity += direccion * 5.5
			
		AudioManager.play("impacto_flecha", randf_range(1.0, 1.25))
		
		if rebotes_restantes > 0:
			rebotes_restantes -= 1
			var nuevo_objetivo = _buscar_siguiente_enemigo(target)
			if nuevo_objetivo != null:
				direccion = (nuevo_objetivo.global_position - global_position).normalized()
				direccion.y = 0.0
				if direccion.length_squared() > 0.001:
					look_at(global_position + direccion, Vector3.UP)
				return
				
		if perforaciones_restantes > 0:
			perforaciones_restantes -= 1
			return
		else:
			queue_free()
	elif target is StaticBody3D:
		queue_free()

func _buscar_siguiente_enemigo(ignorar: Node) -> Node3D:
	var enemigos = get_tree().get_nodes_in_group("enemies")
	if enemigos.is_empty():
		enemigos = get_tree().get_nodes_in_group("enemigos")
	var mas_cercano: Node3D = null
	var menor_dist: float = 14.0
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D and e != ignorar and not (e in _enemigos_golpeados):
			var d = global_position.distance_to(e.global_position)
			if d < menor_dist:
				menor_dist = d
				mas_cercano = e
	return mas_cercano
