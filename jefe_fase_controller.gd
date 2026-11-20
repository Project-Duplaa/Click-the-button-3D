class_name JefeFaseController
extends Node

## JefeFaseController — Controlador Reutilizable de 3 Fases y Conmoción (Stagger) para Jefes
## Gestiona transiciones limpias a 60% HP (FASE_2) y 25% HP (ENRAGE), ventana interactiva
## de Stagger vinculada al BotonMovil (6-8 clics) con telegrafiado en suelo y limpieza segura.

enum FaseJefe {
	FASE_1,
	FASE_2,
	ENRAGE
}

enum EstadoStagger {
	INACTIVO,
	CANALIZANDO,
	CONMOCIONADO
}

signal fase_cambiada(nueva_fase: int)
signal stagger_iniciado(clics_req: int, duracion: float)
signal stagger_progreso(clics_restantes: int, clics_totales: int, tiempo_restante: float)
signal stagger_completado(duracion_conmocion: float, mult_dano: float, pct_dano_ruptura: float)
signal stagger_fallado()
signal conmocion_terminada()

const AudioManager = preload("res://audio_manager.gd")

const UMBRAL_FASE_2: float = 0.60
const UMBRAL_ENRAGE: float = 0.25

var fase_actual: FaseJefe = FaseJefe.FASE_1
var estado_stagger: EstadoStagger = EstadoStagger.INACTIVO

var jefe_ref: Node3D = null
var stagger_requerido: int = 7
var duracion_canalizacion: float = 5.5
var duracion_conmocion: float = 5.5
var mult_dano_conmocion: float = 2.0
var pct_dano_ruptura: float = 0.06
var cooldown_stagger_enrage: float = 18.0
var radio_ataque_mortal: float = 14.0

var _clics_restantes: int = 0
var _reloj_canalizacion: float = 0.0
var _reloj_conmocion: float = 0.0
var _reloj_proximo_stagger: float = 0.0
var _reloj_transicion: float = 0.0
var _anillo_canalizacion: MeshInstance3D = null
var _hud_cache: Node = null

func configurar(
	jefe: Node3D,
	p_stagger_req: int = 7,
	p_duracion_canal: float = 5.5,
	p_radio_mortal: float = 14.0,
	p_cooldown_enrage: float = 18.0
) -> void:
	jefe_ref = jefe
	stagger_requerido = clampi(p_stagger_req, 6, 8)
	duracion_canalizacion = clampf(p_duracion_canal, 4.5, 6.5)
	radio_ataque_mortal = maxf(p_radio_mortal, 6.0)
	cooldown_stagger_enrage = maxf(p_cooldown_enrage, 10.0)

func _exit_tree() -> void:
	limpiar(_hud_cache, true)

func esta_en_transicion() -> bool:
	return _reloj_transicion > 0.0

func esta_canalizando() -> bool:
	return estado_stagger == EstadoStagger.CANALIZANDO

func esta_conmocionado() -> bool:
	return estado_stagger == EstadoStagger.CONMOCIONADO

func obtener_mult_dano() -> float:
	return mult_dano_conmocion if estado_stagger == EstadoStagger.CONMOCIONADO else 1.0

func tiempo_conmocion_restante() -> float:
	return _reloj_conmocion if estado_stagger == EstadoStagger.CONMOCIONADO else 0.0

func clics_restantes() -> int:
	return _clics_restantes

func evaluar_vida(vida_actual: float, vida_maxima: float, permitir_stagger: bool = true, hud: Node = null) -> void:
	if hud != null:
		_hud_cache = hud
	if vida_maxima <= 0.0:
		return
	var pct := clampf(vida_actual / vida_maxima, 0.0, 1.0)

	if fase_actual == FaseJefe.FASE_1 and pct <= UMBRAL_FASE_2:
		fase_actual = FaseJefe.FASE_2
		_reloj_transicion = 0.6
		emit_signal("fase_cambiada", int(FaseJefe.FASE_2))

	if fase_actual != FaseJefe.ENRAGE and pct <= UMBRAL_ENRAGE:
		fase_actual = FaseJefe.ENRAGE
		_reloj_transicion = maxf(_reloj_transicion, 0.45)
		emit_signal("fase_cambiada", int(FaseJefe.ENRAGE))
		if permitir_stagger and estado_stagger == EstadoStagger.INACTIVO:
			iniciar_canalizacion_stagger(_hud_cache)

func iniciar_canalizacion_stagger(hud: Node = null) -> void:
	if estado_stagger == EstadoStagger.CANALIZANDO:
		return
	if hud != null:
		_hud_cache = hud
	estado_stagger = EstadoStagger.CANALIZANDO
	_clics_restantes = stagger_requerido
	_reloj_canalizacion = duracion_canalizacion
	_crear_anillo_canalizacion()
	AudioManager.play("jefe_alerta", 1.35, 3.0)
	emit_signal("stagger_iniciado", stagger_requerido, duracion_canalizacion)
	if _hud_cache != null and _hud_cache.has_method("mostrar_barra_stagger"):
		_hud_cache.mostrar_barra_stagger(_clics_restantes, stagger_requerido, _reloj_canalizacion)

func actualizar(delta: float, hud: Node = null, permitir_nuevo_stagger: bool = true) -> void:
	if hud != null:
		_hud_cache = hud

	if _reloj_transicion > 0.0:
		_reloj_transicion = maxf(_reloj_transicion - delta, 0.0)

	if estado_stagger == EstadoStagger.CANALIZANDO:
		_reloj_canalizacion = maxf(_reloj_canalizacion - delta, 0.0)
		_actualizar_anillo_canalizacion()
		if _hud_cache != null and _hud_cache.has_method("mostrar_barra_stagger"):
			_hud_cache.mostrar_barra_stagger(_clics_restantes, stagger_requerido, _reloj_canalizacion)
		if _reloj_canalizacion <= 0.0:
			_fallar_stagger()
		return

	if estado_stagger == EstadoStagger.CONMOCIONADO:
		_reloj_conmocion = maxf(_reloj_conmocion - delta, 0.0)
		if _reloj_conmocion <= 0.0:
			estado_stagger = EstadoStagger.INACTIVO
			_reloj_proximo_stagger = cooldown_stagger_enrage
			emit_signal("conmocion_terminada")
		return

	if fase_actual == FaseJefe.ENRAGE and permitir_nuevo_stagger:
		_reloj_proximo_stagger -= delta
		if _reloj_proximo_stagger <= 0.0:
			iniciar_canalizacion_stagger(_hud_cache)

func registrar_clic_nucleo(hud: Node = null) -> bool:
	if estado_stagger != EstadoStagger.CANALIZANDO:
		return false
	if hud != null:
		_hud_cache = hud

	_clics_restantes = maxi(0, _clics_restantes - 1)
	var completados := stagger_requerido - _clics_restantes
	AudioManager.play("altar_activado", 1.05 + float(completados) * 0.13, 1.5)
	emit_signal("stagger_progreso", _clics_restantes, stagger_requerido, _reloj_canalizacion)

	if _clics_restantes <= 0:
		_completar_stagger()
	elif _hud_cache != null and _hud_cache.has_method("mostrar_barra_stagger"):
		_hud_cache.mostrar_barra_stagger(_clics_restantes, stagger_requerido, _reloj_canalizacion)
	return true

func cancelar_stagger(hud: Node = null, diferir_remocion: bool = false) -> void:
	if hud != null:
		_hud_cache = hud
	estado_stagger = EstadoStagger.INACTIVO
	_clics_restantes = 0
	_reloj_canalizacion = 0.0
	_reloj_conmocion = 0.0
	_limpiar_anillo_canalizacion(diferir_remocion)
	if _hud_cache != null and is_instance_valid(_hud_cache) and _hud_cache.has_method("ocultar_barra_stagger"):
		_hud_cache.ocultar_barra_stagger()

func limpiar(hud: Node = null, diferir_remocion: bool = false) -> void:
	cancelar_stagger(hud, diferir_remocion)

func _completar_stagger() -> void:
	_limpiar_anillo_canalizacion()
	if _hud_cache != null and is_instance_valid(_hud_cache) and _hud_cache.has_method("ocultar_barra_stagger"):
		_hud_cache.ocultar_barra_stagger()

	estado_stagger = EstadoStagger.CONMOCIONADO
	_reloj_conmocion = duracion_conmocion
	AudioManager.play("puzzle_completo", 1.15, 2.5)

	if jefe_ref != null and is_instance_valid(jefe_ref) and jefe_ref.get_parent() != null and jefe_ref.is_inside_tree():
		BunkerVisualKit.spawn_shockwave_ring(
			jefe_ref.get_parent(),
			jefe_ref.global_position,
			1.5,
			radio_ataque_mortal * 0.85,
			Color(1.0, 0.86, 0.24, 1.0),
			0.55
		)

	emit_signal("stagger_completado", duracion_conmocion, mult_dano_conmocion, pct_dano_ruptura)

func _fallar_stagger() -> void:
	_limpiar_anillo_canalizacion()
	if _hud_cache != null and is_instance_valid(_hud_cache) and _hud_cache.has_method("ocultar_barra_stagger"):
		_hud_cache.ocultar_barra_stagger()

	estado_stagger = EstadoStagger.INACTIVO
	_reloj_proximo_stagger = cooldown_stagger_enrage
	AudioManager.play("danio_jugador", 0.55, 3.5)

	if jefe_ref != null and is_instance_valid(jefe_ref) and jefe_ref.get_parent() != null and jefe_ref.is_inside_tree():
		BunkerVisualKit.spawn_shockwave_ring(
			jefe_ref.get_parent(),
			jefe_ref.global_position,
			1.2,
			radio_ataque_mortal,
			Color(1.0, 0.12, 0.18, 1.0),
			0.55
		)

	emit_signal("stagger_fallado")

func _crear_anillo_canalizacion() -> void:
	_limpiar_anillo_canalizacion()
	if jefe_ref == null or not is_instance_valid(jefe_ref):
		return
	_anillo_canalizacion = BunkerVisualKit.create_hazard_ground_ring(
		radio_ataque_mortal,
		Color(1.0, 0.55, 0.12, 1.0),
		Color(1.0, 0.12, 0.18, 1.0),
		0.72,
		0.96,
		0.55,
		0.14
	)
	_anillo_canalizacion.name = "TelegraphCanalizacionStagger"
	jefe_ref.add_child(_anillo_canalizacion)
	_anillo_canalizacion.position = Vector3(0.0, 0.05, 0.0)

func _actualizar_anillo_canalizacion() -> void:
	if _anillo_canalizacion == null or not is_instance_valid(_anillo_canalizacion):
		return
	var progreso := 1.0 - clampf(_reloj_canalizacion / maxf(duracion_canalizacion, 0.1), 0.0, 1.0)
	if _anillo_canalizacion.material_override is ShaderMaterial:
		var sm := _anillo_canalizacion.material_override as ShaderMaterial
		sm.set_shader_parameter("progress", progreso)
		sm.set_shader_parameter("active_state", progreso)

func _limpiar_anillo_canalizacion(diferir_remocion: bool = false) -> void:
	if _anillo_canalizacion != null and is_instance_valid(_anillo_canalizacion):
		_anillo_canalizacion.visible = false
		if not diferir_remocion and _anillo_canalizacion.get_parent() != null:
			_anillo_canalizacion.get_parent().remove_child(_anillo_canalizacion)
		_anillo_canalizacion.queue_free()
	_anillo_canalizacion = null
