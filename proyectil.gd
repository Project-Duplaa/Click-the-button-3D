extends Area3D

const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")

var direccion: Vector3 = Vector3.FORWARD
var rapidez: float = 16.0
var dano: float = 14.0
var tiempo_vida: float = 2.5
var es_critico: bool = false
var perforaciones: int = 0
var rebotes_restantes: int = 0
var estilo: String = "flecha"
var _enemigos_golpeados: Array = []

func _ready():
	collision_mask = 2 | 8
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if es_critico:
		scale = Vector3(1.45, 1.45, 1.45)
	_actualizar_visual_proyectil()

func _actualizar_visual_proyectil() -> void:
	var malla_base := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if malla_base != null:
		malla_base.visible = false
	VfxCombate.construir_visual_proyectil(self, estilo, es_critico)

func iniciar(pos_origen: Vector3, dir: Vector3, dano_in: float, vel: float = 16.0, perfs: int = 0, crit: bool = false, estilo_in: String = "") -> void:
	global_position = pos_origen
	direccion = dir.normalized() if dir.length_squared() > 0.001 else Vector3.FORWARD
	dano = dano_in
	rapidez = vel
	perforaciones = perfs
	es_critico = crit
	if estilo_in != "":
		estilo = estilo_in
	if es_critico:
		scale = Vector3(1.45, 1.45, 1.45)
	_actualizar_visual_proyectil()
	if direccion.length_squared() > 0.001 and is_inside_tree():
		var target_look = global_position + direccion
		if not global_position.is_equal_approx(target_look):
			look_at(target_look, Vector3.UP)

func _physics_process(delta):
	global_position += direccion * rapidez * delta
	tiempo_vida -= delta
	if tiempo_vida <= 0.0 or not ArenaColiseo.esta_dentro(global_position, 0.0) or global_position.y < ArenaColiseo.obtener_altura_suelo(global_position.x, global_position.z) - 0.15:
		queue_free()

func _on_area_entered(area: Area3D):
	if area == null or _enemigos_golpeados.has(area):
		return
	if (area.is_in_group("cristal_jefe") or area.is_in_group("rompibles")) and area.has_method("recibir_dano"):
		_enemigos_golpeados.append(area)
		area.recibir_dano(dano, es_critico)
		var cols_a := VfxCombate.obtener_colores_estilo(estilo, es_critico)
		VfxCombate.spawn_impacto(get_parent(), global_position, cols_a["main"], cols_a["core"], 0.95, es_critico)
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

		var cols_p := VfxCombate.obtener_colores_estilo(estilo, es_critico)
		VfxCombate.spawn_impacto(get_parent(), global_position, cols_p["main"], cols_p["core"], 0.95, es_critico)

		# Intentar rebote encadenado (Ricochet) si tiene rebotes restantes
		if rebotes_restantes > 0:
			var siguiente: Node3D = _buscar_objetivo_rebote(body)
			if siguiente != null:
				rebotes_restantes -= 1
				var pos_antes: Vector3 = global_position
				var pos_dest: Vector3 = siguiente.global_position + Vector3(0.0, 0.9, 0.0)
				VfxCombate.spawn_rayo_segmento(get_parent(), pos_antes, pos_dest, cols_p["main"], cols_p["core"], 0.09, 0.14, 0.16)
				var dir_rebote = (pos_dest - global_position)
				if dir_rebote.length_squared() > 0.001:
					direccion = dir_rebote.normalized()
					tiempo_vida = maxf(tiempo_vida, 1.2)
					if is_inside_tree() and absf(direccion.dot(Vector3.UP)) < 0.999:
						look_at(global_position + direccion, Vector3.UP)
				return

		if perforaciones > 0:
			perforaciones -= 1
		else:
			queue_free()
	elif body is StaticBody3D:
		var cols_m := VfxCombate.obtener_colores_estilo(estilo, false)
		VfxCombate.spawn_impacto(get_parent(), global_position, cols_m["main"], cols_m["core"], 0.65, false)
		queue_free()

func _buscar_objetivo_rebote(ignorar: Node3D) -> Node3D:
	var mejor: Node3D = null
	var menor_dist_sq: float = 144.0
	var candidatos = get_tree().get_nodes_in_group("enemigos")
	var mi_pos := global_position
	for e in candidatos:
		if e is Node3D and is_instance_valid(e) and e != ignorar and not _enemigos_golpeados.has(e):
			if "muerto" in e and e.muerto:
				continue
			var d_sq = mi_pos.distance_squared_to(e.global_position)
			if d_sq < menor_dist_sq:
				menor_dist_sq = d_sq
				mejor = e
	return mejor
