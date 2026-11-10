extends Node

# Gestor de Altares Rúnicos - Easter Egg / Evento CoD Zombies
# Desarrollado por: Juan Camilo Angulo Camelo
# Administra los 3 pedestales de la arena 60x60 e invoca la recompensa ancestral al completarse.

class_name GestorAltares

const AudioManager = preload("res://audio_manager.gd")

signal evento_completado

@export var cofre_dorado_escena: PackedScene = preload("res://cofre_dorado.tscn")
@export var posicion_recompensa: Vector3 = Vector3(0, 0.5, 0)

var total_altares: int = 3
var altares_resueltos: int = 0
var completado: bool = false

func _ready():
	add_to_group("gestor_altares")
	call_deferred("_conectar_altares")

func _conectar_altares():
	var tree = get_tree()
	if tree == null:
		return
	var altares = tree.get_nodes_in_group("altares_runicos")
	if altares.size() > 0:
		total_altares = altares.size()
	for altar in altares:
		if altar.has_signal("activado") and not altar.activado.is_connected(_on_altar_activado):
			altar.activado.connect(_on_altar_activado)
	print("[GestorAltares] Conectados %d altares rúnicos en la arena." % total_altares)

func _on_altar_activado(id_altar: int):
	altares_resueltos += 1
	print("[GestorAltares] Progreso del puzzle: %d de %d altares despertados." % [altares_resueltos, total_altares])
	
	if altares_resueltos >= total_altares and not completado:
		completado = true
		_desencadenar_evento_secreto()

func _desencadenar_evento_secreto():
	print("=====================================================")
	print("¡EVENTO SECRETO COD ZOMBIES DESPERTADO EN EL COLISEO!")
	print("=====================================================")
	
	AudioManager.play("puzzle_completo", 1.0)
	
	# Invocar Cofre Dorado Ancestral
	if cofre_dorado_escena != null and is_inside_tree() and get_parent() != null:
		var cofre = cofre_dorado_escena.instantiate()
		get_parent().add_child(cofre)
		cofre.global_position = posicion_recompensa
		
	emit_signal("evento_completado")
