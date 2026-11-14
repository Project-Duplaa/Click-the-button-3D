class_name ReliquiaDatos
extends RefCounted

## ReliquiaDatos - Catálogo de Reliquias pasivas acumulables (Clicklike 3D)
## Cada reliquia acumula stacks y se aplica sobre las variables de personaje.gd
## dentro de recalcular_stats_incrementales(). La Forja de Vulcano las duplica.

const CATALOGO: Dictionary = {
	"gladius_marte": {
		"nombre": "Gladius de Marte",
		"descripcion": "+15% de daño por acumulación.",
		"icono": "⚔️", "stat": "bonus_dano_pct", "valor": 0.15
	},
	"pluma_mercurio": {
		"nombre": "Pluma de Mercurio",
		"descripcion": "+12% de velocidad de movimiento por acumulación.",
		"icono": "🪶", "stat": "bonus_velocidad_mov_pct", "valor": 0.12
	},
	"coraza_centurion": {
		"nombre": "Coraza del Centurión",
		"descripcion": "+25 de vida máxima por acumulación.",
		"icono": "🛡️", "stat": "bonus_vida_plana", "valor": 25.0
	},
	"reloj_cronos": {
		"nombre": "Clepsidra de Cronos",
		"descripcion": "+12% de cadencia de ataque por acumulación.",
		"icono": "⏳", "stat": "bonus_cadencia_pct", "valor": 0.12
	},
	"ojo_halcon": {
		"nombre": "Ojo de Halcón",
		"descripcion": "+5% de probabilidad de crítico por acumulación.",
		"icono": "🦅", "stat": "bonus_critico", "valor": 0.05
	},
	"caliz_sangre": {
		"nombre": "Cáliz de Sangre",
		"descripcion": "+1.5 HP/s de regeneración por acumulación.",
		"icono": "🍷", "stat": "regen_vida_seg", "valor": 1.5
	},
	"denario_pluton": {
		"nombre": "Denario de Plutón",
		"descripcion": "+25% de oro por baja por acumulación.",
		"icono": "💰", "stat": "oro_por_baja_pct", "valor": 0.25
	},
	"papiro_minerva": {
		"nombre": "Papiro de Minerva",
		"descripcion": "+20% de experiencia ganada por acumulación.",
		"icono": "📜", "stat": "xp_ganada_pct", "valor": 0.20
	},
	"iman_vulcano": {
		"nombre": "Magnetita de Vulcano",
		"descripcion": "+2 m de radio de atracción de drops por acumulación.",
		"icono": "🧲", "stat": "radio_iman_extra", "valor": 2.0
	},
	"trebol_fortuna": {
		"nombre": "Trébol Sagrado de Fortuna",
		"descripcion": "+0.10 de suerte por acumulación.",
		"icono": "🍀", "stat": "suerte", "valor": 0.10
	},
	"estigma_perforante": {
		"nombre": "Estigma Perforante",
		"descripcion": "+1 de perforación de proyectiles por acumulación.",
		"icono": "🎯", "stat": "perforacion_armas", "valor": 1.0
	},
	"arco_apolo": {
		"nombre": "Arco Solar de Apolo",
		"descripcion": "+1 proyectil extra por acumulación.",
		"icono": "🏹", "stat": "proyectiles_extra", "valor": 1.0
	}
}

static func obtener_todos_los_ids() -> Array:
	return CATALOGO.keys()

static func obtener_datos(id: String) -> Dictionary:
	return CATALOGO.get(id, {})

static func obtener_nombre(id: String) -> String:
	return CATALOGO.get(id, {}).get("nombre", id)

static func obtener_icono(id: String) -> String:
	return CATALOGO.get(id, {}).get("icono", "💎")

static func obtener_descripcion(id: String) -> String:
	return CATALOGO.get(id, {}).get("descripcion", "")

## Suma la suerte aportada por las reliquias
static func calcular_suerte(reliquias: Dictionary) -> float:
	var total: float = 0.0
	for id in reliquias.keys():
		if CATALOGO.has(id) and CATALOGO[id].get("stat", "") == "suerte":
			total += float(CATALOGO[id]["valor"]) * int(reliquias[id])
	return total

## Aplica los bonos de todas las reliquias acumuladas. Se llama desde recalcular_stats_incrementales().
## Devuelve la vida máxima plana extra (la integra el personaje en su cálculo de vida).
static func aplicar_a_personaje(pj, reliquias: Dictionary) -> float:
	var vida_plana: float = 0.0
	if pj == null or reliquias.is_empty():
		return vida_plana
	for id in reliquias.keys():
		var stacks: int = int(reliquias[id])
		if stacks <= 0 or not CATALOGO.has(id):
			continue
		var r: Dictionary = CATALOGO[id]
		var val: float = float(r["valor"]) * stacks
		match r["stat"]:
			"bonus_dano_pct": pj.bonus_dano_pct += val
			"bonus_velocidad_mov_pct": pj.bonus_velocidad_mov_pct += val
			"bonus_vida_plana": vida_plana += val
			"bonus_cadencia_pct": pj.bonus_cadencia_pct += val
			"bonus_critico": pj.prob_critico += val
			"regen_vida_seg": pj.regen_vida_seg += val
			"oro_por_baja_pct": pj.oro_por_baja_pct += val
			"xp_ganada_pct": pj.xp_ganada_pct += val
			"radio_iman_extra": pj.radio_iman_extra += val
			"perforacion_armas": pj.perforacion_armas += int(val)
			"proyectiles_extra": pj.proyectiles_extra += int(val)
	return vida_plana
