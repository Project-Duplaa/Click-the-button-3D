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
	color_luz = Color(1.0, 0.55, 0.18) if _es_brasero else Color(0.92, 0.64, 0.35)
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
		luz.light_energy = 1.6 if _es_brasero else 0.9
		luz.omni_range = 4.5
	if etiqueta != null:
		etiqueta.font_size = 24
		etiqueta.modulate = Color(0.95, 0.84, 0.65, 0.88)

func _construir_visual() -> void:
	if _es_brasero:
		_construir_brasero()
	else:
		_construir_anfora()
	_actualizar_etiqueta("Rompible")

func _construir_anfora() -> void:
	var mat_terracota := _crear_material(Color(0.76, 0.42, 0.24), Color(0.35, 0.16, 0.05), 0.15, 0.08, 0.68)
	var mat_borde := _crear_material(Color(0.86, 0.68, 0.32), Color(0.5, 0.35, 0.1), 0.25, 0.45, 0.4)

	var cuerpo := MeshInstance3D.new()
	var m_cuerpo := CylinderMesh.new()
	m_cuerpo.top_radius = 0.32
	m_cuerpo.bottom_radius = 0.24
	m_cuerpo.height = 0.85
	m_cuerpo.radial_segments = 12
	m_cuerpo.material = mat_terracota
	cuerpo.mesh = m_cuerpo
	cuerpo.position = Vector3(0.0, 0.45, 0.0)
	visual_root.add_child(cuerpo)

	var panza := MeshInstance3D.new()
	var m_panza := SphereMesh.new()
	m_panza.radius = 0.42
	m_panza.height = 0.72
	m_panza.material = mat_terracota
	panza.mesh = m_panza
	panza.position = Vector3(0.0, 0.56, 0.0)
	visual_root.add_child(panza)

	var cuello := MeshInstance3D.new()
	var m_cuello := CylinderMesh.new()
	m_cuello.top_radius = 0.28
	m_cuello.bottom_radius = 0.18
	m_cuello.height = 0.28
	m_cuello.radial_segments = 12
	m_cuello.material = mat_borde
	cuello.mesh = m_cuello
	cuello.position = Vector3(0.0, 1.05, 0.0)
	visual_root.add_child(cuello)

func _construir_brasero() -> void:
	var mat_bronce := _crear_material(Color(0.36, 0.28, 0.20), Color(0.25, 0.1, 0.04), 0.2, 0.78, 0.35)
	var mat_fuego := _crear_material(Color(1.0, 0.58, 0.14), Color(1.0, 0.45, 0.08), 1.9, 0.1, 0.2)

	var tripode := MeshInstance3D.new()
	var m_tri := CylinderMesh.new()
	m_tri.top_radius = 0.48
	m_tri.bottom_radius = 0.34
	m_tri.height = 0.78
	m_tri.radial_segments = 8
	m_tri.material = mat_bronce
	tripode.mesh = m_tri
	tripode.position = Vector3(0.0, 0.39, 0.0)
	visual_root.add_child(tripode)

	var cuenco := MeshInstance3D.new()
	var m_cuenco := CylinderMesh.new()
	m_cuenco.top_radius = 0.62
	m_cuenco.bottom_radius = 0.38
	m_cuenco.height = 0.28
	m_cuenco.radial_segments = 10
	m_cuenco.material = mat_bronce
	cuenco.mesh = m_cuenco
	cuenco.position = Vector3(0.0, 0.88, 0.0)
	visual_root.add_child(cuenco)

	var llama := MeshInstance3D.new()
	var m_llama := PrismMesh.new()
	m_llama.size = Vector3(0.46, 0.55, 0.46)
	m_llama.material = mat_fuego
	llama.mesh = m_llama
	llama.position = Vector3(0.0, 1.24, 0.0)
	visual_root.add_child(llama)

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
