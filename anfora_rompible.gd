extends "res://santuario_base.gd"
class_name AnforaRompible

## AnforaRompible - Ánforas de terracota y braseros rompibles del Coliseo.
## Se rompe con cualquier ataque (espada, flecha, orbe) o clic directo hasta 8 m.
## Pertenece al grupo "rompibles" (nunca "enemigos") para no distraer el auto-apuntado.

var _roto: bool = false
var _es_brasero: bool = false

func _configurar_santuario() -> void:
	_es_brasero = FortunaManager.rng.randf() < 0.38
	nombre_santuario = "Brasero" if _es_brasero else "Ánfora"
	costo_denarios = 0
	radio_interaccion = 8.0
	un_solo_uso = true
	activacion_por_clic = true
	color_luz = BunkerVisualKit.COL_PLASMA_ORANGE if _es_brasero else BunkerVisualKit.COL_CRYO_BLUE
	altura_etiqueta = 2.05

func _ready() -> void:
	super._ready()
	remove_from_group("santuarios")
	add_to_group("rompibles")
	if colision != null and colision.shape is CylinderShape3D:
		var forma := colision.shape as CylinderShape3D
		forma.radius = 0.85
		forma.height = 1.7
		colision.position = Vector3(0.0, 0.85, 0.0)
	if luz != null:
		luz.light_energy = 1.6 if _es_brasero else 1.15
		luz.omni_range = 4.5
	if etiqueta != null:
		BunkerVisualKit.apply_tactical_label_style(
			etiqueta,
			24,
			color_luz.lerp(Color.WHITE, 0.62)
		)

func _construir_visual() -> void:
	if _es_brasero:
		_construir_brasero()
	else:
		_construir_anfora()
	_actualizar_etiqueta("Rompible")

func _construir_anfora() -> void:
	# Célula Volátil de Plasma: tapa inferior y superior de acero carbono
	BunkerVisualKit.make_cylinder(
		visual_root,
		"TapaInferiorAcero",
		0.38,
		0.42,
		0.16,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.08, 0.0),
		12
	)

	# Cuerpo cilíndrico inferior/superior con polímero hazard
	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CARBON_STEEL,
		6.0
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"FaldonHazardInferior",
		0.36,
		0.36,
		0.26,
		mat_hazard,
		Vector3(0.0, 0.28, 0.0),
		12
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"FaldonHazardSuperior",
		0.36,
		0.36,
		0.22,
		mat_hazard,
		Vector3(0.0, 0.90, 0.0),
		12
	)

	# Núcleo interno de plasma cian visible entre los anillos de contención
	BunkerVisualKit.make_cylinder(
		visual_root,
		"NucleoPlasmaCian",
		0.30,
		0.30,
		0.48,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_CYAN_ELECTRIC, 2.4),
		Vector3(0.0, 0.60, 0.0),
		12
	)

	# Anillos de contención de titanio
	for y_anillo in [0.43, 0.77]:
		BunkerVisualKit.make_torus(
			visual_root,
			"AnilloContencion_%s" % str(y_anillo),
			0.29,
			0.39,
			BunkerVisualKit.get_titanium_mat(),
			Vector3(0.0, y_anillo, 0.0)
		)

	# Tapa superior de acero + válvula de presión
	BunkerVisualKit.make_cylinder(
		visual_root,
		"TapaSuperiorAcero",
		0.34,
		0.38,
		0.14,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 1.08, 0.0),
		12
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"ValvulaSuperior",
		0.16,
		0.12,
		0.16,
		BunkerVisualKit.get_chrome_mat(),
		Vector3(0.0, 1.22, 0.0),
		10
	)

func _construir_brasero() -> void:
	# Tambor Térmico Presurizado: acero oscuro / óxido térmico
	var mat_oxido_termico := StandardMaterial3D.new()
	mat_oxido_termico.albedo_color = Color(0.32, 0.14, 0.11)
	mat_oxido_termico.metallic = 0.72
	mat_oxido_termico.roughness = 0.44

	BunkerVisualKit.make_cylinder(
		visual_root,
		"TamborTermicoBase",
		0.46,
		0.48,
		0.96,
		mat_oxido_termico,
		Vector3(0.0, 0.48, 0.0),
		14
	)

	# Cinchos metálicos de titanio
	for y_cincho in [0.18, 0.50, 0.82]:
		BunkerVisualKit.make_cylinder(
			visual_root,
			"CinchoMetalico_%s" % str(y_cincho),
			0.49,
			0.49,
			0.07,
			BunkerVisualKit.get_titanium_mat(),
			Vector3(0.0, y_cincho, 0.0),
			14
		)

	# Collarín superior de acero carbono + rejilla incandescente
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CollarinQuemador",
		0.52,
		0.47,
		0.14,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 1.00, 0.0),
		12
	)
	for i in range(3):
		BunkerVisualKit.make_box(
			visual_root,
			"RejillaTermica_%d" % i,
			Vector3(0.86, 0.04, 0.07),
			BunkerVisualKit.get_chassis_mat(),
			Vector3(0.0, 1.08, 0.0),
			Vector3(0.0, float(i) * 60.0, 0.0)
		)

	# Núcleo de combustión incandescente
	var mat_combustion := BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_PLASMA_ORANGE, 2.8)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"LechoCombustion",
		0.40,
		0.40,
		0.08,
		mat_combustion,
		Vector3(0.0, 1.03, 0.0),
		12
	)
	var nucleo := MeshInstance3D.new()
	nucleo.name = "NucleoCombustion"
	var m_nuc := SphereMesh.new()
	m_nuc.radius = 0.24
	m_nuc.height = 0.44
	nucleo.mesh = m_nuc
	nucleo.material_override = mat_combustion
	nucleo.position = Vector3(0.0, 1.18, 0.0)
	visual_root.add_child(nucleo)

func recibir_dano(_cantidad: float, _es_critico: bool = false) -> void:
	romper()

func _activar(_pj: Node3D) -> bool:
	romper()
	return false

func romper() -> void:
	if _roto or _consumido:
		return
	_roto = true
	remove_from_group("rompibles")
	remove_from_group("santuarios")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("input_ray_pickable", false)
	if colision != null:
		colision.set_deferred("disabled", true)
	AudioManager.play("golpe_impacto", FortunaManager.rng.randf_range(1.15, 1.38))
	call_deferred("_ejecutar_ruptura_diferida")

func _ejecutar_ruptura_diferida() -> void:
	if not is_inside_tree() or get_parent() == null:
		queue_free()
		return

	var pos_spawn := global_position
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), pos_spawn, 0.3, 1.8, color_luz, 0.28)
	FortunaManager.soltar_drops(get_parent(), pos_spawn, "anfora")

	# 2 % base (escalado por suerte) de revelar un Cofre del Gladiador oculto
	if FortunaManager.tirar(0.02):
		var cofre_script := load("res://cofre_gladiador.gd")
		if cofre_script != null:
			var cofre = cofre_script.new()
			get_parent().add_child(cofre)
			cofre.global_position = pos_spawn
			_spawn_texto_3d("🎰 ¡COFRE OCULTO!", Color(1.0, 0.86, 0.25))

	_consumir()
