extends Area3D

## Anomalía del Núcleo Rúnico — Objetivo de Clic Temporal
## Al capturarse, desata una onda de choque expansiva que aplica daño y knockback
## contundente (aplicar_knockback) para despejar a los enemigos circundantes.

const AudioManager = preload("res://audio_manager.gd")

signal recolectada

@export var tiempo_vida: float = 12.0
@export var oro_recompensa: int = 4
@export var xp_recompensa: int = 6
@export var radio_onda_choque: float = 4.8
@export var dano_onda: float = 16.0

var _tiempo_restante: float = 12.0
var _recolectada: bool = false
var _reloj_flotacion: float = 0.0

@onready var cristal_nucleo: MeshInstance3D = $CristalNucleo
@onready var anillo_tiempo: MeshInstance3D = $AnilloTiempo
@onready var luz_nucleo: OmniLight3D = $LuzNucleo

func _ready():
	add_to_group("anomalias_click")
	add_to_group("objetivos_click")
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)
	_tiempo_restante = tiempo_vida
	
	scale = Vector3(0.1, 0.1, 0.1)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float):
	if _recolectada:
		return
		
	_reloj_flotacion += delta * 3.0
	_tiempo_restante -= delta
	
	if cristal_nucleo != null:
		cristal_nucleo.rotate_y(delta * 2.2)
		cristal_nucleo.position.y = 0.8 + sin(_reloj_flotacion) * 0.12
		
	if anillo_tiempo != null:
		anillo_tiempo.rotate_y(-delta * 1.5)
		var frac = clampf(_tiempo_restante / tiempo_vida, 0.0, 1.0)
		anillo_tiempo.scale = Vector3(frac, 1.0, frac)
		
		if luz_nucleo != null:
			if frac > 0.4:
				luz_nucleo.light_color = Color(1.0, 0.85, 0.2)
			else:
				var parpadeo = 0.5 + sin(_reloj_flotacion * 5.0) * 0.5
				luz_nucleo.light_color = Color(1.0, 0.2, 0.2).lerp(Color(1.0, 0.8, 0.1), parpadeo)
				
	if _tiempo_restante <= 0.0:
		_expirar()

func _on_body_entered(body: Node3D):
	if _recolectada:
		return
	if body.is_in_group("player") or body.is_in_group("jugador"):
		activar_recoleccion()

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if _recolectada:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		activar_recoleccion()

func _unhandled_input(event: InputEvent):
	if _recolectada:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var mouse_pos = event.position
			var ray_from = cam.project_ray_origin(mouse_pos)
			var ray_dir = cam.project_ray_normal(mouse_pos)
			var ray_to = ray_from + ray_dir * 150.0
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var result = space_state.intersect_ray(query)
			if result and result.collider == self:
				get_viewport().set_input_as_handled()
				activar_recoleccion()

func activar_recoleccion():
	if _recolectada:
		return
	_recolectada = true
	
	AudioManager.play("click", 1.25)
	AudioManager.play("puzzle_completo", 1.2, -2.0)
	
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("registrar_clic_boton"):
			pj.registrar_clic_boton(true)
		elif pj.has_method("registrar_click_jugador"):
			pj.registrar_click_jugador()
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_recompensa)
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_recompensa)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_recompensa)
			
		if "evolucion_manager" in pj and pj.evolucion_manager != null:
			pj.evolucion_manager.registrar_click()
			
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
	if hud != null and "clicks_boton" in hud:
		hud.clicks_boton += 1
		
	_detonar_onda_defensiva()
	_spawn_floating_text("¡ANOMALÍA! +4⚡ +%d🪙 +%d✨" % [oro_recompensa, xp_recompensa])
	
	emit_signal("recolectada")
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.6, 1.6, 1.6), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if luz_nucleo != null:
		tw.tween_property(luz_nucleo, "light_energy", 4.0, 0.08)
	tw.chain().tween_property(self, "scale", Vector3.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _expirar():
	_recolectada = true
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)

func _detonar_onda_defensiva():
	var enemigos = get_tree().get_nodes_in_group("enemies")
	if enemigos.is_empty():
		enemigos = get_tree().get_nodes_in_group("enemigos")
		
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio_onda_choque:
				if e.has_method("recibir_dano"):
					e.recibir_dano(int(dano_onda))
				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_empuje * 18.0)
				elif "velocity" in e:
					e.velocity += dir_empuje * 18.0

func _spawn_floating_text(txt: String):
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), txt, Color(0.2, 0.9, 1.0), 1.25)
	else:
		var escena = load("res://damage_number_3d.tscn")
		if escena != null and get_parent() != null:
			var num = escena.instantiate()
			get_parent().add_child(num)
			num.global_position = global_position + Vector3(0, 2.0, 0)
			if num.has_method("iniciar"):
				num.iniciar(0, true, false, txt)
