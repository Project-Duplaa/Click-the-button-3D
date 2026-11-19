extends Node

## Gestor de Anomalías del Núcleo Móvil — Spawner de Objetivos de Clic
## No inicia el conteo del temporizador de spawn hasta que la partida haya comenzado efectivamente.
## Conecta la XP ganada directamente con pj.ganar_xp() para asegurar la subida de nivel.

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const AnomaliaEscena = preload("res://anomalia_click.tscn")

@export var intervalo_min: float = 12.0
@export var intervalo_max: float = 16.0
@export var max_anomalias_simultaneas: int = 2

var _reloj_spawn: float = 8.0

func _ready():
	_reloj_spawn = 6.0

func _process(delta: float):
	var spawner = get_parent().get_node_or_null("OleadasSpawner")
	if spawner == null:
		spawner = get_tree().get_first_node_in_group("spawner")
		
	var en_partida = false
	if spawner != null:
		if "partida_iniciada" in spawner:
			en_partida = spawner.partida_iniciada
		elif "en_partida" in spawner:
			en_partida = spawner.en_partida
			
	if not en_partida:
		return
		
	_reloj_spawn -= delta
	if _reloj_spawn <= 0.0:
		_reloj_spawn = randf_range(intervalo_min, intervalo_max)
		_intentar_spawn_anomalia()

func _intentar_spawn_anomalia():
	var activas = get_tree().get_nodes_in_group("anomalias_click").size()
	if activas >= max_anomalias_simultaneas:
		return
		
	var anomalia = AnomaliaEscena.instantiate()
	var pos: Vector3 = ArenaColiseo.punto_aleatorio(10.0, 48.0, null, 0.5)
	
	get_parent().add_child(anomalia)
	anomalia.global_position = pos
	
	AudioManager.play("altar_activado", 1.5, -4.0)

func _al_completar_anomalia(xp_ganada: int, oro_ganado: int):
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_ganada)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_ganada)
			
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_ganado)
