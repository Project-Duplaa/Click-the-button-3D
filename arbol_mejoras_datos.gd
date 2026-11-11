class_name ArbolMejorasDatos
extends RefCounted

## ArbolMejorasDatos - Catálogo y Lógica del Árbol de Ascensión Incremental
## Define todas las mejoras desbloqueables, sus ramas (Monedas, Clics, Híbrido),
## requisitos de árbol y fórmulas de costo exponencial.

const RAMA_TODAS = "todas"
const RAMA_MONEDAS = "monedas"
const RAMA_CLICKS = "clicks"
const RAMA_HIBRIDO = "hibrido"

const MEJORAS: Dictionary = {
	# ==========================================================================
	# RAMA 1: COMERCIO CON MONEDAS (Arsenal, Supervivencia y Economía)
	# ==========================================================================
	"mon_dano": {
		"id": "mon_dano",
		"nombre": "Afilado de Acero",
		"icono": "⚔️",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Templado de armas. Aumenta el daño base de todos tus ataques.",
		"costo_monedas_base": 8,
		"costo_clicks_base": 0,
		"factor_monedas": 1.45,
		"factor_clicks": 1.0,
		"max_nivel": 10,
		"requisitos": {},
		"bono_texto": "+18% Daño por nivel"
	},
	"mon_vida": {
		"id": "mon_vida",
		"nombre": "Coraza del Coliseo",
		"icono": "🛡️",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Armadura de gladiador. Incrementa la Vida Máxima y cura +25 HP al instante.",
		"costo_monedas_base": 10,
		"costo_clicks_base": 0,
		"factor_monedas": 1.40,
		"factor_clicks": 1.0,
		"max_nivel": 10,
		"requisitos": {},
		"bono_texto": "+25 HP Máx y cura inmediata"
	},
	"mon_vel": {
		"id": "mon_vel",
		"nombre": "Botas de Hermes",
		"icono": "👟",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Calzado alado. Aumenta la velocidad al caminar y correr en la arena.",
		"costo_monedas_base": 16,
		"costo_clicks_base": 0,
		"factor_monedas": 1.48,
		"factor_clicks": 1.0,
		"max_nivel": 5,
		"requisitos": {"mon_dano": 1},
		"bono_texto": "+10% Velocidad de movimiento"
	},
	"mon_oro": {
		"id": "mon_oro",
		"nombre": "Codicia del Gladiador",
		"icono": "🪙",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Ojo experto para el botín. Aumenta el oro ganado de bajas y cofres.",
		"costo_monedas_base": 22,
		"costo_clicks_base": 0,
		"factor_monedas": 1.55,
		"factor_clicks": 1.0,
		"max_nivel": 5,
		"requisitos": {"mon_vida": 1},
		"bono_texto": "+25% Oro recolectado"
	},
	"mon_cadencia": {
		"id": "mon_cadencia",
		"nombre": "Frenesí Marcial",
		"icono": "⚡",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Cadencia acelerada. Reduce el intervalo entre golpes automáticos.",
		"costo_monedas_base": 40,
		"costo_clicks_base": 0,
		"factor_monedas": 1.60,
		"factor_clicks": 1.0,
		"max_nivel": 5,
		"requisitos": {"mon_dano": 3, "mon_vel": 2},
		"bono_texto": "+12% Velocidad de ataque"
	},
	"mon_pasivo": {
		"id": "mon_pasivo",
		"nombre": "Tributo Minero Pasivo",
		"icono": "⛏️",
		"rama": RAMA_MONEDAS,
		"tipo_costo": "monedas",
		"descripcion": "Ingresos pasivos continuos. Genera oro automáticamente cada 2 segundos.",
		"costo_monedas_base": 50,
		"costo_clicks_base": 0,
		"factor_monedas": 1.65,
		"factor_clicks": 1.0,
		"max_nivel": 5,
		"requisitos": {"mon_oro": 2},
		"bono_texto": "+1 Oro pasivo / seg"
	},

	# ==========================================================================
	# RAMA 2: COMERCIO CON CLICS (Resonancia y Poder del Núcleo)
	# ==========================================================================
	"clk_potencia": {
		"id": "clk_potencia",
		"nombre": "Clic Potenciado",
		"icono": "👆",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Extrae más energía rúnica al pulsar. Otorga +1 Clic extra y +1 Oro por pulsación.",
		"costo_monedas_base": 0,
		"costo_clicks_base": 5,
		"factor_monedas": 1.0,
		"factor_clicks": 1.45,
		"max_nivel": 10,
		"requisitos": {},
		"bono_texto": "+1 Clic y +1 Oro por clic"
	},
	"clk_onda": {
		"id": "clk_onda",
		"nombre": "Onda de Choque Rúnica",
		"icono": "💥",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Amplía la detonación del botón. +30% radio y +35% daño de la onda expansiva.",
		"costo_monedas_base": 0,
		"costo_clicks_base": 8,
		"factor_monedas": 1.0,
		"factor_clicks": 1.48,
		"max_nivel": 5,
		"requisitos": {},
		"bono_texto": "+30% Radio / +35% Daño onda"
	},
	"clk_iman": {
		"id": "clk_iman",
		"nombre": "Magnetismo Rúnico",
		"icono": "🧲",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Atracción espectral. Atrae orbes y drops desde una distancia mucho mayor.",
		"costo_monedas_base": 0,
		"costo_clicks_base": 14,
		"factor_monedas": 1.0,
		"factor_clicks": 1.50,
		"max_nivel": 5,
		"requisitos": {"clk_potencia": 1},
		"bono_texto": "+2.5m Radio de imán"
	},
	"clk_pasivo": {
		"id": "clk_pasivo",
		"nombre": "Auto-Resonador Pasivo",
		"icono": "⏳",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Generación incremental pura. Genera clics automáticamente con el tiempo.",
		"costo_monedas_base": 0,
		"costo_clicks_base": 24,
		"factor_monedas": 1.0,
		"factor_clicks": 1.60,
		"max_nivel": 5,
		"requisitos": {"clk_potencia": 2},
		"bono_texto": "+0.4 Clics pasivos / seg"
	},
	"clk_critico": {
		"id": "clk_critico",
		"nombre": "Impacto Crítico Rúnico",
		"icono": "🎯",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Probabilidad de asestar golpes críticos demoledores (x2.2 daño de ataque).",
		"costo_monedas_base": 0,
		"costo_clicks_base": 32,
		"factor_monedas": 1.0,
		"factor_clicks": 1.65,
		"max_nivel": 5,
		"requisitos": {"clk_onda": 2, "clk_pasivo": 1},
		"bono_texto": "+8% Prob. Crítico (x2.2 dmg)"
	},
	"clk_sobrecarga": {
		"id": "clk_sobrecarga",
		"nombre": "Sobrecarga de Tormenta",
		"icono": "🌩️",
		"rama": RAMA_CLICKS,
		"tipo_costo": "clicks",
		"descripcion": "Cada 8 clics acumulados, desata relámpagos arcanos sobre todos los enemigos.",
		"costo_monedas_base": 0,
		"costo_clicks_base": 48,
		"factor_monedas": 1.0,
		"factor_clicks": 1.70,
		"max_nivel": 5,
		"requisitos": {"clk_pasivo": 2},
		"bono_texto": "Descarga de 60 dmg / 8 clics"
	},

	# ==========================================================================
	# RAMA 3: SINERGIA HÍBRIDA (Desbloqueadas con AMBAS Monedas y Clics)
	# ==========================================================================
	"hib_alquimia": {
		"id": "hib_alquimia",
		"nombre": "Alquimia Rúnica",
		"icono": "🔮",
		"rama": RAMA_HIBRIDO,
		"tipo_costo": "ambas",
		"descripcion": "Transmutación mágica. Cada clic pulsado otorga Oro proporcional a tu poder de daño.",
		"costo_monedas_base": 28,
		"costo_clicks_base": 18,
		"factor_monedas": 1.55,
		"factor_clicks": 1.55,
		"max_nivel": 5,
		"requisitos": {"mon_oro": 1, "clk_potencia": 2},
		"bono_texto": "+15% Daño convertido en Oro / clic"
	},
	"hib_pacto": {
		"id": "hib_pacto",
		"nombre": "Pacto de Sangre y Runa",
		"icono": "💖",
		"rama": RAMA_HIBRIDO,
		"tipo_costo": "ambas",
		"descripcion": "Inmortalidad del gladiador. Otorga +1 Reaparición / Vida adicional y cura al 100%.",
		"costo_monedas_base": 45,
		"costo_clicks_base": 30,
		"factor_monedas": 1.80,
		"factor_clicks": 1.80,
		"max_nivel": 3,
		"requisitos": {"mon_vida": 3, "clk_iman": 2},
		"bono_texto": "+1 Vida Extra Máxima"
	},
	"hib_filo_crit": {
		"id": "hib_filo_crit",
		"nombre": "Filo Resonante",
		"icono": "✨",
		"rama": RAMA_HIBRIDO,
		"tipo_costo": "ambas",
		"descripcion": "Multiplicador colosal: potencia el daño de todos los Golpes Críticos a 320% (+100%).",
		"costo_monedas_base": 60,
		"costo_clicks_base": 40,
		"factor_monedas": 1.65,
		"factor_clicks": 1.65,
		"max_nivel": 5,
		"requisitos": {"mon_dano": 3, "clk_critico": 1},
		"bono_texto": "+60% Daño Crítico"
	},
	"hib_ascension": {
		"id": "hib_ascension",
		"nombre": "Ascensión Suprema",
		"icono": "👑",
		"rama": RAMA_HIBRIDO,
		"tipo_costo": "ambas",
		"descripcion": "Poder absoluto del Coliseo: +75% daño global masivo, +2 perforaciones y resistencia mística.",
		"costo_monedas_base": 110,
		"costo_clicks_base": 75,
		"factor_monedas": 2.0,
		"factor_clicks": 2.0,
		"max_nivel": 1,
		"requisitos": {"mon_cadencia": 1, "clk_sobrecarga": 1, "hib_alquimia": 1},
		"bono_texto": "¡Trascendencia Total (+75% Daño / +2 Perforaciones)!"
	}
}

# Orden de visualización sugerido para el árbol
const ORDEN_MEJORAS: Array[String] = [
	# Monedas
	"mon_dano", "mon_vida", "mon_vel", "mon_oro", "mon_cadencia", "mon_pasivo",
	# Clics
	"clk_potencia", "clk_onda", "clk_iman", "clk_pasivo", "clk_critico", "clk_sobrecarga",
	# Híbridas
	"hib_alquimia", "hib_pacto", "hib_filo_crit", "hib_ascension"
]

static func calcular_costo(id: String, nivel_actual: int) -> Dictionary:
	if not MEJORAS.has(id):
		return {"monedas": 0, "clicks": 0}
	var datos = MEJORAS[id]
	var c_mon = 0
	var c_clk = 0
	
	if datos.tipo_costo == "monedas" or datos.tipo_costo == "ambas":
		c_mon = int(round(datos.costo_monedas_base * pow(datos.factor_monedas, nivel_actual)))
	if datos.tipo_costo == "clicks" or datos.tipo_costo == "ambas":
		c_clk = int(round(datos.costo_clicks_base * pow(datos.factor_clicks, nivel_actual)))
		
	return {"monedas": c_mon, "clicks": c_clk}

static func cumple_requisitos(id: String, mejoras_compradas: Dictionary) -> bool:
	if not MEJORAS.has(id):
		return false
	var reqs: Dictionary = MEJORAS[id].get("requisitos", {})
	for req_id in reqs.keys():
		var lvl_min: int = reqs[req_id]
		var lvl_act: int = mejoras_compradas.get(req_id, 0)
		if lvl_act < lvl_min:
			return false
	return true

static func obtener_texto_requisitos(id: String) -> String:
	if not MEJORAS.has(id):
		return ""
	var reqs: Dictionary = MEJORAS[id].get("requisitos", {})
	if reqs.is_empty():
		return "Ninguno (Desbloqueado)"
	var partes: Array[String] = []
	for req_id in reqs.keys():
		var nom = MEJORAS[req_id].get("nombre", req_id)
		partes.append("%s Nv.%d" % [nom, reqs[req_id]])
	return "Requiere: " + ", ".join(partes)

static func obtener_ids_por_rama(rama: String) -> Array[String]:
	var res: Array[String] = []
	for id in ORDEN_MEJORAS:
		if rama == RAMA_TODAS or MEJORAS[id].rama == rama:
			res.append(id)
	return res
