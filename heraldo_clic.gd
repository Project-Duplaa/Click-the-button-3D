extends "res://enemigo_base.gd"
class_name HeraldoClic

## Heraldo del Clic — Élite de Fiebre / Overdrive x50
## Monorrueda tragamonedas autómata steampunk que canaliza energía rúnica dorada,
## recibe daño amplificado por clics y suelta un cofre dorado legendario al caer.

const MODELO_GLB: PackedScene = preload("res://assets/modelos/enemigo_heraldo_clic.glb")
const COFRE_DORADO: PackedScene = preload("res://cofre_dorado.tscn")

var _boton_movil: Node3D = null
var _reloj_ataque_heraldo: float = 0.0

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null

func _ready() -> void:
	tipo_enemigo_id = "heraldo_clic"
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
		cap.radius = 0.75
		cap.height = 2.9
		col.shape = cap
		col.position = Vector3(0.0, 1.45, 0.0)
		add_child(col)

	# 2. Modelo 3D oficial de arte conceptual
	if modelo == null:
		modelo = MODELO_GLB.instantiate()
		modelo.name = "Modelo"
		modelo.scale = Vector3.ONE * 1.18
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

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return Vector3.ZERO

	var dir_norm: Vector3 = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
	if dir_norm.length_squared() > 0.0025:
		var look_target := global_position + dir_norm
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
		return dir_norm * rapidez
	return Vector3.ZERO

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if _muerto or muerto:
		return

	if not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.reproducir_accion("hit", 1, 0.05, 1.4, 0.35)

	super.recibir_dano(cantidad, fuente, es_critico)
	if vida <= 0.0 and not _muerto:
		morir()

func _on_boton_click(_total: int) -> void:
	if _muerto or muerto or not is_instance_valid(self):
		return
	# Daño de sobrecarga especial por clic en el botón móvil
	recibir_dano(42.0, "sobrecarga_clic", true)

func morir() -> void:
	if _muerto or muerto:
		return
	_muerto = true
	muerto = true

	set_physics_process(false)
	set_process(false)

	# 1. Desconectar colisión física inmediatamente
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null:
		col.set_deferred("disabled", true)

	# 2. Desvincular de grupos para no interferir con auras ni HUD
	remove_from_group("enemigos")
	remove_from_group("enemies")
	remove_from_group("heraldos_clic")
	remove_from_group("jefes")
	remove_from_group("bosses")

	var arbol := get_tree()
	var pos_muerte := global_position

	# 3. Desconectar señal de botón móvil
	if _boton_movil != null and is_instance_valid(_boton_movil) and _boton_movil.has_signal("click_presionado"):
		if _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.disconnect(_on_boton_click)

	# 4. Registrar baja en telemetría y metaprogresión
	var pj = jugador if (jugador != null and is_instance_valid(jugador)) else (arbol.get_first_node_in_group("jugador") if arbol != null else null)
	MetaprogresoManager.procesar_baja_completa(self, pj, "heraldo_clic", true)

	# 5. Efectos de sonido y partículas de jackpot/explosión
	AudioManager.play("enemigo_muerte", 0.75, 2.0)
	AudioManager.play("victoria", 1.4)
	if is_inside_tree() and get_parent() != null:
		VfxCombate.spawn_explosion_nova(get_parent(), pos_muerte + Vector3(0.0, 1.3, 0.0), 3.5, Color(1.0, 0.85, 0.2), Color.WHITE, 0.35, true, true)

	# 6. Recompensa visual en arena (texto 3D flotante)
	if arbol != null:
		var pool = arbol.get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(pos_muerte + Vector3(0, 2.6, 0), "🎰 ¡JACKPOT! ¡HERALDO ABATIDO! +60🪙 +95 XP", Color(1.0, 0.75, 0.2), 1.5)

		# Dropear cofre dorado legendario en la escena contenedora
		if COFRE_DORADO != null:
			var cofre = COFRE_DORADO.instantiate()
			cofre.global_position = pos_muerte
			var parent_node = get_parent() if get_parent() != null else arbol.current_scene
			if parent_node != null:
				parent_node.add_child(cofre)

	# 7. Otorgar clics bonus al jugador
	if pj != null and is_instance_valid(pj):
		for i in range(5):
			if pj.has_method("registrar_click_jugador"):
				pj.registrar_click_jugador(true)

	# 8. Animación de colapso y liberación forzada garantizada
	if modelo != null and is_instance_valid(modelo):
		var tw_m := create_tween()
		tw_m.tween_property(modelo, "scale", Vector3.ZERO, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		visible = false
		queue_free()
	)

	# 9. Fallback absoluto e incondicional para liberar el nodo del árbol
	if arbol != null:
		arbol.create_timer(0.25).timeout.connect(func():
			if is_instance_valid(self):
				visible = false
				queue_free()
		)
