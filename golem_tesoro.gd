extends "res://enemigo_base.gd"
class_name GolemTesoro

const ESCENA_MODELO_GOLEM = preload("res://assets/modelos/enemigo_golem_tesoro.glb")

## Gólem de Tesoro — Piñata Dorada de Riesgo/Recompensa
## Huye del jugador durante 15 segundos antes de desvanecerse. Cada clic directo con el ratón
## o golpe de arma desprende monedas de oro y XP en tiempo real; abatirlo suelta un premio mayor.

var _tiempo_escape: float = 15.0
var _mat_nucleo_dorado: StandardMaterial3D = null
var _baliza_superior: MeshInstance3D = null

func _ready() -> void:
	rapidez = 4.2
	vida_maxima = 95.0
	dano_contacto = 0.0
	xp_otorgada = 45
	oro_otorgado = 35
	add_to_group("golems_tesoro")
	_asegurar_componentes()
	super._ready()

func _asegurar_componentes():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box_s = BoxShape3D.new()
		box_s.size = Vector3(1.45, 1.85, 1.45)
		col.shape = box_s
		col.position = Vector3(0, 0.92, 0)
		add_child(col)

	var modelo = get_node_or_null("Modelo")
	if modelo == null:
		var escena_mod = ESCENA_MODELO_GOLEM
		if escena_mod:
			modelo = escena_mod.instantiate()
			modelo.name = "Modelo"
			modelo.scale = Vector3.ONE * 1.28
			add_child(modelo)
	if modelo != null:
		_anim_ctrl.vincular_modelo(modelo)
		_anim_ctrl.reproducir_bucle("idle")

	if get_node_or_null("AreaPinataDorada") == null:
		var area_clic = Area3D.new()
		area_clic.name = "AreaPinataDorada"
		area_clic.input_ray_pickable = true
		var col_a = CollisionShape3D.new()
		var sph_a = SphereShape3D.new()
		sph_a.radius = 1.1
		col_a.shape = sph_a
		col_a.position = Vector3(0, 0.8, 0)
		area_clic.add_child(col_a)
		area_clic.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_golpear_pinata_clic()
		)
		add_child(area_clic)

func _process(delta: float) -> void:
	if muerto:
		return
	if _baliza_superior != null:
		_baliza_superior.rotate_y(delta * 3.2)

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_anim_ctrl.actualizar(delta)
	super._physics_process(delta)
	if not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), true, is_on_floor(), rapidez)

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
	var destino_huida := ArenaColiseo.clamping_y_ajustar_a_suelo(global_position + dir_huida * 8.0, 2.6, 0.0)
	var dir_nav := ArenaColiseo.calcular_direccion_persecucion(self, destino_huida, _nav_estado, delta)
	if dir_nav.length_squared() > 0.01:
		dir_huida = dir_nav
	# Evitar quedar atrapado en muros del dodecágono girando tangencialmente por la pasarela
	if ArenaColiseo.apotema_en_pos(global_position.x, global_position.z) > ArenaColiseo.APOTEMA_EXTERIOR - 3.5:
		var inward: Vector3 = ArenaColiseo.obtener_normal_pared_cercana(global_position)
		var tang: Vector3 = Vector3(-inward.z, 0.0, inward.x).normalized()
		if dir_huida.dot(tang) < 0.0:
			tang = -tang
		dir_huida = (tang * 0.72 + inward * 0.28).normalized()
	if dir_huida.length_squared() > 0.0025:
		look_at(global_position + dir_huida, Vector3.UP)
	return dir_huida * rapidez

func _golpear_pinata_clic():
	if muerto:
		return
	AudioManager.play("altar_activado", 1.55, -2.0)
	if _mat_nucleo_dorado != null and is_instance_valid(_mat_nucleo_dorado):
		_mat_nucleo_dorado.emission_energy_multiplier = 0.85
		var tw_flash := create_tween()
		tw_flash.tween_property(_mat_nucleo_dorado, "emission_energy_multiplier", 0.40, 0.14)
	if jugador != null and jugador.has_method("recoger_drop"):
		jugador.recoger_drop(0, 4)
	recibir_dano(14.0, true)

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if not _muerto:
		_anim_ctrl.disparar_golpe()
	super.recibir_dano(cantidad, fuente, es_critico)

func morir() -> void:
	if _muerto:
		return
	var padre = get_parent()
	var pos_muerte = global_position
	var arbol = get_tree()
	super.morir()
	if padre != null:
		BunkerVisualKit.spawn_shockwave_ring(
			padre,
			pos_muerte,
			0.4,
			2.6,
			BunkerVisualKit.COL_VAULT_GOLD,
			0.36
		)
	if arbol != null:
		var pool = arbol.get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(pos_muerte + Vector3(0, 2.2, 0), "🪙 ¡BOTÍN DORADO MASIVO! +35🪙 +45 XP", Color(1.0, 0.88, 0.15), 1.35)
