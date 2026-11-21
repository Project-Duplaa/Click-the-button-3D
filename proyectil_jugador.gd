class_name BalaJugador
extends Area3D

## BalaJugador - Sistema de Proyectiles Balísticos con Perforación, Rebote y Knockback Físico
## Compatible con Godot 4.6

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")

@export var rapidez: float = 16.0
@export var dano: float = 15.0
@export var tiempo_vida: float = 3.0

var direccion: Vector3 = Vector3.FORWARD
var perforaciones_restantes: int = 0
var rebotes_restantes: int = 0
var es_critico: bool = false
var estilo: String = "flecha"
var _enemigos_golpeados: Array = []
var _tiempo: float = 0.0

func _ready():
	add_to_group("proyectil")
	collision_mask = 2 | 8
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_crear_malla_si_no_existe()

static var _shape_col_def: SphereShape3D = null


func _crear_malla_si_no_existe():
	if _shape_col_def == null:
		_shape_col_def = SphereShape3D.new()
		_shape_col_def.radius = 0.45

	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		col.shape = _shape_col_def
		add_child(col)

	var malla_base := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if malla_base != null:
		malla_base.visible = false
	VfxCombate.construir_visual_proyectil(self, estilo, es_critico)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float, rapidez_in: float = 16.0, perforaciones_in: int = 0, es_crit: bool = false, estilo_in: String = ""):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	rapidez = rapidez_in
	perforaciones_restantes = perforaciones_in
	es_critico = es_crit
	if estilo_in != "":
		estilo = estilo_in
	VfxCombate.construir_visual_proyectil(self, estilo, es_critico)
	if direccion.length_squared() > 0.001 and absf(direccion.dot(Vector3.UP)) < 0.999:
		look_at(global_position + direccion, Vector3.UP)

func _physics_process(delta: float):
	global_position += direccion * rapidez * delta
	_tiempo += delta
	if _tiempo >= tiempo_vida or not ArenaColiseo.esta_dentro(global_position, 0.0) or global_position.y < ArenaColiseo.obtener_altura_suelo(global_position.x, global_position.z) - 0.15:
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
		var cols_j := VfxCombate.obtener_colores_estilo(estilo, es_critico)
		VfxCombate.spawn_impacto(get_parent(), global_position, cols_j["main"], cols_j["core"], 0.95, es_critico)
		
		if rebotes_restantes > 0:
			rebotes_restantes -= 1
			var nuevo_objetivo = _buscar_siguiente_enemigo(target)
			if nuevo_objetivo != null:
				var pos_antes: Vector3 = global_position
				var pos_dest: Vector3 = nuevo_objetivo.global_position + Vector3(0.0, 0.9, 0.0)
				VfxCombate.spawn_rayo_segmento(get_parent(), pos_antes, pos_dest, cols_j["main"], cols_j["core"], 0.09, 0.14, 0.16)
				direccion = (pos_dest - global_position).normalized()
				if direccion.length_squared() > 0.001 and absf(direccion.dot(Vector3.UP)) < 0.999:
					look_at(global_position + direccion, Vector3.UP)
				return
				
		if perforaciones_restantes > 0:
			perforaciones_restantes -= 1
			return
		else:
			queue_free()
	elif target is StaticBody3D:
		var cols_w := VfxCombate.obtener_colores_estilo(estilo, false)
		VfxCombate.spawn_impacto(get_parent(), global_position, cols_w["main"], cols_w["core"], 0.65, false)
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
