extends CharacterBody3D
class_name EnemigoBase

# EnemigoBase - Clase base modular para enemigos en Clicklike 3D
# Gestiona física real de retroceso (knockback), aturdimiento, marcas conductivas,
# IA base para subclases interactivas con el cursor, shudder visual al recibir daño y pop de muerte.
# Domain 3: Telemetría de daño, Bono de Bestiario, Sistema Némesis y Chasis Gravitatorio (+25% XP).

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const FUENTES_BOTON: Array[String] = ["onda", "boton", "boton_hilo", "boton_cometa", "sobrecarga_clic"]

static func es_fuente_boton(fuente: String) -> bool:
	return fuente in FUENTES_BOTON

@export var tipo_enemigo_id: String = ""
@export var solo_dano_boton: bool = false
@export var rapidez: float = 2.85
@export var vida_maxima: float = 14.0
@export var dano_ataque: float = 9.0
@export var cadencia_ataque: float = 1.0
@export var rango_ataque: float = 1.1

# Propiedades del Sistema Némesis Vengativo
@export var es_nemesis: bool = false
@export var oro_nemesis_extra: int = 0
@export var clics_nemesis_extra: int = 0

var dano_contacto: float = 10.0
var xp_otorgada: int = 10
var oro_otorgado: int = 5

var vida: float = 14.0
var jugador: Node3D = null
var _reloj_ataque: float = 0.0
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var muerto: bool:
	get: return _muerto
	set(v): _muerto = v

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.0
var _stun_timer: float = 0.0
var _cooldown_feedback_inmune: float = 0.0
var _escudo_fase_mesh: MeshInstance3D = null
var marca_conductiva_timer: float = 0.0
var _nav_estado: Dictionary = {}
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("enemigos")
	ArenaColiseo.configurar_cuerpo_terreno(self, rapidez >= 4.0, true)
	vida = vida_maxima
	_escala_base = scale
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

	_autodetectar_tipo_enemigo()
	if not _anim_ctrl.esta_listo():
		var mod_base := get_node_or_null("Modelo") as Node3D
		if mod_base == null:
			mod_base = get_node_or_null("ModeloVisual") as Node3D
		if mod_base == null:
			mod_base = self
		_anim_ctrl.vincular_modelo(mod_base)
		if _anim_ctrl.esta_listo():
			_anim_ctrl.reproducir_bucle("idle")

func _autodetectar_tipo_enemigo() -> void:
	if tipo_enemigo_id != "":
		return
	var nom := name.to_lower()
	if nom.contains("guardia"): tipo_enemigo_id = "guardia"
	elif nom.contains("espectro"): tipo_enemigo_id = "espectro"
	elif nom.contains("arquero"): tipo_enemigo_id = "arquero"
	elif nom.contains("berserker"): tipo_enemigo_id = "berserker"
	elif nom.contains("kamikaze"): tipo_enemigo_id = "kamikaze"
	elif nom.contains("bruto"): tipo_enemigo_id = "bruto"
	elif nom.contains("centurion"): tipo_enemigo_id = "centurion"
	elif nom.contains("mini_jefe") or nom.contains("gladiador"): tipo_enemigo_id = "mini_jefe"
	elif nom.contains("maestra"): tipo_enemigo_id = "maestra"
	elif nom.contains("coloso"): tipo_enemigo_id = "coloso"
	elif nom.contains("parca"): tipo_enemigo_id = "parca"
	elif nom.contains("espejo"): tipo_enemigo_id = "espejo_sombrio"
	elif nom.contains("centinela_fase"): tipo_enemigo_id = "centinela_fase"
	elif nom.contains("anulador_nucleo"): tipo_enemigo_id = "anulador_nucleo"
	else: tipo_enemigo_id = "guardia"

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_cooldown_feedback_inmune = maxf(_cooldown_feedback_inmune - delta, 0.0)
	_anim_ctrl.actualizar(delta)
	var vel_ia: Vector3 = _calcular_velocidad_ia(delta)
	procesar_fisica_base(delta, vel_ia)

	if not _anim_ctrl.esta_bloqueado():
		if _stun_timer > 0.0 and _anim_ctrl.tiene_clip("stunned"):
			_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
		else:
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)

	if dano_contacto > 0.0 and jugador != null and is_instance_valid(jugador):
		_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
		if _reloj_ataque <= 0.0 and global_position.distance_to(jugador.global_position) <= maxf(rango_ataque, 1.35):
			_reloj_ataque = cadencia_ataque
			_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.07, 1.1)
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_contacto)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return Vector3.ZERO
	var dir_norm: Vector3 = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
	if dir_norm.length_squared() > 0.0025:
		look_at(global_position + dir_norm, Vector3.UP)
		return dir_norm * rapidez
	return Vector3.ZERO

func aplicar_knockback(impulso: Vector3, duracion_stun: float = 0.08) -> void:
	var factor: float = clampf(1.0 - resistencia_knockback, 0.1, 1.0)
	knockback_vel += Vector3(impulso.x, 0.0, impulso.z) * factor
	if knockback_vel.length() > 25.0:
		knockback_vel = knockback_vel.normalized() * 25.0
	_stun_timer = maxf(_stun_timer, duracion_stun * factor)

func aplicar_marca_conductiva(duracion: float = 2.5) -> void:
	marca_conductiva_timer = maxf(marca_conductiva_timer, duracion)

func procesar_fisica_base(delta: float, vel_deseada: Vector3 = Vector3.ZERO) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	_stun_timer = maxf(_stun_timer - delta, 0.0)
	marca_conductiva_timer = maxf(marca_conductiva_timer - delta, 0.0)
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 28.0 * delta)

	var mov: Vector3 = vel_deseada
	if _stun_timer > 0.0:
		mov *= 0.15

	velocity.x = mov.x + knockback_vel.x
	velocity.z = mov.z + knockback_vel.z
	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	var fuente_str: String = str(fuente)
	if solo_dano_boton and not es_fuente_boton(fuente_str):
		_reaccionar_inmunidad_arma()
		return

	var cantidad_final: float = cantidad
	if marca_conductiva_timer > 0.0:
		cantidad_final *= 1.25
	if solo_dano_boton and es_critico:
		cantidad_final *= 1.25

	# Multiplicador de daño por Bono de Bestiario (retorna 0.00..0.20 extra)
	var bono_bestiario: float = float(MetaprogresoManager.obtener_bono_bestiario(tipo_enemigo_id))
	cantidad_final *= (1.0 + bono_bestiario)

	vida -= cantidad_final
	if vida > 0.0 and _anim_ctrl.esta_listo():
		_anim_ctrl.disparar_golpe()

	var tw = create_tween()
	tw.tween_property(self, "scale", _escala_base * 1.15, 0.05)
	tw.tween_property(self, "scale", _escala_base, 0.08)

	var fuente_visual: String = "clic" if solo_dano_boton else fuente_str
	var col_hit := Color(0.22, 0.92, 1.0) if es_fuente_boton(fuente_str) else (Color(1.0, 0.84, 0.16) if es_critico else Color(1.0, 0.45, 0.14))
	VfxCombate.spawn_impacto(get_parent(), global_position + Vector3(0.0, 0.95, 0.0), col_hit, Color.WHITE, 0.95 if es_critico else 0.72, es_critico)
	_notificar_dano(cantidad_final, es_critico, fuente_visual)

	if vida <= 0.0:
		morir()

func _reaccionar_inmunidad_arma() -> void:
	if _escudo_fase_mesh != null and is_instance_valid(_escudo_fase_mesh):
		var esc_tw = create_tween()
		esc_tw.tween_property(_escudo_fase_mesh, "scale", Vector3.ONE * 1.22, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		esc_tw.tween_property(_escudo_fase_mesh, "scale", Vector3.ONE, 0.08).set_trans(Tween.TRANS_CUBIC)
	if _cooldown_feedback_inmune > 0.0:
		return
	_cooldown_feedback_inmune = 0.22
	AudioManager.play("escudo_bloqueo", randf_range(1.35, 1.65), -2.0)
	if is_inside_tree() and get_parent() != null:
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position + Vector3(0.0, 1.35, 0.0), 0.25, 1.55, Color(0.35, 0.92, 1.0), 0.22)
		VfxCombate.spawn_impacto(get_parent(), global_position + Vector3(0.0, 1.25, 0.0), Color(0.35, 0.95, 1.0), Color.WHITE, 0.90, true)

func _notificar_dano(cantidad: float, es_critico: bool, fuente: String) -> void:
	var dmg_pool = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_pool != null and dmg_pool.has_method("mostrar_dano"):
		dmg_pool.mostrar_dano(global_position + Vector3(0, 1.4, 0), int(round(cantidad)), es_critico, fuente)
	else:
		var escena = load("res://damage_number_3d.tscn")
		if escena != null and is_inside_tree() and get_parent() != null:
			var num = escena.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 1.4, randf_range(-0.2, 0.2))
			get_parent().add_child(num)
			num.global_position = pos_num
			if num.has_method("iniciar"):
				num.iniciar(cantidad, es_critico, false)

func morir() -> void:
	if _muerto:
		return
	_muerto = true

	set_physics_process(false)

	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col != null:
		col.set_deferred("disabled", true)

	remove_from_group("enemigos")
	remove_from_group("enemies")

	# 1. Registro de baja en Bestiario y Telemetría
	MetaprogresoManager.registrar_baja_bestiario(tipo_enemigo_id)

	# 2. Notificación al jugador (notificar_baja_enemigo ya invoca registrar_baja)
	if jugador != null and is_instance_valid(jugador):
		if jugador.has_method("notificar_baja_enemigo"):
			jugador.notificar_baja_enemigo(tipo_enemigo_id, global_position)
		elif jugador.has_method("registrar_baja"):
			jugador.registrar_baja()

	# 3. Notificación al FavorEmperadorManager
	var favor_mgr = get_tree().get_first_node_in_group("favor_emperador_manager")
	if favor_mgr != null and favor_mgr.has_method("notificar_baja"):
		var es_elite_o_jefe: bool = is_in_group("jefes") or is_in_group("bosses") or es_nemesis or vida_maxima >= 150.0
		favor_mgr.notificar_baja(tipo_enemigo_id, es_elite_o_jefe)

	# 4. Bono de Chasis Gravitatorio: +25% XP si muere a menos de 6.5m del Botón Móvil
	var mult_xp_chasis: float = 1.0
	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null and is_instance_valid(boton):
		if "chasis_actual" in boton and boton.chasis_actual == "gravitatorio":
			if global_position.distance_to(boton.global_position) <= 6.5:
				mult_xp_chasis = 1.25

	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", _escala_base * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y + 0.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if Engine.has_singleton("FortunaManager") or (get_tree() and get_tree().root and get_tree().root.has_node("FortunaManager")):
		var fm = get_tree().root.get_node("FortunaManager") if (get_tree() and get_tree().root and get_tree().root.has_node("FortunaManager")) else Engine.get_singleton("FortunaManager")
		if fm and fm.has_method("soltar_drops"):
			fm.soltar_drops(get_parent(), global_position, tipo_enemigo_id)

	if jugador != null and is_instance_valid(jugador):
		var xp_calculada = int(ceil(float(xp_otorgada) * mult_xp_chasis))
		if xp_calculada > 10 and jugador.has_method("ganar_xp"):
			jugador.ganar_xp(xp_calculada - 10)
		if oro_otorgado > 5 and jugador.has_method("recoger_drop"):
			jugador.recoger_drop(0, oro_otorgado - 5)

	# 5. Sistema Némesis: Payout de Venganza y Cofre Dorado
	if es_nemesis:
		_ejecutar_recompensa_nemesis()

	tw.chain().tween_callback(queue_free)

	if is_inside_tree() and get_tree() != null:
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)

func _ejecutar_recompensa_nemesis() -> void:
	AudioManager.play("victoria", 1.45)
	if jugador != null and is_instance_valid(jugador):
		if oro_nemesis_extra > 0 and jugador.has_method("recoger_drop"):
			jugador.recoger_drop(0, oro_nemesis_extra)
		if clics_nemesis_extra > 0 and "clics_disponibles" in jugador:
			jugador.clics_disponibles += clics_nemesis_extra
			if "clics_totales" in jugador:
				jugador.clics_totales += clics_nemesis_extra

	var escena_cofre = load("res://cofre_dorado.tscn")
	if escena_cofre != null and get_parent() != null:
		var c = escena_cofre.instantiate()
		get_parent().add_child(c)
		c.global_position = global_position

	MetaprogresoManager.limpiar_nemesis_derrotado()

	var logros = get_tree().get_first_node_in_group("logros_manager")
	if logros != null and logros.has_method("registrar_baja_nemesis"):
		logros.registrar_baja_nemesis()

	var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
	if eventos != null and eventos.has_signal("nemesis_derrotado"):
		eventos.emit_signal("nemesis_derrotado")
