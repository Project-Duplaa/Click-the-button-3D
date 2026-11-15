extends Area3D

var direccion: Vector3 = Vector3.FORWARD
var rapidez: float = 16.0
var dano: float = 14.0
var tiempo_vida: float = 2.5
var es_critico: bool = false
var perforaciones: int = 0
var rebotes_restantes: int = 0
var _enemigos_golpeados: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if es_critico:
		scale = Vector3(1.45, 1.45, 1.45)

func iniciar(pos_origen: Vector3, dir: Vector3, dano_in: float, vel: float = 16.0, perfs: int = 0, crit: bool = false) -> void:
	global_position = pos_origen
	direccion = dir.normalized() if dir.length_squared() > 0.001 else Vector3.FORWARD
	dano = dano_in
	rapidez = vel
	perforaciones = perfs
	es_critico = crit
	if es_critico:
		scale = Vector3(1.45, 1.45, 1.45)
	if direccion.length_squared() > 0.001 and is_inside_tree():
		var target_look = global_position + direccion
		if not global_position.is_equal_approx(target_look):
			look_at(target_look, Vector3.UP)

func _physics_process(delta):
	global_position += direccion * rapidez * delta
	tiempo_vida -= delta
	if tiempo_vida <= 0.0:
		queue_free()

func _on_area_entered(area: Area3D):
	if area == null or _enemigos_golpeados.has(area):
		return
	if (area.is_in_group("cristal_jefe") or area.is_in_group("rompibles")) and area.has_method("recibir_dano"):
		_enemigos_golpeados.append(area)
		area.recibir_dano(dano, es_critico)
		if perforaciones > 0:
			perforaciones -= 1
		else:
			queue_free()

func _on_body_entered(body):
	if body == null or _enemigos_golpeados.has(body):
		return
	if body.is_in_group("enemigos") or body.is_in_group("enemies") or body.is_in_group("rompibles"):
		_enemigos_golpeados.append(body)
		if body.has_method("recibir_dano"):
			body.recibir_dano(dano, es_critico)
		if body.has_method("aplicar_knockback"):
			var dir_kb = direccion
			dir_kb.y = 0.0
			if dir_kb.length_squared() > 0.001:
				body.aplicar_knockback(dir_kb.normalized() * (5.2 if es_critico else 3.0))

		# Intentar rebote encadenado (Ricochet) si tiene rebotes restantes
		if rebotes_restantes > 0:
			var siguiente = _buscar_objetivo_rebote(body)
			if siguiente != null:
				rebotes_restantes -= 1
				var dir_rebote = (siguiente.global_position - global_position)
				dir_rebote.y = 0.0
				if dir_rebote.length_squared() > 0.001:
					direccion = dir_rebote.normalized()
					tiempo_vida = maxf(tiempo_vida, 1.2)
				return

		if perforaciones > 0:
			perforaciones -= 1
		else:
			queue_free()
	elif body is StaticBody3D:
		queue_free()

func _buscar_objetivo_rebote(ignorar: Node3D) -> Node3D:
	var mejor: Node3D = null
	var menor_dist: float = 12.0
	var candidatos = get_tree().get_nodes_in_group("enemigos")
	for e in candidatos:
		if e is Node3D and is_instance_valid(e) and e != ignorar and not _enemigos_golpeados.has(e):
			if "muerto" in e and e.muerto:
				continue
			var d = global_position.distance_to(e.global_position)
			if d < menor_dist:
				menor_dist = d
				mejor = e
	return mejor
