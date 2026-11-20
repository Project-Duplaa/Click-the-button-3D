extends "res://enemigo_base.gd"
class_name HeraldoClic

## Heraldo del Clic — Élite de Fiebre / Overdrive x50
## Monorrueda tragamonedas autómata steampunk que canaliza energía rúnica dorada,
## recibe daño amplificado por clics y suelta un cofre dorado legendario al caer.

const MODELO_GLB: PackedScene = preload("res://assets/modelos/enemigo_heraldo_clic.glb")
const COFRE_DORADO: PackedScene = preload("res://cofre_dorado.tscn")

var _boton_movil: Node3D = null
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()
var _reloj_ataque_heraldo: float = 0.0

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null

func _ready() -> void:
	rapidez = 3.8
	vida_maxima = 280.0
	dano_contacto = 22.0
	rango_ataque = 2.2
	xp_otorgada = 95
	oro_otorgado = 60
	resistencia_knockback = 0.50

	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("heraldos_clic")
	add_to_group("jefes")
	add_to_group("bosses")

	_asegurar_componentes_3d()

	super._ready()

	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null and _boton_movil.has_signal("click_presionado"):
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _asegurar_componentes_3d() -> void:
	# 1. Colisionador físico
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.65
		cap.height = 2.4
		col.shape = cap
		col.position = Vector3(0.0, 1.2, 0.0)
		add_child(col)

	# 2. Modelo 3D oficial de arte conceptual
	if modelo == null:
		modelo = MODELO_GLB.instantiate()
		modelo.name = "Modelo"
		add_child(modelo)

	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
		_anim_ctrl.reproducir_bucle("idle")

func _physics_process(delta: float) -> void:
	if _muerto:
		return

	_anim_ctrl.actualizar(delta)

	var vel_ia: Vector3 = _calcular_velocidad_ia(delta)
	procesar_fisica_base(delta, vel_ia)

	# Gestión de animaciones según estado de locomoción y combate
	if not _anim_ctrl.esta_bloqueado():
		var vel_plana := Vector2(velocity.x, velocity.z).length()
		if vel_plana > 2.5:
			_anim_ctrl.reproducir_bucle("run", 0.12, 1.2)
		elif vel_plana > 0.4:
			_anim_ctrl.reproducir_bucle("walk", 0.15, 1.0)
		else:
			_anim_ctrl.reproducir_bucle("idle", 0.18, 1.0)

	# Ataque a corta distancia con pinza hidráulica y estallido jackpot
	if dano_contacto > 0.0 and jugador != null and is_instance_valid(jugador):
		_reloj_ataque_heraldo = maxf(_reloj_ataque_heraldo - delta, 0.0)
		var dist := global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque and _reloj_ataque_heraldo <= 0.0:
			_reloj_ataque_heraldo = 1.6
			_ejecutar_ataque_pinza()

func _ejecutar_ataque_pinza() -> void:
	_anim_ctrl.reproducir_accion("attack-melee-right", 3, 0.08, 1.25, 0.85)
	if jugador != null and is_instance_valid(jugador) and jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano_contacto)

func _calcular_velocidad_ia(_delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return Vector3.ZERO

	var dif: Vector3 = jugador.global_position - global_position
	dif.y = 0.0
	var dist := dif.length()
	if dist > 0.1:
		var dir_norm := dif / dist
		# Orientar modelo hacia el objetivo manteniendo rotación suave
		var look_target := global_position + dir_norm
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
		return dir_norm * rapidez
	return Vector3.ZERO

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if _muerto:
		return

	if not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.reproducir_accion("hit", 1, 0.05, 1.4, 0.35)

	super.recibir_dano(cantidad, fuente, es_critico)

func _on_boton_click(_total: int) -> void:
	if _muerto or not is_instance_valid(self):
		return
	# Daño de sobrecarga especial por clic en el botón móvil
	recibir_dano(42.0, "sobrecarga_clic", true)

func morir() -> void:
	if _muerto:
		return

	var arbol := get_tree()
	var pos_muerte := global_position
	_muerto = true

	# Desconectar señal de botón móvil
	if _boton_movil != null and is_instance_valid(_boton_movil) and _boton_movil.has_signal("click_presionado"):
		if _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.disconnect(_on_boton_click)

	super.morir()

	# Recompensa visual en arena
	if arbol != null:
		var pool = arbol.get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(pos_muerte + Vector3(0, 2.6, 0), "🎰 ¡JACKPOT! ¡HERALDO ABATIDO! +60🪙 +95 XP", Color(1.0, 0.75, 0.2), 1.5)

		# Dropear cofre legendario ("suelta cofres" del diseño conceptual)
		if COFRE_DORADO != null:
			var cofre = COFRE_DORADO.instantiate()
			cofre.global_position = pos_muerte
			var escena_raiz = arbol.current_scene
			if escena_raiz != null:
				escena_raiz.add_child(cofre)

	if jugador != null and is_instance_valid(jugador):
		for i in range(5):
			if jugador.has_method("registrar_click_jugador"):
				jugador.registrar_click_jugador(true)
