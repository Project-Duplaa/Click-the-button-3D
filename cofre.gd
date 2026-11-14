extends Area3D

## Cofre — Suministro Rúnico Recargable del Coliseo
## Corrección de Bug Crítico: Eliminado avisar_meta() para erradicar la victoria instantánea a los 5 segundos.
## Ahora funciona como un alijo de reabastecimiento periódico:
## - Requiere proximidad (4m caminando o 6.5m al hacer clic).
## - Otorga +25 * oleada de Oro, +35 XP y cura 15 HP al jugador.
## - Entra en enfriamiento durante 45s (se vuelve translúcido), se reubica aleatoriamente en la arena y reactiva.

signal recogido(valor: int)

const AudioManager = preload("res://audio_manager.gd")
const TIEMPO_RECARGA: float = 45.0

@export var valor: int = 25

var _en_cooldown: bool = false
var _reloj_cooldown: float = 0.0
var _posicion_inicial_y: float = 0.5

@onready var mesh_inst: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var colision: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready():
	add_to_group("objetivos")
	add_to_group("suministros_runicos")
	input_ray_pickable = true
	_posicion_inicial_y = global_position.y
	
	body_entered.connect(_al_entrar)
	input_event.connect(_on_input_event)

func _process(delta: float):
	if _en_cooldown:
		_reloj_cooldown -= delta
		if _reloj_cooldown <= 0.0:
			_reactivar_suministro()

func _al_entrar(cuerpo: Node3D):
	if _en_cooldown:
		return
	if cuerpo.is_in_group("player") or cuerpo.is_in_group("jugador"):
		recolectar(false)

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if _en_cooldown:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pj = get_tree().get_first_node_in_group("player") as Node3D
		if pj == null:
			pj = get_tree().get_first_node_in_group("jugador") as Node3D
		if pj != null and global_position.distance_to(pj.global_position) <= 6.5:
			get_viewport().set_input_as_handled()
			recolectar(true)
		elif pj != null:
			_mostrar_aviso_distancia()

func recolectar(_por_click: bool = false):
	if _en_cooldown:
		return
		
	_en_cooldown = true
	_reloj_cooldown = TIEMPO_RECARGA
	input_ray_pickable = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var oleada = 1
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner != null and "oleada_actual" in spawner:
		oleada = int(spawner.oleada_actual)
	var oro_ganado = valor * oleada
	var xp_ganada = 35
	
	AudioManager.play("puzzle_completo", 1.1)
	recogido.emit(oro_ganado)
	
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if "vida" in pj and "vida_maxima" in pj:
			pj.vida = minf(pj.vida + 15.0, pj.vida_maxima)
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_ganado)
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_ganada)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_ganada)
			
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "¡COFRE RÚNICO! +%d🪙 +%d✨ +15 HP" % [oro_ganado, xp_ganada], Color(1.0, 0.85, 0.2), 1.25)
		
	var tw = create_tween()
	if mesh_inst != null:
		tw.tween_property(mesh_inst, "scale", Vector3(1.25, 0.8, 1.25), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(mesh_inst, "scale", Vector3(0.9, 0.9, 0.9), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(self, "scale", Vector3(1.18, 1.18, 1.18), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector3(0.9, 0.9, 0.9), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	_establecer_transparencia(0.25)

func _reactivar_suministro():
	_en_cooldown = false
	input_ray_pickable = true
	monitoring = true
	monitorable = true
	
	var nueva_x = randf_range(-24.0, 24.0)
	var nueva_z = randf_range(-24.0, 24.0)
	global_position = Vector3(nueva_x, _posicion_inicial_y, nueva_z)
	
	_establecer_transparencia(1.0)
	
	scale = Vector3.ONE
	var tw = create_tween()
	if mesh_inst != null:
		mesh_inst.scale = Vector3(0.1, 0.1, 0.1)
		tw.tween_property(mesh_inst, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		scale = Vector3(0.1, 0.1, 0.1)
		tw.tween_property(self, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "✨ ¡Suministro Rúnico Reabastecido!", Color(0.3, 0.9, 1.0), 1.1)

func _establecer_transparencia(alfa: float):
	if mesh_inst != null and mesh_inst.mesh != null:
		var mat = mesh_inst.get_surface_override_material(0) as StandardMaterial3D
		if mat == null and mesh_inst.mesh.material != null:
			mat = mesh_inst.mesh.material.duplicate() as StandardMaterial3D
			mesh_inst.set_surface_override_material(0, mat)
		if mat != null:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = alfa

func _mostrar_aviso_distancia():
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.6, 0), "¡Acércate a menos de 6.5m!", Color(1.0, 0.4, 0.4), 1.0)
