class_name MetaprogresoManager
extends RefCounted

## MetaprogresoManager - Sistema de Progresión Permanente Roguelike
## Persiste mejoras del árbol rúnico, banco de monedas y estadísticas globales entre partidas.

const RUTA_GUARDADO = "user://progreso_roguelike.json"

static var inicializado: bool = false
static var mejoras_arbol: Dictionary = {} # id_nodo -> nivel
static var oro_banco: int = 0
static var clics_banco: int = 0
static var runs_jugadas: int = 0
static var victorias: int = 0
static var bajas_historicas: int = 0

static func asegurar_inicializado():
	if not inicializado:
		inicializado = true
		cargar()

static func cargar():
	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("[MetaprogresoManager] Archivo no existe aún. Creando perfil inicial.")
		mejoras_arbol = {}
		oro_banco = 0
		clics_banco = 0
		runs_jugadas = 0
		victorias = 0
		bajas_historicas = 0
		return
		
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if file == null:
		printerr("[MetaprogresoManager] Error al abrir archivo de guardado.")
		return
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err == OK and json.data is Dictionary:
		var d: Dictionary = json.data
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
		print("[MetaprogresoManager] Perfil roguelike cargado: %d mejoras, %d oro, %d clics, %d runs." % [
			mejoras_arbol.size(), oro_banco, clics_banco, runs_jugadas
		])

static func guardar():
	var file = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if file == null:
		printerr("[MetaprogresoManager] Error al escribir en ", RUTA_GUARDADO)
		return
		
	var data = {
		"mejoras_arbol": mejoras_arbol,
		"oro_banco": oro_banco,
		"clics_banco": clics_banco,
		"runs_jugadas": runs_jugadas,
		"victorias": victorias,
		"bajas_historicas": bajas_historicas
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[MetaprogresoManager] Progreso permanente guardado en disco con éxito.")

static func transferir_recursos_run(oro_run: int, clics_run: int, bajas_run: int, es_victoria: bool) -> Dictionary:
	asegurar_inicializado()
	runs_jugadas += 1
	if es_victoria:
		victorias += 1
	oro_banco += max(0, oro_run)
	clics_banco += max(0, clics_run)
	bajas_historicas += max(0, bajas_run)
	guardar()
	print("[MetaprogresoManager] Transferidos +%d Oro y +%d Clics de la run. Total banco: %d Oro, %d Clics." % [
		oro_run, clics_run, oro_banco, clics_banco
	])
	return {
		"oro_transferido": oro_run,
		"clics_transferidos": clics_run,
		"oro_total": oro_banco,
		"clics_totales": clics_banco,
		"runs": runs_jugadas
	}

static func puede_comprar(nodo: SkillNodeData) -> bool:
	asegurar_inicializado()
	var costos = nodo.calcular_costo()
	return oro_banco >= costos.oro and clics_banco >= costos.clics

static func comprar_nodo(id: String, costo_oro: int, costo_clics: int) -> bool:
	asegurar_inicializado()
	if oro_banco < costo_oro or clics_banco < costo_clics:
		return false
	oro_banco -= costo_oro
	clics_banco -= costo_clics
	var lvl_actual = mejoras_arbol.get(id, 0)
	mejoras_arbol[id] = lvl_actual + 1
	guardar()
	print("[MetaprogresoManager] Nodo '%s' mejorado a Nivel %d. Restante en banco: %d Oro, %d Clics." % [
		id, mejoras_arbol[id], oro_banco, clics_banco
	])
	return true

static func aplicar_a_personaje(pj: CharacterBody3D):
	asegurar_inicializado()
	if pj == null:
		return
	pj.mejoras_arbol = mejoras_arbol.duplicate(true)
	if pj.has_method("recalcular_stats_incrementales"):
		pj.recalcular_stats_incrementales()
	print("[MetaprogresoManager] %d mejoras permanentes aplicadas al gladiador." % mejoras_arbol.size())

static func resetear_todo_para_pruebas():
	mejoras_arbol = {}
	oro_banco = 0
	clics_banco = 0
	runs_jugadas = 0
	victorias = 0
	bajas_historicas = 0
	guardar()
