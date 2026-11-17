class_name CatalogoBendiciones
extends RefCounted

## CatalogoBendiciones — Catálogo Central de Bendiciones Roguelike, Sinergias y Bendiciones Corruptas
## Desarrollado para Clicklike 3D (Godot 4.7).
## Contiene 24 bendiciones (10 iniciales + 14 desbloqueables), 6 Sinergias Míticas y 6 Bendiciones Corruptas.

const RAREZAS = {
	"COMUN": { "peso": 60.0, "color": Color(0.80, 0.84, 0.90) },
	"RARA": { "peso": 28.0, "color": Color(0.25, 0.75, 1.0) },
	"EPICA": { "peso": 10.0, "color": Color(0.75, 0.35, 1.0) },
	"LEGENDARIA": { "peso": 2.0, "color": Color(1.0, 0.80, 0.20) },
	"MITICA": { "peso": 0.0, "color": Color(1.0, 0.25, 0.65) },
	"CORRUPTA": { "peso": 0.0, "color": Color(0.95, 0.15, 0.25) }
}

# 10 Bendiciones Iniciales Disponibles desde la primera partida
const BENDICIONES_INICIALES: Array[String] = [
	"celeridad_marcial",
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

const BENDICIONES: Dictionary = {
	"celeridad_marcial": {
		"id": "celeridad_marcial",
		"icono": "⚡",
		"nombre": "Celeridad Marcial",
		"descripcion": "+18% Cadencia de ataque (reduce el tiempo de espera entre ataques automáticos).",
		"rareza": "COMUN",
		"color": Color(0.95, 0.78, 0.25),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"cadena_rayos": {
		"id": "cadena_rayos",
		"icono": "⚡",
		"nombre": "Cadena de Rayos",
		"descripcion": "Los ataques y descargas encadenan rayos voltaicos a enemigos cercanos (+1 rebote por nivel).",
		"rareza": "RARA",
		"color": Color(0.25, 0.75, 1.0),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"sobrecarga_hilo": {
		"id": "sobrecarga_hilo",
		"icono": "🔗",
		"nombre": "Sobrecarga del Núcleo",
		"descripcion": "Las ondas y descargas de clic del Núcleo Rúnico infligen +35% de daño adicional.",
		"rareza": "EPICA",
		"color": Color(0.75, 0.35, 1.0),
		"categoria": "hilo",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"anillo_fuego": {
		"id": "anillo_fuego",
		"icono": "🔥",
		"nombre": "Anillo de Fuego",
		"descripcion": "Un aura ígnea orbital rodea al héroe (+25% daño de área y +0.8m de alcance cuerpo a cuerpo).",
		"rareza": "RARA",
		"color": Color(1.0, 0.45, 0.15),
		"categoria": "defensa",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"iman_gravitatorio": {
		"id": "iman_gravitatorio",
		"icono": "🧲",
		"nombre": "Imán Gravitatorio",
		"descripcion": "+3.0m Radio de recolección magnética de XP y Oro en la arena, y +10% velocidad de movimiento.",
		"rareza": "COMUN",
		"color": Color(0.2, 0.85, 1.0),
		"categoria": "utilidad",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"dagas_fantasma": {
		"id": "dagas_fantasma",
		"icono": "🗡️",
		"nombre": "Dagas Fantasma",
		"descripcion": "Cada clic efectuado en el Botón Móvil dispara una ráfaga radial de proyectiles espectrales.",
		"rareza": "RARA",
		"color": Color(0.35, 0.85, 0.95),
		"categoria": "clic",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"lentes_critico": {
		"id": "lentes_critico",
		"icono": "🎯",
		"nombre": "Lentes de Crítico",
		"descripcion": "+10% Probabilidad de Golpe Crítico y +35% Daño Crítico a todas las fuentes de daño.",
		"rareza": "COMUN",
		"color": Color(1.0, 0.85, 0.2),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"escudo_espinas": {
		"id": "escudo_espinas",
		"icono": "🛡️",
		"nombre": "Escudo de Espinas",
		"descripcion": "+20 Armadura plana y devuelve el 35% del daño recibido en una onda radial de esquirlas.",
		"rareza": "RARA",
		"color": Color(0.3, 0.9, 0.4),
		"categoria": "defensa",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"sangre_coloso": {
		"id": "sangre_coloso",
		"icono": "❤️",
		"nombre": "Sangre del Coloso",
		"descripcion": "+40 Vida Máxima y +2.5 Regeneración de vida por segundo de forma permanente.",
		"rareza": "COMUN",
		"color": Color(0.95, 0.25, 0.25),
		"categoria": "defensa",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"eco_clic": {
		"id": "eco_clic",
		"icono": "💫",
		"nombre": "Eco de Clic",
		"descripcion": "+20% Probabilidad de que cada clic cuente doble y detone una segunda onda de choque inmediata.",
		"rareza": "RARA",
		"color": Color(0.4, 0.7, 1.0),
		"categoria": "clic",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"fiebre_perpetua": {
		"id": "fiebre_perpetua",
		"icono": "🌡️",
		"nombre": "Fiebre Perpetua",
		"descripcion": "+30% Daño de clic y +15% probabilidad de crítico en ondas del Botón Móvil.",
		"rareza": "EPICA",
		"color": Color(1.0, 0.5, 0.1),
		"categoria": "clic",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"moneda_maldita": {
		"id": "moneda_maldita",
		"icono": "🪙",
		"nombre": "Moneda Maldita",
		"descripcion": "+30% Oro obtenido en la arena y +8% interés compuesto al superar cada oleada.",
		"rareza": "RARA",
		"color": Color(1.0, 0.8, 0.1),
		"categoria": "utilidad",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"canon_mercenario": {
		"id": "canon_mercenario",
		"icono": "💥",
		"nombre": "Cañón Mercenario",
		"descripcion": "+22% Daño total base y +4% adicional por cada 50 de Oro acumulado en tu reserva.",
		"rareza": "EPICA",
		"color": Color(1.0, 0.7, 0.15),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"municion_perforante": {
		"id": "municion_perforante",
		"icono": "🏹",
		"nombre": "Munición Perforante",
		"descripcion": "+2 Perforaciones en todos los proyectiles balísticos y mágicos, y +15% daño de armas.",
		"rareza": "COMUN",
		"color": Color(0.7, 0.85, 0.95),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"prisma_multidisparo": {
		"id": "prisma_multidisparo",
		"icono": "💠",
		"nombre": "Prisma Multidisparo",
		"descripcion": "+1 Proyectil adicional simultáneo disparado por todas las armas a distancia activas.",
		"rareza": "EPICA",
		"color": Color(0.85, 0.4, 1.0),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"botas_relampago": {
		"id": "botas_relampago",
		"icono": "⚡",
		"nombre": "Botas Relámpago",
		"descripcion": "+15% Velocidad de movimiento y mayor impulso evasivo en la arena.",
		"rareza": "COMUN",
		"color": Color(0.3, 0.9, 0.9),
		"categoria": "movilidad",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"nova_helada": {
		"id": "nova_helada",
		"icono": "❄️",
		"nombre": "Nova Helada",
		"descripcion": "Cada clic en el Botón Móvil expande +1.2m el radio de onda y ralentiza enemigos cercanos.",
		"rareza": "EPICA",
		"color": Color(0.45, 0.85, 1.0),
		"categoria": "clic",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"vampirismo_runico": {
		"id": "vampirismo_runico",
		"icono": "🩸",
		"nombre": "Vampirismo Rúnico",
		"descripcion": "Recuperas +4 HP de forma inmediata por cada enemigo abatido en la arena.",
		"rareza": "EPICA",
		"color": Color(0.85, 0.15, 0.35),
		"categoria": "defensa",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"supernova_inestable": {
		"id": "supernova_inestable",
		"icono": "☄️",
		"nombre": "Supernova Inestable",
		"descripcion": "+1.8m Radio de la onda de choque del Botón Móvil y +30% de fuerza de empuje a los enemigos.",
		"rareza": "LEGENDARIA",
		"color": Color(1.0, 0.35, 0.15),
		"categoria": "clic",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"pulso_estatico": {
		"id": "pulso_estatico",
		"icono": "🌩️",
		"nombre": "Pulso Estático",
		"descripcion": "+18% Cadencia de ataque y sobrecarga voltaica en todas las armas.",
		"rareza": "LEGENDARIA",
		"color": Color(0.9, 0.85, 0.25),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"corazon_runico": {
		"id": "corazon_runico",
		"icono": "🔷",
		"nombre": "Corazón Rúnico",
		"descripcion": "Genera una barrera de Escudo de Almas de +45 HP que absorbe daño antes que tu vida.",
		"rareza": "COMUN",
		"color": Color(0.2, 0.7, 1.0),
		"categoria": "defensa",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"sed_de_sangre": {
		"id": "sed_de_sangre",
		"icono": "⚔️",
		"nombre": "Sed de Sangre",
		"descripcion": "+14% Velocidad de ataque y +15% daño de armas cuerpo a cuerpo y a distancia.",
		"rareza": "RARA",
		"color": Color(0.9, 0.2, 0.3),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"meteoro_orbital": {
		"id": "meteoro_orbital",
		"icono": "🌠",
		"nombre": "Meteoro Orbital",
		"descripcion": "+35% Daño de armas y cada clic en el Botón Móvil detona un corte sísmico alrededor del héroe.",
		"rareza": "LEGENDARIA",
		"color": Color(1.0, 0.4, 0.1),
		"categoria": "ataque",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"paso_etereo": {
		"id": "paso_etereo",
		"icono": "💨",
		"nombre": "Paso Etéreo",
		"descripcion": "+10% Probabilidad de esquiva perfecta, +0.4s de invulnerabilidad post-golpe y +12% velocidad.",
		"rareza": "LEGENDARIA",
		"color": Color(0.6, 0.9, 1.0),
		"categoria": "movilidad",
		"max_nivel": 5,
		"es_sinergia": false
	},
	"toque_de_midas": {
		"id": "toque_de_midas",
		"icono": "👑",
		"nombre": "Toque de Midas",
		"descripcion": "+25% Probabilidad de que cada clic genere oro puro adicional y +25% de experiencia.",
		"rareza": "LEGENDARIA",
		"color": Color(1.0, 0.85, 0.15),
		"categoria": "utilidad",
		"max_nivel": 5,
		"es_sinergia": false
	}
}

const SINERGIAS_DUALES: Dictionary = {
	"sinergia_jaula_faraday": {
		"id": "sinergia_jaula_faraday",
		"icono": "⚡",
		"nombre": "Fusión: Jaula de Faraday",
		"descripcion": "Las pulsaciones del Núcleo desatan descargas eléctricas masivas (+75% daño de clic y +2 clics por pulsación).",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["cadena_rayos", "sobrecarga_hilo"]
	},
	"sinergia_estrella_enana": {
		"id": "sinergia_estrella_enana",
		"icono": "🌟",
		"nombre": "Fusión: Estrella Enana",
		"descripcion": "El Anillo de Fuego colapsa en un vórtice gravitacional que arrastra drops y calcina a quemarropa.",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["anillo_fuego", "iman_gravitatorio"]
	},
	"sinergia_verdugo_cortes": {
		"id": "sinergia_verdugo_cortes",
		"icono": "🗡️",
		"nombre": "Fusión: Verdugo de Sombras",
		"descripcion": "Las dagas espectrales impactan con daño crítico letal garantizado y rebotan entre 3 objetivos.",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["dagas_fantasma", "lentes_critico"]
	},
	"sinergia_bastion_inmortal": {
		"id": "sinergia_bastion_inmortal",
		"icono": "🛡️",
		"nombre": "Fusión: Bastión Inmortal",
		"descripcion": "Al recibir daño detona un cataclismo de esquirlas protectoras y la regeneración de vida se triplica.",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["escudo_espinas", "sangre_coloso"]
	},
	"sinergia_singularidad_cursor": {
		"id": "sinergia_singularidad_cursor",
		"icono": "🌀",
		"nombre": "Fusión: Singularidad del Cursor",
		"descripcion": "Durante Fiebre u Overdrive, cada clic detona una singularidad gravitatoria que comprime y aniquila.",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["eco_clic", "fiebre_perpetua"]
	},
	"sinergia_artilleria_midas": {
		"id": "sinergia_artilleria_midas",
		"icono": "👑",
		"nombre": "Fusión: Artillería de Midas",
		"descripcion": "Disparas ráfagas de esquirlas de oro puro y cada baja suelta monedas rúnicas potenciadas.",
		"rareza": "MITICA",
		"color": Color(1.0, 0.25, 0.65),
		"categoria": "sinergia",
		"max_nivel": 1,
		"es_sinergia": true,
		"requisitos": ["moneda_maldita", "canon_mercenario"]
	}
}

# ==============================================================================
# LAS 6 BENDICIONES CORRUPTAS (ALTO RIESGO / PODER COLOSAL)
# ==============================================================================
const BENDICIONES_CORRUPTAS: Dictionary = {
	"corrupta_pacto_cristal": {
		"id": "corrupta_pacto_cristal",
		"nombre": "Pacto del Cristal Quebrantado",
		"descripcion": "x2.2 Daño de Clic, +40% Daño Global y +25% Crítico | MALDICIÓN: -40% Vida Máxima.",
		"icono": "🔮🩸",
		"maldicion": "-40% Vida Máxima permanente en la run.",
		"bendicion": "x2.2 Daño de Clic, +40% Daño Global y +25% Crítico.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	},
	"corrupta_hilo_corto": {
		"id": "corrupta_hilo_corto",
		"nombre": "Hilo Corto de Fisión",
		"descripcion": "x2.5 Daño Onda/Hilo y +35% Cadencia Global | MALDICIÓN: Órbita del Botón <= 5.5m.",
		"icono": "⚡✂️",
		"maldicion": "La órbita del Botón queda limitada a máximo 5.5m.",
		"bendicion": "x2.5 Daño Onda/Hilo y +35% Cadencia de Ataque.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	},
	"corrupta_avaricia_sangrienta": {
		"id": "corrupta_avaricia_sangrienta",
		"nombre": "Avaricia Sangrienta",
		"descripcion": "+120% Oro, +40% Daño Global y +3 HP/baja | MALDICIÓN: Pierdes 1 HP/s.",
		"icono": "🪙🩸",
		"maldicion": "Pierdes 1 HP cada segundo transcurrido en combate.",
		"bendicion": "+120% Oro de bajas/drops, +40% Daño Global y +3 HP por baja.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	},
	"corrupta_coloso_inamovible": {
		"id": "corrupta_coloso_inamovible",
		"nombre": "Coloso Inamovible",
		"descripcion": "+120 Armadura, Inmune a Empuje y Ondas al caminar | MALDICIÓN: Sin Dash y -25% Vel.",
		"icono": "🗿⛓️",
		"maldicion": "Sin Dash Táctico y -25% Velocidad de Movimiento.",
		"bendicion": "+120 Armadura Plana, inmunidad total a empuje y ondas expansivas al caminar.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	},
	"corrupta_destino_caotico": {
		"id": "corrupta_destino_caotico",
		"nombre": "Destino Caótico",
		"descripcion": "Cada 20s rota +50%..+180% en Daño, Cadencia o Crítico | MALDICIÓN: -0.35 Suerte.",
		"icono": "💥🎲",
		"maldicion": "-0.35 a la Suerte general de la run.",
		"bendicion": "Cada 20s rota un bono aleatorio masivo (+50%..+180%) en Daño, Cadencia o Crítico.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	},
	"corrupta_sobrecarga_sin_freno": {
		"id": "corrupta_sobrecarga_sin_freno",
		"nombre": "Sobrecarga Sin Freno",
		"descripcion": "Frenesí dura 24s con x5 Clics y Oro | MALDICIÓN: Cadenas cada 12 clics.",
		"icono": "🔥⚡",
		"maldicion": "El Núcleo se encadena cada 12 clics (en lugar de 20).",
		"bendicion": "Frenesí dura 24s y multiplica Clics y Oro x5.",
		"rareza": "CORRUPTA",
		"color": Color(0.95, 0.15, 0.25),
		"categoria": "corrupta",
		"max_nivel": 1,
		"es_sinergia": false
	}
}

static func _obtener_nivel_actual(bendiciones_actuales: Dictionary, id: String) -> int:
	if not bendiciones_actuales.has(id):
		return 0
	var val = bendiciones_actuales[id]
	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		return int(val)
	elif typeof(val) == TYPE_DICTIONARY and val.has("nivel"):
		return int(val["nivel"])
	return 0

static func verificar_sinergia_desbloqueable(id_sinergia: String, bendiciones_actuales: Dictionary) -> bool:
	if not SINERGIAS_DUALES.has(id_sinergia):
		return false
	var sinergia = SINERGIAS_DUALES[id_sinergia]
	var nivel_sinergia = _obtener_nivel_actual(bendiciones_actuales, id_sinergia)
	if nivel_sinergia >= int(sinergia["max_nivel"]):
		return false
	var reqs = sinergia["requisitos"] as Array
	for req_id in reqs:
		if _obtener_nivel_actual(bendiciones_actuales, str(req_id)) < 1:
			return false
	return true

## Alias compatible con ClickHUD
static func obtener_3_opciones(bendiciones_actuales: Dictionary, suerte: float = 0.0) -> Array:
	return obtener_opciones_nivel(bendiciones_actuales, suerte)

## Selecciona 3 opciones distintas aleatorias para la pantalla de subida de nivel,
## FILTRANDO estrictamente por las bendiciones desbloqueadas en MetaprogresoManager.
static func obtener_opciones_nivel(bendiciones_actuales: Dictionary, suerte: float = 0.0) -> Array:
	MetaprogresoManager.asegurar_inicializado()
	var seleccionadas: Array = []
	var ids_elegidos: Dictionary = {}

	# 1. Comprobar Sinergias Duales Míticas
	var sinergias_posibles: Array = []
	for id_sin in SINERGIAS_DUALES.keys():
		if verificar_sinergia_desbloqueable(id_sin, bendiciones_actuales):
			sinergias_posibles.append(id_sin)

	if sinergias_posibles.size() > 0 and randf() < 0.65:
		sinergias_posibles.shuffle()
		var id_sinergia_escogida = sinergias_posibles[0]
		var datos_sin = SINERGIAS_DUALES[id_sinergia_escogida].duplicate(true)
		var nivel_actual = _obtener_nivel_actual(bendiciones_actuales, id_sinergia_escogida)
		datos_sin["nivel_actual"] = nivel_actual
		datos_sin["nivel_nuevo"] = nivel_actual + 1
		datos_sin["desc"] = datos_sin.get("descripcion", "")
		seleccionadas.append(datos_sin)
		ids_elegidos[id_sinergia_escogida] = true
		MetaprogresoManager.registrar_sinergia_descubierta(id_sinergia_escogida)

	var mult_suerte = 1.0 + maxf(suerte, 0.0) * 0.45
	var pesos_rareza = {
		"COMUN": maxf(15.0, RAREZAS["COMUN"]["peso"] / mult_suerte),
		"RARA": RAREZAS["RARA"]["peso"] * mult_suerte,
		"EPICA": RAREZAS["EPICA"]["peso"] * (mult_suerte * 1.35),
		"LEGENDARIA": RAREZAS["LEGENDARIA"]["peso"] * (mult_suerte * 1.8)
	}

	var disponibles_por_rareza = {
		"COMUN": [],
		"RARA": [],
		"EPICA": [],
		"LEGENDARIA": []
	}

	for id_bend in BENDICIONES.keys():
		if ids_elegidos.has(id_bend):
			continue
		# FILTRO METAPROGRESO: solo si está desbloqueada permanentemente
		if not MetaprogresoManager.esta_bendicion_desbloqueada(id_bend):
			continue
		var nivel_act = _obtener_nivel_actual(bendiciones_actuales, id_bend)
		var max_niv = int(BENDICIONES[id_bend]["max_nivel"])
		if nivel_act < max_niv:
			var rareza = BENDICIONES[id_bend]["rareza"]
			if disponibles_por_rareza.has(rareza):
				disponibles_por_rareza[rareza].append(id_bend)

	# Salvaguarda: si por alguna razón el pool desbloqueado no llena 3 opciones,
	# recurrir al mazo inicial de 10 cartas
	var total_disponibles = 0
	for r in disponibles_por_rareza.keys():
		total_disponibles += disponibles_por_rareza[r].size()
	if total_disponibles == 0:
		for id_ini in BENDICIONES_INICIALES:
			if ids_elegidos.has(id_ini):
				continue
			var rz = BENDICIONES[id_ini]["rareza"]
			if disponibles_por_rareza.has(rz):
				disponibles_por_rareza[rz].append(id_ini)

	var intentos_seguridad = 0
	while seleccionadas.size() < 3 and intentos_seguridad < 60:
		intentos_seguridad += 1

		var peso_total = 0.0
		for r in ["COMUN", "RARA", "EPICA", "LEGENDARIA"]:
			if disponibles_por_rareza[r].size() > 0:
				peso_total += pesos_rareza[r]

		if peso_total <= 0.001:
			break

		var tirada = randf_range(0.0, peso_total)
		var rareza_ganadora = "COMUN"
		var acum = 0.0
		for r in ["COMUN", "RARA", "EPICA", "LEGENDARIA"]:
			if disponibles_por_rareza[r].size() > 0:
				acum += pesos_rareza[r]
				if tirada <= acum:
					rareza_ganadora = r
					break

		var lista = disponibles_por_rareza[rareza_ganadora]
		if lista.size() == 0:
			continue

		var idx = randi() % lista.size()
		var id_elegido = lista[idx]
		lista.remove_at(idx)
		ids_elegidos[id_elegido] = true

		var datos = BENDICIONES[id_elegido].duplicate(true)
		var niv_act = _obtener_nivel_actual(bendiciones_actuales, id_elegido)
		datos["nivel_actual"] = niv_act
		datos["nivel_nuevo"] = niv_act + 1
		datos["desc"] = datos.get("descripcion", "")
		seleccionadas.append(datos)

	return seleccionadas

# ==============================================================================
# AYUDANTES PARA BENDICIONES CORRUPTAS
# ==============================================================================
static func obtener_opciones_corruptas(poseidas: Array = [], cantidad: int = 3) -> Array:
	var pool: Array = []
	for id_c in BENDICIONES_CORRUPTAS.keys():
		if not poseidas.has(id_c):
			pool.append(BENDICIONES_CORRUPTAS[id_c].duplicate(true))
	pool.shuffle()
	return pool.slice(0, min(cantidad, pool.size()))

static func obtener_bendicion_corrupta(id: String) -> Dictionary:
	if BENDICIONES_CORRUPTAS.has(id):
		return BENDICIONES_CORRUPTAS[id].duplicate(true)
	return {}

static func obtener_bendicion(id: String) -> Dictionary:
	if BENDICIONES.has(id):
		return BENDICIONES[id]
	if SINERGIAS_DUALES.has(id):
		return SINERGIAS_DUALES[id]
	if BENDICIONES_CORRUPTAS.has(id):
		return BENDICIONES_CORRUPTAS[id]
	return {}

static func obtener_datos_bendicion(id: String) -> Dictionary:
	return obtener_bendicion(id)

static func obtener_todas() -> Dictionary:
	return BENDICIONES

static func obtener_sinergias() -> Dictionary:
	return SINERGIAS_DUALES

static func verificar_nuevas_sinergias(bendiciones_actuales: Dictionary, sinergias_activas: Array) -> Array:
	var nuevas: Array = []
	for id_sin in SINERGIAS_DUALES.keys():
		if not sinergias_activas.has(id_sin) and verificar_sinergia_desbloqueable(id_sin, bendiciones_actuales):
			var datos_sin = SINERGIAS_DUALES[id_sin].duplicate(true)
			nuevas.append(datos_sin)
			MetaprogresoManager.registrar_sinergia_descubierta(id_sin)
	return nuevas
