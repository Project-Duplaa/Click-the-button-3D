extends Node

# Gestor de Anomalías del Núcleo Móvil - Spawner de Objetivos de Clic
# Hace aparecer anomalías rúnicas temporales en la arena 60x60 para generar tensión y oportunidad de clics.

const AudioManager = preload("res://audio_manager.gd")
const AnomaliaEscena = preload("res://anomalia_click.tscn")

@export var intervalo_min: float = 12.0
@export var intervalo_max: float = 16.0
@export var max_anomalias_simultaneas: int = 2

var _reloj_spawn: float = 8.0

func _ready():
	_reloj_spawn = 6.0 # La primera aparece a los 6 segundos de iniciada la partida

func _process(delta):
	_reloj_spawn -= delta
	if _reloj_spawn <= 0.0:
		_reloj_spawn = randf_range(intervalo_min, intervalo_max)
		_intentar_spawn_anomalia()

func _intentar_spawn_anomalia():
	var activas = get_tree().get_nodes_in_group("anomalias_click").size()
	if activas >= max_anomalias_simultaneas:
		return
		
	var anomalia = AnomaliaEscena.instantiate()
	var rx = randf_range(-22.0, 22.0)
	var rz = randf_range(-22.0, 22.0)
	var pos = Vector3(rx, 0.0, rz)
	
	get_parent().add_child(anomalia)
	anomalia.global_position = pos
	
	# Audio sutil de aviso de aparición
	AudioManager.play("altar_activado", 1.5, -4.0)
