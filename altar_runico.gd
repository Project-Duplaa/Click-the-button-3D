extends Area3D

# Altar Rúnico CoD Zombies - Sistema de Objetivos Secundarios
# Desarrollado por: Juan Camilo Angulo Camelo
# Pedestal ancestral interactivo que reacciona al jugador, al botón móvil o a clics.

signal activado(id_altar: int)

const AudioManager = preload("res://audio_manager.gd")

@export var id_altar: int = 1
@export var nombre_altar: String = "Altar de la Resonancia"

var activo: bool = false
var _reloj_flotacion: float = 0.0

@onready var runa_cristal: MeshInstance3D = $Pedestal/RunaCristal
@onready var luz_runa: OmniLight3D = $Pedestal/LuzRuna
@onready var columna_mesh: MeshInstance3D = get_node_or_null("Pedestal/Columna")

func _ready():
	add_to_group("altares_runicos")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	input_event.connect(_on_input_event)

func _physics_process(delta):
	_reloj_flotacion += delta * (4.0 if activo else 1.8)
	if runa_cristal != null:
		# Giro continuo de la runa
		runa_cristal.rotate_y(delta * (3.5 if activo else 1.0))
		runa_cristal.position.y = 1.35 + sin(_reloj_flotacion) * (0.15 if activo else 0.06)

func _on_body_entered(body):
	if activo:
		return
	if body.is_in_group("jugador"):
		activar_altar("Contacto con el custodio")

func _on_area_entered(area):
	if activo:
		return
	if area.is_in_group("boton_movil"):
		activar_altar("Paso del Núcleo Móvil")

func _on_input_event(_cam, event, _pos, _norm, _shape):
	if activo:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		activar_altar("Interacción mística directa")

func activar_altar(motivo: String = ""):
	if activo:
		return
	activo = true
	print("[CoD Zombies Altar] ¡%s (Altar #%d) activado! Motivo: %s" % [nombre_altar, id_altar, motivo])
	
	# Sonido místico
	AudioManager.play("altar_activado", 0.9 + id_altar * 0.15)
	
	# Transición visual de dormido (carmesí apagado) a despierto (oro / cian radiante)
	if luz_runa != null:
		luz_runa.light_color = Color(0.2, 0.9, 1.0)
		var tw = create_tween()
		tw.tween_property(luz_runa, "light_energy", 3.8, 0.4)
		
	if runa_cristal != null and runa_cristal.mesh != null and runa_cristal.mesh.material != null:
		var mat = runa_cristal.mesh.material as StandardMaterial3D
		if mat != null:
			var tw_mat = create_tween()
			tw_mat.tween_property(mat, "albedo_color", Color(0.2, 0.85, 1.0, 1.0), 0.4)
			tw_mat.parallel().tween_property(mat, "emission", Color(0.3, 0.9, 1.0), 0.4)
			tw_mat.parallel().tween_property(mat, "emission_energy_multiplier", 4.0, 0.4)

	# Notificación visual mediante número de daño estilo billboard
	if is_inside_tree() and get_parent() != null:
		var escena_texto = load("res://damage_number_3d.tscn")
		if escena_texto != null:
			var texto = escena_texto.instantiate()
			get_parent().add_child(texto)
			texto.global_position = global_position + Vector3(0, 2.2, 0)
			texto.iniciar(id_altar * 100, true, false)
		
	emit_signal("activado", id_altar)
