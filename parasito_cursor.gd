extends "res://enemigo_base.gd"
class_name ParasitoCursor

## Parásito de Cursor — Enemigo Interactivo con el Ratón
## Ignora al jugador y persigue directamente al Botón Móvil para adherirse a él y bloquearlo.
## Requiere 3 clics directos (o ataques del héroe) para reventar en una lluvia de Clics y XP.

var boton_objetivo: Node3D = null
var adherido_al_boton: bool = false
var clics_para_reventar: int = 3
var _angulo_adherido: float = 0.0

func _ready():
	rapidez = 4.6
	vida_maxima = 32.0
	dano_contacto = 6.0
	xp_otorgada = 16
	oro_otorgado = 6
	add_to_group("parasitos_cursor")
	_construir_geometria_procedural()
	super._ready()
	boton_objetivo = get_tree().get_first_node_in_group("boton_movil")

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sph = SphereShape3D.new()
		sph.radius = 0.5
		col.shape = sph
		col.position = Vector3(0, 0.5, 0)
		add_child(col)

	var mesh_i = MeshInstance3D.new()
	mesh_i.name = "MeshInstance3D"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.22
	torus.outer_radius = 0.52
	mesh_i.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.15, 0.95)
	mesh_i.material_override = mat
	mesh_i.position = Vector3(0, 0.65, 0)
	add_child(mesh_i)

	var area_clic = Area3D.new()
	area_clic.name = "AreaClicDirecto"
	area_clic.input_ray_pickable = true
	var col_a = CollisionShape3D.new()
	var sph_a = SphereShape3D.new()
	sph_a.radius = 0.75
	col_a.shape = sph_a
	col_a.position = Vector3(0, 0.65, 0)
	area_clic.add_child(col_a)
	area_clic.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			recibir_clic_directo()
	)
	add_child(area_clic)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if boton_objetivo == null or not is_instance_valid(boton_objetivo):
		boton_objetivo = get_tree().get_first_node_in_group("boton_movil")
	if boton_objetivo == null:
		return super._calcular_velocidad_ia(delta)

	var dist = global_position.distance_to(boton_objetivo.global_position)
	if dist <= 1.45 or adherido_al_boton:
		adherido_al_boton = true
		_angulo_adherido += delta * 4.5
		global_position = boton_objetivo.global_position + Vector3(cos(_angulo_adherido) * 0.85, 0.35, sin(_angulo_adherido) * 0.85)
		return Vector3.ZERO

	var dir = (boton_objetivo.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		look_at(global_position + dir, Vector3.UP)
	return dir * rapidez

func recibir_clic_directo():
	if muerto:
		return
	clics_para_reventar -= 1
	AudioManager.play("click", 1.35)
	recibir_dano(vida_maxima * 0.36, true)
	if clics_para_reventar <= 0 and not muerto:
		morir()

func morir():
	adherido_al_boton = false
	if jugador != null and is_instance_valid(jugador):
		if jugador.has_method("registrar_click_jugador"):
			jugador.registrar_click_jugador(true)
	super.morir()
