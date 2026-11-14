extends "res://enemigo_base.gd"
class_name GolemTesoro

## Gólem de Tesoro — Piñata Dorada de Riesgo/Recompensa
## Huye del jugador durante 15 segundos antes de desvanecerse. Cada clic directo con el ratón
## o golpe de arma desprende monedas de oro y XP en tiempo real; abatirlo suelta un premio mayor.

var _tiempo_escape: float = 15.0

func _ready():
	rapidez = 4.2
	vida_maxima = 95.0
	dano_contacto = 0.0
	xp_otorgada = 45
	oro_otorgado = 35
	add_to_group("golems_tesoro")
	_construir_geometria_procedural()
	super._ready()

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box_s = BoxShape3D.new()
		box_s.size = Vector3(1.1, 1.4, 1.1)
		col.shape = box_s
		col.position = Vector3(0, 0.7, 0)
		add_child(col)

	var cuerpo = MeshInstance3D.new()
	cuerpo.name = "MeshInstance3D"
	var box_m = BoxMesh.new()
	box_m.size = Vector3(1.0, 1.3, 1.0)
	cuerpo.mesh = box_m
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.84, 0.12)
	cuerpo.material_override = mat
	cuerpo.position = Vector3(0, 0.7, 0)
	add_child(cuerpo)

	var area_clic = Area3D.new()
	area_clic.name = "AreaPinataDorada"
	area_clic.input_ray_pickable = true
	var col_a = CollisionShape3D.new()
	var sph_a = SphereShape3D.new()
	sph_a.radius = 0.95
	col_a.shape = sph_a
	col_a.position = Vector3(0, 0.8, 0)
	area_clic.add_child(col_a)
	area_clic.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_golpear_pinata_clic()
	)
	add_child(area_clic)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	_tiempo_escape -= delta
	if _tiempo_escape <= 0.0 and not muerto:
		var pool = get_tree().get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(global_position + Vector3(0, 1.8, 0), "💨 ¡Gólem de Tesoro escapó!", Color(0.9, 0.8, 0.3), 1.1)
		queue_free()
		return Vector3.ZERO

	if jugador == null or not is_instance_valid(jugador):
		return Vector3.ZERO
	var dir_huida = (global_position - jugador.global_position)
	dir_huida.y = 0.0
	if dir_huida.length_squared() < 0.01:
		dir_huida = Vector3.FORWARD
	dir_huida = dir_huida.normalized()
	# Si se acerca al borde de la arena, girar 90 grados para no acorralarse solo
	if absf(global_position.x) > 21.0 or absf(global_position.z) > 21.0:
		dir_huida = dir_huida.rotated(Vector3.UP, deg_to_rad(105.0))
	return dir_huida * rapidez

func _golpear_pinata_clic():
	if muerto:
		return
	AudioManager.play("moneda", 1.35)
	if jugador != null and jugador.has_method("recoger_drop"):
		jugador.recoger_drop(0, 4)
	recibir_dano(14.0, true)

func morir():
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 2.2, 0), "🪙 ¡BOTÍN DORADO MASIVO! +35🪙 +45 XP", Color(1.0, 0.88, 0.15), 1.35)
	super.morir()
