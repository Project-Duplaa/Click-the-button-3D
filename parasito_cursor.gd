extends "res://enemigo_base.gd"
class_name ParasitoCursor

const ESCENA_MODELO_PARASITO = preload("res://assets/modelos/enemigo_parasito_cursor.glb")

## Parásito de Cursor — Enemigo Interactivo con el Ratón
## Ignora al jugador y persigue directamente al Botón Móvil para adherirse a él y bloquearlo.
## Requiere 3 clics directos (o ataques del héroe) para reventar en una lluvia de Clics y XP.

var boton_objetivo: Node3D = null
var adherido_al_boton: bool = false
var clics_para_reventar: int = 3
var _angulo_adherido: float = 0.0
var _label_pips: Label3D = null
var _modo_esencial: bool = false

func actualizar_modo_esencial(activo: bool) -> void:
	_modo_esencial = activo
	_actualizar_pips_visuales()

func _ready() -> void:
	rapidez = 4.6
	vida_maxima = 32.0
	dano_contacto = 6.0
	xp_otorgada = 16
	oro_otorgado = 6
	add_to_group("parasitos_cursor")
	add_to_group("indicadores_tacticos")
	_crear_label_pips()
	_construir_geometria_procedural()
	super._ready()
	boton_objetivo = get_tree().get_first_node_in_group("boton_movil")

func _crear_label_pips() -> void:
	_label_pips = Label3D.new()
	_label_pips.name = "LabelPipsParasito"
	_label_pips.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_pips.no_depth_test = true
	_label_pips.font_size = 28
	_label_pips.modulate = Color(1.0, 0.35, 0.55)
	_label_pips.position = Vector3(0.0, 1.25, 0.0)
	_label_pips.visible = false
	add_child(_label_pips)

func _actualizar_pips_visuales() -> void:
	if _label_pips == null:
		return
	if not adherido_al_boton or _muerto:
		_label_pips.visible = false
		return
	_label_pips.visible = true
	var pips_str := ""
	for i in range(3):
		if i < clics_para_reventar:
			pips_str += "● "
		else:
			pips_str += "○ "
	pips_str = pips_str.strip_edges()
	if _modo_esencial:
		_label_pips.text = pips_str
	else:
		_label_pips.text = "🦠 [CLIC AL PARÁSITO: %s]" % pips_str

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sph = SphereShape3D.new()
		sph.radius = 0.5
		col.shape = sph
		col.position = Vector3(0, 0.5, 0)
		add_child(col)

	var area_clic := get_node_or_null("AreaClicDirecto") as Area3D
	if area_clic == null:
		area_clic = Area3D.new()
		area_clic.name = "AreaClicDirecto"
		var col_a = CollisionShape3D.new()
		var sph_a = SphereShape3D.new()
		sph_a.radius = 0.75
		col_a.shape = sph_a
		col_a.position = Vector3(0, 0.65, 0)
		area_clic.add_child(col_a)
		add_child(area_clic)
	area_clic.input_ray_pickable = true
	if not area_clic.input_event.is_connected(_on_area_clic_input):
		area_clic.input_event.connect(_on_area_clic_input)

	var modelo := get_node_or_null("Modelo") as Node3D
	if modelo == null:
		var escena_mod := ESCENA_MODELO_PARASITO
		if escena_mod != null:
			modelo = escena_mod.instantiate() as Node3D
			if modelo != null:
				modelo.name = "Modelo"
				add_child(modelo)
	if modelo != null:
		_anim_ctrl.vincular_modelo(modelo)
		_anim_ctrl.reproducir_bucle("idle")

func _on_area_clic_input(_cam, ev, _pos, _norm, _idx) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		recibir_clic_directo()

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_anim_ctrl.actualizar(delta)
	super._physics_process(delta)
	if not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), adherido_al_boton, is_on_floor(), rapidez)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if boton_objetivo == null or not is_instance_valid(boton_objetivo):
		boton_objetivo = get_tree().get_first_node_in_group("boton_movil")
	if boton_objetivo == null:
		return super._calcular_velocidad_ia(delta)

	var dist = global_position.distance_to(boton_objetivo.global_position)
	if dist <= 1.45 or adherido_al_boton:
		if not adherido_al_boton:
			adherido_al_boton = true
			_actualizar_pips_visuales()
		adherido_al_boton = true
		_angulo_adherido += delta * 4.5
		global_position = boton_objetivo.global_position + Vector3(cos(_angulo_adherido) * 0.85, 0.35, sin(_angulo_adherido) * 0.85)
		return Vector3.ZERO

	var dir := ArenaColiseo.calcular_direccion_persecucion(self, boton_objetivo.global_position, _nav_estado, delta)
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)
	return dir * rapidez

func recibir_clic_directo():
	if muerto:
		return
	clics_para_reventar -= 1
	_actualizar_pips_visuales()
	AudioManager.play("click", 1.35)
	_anim_ctrl.disparar_golpe()
	recibir_dano(vida_maxima * 0.36, true)
	if clics_para_reventar <= 0 and not muerto:
		morir()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if not _muerto:
		_anim_ctrl.disparar_golpe()
	super.recibir_dano(cantidad, fuente, es_critico)

func morir() -> void:
	if _muerto:
		return
	adherido_al_boton = false
	if _label_pips != null:
		_label_pips.visible = false
	super.morir()
	if jugador != null and is_instance_valid(jugador):
		if jugador.has_method("registrar_click_jugador"):
			jugador.registrar_click_jugador(true)
