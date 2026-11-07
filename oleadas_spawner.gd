extends Node3D

@export var guardia_escena: PackedScene = preload("res://guardia.tscn")
@export var intervalo_oleada: float = 25.0
@export var radio_spawn: float = 12.0

var _reloj_oleada: float = 25.0
var oleada_actual: int = 1
var hud: Node = null

func _ready():
	hud = get_parent().get_node_or_null("ClickHUD")

func _process(delta):
	_reloj_oleada -= delta
	if _reloj_oleada <= 0.0:
		_reloj_oleada = intervalo_oleada
		oleada_actual += 1
		if hud != null:
			hud.oleada = oleada_actual
		_generar_oleada(oleada_actual)

func _generar_oleada(num_oleada: int):
	var cantidad = min(2 + num_oleada, 6)
	for i in range(cantidad):
		if guardia_escena != null:
			var g = guardia_escena.instantiate()
			var angulo = randf() * TAU
			var pos = Vector3(cos(angulo) * radio_spawn, 0.0, sin(angulo) * radio_spawn)
			g.global_position = pos
			# Ruta aleatoria cercana
			g.ruta = [Vector3.ZERO, Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))]
			g.vida_maxima = 25.0 + (num_oleada * 5.0)
			g.dano_ataque = 8.0 + (num_oleada * 1.5)
			get_parent().add_child(g)
