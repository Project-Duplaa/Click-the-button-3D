extends Area3D
class_name PalancaBoton

## PalancaBoton - Terminal de Desbloqueo Industrial para el Botón Móvil
## Se activa cuando el Dron es bloqueado por Cadenas. El jugador puede hacerle clic
## con el ratón o acercarse físicamente para accionarla y romper una de las cadenas.

signal palanca_activada(id: int)

const AudioManager = preload("res://audio_manager.gd")

@export var id_palanca: int = 1

var activada: bool = false
var habilitada: bool = false

@onready var luz_indicador: OmniLight3D = $LuzIndicador
@onready var haz_luz: MeshInstance3D = $HazLuz
@onready var manija: MeshInstance3D = $BaseControl/Manija
@onready var colision: CollisionShape3D = $CollisionShape3D

func _ready():
	add_to_group("palancas_boton")
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered)
	desactivar_silencioso()

func armar():
	activada = false
	habilitada = true
	visible = true
	
	if colision != null:
		colision.disabled = false
		
	if luz_indicador != null:
		luz_indicador.light_color = Color(1.0, 0.18, 0.18)
		luz_indicador.light_energy = 3.2
		luz_indicador.visible = true
		
	if haz_luz != null:
		haz_luz.visible = true
		haz_luz.scale = Vector3(1.0, 1.0, 1.0)
		
	if manija != null:
		manija.rotation_degrees.x = -35.0

func desactivar_silencioso():
	activada = false
	habilitada = false
	visible = false
	if colision != null:
		colision.disabled = true
	if haz_luz != null:
		haz_luz.visible = false

func accionar():
	if not habilitada or activada:
		return
		
	activada = true
	AudioManager.play("altar_activado", 1.4, 0.0)
	
	# Animación física de la manija bajando
	if manija != null:
		var tw_manija = create_tween()
		tw_manija.tween_property(manija, "rotation_degrees:x", 35.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Transición cromática de advertencia roja a verde neón de éxito
	if luz_indicador != null:
		luz_indicador.light_color = Color(0.18, 1.0, 0.42)
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_indicador, "light_energy", 5.5, 0.08)
		tw_luz.tween_property(luz_indicador, "light_energy", 2.2, 0.3)
		
	# Haz de luz se desvanece
	if haz_luz != null:
		var tw_haz = create_tween()
		tw_haz.tween_property(haz_luz, "scale:y", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_haz.tween_callback(func(): haz_luz.visible = false)
		
	_spawn_floating_text("¡TERMINAL %d ACTIVADO! ⚡" % id_palanca)
	emit_signal("palanca_activada", id_palanca)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		accionar()

func _on_body_entered(body):
	if body != null and body.is_in_group("jugador"):
		accionar()

func _spawn_floating_text(txt: String):
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 2.2, 0)
		num.iniciar(0, true, false, txt)
