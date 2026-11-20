class_name PortalSpawn
extends Node3D

# ==============================================================================
# Portal de Spawn Telegrafiado - Clicklike 3D
# Muestra una grieta de invocación luminosa para advertir al jugador dónde y
# cuándo va a aparecer un enemigo.
# ==============================================================================

const AudioManager = preload("res://audio_manager.gd")

signal enemigo_spawneado(enemigo: Node3D)

@export var duracion_telegrafo: float = 0.85
@export var es_jefe: bool = false
@export var color_portal: Color = Color(1.0, 0.22, 0.32, 1.0)

var escena_enemigo: PackedScene = null
var vida_extra: float = 0.0

var _tiempo: float = 0.0
var _spawneado: bool = false
var _factor_escala: float = 1.0
var _onda_bullet_clear_emitida: bool = false

@onready var anillo_exterior: MeshInstance3D = $AnilloExterior
@onready var anillo_interior: MeshInstance3D = $AnilloInterior
@onready var vortice: MeshInstance3D = $Vortice
@onready var haz_vertical: MeshInstance3D = $HazVertical
@onready var onda_expansion: MeshInstance3D = $OndaExpansion
@onready var nodos_orbitales: Node3D = $NodosOrbitales
@onready var luz: OmniLight3D = get_node_or_null("LuzPortal")

func preparar_spawn(escena: PackedScene, vida_adicional: float = 0.0, jefe: bool = false):
	escena_enemigo = escena
	vida_extra = vida_adicional
	es_jefe = jefe
	
	if es_jefe:
		duracion_telegrafo = 1.4
		_factor_escala = 1.9
		color_portal = Color(0.88, 0.15, 1.0, 1.0) # Púrpura abisal para Jefes
	elif escena != null:
		var path_str = escena.resource_path.to_lower()
		if "kamikaze" in path_str:
			color_portal = Color(0.2, 1.0, 0.35, 1.0) # Verde radioactivo / tóxico
		elif "bruto" in path_str or "berserker" in path_str:
			color_portal = Color(1.0, 0.5, 0.1, 1.0) # Naranja ígneo / asedio
		elif "espectro" in path_str:
			color_portal = Color(0.25, 0.85, 1.0, 1.0) # Cian espectral
		else:
			color_portal = Color(1.0, 0.22, 0.32, 1.0) # Carmesí advertencia estándar

	# Si preparar_spawn() fue invocado después de add_child(), sincronizar aspecto y onda dorada
	if is_inside_tree():
		_aplicar_color()
		var tw_re := create_tween()
		tw_re.tween_property(self, "scale", Vector3.ONE * _factor_escala, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if es_jefe:
			AudioManager.play("jefe_alerta", 1.0, 1.0)
			_emitir_onda_bullet_clear_jefe()

func _ready():
	add_to_group("portal_spawn")
	_aplicar_color()
	
	# Inicia pequeño y hace pop elástico
	scale = Vector3(0.01, 0.01, 0.01)
	
	# Sonido de apertura y Onda Expansiva Dorada ("Bullet Clear") para Jefes
	if es_jefe:
		AudioManager.play("jefe_alerta", 1.0, 1.0)
		_emitir_onda_bullet_clear_jefe()
	else:
		AudioManager.play("portal_spawn", randf_range(0.95, 1.1), -3.0)
	
	var tween = create_tween()
	var escala_final = Vector3.ONE * _factor_escala
	tween.tween_property(self, "scale", escala_final, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func emitir_onda_bullet_clear(arena: Node, origen: Vector3, radio_max: float = 34.0) -> Dictionary:
	return BunkerVisualKit.emitir_onda_bullet_clear(arena, origen, radio_max)

func _emitir_onda_bullet_clear_jefe() -> void:
	if _onda_bullet_clear_emitida or not is_inside_tree() or get_parent() == null:
		return
	_onda_bullet_clear_emitida = true
	BunkerVisualKit.emitir_onda_bullet_clear(get_parent(), global_position, 34.0)

func _process(delta: float):
	_tiempo += delta
	
	# Rotación continua del vórtice
	if anillo_exterior != null:
		anillo_exterior.rotate_y(delta * 3.6)
	if anillo_interior != null:
		anillo_interior.rotate_y(-delta * 5.2)
	if nodos_orbitales != null:
		nodos_orbitales.rotate_y(delta * 4.2)
		
	# Pulso de la luz
	if luz != null:
		var pulso = sin(_tiempo * 16.0) * 0.5 + 0.5
		luz.light_energy = (2.2 + pulso * 1.6) * _factor_escala
		
	# Onda de expansión en el suelo
	if onda_expansion != null:
		var frac = fmod(_tiempo * 2.4, 1.0)
		var s = lerpf(0.35, 1.35, frac)
		onda_expansion.scale = Vector3(s, 1.0, s)
		if onda_expansion.material_override != null:
			onda_expansion.material_override.albedo_color.a = (1.0 - frac) * 0.75
			
	# Haz vertical pulsante
	if haz_vertical != null:
		var pulso_haz = sin(_tiempo * 10.0) * 0.15 + 0.85
		haz_vertical.scale = Vector3(pulso_haz, 1.0, pulso_haz)
		
	# Disparar aparición del enemigo al terminar el tiempo de telegrafo
	if not _spawneado and _tiempo >= duracion_telegrafo:
		_ejecutar_spawn_enemigo()

func esta_pendiente_jefe() -> bool:
	return es_jefe and not _spawneado and not is_queued_for_deletion()

func cancelar_portal() -> void:
	_spawneado = true
	set_process(false)
	if is_in_group("portal_spawn"):
		remove_from_group("portal_spawn")
	queue_free()

func _ejecutar_spawn_enemigo():
	_spawneado = true
	
	if escena_enemigo != null and is_inside_tree():
		var enemigo = escena_enemigo.instantiate()
		get_parent().add_child(enemigo)
		enemigo.global_position = global_position
		
		var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
		if spawner != null and spawner.has_method("aplicar_escalado_dificultad"):
			spawner.aplicar_escalado_dificultad(enemigo, vida_extra)
		else:
			if "vida_maxima" in enemigo:
				enemigo.vida_maxima += vida_extra
				enemigo.vida = enemigo.vida_maxima
			
		# Animación de emergencia suave para que emerja de la grieta
		enemigo.scale = Vector3(0.05, 0.05, 0.05)
		var t_enemigo = enemigo.create_tween()
		t_enemigo.tween_property(enemigo, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		emit_signal("enemigo_spawneado", enemigo)
	
	# Sonido y destello de energía al salir el enemigo
	AudioManager.play("portal_emergencia", randf_range(0.95, 1.1), -2.0)
	if luz != null:
		luz.light_energy = 5.5 * _factor_escala
		
	# Animación de contracción y desaparición del portal
	var t_cierre = create_tween()
	t_cierre.set_parallel(true)
	t_cierre.tween_property(self, "scale", Vector3(0.01, 2.5 * _factor_escala, 0.01), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if luz != null:
		t_cierre.tween_property(luz, "light_energy", 0.0, 0.25)
	t_cierre.chain().tween_callback(queue_free)

static var _cache_mat_emision: Dictionary = {}
static var _cache_mat_haz: Dictionary = {}


func _aplicar_color():
	if luz != null:
		luz.light_color = color_portal
		
	var clave_col: int = color_portal.to_rgba32()
	var mat_emision := _cache_mat_emision.get(clave_col, null) as StandardMaterial3D
	if mat_emision == null:
		mat_emision = StandardMaterial3D.new()
		mat_emision.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_emision.albedo_color = color_portal
		mat_emision.emission_enabled = true
		mat_emision.emission = color_portal
		mat_emision.emission_energy_multiplier = 2.4
		mat_emision.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cache_mat_emision[clave_col] = mat_emision
	
	if anillo_exterior != null:
		anillo_exterior.material_override = mat_emision
	if anillo_interior != null:
		anillo_interior.material_override = mat_emision
		
	if onda_expansion != null:
		var mat_onda = mat_emision.duplicate()
		mat_onda.albedo_color.a = 0.7
		onda_expansion.material_override = mat_onda
		
	if haz_vertical != null:
		var mat_haz := _cache_mat_haz.get(clave_col, null) as StandardMaterial3D
		if mat_haz == null:
			mat_haz = StandardMaterial3D.new()
			mat_haz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat_haz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat_haz.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat_haz.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat_haz.albedo_color = Color(color_portal.r, color_portal.g, color_portal.b, 0.32)
			_cache_mat_haz[clave_col] = mat_haz
		haz_vertical.material_override = mat_haz
		
	if nodos_orbitales != null:
		for n in nodos_orbitales.get_children():
			if n is MeshInstance3D:
				n.material_override = mat_emision
