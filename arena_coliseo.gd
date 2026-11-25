extends Node3D
class_name ArenaColiseo

## ArenaColiseo — Anfiteatro Dodecagonal (12 caras), Pasarela Perimetral (+0.80 m),
## 4 Rampas Cardinales, 4 Bastiones Diagonales (+0.40 m) y 4 Sectores Temáticos.
## Fuente única de verdad espacial para límites, altura de suelo, física Jolt y steering IA.

const BunkerVisualKit = preload("res://bunker_visual_kit.gd")

const TEX_PISO := preload("res://assets/modelos/floor_concrete_tile_ConcreteTile_Tex.png")
const ESCENA_PILAR_ANTORCHA := preload("res://pilar_antorcha.tscn")
const GLB_WALL_PANEL := preload("res://assets/modelos/wall_bunker_panel.glb")
const GLB_WALL_DOOR := preload("res://assets/modelos/wall_blast_door.glb")
const GLB_WALL_PIPES := preload("res://assets/modelos/wall_light_pipes.glb")

const GLB_SERVER := preload("res://assets/modelos/prop_server_rack.glb")
const GLB_TANK := preload("res://assets/modelos/prop_pressure_tank.glb")
const GLB_BARRIER := preload("res://assets/modelos/prop_hazard_barrier.glb")
const GLB_CABLE := preload("res://assets/modelos/prop_cable_ramp.glb")
const GLB_TRANSFORMER := preload("res://assets/modelos/prop_wall_transformer.glb")
const GLB_GENERATOR := preload("res://assets/modelos/prop_bunker_generator.glb")
const GLB_OIL := preload("res://assets/modelos/prop_oil_puddle.glb")
const GLB_ACID := preload("res://assets/modelos/prop_acid_puddle.glb")
const GLB_STRETCHER := preload("res://assets/modelos/prop_medical_stretcher.glb")
const GLB_BARREL := preload("res://assets/modelos/prop_toxic_barrel.glb")
const GLB_LOCKERS := preload("res://assets/modelos/prop_hazard_lockers.glb")
const GLB_CRATE := preload("res://assets/modelos/prop_military_crate.glb")

# Capas de colisión (bit 0 = Terreno preservado para compatibilidad con Area3D por defecto)
const LAYER_TERRENO: int = 1
const LAYER_MUROS_OBSTACULOS: int = 3 # 1 | 2: bloquea cuerpos (mask 1|2) y proyectiles (mask 2|...)

# Geometría del dodecágono regular (sentido horario desde Norte -Z: k=0 => -Z, k=3 => +X, k=6 => +Z, k=9 => -X)
const NUM_LADOS: int = 12
const COS_15: float = 0.965925826289
const SIN_15: float = 0.258819045103
const TAN_15: float = 0.267949192431

const FACTOR_ESCALA_MAPA: float = 1.75
const APOTEMA_EXTERIOR: float = 52.248711 # 14.0 / tan(15 deg) -> cuerda exacta 28.0m (7 módulos de 4m)
const R_EXTERIOR: float = 54.091845
const APOTEMA_FOSO: float = 39.90
const R_FOSO: float = 41.307519
const ALTURA_PASARELA: float = 0.80
const ALTURA_BASTION: float = 0.40

# 4 Rampas Cardinales directas (caras 0=N, 3=E, 6=S, 9=O)
const INDICES_RAMPAS_CARDINALES: Array[int] = [0, 3, 6, 9]
const RAMPA_CARDINAL_INICIO: float = 31.15
const RAMPA_CARDINAL_FIN: float = 39.90
const RAMPA_CARDINAL_SEMI_ANCHO: float = 3.4

# 4 Bastiones Diagonales escalonados en ángulos de vértices (45°, 135°, 225°, 315°)
const ANGULOS_DIAGONALES_DEG: Array[float] = [45.0, 135.0, 225.0, 315.0]
const BASTION_RAMPA_INF_INICIO: float = 26.60
const BASTION_RAMPA_INF_FIN: float = 31.15
const BASTION_RAMPA_INF_SEMI_ANCHO: float = 2.4
const BASTION_DECK_INICIO: float = 31.15
const BASTION_DECK_FIN: float = 36.75
const BASTION_DECK_SEMI_ANCHO: float = 3.1
const BASTION_RAMPA_SUP_INICIO: float = 36.75
const BASTION_RAMPA_SUP_FIN_PENDIENTE: float = 40.416
const BASTION_RAMPA_SUP_FIN_APRON: float = 41.44
const BASTION_RAMPA_SUP_SEMI_ANCHO: float = 2.3

# Coberturas base de respaldo si aún no se ha ejecutado una run
const CENTROS_RUINAS: Array[Vector2] = [
	Vector2(14.0, -15.75),
	Vector2(-17.5, -12.25),
	Vector2(13.125, 15.75),
	Vector2(-16.625, 14.875),
]

static var centros_obstaculos_run: Array[Vector2] = []
static var _ruinas_pos_run: Array[Vector3] = []
static var _ruinas_rot_run: Array[float] = []

static var _cache_init: bool = false
static var _normales_caras: PackedVector2Array = PackedVector2Array()
static var _tangentes_caras: PackedVector2Array = PackedVector2Array()
static var _vertices_ext: PackedVector2Array = PackedVector2Array()
static var _vertices_foso: PackedVector2Array = PackedVector2Array()
static var _rampas_info: Array[Dictionary] = []
static var _nav_obj_frame: int = -1
static var _nav_obj_pos: Vector3 = Vector3(1e9, 1e9, 1e9)
static var _nav_obj_h: float = 0.0
static var _nav_obj_en_pasarela: bool = false
static var _nav_obj_apotema: float = 0.0

var _mat_piso_foso: StandardMaterial3D = null
var _mat_bastion: StandardMaterial3D = null
var _mat_pasarela: StandardMaterial3D = null
var _mat_rampa: StandardMaterial3D = null
var _mat_hazard_zocalo: ShaderMaterial = null
var _mat_hazard_rampa: ShaderMaterial = null

func _init() -> void:
	_asegurar_cache()

func altura_suelo_en(x: float, z: float) -> float:
	return obtener_altura_suelo(x, z)

func limitar_en_arena(pos: Vector3, margen: float = 1.0) -> Vector3:
	return clamping_en_arena(pos, margen)

func _ready() -> void:
	add_to_group("arena_coliseo")
	_asegurar_cache()
	# Los muros rectangulares heredados (a +-31 m) y sus esquinas/detalles perimetrales antiguos quedan DENTRO
	# del foso dodecagonal (apotema 39.9 m) y bloquean las rampas: se retiran y los reemplaza GeometriaAnfiteatro.
	for legacy_name in ["Muros", "EsquinasIndustriales", "DetallesPerimetro"]:
		var legacy_node := get_node_or_null(legacy_name)
		if legacy_node != null:
			remove_child(legacy_node)
			legacy_node.queue_free()
	var pilares_legacy := get_node_or_null("Pilares")
	if pilares_legacy != null:
		for p_diag in ["Pilar_NO", "Pilar_NE", "Pilar_SO", "Pilar_SE"]:
			var p_node := pilares_legacy.get_node_or_null(p_diag) as Node3D
			if p_node != null:
				# Reubicar los 4 pilares diagonales fuera del corredor de acceso de los Bastiones Diagonales (45°/135°/225°/315°)
				var s_x := signf(p_node.position.x)
				var s_z := signf(p_node.position.z)
				p_node.position = Vector3(s_x * 16.5, 0.0, s_z * 25.5)
	_construir_anfiteatro_completo()
	call_deferred("_reubicar_ruinas_escena")

# ==============================================================================
# CACHÉ ESTÁTICO Y MATEMÁTICA DODECAGONAL (SINGLE SOURCE OF TRUTH)
# ==============================================================================

static func _asegurar_cache() -> void:
	if _cache_init:
		return
	_cache_init = true
	_normales_caras.clear()
	_tangentes_caras.clear()
	_vertices_ext.clear()
	_vertices_foso.clear()
	_rampas_info.clear()

	for k in range(NUM_LADOS):
		var theta := float(k) * (TAU / float(NUM_LADOS))
		var normal := Vector2(sin(theta), -cos(theta))
		var tangente := Vector2(cos(theta), sin(theta))
		_normales_caras.append(normal)
		_tangentes_caras.append(tangente)

		# Vértice entre cara (k-1) y cara k en ángulo theta - 15°
		var phi := theta - (PI / float(NUM_LADOS))
		var dir_v := Vector2(sin(phi), -cos(phi))
		_vertices_ext.append(dir_v * R_EXTERIOR)
		_vertices_foso.append(dir_v * R_FOSO)

	# Registrar las 4 rampas cardinales (acceso directo 0.0 -> 0.80)
	for idx_face in INDICES_RAMPAS_CARDINALES:
		var n := _normales_caras[idx_face]
		var t := _tangentes_caras[idx_face]
		_rampas_info.append({
			"tipo": "cardinal",
			"es_cardinal": true,
			"theta": float(idx_face) * (TAU / float(NUM_LADOS)),
			"normal": n,
			"tangente": t,
			"r_inicio": RAMPA_CARDINAL_INICIO,
			"r_fin": RAMPA_CARDINAL_FIN,
			"semi_ancho": RAMPA_CARDINAL_SEMI_ANCHO,
			"semi_ancho_deck": RAMPA_CARDINAL_SEMI_ANCHO,
			"boca": Vector3(n.x * (RAMPA_CARDINAL_INICIO - 1.4), 0.0, n.y * (RAMPA_CARDINAL_INICIO - 1.4)),
			"cresta": Vector3(n.x * (RAMPA_CARDINAL_FIN + 1.4), ALTURA_PASARELA, n.y * (RAMPA_CARDINAL_FIN + 1.4)),
		})

	# Registrar los 4 ejes diagonales (bastiones escalonados 0.0 -> 0.40 -> 0.80)
	for deg in ANGULOS_DIAGONALES_DEG:
		var phi_d := deg_to_rad(deg)
		var nd := Vector2(sin(phi_d), -cos(phi_d))
		var td := Vector2(cos(phi_d), sin(phi_d))
		_rampas_info.append({
			"tipo": "diagonal",
			"es_cardinal": false,
			"theta": phi_d,
			"normal": nd,
			"tangente": td,
			"r_inicio": BASTION_RAMPA_INF_INICIO,
			"r_fin": BASTION_RAMPA_SUP_FIN_APRON,
			"r_deck_ini": BASTION_DECK_INICIO,
			"r_sup_ini": BASTION_RAMPA_SUP_INICIO,
			"semi_ancho": BASTION_RAMPA_SUP_SEMI_ANCHO,
			"semi_ancho_inf": BASTION_RAMPA_INF_SEMI_ANCHO,
			"semi_ancho_deck": BASTION_DECK_SEMI_ANCHO,
			"boca": Vector3(nd.x * (BASTION_RAMPA_INF_INICIO - 1.3), 0.0, nd.y * (BASTION_RAMPA_INF_INICIO - 1.3)),
			"boca_sup": Vector3(nd.x * (BASTION_RAMPA_SUP_INICIO - 0.5), ALTURA_BASTION, nd.y * (BASTION_RAMPA_SUP_INICIO - 0.5)),
			"cresta_inf": Vector3(nd.x * ((BASTION_DECK_INICIO + BASTION_DECK_FIN) * 0.5), ALTURA_BASTION, nd.y * ((BASTION_DECK_INICIO + BASTION_DECK_FIN) * 0.5)),
			"cresta": Vector3(nd.x * (BASTION_RAMPA_SUP_FIN_APRON + 1.4), ALTURA_PASARELA, nd.y * (BASTION_RAMPA_SUP_FIN_APRON + 1.4)),
		})

static func apotema_en_pos(x: float, z: float) -> float:
	_asegurar_cache()
	# Simetría central del dodecágono regular: |x*n.x + z*n.y| sobre las primeras 6 caras equivale al máximo de las 12
	var max_proj: float = 0.0
	for k in range(6):
		var n := _normales_caras[k]
		var p: float = absf(x * n.x + z * n.y)
		if p > max_proj:
			max_proj = p
	return max_proj

static func esta_dentro(pos: Vector3, margen: float = 0.0) -> bool:
	return apotema_en_pos(pos.x, pos.z) <= maxf(0.5, APOTEMA_EXTERIOR - margen)

static func clamping_en_arena(pos: Vector3, margen: float = 1.0) -> Vector3:
	var limite: float = maxf(0.5, APOTEMA_EXTERIOR - margen)
	var m: float = apotema_en_pos(pos.x, pos.z)
	if m <= limite or m <= 0.0001:
		return pos
	var factor: float = limite / m
	return Vector3(pos.x * factor, pos.y, pos.z * factor)

static func obtener_altura_suelo(x: float, z: float) -> float:
	_asegurar_cache()
	var m := apotema_en_pos(x, z)
	if m >= APOTEMA_FOSO:
		return ALTURA_PASARELA
	# Salida temprana O(1): dentro del foso central (< 26.6 * cos(15°)) no existen rampas ni bastiones
	if m < BASTION_RAMPA_INF_INICIO * COS_15:
		return 0.0

	for r in _rampas_info:
		var n: Vector2 = r["normal"]
		var along: float = x * n.x + z * n.y
		if along < BASTION_RAMPA_INF_INICIO:
			continue
		var t: Vector2 = r["tangente"]
		var perp: float = absf(x * t.x + z * t.y)
		if r["es_cardinal"]:
			if perp <= RAMPA_CARDINAL_SEMI_ANCHO and along >= RAMPA_CARDINAL_INICIO and along <= RAMPA_CARDINAL_FIN:
				var frac: float = clampf((along - RAMPA_CARDINAL_INICIO) / (RAMPA_CARDINAL_FIN - RAMPA_CARDINAL_INICIO), 0.0, 1.0)
				return frac * ALTURA_PASARELA
		else:
			if perp <= BASTION_RAMPA_SUP_SEMI_ANCHO and along >= BASTION_RAMPA_SUP_INICIO and along <= BASTION_RAMPA_SUP_FIN_APRON:
				var frac_sup: float = clampf((along - BASTION_RAMPA_SUP_INICIO) / (BASTION_RAMPA_SUP_FIN_PENDIENTE - BASTION_RAMPA_SUP_INICIO), 0.0, 1.0)
				return ALTURA_BASTION + frac_sup * (ALTURA_PASARELA - ALTURA_BASTION)
			if perp <= BASTION_DECK_SEMI_ANCHO and along >= BASTION_DECK_INICIO and along <= BASTION_DECK_FIN:
				return ALTURA_BASTION
			if perp <= BASTION_RAMPA_INF_SEMI_ANCHO and along >= BASTION_RAMPA_INF_INICIO and along <= BASTION_RAMPA_INF_FIN:
				var frac_inf: float = clampf((along - BASTION_RAMPA_INF_INICIO) / (BASTION_RAMPA_INF_FIN - BASTION_RAMPA_INF_INICIO), 0.0, 1.0)
				return frac_inf * ALTURA_BASTION
	return 0.0

static func ajustar_a_suelo(pos: Vector3, offset_y: float = 0.0) -> Vector3:
	return Vector3(pos.x, obtener_altura_suelo(pos.x, pos.z) + offset_y, pos.z)

static func clamping_y_ajustar_a_suelo(pos: Vector3, margen: float = 1.5, offset_y: float = 0.0) -> Vector3:
	var c := clamping_en_arena(pos, margen)
	return Vector3(c.x, obtener_altura_suelo(c.x, c.z) + offset_y, c.z)

static func esta_en_pasarela(pos: Vector3) -> bool:
	return apotema_en_pos(pos.x, pos.z) >= (APOTEMA_FOSO - 0.15) and pos.y >= 0.45

static func obtener_normal_pared_cercana(pos: Vector3) -> Vector3:
	_asegurar_cache()
	var mejor_k: int = 0
	var max_proj: float = -999999.0
	for k in range(NUM_LADOS):
		var n := _normales_caras[k]
		var p: float = pos.x * n.x + pos.z * n.y
		if p > max_proj:
			max_proj = p
			mejor_k = k
	var n_sel := _normales_caras[mejor_k]
	# Devuelve normal apuntando hacia el interior de la arena
	return Vector3(-n_sel.x, 0.0, -n_sel.y).normalized()

static func obtener_centros_obstaculos() -> Array[Vector2]:
	if not centros_obstaculos_run.is_empty():
		return centros_obstaculos_run
	return CENTROS_RUINAS

static func _obtener_rng_run(ctx: Node = null, rng_ext: RandomNumberGenerator = null) -> RandomNumberGenerator:
	if rng_ext != null:
		return rng_ext
	if ctx != null and is_instance_valid(ctx) and ctx.is_inside_tree():
		var fm: Node = ctx.get_node_or_null("/root/FortunaManager")
		if fm != null and "rng" in fm and fm.rng is RandomNumberGenerator:
			return fm.rng
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback

static func esta_en_pendiente(x: float, z: float, margen: float = 0.6) -> bool:
	_asegurar_cache()
	if apotema_en_pos(x, z) < (BASTION_RAMPA_INF_INICIO - margen) * COS_15:
		return false
	for r in _rampas_info:
		var n: Vector2 = r["normal"]
		var along: float = x * n.x + z * n.y
		if along < BASTION_RAMPA_INF_INICIO - margen:
			continue
		var t: Vector2 = r["tangente"]
		var perp: float = absf(x * t.x + z * t.y)
		if r["es_cardinal"]:
			if perp <= (RAMPA_CARDINAL_SEMI_ANCHO + margen) and along >= (RAMPA_CARDINAL_INICIO - margen) and along <= (RAMPA_CARDINAL_FIN + margen):
				return true
		else:
			if perp <= (BASTION_DECK_SEMI_ANCHO + margen):
				if (along >= (BASTION_RAMPA_INF_INICIO - margen) and along <= (BASTION_RAMPA_INF_FIN + margen)) or (along >= (BASTION_RAMPA_SUP_INICIO - margen) and along <= (BASTION_RAMPA_SUP_FIN_PENDIENTE + margen)):
					return true
	return false

static func punto_libre_de_obstaculos(pos: Vector3, radio_extra: float = 2.8) -> bool:
	var p2 := Vector2(pos.x, pos.z)
	for cr in obtener_centros_obstaculos():
		if p2.distance_to(cr) < radio_extra:
			return false
	return true

static func punto_aleatorio(
	min_r: float = 3.5,
	max_r: float = 49.5,
	rng: RandomNumberGenerator = null,
	offset_y: float = 0.0
) -> Vector3:
	_asegurar_cache()
	var gen: RandomNumberGenerator = _obtener_rng_run(null, rng)
	var r_lo: float = maxf(0.0, min_r)
	var r_hi: float = minf(max_r, APOTEMA_EXTERIOR - 1.8)
	if r_hi < r_lo:
		r_hi = r_lo

	for _intento in range(28):
		var u: float = gen.randf()
		var ang: float = gen.randf() * TAU
		var r: float = sqrt(lerpf(r_lo * r_lo, r_hi * r_hi, u))
		var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
		if _punto_es_seguro_spawn(cand):
			return ajustar_a_suelo(cand, offset_y)

	var ang_fb: float = gen.randf() * TAU
	var fallback := clamping_en_arena(Vector3(cos(ang_fb) * r_lo, 0.0, sin(ang_fb) * r_lo), 2.0)
	return ajustar_a_suelo(fallback, offset_y)

static func punto_aleatorio_en_foso(
	min_r: float = 4.2,
	max_r: float = 36.5,
	rng: RandomNumberGenerator = null,
	offset_y: float = 0.0
) -> Vector3:
	return punto_aleatorio(min_r, minf(max_r, APOTEMA_FOSO - 2.0), rng, offset_y)

static func punto_aleatorio_en_pasarela(
	rng: RandomNumberGenerator = null,
	offset_y: float = 0.0
) -> Vector3:
	return punto_aleatorio(APOTEMA_FOSO + 1.8, APOTEMA_EXTERIOR - 2.2, rng, offset_y)

static func punto_seguro_con_exclusiones(
	min_r: float,
	max_r: float,
	exclusiones: Array[Vector2],
	min_dist_excl: float = 10.0,
	rng: RandomNumberGenerator = null,
	offset_y: float = 0.0,
	permitir_pendiente: bool = false,
	permitir_bastion_deck: bool = true
) -> Vector3:
	_asegurar_cache()
	var gen: RandomNumberGenerator = _obtener_rng_run(null, rng)
	var r_lo: float = maxf(3.6, min_r)
	var r_hi: float = clampf(max_r, r_lo, APOTEMA_EXTERIOR - 2.2)

	for pasada in range(3):
		var factor_d: float = 1.0 if pasada == 0 else (0.65 if pasada == 1 else 0.35)
		var dist_req: float = min_dist_excl * factor_d
		var intentos: int = 72 if pasada == 0 else 36
		for _i in range(intentos):
			var u: float = gen.randf()
			var ang: float = gen.randf() * TAU
			var r: float = sqrt(lerpf(r_lo * r_lo, r_hi * r_hi, u))
			var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
			if not _punto_es_seguro_spawn(cand):
				continue
			if not permitir_pendiente and esta_en_pendiente(cand.x, cand.z, 0.9):
				continue
			if not permitir_bastion_deck:
				var h_c: float = obtener_altura_suelo(cand.x, cand.z)
				if h_c > 0.08 and h_c < 0.72:
					continue
			var m_c: float = apotema_en_pos(cand.x, cand.z)
			if m_c >= (APOTEMA_FOSO - 1.35) and m_c <= (APOTEMA_FOSO + 1.35):
				continue
			var p2 := Vector2(cand.x, cand.z)
			var ok := true
			for ex in exclusiones:
				if p2.distance_to(ex) < dist_req:
					ok = false
					break
			if ok:
				return ajustar_a_suelo(cand, offset_y)

	return punto_aleatorio(r_lo, r_hi, gen, offset_y)

static func _punto_es_seguro_spawn(pos: Vector3) -> bool:
	var p2 := Vector2(pos.x, pos.z)
	if p2.length() < 3.4: # Exclusión del Núcleo Bio-Estático central
		return false
	if not esta_dentro(pos, 1.9):
		return false
	if not punto_libre_de_obstaculos(pos, 2.9):
		return false
	# Evitar que un spawn caiga montado justo en el escalón vertical de 0.80 m (fuera de rampas)
	var m := apotema_en_pos(pos.x, pos.z)
	if m >= (APOTEMA_FOSO - 1.65) and m <= (APOTEMA_FOSO + 1.45):
		var h := obtener_altura_suelo(pos.x, pos.z)
		if h <= 0.05 or h >= 0.78:
			return false
	if esta_en_pendiente(pos.x, pos.z, 1.15):
		return false
	return true

# ==============================================================================
# FÍSICA DE TERRENO Y STEERING LIGERO DE ENEMIGOS (SIN NAVIGATIONAGENT3D)
# ==============================================================================

static func configurar_cuerpo_terreno(body: CharacterBody3D, es_rapido: bool = false, es_enemigo: bool = true) -> void:
	if body == null:
		return
	body.floor_max_angle = deg_to_rad(56.0)
	body.floor_snap_length = 0.65 if es_rapido else 0.55
	body.floor_stop_on_slope = true
	body.floor_constant_speed = true
	body.floor_block_on_wall = false
	body.wall_min_slide_angle = deg_to_rad(5.0)
	body.safe_margin = 0.04
	body.max_slides = 6
	# Mantener bit 0 (Layer 1) activo para que Area3D existentes (DropItem, Cofre, Palanca...) sigan disparando body_entered
	if es_enemigo:
		body.collision_layer = 1 | 8
	else:
		body.collision_layer = 1 | 4
	body.collision_mask = LAYER_MUROS_OBSTACULOS # 1 | 2 (Terreno + MurosYObstaculos)

static func _detectar_corredor_rampa(x: float, z: float, margen_r: float = 1.35, margen_lat: float = 0.30) -> int:
	_asegurar_cache()
	if apotema_en_pos(x, z) < (BASTION_RAMPA_INF_INICIO - margen_r) * COS_15:
		return -1
	for i in range(_rampas_info.size()):
		var r_info: Dictionary = _rampas_info[i]
		var rn: Vector2 = r_info["normal"]
		var along: float = x * rn.x + z * rn.y
		var r_min_i: float = float(r_info["r_inicio"]) - margen_r
		var r_max_i: float = float(r_info["r_fin"]) + margen_r
		if along < r_min_i or along > r_max_i:
			continue
		var rt: Vector2 = r_info["tangente"]
		var perp: float = absf(x * rt.x + z * rt.y)
		var semi_max: float = float(r_info["semi_ancho_deck"]) + margen_lat
		if perp <= semi_max:
			return i
	return -1

static func calcular_direccion_persecucion(
	cuerpo: CharacterBody3D,
	objetivo_pos: Vector3,
	estado_nav: Dictionary,
	delta: float
) -> Vector3:
	_asegurar_cache()
	if cuerpo == null:
		return Vector3.ZERO

	var orig := cuerpo.global_position
	var apot_actual := apotema_en_pos(orig.x, orig.z)
	var h_suelo_actual := obtener_altura_suelo(orig.x, orig.z)

	var frame_actual := Engine.get_physics_frames()
	var h_suelo_obj: float
	var en_pasarela_obj: bool
	var apot_obj: float
	if frame_actual == _nav_obj_frame and _nav_obj_pos.is_equal_approx(objetivo_pos):
		h_suelo_obj = _nav_obj_h
		en_pasarela_obj = _nav_obj_en_pasarela
		apot_obj = _nav_obj_apotema
	else:
		apot_obj = apotema_en_pos(objetivo_pos.x, objetivo_pos.z)
		h_suelo_obj = obtener_altura_suelo(objetivo_pos.x, objetivo_pos.z)
		en_pasarela_obj = apot_obj >= (APOTEMA_FOSO - 0.15) and objetivo_pos.y >= 0.45
		_nav_obj_frame = frame_actual
		_nav_obj_pos = objetivo_pos
		_nav_obj_h = h_suelo_obj
		_nav_obj_en_pasarela = en_pasarela_obj
		_nav_obj_apotema = apot_obj

	var y_ref_orig := maxf(orig.y, h_suelo_actual)
	var y_ref_obj := maxf(objetivo_pos.y, h_suelo_obj)

	# 0. Watchdog físico de rescate: si un enemigo queda incrustado bajo una rampa/escalón
	if orig.y < h_suelo_actual - 0.14:
		cuerpo.global_position.y = h_suelo_actual + 0.04
		orig = cuerpo.global_position

	var dif_total := objetivo_pos - orig
	dif_total.y = 0.0
	if dif_total.length_squared() < 0.0025:
		return Vector3.ZERO
	var dir_directa := dif_total.normalized()

	var corredor_actual_idx := _detectar_corredor_rampa(orig.x, orig.z, 1.35, 0.25)
	var en_rampa_activa: bool = corredor_actual_idx >= 0 or esta_en_pendiente(orig.x, orig.z, 0.65)

	# Timer de deslizamiento anti-atasco activo (nunca desviar de costado si está en una rampa)
	var slide_t := float(estado_nav.get("slide_timer", 0.0))
	if slide_t > 0.0 and not en_rampa_activa:
		slide_t = maxf(0.0, slide_t - delta)
		estado_nav["slide_timer"] = slide_t
		var s_dir: Vector3 = estado_nav.get("slide_dir", dir_directa)
		if slide_t > 0.0 and s_dir.length_squared() > 0.01:
			return s_dir.normalized()
	elif en_rampa_activa:
		estado_nav["slide_timer"] = 0.0

	var dir_deseada := dir_directa
	var rampa_guardada_idx := int(estado_nav.get("rampa_idx", -1))
	var buscando_bastion := (h_suelo_obj >= 0.35 and h_suelo_obj < 0.60) and not en_pasarela_obj
	var en_pasarela_plana := h_suelo_actual >= ALTURA_PASARELA - 0.02 and orig.y >= ALTURA_PASARELA - 0.06 and apot_actual >= (APOTEMA_FOSO + 0.70)
	if corredor_actual_idx >= 0 and not _rampas_info[corredor_actual_idx]["es_cardinal"]:
		var rn_corr: Vector2 = _rampas_info[corredor_actual_idx]["normal"]
		var along_corr: float = orig.x * rn_corr.x + orig.z * rn_corr.y
		if along_corr < (BASTION_RAMPA_SUP_FIN_APRON + 0.15):
			en_pasarela_plana = false
	var coronada_pasarela := en_pasarela_plana
	var coronado_bastion := h_suelo_actual >= ALTURA_BASTION - 0.02 and orig.y >= ALTURA_BASTION - 0.06

	# CASO A: Objetivo en nivel superior (Pasarela +0.80m o Bastión +0.40m) o enemigo actualmente subiendo una rampa
	# Mantener bloqueo de rampa hasta que tanto la posición como la altura real del cuerpo hayan coronado la cresta!
	var necesita_subir_rampa: bool = (
		(y_ref_obj > orig.y + 0.14 and not coronada_pasarela)
		or (h_suelo_obj >= ALTURA_PASARELA - 0.05 and not coronada_pasarela)
		or (buscando_bastion and not coronado_bastion)
		or (rampa_guardada_idx >= 0 and h_suelo_obj >= ALTURA_BASTION - 0.05 and orig.y < h_suelo_obj - 0.06)
		or (corredor_actual_idx >= 0 and y_ref_obj >= orig.y - 0.06 and not coronada_pasarela and apot_obj >= RAMPA_CARDINAL_INICIO - 1.0)
	)

	if necesita_subir_rampa:
		var mejor_idx := rampa_guardada_idx
		if corredor_actual_idx >= 0 and ( not buscando_bastion or not _rampas_info[corredor_actual_idx]["es_cardinal"] ):
			mejor_idx = corredor_actual_idx
		else:
			var mejor_costo: float = 999999.0
			for i in range(_rampas_info.size()):
				var r := _rampas_info[i]
				if buscando_bastion and r["es_cardinal"]:
					continue
				var boca: Vector3 = r["boca"]
				var cresta: Vector3 = r["cresta_inf"] if buscando_bastion else r["cresta"]
				var d_boca := Vector2(orig.x - boca.x, orig.z - boca.z).length()
				var d_cresta := Vector2(cresta.x - objetivo_pos.x, cresta.z - objetivo_pos.z).length()
				var bonus: float = 3.2 if i == mejor_idx else 0.0
				var costo := d_boca + 0.65 * d_cresta - bonus
				if costo < mejor_costo:
					mejor_costo = costo
					mejor_idx = i

		if mejor_idx < 0 or mejor_idx >= _rampas_info.size():
			mejor_idx = 0
		estado_nav["rampa_idx"] = mejor_idx
		var rampa_elegida: Dictionary = _rampas_info[mejor_idx]
		var es_cardinal_r: bool = rampa_elegida["es_cardinal"]
		var rn: Vector2 = rampa_elegida["normal"]
		var rt: Vector2 = rampa_elegida["tangente"]
		var along: float = orig.x * rn.x + orig.z * rn.y
		var perp: float = orig.x * rt.x + orig.z * rt.y
		var r_ini: float = float(rampa_elegida["r_inicio"])
		var r_fin_r: float = float(rampa_elegida["r_fin"])
		var semi_a: float = float(rampa_elegida["semi_ancho"])
		if not es_cardinal_r and along < float(rampa_elegida.get("r_sup_ini", BASTION_RAMPA_SUP_INICIO)) - 1.0:
			semi_a = float(rampa_elegida.get("semi_ancho_inf", BASTION_RAMPA_INF_SEMI_ANCHO))
		var semi_seguro := maxf(0.9, semi_a - 0.72)
		var wp: Vector3

		# Escape lateral si se quedó pegado fuera de la boca o en el bolsillo lateral junto a la rampa
		if along >= (r_ini - 0.5) and absf(perp) > (semi_a - 0.25) and orig.y < 0.36:
			var p_esc := rn * (r_ini - 2.0) + rt * (signf(perp) * maxf(0.0, absf(perp) - 1.6))
			wp = Vector3(p_esc.x, 0.0, p_esc.y)
		elif along < (r_ini - 0.4) or (absf(perp) > semi_seguro and orig.y < 0.28):
			# Si está en el foso pegado al escalón de 0.80m lejos de la boca, bordear hacia la boca sin chocar contra el escalón
			if orig.y < 0.36 and apot_actual >= (APOTEMA_FOSO - 2.2) and absf(perp) > semi_seguro + 0.5:
				var s_hacia := -signf(perp) if absf(perp) > 0.01 else 1.0
				var p_borde := Vector2(orig.x, orig.z) + rt * (s_hacia * 2.8) - rn * 1.15
				wp = Vector3(p_borde.x, 0.0, p_borde.y)
			else:
				var r_boca_wp := clampf(along + 1.6, r_ini - 1.3, r_ini + 0.5)
				var p_boca_wp := clampf(perp * 0.25, -semi_seguro * 0.45, semi_seguro * 0.45)
				var pt_b := rn * r_boca_wp + rt * p_boca_wp
				wp = Vector3(pt_b.x, 0.0, pt_b.y)
		elif not es_cardinal_r and along >= (BASTION_RAMPA_SUP_FIN_PENDIENTE - 0.15) and orig.y >= (ALTURA_PASARELA - 0.06):
			# Ya en el puente horizontal del bastión (Apron, y = 0.80m): avanzar hacia el carril de la pasarela en dirección al jugador
			var dot_obj_t := (objetivo_pos.x * rt.x + objetivo_pos.z * rt.y) - perp
			var s_lat := signf(dot_obj_t) if absf(dot_obj_t) > 0.2 else 0.0
			var pt_apron := rn * (r_fin_r + 2.2) + rt * (s_lat * 2.4)
			wp = Vector3(pt_apron.x, ALTURA_PASARELA, pt_apron.y)
		else:
			# Ya dentro del corredor de la rampa: avanzar centrado por el eje longitudinal hasta superar r_fin + 1.4m
			if buscando_bastion and not es_cardinal_r:
				wp = rampa_elegida["cresta_inf"]
			elif not es_cardinal_r and along >= float(rampa_elegida.get("r_deck_ini", BASTION_DECK_INICIO)) - 0.5 and absf(perp) > 1.15 and along < float(rampa_elegida.get("r_sup_ini", BASTION_RAMPA_SUP_INICIO)) + 1.2:
				# Si está en la plataforma intermedia del bastión (semi_ancho 3.1m) desplazado lateralmente,
				# primero embocar la boca de la rampa superior (semi_ancho 2.3m) antes de avanzar contra el muro de 0.80m
				var r_emb := clampf(along + 0.8, BASTION_DECK_INICIO + 1.2, BASTION_RAMPA_SUP_INICIO - 0.3)
				var pt_emb := rn * r_emb + rt * (perp * 0.15)
				wp = Vector3(pt_emb.x, ALTURA_BASTION, pt_emb.y)
			else:
				var r_avance := minf(r_fin_r + 1.45, along + 3.4)
				var factor_c := 0.20
				if not es_cardinal_r and along >= float(rampa_elegida.get("r_deck_ini", BASTION_DECK_INICIO)) - 0.5:
					# Embocar el tramo superior del bastión (semi_ancho = 2.30m) bien centrado
					factor_c = 0.08
					semi_seguro = BASTION_RAMPA_SUP_SEMI_ANCHO - 0.95
				var p_centrado := clampf(perp * factor_c, -semi_seguro * 0.45, semi_seguro * 0.45)
				var pt_c := rn * r_avance + rt * p_centrado
				wp = Vector3(pt_c.x, ALTURA_PASARELA, pt_c.y)

		# Rescate anti-atasco dentro de la rampa: si lleva > 0.40s sin avanzar en la rampa, centrar y elevar suavemente
		var last_pos_r: Vector3 = estado_nav.get("last_pos_rampa", orig)
		var stuck_r: float = float(estado_nav.get("stuck_rampa_t", 0.0))
		if Vector2(orig.x - last_pos_r.x, orig.z - last_pos_r.z).length() < 0.28 * maxf(delta * 12.0, 0.16):
			stuck_r += delta
		else:
			stuck_r = maxf(0.0, stuck_r - delta * 2.0)
			estado_nav["last_pos_rampa"] = orig
		estado_nav["stuck_rampa_t"] = stuck_r

		if stuck_r >= 0.40 and along >= (r_ini - 1.6) and along <= (r_fin_r + 1.2):
			var r_snap := clampf(along + 0.60, r_ini + 0.3, r_fin_r + 0.9)
			var p_snap := clampf(perp * 0.30, -1.0, 1.0)
			var pt_s := rn * r_snap + rt * p_snap
			var ny := obtener_altura_suelo(pt_s.x, pt_s.y) + 0.05
			cuerpo.global_position = Vector3(pt_s.x, maxf(orig.y + 0.06, ny), pt_s.y)
			orig = cuerpo.global_position
			estado_nav["stuck_rampa_t"] = 0.0
			estado_nav["last_pos_rampa"] = orig

		var h_wp := Vector3(wp.x - orig.x, 0.0, wp.z - orig.z)
		if h_wp.length_squared() > 0.01:
			return h_wp.normalized()
	else:
		if coronada_pasarela or corredor_actual_idx < 0:
			estado_nav["rampa_idx"] = -1
			estado_nav["stuck_rampa_t"] = 0.0

	# CASO A2: Enemigo en el Foso (0.0m) cerca del muro vertical de la Pasarela (+0.80m) fuera de rampa
	if orig.y < 0.38 and apot_actual >= (APOTEMA_FOSO - 1.65) and corredor_actual_idx < 0:
		var n_inward := obtener_normal_pared_cercana(orig)
		if dir_directa.dot(-n_inward) > 0.12 or cuerpo.is_on_wall():
			var mejor_i := 0
			var mejor_d := 999999.0
			for i in range(_rampas_info.size()):
				var b_pos: Vector3 = _rampas_info[i]["boca"]
				var d_b := Vector2(orig.x - b_pos.x, orig.z - b_pos.z).length()
				if d_b < mejor_d:
					mejor_d = d_b
					mejor_i = i
			estado_nav["rampa_idx"] = mejor_i
			var boca_c: Vector3 = _rampas_info[mejor_i]["boca"]
			var h_boca := Vector3(boca_c.x - orig.x, 0.0, boca_c.z - orig.z)
			if h_boca.length_squared() > 0.01:
				return h_boca.normalized()

	# CASO A3: Enemigo bajando por una rampa hacia el Foso: mantener centrado en el corredor para no caer de costado en un rincón
	if corredor_actual_idx >= 0 and y_ref_obj < y_ref_orig - 0.15:
		var r_baja: Dictionary = _rampas_info[corredor_actual_idx]
		var rn_b: Vector2 = r_baja["normal"]
		var rt_b: Vector2 = r_baja["tangente"]
		var along_b: float = orig.x * rn_b.x + orig.z * rn_b.y
		var perp_b: float = orig.x * rt_b.x + orig.z * rt_b.y
		var semi_b := maxf(0.9, float(r_baja["semi_ancho"]) - 0.75)
		var r_dest_b := maxf(float(r_baja["r_inicio"]) - 1.2, along_b - 3.0)
		var p_dest_b := clampf(perp_b * 0.25, -semi_b * 0.45, semi_b * 0.45)
		var pt_baja := rn_b * r_dest_b + rt_b * p_dest_b
		var h_baja := Vector3(pt_baja.x - orig.x, 0.0, pt_baja.y - orig.z)
		if h_baja.length_squared() > 0.01:
			return h_baja.normalized()

	# CASO B: Ambos en la Pasarela (+0.80m) -> rodear si la línea recta cruza el foso con diferencia angular <= 115°
	if orig.y >= 0.45 and objetivo_pos.y >= 0.45 and apot_actual >= (APOTEMA_FOSO - 0.5):
		var corta_foso := false
		for t_m in [0.25, 0.50, 0.75]:
			var m_pt := orig.lerp(objetivo_pos, t_m)
			if apotema_en_pos(m_pt.x, m_pt.z) < (APOTEMA_FOSO - 0.45):
				corta_foso = true
				break
		if corta_foso:
			var ang_o := atan2(orig.x, -orig.z)
			var ang_t := atan2(objetivo_pos.x, -objetivo_pos.z)
			var diff_ang := wrapf(ang_t - ang_o, -PI, PI)
			if absf(diff_ang) <= deg_to_rad(115.0):
				var paso_ang: float = signf(diff_ang) * deg_to_rad(22.0)
				var ang_look := ang_o + paso_ang
				var radio_carril: float = (APOTEMA_FOSO + APOTEMA_EXTERIOR) * 0.5
				var pt_orbita := Vector3(sin(ang_look) * radio_carril, orig.y, -cos(ang_look) * radio_carril)
				var h_orb := Vector3(pt_orbita.x - orig.x, 0.0, pt_orbita.z - orig.z)
				if h_orb.length_squared() > 0.01:
					dir_deseada = h_orb.normalized()
		elif apot_actual < (APOTEMA_FOSO + 1.15) and apotema_en_pos(orig.x + dir_deseada.x * 2.5, orig.z + dir_deseada.z * 2.5) < (APOTEMA_FOSO + 0.35):
			# Si camina por la pasarela rozando la esquina interior de un vértice del foso, abrirse ligeramente hacia el exterior
			var n_in_p := obtener_normal_pared_cercana(orig)
			dir_deseada = (dir_deseada * 0.78 - n_in_p * 0.38).normalized()

	# CASO D: Anti-atasco y deslizamiento tangencial si hay contacto con muro/escalón
	var choca_muro := cuerpo.is_on_wall()
	var stall_t := float(estado_nav.get("stall_t", 0.0))
	var last_pos: Vector3 = estado_nav.get("last_pos", orig)
	stall_t += delta
	var bloqueado_avance := false
	if stall_t >= 0.22:
		var dist_av := Vector2(orig.x - last_pos.x, orig.z - last_pos.z).length()
		var vel_esperada := Vector2(cuerpo.velocity.x, cuerpo.velocity.z).length()
		if vel_esperada > 0.5 and dist_av < vel_esperada * stall_t * 0.16:
			bloqueado_avance = true
		stall_t = 0.0
		last_pos = orig
	estado_nav["stall_t"] = stall_t
	estado_nav["last_pos"] = last_pos

	if choca_muro or bloqueado_avance:
		# Si está en o cerca de una rampa Y aún necesita subir o bajar por ella, desatascar alineando al eje longitudinal
		var r_cerca_idx := _detectar_corredor_rampa(orig.x, orig.z, 2.2, 0.85)
		if r_cerca_idx >= 0 and (necesita_subir_rampa or y_ref_obj < y_ref_orig - 0.15):
			var r_c: Dictionary = _rampas_info[r_cerca_idx]
			var rn_c: Vector2 = r_c["normal"]
			var along_c: float = orig.x * rn_c.x + orig.z * rn_c.y
			var va_subiendo := y_ref_obj >= y_ref_orig - 0.05
			var r_obj_c := (along_c + 2.4) if va_subiendo else (along_c - 2.4)
			var pt_eje := rn_c * r_obj_c
			var dir_eje := Vector3(pt_eje.x - orig.x, 0.0, pt_eje.y - orig.z)
			if dir_eje.length_squared() > 0.01:
				return dir_eje.normalized()
		elif r_cerca_idx >= 0 and coronada_pasarela:
			# Ya coronó una rampa hacia la pasarela pero choca con un obstáculo o borde: empujar radialmente hacia el centro del carril de la pasarela
			var r_c2: Dictionary = _rampas_info[r_cerca_idx]
			var rn_c2: Vector2 = r_c2["normal"]
			var rt_c2: Vector2 = r_c2["tangente"]
			var dot_t2 := dir_deseada.x * rt_c2.x + dir_deseada.z * rt_c2.y
			var s_t2 := 1.0 if dot_t2 >= 0.0 else -1.0
			var dir_carril := Vector3(rn_c2.x * 0.45 + rt_c2.x * s_t2 * 0.89, 0.0, rn_c2.y * 0.45 + rt_c2.y * s_t2 * 0.89).normalized()
			return dir_carril

		var wn := Vector3.ZERO
		if choca_muro:
			wn = cuerpo.get_wall_normal()
			wn.y = 0.0
		if wn.length_squared() < 0.01:
			wn = -dir_deseada
		wn = wn.normalized()
		var tang := Vector3(-wn.z, 0.0, wn.x).normalized()
		var dot_t := dir_deseada.dot(tang)
		var signo: float = 1.0 if dot_t >= 0.0 else -1.0
		if absf(dot_t) < 0.18:
			signo = 1.0 if ((cuerpo.get_instance_id() & 1) == 0) else -1.0
		var slide := (tang * signo * 0.90 + wn * 0.10).normalized()
		if choca_muro:
			estado_nav["slide_dir"] = slide
			estado_nav["slide_timer"] = 0.25
		else:
			estado_nav["slide_dir"] = slide
			estado_nav["slide_timer"] = 0.30
		return slide

	return dir_deseada

# ==============================================================================
# CONSTRUCCIÓN PROCEDURAL DEL ANFITEATRO Y LOS 4 SECTORES
# ==============================================================================

func _construir_anfiteatro_completo() -> void:
	var prev := get_node_or_null("GeometriaAnfiteatro")
	if prev != null:
		prev.queue_free()

	var root := Node3D.new()
	root.name = "GeometriaAnfiteatro"
	add_child(root)

	_preparar_materiales_terreno()
	_construir_foso_y_pasarela(root)
	_construir_rampas_cardinales(root)
	_construir_bastiones_diagonales(root)
	_construir_muros_y_pilastras(root)
	_construir_props_e_iluminacion_sectores(root)
	_generar_obstaculos_run(root)

func _preparar_materiales_terreno() -> void:
	_mat_piso_foso = StandardMaterial3D.new()
	_mat_piso_foso.albedo_color = Color(0.68, 0.72, 0.78, 1.0)
	_mat_piso_foso.albedo_texture = TEX_PISO
	_mat_piso_foso.metallic = 0.25
	_mat_piso_foso.roughness = 0.68
	_mat_piso_foso.uv1_triplanar = true
	_mat_piso_foso.uv1_scale = Vector3(0.50, 0.50, 0.50)

	_mat_bastion = StandardMaterial3D.new()
	_mat_bastion.albedo_color = Color(0.52, 0.56, 0.62, 1.0)
	_mat_bastion.albedo_texture = TEX_PISO
	_mat_bastion.metallic = 0.35
	_mat_bastion.roughness = 0.58
	_mat_bastion.uv1_triplanar = true
	_mat_bastion.uv1_scale = Vector3(0.55, 0.55, 0.55)

	_mat_pasarela = StandardMaterial3D.new()
	_mat_pasarela.albedo_color = Color(0.40, 0.44, 0.50, 1.0)
	_mat_pasarela.albedo_texture = TEX_PISO
	_mat_pasarela.metallic = 0.42
	_mat_pasarela.roughness = 0.52
	_mat_pasarela.uv1_triplanar = true
	_mat_pasarela.uv1_scale = Vector3(0.625, 0.625, 0.625)

	_mat_rampa = BunkerVisualKit.get_armor_grey_mat()

	_mat_hazard_zocalo = BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CARBON_STEEL,
		14.0,
		Vector2(4.5, 1.0),
		45.0
	)
	_mat_hazard_zocalo.set_shader_parameter("emission_a", 0.22)
	_mat_hazard_zocalo.set_shader_parameter("wear_amount", 0.08)

	_mat_hazard_rampa = BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CARBON_STEEL,
		10.0,
		Vector2(3.0, 1.0),
		45.0
	)
	_mat_hazard_rampa.set_shader_parameter("emission_a", 0.28)
	_mat_hazard_rampa.set_shader_parameter("wear_amount", 0.07)

func _agregar_tri_orientado(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	uva: Vector2,
	uvb: Vector2,
	uvc: Vector2,
	normal_esp: Vector3
) -> void:
	# En Godot el winding horario mirando contra la normal da (c - a).cross(b - a) == normal_esp
	var geom_n: Vector3 = (c - a).cross(b - a)
	var b_fin := b
	var c_fin := c
	var uvb_fin := uvb
	var uvc_fin := uvc
	if geom_n.dot(normal_esp) < 0.0:
		b_fin = c
		c_fin = b
		uvb_fin = uvc
		uvc_fin = uvb
	st.set_normal(normal_esp)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_normal(normal_esp)
	st.set_uv(uvb_fin)
	st.add_vertex(b_fin)
	st.set_normal(normal_esp)
	st.set_uv(uvc_fin)
	st.add_vertex(c_fin)

func _agregar_quad_orientado(
	st: SurfaceTool,
	p00: Vector3,
	p10: Vector3,
	p11: Vector3,
	p01: Vector3,
	normal_esp: Vector3,
	uv_escala: Vector2 = Vector2(0.5, 0.5),
	usar_uv_planar_xz: bool = true,
	uv_manual_w: float = 1.0
) -> void:
	var uv00 := Vector2(p00.x, p00.z) * uv_escala if usar_uv_planar_xz else Vector2(0.0, 0.0)
	var uv10 := Vector2(p10.x, p10.z) * uv_escala if usar_uv_planar_xz else Vector2(uv_manual_w, 0.0)
	var uv11 := Vector2(p11.x, p11.z) * uv_escala if usar_uv_planar_xz else Vector2(uv_manual_w, 1.0)
	var uv01 := Vector2(p01.x, p01.z) * uv_escala if usar_uv_planar_xz else Vector2(0.0, 1.0)
	_agregar_tri_orientado(st, p00, p10, p11, uv00, uv10, uv11, normal_esp)
	_agregar_tri_orientado(st, p00, p11, p01, uv00, uv11, uv01, normal_esp)

func _construir_foso_y_pasarela(parent: Node3D) -> void:
	# 1. Foso Central (Y = 0.00): 1 BoxShape3D plano sin costuras + malla dodecagonal plana
	var cuerpo_foso := StaticBody3D.new()
	cuerpo_foso.name = "PisoFoso"
	cuerpo_foso.collision_layer = LAYER_TERRENO
	cuerpo_foso.collision_mask = 0
	parent.add_child(cuerpo_foso)

	var col_foso := CollisionShape3D.new()
	var box_foso := BoxShape3D.new()
	box_foso.size = Vector3(134.0, 0.6, 134.0)
	col_foso.shape = box_foso
	col_foso.position = Vector3(0.0, -0.30, 0.0)
	cuerpo_foso.add_child(col_foso)

	var st_foso := SurfaceTool.new()
	st_foso.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centro := Vector3.ZERO
	for k in range(NUM_LADOS):
		var v0_2d := _vertices_ext[k]
		var v1_2d := _vertices_ext[(k + 1) % NUM_LADOS]
		var p0 := Vector3(v0_2d.x, 0.0, v0_2d.y)
		var p1 := Vector3(v1_2d.x, 0.0, v1_2d.y)
		_agregar_tri_orientado(
			st_foso,
			centro,
			p0,
			p1,
			Vector2.ZERO,
			Vector2(p0.x, p0.z) * 0.5,
			Vector2(p1.x, p1.z) * 0.5,
			Vector3.UP
		)
	var mesh_foso := MeshInstance3D.new()
	mesh_foso.name = "MallaFoso"
	mesh_foso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_foso.mesh = st_foso.commit()
	mesh_foso.material_override = _mat_piso_foso
	cuerpo_foso.add_child(mesh_foso)

	# 2. Pasarela Perimetral (+0.80 m):
	#    - Malla superior indexada con vértices soldados -> ConcavePolygonShape3D (suave entre caras)
	#    - 12 cuñas ConvexPolygonShape3D por debajo (y = -0.05..0.785) anti-tunneling
	var cuerpo_pasarela := StaticBody3D.new()
	cuerpo_pasarela.name = "PasarelaPerimetral"
	cuerpo_pasarela.collision_layer = LAYER_TERRENO
	cuerpo_pasarela.collision_mask = 0
	parent.add_child(cuerpo_pasarela)

	var st_deck := SurfaceTool.new()
	st_deck.begin(Mesh.PRIMITIVE_TRIANGLES)

	var st_zocalo := SurfaceTool.new()
	st_zocalo.begin(Mesh.PRIMITIVE_TRIANGLES)

	for k in range(NUM_LADOS):
		var kn := (k + 1) % NUM_LADOS
		var i0_2d := _vertices_foso[k]
		var i1_2d := _vertices_foso[kn]
		var o0_2d := _vertices_ext[k] * 1.035 # Extender bajo el muro exterior para sellar
		var o1_2d := _vertices_ext[kn] * 1.035

		var ti0 := Vector3(i0_2d.x, ALTURA_PASARELA, i0_2d.y)
		var ti1 := Vector3(i1_2d.x, ALTURA_PASARELA, i1_2d.y)
		var to0 := Vector3(o0_2d.x, ALTURA_PASARELA, o0_2d.y)
		var to1 := Vector3(o1_2d.x, ALTURA_PASARELA, o1_2d.y)

		_agregar_quad_orientado(st_deck, ti0, to0, to1, ti1, Vector3.UP, Vector2(0.5, 0.5), true)

		# Cuña sólida sub-pasarela (y = -0.05..0.785)
		var b_i0 := Vector3(i0_2d.x, -0.05, i0_2d.y)
		var b_i1 := Vector3(i1_2d.x, -0.05, i1_2d.y)
		var b_o0 := Vector3(o0_2d.x, -0.05, o0_2d.y)
		var b_o1 := Vector3(o1_2d.x, -0.05, o1_2d.y)
		var u_i0 := Vector3(i0_2d.x, ALTURA_PASARELA - 0.015, i0_2d.y)
		var u_i1 := Vector3(i1_2d.x, ALTURA_PASARELA - 0.015, i1_2d.y)
		var u_o0 := Vector3(o0_2d.x, ALTURA_PASARELA - 0.015, o0_2d.y)
		var u_o1 := Vector3(o1_2d.x, ALTURA_PASARELA - 0.015, o1_2d.y)

		var conv := ConvexPolygonShape3D.new()
		conv.points = PackedVector3Array([b_i0, b_i1, b_o0, b_o1, u_i0, u_i1, u_o0, u_o1])
		var col_sub := CollisionShape3D.new()
		col_sub.shape = conv
		cuerpo_pasarela.add_child(col_sub)

		# Cara vertical interior del escalón (hazard stripes)
		var n_in := Vector3(-_normales_caras[k].x, 0.0, -_normales_caras[k].y).normalized()
		var zi0 := Vector3(i0_2d.x, 0.0, i0_2d.y)
		var zi1 := Vector3(i1_2d.x, 0.0, i1_2d.y)
		var zt0 := Vector3(i0_2d.x, ALTURA_PASARELA - 0.04, i0_2d.y)
		var zt1 := Vector3(i1_2d.x, ALTURA_PASARELA - 0.04, i1_2d.y)
		var ancho_foso := zi0.distance_to(zi1)
		_agregar_quad_orientado(st_zocalo, zi0, zi1, zt1, zt0, n_in, Vector2.ONE, false, ancho_foso * 0.28)

		# Detalles visuales de lectura del escalón en 4 capas (canaleta inferior, labio titanio, tira emisiva del sector)
		_crear_molduras_escalon_cara(parent, k, i0_2d, i1_2d)

	st_deck.index()
	var arr_deck := st_deck.commit()
	var mesh_deck := MeshInstance3D.new()
	mesh_deck.name = "MallaPasarela"
	mesh_deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_deck.mesh = arr_deck
	mesh_deck.material_override = _mat_pasarela
	cuerpo_pasarela.add_child(mesh_deck)

	var col_deck := CollisionShape3D.new()
	col_deck.shape = arr_deck.create_trimesh_shape()
	cuerpo_pasarela.add_child(col_deck)

	var mesh_zocalo := MeshInstance3D.new()
	mesh_zocalo.name = "MallaZocaloHazard"
	mesh_zocalo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_zocalo.mesh = st_zocalo.commit()
	mesh_zocalo.material_override = _mat_hazard_zocalo
	cuerpo_pasarela.add_child(mesh_zocalo)

func _crear_molduras_escalon_cara(parent: Node3D, k: int, i0_2d: Vector2, i1_2d: Vector2) -> void:
	var n := _normales_caras[k]
	var theta := float(k) * (TAU / float(NUM_LADOS))
	var largo := i0_2d.distance_to(i1_2d)
	var col_sector := _color_sector_por_cara(k)

	# Para caras cardinales con rampa (0, 3, 6, 9), dividir la moldura dejando libre el vano central de 5.6m
	var spans: Array[Vector2] = []
	if k in INDICES_RAMPAS_CARDINALES:
		var half_l := largo * 0.5
		var gap_half := RAMPA_CARDINAL_SEMI_ANCHO + 0.05
		if half_l - gap_half > 0.25:
			spans.append(Vector2(-half_l, -gap_half))
			spans.append(Vector2(gap_half, half_l))
	else:
		spans.append(Vector2(-largo * 0.5, largo * 0.5))

	var holder := Node3D.new()
	holder.name = "MolduraEscalon_%02d" % k
	holder.position = Vector3(n.x * APOTEMA_FOSO, 0.0, n.y * APOTEMA_FOSO)
	holder.rotation.y = -theta
	parent.add_child(holder)

	var mat_tira := BunkerVisualKit.make_emissive_mat(col_sector, 1.55, col_sector.darkened(0.4))
	for idx in range(spans.size()):
		var sp := spans[idx]
		var w := sp.y - sp.x
		var cx := (sp.x + sp.y) * 0.5
		# 1. Canaleta inferior acero carbono (Y = 0.015)
		BunkerVisualKit.make_box(holder, "Canaleta_%d" % idx, Vector3(w, 0.03, 0.28), BunkerVisualKit.get_chassis_mat(), Vector3(cx, 0.015, 0.14))
		# 2. Labio biselado superior de titanio (+0.04m relieve visual)
		BunkerVisualKit.make_box(holder, "LabioTitanio_%d" % idx, Vector3(w, 0.09, 0.36), BunkerVisualKit.get_titanium_mat(), Vector3(cx, ALTURA_PASARELA - 0.01, -0.14))
		# 3. Tira guía emisiva de sector en borde interior de pasarela
		BunkerVisualKit.make_box(holder, "TiraSector_%d" % idx, Vector3(w, 0.02, 0.09), mat_tira, Vector3(cx, ALTURA_PASARELA + 0.008, -0.40))

func _construir_rampas_cardinales(parent: Node3D) -> void:
	for k in INDICES_RAMPAS_CARDINALES:
		var theta := float(k) * (TAU / float(NUM_LADOS))
		var col_sector := _color_sector_por_cara(k)
		_crear_tramo_rampa(
			parent,
			"RampaCardinal_%02d" % k,
			theta,
			RAMPA_CARDINAL_INICIO,
			RAMPA_CARDINAL_FIN,
			0.0,
			ALTURA_PASARELA,
			RAMPA_CARDINAL_SEMI_ANCHO * 2.0,
			col_sector,
			true,
			false
		)

func _construir_bastiones_diagonales(parent: Node3D) -> void:
	var colores_diag := [
		BunkerVisualKit.COL_CRYO_BLUE,       # NE 45°
		BunkerVisualKit.COL_PLASMA_ORANGE,   # SE 135°
		BunkerVisualKit.COL_NEON_GREEN,      # SW 225°
		BunkerVisualKit.COL_CRIMSON_ALERT,   # NW 315°
	]
	for idx in range(ANGULOS_DIAGONALES_DEG.size()):
		var phi_rad := deg_to_rad(ANGULOS_DIAGONALES_DEG[idx])
		var nd := Vector2(sin(phi_rad), -cos(phi_rad))
		var col_sec: Color = colores_diag[idx]

		# 1. Rampa inferior (0.00 -> 0.40 m)
		_crear_tramo_rampa(
			parent,
			"Bastion_%d_RampaInf" % idx,
			phi_rad,
			BASTION_RAMPA_INF_INICIO,
			BASTION_RAMPA_INF_FIN,
			0.0,
			ALTURA_BASTION,
			BASTION_RAMPA_INF_SEMI_ANCHO * 2.0,
			col_sec,
			true,
			false
		)

		# 2. Plataforma Bastión intermedia (+0.40 m)
		var deck_len := BASTION_DECK_FIN - BASTION_DECK_INICIO
		var deck_w := BASTION_DECK_SEMI_ANCHO * 2.0
		var deck_mid := (BASTION_DECK_INICIO + BASTION_DECK_FIN) * 0.5
		var body_deck := StaticBody3D.new()
		body_deck.name = "Bastion_%d_Deck" % idx
		body_deck.collision_layer = LAYER_TERRENO
		body_deck.collision_mask = 0
		body_deck.position = Vector3(nd.x * deck_mid, 0.0, nd.y * deck_mid)
		body_deck.rotation.y = -phi_rad
		parent.add_child(body_deck)

		var col_d := CollisionShape3D.new()
		var box_col := BoxShape3D.new()
		box_col.size = Vector3(deck_w, ALTURA_BASTION - 0.015, deck_len)
		col_d.shape = box_col
		col_d.position = Vector3(0.0, (ALTURA_BASTION - 0.015) * 0.5, 0.0)
		body_deck.add_child(col_d)

		# Malla del bastión con contraste + rebordes titanio y franjas hazard laterales
		var st_d := SurfaceTool.new()
		st_d.begin(Mesh.PRIMITIVE_TRIANGLES)
		var hw := deck_w * 0.5
		var hl := deck_len * 0.5
		_agregar_quad_orientado(
			st_d,
			Vector3(-hw, ALTURA_BASTION, -hl),
			Vector3(hw, ALTURA_BASTION, -hl),
			Vector3(hw, ALTURA_BASTION, hl),
			Vector3(-hw, ALTURA_BASTION, hl),
			Vector3.UP,
			Vector2(0.5, 0.5),
			false,
			2.0
		)
		var m_deck := MeshInstance3D.new()
		m_deck.mesh = st_d.commit()
		m_deck.material_override = _mat_bastion
		m_deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body_deck.add_child(m_deck)

		BunkerVisualKit.make_box(body_deck, "FaldonBastion", Vector3(deck_w - 0.02, ALTURA_BASTION - 0.02, deck_len - 0.02), _mat_hazard_zocalo, Vector3(0.0, (ALTURA_BASTION - 0.02) * 0.5, 0.0))
		var mat_tira := BunkerVisualKit.make_emissive_mat(col_sec, 1.45, col_sec.darkened(0.4))
		BunkerVisualKit.make_box(body_deck, "BordeIzq", Vector3(0.16, 0.04, deck_len), BunkerVisualKit.get_titanium_mat(), Vector3(-hw + 0.08, ALTURA_BASTION + 0.01, 0.0))
		BunkerVisualKit.make_box(body_deck, "BordeDer", Vector3(0.16, 0.04, deck_len), BunkerVisualKit.get_titanium_mat(), Vector3(hw - 0.08, ALTURA_BASTION + 0.01, 0.0))
		BunkerVisualKit.make_box(body_deck, "LuzIzq", Vector3(0.06, 0.015, deck_len * 0.85), mat_tira, Vector3(-hw + 0.22, ALTURA_BASTION + 0.008, 0.0))
		BunkerVisualKit.make_box(body_deck, "LuzDer", Vector3(0.06, 0.015, deck_len * 0.85), mat_tira, Vector3(hw - 0.22, ALTURA_BASTION + 0.008, 0.0))

		# 3. Rampa superior (+0.40 -> +0.80 m) + puente horizontal sin muesca hasta el vértice
		_crear_tramo_rampa(
			parent,
			"Bastion_%d_RampaSup" % idx,
			phi_rad,
			BASTION_RAMPA_SUP_INICIO,
			BASTION_RAMPA_SUP_FIN_PENDIENTE,
			ALTURA_BASTION,
			ALTURA_PASARELA,
			BASTION_RAMPA_SUP_SEMI_ANCHO * 2.0,
			col_sec,
			false,
			true
		)

		var apron_len := BASTION_RAMPA_SUP_FIN_APRON - BASTION_RAMPA_SUP_FIN_PENDIENTE
		var apron_mid := (BASTION_RAMPA_SUP_FIN_PENDIENTE + BASTION_RAMPA_SUP_FIN_APRON) * 0.5
		var body_apron := StaticBody3D.new()
		body_apron.name = "Bastion_%d_Apron" % idx
		body_apron.collision_layer = LAYER_TERRENO
		body_apron.collision_mask = 0
		body_apron.position = Vector3(nd.x * apron_mid, 0.0, nd.y * apron_mid)
		body_apron.rotation.y = -phi_rad
		parent.add_child(body_apron)

		var col_ap := CollisionShape3D.new()
		var box_ap := BoxShape3D.new()
		box_ap.size = Vector3(BASTION_RAMPA_SUP_SEMI_ANCHO * 2.0, ALTURA_PASARELA - 0.015, apron_len)
		col_ap.shape = box_ap
		col_ap.position = Vector3(0.0, (ALTURA_PASARELA - 0.015) * 0.5, 0.0)
		body_apron.add_child(col_ap)

		BunkerVisualKit.make_box(
			body_apron,
			"VisualApron",
			Vector3(BASTION_RAMPA_SUP_SEMI_ANCHO * 2.0, ALTURA_PASARELA, apron_len),
			_mat_pasarela,
			Vector3(0.0, ALTURA_PASARELA * 0.5, 0.0)
		)

func _crear_tramo_rampa(
	parent: Node3D,
	nombre: String,
	theta: float,
	r_inicio: float,
	r_fin: float,
	y_inicio: float,
	y_fin: float,
	ancho: float,
	col_sector: Color,
	con_pad_entrada: bool,
	con_pad_salida: bool
) -> void:
	var n := Vector2(sin(theta), -cos(theta))
	var run := r_fin - r_inicio
	var rise := y_fin - y_inicio
	var largo_pendiente := sqrt(run * run + rise * rise)
	var ang_x := atan2(rise, run) # Positivo: local -Z (exterior) sube, +Z (interior) baja

	var holder := Node3D.new()
	holder.name = nombre
	holder.position = Vector3(n.x * ((r_inicio + r_fin) * 0.5), 0.0, n.y * ((r_inicio + r_fin) * 0.5))
	holder.rotation.y = -theta
	parent.add_child(holder)

	var body := StaticBody3D.new()
	body.name = "CuerpoRampa"
	body.collision_layer = LAYER_TERRENO
	body.collision_mask = 0
	holder.add_child(body)

	# Losa inclinada exacta: su cara superior pasa milimétricamente por (r_inicio, y_inicio) y (r_fin, y_fin)
	var espesor: float = 0.28
	var xf_losa := Transform3D(Basis(Vector3.RIGHT, ang_x), Vector3(0.0, (y_inicio + y_fin) * 0.5, 0.0))
	var normal_sup := xf_losa.basis.y
	xf_losa.origin -= normal_sup * (espesor * 0.5)

	var col_losa := CollisionShape3D.new()
	var box_losa := BoxShape3D.new()
	box_losa.size = Vector3(ancho, espesor, largo_pendiente)
	col_losa.shape = box_losa
	col_losa.transform = xf_losa
	body.add_child(col_losa)

	# Cuña sólida inferior (evita atravesar por los flancos debajo de la rampa)
	var hw := ancho * 0.5
	var hl := run * 0.5
	var conv_cuna := ConvexPolygonShape3D.new()
	conv_cuna.points = PackedVector3Array([
		Vector3(-hw, -0.05, hl), Vector3(hw, -0.05, hl),
		Vector3(-hw, -0.05, -hl), Vector3(hw, -0.05, -hl),
		Vector3(-hw, maxf(-0.02, y_inicio - 0.02), hl), Vector3(hw, maxf(-0.02, y_inicio - 0.02), hl),
		Vector3(-hw, y_fin - 0.02, -hl), Vector3(hw, y_fin - 0.02, -hl),
	])
	var col_cuna := CollisionShape3D.new()
	col_cuna.shape = conv_cuna
	body.add_child(col_cuna)

	# Losa puente horizontal a ras de la cresta (y = y_fin) y de la entrada (y = y_inicio):
	# sella cualquier micro-costura entre la losa inclinada y la plataforma superior/inferior en Jolt Physics
	var col_puente_sup := CollisionShape3D.new()
	var box_puente_sup := BoxShape3D.new()
	box_puente_sup.size = Vector3(ancho, 0.24, 0.90)
	col_puente_sup.shape = box_puente_sup
	col_puente_sup.position = Vector3(0.0, y_fin - 0.12, -hl - 0.35)
	body.add_child(col_puente_sup)

	var col_puente_inf := CollisionShape3D.new()
	var box_puente_inf := BoxShape3D.new()
	box_puente_inf.size = Vector3(ancho, 0.20, 0.70)
	col_puente_inf.shape = box_puente_inf
	col_puente_inf.position = Vector3(0.0, y_inicio - 0.10, hl + 0.25)
	body.add_child(col_puente_inf)

	# Malla visual superior de la rampa + costados hazard (sin colisión lateral sobresaliente)
	var malla_losa := MeshInstance3D.new()
	malla_losa.name = "MallaRampa"
	var bm := BoxMesh.new()
	bm.size = Vector3(ancho, 0.06, largo_pendiente)
	malla_losa.mesh = bm
	malla_losa.transform = Transform3D(Basis(Vector3.RIGHT, ang_x), Vector3(0.0, (y_inicio + y_fin) * 0.5, 0.0) - normal_sup * 0.03)
	malla_losa.material_override = _mat_rampa
	malla_losa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(malla_losa)

	# Costados laterales visibles de rampa + costillas antideslizantes de titanio
	for lado_s in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var bm_rail := BoxMesh.new()
		bm_rail.size = Vector3(0.24, 0.08, largo_pendiente)
		rail.mesh = bm_rail
		rail.transform = Transform3D(Basis(Vector3.RIGHT, ang_x), Vector3(lado_s * (hw - 0.12), (y_inicio + y_fin) * 0.5, 0.0) + normal_sup * 0.03)
		rail.material_override = _mat_hazard_rampa
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(rail)

	var mat_tread := BunkerVisualKit.get_titanium_mat()
	var n_costillas := maxi(3, int(floor(largo_pendiente / 0.65)))
	for ci in range(1, n_costillas):
		var frac := float(ci) / float(n_costillas)
		var z_c := lerpf(hl, -hl, frac)
		var y_c := lerpf(y_inicio, y_fin, frac)
		var costilla := MeshInstance3D.new()
		var bm_c := BoxMesh.new()
		bm_c.size = Vector3(ancho - 0.56, 0.025, 0.09)
		costilla.mesh = bm_c
		costilla.transform = Transform3D(Basis(Vector3.RIGHT, ang_x), Vector3(0.0, y_c + 0.008, z_c))
		costilla.material_override = mat_tread
		costilla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(costilla)

	if con_pad_entrada:
		BunkerVisualKit.make_box(holder, "PadEntrada", Vector3(ancho, 0.02, 0.42), _mat_hazard_rampa, Vector3(0.0, y_inicio + 0.012, hl + 0.21))
		# Baliza de umbral luminosa en la entrada
		var mat_th := BunkerVisualKit.make_emissive_mat(col_sector, 1.8)
		BunkerVisualKit.make_box(holder, "TiraEntrada", Vector3(ancho * 0.85, 0.025, 0.08), mat_th, Vector3(0.0, y_inicio + 0.014, hl + 0.44))
	if con_pad_salida:
		BunkerVisualKit.make_box(holder, "PadSalida", Vector3(ancho, 0.02, 0.42), _mat_hazard_rampa, Vector3(0.0, y_fin + 0.012, -hl - 0.21))

# ==============================================================================
# MUROS EXTERIORES DODECAGONALES Y REGLA DE OCLUSIÓN DE CÁMARA (CARAS SUR <= 1.95m)
# ==============================================================================

func _construir_muros_y_pilastras(parent: Node3D) -> void:
	var muros_node := Node3D.new()
	muros_node.name = "MurosDodecagonales"
	parent.add_child(muros_node)

	var secuencias_bays: Dictionary = {
		0: ["pipes", "panel", "door", "door", "door", "panel", "pipes"],
		1: ["panel", "pipes", "door", "panel", "pipes", "door", "panel"],
		2: ["panel", "door", "pipes", "panel", "door", "pipes", "panel"],
		3: ["pipes", "panel", "pipes", "door", "panel", "pipes", "pipes"],
		4: ["panel", "pipes", "panel", "barrier", "barrier", "barrier", "barrier"],
		8: ["barrier", "barrier", "barrier", "barrier", "panel", "pipes", "panel"],
		9: ["pipes", "door", "panel", "pipes", "panel", "door", "pipes"],
		10: ["panel", "pipes", "door", "panel", "door", "pipes", "panel"],
		11: ["panel", "door", "pipes", "panel", "pipes", "door", "panel"],
	}

	var xs_bay: Array[float] = [-12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0]

	for k in range(NUM_LADOS):
		var theta := float(k) * (TAU / float(NUM_LADOS))
		var n := _normales_caras[k]
		var muro := StaticBody3D.new()
		muro.name = "Muro_%02d" % k
		muro.collision_layer = LAYER_MUROS_OBSTACULOS
		muro.collision_mask = 0
		muro.position = Vector3(n.x * APOTEMA_EXTERIOR, 0.0, n.y * APOTEMA_EXTERIOR)
		muro.rotation.y = -theta
		muros_node.add_child(muro)

		# Colisión invisible alta (10 m) detrás de cada cara para impedir fugas por knockback en todo el perímetro
		var col_wall := CollisionShape3D.new()
		var box_col := BoxShape3D.new()
		box_col.size = Vector3(28.6, 10.0, 2.6)
		col_wall.shape = box_col
		col_wall.position = Vector3(0.0, 5.0, -1.30)
		muro.add_child(col_wall)

		var col_sector := _color_sector_por_cara(k)

		# Caras Sur (5, 6, 7): Parapeto recortado <= 1.95 m de altura mundial (1.15 m sobre pasarela) para 0% oclusión de cámara
		if k in [5, 6, 7]:
			BunkerVisualKit.make_box(muro, "ParapetoBase", Vector3(28.0, 0.85, 0.72), BunkerVisualKit.get_concrete_base_mat(), Vector3(0.0, ALTURA_PASARELA + 0.425, -0.36))
			BunkerVisualKit.make_box(muro, "ParapetoCoping", Vector3(28.2, 0.30, 0.86), BunkerVisualKit.get_titanium_mat(), Vector3(0.0, ALTURA_PASARELA + 1.00, -0.36))
			var mat_tubo := BunkerVisualKit.make_emissive_mat(col_sector, 1.4, col_sector.darkened(0.35))
			BunkerVisualKit.make_box(muro, "TuboEmisivoSur", Vector3(27.2, 0.14, 0.16), mat_tubo, Vector3(0.0, ALTURA_PASARELA + 0.72, 0.06))
			continue

		# Respaldo sólido discreto detrás de módulos GLB (solo tan alto como permite la envolvente de cámara)
		var y_top := 6.40 if k in [11, 0, 1] else (5.30 if k in [10, 2] else (4.00 if k in [3, 9] else 3.20))
		if k in [4, 8]:
			# Transición Sur-Este (4) y Sur-Oeste (8): módulos medios + parapeto bajo
			BunkerVisualKit.make_box(muro, "ParapetoSurTrans", Vector3(28.0, 1.15, 0.72), BunkerVisualKit.get_armor_grey_mat(), Vector3(0.0, ALTURA_PASARELA + 0.575, -0.38))
		else:
			BunkerVisualKit.make_box(muro, "MuroRespaldo", Vector3(28.2, y_top, 0.90), BunkerVisualKit.get_chassis_mat(), Vector3(0.0, y_top * 0.5, -0.65))

		var bays: Array = secuencias_bays.get(k, ["panel", "pipes", "panel", "door", "panel", "pipes", "panel"])
		for bi in range(7):
			var tipo_bay: String = str(bays[bi])
			var lx: float = xs_bay[bi]
			if tipo_bay == "barrier":
				var bar := GLB_BARRIER.instantiate() as Node3D
				bar.position = Vector3(lx, ALTURA_PASARELA, 0.55)
				muro.add_child(bar)
				continue

			var escena_glb: PackedScene = GLB_WALL_PANEL if tipo_bay == "panel" else (GLB_WALL_DOOR if tipo_bay == "door" else GLB_WALL_PIPES)
			var inst := escena_glb.instantiate() as Node3D
			var y_glb := ALTURA_PASARELA
			if k in [3, 9]:
				y_glb = -0.50 # Techo a Y = 4.00 m manteniendo proporción 1.0x intacta
			elif k in [4, 8]:
				y_glb = -1.30 # Techo a Y = 3.20 m
			inst.position = Vector3(lx, y_glb, -0.15)
			muro.add_child(inst)
			_estilizar_modulo_pared(inst, k, tipo_bay, col_sector)

		# Cornisa superior para el fondo Norte (caras 11, 0, 1) + transformadores murales
		if k in [11, 0, 1]:
			BunkerVisualKit.make_box(muro, "CornisaNorte", Vector3(28.2, 1.10, 1.25), BunkerVisualKit.get_chassis_mat(), Vector3(0.0, 5.85, -0.35))
			if k in [11, 1]:
				for tx in [-6.0, 6.0]:
					var tr := GLB_TRANSFORMER.instantiate() as Node3D
					tr.position = Vector3(tx, 5.30, 0.45)
					muro.add_child(tr)
		elif k in [10, 2]:
			BunkerVisualKit.make_box(muro, "CopingLateral", Vector3(28.2, 0.22, 1.05), BunkerVisualKit.get_titanium_mat(), Vector3(0.0, 5.30, -0.25))
		elif k in [3, 9]:
			BunkerVisualKit.make_box(muro, "CopingMedio", Vector3(28.2, 0.22, 1.05), BunkerVisualKit.get_titanium_mat(), Vector3(0.0, 4.05, -0.25))

	# 12 Pilastras en los vértices del dodecágono para sellar juntas de 30°
	for v_idx in range(NUM_LADOS):
		var v2 := _vertices_ext[v_idx]
		var phi := float(v_idx) * (TAU / float(NUM_LADOS)) - (PI / float(NUM_LADOS))
		var es_sur := v_idx in [5, 6, 7, 8] # Vértices junto a caras Sur 5, 6, 7 (entre 135° y 225°)
		var altura_vis: float = 1.22 if es_sur else (3.30 if v_idx in [4, 9] else 5.00)

		var pilastra := StaticBody3D.new()
		pilastra.name = "PilastraVertice_%02d" % v_idx
		pilastra.collision_layer = LAYER_MUROS_OBSTACULOS
		pilastra.collision_mask = 0
		pilastra.position = Vector3(v2.x, 0.0, v2.y)
		pilastra.rotation.y = -phi
		muros_node.add_child(pilastra)

		var c_p := CollisionShape3D.new()
		var b_p := BoxShape3D.new()
		b_p.size = Vector3(1.45, 9.5, 1.45)
		c_p.shape = b_p
		c_p.position = Vector3(0.0, 4.75, 0.0)
		pilastra.add_child(c_p)

		BunkerVisualKit.make_box(pilastra, "Cuerpo", Vector3(1.35, altura_vis, 1.35), BunkerVisualKit.get_chassis_mat(), Vector3(0.0, ALTURA_PASARELA + altura_vis * 0.5, 0.0))
		BunkerVisualKit.make_box(pilastra, "CollarHazard", Vector3(1.42, 0.32, 1.42), _mat_hazard_zocalo, Vector3(0.0, ALTURA_PASARELA + 0.16, 0.0))
		BunkerVisualKit.make_box(pilastra, "TapaTitanio", Vector3(1.44, 0.18, 1.44), BunkerVisualKit.get_titanium_mat(), Vector3(0.0, ALTURA_PASARELA + altura_vis + 0.06, 0.0))

func _estilizar_modulo_pared(modulo: Node3D, face_k: int, tipo_bay: String, col_sector: Color) -> void:
	var energia: float = 1.85 if face_k in [11, 0, 1, 2, 3, 4] else 1.65
	var mat_em := BunkerVisualKit.make_emissive_mat(col_sector, energia, col_sector.darkened(0.45))
	if tipo_bay == "pipes":
		BunkerVisualKit.override_glb_hierarchy(modulo, {
			"Cylinder*": mat_em,
		}, false)
	elif tipo_bay == "door":
		BunkerVisualKit.override_glb_hierarchy(modulo, {
			"Torus*": BunkerVisualKit.get_titanium_mat() if face_k in [11, 0, 1] else BunkerVisualKit.get_copper_coil_mat(),
		}, false)
	else:
		BunkerVisualKit.override_glb_hierarchy(modulo, {
			"Cylinder*": BunkerVisualKit.get_copper_coil_mat(),
		}, false)
	# Franja emisiva horizontal discreta de sector legible en el alzado interior del muro
	var y_tira: float = 2.95 if face_k in [11, 0, 1, 10, 2] else (2.55 if face_k in [3, 9] else 2.25)
	BunkerVisualKit.make_box(modulo, "TiraLuminosaSector", Vector3(3.5, 0.12, 0.14), mat_em, Vector3(0.0, y_tira, 0.34))

# ==============================================================================
# PROPS E ILUMINACIÓN DIFERENCIADA POR SECTOR (NORTE / ESTE / SUR / OESTE)
# ==============================================================================

func _construir_props_e_iluminacion_sectores(parent: Node3D) -> void:
	var sect := Node3D.new()
	sect.name = "SectoresAmbientacion"
	parent.add_child(sect)

	# 1. Luces en los umbrales de las 4 rampas cardinales para lectura inmediata del carril
	var r_umbral: float = RAMPA_CARDINAL_INICIO - 0.40
	var pos_umbrales := [
		{"pos": Vector3(0.0, 1.65, -r_umbral), "col": BunkerVisualKit.COL_CRYO_BLUE},
		{"pos": Vector3(r_umbral, 1.65, 0.0), "col": BunkerVisualKit.COL_PLASMA_ORANGE},
		{"pos": Vector3(0.0, 1.65, r_umbral), "col": BunkerVisualKit.COL_NEON_GREEN},
		{"pos": Vector3(-r_umbral, 1.65, 0.0), "col": BunkerVisualKit.COL_CRIMSON_ALERT},
	]
	for i in range(pos_umbrales.size()):
		var l := OmniLight3D.new()
		l.name = "LuzUmbralRampa_%d" % i
		l.position = pos_umbrales[i]["pos"]
		l.light_color = pos_umbrales[i]["col"]
		l.light_energy = 1.65
		l.omni_range = 10.5
		l.shadow_enabled = false
		l.distance_fade_enabled = true
		l.distance_fade_begin = 28.0
		l.distance_fade_length = 8.0
		sect.add_child(l)

	# 2. Iluminación cromática de muro/parapeto por sector (escalada 1.75x)
	var luces_sector := [
		# NORTE (Cryo Gate)
		{"pos": Vector3(-23.6, 3.8, -42.8), "col": BunkerVisualKit.COL_CRYO_BLUE, "e": 2.1, "r": 18.0},
		{"pos": Vector3(0.0, 4.0, -49.0), "col": BunkerVisualKit.COL_CYAN_ELECTRIC, "e": 2.25, "r": 18.5},
		{"pos": Vector3(23.6, 3.8, -42.8), "col": BunkerVisualKit.COL_CRYO_BLUE, "e": 2.1, "r": 18.0},
		# ESTE (Reactor Core)
		{"pos": Vector3(42.8, 3.6, -23.6), "col": BunkerVisualKit.COL_PLASMA_ORANGE, "e": 2.1, "r": 18.0},
		{"pos": Vector3(49.0, 3.4, 0.0), "col": BunkerVisualKit.COL_PLASMA_ORANGE, "e": 2.2, "r": 18.5},
		{"pos": Vector3(42.8, 2.4, 23.6), "col": BunkerVisualKit.COL_HAZARD_YELLOW, "e": 1.85, "r": 16.5},
		# SUR (Med-Bay / Toxic Ward - energía moderada para proteger vista de cámara)
		{"pos": Vector3(23.6, 1.85, 43.4), "col": BunkerVisualKit.COL_NEON_GREEN, "e": 1.55, "r": 16.0},
		{"pos": Vector3(0.0, 1.85, 49.5), "col": BunkerVisualKit.COL_NEON_GREEN, "e": 1.60, "r": 16.0},
		{"pos": Vector3(-23.6, 1.85, 43.4), "col": BunkerVisualKit.COL_NEON_GREEN, "e": 1.55, "r": 16.0},
		# OESTE (Munition Forge)
		{"pos": Vector3(-42.8, 2.4, 23.6), "col": BunkerVisualKit.COL_CRIMSON_ALERT, "e": 1.85, "r": 16.5},
		{"pos": Vector3(-49.0, 3.4, 0.0), "col": BunkerVisualKit.COL_CRIMSON_ALERT, "e": 2.1, "r": 18.0},
		{"pos": Vector3(-42.8, 3.6, -23.6), "col": BunkerVisualKit.COL_PLASMA_ORANGE, "e": 1.9, "r": 17.5},
	]
	for idx in range(luces_sector.size()):
		var info: Dictionary = luces_sector[idx]
		var omni := OmniLight3D.new()
		omni.name = "LuzSector_%02d" % idx
		omni.position = info["pos"]
		omni.light_color = info["col"]
		omni.light_energy = info["e"]
		omni.omni_range = minf(float(info["r"]), 15.0)
		omni.shadow_enabled = false
		omni.distance_fade_enabled = true
		omni.distance_fade_begin = 32.0
		omni.distance_fade_length = 10.0
		sect.add_child(omni)

	# 3. Foco cenital sobre el Sector Norte
	var spot_gate := SpotLight3D.new()
	spot_gate.name = "SpotPuertaNorte"
	spot_gate.position = Vector3(0.0, 12.0, -43.0)
	spot_gate.rotation_degrees = Vector3(-76.0, 0.0, 0.0)
	spot_gate.light_color = BunkerVisualKit.COL_CRYO_BLUE
	spot_gate.light_energy = 1.9
	spot_gate.spot_range = 24.0
	spot_gate.spot_angle = 48.0
	spot_gate.shadow_enabled = false
	sect.add_child(spot_gate)

	# 4. Props perimetrales temáticos (anclados junto al muro a Y = 0.80 m sin invadir el carril)
	# --- NORTE: Cryo Gate ---
	_colocar_prop(sect, GLB_SERVER, Vector3(-19.6, ALTURA_PASARELA, -45.15), 30.0)
	_colocar_prop(sect, GLB_SERVER, Vector3(19.6, ALTURA_PASARELA, -45.15), -30.0)
	_colocar_prop(sect, GLB_TANK, Vector3(-11.2, ALTURA_PASARELA, -49.7), 10.0)
	_colocar_prop(sect, GLB_TANK, Vector3(11.2, ALTURA_PASARELA, -49.7), -10.0)
	_colocar_prop(sect, GLB_CABLE, Vector3(0.0, ALTURA_PASARELA + 0.015, -49.35), 0.0)
	for px in [-7.8, 7.8]:
		var p_norte := ESCENA_PILAR_ANTORCHA.instantiate()
		p_norte.position = Vector3(px, ALTURA_PASARELA, -49.35)
		if p_norte is CollisionObject3D:
			(p_norte as CollisionObject3D).collision_layer = LAYER_MUROS_OBSTACULOS
		var f_light := p_norte.get_node_or_null("OmniLight3D") as OmniLight3D
		if f_light != null:
			f_light.light_color = BunkerVisualKit.COL_CRYO_BLUE
		sect.add_child(p_norte)

	# --- ESTE: Reactor Core ---
	_colocar_prop(sect, GLB_GENERATOR, Vector3(49.0, ALTURA_PASARELA, -6.125), -90.0, true, Vector3(2.8, 2.2, 2.2))
	_colocar_prop(sect, GLB_GENERATOR, Vector3(42.0, ALTURA_PASARELA, -26.25), -60.0, true, Vector3(2.8, 2.2, 2.2))
	_colocar_prop(sect, GLB_TANK, Vector3(49.7, ALTURA_PASARELA, 6.65), -90.0)
	_colocar_prop(sect, GLB_TANK, Vector3(49.7, ALTURA_PASARELA, 9.45), -80.0)
	_colocar_prop(sect, GLB_CABLE, Vector3(46.55, ALTURA_PASARELA + 0.015, -6.125), -90.0)
	_colocar_prop(sect, GLB_OIL, Vector3(45.85, ALTURA_PASARELA + 0.015, 3.5), 15.0, false, Vector3.ZERO, Vector3(1.25, 1.0, 1.25))

	# --- SUR: Med-Bay / Toxic Ward (todo <= 1.90 m para cero bloqueo de cámara) ---
	_colocar_prop(sect, GLB_STRETCHER, Vector3(21.35, ALTURA_PASARELA, 44.45), 150.0)
	_colocar_prop(sect, GLB_STRETCHER, Vector3(-21.35, ALTURA_PASARELA, 44.45), -150.0)
	_colocar_prop(sect, GLB_BARREL, Vector3(-10.85, ALTURA_PASARELA, 49.7), 18.0)
	_colocar_prop(sect, GLB_BARREL, Vector3(-12.75, ALTURA_PASARELA, 49.0), 55.0)
	_colocar_prop(sect, GLB_BARREL, Vector3(10.85, ALTURA_PASARELA, 49.7), -25.0)
	_colocar_prop(sect, GLB_BARREL, Vector3(12.75, ALTURA_PASARELA, 49.0), -60.0)
	_colocar_prop(sect, GLB_ACID, Vector3(-11.55, ALTURA_PASARELA + 0.015, 48.3), 0.0, false, Vector3.ZERO, Vector3(1.15, 1.0, 1.15))
	_colocar_prop(sect, GLB_ACID, Vector3(11.55, ALTURA_PASARELA + 0.015, 48.3), 30.0, false, Vector3.ZERO, Vector3(1.15, 1.0, 1.15))
	_colocar_prop(sect, GLB_LOCKERS, Vector3(29.4, ALTURA_PASARELA, 39.9), 150.0)

	# --- OESTE: Munition Forge ---
	_colocar_prop(sect, GLB_CRATE, Vector3(-49.7, ALTURA_PASARELA, 6.3), 12.0)
	_colocar_prop(sect, GLB_CRATE, Vector3(-49.7, ALTURA_PASARELA + 0.70, 6.3), -14.0)
	_colocar_prop(sect, GLB_CRATE, Vector3(-49.7, ALTURA_PASARELA, -6.3), -18.0)
	_colocar_prop(sect, GLB_GENERATOR, Vector3(-48.65, ALTURA_PASARELA, -10.15), 90.0, true, Vector3(2.8, 2.2, 2.2))
	_colocar_prop(sect, GLB_LOCKERS, Vector3(-43.75, ALTURA_PASARELA, -26.95), 60.0)
	_colocar_prop(sect, GLB_OIL, Vector3(-46.2, ALTURA_PASARELA + 0.015, 0.0), 40.0, false, Vector3.ZERO, Vector3(1.2, 1.0, 1.2))

func _colocar_prop(
	parent: Node3D,
	escena: PackedScene,
	pos: Vector3,
	rot_y_deg: float,
	con_colision: bool = false,
	tam_col: Vector3 = Vector3.ZERO,
	escala: Vector3 = Vector3.ONE
) -> Node3D:
	if escena == null:
		return null
	var nodo := escena.instantiate() as Node3D
	if nodo == null:
		return null
	nodo.position = pos
	nodo.rotation_degrees.y = rot_y_deg
	if escala != Vector3.ONE:
		nodo.scale = escala
	parent.add_child(nodo)

	if con_colision and tam_col != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.collision_layer = LAYER_MUROS_OBSTACULOS
		body.collision_mask = 0
		body.position = pos
		body.rotation_degrees.y = rot_y_deg
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = tam_col
		col.shape = box
		col.position = Vector3(0.0, tam_col.y * 0.5, 0.0)
		body.add_child(col)
		parent.add_child(body)
	return nodo

func _color_sector_por_cara(face_k: int) -> Color:
	if face_k in [11, 0, 1]:
		return BunkerVisualKit.COL_CRYO_BLUE
	elif face_k in [2, 3, 4]:
		return BunkerVisualKit.COL_PLASMA_ORANGE
	elif face_k in [5, 6, 7]:
		return BunkerVisualKit.COL_NEON_GREEN
	return BunkerVisualKit.COL_CRIMSON_ALERT


# ==============================================================================
# COBERTURAS Y RUINAS ALEATORIAS POR RUN
# ==============================================================================

func _generar_obstaculos_run(parent: Node3D) -> void:
	centros_obstaculos_run.clear()
	_ruinas_pos_run.clear()
	_ruinas_rot_run.clear()

	# Registrar generadores perimetrales con colisión y pilares centrales de la escena
	centros_obstaculos_run.append(Vector2(49.0, -6.125))
	centros_obstaculos_run.append(Vector2(42.0, -26.25))
	centros_obstaculos_run.append(Vector2(-48.65, -10.15))
	# Reservar las bocas y salidas de todas las rampas cardinales y diagonales para que nunca se coloque una barricada frente a una rampa
	for r_res in _rampas_info:
		var b_res: Vector3 = r_res["boca"]
		var c_res: Vector3 = r_res["cresta"]
		centros_obstaculos_run.append(Vector2(b_res.x, b_res.z))
		centros_obstaculos_run.append(Vector2(c_res.x, c_res.z))
	var pilares_node: Node = get_node_or_null("Pilares")
	if pilares_node != null:
		for p_child in pilares_node.get_children():
			if p_child is Node3D:
				var p_pos: Vector3 = (p_child as Node3D).position
				centros_obstaculos_run.append(Vector2(p_pos.x, p_pos.z))

	var rng: RandomNumberGenerator = _obtener_rng_run(self)
	var cob_root := Node3D.new()
	cob_root.name = "CoberturasRun"
	parent.add_child(cob_root)

	var inicio_jugador := Vector2(0.0, 5.25)

	# 1. Calcular 4 nuevas posiciones para las Ruina1..4 del foso medio (1 por cuadrante)
	for q in range(4):
		var elegido := Vector3.ZERO
		var base_deg: float = float(q) * 90.0
		for _i in range(36):
			var ang_deg: float = base_deg + rng.randf_range(16.0, 74.0)
			var ang: float = deg_to_rad(ang_deg)
			var r: float = rng.randf_range(12.5, 25.5)
			var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
			var c2 := Vector2(cand.x, cand.z)
			if c2.distance_to(inicio_jugador) < 8.5:
				continue
			if esta_en_pendiente(cand.x, cand.z, 1.4):
				continue
			if obtener_altura_suelo(cand.x, cand.z) > 0.05:
				continue
			var ok := true
			for prev in centros_obstaculos_run:
				if c2.distance_to(prev) < 9.5:
					ok = false
					break
			if ok:
				elegido = cand
				break
		if elegido == Vector3.ZERO:
			var fb_ang: float = deg_to_rad(base_deg + 42.0)
			elegido = Vector3(sin(fb_ang) * 18.0, 0.0, -cos(fb_ang) * 18.0)
		_ruinas_pos_run.append(ajustar_a_suelo(elegido, 0.7))
		_ruinas_rot_run.append(rng.randf_range(0.0, 360.0))
		centros_obstaculos_run.append(Vector2(elegido.x, elegido.z))

	# 2. Generar 6 clústeres de cobertura en el anillo exterior del foso (r = 23.5..35.8 m)
	for idx in range(6):
		var c_foso := Vector3.ZERO
		var sec_deg: float = float(idx) * 60.0
		for _i in range(44):
			var ang: float = deg_to_rad(sec_deg + rng.randf_range(6.0, 54.0))
			var r: float = rng.randf_range(23.5, 35.8)
			var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
			var c2 := Vector2(cand.x, cand.z)
			if apotema_en_pos(cand.x, cand.z) >= (APOTEMA_FOSO - 2.4):
				continue
			if esta_en_pendiente(cand.x, cand.z, 3.6):
				continue
			if obtener_altura_suelo(cand.x, cand.z) > 0.05:
				continue
			var ok := true
			for prev in centros_obstaculos_run:
				if c2.distance_to(prev) < 9.5:
					ok = false
					break
			if ok:
				c_foso = cand
				break
		if c_foso != Vector3.ZERO:
			var pos_f: Vector3 = ajustar_a_suelo(c_foso, 0.0)
			_instanciar_cluster_cobertura(cob_root, "CoverFoso_%d" % idx, pos_f, rng, idx % 3)
			centros_obstaculos_run.append(Vector2(pos_f.x, pos_f.z))

	# 3. Generar 4 barricadas tácticas distribuidas en la pasarela perimetral (+0.80 m)
	for pi in range(4):
		var c_pasa := Vector3.ZERO
		var base_p: float = float(pi) * 90.0 + 18.0
		for _i in range(44):
			var ang: float = deg_to_rad(base_p + rng.randf_range(0.0, 54.0))
			var r: float = rng.randf_range(44.6, 48.2)
			var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
			var m_p: float = apotema_en_pos(cand.x, cand.z)
			if m_p < (APOTEMA_FOSO + 3.8) or m_p > (APOTEMA_EXTERIOR - 3.2):
				continue
			if esta_en_pendiente(cand.x, cand.z, 3.8):
				continue
			var c2 := Vector2(cand.x, cand.z)
			var ok := true
			for prev in centros_obstaculos_run:
				if c2.distance_to(prev) < 11.5:
					ok = false
					break
			if ok:
				c_pasa = cand
				break
		if c_pasa != Vector3.ZERO:
			var pos_p: Vector3 = ajustar_a_suelo(c_pasa, 0.0)
			_instanciar_cluster_cobertura(cob_root, "CoverPasarela_%d" % pi, pos_p, rng, (pi + 1) % 2)
			centros_obstaculos_run.append(Vector2(pos_p.x, pos_p.z))

func _instanciar_cluster_cobertura(parent: Node3D, nombre: String, pos: Vector3, rng: RandomNumberGenerator, variante: int) -> void:
	var holder := StaticBody3D.new()
	holder.name = nombre
	holder.collision_layer = LAYER_MUROS_OBSTACULOS
	holder.collision_mask = 0
	holder.position = pos
	holder.rotation_degrees.y = rng.randf_range(0.0, 360.0)
	parent.add_child(holder)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.35, 1.55, 1.85)
	col.shape = box
	col.position = Vector3(0.0, 0.775, 0.0)
	holder.add_child(col)

	var bar: Node3D = GLB_BARRIER.instantiate() as Node3D
	if bar != null:
		bar.position = Vector3(0.0, 0.0, 0.45)
		holder.add_child(bar)

	if variante == 0:
		var c1: Node3D = GLB_CRATE.instantiate() as Node3D
		if c1 != null:
			c1.position = Vector3(-0.55, 0.0, -0.40)
			c1.rotation_degrees.y = 18.0
			holder.add_child(c1)
		var b1: Node3D = GLB_BARREL.instantiate() as Node3D
		if b1 != null:
			b1.position = Vector3(0.75, 0.0, -0.35)
			holder.add_child(b1)
	elif variante == 1:
		var t1: Node3D = GLB_TANK.instantiate() as Node3D
		if t1 != null:
			t1.position = Vector3(0.0, 0.0, -0.45)
			t1.rotation_degrees.y = -25.0
			holder.add_child(t1)
	else:
		BunkerVisualKit.make_box(holder, "BloqueTactico", Vector3(1.85, 1.25, 0.78), BunkerVisualKit.get_armor_grey_mat(), Vector3(0.0, 0.625, -0.35))
		BunkerVisualKit.make_box(holder, "FranjaTactica", Vector3(1.75, 0.16, 0.84), _mat_hazard_zocalo, Vector3(0.0, 1.05, -0.35))

func _reubicar_ruinas_escena() -> void:
	if _ruinas_pos_run.size() < 4:
		return
	var padre: Node = get_parent()
	if padre == null:
		return
	var obstaculos: Node = padre.get_node_or_null("Obstaculos")
	if obstaculos == null:
		return
	for i in range(4):
		var ruina: Node3D = obstaculos.get_node_or_null("Ruina%d" % (i + 1)) as Node3D
		if ruina != null:
			ruina.global_position = _ruinas_pos_run[i]
			ruina.rotation_degrees.y = _ruinas_rot_run[i]
