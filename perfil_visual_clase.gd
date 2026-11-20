extends RefCounted
class_name PerfilVisualClase

## PerfilVisualClase — Tabla Centralizada de Identidad Visual por Clase / Subclase
## Define paleta cromática, rim-light, emisión, ajuste metálico/rugosidad, escala sutil,
## contorno teñido, distintivo dorsal/orbital y aura de partículas liviana para Tier 1,
## las 7 especializaciones Tier 2, las 7 ascensiones definitivas Tier 3 y aliases legacy.

const SHADER_ARMADURA_SUBCLASE: Shader = preload("res://shaders/subclase_armadura.gdshader")

const PERFIL_BASE_DEFAULT: Dictionary = {
	"tier": 0,
	"color_primario": Color(0.88, 0.74, 0.38, 1.0),
	"color_rim": Color(0.95, 0.88, 0.68, 1.0),
	"color_emision": Color(0.88, 0.74, 0.38, 1.0),
	"color_outline": Color(0.08, 0.10, 0.14, 1.0),
	"intensidad_emision": 0.0,
	"tinte_albedo": 0.0,
	"metallic_boost": 0.0,
	"roughness_bias": 0.0,
	"escala_extra": 1.0,
	"rim_power": 2.6,
	"rim_intensity": 0.0,
	"pulse_speed": 2.2,
	"rune_intensity": 0.0,
	"emblema": "ninguno",
	"estilo_particulas": "ninguno",
	"particulas_cantidad": 0
}

const PERFILES: Dictionary = {
	# ================= BASE Y TIER 1 (Limpias, sin aura invasiva) =================
	"Novato": {
		"tier": 0,
		"color_primario": Color(0.88, 0.74, 0.38, 1.0),
		"color_rim": Color(0.95, 0.88, 0.68, 1.0),
		"color_emision": Color(0.88, 0.74, 0.38, 1.0),
		"color_outline": Color(0.08, 0.10, 0.14, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Recluta del Coliseo": {
		"tier": 0,
		"color_primario": Color(0.88, 0.74, 0.38, 1.0),
		"color_rim": Color(0.95, 0.88, 0.68, 1.0),
		"color_emision": Color(0.88, 0.74, 0.38, 1.0),
		"color_outline": Color(0.08, 0.10, 0.14, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Murmillo": {
		"tier": 1,
		"color_primario": Color(0.95, 0.25, 0.24, 1.0),
		"color_rim": Color(1.0, 0.55, 0.42, 1.0),
		"color_emision": Color(0.95, 0.25, 0.24, 1.0),
		"color_outline": Color(0.10, 0.07, 0.08, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Guerrero": {
		"tier": 1,
		"color_primario": Color(0.95, 0.25, 0.24, 1.0),
		"color_rim": Color(1.0, 0.55, 0.42, 1.0),
		"color_emision": Color(0.95, 0.25, 0.24, 1.0),
		"color_outline": Color(0.10, 0.07, 0.08, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Sagittario": {
		"tier": 1,
		"color_primario": Color(0.18, 0.88, 0.76, 1.0),
		"color_rim": Color(0.60, 0.96, 0.90, 1.0),
		"color_emision": Color(0.18, 0.88, 0.76, 1.0),
		"color_outline": Color(0.06, 0.11, 0.12, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Cazador": {
		"tier": 1,
		"color_primario": Color(0.95, 0.44, 0.08, 1.0),
		"color_rim": Color(1.0, 0.72, 0.40, 1.0),
		"color_emision": Color(0.95, 0.44, 0.08, 1.0),
		"color_outline": Color(0.11, 0.08, 0.06, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Arquero": {
		"tier": 1,
		"color_primario": Color(0.95, 0.44, 0.08, 1.0),
		"color_rim": Color(1.0, 0.72, 0.40, 1.0),
		"color_emision": Color(0.95, 0.44, 0.08, 1.0),
		"color_outline": Color(0.11, 0.08, 0.06, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Arúspice": {
		"tier": 1,
		"color_primario": Color(0.28, 0.58, 1.0, 1.0),
		"color_rim": Color(0.65, 0.84, 1.0, 1.0),
		"color_emision": Color(0.28, 0.58, 1.0, 1.0),
		"color_outline": Color(0.06, 0.08, 0.14, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},
	"Mago": {
		"tier": 1,
		"color_primario": Color(0.28, 0.58, 1.0, 1.0),
		"color_rim": Color(0.65, 0.84, 1.0, 1.0),
		"color_emision": Color(0.28, 0.58, 1.0, 1.0),
		"color_outline": Color(0.06, 0.08, 0.14, 1.0),
		"intensidad_emision": 0.0,
		"tinte_albedo": 0.0,
		"metallic_boost": 0.0,
		"roughness_bias": 0.0,
		"escala_extra": 1.0,
		"emblema": "ninguno",
		"estilo_particulas": "ninguno",
		"particulas_cantidad": 0
	},

	# ================= TIER 2: ESPECIALIZACIONES DE LA ARENA =================
	"Secutor Radiante": {
		"tier": 2,
		"color_primario": Color(1.0, 0.84, 0.24, 1.0),
		"color_rim": Color(1.0, 0.96, 0.66, 1.0),
		"color_emision": Color(1.0, 0.72, 0.14, 1.0),
		"color_outline": Color(0.36, 0.24, 0.04, 1.0),
		"intensidad_emision": 0.95,
		"tinte_albedo": 0.28,
		"metallic_boost": 0.32,
		"roughness_bias": -0.18,
		"escala_extra": 1.06,
		"rim_power": 2.4,
		"rim_intensity": 0.95,
		"pulse_speed": 2.2,
		"rune_intensity": 0.30,
		"emblema": "halo_solar",
		"estilo_particulas": "chispas_ascendentes",
		"particulas_cantidad": 14
	},
	"Provocator Sangriento": {
		"tier": 2,
		"color_primario": Color(0.92, 0.12, 0.18, 1.0),
		"color_rim": Color(1.0, 0.42, 0.28, 1.0),
		"color_emision": Color(0.96, 0.10, 0.16, 1.0),
		"color_outline": Color(0.32, 0.03, 0.05, 1.0),
		"intensidad_emision": 1.05,
		"tinte_albedo": 0.30,
		"metallic_boost": 0.18,
		"roughness_bias": -0.12,
		"escala_extra": 1.08,
		"rim_power": 2.2,
		"rim_intensity": 1.05,
		"pulse_speed": 3.4,
		"rune_intensity": 0.36,
		"emblema": "corona_furia",
		"estilo_particulas": "brasas",
		"particulas_cantidad": 15
	},
	"Velites Balístico": {
		"tier": 2,
		"color_primario": Color(0.14, 0.92, 1.0, 1.0),
		"color_rim": Color(0.76, 0.98, 1.0, 1.0),
		"color_emision": Color(0.06, 0.85, 1.0, 1.0),
		"color_outline": Color(0.04, 0.26, 0.34, 1.0),
		"intensidad_emision": 0.95,
		"tinte_albedo": 0.24,
		"metallic_boost": 0.26,
		"roughness_bias": -0.16,
		"escala_extra": 1.04,
		"rim_power": 2.5,
		"rim_intensity": 0.92,
		"pulse_speed": 2.8,
		"rune_intensity": 0.34,
		"emblema": "visor_astral",
		"estilo_particulas": "anillos_orbitales",
		"particulas_cantidad": 14
	},
	"Dimachaerus Espectral": {
		"tier": 2,
		"color_primario": Color(0.62, 0.22, 0.96, 1.0),
		"color_rim": Color(0.86, 0.62, 1.0, 1.0),
		"color_emision": Color(0.52, 0.14, 0.92, 1.0),
		"color_outline": Color(0.16, 0.04, 0.28, 1.0),
		"intensidad_emision": 0.90,
		"tinte_albedo": 0.28,
		"metallic_boost": 0.12,
		"roughness_bias": -0.06,
		"escala_extra": 1.04,
		"rim_power": 2.1,
		"rim_intensity": 0.96,
		"pulse_speed": 2.6,
		"rune_intensity": 0.28,
		"emblema": "dagas_sombra",
		"estilo_particulas": "niebla_sombria",
		"particulas_cantidad": 14
	},
	"Taumaturgo del Vacío": {
		"tier": 2,
		"color_primario": Color(0.48, 0.16, 0.96, 1.0),
		"color_rim": Color(0.76, 0.56, 1.0, 1.0),
		"color_emision": Color(0.44, 0.12, 0.95, 1.0),
		"color_outline": Color(0.14, 0.04, 0.30, 1.0),
		"intensidad_emision": 1.0,
		"tinte_albedo": 0.28,
		"metallic_boost": 0.16,
		"roughness_bias": -0.14,
		"escala_extra": 1.05,
		"rim_power": 2.3,
		"rim_intensity": 0.98,
		"pulse_speed": 2.1,
		"rune_intensity": 0.36,
		"emblema": "orbita_vacio",
		"estilo_particulas": "anillos_orbitales",
		"particulas_cantidad": 15
	},
	"Flamen Volcánico": {
		"tier": 2,
		"color_primario": Color(1.0, 0.42, 0.08, 1.0),
		"color_rim": Color(1.0, 0.82, 0.34, 1.0),
		"color_emision": Color(1.0, 0.32, 0.04, 1.0),
		"color_outline": Color(0.34, 0.10, 0.02, 1.0),
		"intensidad_emision": 1.05,
		"tinte_albedo": 0.28,
		"metallic_boost": 0.15,
		"roughness_bias": -0.12,
		"escala_extra": 1.06,
		"rim_power": 2.2,
		"rim_intensity": 1.0,
		"pulse_speed": 3.0,
		"rune_intensity": 0.38,
		"emblema": "corona_ignea",
		"estilo_particulas": "brasas",
		"particulas_cantidad": 16
	},
	"Custodio del Núcleo": {
		"tier": 2,
		"color_primario": Color(0.18, 0.96, 0.86, 1.0),
		"color_rim": Color(0.78, 1.0, 0.96, 1.0),
		"color_emision": Color(0.12, 0.92, 0.82, 1.0),
		"color_outline": Color(0.04, 0.28, 0.26, 1.0),
		"intensidad_emision": 1.0,
		"tinte_albedo": 0.26,
		"metallic_boost": 0.28,
		"roughness_bias": -0.18,
		"escala_extra": 1.07,
		"rim_power": 2.4,
		"rim_intensity": 0.96,
		"pulse_speed": 2.5,
		"rune_intensity": 0.38,
		"emblema": "prisma_nucleo",
		"estilo_particulas": "prisma_flotante",
		"particulas_cantidad": 15
	},

	# ================= TIER 3: ASCENSIÓN DEFINITIVA =================
	"Paladín del Sol Invictus": {
		"tier": 3,
		"color_primario": Color(1.0, 0.88, 0.28, 1.0),
		"color_rim": Color(1.0, 0.98, 0.78, 1.0),
		"color_emision": Color(1.0, 0.78, 0.18, 1.0),
		"color_outline": Color(0.52, 0.36, 0.06, 1.0),
		"intensidad_emision": 1.35,
		"tinte_albedo": 0.34,
		"metallic_boost": 0.42,
		"roughness_bias": -0.24,
		"escala_extra": 1.14,
		"rim_power": 2.1,
		"rim_intensity": 1.25,
		"pulse_speed": 2.6,
		"rune_intensity": 0.45,
		"emblema": "halo_solar",
		"estilo_particulas": "chispas_ascendentes",
		"particulas_cantidad": 18
	},
	"Campeón Augusto de Sangre": {
		"tier": 3,
		"color_primario": Color(0.96, 0.10, 0.16, 1.0),
		"color_rim": Color(1.0, 0.48, 0.30, 1.0),
		"color_emision": Color(1.0, 0.14, 0.18, 1.0),
		"color_outline": Color(0.46, 0.04, 0.06, 1.0),
		"intensidad_emision": 1.40,
		"tinte_albedo": 0.34,
		"metallic_boost": 0.25,
		"roughness_bias": -0.18,
		"escala_extra": 1.15,
		"rim_power": 2.0,
		"rim_intensity": 1.30,
		"pulse_speed": 3.8,
		"rune_intensity": 0.50,
		"emblema": "corona_furia",
		"estilo_particulas": "brasas",
		"particulas_cantidad": 18
	},
	"Centurión Balístico Astral": {
		"tier": 3,
		"color_primario": Color(0.20, 0.95, 1.0, 1.0),
		"color_rim": Color(0.84, 1.0, 1.0, 1.0),
		"color_emision": Color(0.10, 0.90, 1.0, 1.0),
		"color_outline": Color(0.06, 0.38, 0.48, 1.0),
		"intensidad_emision": 1.30,
		"tinte_albedo": 0.30,
		"metallic_boost": 0.35,
		"roughness_bias": -0.22,
		"escala_extra": 1.12,
		"rim_power": 2.2,
		"rim_intensity": 1.22,
		"pulse_speed": 3.2,
		"rune_intensity": 0.46,
		"emblema": "visor_astral",
		"estilo_particulas": "anillos_orbitales",
		"particulas_cantidad": 16
	},
	"Sombra del Anfiteatro": {
		"tier": 3,
		"color_primario": Color(0.76, 0.24, 1.0, 1.0),
		"color_rim": Color(0.92, 0.72, 1.0, 1.0),
		"color_emision": Color(0.66, 0.16, 1.0, 1.0),
		"color_outline": Color(0.26, 0.06, 0.42, 1.0),
		"intensidad_emision": 1.25,
		"tinte_albedo": 0.32,
		"metallic_boost": 0.18,
		"roughness_bias": -0.10,
		"escala_extra": 1.12,
		"rim_power": 1.9,
		"rim_intensity": 1.24,
		"pulse_speed": 3.0,
		"rune_intensity": 0.40,
		"emblema": "dagas_sombra",
		"estilo_particulas": "niebla_sombria",
		"particulas_cantidad": 18
	},
	"Pontífice del Vacío Estelar": {
		"tier": 3,
		"color_primario": Color(0.58, 0.20, 1.0, 1.0),
		"color_rim": Color(0.84, 0.66, 1.0, 1.0),
		"color_emision": Color(0.52, 0.14, 1.0, 1.0),
		"color_outline": Color(0.22, 0.06, 0.44, 1.0),
		"intensidad_emision": 1.35,
		"tinte_albedo": 0.34,
		"metallic_boost": 0.22,
		"roughness_bias": -0.18,
		"escala_extra": 1.13,
		"rim_power": 2.0,
		"rim_intensity": 1.26,
		"pulse_speed": 2.4,
		"rune_intensity": 0.48,
		"emblema": "orbita_vacio",
		"estilo_particulas": "anillos_orbitales",
		"particulas_cantidad": 18
	},
	"Señor del Magma Imperial": {
		"tier": 3,
		"color_primario": Color(1.0, 0.40, 0.06, 1.0),
		"color_rim": Color(1.0, 0.88, 0.42, 1.0),
		"color_emision": Color(1.0, 0.34, 0.04, 1.0),
		"color_outline": Color(0.48, 0.14, 0.03, 1.0),
		"intensidad_emision": 1.40,
		"tinte_albedo": 0.34,
		"metallic_boost": 0.22,
		"roughness_bias": -0.16,
		"escala_extra": 1.14,
		"rim_power": 2.0,
		"rim_intensity": 1.28,
		"pulse_speed": 3.4,
		"rune_intensity": 0.50,
		"emblema": "corona_ignea",
		"estilo_particulas": "brasas",
		"particulas_cantidad": 18
	},
	"Titán Supremo del Núcleo": {
		"tier": 3,
		"color_primario": Color(0.25, 0.98, 0.90, 1.0),
		"color_rim": Color(0.86, 1.0, 0.98, 1.0),
		"color_emision": Color(0.18, 0.96, 0.88, 1.0),
		"color_outline": Color(0.06, 0.42, 0.38, 1.0),
		"intensidad_emision": 1.38,
		"tinte_albedo": 0.32,
		"metallic_boost": 0.36,
		"roughness_bias": -0.22,
		"escala_extra": 1.16,
		"rim_power": 2.1,
		"rim_intensity": 1.28,
		"pulse_speed": 2.8,
		"rune_intensity": 0.52,
		"emblema": "prisma_nucleo",
		"estilo_particulas": "prisma_flotante",
		"particulas_cantidad": 18
	}
}

const ALIASES_LEGACY: Dictionary = {
	"Paladín Solar": "Secutor Radiante",
	"Berserker Sangriento": "Provocator Sangriento",
	"Francotirador Astral": "Velites Balístico",
	"Maestro de Sombras": "Dimachaerus Espectral",
	"Archimago del Vacío": "Taumaturgo del Vacío",
	"Piromante Cataclísmico": "Flamen Volcánico",
	"Avatar del Núcleo": "Custodio del Núcleo"
}

static func obtener_perfil(nombre_clase: String) -> Dictionary:
	var clave := nombre_clase.strip_edges()
	if ALIASES_LEGACY.has(clave):
		clave = str(ALIASES_LEGACY[clave])
	if PERFILES.has(clave):
		return PERFILES[clave]
	return PERFIL_BASE_DEFAULT

static func es_subclase_ascendida(nombre_clase: String) -> bool:
	var perfil := obtener_perfil(nombre_clase)
	return int(perfil.get("tier", 0)) >= 2

static func crear_material_shader_armadura(perfil: Dictionary) -> ShaderMaterial:
	var smat := ShaderMaterial.new()
	smat.shader = SHADER_ARMADURA_SUBCLASE
	smat.set_shader_parameter("rim_color", perfil.get("color_rim", Color(1.0, 0.9, 0.5, 1.0)))
	smat.set_shader_parameter("energy_color", perfil.get("color_emision", Color(1.0, 0.7, 0.2, 1.0)))
	smat.set_shader_parameter("rim_power", float(perfil.get("rim_power", 2.4)))
	smat.set_shader_parameter("rim_intensity", float(perfil.get("rim_intensity", 0.95)))
	smat.set_shader_parameter("pulse_speed", float(perfil.get("pulse_speed", 2.5)))
	smat.set_shader_parameter("pulse_amount", 0.28 if int(perfil.get("tier", 2)) >= 3 else 0.22)
	smat.set_shader_parameter("rune_flow_speed", 1.55 if int(perfil.get("tier", 2)) >= 3 else 1.15)
	smat.set_shader_parameter("rune_intensity", float(perfil.get("rune_intensity", 0.34)))
	return smat

static func crear_material_outline_subclase(perfil: Dictionary) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = perfil.get("color_outline", Color(0.08, 0.10, 0.14, 1.0))
	mat.grow = true
	mat.grow_amount = 0.022 if int(perfil.get("tier", 2)) >= 3 else 0.018
	return mat
