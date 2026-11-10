extends Area3D

# Cofre Dorado Ancestral - Recompensa de los Altares de CoD Zombies
# Desarrollado por: Juan Camilo Angulo Camelo
# Desbloquea la reliquia legendaria y genera una lluvia de gemas y oro.

signal abierto

const AudioManager = preload("res://audio_manager.gd")

@export var oro_directo: int = 150
@export var xp_directa: int = 120

var _abierto: bool = false
@onready var luz_dorada: OmniLight3D = $LuzDorada
@onready var mesh_cofre: MeshInstance3D = $MeshInstance3D

func _ready():
	add_to_group("objetivos")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)
	
	# Animación de aparición triunfal desde el suelo
	scale = Vector3(0.01, 0.01, 0.01)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.3, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta):
	rotate_y(delta * 1.2)

func _on_body_entered(body):
	if body.is_in_group("jugador"):
		abrir_cofre()

func _on_input_event(_cam, event, _pos, _norm, _shape):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		abrir_cofre()

func abrir_cofre():
	if _abierto:
		return
	_abierto = true
	remove_from_group("objetivos")
	print("[CoD Zombies Event] ¡COFRE DORADO ANCESTRAL ABIERTO!")
	
	AudioManager.play("puzzle_completo", 1.05)
	
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		# 1. Buff Legendario al Héroe
		if "dano" in pj:
			pj.dano *= 1.35
		if "speed_caminar" in pj:
			pj.speed_caminar *= 1.22
			pj.speed_correr *= 1.22
		if "vida" in pj and "vida_maxima" in pj:
			pj.vida_maxima += 50.0
			pj.vida = pj.vida_maxima
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_directo)
			pj.recoger_drop(1, xp_directa)
			
	# 2. Lluvia de Drops en la Arena
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		for i in range(14):
			var d = drop_escena.instantiate()
			get_parent().add_child(d)
			var ang = randf() * TAU
			var dist = randf_range(1.5, 4.5)
			var pos_final = global_position + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
			d.global_position = global_position + Vector3(0, 1.2, 0)
			if d.has_method("iniciar"):
				d.iniciar(randi() % 2, randi_range(10, 25))
				
	# 3. Notificación flotante de Reliquia
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		get_parent().add_child(n)
		n.global_position = global_position + Vector3(0, 2.5, 0)
		n.iniciar(999, true, false)
		
	emit_signal("abierto")
	
	# Desvanecimiento
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)
