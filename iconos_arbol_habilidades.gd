class_name IconosArbolHabilidades
extends RefCounted

## IconosArbolHabilidades - Preload y Mapeo Semántico de los 21 SVGs en res://ui_assets/
## Distingue entre iconos blancos puros [W] (tinte directo al color de rama)
## e iconos policromos [C] (tinte suave preservando matices originales).

const TEX_ATTEMPT: Texture2D = preload("res://ui_assets/icon_attempt_hades.svg")
const TEX_BLOOD: Texture2D = preload("res://ui_assets/icon_blood_hades.svg")
const TEX_BOLT: Texture2D = preload("res://ui_assets/icon_bolt_hades.svg")
const TEX_BOOK: Texture2D = preload("res://ui_assets/icon_book_cyber.svg")
const TEX_CLASS: Texture2D = preload("res://ui_assets/icon_class_hades.svg")
const TEX_CLICKS: Texture2D = preload("res://ui_assets/icon_clicks_hades.svg")
const TEX_DAGGERS: Texture2D = preload("res://ui_assets/icon_daggers_hades.svg")
const TEX_DENARIO: Texture2D = preload("res://ui_assets/icon_denario_hades.svg")
const TEX_FEVER: Texture2D = preload("res://ui_assets/icon_fever_hades.svg")
const TEX_FROST: Texture2D = preload("res://ui_assets/icon_frost_hades.svg")
const TEX_GOLD: Texture2D = preload("res://ui_assets/icon_gold_hades.svg")
const TEX_KILLS: Texture2D = preload("res://ui_assets/icon_kills_hades.svg")
const TEX_LUCK: Texture2D = preload("res://ui_assets/icon_luck_hades.svg")
const TEX_PACTO: Texture2D = preload("res://ui_assets/icon_pacto_hades.svg")
const TEX_PRISM: Texture2D = preload("res://ui_assets/icon_prism_hades.svg")
const TEX_SHIELD: Texture2D = preload("res://ui_assets/icon_shield_hades.svg")
const TEX_SKULL: Texture2D = preload("res://ui_assets/icon_skull_hades.svg")
const TEX_SYNERGY: Texture2D = preload("res://ui_assets/icon_synergy_hades.svg")
const TEX_TIME: Texture2D = preload("res://ui_assets/icon_time_hades.svg")
const TEX_VAULT: Texture2D = preload("res://ui_assets/icon_vault_hades.svg")
const TEX_VICTORY: Texture2D = preload("res://ui_assets/icon_victory_hades.svg")

const MAPA_ICONOS: Dictionary = {
	# Núcleo Central
	"nodo_origen": TEX_PRISM,

	# Rama Azul (Poder Activo de Clic)
	"clk_fuerza_1": TEX_CLICKS,
	"clk_pulso_1": TEX_BOLT,
	"clk_aoe_1": TEX_FEVER,
	"clk_crit_1": TEX_DAGGERS,
	"clk_impulso_1": TEX_ATTEMPT,
	"clk_eco_1": TEX_SYNERGY,
	"clk_filo_1": TEX_DAGGERS,
	"clk_anomalia_1": TEX_PRISM,
	"clk_sobrecarga_1": TEX_BOLT,
	"clk_frenesi_1": TEX_FEVER,
	"clk_penetracion_1": TEX_KILLS,
	"clk_keystone_cataclismo": TEX_BOLT,
	"clk_keystone_soberania": TEX_VICTORY,

	# Rama Botón (Ingeniería del Núcleo Móvil)
	"btn_disipador_1": TEX_FROST,
	"btn_tamano_1": TEX_PRISM,
	"btn_enfriamiento_1": TEX_FROST,
	"btn_ritmo_1": TEX_TIME,
	"btn_ancla_orbita_1": TEX_ATTEMPT,
	"btn_cadenas_1": TEX_SHIELD,
	"btn_sobrecarga_termica_1": TEX_FEVER,
	"btn_fiebre_sostenida_1": TEX_FEVER,
	"btn_palancas_1": TEX_BOLT,
	"btn_frenesi_duracion_1": TEX_TIME,
	"btn_keystone_criogenico": TEX_FROST,
	"btn_keystone_rompecadenas": TEX_VICTORY,

	# Rama Verde (Biocontención & Tanque)
	"srv_salud_1": TEX_BLOOD,
	"srv_armadura_1": TEX_SHIELD,
	"srv_vel_1": TEX_ATTEMPT,
	"srv_iman_1": TEX_PRISM,
	"srv_escudo_1": TEX_SHIELD,
	"srv_vida_extra_1": TEX_BLOOD,
	"srv_regen_1": TEX_BLOOD,
	"srv_vampirismo_1": TEX_SKULL,
	"srv_iframes_1": TEX_CLASS,
	"srv_fortaleza_1": TEX_SHIELD,
	"srv_desquite_1": TEX_KILLS,
	"srv_resistencia_1": TEX_PACTO,
	"srv_keystone_segunda_vida": TEX_BLOOD,
	"srv_keystone_coloso": TEX_CLASS,
	"srv_keystone_aliento": TEX_FEVER,

	# Rama Dorada (Economía & Arsenal)
	"eco_oro_1": TEX_GOLD,
	"eco_xp_1": TEX_BOOK,
	"trebol_coliseo": TEX_LUCK,
	"eco_cadencia_1": TEX_DAGGERS,
	"eco_autoclick_1": TEX_TIME,
	"eco_proyectiles_1": TEX_KILLS,
	"eco_multidisparo_1": TEX_SYNERGY,
	"eco_perforacion_1": TEX_DAGGERS,
	"eco_minero_1": TEX_DENARIO,
	"eco_alcance_1": TEX_ATTEMPT,
	"eco_reloj_1": TEX_TIME,
	"eco_dividendos_1": TEX_VAULT,
	"eco_keystone_usura": TEX_VAULT,
	"eco_keystone_fabrica": TEX_CLICKS,

	# Red Híbrida & Apex
	"pnt_azul_verde_1": TEX_SYNERGY,
	"pnt_verde_dorada_1": TEX_DENARIO,
	"pnt_dorada_azul_1": TEX_PRISM,
	"pnt_azul_verde_2": TEX_SHIELD,
	"pnt_verde_dorada_2": TEX_GOLD,
	"pnt_dorada_azul_2": TEX_DENARIO,
	"pnt_azul_verde_3": TEX_FEVER,
	"pnt_verde_dorada_3": TEX_BLOOD,
	"pnt_dorada_azul_3": TEX_GOLD,
	"pnt_keystone_bucle": TEX_SYNERGY,
	"pnt_keystone_midas": TEX_PACTO,
	"pnt_keystone_apex_orb": TEX_PRISM,
	"apex_keystone_ascension": TEX_VICTORY,

	# Constelación Cósmica & Maestrías Infinitas
	"cosm_nexo_primordial": TEX_PRISM,
	"inf_poder_armas": TEX_DAGGERS,
	"inf_resonancia_clic": TEX_BOLT,
	"inf_fortuna_eterna": TEX_LUCK,
	"cosm_singularidad_estelar": TEX_ATTEMPT,
	"cosm_pulso_supernova": TEX_FEVER,
	"cosm_ojo_cosmos": TEX_SKULL,
	"cosm_vortice_tiempo": TEX_TIME,
	"cosm_constelacion_draconis": TEX_KILLS,
	"cosm_corona_astral": TEX_VICTORY,
	"cosm_espejo_vacio": TEX_PACTO,
	"cosm_keystone_genesis": TEX_VICTORY
}

static func _es_tex_blanca(tex: Texture2D) -> bool:
	return tex == TEX_BLOOD or tex == TEX_BOLT or tex == TEX_DAGGERS or tex == TEX_FROST or tex == TEX_PRISM or tex == TEX_SYNERGY or tex == TEX_ATTEMPT

static func obtener_icono(nodo_id: String, rama: String = "") -> Texture2D:
	if MAPA_ICONOS.has(nodo_id):
		return MAPA_ICONOS[nodo_id]
	match rama:
		"azul":
			return TEX_BOLT
		"verde":
			return TEX_BLOOD
		"dorada":
			return TEX_GOLD
		"hibrido":
			return TEX_SYNERGY
		"cosmico":
			return TEX_PRISM
		"boton":
			return TEX_FROST
		"central":
			return TEX_PRISM
		_:
			return TEX_PRISM

static func es_tinte_puro(nodo_id: String) -> bool:
	var tex := obtener_icono(nodo_id)
	return _es_tex_blanca(tex)

static func obtener_color_icono(nodo_id: String, rama_brillo: Color, estado: String, rama: String = "") -> Color:
	var tex := obtener_icono(nodo_id, rama)
	var puro := _es_tex_blanca(tex)
	if estado == "bloqueado":
		if puro:
			return Color(0.46, 0.52, 0.60, 0.72)
		return Color(0.54, 0.57, 0.62, 0.72)
	elif estado == "desbloqueable":
		if puro:
			return rama_brillo.lightened(0.28)
		return Color.WHITE.lerp(rama_brillo, 0.16)
	else:
		if puro:
			return rama_brillo.lightened(0.22)
		return Color.WHITE.lerp(rama_brillo, 0.22)
