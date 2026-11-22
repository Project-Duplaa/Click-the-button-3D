extends Node

const ArenaColiseo = preload("res://arena_coliseo.gd")
const ESCENA_DROP_ITEM = preload("res://drop_item.tscn")

## FortunaManager - Singleton Autoload del Sistema de Fortuna (Clicklike 3D)
## Gestiona el RNG con semilla por run, tiradas binarias con suerte no lineal,
## tiradas de rareza ponderadas con pity contra malas rachas, tablas de drops
## y el cálculo del Índice de Fortuna para la pantalla de fin de partida.

signal suerte_cambiada(nueva_suerte_total: float)
signal presagio_sorteado(presagio: Dictionary)

const COMUN: int = 0
const RARO: int = 1
const EPICO: int = 2
const LEGENDARIO: int = 3

# Tipos de drop (coordinados con el enum de drop_item.gd)
const DROP_ORO: int = 0
const DROP_EXP: int = 1
const DROP_CORAZON: int = 2
const DROP_TREBOL: int = 3
const DROP_IMAN: int = 4
const DROP_BOMBA: int = 5
const DROP_DENARIO: int = 6

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var semilla_actual: int = 0
var suerte: float = 0.0          # Suerte base de la run (presagio inicial, pactos...)
var suerte_oculta: float = 0.0   # Pity: +0.05 por cada Común, se reinicia al sacar Raro o mejor

var es_run_diaria: bool = false
var fecha_seed_diaria: int = 0

var suerte_total: float:
	get:
		return obtener_suerte_efectiva()

# Estado del Presagio inicial y modificadores de run
var presagio_id: String = "cielo_despejado"
var presagio_nombre: String = "Cielo Despejado"
var presagio_desc: String = "Sin alteraciones del destino."
var multiplicador_legendario: float = 3.0
var santuarios_extra: int = 0
var bonus_oro_anforas_pct: float = 0.0
var cofres_gladiador_abiertos: int = 0

# Métricas para el Índice de Fortuna
var _legendarios_obtenidos: int = 0
var _legendarios_esperados: float = 0.0
var _epicos_obtenidos: int = 0
var _epicos_esperados: float = 0.0
var _total_tiradas_rareza: int = 0
var _puntaje_obtenido: float = 0.0
var _puntaje_esperado: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	iniciar_run()

## Inicia o reinicia el estado de la run con una semilla fija o aleatoria
func iniciar_run(semilla: int = -1) -> void:
	if semilla == -1:
		semilla_actual = int(Time.get_unix_time_from_system()) ^ randi()
	else:
		semilla_actual = semilla
	rng.seed = semilla_actual
	suerte = 0.0
	suerte_oculta = 0.0
	es_run_diaria = false
	presagio_id = "cielo_despejado"
	presagio_nombre = "Cielo Despejado"
	presagio_desc = "Sin alteraciones del destino."
	multiplicador_legendario = 3.0
	santuarios_extra = 0
	bonus_oro_anforas_pct = 0.0
	cofres_gladiador_abiertos = 0
	_legendarios_obtenidos = 0
	_legendarios_esperados = 0.0
	_epicos_obtenidos = 0
	_epicos_esperados = 0.0
	_total_tiradas_rareza = 0
	_puntaje_obtenido = 0.0
	_puntaje_esperado = 0.0
	suerte_cambiada.emit(obtener_suerte_efectiva())
	print("[FortunaManager] Run iniciada. Semilla: %d" % semilla_actual)

## Sortea el Presagio de la run (suerte de salida con compensación en presagios adversos)
func tirar_presagio() -> Dictionary:
	var r: float = rng.randf()
	var delta_suerte: float = 0.0
	var icono: String = "☀️"
	var color_banner: Color = Color(0.75, 0.85, 0.98)

	# Reiniciar efectos de presagio previo antes de aplicar el nuevo
	multiplicador_legendario = 3.0
	santuarios_extra = 0
	bonus_oro_anforas_pct = 0.0

	if r < 0.15:
		presagio_id = "augurio_jupiter"
		presagio_nombre = "Augurio de Júpiter"
		presagio_desc = "+25% Suerte · +1 Santuario"
		delta_suerte = 0.25
		santuarios_extra = 1
		icono = "⚡"
		color_banner = Color(1.0, 0.84, 0.28)
	elif r < 0.70:
		presagio_id = "cielo_despejado"
		presagio_nombre = "Cielo Despejado"
		presagio_desc = "Suerte estándar · Sin efectos"
		delta_suerte = 0.0
		icono = "☀️"
		color_banner = Color(0.72, 0.88, 1.0)
	elif r < 0.90:
		presagio_id = "vuelo_cuervos"
		presagio_nombre = "Vuelo de Cuervos"
		presagio_desc = "-10% Suerte · +20% Oro en Ánforas"
		delta_suerte = -0.10
		bonus_oro_anforas_pct = 0.20
		icono = "🪶"
		color_banner = Color(0.86, 0.56, 0.34)
	else:
		presagio_id = "eclipse_pluton"
		presagio_nombre = "Eclipse de Plutón"
		presagio_desc = "-15% Suerte · Cartas Legendarias x3.5"
		delta_suerte = -0.15
		multiplicador_legendario = 3.5
		icono = "🌑"
		color_banner = Color(0.85, 0.32, 0.95)

	suerte += delta_suerte
	suerte_cambiada.emit(obtener_suerte_efectiva())
	var datos: Dictionary = {
		"id": presagio_id,
		"nombre": presagio_nombre,
		"descripcion": presagio_desc,
		"suerte_delta": delta_suerte,
		"icono": icono,
		"color": color_banner,
	}
	presagio_sorteado.emit(datos)
	print("[FortunaManager] Presagio: %s (%s)" % [presagio_nombre, presagio_desc])
	return datos

## Devuelve el multiplicador efectivo de una rareza (respetando Eclipse de Plutón x3.5)
func obtener_multiplicador_rareza(rareza: int) -> float:
	match rareza:
		RARO:
			return 1.5
		EPICO:
			return 2.0
		LEGENDARIO:
			return multiplicador_legendario
		_:
			return 1.0

## Suerte efectiva total: base + pity + extra + personaje + Tormento
func obtener_suerte_efectiva(extra_suerte: float = 0.0) -> float:
	var l: float = suerte + suerte_oculta + extra_suerte
	if is_inside_tree():
		var pj = get_tree().get_first_node_in_group("jugador")
		if pj != null and pj.has_method("obtener_suerte_personaje"):
			l += float(pj.obtener_suerte_personaje())
		var logros = get_tree().get_first_node_in_group("logros_manager")
		if logros != null and logros.has_method("obtener_multiplicadores_tormento"):
			var mt: Dictionary = logros.obtener_multiplicadores_tormento()
			l += float(mt.get("bono_suerte", 0.0))
	return clampf(l, -0.90, 50.0)

## Tirada binaria: p_final = 1 - (1 - p_base)^(1 + L). Nunca supera el 100 %.
func tirar(p_base: float, extra_suerte: float = 0.0) -> bool:
	if p_base <= 0.0:
		return false
	if p_base >= 1.0:
		return true
	var l: float = obtener_suerte_efectiva(extra_suerte)
	var expo: float = maxf(0.05, 1.0 + l)
	var p_final: float = clampf(1.0 - pow(1.0 - p_base, expo), 0.0, 1.0)
	return rng.randf() < p_final

## Tirada de rareza ponderada. Pesos base 70/22/7/1 multiplicados por (1+L)^k con k = 0, 1, 1.5, 2
func tirar_rareza(min_rareza: int = COMUN, registrar: bool = true) -> int:
	var l: float = obtener_suerte_efectiva()
	var b: float = maxf(0.05, 1.0 + l)

	var w_comun: float = 70.0
	var w_raro: float = 22.0 * b
	var w_epico: float = 7.0 * pow(b, 1.5)
	var w_leg: float = 1.0 * pow(b, 2.0)

	if min_rareza > COMUN:
		w_comun = 0.0
	if min_rareza > RARO:
		w_raro = 0.0
	if min_rareza > EPICO:
		w_epico = 0.0

	var w_total: float = w_comun + w_raro + w_epico + w_leg
	if w_total <= 0.0001:
		return min_rareza

	var r: float = rng.randf_range(0.0, w_total)
	var seleccion: int = COMUN
	if r < w_comun:
		seleccion = COMUN
	elif r < w_comun + w_raro:
		seleccion = RARO
	elif r < w_comun + w_raro + w_epico:
		seleccion = EPICO
	else:
		seleccion = LEGENDARIO

	if registrar:
		# Pity: la mala racha acumula suerte oculta
		if seleccion == COMUN:
			suerte_oculta += 0.05
		else:
			suerte_oculta = 0.0
		suerte_cambiada.emit(obtener_suerte_efectiva())

		# Registro para el Índice de Fortuna
		var p_leg: float = w_leg / w_total
		var p_epi: float = w_epico / w_total
		var p_rar: float = w_raro / w_total
		_total_tiradas_rareza += 1
		_legendarios_esperados += p_leg
		_epicos_esperados += p_epi
		if seleccion == LEGENDARIO:
			_legendarios_obtenidos += 1
		elif seleccion == EPICO:
			_epicos_obtenidos += 1
		var valor_obtenido: float = 0.0
		match seleccion:
			RARO: valor_obtenido = 1.0
			EPICO: valor_obtenido = 2.0
			LEGENDARIO: valor_obtenido = 4.0
		_puntaje_obtenido += valor_obtenido
		_puntaje_esperado += p_rar * 1.0 + p_epi * 2.0 + p_leg * 4.0

	return seleccion

## Lista de drops {tipo, valor} según el tipo de enemigo. Siempre incluye el drop base de oro/XP.
func tirar_tabla_drops(tipo_enemigo: String) -> Array:
	var drops: Array = []
	var t: String = tipo_enemigo.to_lower()

	# Drop base: conserva la econom?a original de cada enemigo (la suerte solo a?ade extras)
	match t:
		"guardia":
			var roll_g: float = rng.randf()
			if roll_g < 0.06:
				drops.append({"tipo": DROP_CORAZON, "valor": 20})
			elif roll_g < 0.26:
				drops.append({"tipo": DROP_ORO, "valor": 8})
			else:
				drops.append({"tipo": DROP_EXP, "valor": 10})
		"bruto":
			for _i in range(3):
				drops.append({"tipo": DROP_ORO, "valor": 5})
		"arquero":
			drops.append({"tipo": DROP_EXP, "valor": rng.randi_range(8, 14)})
		"berserker":
			drops.append({"tipo": DROP_ORO, "valor": rng.randi_range(6, 12)})
		"centinela_fase":
			for _i in range(2):
				drops.append({"tipo": DROP_ORO, "valor": 4})
			drops.append({"tipo": DROP_EXP, "valor": 14})
		"anulador_nucleo":
			for _i in range(3):
				drops.append({"tipo": DROP_ORO, "valor": 6})
			drops.append({"tipo": DROP_EXP, "valor": 24})
			drops.append({"tipo": DROP_DENARIO, "valor": rng.randi_range(1, 2)})
		"mini_jefe":
			for _i in range(8):
				drops.append({"tipo": DROP_ORO, "valor": 5})
			drops.append({"tipo": DROP_DENARIO, "valor": rng.randi_range(2, 4)})
		"parca", "jefe":
			for _i in range(8):
				drops.append({"tipo": DROP_ORO, "valor": rng.randi_range(20, 35)})
			for _j in range(6):
				drops.append({"tipo": DROP_EXP, "valor": rng.randi_range(30, 50)})
			drops.append({"tipo": DROP_DENARIO, "valor": rng.randi_range(6, 12)})
		"anfora":
			var mult_oro_anf: float = 1.0 + bonus_oro_anforas_pct
			var roll_a: float = rng.randf()
			if roll_a < 0.45:
				var oro_base: int = int(round(float(rng.randi_range(8, 16)) * mult_oro_anf))
				drops.append({"tipo": DROP_ORO, "valor": max(1, oro_base)})
			elif roll_a < 0.70:
				drops.append({"tipo": DROP_EXP, "valor": rng.randi_range(8, 14)})
			elif roll_a < 0.85:
				drops.append({"tipo": DROP_CORAZON, "valor": 20})
			else:
				drops.append({"tipo": DROP_DENARIO, "valor": 1})
			if tirar(0.18):
				var oro_extra: int = int(round(float(rng.randi_range(6, 12)) * mult_oro_anf))
				drops.append({"tipo": DROP_ORO, "valor": max(1, oro_extra)})
			if tirar(0.06):
				drops.append({"tipo": DROP_IMAN, "valor": 1})
			if tirar(0.05):
				drops.append({"tipo": DROP_BOMBA, "valor": 1})
			if tirar(0.06):
				drops.append({"tipo": DROP_TREBOL, "valor": 1})
			if tirar(0.10):
				drops.append({"tipo": DROP_DENARIO, "valor": 1})
			return drops
		"nucleo_dorado":
			if tirar(0.07):
				drops.append({"tipo": DROP_TREBOL, "valor": 1})
			elif tirar(0.20):
				drops.append({"tipo": DROP_DENARIO, "valor": 1})
			elif tirar(0.12):
				drops.append({"tipo": DROP_CORAZON, "valor": 15})
			elif tirar(0.10):
				drops.append({"tipo": DROP_IMAN, "valor": 1})
			else:
				drops.append({"tipo": DROP_ORO, "valor": rng.randi_range(6, 12)})
			return drops
		_: # espectro u otro enemigo est?ndar
			var roll_e: float = rng.randf()
			if roll_e < 0.05:
				drops.append({"tipo": DROP_CORAZON, "valor": 15})
			elif roll_e < 0.20:
				drops.append({"tipo": DROP_ORO, "valor": 5})
			else:
				drops.append({"tipo": DROP_EXP, "valor": 6})

	var es_jefe: bool = (t == "mini_jefe" or t == "parca" or t == "jefe")

	var base_tiene_corazon: bool = (t == "guardia" or t == "espectro" or t == "comun")
	if not base_tiene_corazon and tirar(0.40 if es_jefe else 0.03):
		drops.append({"tipo": DROP_CORAZON, "valor": 35 if es_jefe else 15})
	if tirar(0.10 if not es_jefe else 0.5):
		drops.append({"tipo": DROP_EXP, "valor": 6})
	if tirar(0.25 if es_jefe else 0.015):
		drops.append({"tipo": DROP_IMAN, "valor": 1})
	if tirar(0.20 if es_jefe else 0.01):
		drops.append({"tipo": DROP_TREBOL, "valor": 1})
	if tirar(0.35 if es_jefe else 0.08):
		drops.append({"tipo": DROP_DENARIO, "valor": rng.randi_range(1, 3)})
	if tirar(0.15 if es_jefe else 0.01):
		drops.append({"tipo": DROP_BOMBA, "valor": 1})

	return drops

## Instancia en el mundo los drops calculados, con dispersión radial
func soltar_drops(nodo_padre: Node, posicion: Vector3, tipo_enemigo: String = "comun") -> Array:
	var creados: Array = []
	if nodo_padre == null or not is_instance_valid(nodo_padre):
		return creados
	var escena = ESCENA_DROP_ITEM
	if escena == null:
		return creados

	var lista: Array = tirar_tabla_drops(tipo_enemigo)
	for d in lista:
		var item = escena.instantiate()
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.2, 1.2) if lista.size() <= 3 else rng.randf_range(0.5, 2.5)
		nodo_padre.add_child(item)
		item.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(posicion + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist), 1.4, 0.40)
		if item.has_method("iniciar"):
			item.iniciar(d["tipo"], d["valor"])
		creados.append(item)
	return creados

## Balance de fortuna de la run para la pantalla de fin
func obtener_indice_fortuna() -> Dictionary:
	var delta: float = _puntaje_obtenido - _puntaje_esperado
	var etiqueta: String = "Run Equilibrada"
	if delta >= 1.5:
		etiqueta = "Run Bendecida"
	elif delta <= -1.5:
		etiqueta = "Run Maldita"
	return {
		"puntaje": snappedf(delta, 0.01),
		"etiqueta": etiqueta,
		"semilla": semilla_actual,
		"presagio_id": presagio_id,
		"presagio_nombre": presagio_nombre,
		"presagio_desc": presagio_desc,
		"multiplicador_legendario": multiplicador_legendario,
		"legendarios_obtenidos": _legendarios_obtenidos,
		"legendarios_esperados": snappedf(_legendarios_esperados, 0.1),
		"epicos_obtenidos": _epicos_obtenidos,
		"epicos_esperados": snappedf(_epicos_esperados, 0.1),
		"total_tiradas": _total_tiradas_rareza
	}

## Inicia una run de desafío diario con semilla determinista basada en la fecha del sistema (YYYYMMDD)
func iniciar_run_diaria() -> int:
	var d := Time.get_date_dict_from_system()
	fecha_seed_diaria = int(d.get("year", 2026)) * 10000 + int(d.get("month", 1)) * 100 + int(d.get("day", 1))
	iniciar_run(fecha_seed_diaria)
	es_run_diaria = true
	print("[FortunaManager] Run diaria iniciada. Fecha/Semilla: %d" % fecha_seed_diaria)
	return fecha_seed_diaria
