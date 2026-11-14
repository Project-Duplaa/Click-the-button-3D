extends "res://enemigo_base.gd"
class_name CanalizadorVacio

## Canalizador del Vacío — Sacerdote con Orbe Clicable sobre la Cabeza
## Otorga mitigación a enemigos cercanos hasta que el jugador hace clic directo con el ratón
## sobre su Orbe del Vacío flotante, provocando una implosión arcana que los aturde y daña.

var _orbe_area: Area3D = null
var _orbe_mesh: MeshInstance3D = null
var _reloj_pulso: float = 0.0

func _ready():
	rapidez = 2.1
	vida_maxima = 58.0
	dano_contacto = 10.0
	xp_otorgada = 22
	oro_otorgado = 9
	add_to_group("canalizadores_vacio")
	_construir_geometria_procedural()
	super._ready()

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.45
		cap.height = 1.8
		col.shape = cap
		col.position = Vector3(0, 0.9, 0)
		add_child(col)

	var cuerpo = MeshInstance3D.new()
	cuerpo.name = "MeshInstance3D"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.55
	cyl.height = 1.7
	cuerpo.mesh = cyl
	var mat_c = StandardMaterial3D.new()
	mat_c.albedo_color = Color(0.18, 0.08, 0.35)
	mat_c.emission_enabled = true
	mat_c.emission = Color(0.45, 0.12, 0.85)
	cuerpo.material_override = mat_c
	cuerpo.position = Vector3(0, 0.85, 0)
	add_child(cuerpo)

	# Orbe del Vacío clicable sobre la cabeza
	_orbe_area = Area3D.new()
	_orbe_area.name = "OrbeVacioClicable"
	_orbe_area.add_to_group("cristal_jefe")
	_orbe_area.input_ray_pickable = true
	_orbe_area.position = Vector3(0, 2.35, 0)

	var col_o = CollisionShape3D.new()
	var sph_o = SphereShape3D.new()
	sph_o.radius = 0.65
	col_o.shape = sph_o
	_orbe_area.add_child(col_o)

	_orbe_mesh = MeshInstance3D.new()
	var sph_m = SphereMesh.new()
	sph_m.radius = 0.42
	sph_m.height = 0.84
	_orbe_mesh.mesh = sph_m
	var mat_o = StandardMaterial3D.new()
	mat_o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_o.albedo_color = Color(0.35, 0.95, 1.0)
	_orbe_mesh.material_override = mat_o
	_orbe_area.add_child(_orbe_mesh)

	_orbe_area.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_detonar_orbe_vacio()
	)
	add_child(_orbe_area)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	_reloj_pulso += delta * 4.0
	if _orbe_mesh != null:
		var s = 1.0 + sin(_reloj_pulso) * 0.18
		_orbe_mesh.scale = Vector3(s, s, s)

	if jugador == null or not is_instance_valid(jugador):
		return Vector3.ZERO
	var dif = jugador.global_position - global_position
	dif.y = 0.0
	var dist = dif.length()
	if dist < 6.5:
		return -dif.normalized() * (rapidez * 0.75)
	elif dist > 10.5:
		return dif.normalized() * rapidez
	return Vector3.ZERO

func _detonar_orbe_vacio():
	if muerto:
		return
	AudioManager.play("orbe_explosion", 1.35)
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 2.6, 0), "💥 ¡CANALIZACIÓN ROTA!", Color(0.35, 0.95, 1.0), 1.25)

	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node3D and is_instance_valid(e) and e != self:
			if global_position.distance_to(e.global_position) <= 6.5:
				if e.has_method("recibir_dano"):
					e.recibir_dano(28.0, true)
				if e.has_method("aplicar_knockback"):
					var dir = (e.global_position - global_position).normalized()
					dir.y = 0.0
					e.aplicar_knockback(dir * 9.0)
	recibir_dano(vida_maxima + 10.0, true)
