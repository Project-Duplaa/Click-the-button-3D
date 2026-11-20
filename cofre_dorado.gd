extends Area3D

## Cofre Dorado Ancestral — Recompensa Legendaria de Altares y Jefes
## Aplica bonos permanentes a través de registrar_bono_cofre_dorado para evitar
## que se sobreescriban con recalcular_stats_incrementales().

signal abierto

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var oro_directo: int = 150
@export var xp_directa: int = 120

var _abierto: bool = false
var _nucleo_superior: MeshInstance3D = null
var _aro_escudo: MeshInstance3D = null
@onready var luz_dorada: OmniLight3D = get_node_or_null("LuzDorada")
@onready var mesh_cofre: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready():
	add_to_group("objetivos")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)

	_construir_capsula_vault()

	scale = Vector3(0.01, 0.01, 0.01)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.3, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _construir_capsula_vault() -> void:
	# Material de oro cepillado / titanio nivel Alfa
	var mat_oro_vault := StandardMaterial3D.new()
	mat_oro_vault.albedo_color = BunkerVisualKit.COL_VAULT_GOLD
	mat_oro_vault.metallic = 0.92
	mat_oro_vault.roughness = 0.20
	mat_oro_vault.emission_enabled = true
	mat_oro_vault.emission = BunkerVisualKit.COL_VAULT_GOLD
	mat_oro_vault.emission_energy_multiplier = 0.45

	if mesh_cofre != null:
		var box := BoxMesh.new()
		box.size = Vector3(1.24, 0.76, 1.24)
		mesh_cofre.mesh = box
		mesh_cofre.position = Vector3(0.0, 0.44, 0.0)
		mesh_cofre.material_override = mat_oro_vault

	if luz_dorada != null:
		luz_dorada.light_color = BunkerVisualKit.COL_VAULT_GOLD
		luz_dorada.light_energy = 3.4

	var vault_root := Node3D.new()
	vault_root.name = "VaultVisuals"
	add_child(vault_root)

	# Anillo táctico de suelo
	var ring := BunkerVisualKit.create_hazard_ground_ring(
		1.35,
		BunkerVisualKit.COL_VAULT_GOLD,
		Color(1.0, 0.96, 0.65),
		0.78,
		0.95,
		0.45,
		0.18
	)
	var ring_mat := ring.material_override as ShaderMaterial
	if ring_mat != null:
		ring_mat.set_shader_parameter("progress", 1.0)
		ring_mat.set_shader_parameter("active_state", 1.0)
	vault_root.add_child(ring)

	# Zócalo inferior de acero carbono
	BunkerVisualKit.make_box(
		vault_root,
		"ZocaloCarbonSteel",
		Vector3(1.36, 0.14, 1.36),
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.07, 0.0)
	)

	# 4 esquineros verticales blindados de acero carbono
	for sx in [-0.60, 0.60]:
		for sz in [-0.60, 0.60]:
			BunkerVisualKit.make_box(
				vault_root,
				"EsquineroVault_%s_%s" % [str(sx), str(sz)],
				Vector3(0.16, 0.82, 0.16),
				BunkerVisualKit.get_chassis_mat(),
				Vector3(sx, 0.46, sz)
			)

	# Banda hazard dorada/negra perimetral
	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_VAULT_GOLD,
		BunkerVisualKit.COL_CARBON_STEEL,
		10.0
	)
	BunkerVisualKit.make_box(
		vault_root,
		"BandaHazardVault",
		Vector3(1.30, 0.16, 1.30),
		mat_hazard,
		Vector3(0.0, 0.56, 0.0)
	)

	# Tapa superior de titanio cepillado
	BunkerVisualKit.make_box(
		vault_root,
		"TapaSuperiorTitanio",
		Vector3(1.16, 0.14, 1.16),
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 0.86, 0.0)
	)

	# Escudo circular superior emisivo legible desde -40°
	_aro_escudo = BunkerVisualKit.make_torus(
		vault_root,
		"EscudoCircularSuperior",
		0.34,
		0.46,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_VAULT_GOLD, 2.2),
		Vector3(0.0, 0.96, 0.0)
	)
	_nucleo_superior = BunkerVisualKit.make_cylinder(
		vault_root,
		"NucleoVaultAlfa",
		0.30,
		0.32,
		0.12,
		BunkerVisualKit.create_hologram_material(
			BunkerVisualKit.COL_VAULT_GOLD,
			Color(1.0, 0.98, 0.78),
			2.6
		),
		Vector3(0.0, 0.98, 0.0),
		16
	)

func _process(delta: float):
	rotate_y(delta * 1.2)
	if _aro_escudo != null:
		_aro_escudo.rotate_y(-delta * 2.4)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player") or body.is_in_group("jugador"):
		abrir_cofre()

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pj = get_tree().get_first_node_in_group("player") as Node3D
		if pj == null:
			pj = get_tree().get_first_node_in_group("jugador") as Node3D
		if pj != null and global_position.distance_to(pj.global_position) > 8.0:
			_mostrar_aviso_distancia()
			return
		get_viewport().set_input_as_handled()
		abrir_cofre()

func abrir_cofre():
	if _abierto:
		return
	_abierto = true
	input_ray_pickable = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	remove_from_group("objetivos")
	
	AudioManager.play("puzzle_completo", 1.05)
	BunkerVisualKit.spawn_shockwave_ring(
		get_parent(),
		global_position,
		0.8,
		4.2,
		BunkerVisualKit.COL_VAULT_GOLD,
		0.45
	)
	
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("registrar_bono_cofre_dorado"):
			pj.registrar_bono_cofre_dorado("dano_mult", 0.25)
			pj.registrar_bono_cofre_dorado("velocidad_plana", 1.5)
			pj.registrar_bono_cofre_dorado("vida_plana", 50.0)
		else:
			if "base_dano" in pj: pj.base_dano *= 1.25
			if "base_speed_caminar" in pj: pj.base_speed_caminar += 1.5
			if "base_vida_maxima" in pj:
				pj.base_vida_maxima += 50.0
				pj.vida_maxima += 50.0
				pj.vida = pj.vida_maxima
				
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_directo)
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_directa)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_directa)
			
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null and get_parent() != null:
		for i in range(14):
			var d = drop_escena.instantiate()
			get_parent().add_child(d)
			var ang = randf() * TAU
			var dist = randf_range(1.5, 4.5)
			d.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(global_position + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist), 1.4, 0.35)
			if d.has_method("iniciar"):
				d.iniciar(randi() % 2, randi_range(10, 25))
				
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.5, 0), "👑 ¡RELIQUIA DORADA ANCESTRAL!", Color(1.0, 0.85, 0.2), 1.5)
		
	emit_signal("abierto")
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.02, 0.02, 0.02), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _mostrar_aviso_distancia():
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "¡Demasiado lejos! Acércate a menos de 8m", Color(1.0, 0.35, 0.35), 1.0)
