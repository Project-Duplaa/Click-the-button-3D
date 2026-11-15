extends "res://enemigo_base.gd"
class_name GolemTesoro

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
	_construir_geometria_procedural()
	super._ready()

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var box_s = BoxShape3D.new()
		box_s.size = Vector3(1.2, 1.4, 1.2)
		col.shape = box_s
		col.position = Vector3(0, 0.7, 0)
		add_child(col)

	# Chasis hexagonal blindado principal (MeshInstance3D raíz visual)
	var cuerpo := BunkerVisualKit.make_cylinder(
		self,
		"MeshInstance3D",
		0.56,
		0.64,
		0.48,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.58, 0.0),
		6
	)

	# Anillo hazard dorado/acero alrededor del chasis
	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_VAULT_GOLD,
		BunkerVisualKit.COL_CARBON_STEEL,
		8.0
	)
	BunkerVisualKit.make_cylinder(
		cuerpo,
		"CollarinHazardDron",
		0.60,
		0.62,
		0.14,
		mat_hazard,
		Vector3(0.0, 0.02, 0.0),
		6
	)

	# Bahía superior de lingotes / núcleo energético dorado
	_mat_nucleo_dorado = BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_VAULT_GOLD,
		2.4,
		BunkerVisualKit.COL_VAULT_GOLD,
		0.88,
		0.18
	)
	BunkerVisualKit.make_cylinder(
		cuerpo,
		"NucleoCargaDorada",
		0.38,
		0.44,
		0.34,
		_mat_nucleo_dorado,
		Vector3(0.0, 0.34, 0.0),
		6
	)
	for i in range(3):
		var z_off: float = -0.18 + float(i) * 0.18
		BunkerVisualKit.make_box(
			cuerpo,
			"LingoteDorado_%d" % i,
			Vector3(0.46, 0.12, 0.12),
			_mat_nucleo_dorado,
			Vector3(0.0, 0.54, z_off)
		)

	# 4 brazos diagonales de titanio con micro-turbinas inferiores cian
	var mat_turbina := BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		2.5
	)
	for i in range(4):
		var ang: float = (TAU * 0.25) * float(i) + PI * 0.25
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		BunkerVisualKit.make_box(
			cuerpo,
			"BrazoDron_%d" % i,
			Vector3(0.14, 0.10, 0.42),
			BunkerVisualKit.get_titanium_mat(),
			dir * 0.56 + Vector3(0.0, -0.05, 0.0),
			Vector3(0.0, -rad_to_deg(ang) + 90.0, 0.0)
		)
		BunkerVisualKit.make_cylinder(
			cuerpo,
			"CarcasaTurbina_%d" % i,
			0.16,
			0.18,
			0.20,
			BunkerVisualKit.get_armor_grey_mat(),
			dir * 0.72 + Vector3(0.0, -0.10, 0.0),
			10
		)
		BunkerVisualKit.make_cylinder(
			cuerpo,
			"ToberaCian_%d" % i,
			0.12,
			0.14,
			0.08,
			mat_turbina,
			dir * 0.72 + Vector3(0.0, -0.22, 0.0),
			10
		)

	# Baliza superior giratoria
	_baliza_superior = BunkerVisualKit.make_torus(
		cuerpo,
		"BalizaSuperior",
		0.22,
		0.28,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_VAULT_GOLD, 2.2),
		Vector3(0.0, 0.68, 0.0)
	)

	var area_clic = Area3D.new()
	area_clic.name = "AreaPinataDorada"
	area_clic.input_ray_pickable = true
	var col_a = CollisionShape3D.new()
	var sph_a = SphereShape3D.new()
	sph_a.radius = 0.98
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
	AudioManager.play("altar_activado", 1.55, -2.0)
	if _mat_nucleo_dorado != null and is_instance_valid(_mat_nucleo_dorado):
		_mat_nucleo_dorado.emission_energy_multiplier = 5.2
		var tw_flash := create_tween()
		tw_flash.tween_property(_mat_nucleo_dorado, "emission_energy_multiplier", 2.4, 0.14)
	if jugador != null and jugador.has_method("recoger_drop"):
		jugador.recoger_drop(0, 4)
	recibir_dano(14.0, true)

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
