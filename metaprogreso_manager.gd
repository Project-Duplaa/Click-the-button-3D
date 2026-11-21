class_name MetaprogresoManager
extends RefCounted

## MetaprogresoManager - Sistema de Progresión Permanente Roguelike (Versión 2)
## Persiste mejoras del árbol rúnico, banco de monedas, esquirlas astrales, prestigio,
## catálogo de bendiciones desbloqueadas, bestiario y némesis entre partidas.

const RUTA_GUARDADO: String = "user://progreso_roguelike.json"
const VERSION_ACTUAL: int = 2

const BENDICIONES_INICIALES: Array[String] = [
	"iman_gravitatorio",
	"lentes_critico",
	"sangre_coloso",
	"municion_perforante",
	"botas_relampago",
	"corazon_runico",
	"cadena_rayos",
	"anillo_fuego",
	"dagas_fantasma",
	"eco_clic"
]

static var inicializado: bool = false
static var version: int = VERSION_ACTUAL
static var mejoras_arbol: Dictionary = {} # id_nodo -> nivel
static var oro_banco: int = 0
static var clics_banco: int = 0
static var runs_jugadas: int = 0
static var victorias: int = 0
static var bajas_historicas: int = 0

# Nuevos campos persistentes Versión 2
static var nivel_prestigio: int = 0
static var esquirlas_astrales: int = 0
static var modo_run_pura: bool = false
static var bendiciones_desbloqueadas: Array = []
static var clases_desbloqueadas: Array = ["Novato", "Guerrero", "Cazador", "Mago"]
static var sinergias_descubiertas: Array = []
static var chasis_desbloqueados: Array = ["estandar"]
static var chasis_equipado: String = "estandar"
static var bestiario_bajas: Dictionary = {} # tipo_enemigo -> int
static var nemesis_activo: Dictionary = {
	"clase_enemigo": "",
	"nombre_titulo": "",
	"oro_robado": 0,
	"clics_robados": 0,
	"racha": 0,
	"activo": false
}
static var mejor_oleada_diaria: Dictionary = {
	"fecha_seed": 0,
	"bajas": 0,
	"tiempo": 0.0
}

static func asegurar_inicializado() -> void:
	if not inicializado:
		inicializado = true
		cargar()

static func cargar() -> void:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("[MetaprogresoManager] Perfil no encontrado. Creando perfil inicial v%d." % VERSION_ACTUAL)
		_establecer_valores_por_defecto()
		guardar()
		return
		
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if file == null:
		printerr("[MetaprogresoManager] Error al abrir archivo de guardado.")
		_establecer_valores_por_defecto()
		return
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		var ver_cargada: int = int(d.get("version", 1))
		
		# Campos heredados de v1
		var m = d.get("mejoras_arbol", {})
		mejoras_arbol = {}
		if m is Dictionary:
			for k in m.keys():
				mejoras_arbol[str(k)] = int(m[k])
		oro_banco = int(d.get("oro_banco", 0))
		clics_banco = int(d.get("clics_banco", 0))
		runs_jugadas = int(d.get("runs_jugadas", 0))
		victorias = int(d.get("victorias", 0))
		bajas_historicas = int(d.get("bajas_historicas", 0))
		
		# Carga de campos v2 con inicialización defensiva
		nivel_prestigio = int(d.get("nivel_prestigio", 0))
		esquirlas_astrales = int(d.get("esquirlas_astrales", 0))
		modo_run_pura = bool(d.get("modo_run_pura", false))
		
		var bend_cargadas = d.get("bendiciones_desbloqueadas", [])
		bendiciones_desbloqueadas = []
		if bend_cargadas is Array:
			for b in bend_cargadas:
				bendiciones_desbloqueadas.append(str(b))
		for b_ini in BENDICIONES_INICIALES:
			if not bendiciones_desbloqueadas.has(b_ini):
				bendiciones_desbloqueadas.append(b_ini)
				
		var clases_cargadas = d.get("clases_desbloqueadas", ["Novato", "Guerrero", "Cazador", "Mago"])
		clases_desbloqueadas = []
		if clases_cargadas is Array:
			for c in clases_cargadas:
				clases_desbloqueadas.append(str(c))
		for def_c in ["Novato", "Guerrero", "Cazador", "Mago"]:
			if not clases_desbloqueadas.has(def_c):
				clases_desbloqueadas.append(def_c)
				
		var sin_cargadas = d.get("sinergias_descubiertas", [])
		sinergias_descubiertas = []
		if sin_cargadas is Array:
			for s in sin_cargadas:
				sinergias_descubiertas.append(str(s))
				
		var chasis_cargados = d.get("chasis_desbloqueados", ["estandar"])
		chasis_desbloqueados = []
		if chasis_cargados is Array:
			for ch in chasis_cargados:
				chasis_desbloqueados.append(str(ch))
		if not chasis_desbloqueados.has("estandar"):
			chasis_desbloqueados.append("estandar")
		chasis_equipado = str(d.get("chasis_equipado", "estandar"))
		
		var bb = d.get("bestiario_bajas", {})
		bestiario_bajas = {}
		if bb is Dictionary:
			for k in bb.keys():
				bestiario_bajas[str(k)] = int(bb[k])
				
		var nem = d.get("nemesis_activo", {})
		if nem is Dictionary:
			nemesis_activo = {
				"clase_enemigo": str(nem.get("clase_enemigo", "")),
				"nombre_titulo": str(nem.get("nombre_titulo", "")),
				"oro_robado": int(nem.get("oro_robado", 0)),
				"clics_robados": int(nem.get("clics_robados", 0)),
				"racha": int(nem.get("racha", 0)),
				"activo": bool(nem.get("activo", false))
			}
		else:
			nemesis_activo = {"clase_enemigo": "", "nombre_titulo": "", "oro_robado": 0, "clics_robados": 0, "racha": 0, "activo": false}
			
		var od = d.get("mejor_oleada_diaria", {})
		if od is Dictionary:
			mejor_oleada_diaria = {
				"fecha_seed": int(od.get("fecha_seed", 0)),
				"bajas": int(od.get("bajas", 0)),
				"tiempo": float(od.get("tiempo", 0.0))
			}
		else:
			mejor_oleada_diaria = {"fecha_seed": 0, "bajas": 0, "tiempo": 0.0}
			
		version = VERSION_ACTUAL
		if ver_cargada < VERSION_ACTUAL:
			print("[MetaprogresoManager] Migración v%d -> v%d completada exitosamente. Guardando." % [ver_cargada, VERSION_ACTUAL])
			guardar()
		else:
			print("[MetaprogresoManager] Perfil v%d cargado: %d mejoras, %d oro, %d clics, %d esquirlas, prestigio Nv.%d." % [
				version, mejoras_arbol.size(), oro_banco, clics_banco, esquirlas_astrales, nivel_prestigio
			])
	else:
		_establecer_valores_por_defecto()
		guardar()

static func _establecer_valores_por_defecto() -> void:
	version = VERSION_ACTUAL
	mejoras_arbol = {}
	oro_banco = 0
	clics_banco = 0
	runs_jugadas = 0
	victorias = 0
	bajas_historicas = 0
	nivel_prestigio = 0
	esquirlas_astrales = 0
	modo_run_pura = false
	bendiciones_desbloqueadas = []
	for b in BENDICIONES_INICIALES:
		bendiciones_desbloqueadas.append(b)
	clases_desbloqueadas = ["Novato", "Guerrero", "Cazador", "Mago"]
	sinergias_descubiertas = []
	chasis_desbloqueados = ["estandar"]
	chasis_equipado = "estandar"
	bestiario_bajas = {}
	nemesis_activo = {"clase_enemigo": "", "nombre_titulo": "", "oro_robado": 0, "clics_robados": 0, "racha": 0, "activo": false}
	mejor_oleada_diaria = {"fecha_seed": 0, "bajas": 0, "tiempo": 0.0}

static func guardar() -> void:
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if file == null:
		printerr("[MetaprogresoManager] Error al escribir en ", RUTA_GUARDADO)
		return
		
	var data = {
		"version": VERSION_ACTUAL,
		"mejoras_arbol": mejoras_arbol,
		"oro_banco": oro_banco,
		"clics_banco": clics_banco,
		"runs_jugadas": runs_jugadas,
		"victorias": victorias,
		"bajas_historicas": bajas_historicas,
		"nivel_prestigio": nivel_prestigio,
		"esquirlas_astrales": esquirlas_astrales,
		"modo_run_pura": modo_run_pura,
		"bendiciones_desbloqueadas": bendiciones_desbloqueadas,
		"clases_desbloqueadas": clases_desbloqueadas,
		"sinergias_descubiertas": sinergias_descubiertas,
		"chasis_desbloqueados": chasis_desbloqueados,
		"chasis_equipado": chasis_equipado,
		"bestiario_bajas": bestiario_bajas,
		"nemesis_activo": nemesis_activo,
		"mejor_oleada_diaria": mejor_oleada_diaria
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

static func transferir_recursos_run(oro_run: int, clics_run: int, bajas_run: int, es_victoria: bool) -> Dictionary:
	asegurar_inicializado()
	runs_jugadas += 1
	if es_victoria:
		victorias += 1
	var ratio_oro: float = 1.0 if es_victoria else 0.45
	var ratio_clics: float = 1.0 if es_victoria else 0.50
	var oro_extraido: int = int(floor(float(max(0, oro_run)) * ratio_oro))
	var clics_extraidos: int = int(floor(float(max(0, clics_run)) * ratio_clics))
	oro_banco += oro_extraido
	clics_banco += clics_extraidos
	bajas_historicas += max(0, bajas_run)
	guardar()
	return {
		"oro_transferido": oro_extraido,
		"clics_transferidos": clics_extraidos,
		"ratio_oro": ratio_oro,
		"ratio_clics": ratio_clics,
		"oro_total": oro_banco,
		"clics_totales": clics_banco,
		"runs": runs_jugadas,
		"esquirlas": esquirlas_astrales,
		"prestigio": nivel_prestigio
	}

static func establecer_modo_run_pura(activo: bool) -> void:
	asegurar_inicializado()
	modo_run_pura = activo
	guardar()
	print("[MetaprogresoManager] Modo Run Pura: %s" % ("ACTIVO (0% metaprogreso)" if modo_run_pura else "Desactivado"))

# ==============================================================================
# FORMATEO NUMÉRICO UNIVERSAL (K, M, B)
# ==============================================================================
static func formatear_numero(valor: float) -> String:
	var abs_v = absf(valor)
	var prefijo = "-" if valor < 0 else ""
	if abs_v < 1000.0:
		return "%s%d" % [prefijo, int(round(abs_v))]
	elif abs_v < 1000000.0:
		return "%s%.2fK" % [prefijo, abs_v / 1000.0]
	elif abs_v < 1000000000.0:
		return "%s%.2fM" % [prefijo, abs_v / 1000000.0]
	else:
		return "%s%.2fB" % [prefijo, abs_v / 1000000000.0]

# ==============================================================================
# SISTEMA DE PRESTIGIO & RENACIMIENTO ASTRAL
# ==============================================================================
static func obtener_multiplicador_prestigio() -> float:
	asegurar_inicializado()
	if modo_run_pura:
		return 1.0
	return 1.0 + float(nivel_prestigio) * 0.15

static func obtener_niveles_totales_arbol() -> int:
	asegurar_inicializado()
	var total: int = 0
	for k in mejoras_arbol.keys():
		if str(k) == "nodo_origen":
			continue
		total += maxi(0, int(mejoras_arbol[k]))
	return total

static func puede_hacer_prestigio() -> bool:
	asegurar_inicializado()
	if int(mejoras_arbol.get("apex_keystone_ascension", 0)) > 0:
		return true
	var niveles_normales: int = 0
	for k in mejoras_arbol.keys():
		var id_str = str(k)
		if id_str == "nodo_origen":
			continue
		if not id_str.begins_with("inf_") and not id_str.begins_with("cosm_"):
			niveles_normales += int(mejoras_arbol[k])
	return niveles_normales >= 45

static func calcular_esquirlas_prestigio() -> int:
	asegurar_inicializado()
	var niveles_totales: int = obtener_niveles_totales_arbol()
	var base = 8 + niveles_totales + (victorias * 4) + int(floor(float(bajas_historicas) / 400.0))
	return max(8, base)

static func ejecutar_renacimiento_astral() -> int:
	asegurar_inicializado()
	if not puede_hacer_prestigio():
		return 0
	var esquirlas_ganadas = calcular_esquirlas_prestigio()
	nivel_prestigio += 1
	esquirlas_astrales += esquirlas_ganadas
	
	# Preservar nodos cósmicos e infinitos; reiniciar árbol estándar
	var nodos_preservados: Dictionary = {}
	for k in mejoras_arbol.keys():
		var id_str = str(k)
		if id_str.begins_with("inf_") or id_str.begins_with("cosm_"):
			nodos_preservados[id_str] = int(mejoras_arbol[k])
	nodos_preservados["nodo_origen"] = 1
	mejoras_arbol = nodos_preservados
	
	guardar()
	print("[MetaprogresoManager] Renacimiento Astral ejecutado. Prestigio Nv.%d, +%d Esquirlas Astrales." % [
		nivel_prestigio, esquirlas_ganadas
	])
	return esquirlas_ganadas

# ==============================================================================
# AYUDANTES DE DESBLOQUEO, BESTIARIO Y NÉMESIS
# ==============================================================================
static func desbloquear_bendicion(id: String) -> bool:
	asegurar_inicializado()
	if not bendiciones_desbloqueadas.has(id):
		bendiciones_desbloqueadas.append(id)
		guardar()
		print("[MetaprogresoManager] ¡Nueva Bendición Desbloqueada!: ", id)
		return true
	return false

static func esta_bendicion_desbloqueada(id: String) -> bool:
	asegurar_inicializado()
	return bendiciones_desbloqueadas.has(id)

static func registrar_sinergia_descubierta(id: String) -> void:
	asegurar_inicializado()
	if not sinergias_descubiertas.has(id):
		sinergias_descubiertas.append(id)
		guardar()
		print("[MetaprogresoManager] ¡Sinergia Mítica Descubierta!: ", id)

static func registrar_subclase_descubierta(nombre: String) -> void:
	asegurar_inicializado()
	if not clases_desbloqueadas.has(nombre):
		clases_desbloqueadas.append(nombre)
		guardar()
		print("[MetaprogresoManager] ¡Subclase de Gladiador Desbloqueada!: ", nombre)

static func desbloquear_chasis(id: String) -> bool:
	asegurar_inicializado()
	if not chasis_desbloqueados.has(id):
		chasis_desbloqueados.append(id)
		guardar()
		print("[MetaprogresoManager] ¡Nuevo Chasis Rúnico Desbloqueado!: ", id)
		return true
	return false

static func _normalizar_bestiario_id(tipo: String) -> String:
	var key := tipo.strip_edges().to_lower()
	match key:
		"parca_roja":
			return "parca"
		"centurion_corrupto":
			return "centurion"
		"coloso_bronce":
			return "coloso"
		"maestra_sanguinaria":
			return "maestra"
		_:
			return key

static func registrar_baja_bestiario(tipo: String) -> void:
	asegurar_inicializado()
	var key := _normalizar_bestiario_id(tipo)
	if key == "":
		return
	var act = int(bestiario_bajas.get(key, 0))
	bestiario_bajas[key] = act + 1

static func obtener_bono_bestiario(tipo: String) -> float:
	asegurar_inicializado()
	if modo_run_pura:
		return 0.0
	var key := _normalizar_bestiario_id(tipo)
	var bajas = int(bestiario_bajas.get(key, 0))
	return minf(0.20, floor(float(bajas) / 25.0) * 0.01)

static func procesar_baja_completa(enemigo: Node, jugador_ref: Node, tipo_id: String, es_jefe: bool = false) -> void:
	var key := _normalizar_bestiario_id(tipo_id)
	registrar_baja_bestiario(key)

	var es_nem: bool = false
	var oro_extra: int = 0
	var clics_extra: int = 0
	if enemigo != null and is_instance_valid(enemigo):
		if "es_nemesis" in enemigo and bool(enemigo.es_nemesis):
			es_nem = true
		elif enemigo.has_meta("es_nemesis") and bool(enemigo.get_meta("es_nemesis")):
			es_nem = true
		if "oro_nemesis_extra" in enemigo:
			oro_extra = int(enemigo.oro_nemesis_extra)
		elif enemigo.has_meta("oro_nemesis_extra"):
			oro_extra = int(enemigo.get_meta("oro_nemesis_extra"))
		if "clics_nemesis_extra" in enemigo:
			clics_extra = int(enemigo.clics_nemesis_extra)
		elif enemigo.has_meta("clics_nemesis_extra"):
			clics_extra = int(enemigo.get_meta("clics_nemesis_extra"))

	var pos_enem: Vector3 = enemigo.global_position if (enemigo is Node3D and is_instance_valid(enemigo)) else Vector3.ZERO
	var tree: SceneTree = enemigo.get_tree() if (enemigo != null and enemigo.is_inside_tree()) else null
	if tree == null and jugador_ref != null and jugador_ref.is_inside_tree():
		tree = jugador_ref.get_tree()

	if jugador_ref != null and is_instance_valid(jugador_ref):
		if jugador_ref.has_method("notificar_baja_enemigo"):
			jugador_ref.notificar_baja_enemigo(key, pos_enem)
		elif jugador_ref.has_method("registrar_baja"):
			jugador_ref.registrar_baja()

		if tree != null:
			var boton = tree.get_first_node_in_group("boton_movil")
			if boton != null and is_instance_valid(boton) and "chasis_actual" in boton and str(boton.chasis_actual) == "gravitatorio":
				if pos_enem.distance_to(boton.global_position) <= 6.5 and jugador_ref.has_method("ganar_xp"):
					jugador_ref.ganar_xp(4)

	if tree != null:
		var favor_mgr = tree.get_first_node_in_group("favor_emperador_manager")
		if favor_mgr != null and favor_mgr.has_method("notificar_baja"):
			favor_mgr.notificar_baja(key, es_jefe or es_nem)

	if es_nem:
		if jugador_ref != null and is_instance_valid(jugador_ref):
			if oro_extra > 0 and jugador_ref.has_method("recoger_drop"):
				jugador_ref.recoger_drop(0, oro_extra)
			if clics_extra > 0 and "clics_disponibles" in jugador_ref:
				jugador_ref.clics_disponibles += clics_extra
				if "clics_totales" in jugador_ref:
					jugador_ref.clics_totales += clics_extra
		if enemigo != null and enemigo.get_parent() != null:
			var esc_cofre = load("res://cofre_dorado.tscn")
			if esc_cofre != null:
				var c = esc_cofre.instantiate()
				enemigo.get_parent().add_child(c)
				c.global_position = pos_enem
		limpiar_nemesis_derrotado()
		if tree != null:
			var logros = tree.get_first_node_in_group("logros_manager")
			if logros != null and logros.has_method("registrar_baja_nemesis"):
				logros.registrar_baja_nemesis()
			var eventos = tree.get_first_node_in_group("eventos_coliseo_manager")
			if eventos != null and eventos.has_signal("nemesis_derrotado"):
				eventos.emit_signal("nemesis_derrotado")

static func registrar_nemesis_verdugo(clase_enemigo: String, titulo: String = "", oro_run: int = 0, clics_run: int = 0) -> void:
	asegurar_inicializado()
	var prev_racha = 0
	if nemesis_activo.get("clase_enemigo", "") == clase_enemigo and bool(nemesis_activo.get("activo", false)):
		prev_racha = int(nemesis_activo.get("racha", 0))
	nemesis_activo = {
		"clase_enemigo": clase_enemigo,
		"nombre_titulo": titulo,
		"oro_robado": int(nemesis_activo.get("oro_robado", 0)) + oro_run,
		"clics_robados": int(nemesis_activo.get("clics_robados", 0)) + clics_run,
		"racha": prev_racha + 1,
		"activo": true
	}
	guardar()
	print("[MetaprogresoManager] Némesis Activo: %s - %s (Racha: %d)" % [titulo, clase_enemigo, nemesis_activo["racha"]])

static func limpiar_nemesis_derrotado() -> void:
	asegurar_inicializado()
	if bool(nemesis_activo.get("activo", false)):
		nemesis_activo["activo"] = false
		guardar()
		print("[MetaprogresoManager] ¡Némesis Vengativo ha sido destruido en combate!")

static func agregar_esquirlas(cant: int) -> void:
	asegurar_inicializado()
	esquirlas_astrales += max(0, cant)
	guardar()

static func actualizar_record_diario(fecha_seed: int, bajas_run: int, tiempo_run: float) -> void:
	asegurar_inicializado()
	if bajas_run > int(mejor_oleada_diaria.get("bajas", 0)):
		mejor_oleada_diaria = {
			"fecha_seed": fecha_seed,
			"bajas": bajas_run,
			"tiempo": tiempo_run
		}
		guardar()

# ==============================================================================
# COMPRA Y ADQUISICIÓN DE NODOS (CON SOPORTE PARA ESQUIRLAS)
# ==============================================================================
static func puede_comprar(nodo: SkillNodeData) -> bool:
	asegurar_inicializado()
	var costos = nodo.calcular_costo(obtener_niveles_totales_arbol())
	var c_esq = int(costos.get("esquirlas", 0))
	if c_esq > 0 and esquirlas_astrales < c_esq:
		return false
	return oro_banco >= int(costos.get("oro", 0)) and clics_banco >= int(costos.get("clics", 0))

static func comprar_nodo(nodo_o_id, costo_oro: int = -1, costo_clics: int = -1, costo_esquirlas: int = 0) -> bool:
	asegurar_inicializado()
	var id = ""
	var c_oro = 0
	var c_clk = 0
	var c_esq = 0
	if nodo_o_id is SkillNodeData:
		id = nodo_o_id.id
		var costos = nodo_o_id.calcular_costo(obtener_niveles_totales_arbol())
		c_oro = int(costos.get("oro", 0))
		c_clk = int(costos.get("clics", 0))
		c_esq = int(costos.get("esquirlas", 0))
	else:
		id = str(nodo_o_id)
		c_oro = max(0, costo_oro)
		c_clk = max(0, costo_clics)
		c_esq = max(0, costo_esquirlas)
		
	if oro_banco < c_oro or clics_banco < c_clk or esquirlas_astrales < c_esq:
		return false
		
	oro_banco -= c_oro
	clics_banco -= c_clk
	esquirlas_astrales -= c_esq
	
	var lvl_actual = int(mejoras_arbol.get(id, 0))
	mejoras_arbol[id] = lvl_actual + 1
	if nodo_o_id is SkillNodeData:
		nodo_o_id.nivel_actual = mejoras_arbol[id]
	guardar()
	return true

# ==============================================================================
# APLICACIÓN DE BONIFICACIONES AL GLADIADOR
# ==============================================================================
static func aplicar_a_personaje(pj: CharacterBody3D) -> void:
	asegurar_inicializado()
	if pj == null:
		return

	if modo_run_pura:
		pj.mejoras_arbol = {}
		if pj.has_method("recalcular_stats_incrementales"):
			pj.recalcular_stats_incrementales()
		print("[MetaprogresoManager] Modo Run Pura activo (0% metaprogreso aplicado).")
		return

	pj.mejoras_arbol = mejoras_arbol.duplicate(true)
	if pj.has_method("recalcular_stats_incrementales"):
		pj.recalcular_stats_incrementales()
		print("[MetaprogresoManager] %d mejoras aplicadas (Prestige x%.2f)." % [mejoras_arbol.size(), obtener_multiplicador_prestigio()])
		return
		
	# 1. Aplicación de multiplicador de Prestigio
	var mult_prestigio = obtener_multiplicador_prestigio()
	if mult_prestigio > 1.0:
		if "bono_meta_dano_global" in pj:
			pj.bono_meta_dano_global *= mult_prestigio
		elif "bonus_dano_pct" in pj:
			pj.bonus_dano_pct += (mult_prestigio - 1.0)
		elif "dano" in pj:
			pj.dano *= mult_prestigio
			
		if "bono_meta_dano_clic" in pj:
			pj.bono_meta_dano_clic *= mult_prestigio
		elif "bonus_dano_clic_pct" in pj:
			pj.bonus_dano_clic_pct += (mult_prestigio - 1.0)

	# 2. Aplicación directa de Nodos Infinitos y Cósmicos de Tier 6
	var lvl_inf_armas = int(mejoras_arbol.get("inf_poder_armas", 0))
	if lvl_inf_armas > 0:
		if "bonus_dano_armas_pct" in pj:
			pj.bonus_dano_armas_pct += 0.05 * float(lvl_inf_armas)
		elif "dano" in pj:
			pj.dano *= (1.0 + 0.05 * float(lvl_inf_armas))
			
	var lvl_inf_clic = int(mejoras_arbol.get("inf_resonancia_clic", 0))
	if lvl_inf_clic > 0:
		if "bonus_dano_clic_pct" in pj:
			pj.bonus_dano_clic_pct += 0.08 * float(lvl_inf_clic)
			
	var lvl_inf_fortuna = int(mejoras_arbol.get("inf_fortuna_eterna", 0))
	if lvl_inf_fortuna > 0:
		if "oro_por_baja_pct" in pj:
			pj.oro_por_baja_pct += 0.02 * float(lvl_inf_fortuna)
		if "xp_ganada_pct" in pj:
			pj.xp_ganada_pct += 0.02 * float(lvl_inf_fortuna)
		if "suerte_arbol" in pj:
			pj.suerte_arbol += 0.02 * float(lvl_inf_fortuna)
		elif "suerte" in pj:
			pj.suerte += 0.02 * float(lvl_inf_fortuna)
			
	# Nodos Cósmicos Tier-6 adicionales
	var lvl_cosm_genesis = int(mejoras_arbol.get("cosm_keystone_genesis", 0))
	if lvl_cosm_genesis > 0:
		if "bonus_dano_pct" in pj:
			pj.bonus_dano_pct += 0.50
		if "proyectiles_extra" in pj:
			pj.proyectiles_extra += 2

	print("[MetaprogresoManager] %d mejoras aplicadas. Multiplicador de Prestigio: x%.2f" % [
		mejoras_arbol.size(), mult_prestigio
	])

static func resetear_todo_para_pruebas() -> void:
	_establecer_valores_por_defecto()
	guardar()
