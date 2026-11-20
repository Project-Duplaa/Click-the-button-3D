extends Area3D

## Cofre — Suministro Rúnico Recargable del Coliseo
## Corrección de Bug Crítico: Eliminado avisar_meta() para erradicar la victoria instantánea a los 5 segundos.
## Ahora funciona como un alijo de reabastecimiento periódico:
## - Requiere proximidad (4m caminando o 6.5m al hacer clic).
## - Otorga +25 * oleada de Oro, +35 XP y cura 15 HP al jugador.
## - Entra en enfriamiento durante 45s (se vuelve translúcido), se reubica aleatoriamente en la arena y reactiva.

signal recogido(valor: int)

const AudioManager = preload("res://audio_manager.gd")

const TIEMPO_RECARGA: float = 55.0

@export var valor: int = 15
@export var oleada_desbloqueo: int = 0

var _desbloqueado: bool = false
var _en_cooldown: bool = false
var _reloj_cooldown: float = 0.0
var _posicion_inicial_y: float = 0.5

@onready var mesh_inst: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var colision: CollisionShape3D = get_node_or_null("CollisionShape3D")

func _ready():
	add_to_group("objetivos")
	add_to_group("suministros_runicos")
	global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(global_position, 1.5, 0.0)
	_posicion_inicial_y = global_position.y
	call_deferred("_reubicar_cofre_inicial_run")

	if oleada_desbloqueo <= 0:
		match name:
			"Cofre1":
				oleada_desbloqueo = 2
			"Cofre2":
				oleada_desbloqueo = 4
			"Cofre3":
				oleada_desbloqueo = 6
			_:
				oleada_desbloqueo = 2

	_desbloqueado = false
	visible = false
	input_ray_pickable = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	body_entered.connect(_al_entrar)
	input_event.connect(_on_input_event)

func _process(delta: float):
	if not _desbloqueado:
		var spawner = get_tree().get_first_node_in_group("spawner") if get_tree() != null else null
		if spawner != null and bool(spawner.get("partida_iniciada")) and int(spawner.get("oleada_actual")) >= oleada_desbloqueo:
			_desbloquear_suministro_inicial()
		return

	if _en_cooldown:
		_reloj_cooldown -= delta
		if _reloj_cooldown <= 0.0:
			_reactivar_suministro()

func _desbloquear_suministro_inicial():
	if _desbloqueado:
		return
	_desbloqueado = true
	visible = true
	input_ray_pickable = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	scale = Vector3(0.1, 0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers") if get_tree() != null else null
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "📦 ¡SUMINISTRO RÚNICO DESPLEGADO!", Color(0.98, 0.84, 0.28), 1.15)

func _al_entrar(cuerpo: Node3D):
	if not _desbloqueado or _en_cooldown:
		return
	if cuerpo.is_in_group("player") or cuerpo.is_in_group("jugador"):
		recolectar(false)

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if not _desbloqueado or _en_cooldown:
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
	if not _desbloqueado or _en_cooldown:
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
	var xp_ganada = 18
	
	AudioManager.play("puzzle_completo", 1.1)
	recogido.emit(oro_ganado)
	
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if "vida" in pj and "vida_maxima" in pj:
			pj.vida = minf(pj.vida + 10.0, pj.vida_maxima)
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_ganado)
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_ganada)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_ganada)
			
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "¡COFRE RÚNICO! +%d🪙 +%d✨ +10 HP" % [oro_ganado, xp_ganada], Color(1.0, 0.85, 0.2), 1.25)
		
	var tw = create_tween()
	if mesh_inst != null:
		tw.tween_property(mesh_inst, "scale", Vector3(1.25, 0.8, 1.25), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(mesh_inst, "scale", Vector3(0.9, 0.9, 0.9), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(self, "scale", Vector3(1.18, 1.18, 1.18), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector3(0.9, 0.9, 0.9), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	_establecer_transparencia(0.25)

func _reubicar_cofre_inicial_run() -> void:
	var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
	var parent_node: Node = get_parent()
	var ang_base: float = 0.0
	if parent_node != null:
		if parent_node.has_meta("_cofres_ang_base"):
			ang_base = float(parent_node.get_meta("_cofres_ang_base"))
		else:
			ang_base = rng.randf() * TAU
			parent_node.set_meta("_cofres_ang_base", ang_base)
	else:
		ang_base = rng.randf() * TAU

	var idx: int = 0
	if name == "Cofre2":
		idx = 1
	elif name == "Cofre3":
		idx = 2
	else:
		var todos: Array = get_tree().get_nodes_in_group("suministros_runicos")
		idx = maxi(0, todos.find(self))

	var exclusiones: Array[Vector2] = _recolectar_exclusiones_arena()
	var en_pasarela: bool = (idx == 1 and rng.randf() < 0.7) or (idx != 1 and rng.randf() < 0.4)
	var r_min: float = 42.4 if en_pasarela else 20.5
	var r_max: float = 47.4 if en_pasarela else 35.0
	var elegido := Vector3.ZERO
	var sector_ang: float = ang_base + float(idx) * (TAU / 3.0)
	for _intento in range(44):
		var ang: float = sector_ang + rng.randf_range(-0.42, 0.42)
		var r: float = rng.randf_range(r_min, r_max)
		var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
		if not ArenaColiseo.esta_dentro(cand, 2.4):
			continue
		if ArenaColiseo.esta_en_pendiente(cand.x, cand.z, 0.9):
			continue
		if not ArenaColiseo.punto_libre_de_obstaculos(cand, 3.2):
			continue
		var m_c: float = ArenaColiseo.apotema_en_pos(cand.x, cand.z)
		if m_c >= (ArenaColiseo.APOTEMA_FOSO - 1.5) and m_c <= (ArenaColiseo.APOTEMA_FOSO + 1.5):
			continue
		var p2 := Vector2(cand.x, cand.z)
		var ok := true
		for ex in exclusiones:
			if p2.distance_to(ex) < 18.0:
				ok = false
				break
		if ok:
			elegido = ArenaColiseo.clamping_y_ajustar_a_suelo(cand, 2.4, 0.0)
			break

	if elegido == Vector3.ZERO:
		elegido = ArenaColiseo.punto_seguro_con_exclusiones(20.0, 47.5, exclusiones, 16.0, rng, 0.0, false, false)

	global_position = elegido
	_posicion_inicial_y = global_position.y
	set_meta("_pos_asignada_run", true)

	if parent_node != null:
		var deco: Node = parent_node.get_node_or_null("DecoracionesArena")
		if deco != null:
			var nombre_prop: String = "Cofre3_Tanque" if name == "Cofre3" else ("%s_Caja" % name)
			var prop: Node3D = deco.get_node_or_null(nombre_prop) as Node3D
			if prop != null:
				var rad: Vector3 = Vector3(elegido.x, 0.0, elegido.z).normalized()
				if rad.length_squared() < 0.01:
					rad = Vector3.FORWARD
				var tang: Vector3 = Vector3(-rad.z, 0.0, rad.x)
				var pos_prop: Vector3 = ArenaColiseo.clamping_y_ajustar_a_suelo(elegido + tang * 1.45, 2.0, 0.0)
				prop.global_position = pos_prop
				prop.rotation.y = atan2(-pos_prop.x, -pos_prop.z) + 0.4

func _recolectar_exclusiones_arena() -> Array[Vector2]:
	var excl: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 5.25)]
	if not is_inside_tree():
		return excl
	for grupo in ["altares_runicos", "palancas_cadena"]:
		for n in get_tree().get_nodes_in_group(grupo):
			var n3: Node3D = n as Node3D
			if n3 != null:
				excl.append(Vector2(n3.global_position.x, n3.global_position.z))
	for c in get_tree().get_nodes_in_group("suministros_runicos"):
		var c3: Node3D = c as Node3D
		if c3 != null and c3 != self and c3.has_meta("_pos_asignada_run"):
			excl.append(Vector2(c3.global_position.x, c3.global_position.z))
	var j: Node3D = get_tree().get_first_node_in_group("jugador") as Node3D
	if j != null:
		excl.append(Vector2(j.global_position.x, j.global_position.z))
	return excl

func _reactivar_suministro():
	_en_cooldown = false
	input_ray_pickable = true
	monitoring = true
	monitorable = true
	
	var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
	var excl: Array[Vector2] = _recolectar_exclusiones_arena()
	global_position = ArenaColiseo.punto_seguro_con_exclusiones(16.0, 47.5, excl, 14.0, rng, 0.0, false, false)
	_posicion_inicial_y = global_position.y
	
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
