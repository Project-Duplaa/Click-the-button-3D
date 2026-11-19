extends Node3D

@export var energia_base: float = 2.45
@export var rango_luz: float = 9.2
@export var color_fuego: Color = Color(1.0, 0.56, 0.14, 1.0)

@onready var luz: OmniLight3D = $OmniLight3D
@onready var fuego_mesh: MeshInstance3D = $FuegoMesh

var _tiempo: float = 0.0
var _offset_fase: float = 0.0

func _ready():
	_offset_fase = randf() * 100.0
	if luz != null:
		luz.light_color = color_fuego
		luz.omni_range = rango_luz
		luz.shadow_enabled = false
		luz.omni_attenuation = 1.05
	_aplicar_acabado_pbr_farola()

func _aplicar_acabado_pbr_farola() -> void:
	var modelo := get_node_or_null("ModeloBeacon")
	if modelo == null:
		return
	var mat_metal := StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.16, 0.19, 0.24, 1.0)
	mat_metal.metallic = 0.36
	mat_metal.roughness = 0.42
	var norm_path := "res://assets/texturas_pbr/metal_brush_normal.png"
	if ResourceLoader.exists(norm_path):
		mat_metal.normal_enabled = true
		mat_metal.normal_texture = load(norm_path)
		mat_metal.normal_scale = 0.42

	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CARBON_STEEL,
		6.0,
		Vector2(2.0, 1.0),
		45.0
	)
	var mat_lamp := StandardMaterial3D.new()
	mat_lamp.albedo_color = Color(1.0, 0.78, 0.35, 1.0)
	mat_lamp.roughness = 0.18
	mat_lamp.emission_enabled = true
	mat_lamp.emission = Color(1.0, 0.56, 0.14, 1.0)
	mat_lamp.emission_energy_multiplier = 4.2

	var stack: Array[Node] = [modelo]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			var mesh: Mesh = mi.mesh
			if mesh != null:
				for s in range(mesh.get_surface_count()):
					var surf_mat: Material = mesh.surface_get_material(s)
					var m_name := surf_mat.resource_name if surf_mat != null else ""
					if "Siren" in m_name or "Lamp" in m_name or "Cone" in mi.name:
						mi.set_surface_override_material(s, mat_lamp)
					elif "Collar" in m_name:
						mi.set_surface_override_material(s, mat_hazard)
					else:
						mi.set_surface_override_material(s, mat_metal)
		for child in curr.get_children():
			stack.append(child)

func _process(delta):
	_tiempo += delta * 4.5
	# Pulsación eléctrica industrial estable de lámpara halógena/sodio
	var fluctuacion = sin(_tiempo + _offset_fase) * 0.045 + cos(_tiempo * 1.9 + _offset_fase) * 0.025
	if luz != null:
		luz.light_energy = maxf(1.2, energia_base + fluctuacion)
	if fuego_mesh != null:
		var s = 1.0 + fluctuacion * 0.12
		fuego_mesh.scale = Vector3(s, s * 1.08, s)
