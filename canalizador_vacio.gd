extends "res://enemigo_base.gd"
class_name CanalizadorVacio

## Canalizador del Vacío — Sacerdote con Orbe Clicable sobre la Cabeza
## Otorga mitigación a enemigos cercanos hasta que el jugador hace clic directo con el ratón
## sobre su Orbe del Vacío flotante, provocando una implosión arcana que los aturde y daña.

var _orbe_area: Area3D = null
var _orbe_mesh: MeshInstance3D = null
var _reloj_pulso: float = 0.0

func _ready() -> void:
	rapidez = 2.1
	vida_maxima = 58.0
	dano_contacto = 10.0
	xp_otorgada = 22
	oro_otorgado = 9
	add_to_group("canalizadores_vacio")
	_asegurar_componentes()
	super._ready()

func _asegurar_componentes() -> void:
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.6
		cap.height = 2.4
		col.shape = cap
		col.position = Vector3(0, 1.2, 0)
		add_child(col)

	var modelo = get_node_or_null("Modelo")
	if modelo == null:
		var escena_mod = load("res://assets/modelos/enemigo_canalizador_vacio.glb") as PackedScene
		if escena_mod:
			modelo = escena_mod.instantiate()
			modelo.name = "Modelo"
			modelo.scale = Vector3.ONE * 1.04
			add_child(modelo)

	if get_node_or_null("OrbeVacioClicable") == null:
		_orbe_area = Area3D.new()
		_orbe_area.name = "OrbeVacioClicable"
		_orbe_area.position = Vector3(0, 1.92, 0)

		var col_o = CollisionShape3D.new()
		var sph_o = SphereShape3D.new()
		sph_o.radius = 0.75
		col_o.shape = sph_o
		_orbe_area.add_child(col_o)
		add_child(_orbe_area)
	else:
		_orbe_area = get_node_or_null("OrbeVacioClicable") as Area3D

	if _orbe_area != null:
		_orbe_area.add_to_group("cristal_jefe")
		_orbe_area.collision_layer = 1 | 8
		_orbe_area.input_ray_pickable = true
		if not _orbe_area.is_connected("input_event", Callable(self, "_on_orbe_input")):
			_orbe_area.input_event.connect(_on_orbe_input)

	if modelo != null:
		_orbe_mesh = modelo.find_child("NucleoSingularidad", true, false) as MeshInstance3D
		_anim_ctrl.vincular_modelo(modelo)
		_anim_ctrl.reproducir_bucle("idle")

func _on_orbe_input(_cam, ev, _pos, _norm, _idx) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_detonar_orbe_vacio()

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_anim_ctrl.actualizar(delta)
	super._physics_process(delta)
	if not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)

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
	if dist > 0.1:
		look_at(global_position + (dif / dist), Vector3.UP)
	if dist < 6.5:
		var destino_h := ArenaColiseo.clamping_y_ajustar_a_suelo(global_position - dif.normalized() * 6.5, 2.2, 0.0)
		var dir_h := ArenaColiseo.calcular_direccion_persecucion(self, destino_h, _nav_estado, delta)
		if dir_h.length_squared() < 0.01:
			dir_h = -dif.normalized()
		return dir_h * (rapidez * 0.75)
	elif dist > 10.5:
		var dir_a := ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
		if dir_a.length_squared() < 0.01:
			dir_a = dif.normalized()
		return dir_a * rapidez
	return Vector3.ZERO

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if not _muerto:
		_anim_ctrl.disparar_golpe()
	super.recibir_dano(cantidad, fuente, es_critico)

var _orbe_detonado: bool = false

func _detonar_orbe_vacio():
	if muerto or _orbe_detonado:
		return
	_orbe_detonado = true
	AudioManager.play("orbe_explosion", 1.35)
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.8, 0), 5.6, Color(0.28, 0.90, 1.0), Color(0.95, 0.80, 1.0), 0.36, true, true)
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
