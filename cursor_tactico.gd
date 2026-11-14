class_name CursorTactico
extends CanvasLayer

## CursorTactico — HUD Táctico Radial en Vivo sobre el Cursor del Ratón
## Renderiza arcos de enfriamiento de Dash, medidor de Fiebre y anillo sincronizado
## con la ventana de Clic Perfecto del BotonMovil.

var _control_dibujo: Control = null
var jugador: CharacterBody3D = null
var boton: Area3D = null

var radio_anillo: float = 24.0
var grosor_arco: float = 2.8
var progreso_pulso_perfecto: float = 0.0
var _anim_rotacion: float = 0.0
var _escala_pulsacion: float = 1.0

func _ready():
	add_to_group("cursor_tactico")
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_control_dibujo = Control.new()
	_control_dibujo.name = "TacticalCanvas"
	_control_dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control_dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control_dibujo.draw.connect(_on_control_draw)
	add_child(_control_dibujo)
	
	call_deferred("_cache_referencias")

func _cache_referencias():
	jugador = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	boton = get_tree().get_first_node_in_group("boton_movil") as Area3D

func _process(delta: float):
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if boton == null or not is_instance_valid(boton):
		boton = get_tree().get_first_node_in_group("boton_movil") as Area3D
		
	_anim_rotacion += delta * 1.5
	_escala_pulsacion = move_toward(_escala_pulsacion, 1.0, delta * 4.0)
	
	if boton != null:
		if "progreso_pulso_perfecto" in boton:
			progreso_pulso_perfecto = float(boton.progreso_pulso_perfecto)
		else:
			progreso_pulso_perfecto = 0.0
			
	if _control_dibujo != null:
		_control_dibujo.queue_redraw()

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_escala_pulsacion = 0.85

func _on_control_draw():
	if _control_dibujo == null:
		return
		
	var mouse_pos = _control_dibujo.get_viewport().get_mouse_position()
	var r = radio_anillo * _escala_pulsacion
	
	_control_dibujo.draw_circle(mouse_pos, 2.0, Color(0.85, 0.95, 1.0, 0.85))
	
	for i in range(4):
		var ang = _anim_rotacion + (i * PI * 0.5)
		var p1 = mouse_pos + Vector2(cos(ang), sin(ang)) * (r + 4.0)
		var p2 = mouse_pos + Vector2(cos(ang), sin(ang)) * (r + 7.5)
		_control_dibujo.draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.35), 1.2, true)
		
	var dash_listo = true
	var frac_dash = 1.0
	if jugador != null:
		if "dash_cooldown_restante" in jugador and "dash_cooldown_max" in jugador:
			var max_cd = maxf(float(jugador.dash_cooldown_max), 0.1)
			var cur_cd = maxf(float(jugador.dash_cooldown_restante), 0.0)
			frac_dash = clampf(1.0 - (cur_cd / max_cd), 0.0, 1.0)
			dash_listo = (cur_cd <= 0.01)
		elif "cooldown_dash_restante" in jugador and "cooldown_dash_max" in jugador:
			var max_cd = maxf(float(jugador.cooldown_dash_max), 0.1)
			var cur_cd = maxf(float(jugador.cooldown_dash_restante), 0.0)
			frac_dash = clampf(1.0 - (cur_cd / max_cd), 0.0, 1.0)
			dash_listo = (cur_cd <= 0.01)
			
	var ang_dash_inicio = deg_to_rad(130.0)
	var ang_dash_total = deg_to_rad(100.0)
	var col_dash = Color(0.2, 0.9, 1.0, 0.9) if dash_listo else Color(0.2, 0.5, 0.7, 0.45)
	
	_control_dibujo.draw_arc(mouse_pos, r, ang_dash_inicio, ang_dash_inicio + ang_dash_total, 16, Color(0.1, 0.2, 0.3, 0.3), grosor_arco, true)
	_control_dibujo.draw_arc(mouse_pos, r, ang_dash_inicio, ang_dash_inicio + (ang_dash_total * frac_dash), 16, col_dash, grosor_arco, true)
	
	var frac_fiebre = 0.0
	if jugador != null and "fiebre_actual" in jugador:
		frac_fiebre = clampf(float(jugador.fiebre_actual) / 100.0, 0.0, 1.0)
		
	var ang_fiebre_inicio = deg_to_rad(-50.0)
	var ang_fiebre_total = deg_to_rad(100.0)
	var col_fiebre = Color(0.2, 0.85, 1.0, 0.75).lerp(Color(1.0, 0.35, 0.12, 1.0), frac_fiebre)
	if frac_fiebre >= 0.99:
		col_fiebre = Color(1.0, 0.90, 0.20, 1.0)
		
	_control_dibujo.draw_arc(mouse_pos, r, ang_fiebre_inicio, ang_fiebre_inicio + ang_fiebre_total, 16, Color(0.2, 0.15, 0.1, 0.3), grosor_arco, true)
	_control_dibujo.draw_arc(mouse_pos, r, ang_fiebre_inicio, ang_fiebre_inicio + (ang_fiebre_total * frac_fiebre), 16, col_fiebre, grosor_arco, true)
	
	if progreso_pulso_perfecto > 0.001:
		var r_pulso = lerpf(r * 1.5, r * 0.45, progreso_pulso_perfecto)
		var en_sweet_spot = (boton != null and "en_ventana_perfecta" in boton and boton.en_ventana_perfecta) or (progreso_pulso_perfecto >= 0.30 and progreso_pulso_perfecto <= 0.85)
		var col_pulso = Color(1.0, 0.85, 0.2, 0.95) if en_sweet_spot else Color(0.4, 0.85, 1.0, 0.45)
		var grosor_pulso = 3.2 if en_sweet_spot else 1.5
		_control_dibujo.draw_arc(mouse_pos, r_pulso, 0.0, TAU, 32, col_pulso, grosor_pulso, true)
