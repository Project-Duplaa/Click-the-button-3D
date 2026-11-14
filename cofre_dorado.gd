extends Area3D

## Cofre Dorado Ancestral — Recompensa Legendaria de Altares y Jefes
## Aplica bonos permanentes a través de registrar_bono_cofre_dorado para evitar
## que se sobreescriban con recalcular_stats_incrementales().

signal abierto

const AudioManager = preload("res://audio_manager.gd")

@export var oro_directo: int = 150
@export var xp_directa: int = 120

var _abierto: bool = false
@onready var luz_dorada: OmniLight3D = get_node_or_null("LuzDorada")
@onready var mesh_cofre: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready():
	add_to_group("objetivos")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)
	
	scale = Vector3(0.01, 0.01, 0.01)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.3, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float):
	rotate_y(delta * 1.2)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player") or body.is_in_group("jugador"):
		abrir_cofre()

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pj = get_tree().get_first_node_in_group("player") as Node3D
		if pj == null:
			pj = get_tree().get_first_node_in_group("jugador") as Node3D
		if pj != null and global_position.distance_to(pj.global_position) > 8.0:
			_mostrar_aviso_distancia()
			return
		get_viewport().set_input_as_handled()
		abrir_cofre()

func abrir_cofre():
	if _abierto:
		return
	_abierto = true
	remove_from_group("objetivos")
	
	AudioManager.play("puzzle_completo", 1.05)
	
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("registrar_bono_cofre_dorado"):
			pj.registrar_bono_cofre_dorado(0.25, 1.5, 50)
		else:
			if "base_dano" in pj: pj.base_dano *= 1.25
			if "base_speed_caminar" in pj: pj.base_speed_caminar += 1.5
			if "base_vida_maxima" in pj:
				pj.base_vida_maxima += 50.0
				pj.vida_maxima += 50.0
				pj.vida = pj.vida_maxima
				
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_directo)
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_directa)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_directa)
			
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null and get_parent() != null:
		for i in range(14):
			var d = drop_escena.instantiate()
			get_parent().add_child(d)
			var ang = randf() * TAU
			var dist = randf_range(1.5, 4.5)
			d.global_position = global_position + Vector3(cos(ang) * dist, 0.2, sin(ang) * dist)
			if d.has_method("iniciar"):
				d.iniciar(randi() % 2, randi_range(10, 25))
				
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.5, 0), "👑 ¡RELIQUIA DORADA ANCESTRAL!", Color(1.0, 0.85, 0.2), 1.5)
		
	emit_signal("abierto")
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _mostrar_aviso_distancia():
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 1.8, 0), "¡Demasiado lejos! Acércate a menos de 8m", Color(1.0, 0.35, 0.35), 1.0)
