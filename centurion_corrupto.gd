extends CharacterBody3D

# Jefe 1: Centurión Corrupto (Minuto 3:00)
# Comandante de la guardia caída. 850 HP.
# Incluye Cristales de Escudo Clicables al 50% HP, interrupción de Sentencia de Muerte con Botón Móvil y Knockback real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var rapidez: float = 3.65
@export var vida_maxima: float = 1750.0
@export var dano_golpe: float = 45.0
@export var dano_sentencia: float = 95.0
@export var rango_ataque: float = 3.0
@export var tiempo_telegraph: float = 0.60

var vida: float = 1750.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_ataque: float = 0.0
var _reloj_grito: float = 5.5
var _reloj_sentencia: float = 11.0
var _esta_telegrafando: bool = false
var _canalizando_sentencia: bool = false
var _grito_activo: bool = false
var _aturdido: bool = false
var _en_enrage: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

# Cristales de Escudo Clicables al 50% HP
var _cristales_invocados: bool = false
var _cristales_activos: Array = []
var _angulo_cristales: float = 0.0

# Controlador de 3 Fases y Stagger + Peligros Fase 2 (Pilares Rúnicos)
var _fase_ctrl: JefeFaseController = null
var _pilares_runicos_f2: Array = []
var _reloj_pulso_pilar_f2: float = 0.0
var _ultimo_seg_stagger_hud: int = -1

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()
var _decal_ataque: ThreatDecal3D = null
var _nav_estado: Dictionary = {}

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo if has_node("TelegraphSuelo") else null
@onready var luz_aura: OmniLight3D = $LuzCenturion

func _ready():
	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("jefes")
	add_to_group("bosses")
	ArenaColiseo.configurar_cuerpo_terreno(self, false, true)
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")

	if telegraph_mesh != null:
		telegraph_mesh.visible = false
		telegraph_mesh.queue_free()
		telegraph_mesh = null
	_decal_ataque = BunkerVisualKit.create_threat_decal(self, "DecalAtaqueCenturion")

	_fase_ctrl = JefeFaseController.new()
	_fase_ctrl.name = "JefeFaseController"
	_fase_ctrl.configurar(self, 6, 5.2, 13.0, 17.0)
	add_child(_fase_ctrl)
	_fase_ctrl.fase_cambiada.connect(_on_fase_cambiada)
	_fase_ctrl.stagger_iniciado.connect(_on_stagger_iniciado)
	_fase_ctrl.stagger_progreso.connect(_on_stagger_progreso)
	_fase_ctrl.stagger_completado.connect(_on_stagger_completado)
	_fase_ctrl.stagger_fallado.connect(_on_stagger_fallado)
	_fase_ctrl.conmocion_terminada.connect(_on_conmocion_terminada)

	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.25)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("⚔️ CENTURIÓN CORRUPTO", vida_maxima, vida)

func _exit_tree() -> void:
	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.cancelar()
	_limpiar_peligros_fase2(true)
	if _fase_ctrl != null and is_instance_valid(_fase_ctrl):
		_fase_ctrl.limpiar(hud, true)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.45
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 12.0:
		_knockback_velocity = _knockback_velocity.normalized() * 12.0

func _conectar_boton_movil():
	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null:
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _i_frame_timer > 0.0:
		_i_frame_timer = maxf(_i_frame_timer - delta, 0.0)

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	_actualizar_orbita_cristales(delta)
	_actualizar_pilares_fase2(delta)
	if _fase_ctrl != null:
		_fase_ctrl.actualizar(delta, hud, not muerto)
		if _fase_ctrl.esta_conmocionado():
			var seg_c := maxi(1, int(ceil(_fase_ctrl.tiempo_conmocion_restante())))
			if seg_c != _ultimo_seg_stagger_hud:
				_ultimo_seg_stagger_hud = seg_c
				_actualizar_hud()

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()

	var bloqueado_por_fase := _fase_ctrl != null and (_fase_ctrl.esta_en_transicion() or _fase_ctrl.esta_canalizando() or _fase_ctrl.esta_conmocionado())
	if _aturdido or _esta_telegrafando or _canalizando_sentencia or bloqueado_por_fase:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta) + _knockback_velocity.z
		var es_stun_anim := _aturdido or (_fase_ctrl != null and _fase_ctrl.esta_conmocionado())
		_anim_ctrl.reproducir_bucle("stunned" if es_stun_anim else "telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	_reloj_grito = maxf(_reloj_grito - delta, 0.0)
	_reloj_sentencia = maxf(_reloj_sentencia - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()

		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)

		if _reloj_sentencia <= 0.001 and dist <= 10.0:
			_iniciar_sentencia_de_muerte()
			return

		if _reloj_grito <= 0.001 and dist <= 12.0:
			_ejecutar_grito_guerra()

		var mult_enrage := 1.22 if _en_enrage else 1.0
		var vel_actual = rapidez * (1.35 if _grito_activo else 1.0) * mult_enrage

		if dist <= rango_ataque and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
			velocity.x = dir_mov.x * vel_actual + _knockback_velocity.x
			velocity.z = dir_mov.z * vel_actual + _knockback_velocity.z
			if dir_mov.length_squared() > 0.01:
				look_at(global_position + dir_mov, Vector3.UP)
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), _grito_activo, is_on_floor(), vel_actual)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func _invocar_cristales_escudo():
	_cristales_invocados = true
	_crear_texto_flotante("💎 ¡CRISTALES DE ESCUDO! ¡CLIC EN ELLOS O EN EL NÚCLEO!", true)
	for i in range(3):
		var area = Area3D.new()
		area.name = "CristalEscudo_%d" % i
		area.add_to_group("cristal_jefe")
		area.collision_layer = 1 | 8
		area.input_ray_pickable = true
		var col = CollisionShape3D.new()
		var sph = SphereShape3D.new()
		sph.radius = 0.65
		col.shape = sph
		area.add_child(col)

		var mesh_i = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.6, 0.9, 0.6)
		mesh_i.mesh = prism
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.45, 0.08)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.35, 0.05)
		mat.emission_energy_multiplier = 1.4
		mat.metallic = 0.5
		mat.roughness = 0.25
		mesh_i.material_override = mat
		area.add_child(mesh_i)

		area.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_destruir_cristal(area)
		)
		add_child(area)
		_cristales_activos.append(area)
	_actualizar_hud()

func _actualizar_orbita_cristales(delta: float):
	if _cristales_activos.is_empty():
		return
	_angulo_cristales += delta * 2.4
	var limpios: Array = []
	for i in range(_cristales_activos.size()):
		var c = _cristales_activos[i]
		if is_instance_valid(c):
			var ang = _angulo_cristales + (TAU / float(max(_cristales_activos.size(), 1))) * i
			c.position = Vector3(cos(ang) * 2.2, 1.8, sin(ang) * 2.2)
			c.rotate_y(delta * 3.0)
			limpios.append(c)
	_cristales_activos = limpios

func _destruir_cristal(cristal: Node):
	if is_instance_valid(cristal):
		cristal.queue_free()
	_cristales_activos.erase(cristal)
	AudioManager.play("corte_giratorio", 1.5)
	_crear_texto_flotante("💎 ¡CRISTAL ROTO! (%d restantes)" % _cristales_activos.size(), true)
	if _cristales_activos.is_empty():
		_aturdido = true
		_crear_texto_flotante("💥 ¡ESCUDO QUEBRADO! (Aturdido 3s - Daño x2)", true)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(self):
				_aturdido = false
				_actualizar_hud()
		)
	_actualizar_hud()

func _iniciar_sentencia_de_muerte():
	_canalizando_sentencia = true
	_reloj_sentencia = randf_range(12.0, 15.0)

	AudioManager.play("rugido_jefe", 1.3)
	_crear_texto_flotante("⚡ ¡PULSA EL NÚCLEO PARA DESARMARLO!", true)

	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN [⚡ ¡PULSA EL NÚCLEO PARA INTERRUMPIR!]", "CANALIZANDO")

	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.configurar_circulo(rango_ataque * 1.4, Color(0.92, 0.08, 0.14, 1.0), Color(1.0, 0.72, 0.18, 1.0), Color(1.0, 0.90, 0.42, 1.0))
		_decal_ataque.iniciar_cuenta_regresiva(2.2, false)

	get_tree().create_timer(2.2).timeout.connect(_ejecutar_sentencia_de_muerte)

func _ejecutar_sentencia_de_muerte():
	if muerto or not _canalizando_sentencia:
		if _decal_ataque != null and is_instance_valid(_decal_ataque):
			_decal_ataque.cancelar()
		return

	var en_area := false
	if is_instance_valid(jugador) and jugador is Node3D:
		if _decal_ataque != null and is_instance_valid(_decal_ataque):
			en_area = _decal_ataque.punto_en_area(jugador.global_position)
		else:
			en_area = global_position.distance_to(jugador.global_position) <= (rango_ataque * 1.4)

	_canalizando_sentencia = false
	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.cancelar()
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.25)

	AudioManager.play("danio_jugador", 0.6, 2.5)
	_sacudir_camara(0.45)

	if en_area and is_instance_valid(jugador) and jugador is Node3D:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_sentencia)
		elif jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_sentencia))

	_actualizar_hud()

func _on_boton_click(_total_clicks: int):
	if vida <= 0.0 or muerto:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)

	# Prioridad absoluta: Canalización de Stagger en Enrage (<25% HP)
	if _fase_ctrl != null and _fase_ctrl.registrar_clic_nucleo(hud):
		_sacudir_camara(0.22)
		return

	if not _cristales_activos.is_empty():
		_destruir_cristal(_cristales_activos[0])
		return

	if _canalizando_sentencia:
		_canalizando_sentencia = false
		_aturdido = true
		if _decal_ataque != null and is_instance_valid(_decal_ataque):
			_decal_ataque.cancelar()

		AudioManager.play("puzzle_completo", 1.2)
		_sacudir_camara(0.3)
		_crear_texto_flotante("💥 ¡DESARMADO POR EL NÚCLEO! (Aturdido)", true)

		aplicar_knockback(-global_transform.basis.z * 10.0)
		if hud != null and hud.has_method("actualizar_barra_jefe"):
			hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN [💥 ¡DESARMADO Y ATURDIDO!]")

		get_tree().create_timer(2.5).timeout.connect(func():
			if is_instance_valid(self):
				_aturdido = false
				_actualizar_hud()
		)
		return

	if is_instance_valid(jugador):
		var dir_empuje = (global_position - jugador.global_position).normalized()
		aplicar_knockback(dir_empuje * 10.0)
		_crear_texto_flotante("⚡ REPELIDO", false)
		AudioManager.play("altar_activado", 1.1)

func _ejecutar_grito_guerra():
	_reloj_grito = 9.0
	_grito_activo = true
	AudioManager.play("alerta_oleada", 1.4, 2.0)
	_sacudir_camara(0.2)

	_crear_texto_flotante("📢 ¡POR EL COLISEO!", true)

	if _fase_ctrl != null and _fase_ctrl.fase_actual != JefeFaseController.FaseJefe.FASE_1:
		_invocar_falange_runica()

	if luz_aura != null:
		luz_aura.light_energy = 4.0

	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(self):
			_grito_activo = false
			if luz_aura != null:
				luz_aura.light_energy = 3.2 if _en_enrage else 2.0
	)

func _iniciar_ataque_telegrafiado():
	_esta_telegrafando = true

	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.configurar_arco(rango_ataque + 0.8, 150.0, Color(0.95, 0.36, 0.10, 1.0), Color(1.0, 0.60, 0.14, 1.0), Color(1.0, 0.88, 0.38, 1.0))
		_decal_ataque.iniciar_cuenta_regresiva(tiempo_telegraph, false)

	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_golpe_telegrafiado)

func _ejecutar_golpe_telegrafiado():
	if muerto or not _esta_telegrafando:
		_esta_telegrafando = false
		if _decal_ataque != null and is_instance_valid(_decal_ataque):
			_decal_ataque.cancelar()
		return
	var en_arco := false
	if is_instance_valid(jugador) and jugador is Node3D:
		if _decal_ataque != null and is_instance_valid(_decal_ataque):
			en_arco = _decal_ataque.punto_en_area(jugador.global_position)
		else:
			en_arco = global_position.distance_to(jugador.global_position) <= (rango_ataque + 0.8)
	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.cancelar()
	_esta_telegrafando = false
	_reloj_ataque = 1.3
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.0)

	AudioManager.play("corte_giratorio", 1.1)

	if en_arco and is_instance_valid(jugador) and jugador is Node3D:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_golpe)
		elif jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
		_sacudir_camara(0.3)

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if muerto:
		return
	if _i_frame_timer > 0.0 and str(fuente) != "ejecucion":
		return
	_i_frame_timer = 0.14
	var fuente_str := "normal"
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
	else:
		fuente_str = str(fuente)
	var mult_stagger := _fase_ctrl.obtener_mult_dano() if _fase_ctrl != null else 1.0
	var mult = maxf(2.0 if _aturdido else (0.20 if not _cristales_activos.is_empty() else 1.0), mult_stagger)
	var dano_final = cantidad * mult * (1.0 + MetaprogresoManager.obtener_bono_bestiario("centurion"))

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 8% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.08
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if _fase_ctrl != null and vida > 0.0:
		_fase_ctrl.evaluar_vida(vida, vida_maxima, not muerto, hud)

	if not _cristales_invocados and vida <= vida_maxima * 0.5:
		_i_frame_timer = 0.6
		_invocar_cristales_escudo()

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
	var es_vuln_visual := _aturdido or (_fase_ctrl != null and _fase_ctrl.esta_conmocionado())
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(dano_final)), es_critico or es_vuln_visual, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(dano_final, es_critico or es_vuln_visual, false)

	_actualizar_hud()
	if vida <= 0.0:
		morir()

func morir():
	if muerto:
		return
	muerto = true
	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.cancelar()
	_limpiar_peligros_fase2(false)
	if _fase_ctrl != null and is_instance_valid(_fase_ctrl):
		_fase_ctrl.limpiar(hud, false)
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("enemigo_muerte", 0.8, 2.5)
	_sacudir_camara(0.35)

	var pj = get_tree().get_first_node_in_group("jugador") if is_inside_tree() else null
	MetaprogresoManager.procesar_baja_completa(self, pj, "centurion", true)
	if pj != null:
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 25)
			pj.recoger_drop(1, 30)

	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		var txt = "⚔️ CENTURIÓN CORRUPTO"
		var tag = "NORMAL"
		if _fase_ctrl != null and _fase_ctrl.esta_canalizando():
			txt = "⚔️ CENTURIÓN [⚡ ATAQUE MORTAL — ¡PULSA EL NÚCLEO!]"
			tag = "CANALIZANDO"
		elif _fase_ctrl != null and _fase_ctrl.esta_conmocionado():
			var segs := maxi(1, int(ceil(_fase_ctrl.tiempo_conmocion_restante())))
			txt = "⚔️ CENTURIÓN [💥 CONMOCIONADO x2 · %ds - ¡ATACA!]" % segs
			tag = "VULNERABLE"
		elif not _cristales_activos.is_empty():
			txt = "⚔️ CENTURIÓN [💎 CRISTALES: %d/3]" % _cristales_activos.size()
			tag = "ESCUDO"
		elif _aturdido:
			txt = "⚔️ CENTURIÓN [💥 VULNERABLE x2]"
			tag = "VULNERABLE"
		elif _en_enrage:
			txt = "⚔️ CENTURIÓN [🔥 ENRAGE — FURIA DE LA LEGION]"
			tag = "ENRAGE"
		elif _fase_ctrl != null and _fase_ctrl.fase_actual == JefeFaseController.FaseJefe.FASE_2:
			txt = "⚔️ CENTURIÓN [⚔️ FASE II — FALANGE RÚNICA]"
			tag = "NORMAL"
		hud.actualizar_barra_jefe(vida, txt, tag)

func _on_fase_cambiada(nueva_fase: int) -> void:
	if muerto:
		return
	if nueva_fase == int(JefeFaseController.FaseJefe.FASE_2):
		AudioManager.play("jefe_alerta", 1.15, 3.0)
		_sacudir_camara(0.45)
		_crear_texto_flotante("⚡ FASE II — ¡FALANGE RÚNICA!", true)
		if luz_aura != null:
			luz_aura.light_color = Color(1.0, 0.42, 0.14)
			luz_aura.light_energy = 3.0
		if get_parent() != null and is_inside_tree():
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 1.4, 11.0, Color(1.0, 0.55, 0.14, 1.0), 0.55)
		_invocar_falange_runica()
		_actualizar_hud()
	elif nueva_fase == int(JefeFaseController.FaseJefe.ENRAGE):
		_en_enrage = true
		AudioManager.play("rugido_jefe", 1.15, 3.5)
		_sacudir_camara(0.55)
		_crear_texto_flotante("🔥 ¡ENRAGE — SENTENCIA IMPERIAL!", true)
		if luz_aura != null:
			luz_aura.light_color = Color(1.0, 0.14, 0.18)
			luz_aura.light_energy = 4.2
		if get_parent() != null and is_inside_tree():
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 1.4, 13.0, Color(1.0, 0.16, 0.22, 1.0), 0.55)
		_actualizar_hud()

func _on_stagger_iniciado(clics_req: int, _duracion: float) -> void:
	_canalizando_sentencia = false
	_esta_telegrafando = false
	if _decal_ataque != null and is_instance_valid(_decal_ataque):
		_decal_ataque.cancelar()
	_crear_texto_flotante("⚡ ¡ATAQUE MORTAL! %d CLICS AL NÚCLEO" % clics_req, true)
	_actualizar_hud()

func _on_stagger_progreso(clics_restantes: int, clics_totales: int, _tiempo: float) -> void:
	var completados := clics_totales - clics_restantes
	_crear_texto_flotante("⚡ CONMOCIÓN %d/%d" % [completados, clics_totales], true)

func _on_stagger_completado(duracion_conm: float, _mult_dano: float, pct_ruptura: float) -> void:
	if muerto:
		return
	_aturdido = true
	_canalizando_sentencia = false
	_esta_telegrafando = false
	_ultimo_seg_stagger_hud = maxi(1, int(ceil(duracion_conm)))
	_sacudir_camara(0.50)

	var dano_ruptura := vida_maxima * pct_ruptura
	vida = maxf(vida - dano_ruptura, 0.0)
	_crear_texto_flotante("💥 ¡CONMOCIONADO! -%d HP (DAÑO x2)" % int(round(dano_ruptura)), true)
	if is_inside_tree():
		var pool = get_tree().get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_dano"):
			pool.mostrar_dano(global_position + Vector3(0.0, 3.0, 0.0), int(round(dano_ruptura)), true, "stagger_ruptura")
	_actualizar_hud()
	if vida <= 0.0:
		morir()

func _on_conmocion_terminada() -> void:
	if muerto:
		return
	_aturdido = false
	_ultimo_seg_stagger_hud = -1
	_actualizar_hud()

func _on_stagger_fallado() -> void:
	if muerto:
		return
	_sacudir_camara(0.65)
	_crear_texto_flotante("💀 ¡SENTENCIA IMPERIAL DESATADA!", true)
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.35)
	if is_instance_valid(jugador) and jugador is Node3D:
		var dist := global_position.distance_to(jugador.global_position)
		var radio_m := _fase_ctrl.radio_ataque_mortal if _fase_ctrl != null else 13.0
		if dist <= radio_m:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(135.0)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(135)
	_actualizar_hud()

func _invocar_falange_runica() -> void:
	if muerto or get_parent() == null or not is_inside_tree():
		return
	# Mantener cota máxima de pilares activos para rendimiento estable
	if _pilares_runicos_f2.size() >= 8:
		_limpiar_peligros_fase2(false)

	var dirs: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var padre := get_parent()
	for idx in range(dirs.size()):
		var pos_pilar: Vector3 = global_position + dirs[idx] * 5.8
		pos_pilar.y = 0.0
		var pilar := Node3D.new()
		pilar.name = "PilarRunicoF2_%d" % idx
		pilar.set_meta("activo", false)
		pilar.set_meta("vida_restante", 5.85)
		pilar.set_meta("tiempo_telegraph", 0.85)
		pilar.set_meta("radio", 2.1)

		var anillo := BunkerVisualKit.create_hazard_ground_ring(2.1, Color(1.0, 0.52, 0.14, 1.0), Color(1.0, 0.16, 0.18, 1.0), 0.72, 0.96, 0.55, 0.15)
		anillo.position = Vector3(0.0, 0.05, 0.0)
		pilar.add_child(anillo)

		var lanza := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.36
		cyl.height = 3.2
		cyl.radial_segments = 8
		lanza.mesh = cyl
		lanza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat_l := StandardMaterial3D.new()
		mat_l.albedo_color = Color(0.95, 0.34, 0.10)
		mat_l.emission_enabled = true
		mat_l.emission = Color(1.0, 0.38, 0.12)
		mat_l.emission_energy_multiplier = 1.6
		mat_l.metallic = 0.65
		mat_l.roughness = 0.25
		lanza.material_override = mat_l
		lanza.position = Vector3(0.0, -1.6, 0.0)
		lanza.visible = false
		lanza.name = "LanzaMesh"
		pilar.add_child(lanza)

		padre.add_child(pilar)
		pilar.global_position = pos_pilar
		_pilares_runicos_f2.append(pilar)

func _actualizar_pilares_fase2(delta: float) -> void:
	if _pilares_runicos_f2.is_empty():
		return
	_reloj_pulso_pilar_f2 = maxf(_reloj_pulso_pilar_f2 - delta, 0.0)
	var vivos: Array = []
	for p in _pilares_runicos_f2:
		if not is_instance_valid(p):
			continue
		var t_tel := float(p.get_meta("tiempo_telegraph", 0.0))
		var t_vida := float(p.get_meta("vida_restante", 0.0)) - delta
		p.set_meta("vida_restante", t_vida)
		if t_vida <= 0.0:
			p.queue_free()
			continue

		if t_tel > 0.0:
			t_tel = maxf(t_tel - delta, 0.0)
			p.set_meta("tiempo_telegraph", t_tel)
			if t_tel <= 0.0:
				p.set_meta("activo", true)
				var lanza := p.get_node_or_null("LanzaMesh") as Node3D
				if lanza != null:
					lanza.visible = true
					lanza.position.y = 1.6
				if is_instance_valid(jugador) and jugador is Node3D:
					var dp := Vector2(jugador.global_position.x - p.global_position.x, jugador.global_position.z - p.global_position.z).length()
					if dp <= float(p.get_meta("radio", 2.1)):
						_infligir_dano_jugador_f2(34.0)
		elif bool(p.get_meta("activo", false)) and _reloj_pulso_pilar_f2 <= 0.0:
			if is_instance_valid(jugador) and jugador is Node3D:
				var dp2 := Vector2(jugador.global_position.x - p.global_position.x, jugador.global_position.z - p.global_position.z).length()
				if dp2 <= float(p.get_meta("radio", 2.1)) * 0.85:
					_reloj_pulso_pilar_f2 = 0.75
					_infligir_dano_jugador_f2(20.0)
		vivos.append(p)
	_pilares_runicos_f2 = vivos

func _infligir_dano_jugador_f2(cantidad: float) -> void:
	if not is_instance_valid(jugador):
		return
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(cantidad)
	elif jugador.has_node("Salud"):
		jugador.get_node("Salud").recibir_golpe(int(cantidad))

func _limpiar_peligros_fase2(diferir_remocion: bool = false) -> void:
	for p in _pilares_runicos_f2:
		if is_instance_valid(p):
			p.visible = false
			if not diferir_remocion and p.get_parent() != null:
				p.get_parent().remove_child(p)
			p.queue_free()
	_pilares_runicos_f2.clear()

func _crear_rayo_hacia_jefe(desde_pos: Vector3):
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.28
	esfera.height = 0.56
	orbe.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	orbe.material_override = mat
	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 1.8, 0)
		var tw = create_tween()
		tw.tween_property(orbe, "global_position", dest, 0.16)
		tw.tween_callback(func():
			if is_instance_valid(orbe):
				orbe.queue_free()
		)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.2, 0), texto, Color(1.0, 0.85, 0.2), 1.2)
		return
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		get_parent().add_child(n)
		n.global_position = global_position + Vector3(0, 3.2, 0)
		n.iniciar(0.0, es_crit, false, texto)

func _sacudir_camara(intensidad: float = 0.25):
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)
