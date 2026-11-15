class_name EvolucionManager
extends Node

## EvolucionManager (FSM de Evolución de Clases y Metamorfosis 3D)
## Administra la transición de estados de clase del jugador (Tier 1 y Ascensión Tier 2)
## y el despliegue de la rueda radial 3D in-world preservando bonos de run y árbol.

enum EstadoFSM {
	NOVATO,             # Clase base inicial
	DISPONIBLE,         # Cumplió hito Tier 1 (Nivel 3 + 15 clics + 8 bajas), listo para elegir
	METAMORFOSIS,       # Modal activo / proceso de transformación Tier 1
	EVOLUCIONADO,       # Clase Tier 1 seleccionada (Guerrero / Cazador / Mago)
	ASCENSION_T2_LISTA, # Cumplió hito Tier 2 (Nivel 8 + 45 clics), rueda Tier 2 activa
	ASCENDIDO_TIER_2    # Subclase Suprema Tier 2 desbloqueada
}

signal metamorfosis_disponible()
signal clase_evolucionada(nombre_clase: String, stats: Dictionary)
signal subclase_ascendida(nombre_subclase: String, stats: Dictionary)
signal evolucion_tier2_completada(nombre_subclase: String)
signal evolucion_completada(nombre_subclase: String)
signal malla_cambiada(nuevo_modelo: Node3D)

# Requisitos de Metamorfosis Tier 1 (Acelerados al minuto 1:15 - 1:30 para dopamina temprana)
@export var hito_nivel: int = 3
@export var hito_clics: int = 15
@export var hito_bajas: int = 8
@export var requiere_todos_los_hitos: bool = true

# Requisitos de Ascensión Tier 2 (Nv.8 + 45 clics)
@export var hito_nivel_tier2: int = 8
@export var hito_clics_tier2: int = 45

const HITO_NIVEL: int = 3
const HITO_CLICS: int = 15
const HITO_BAJAS: int = 8
const HITO_NIVEL_TIER2: int = 8
const HITO_CLICS_TIER2: int = 45

const MALLAS_CLASE = {
	"Novato": "res://personaje/character-male-a.glb",
	"Guerrero": "res://personaje/character-male-d.glb",
	"Cazador": "res://personaje/character-female-e.glb",
	"Mago": "res://personaje/character-female-b.glb",
	"Paladín Solar": "res://personaje/character-male-d.glb",
	"Berserker Sangriento": "res://personaje/character-male-d.glb",
	"Francotirador Astral": "res://personaje/character-female-e.glb",
	"Maestro de Sombras": "res://personaje/character-female-e.glb",
	"Archimago del Vacío": "res://personaje/character-female-b.glb",
	"Piromante Cataclísmico": "res://personaje/character-female-b.glb",
	"Avatar del Núcleo": "res://personaje/character-male-d.glb"
}

const STATS_CLASE = {
	"Novato": {
		"nombre": "Novato",
		"rol": "Aventurero Base",
		"descripcion": "Combatiente novato que recién ingresa al Coliseo.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 2.6,
		"cadencia_ataque": 0.85,
		"speed_caminar": 3.4,
		"speed_correr": 5.4
	},
	"Guerrero": {
		"nombre": "Guerrero",
		"rol": "Tanque / Melee Colosal",
		"descripcion": "Especialista en combate cuerpo a cuerpo y resistencia extrema.",
		"vida_maxima": 160.0,
		"dano": 22.0,
		"rango_ataque": 3.2,
		"cadencia_ataque": 0.70,
		"speed_caminar": 3.2,
		"speed_correr": 5.6
	},
	"Cazador": {
		"nombre": "Cazador",
		"rol": "Ranger / Ráfaga Veloz",
		"descripcion": "Especialista en disparos continuos a distancia y evasión veloz.",
		"vida_maxima": 100.0,
		"dano": 14.0,
		"rango_ataque": 7.5,
		"cadencia_ataque": 0.45,
		"speed_caminar": 3.8,
		"speed_correr": 6.4
	},
	"Mago": {
		"nombre": "Mago",
		"rol": "Arcanista / Daño Mágico Masivo",
		"descripcion": "Lanza proyectiles arcanos devastadores a media distancia.",
		"vida_maxima": 85.0,
		"dano": 28.0,
		"rango_ataque": 5.5,
		"cadencia_ataque": 0.90,
		"speed_caminar": 3.3,
		"speed_correr": 5.7
	}
}

const SUBCLASES_TIER2 = {
	"Paladín Solar": {
		"nombre": "Paladín Solar",
		"clase_base": "Guerrero",
		"rol": "Coloso de Luz / Baluarte Sagrado",
		"bonus_vida": 100.0,
		"mult_dano": 1.40,
		"mult_cadencia": 0.85,
		"bonus_armadura": 50.0,
		"descripcion": "Baluarte sagrado imbuido de fuego solar. Cada bloqueo desata una supernova radiante que sana y calcina."
	},
	"Berserker Sangriento": {
		"nombre": "Berserker Sangriento",
		"clase_base": "Guerrero",
		"rol": "Frenesí Melee / Hachas Dobles",
		"bonus_vida": 60.0,
		"mult_dano": 1.65,
		"mult_cadencia": 0.65,
		"bonus_armadura": 10.0,
		"descripcion": "Torbellino sangriento con dos hachas voraces. Gana velocidad y daño por vida faltante con robo de vida."
	},
	"Francotirador Astral": {
		"nombre": "Francotirador Astral",
		"clase_base": "Cazador",
		"rol": "Riel Astral / Francotirador Perforante",
		"bonus_vida": 45.0,
		"mult_dano": 1.70,
		"mult_cadencia": 0.85,
		"proyectiles_extra": 1,
		"descripcion": "Dispara saetas de plasma a hipervelocidad perforando toda la línea recta con daño masivo."
	},
	"Maestro de Sombras": {
		"nombre": "Maestro de Sombras",
		"clase_base": "Cazador",
		"rol": "Asesino Evasivo / Dagas Espectrales",
		"bonus_vida": 50.0,
		"mult_dano": 1.45,
		"mult_cadencia": 0.70,
		"proyectiles_extra": 2,
		"descripcion": "Espiral de dagas espectrales en 360°, alta evasión pasiva (+35%) y señuelo explosivo en dash."
	},
	"Archimago del Vacío": {
		"nombre": "Archimago del Vacío",
		"clase_base": "Mago",
		"rol": "Vórtice Gravitacional / Control Cósmico",
		"bonus_vida": 55.0,
		"mult_dano": 1.60,
		"mult_cadencia": 0.85,
		"bonus_aoe": 1.8,
		"descripcion": "Orbes oscuros que colapsan en singularidades gravitacionales atrayendo y devorando enemigos."
	},
	"Piromante Cataclísmico": {
		"nombre": "Piromante Cataclísmico",
		"clase_base": "Mago",
		"rol": "Magma Solar / Calamidad de Fuego",
		"bonus_vida": 60.0,
		"mult_dano": 1.75,
		"mult_cadencia": 0.88,
		"bonus_aoe": 2.0,
		"descripcion": "Desata meteoros ígneos que dejan charcos de magma ardiente de 2.8s sobre la arena."
	},
	"Avatar del Núcleo": {
		"nombre": "Avatar del Núcleo",
		"clase_base": "Universal",
		"rol": "Híbrido de Resonancia / Clic Supremo",
		"bonus_vida": 75.0,
		"mult_dano": 1.50,
		"mult_cadencia": 0.80,
		"bonus_armadura": 30.0,
		"descripcion": "Sintonizado con el Núcleo 3D. Hilos gemelos de resonancia continua y doble onda de choque al hacer clic."
	}
}

const OPCIONES_TIER2 = {
	"Guerrero": ["Paladín Solar", "Berserker Sangriento", "Avatar del Núcleo"],
	"Cazador": ["Francotirador Astral", "Maestro de Sombras", "Avatar del Núcleo"],
	"Mago": ["Archimago del Vacío", "Piromante Cataclísmico", "Avatar del Núcleo"]
}

var estado_actual: EstadoFSM = EstadoFSM.NOVATO
var total_clics_acumulados: int = 0
var subclase_activa: String = ""
var personaje_ref: CharacterBody3D = null
var modal_instancia: Node = null
var tier_menu_activo: int = 1

func _ready():
	add_to_group("evolucion_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() is CharacterBody3D:
		configurar_con_personaje(get_parent() as CharacterBody3D)

func configurar_con_personaje(personaje: CharacterBody3D):
	personaje_ref = personaje
	call_deferred("_vincular_eventos_externos")

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _vincular_eventos_externos():
	var tree = _obtener_tree()
	if tree == null:
		return
	var boton = tree.get_first_node_in_group("boton_movil")
	if boton != null and boton.has_signal("click_presionado"):
		if not boton.click_presionado.is_connected(_on_boton_movil_click):
			boton.click_presionado.connect(_on_boton_movil_click)

func _on_boton_movil_click(total_clicks: int):
	total_clics_acumulados = max(total_clics_acumulados, total_clicks)
	_evaluar_hito_evolucion()

func registrar_click():
	var tree = _obtener_tree()
	if tree != null:
		var b = tree.get_first_node_in_group("boton_movil")
		if b != null and "total_clicks" in b and b.total_clicks > total_clics_acumulados:
			total_clics_acumulados = b.total_clicks
		else:
			total_clics_acumulados += 1
	else:
		total_clics_acumulados += 1
	_evaluar_hito_evolucion()

func notificar_nivel(_nuevo_nivel: int):
	_evaluar_hito_evolucion()

func notificar_baja():
	_evaluar_hito_evolucion()

func puede_evolucionar() -> bool:
	if estado_actual != EstadoFSM.NOVATO:
		return false
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var bajas_actuales = personaje_ref.bajas if personaje_ref != null else 0
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	
	if requiere_todos_los_hitos:
		return (nivel_actual >= hito_nivel 
			and clics_reales >= hito_clics 
			and bajas_actuales >= hito_bajas)
	else:
		return (nivel_actual >= hito_nivel or clics_reales >= hito_clics)

func puede_ascender_tier2() -> bool:
	if estado_actual != EstadoFSM.EVOLUCIONADO:
		return false
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	return nivel_actual >= hito_nivel_tier2 and clics_reales >= hito_clics_tier2

func obtener_texto_progreso_evolucion() -> String:
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var bajas_actuales = personaje_ref.bajas if personaje_ref != null else 0
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	
	if estado_actual == EstadoFSM.NOVATO:
		if puede_evolucionar():
			return "¡METAMORFOSIS DISPONIBLE!"
		return "Metamorfosis T1: Nv.%d/%d · Clics:%d/%d · Bajas:%d/%d" % [
			nivel_actual, hito_nivel,
			clics_reales, hito_clics,
			bajas_actuales, hito_bajas
		]
	elif estado_actual == EstadoFSM.EVOLUCIONADO:
		if puede_ascender_tier2():
			return "¡ASCENSIÓN T2 DISPONIBLE!"
		return "Ascensión T2: Nv.%d/%d · Clics:%d/%d" % [
			nivel_actual, hito_nivel_tier2,
			clics_reales, hito_clics_tier2
		]
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2:
		return "👑 " + subclase_activa
	return ""

func _evaluar_hito_evolucion():
	if estado_actual == EstadoFSM.NOVATO and puede_evolucionar():
		disparar_metamorfosis()
	elif estado_actual == EstadoFSM.EVOLUCIONADO and puede_ascender_tier2():
		disparar_ascension_tier2()

func disparar_metamorfosis():
	if estado_actual != EstadoFSM.NOVATO:
		return
	
	estado_actual = EstadoFSM.DISPONIBLE
	tier_menu_activo = 1
	emit_signal("metamorfosis_disponible")
	
	AudioManager.play("altar_activado", 1.25, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("✨ ¡METAMORFOSIS HEROICA TIER 1!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(1)

func disparar_ascension_tier2():
	if estado_actual != EstadoFSM.EVOLUCIONADO:
		return
	
	estado_actual = EstadoFSM.ASCENSION_T2_LISTA
	tier_menu_activo = 2
	
	AudioManager.play("altar_activado", 1.35, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("👑 ¡ASCENSIÓN SUPREMA TIER 2 DISPONIBLE!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(2)

## Método público para el panel de depuración F3
func forzar_rueda_tier2():
	if personaje_ref == null:
		return
	if estado_actual == EstadoFSM.NOVATO or estado_actual == EstadoFSM.DISPONIBLE or estado_actual == EstadoFSM.METAMORFOSIS:
		if modal_instancia != null and is_instance_valid(modal_instancia) and modal_instancia.has_method("cerrar"):
			modal_instancia.cerrar()
		estado_actual = EstadoFSM.NOVATO
		evolucionar_a("Guerrero")
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2:
		estado_actual = EstadoFSM.EVOLUCIONADO
	if estado_actual == EstadoFSM.EVOLUCIONADO:
		disparar_ascension_tier2()

func abrir_modal_evolucion(tier: int = 1):
	tier_menu_activo = tier
	if modal_instancia != null and is_instance_valid(modal_instancia):
		if modal_instancia.has_method("configurar_modo_tier"):
			var base_clase = _obtener_arquetipo_base_personaje()
			modal_instancia.configurar_modo_tier(tier, base_clase)
		if modal_instancia.has_method("abrir"):
			modal_instancia.abrir()
		return
	
	estado_actual = EstadoFSM.METAMORFOSIS if tier == 1 else EstadoFSM.ASCENSION_T2_LISTA
	
	if personaje_ref != null and is_instance_valid(personaje_ref):
		var radial = personaje_ref.get_node_or_null("EvolucionRadial")
		if radial == null:
			var escena_radial = load("res://evolucion_radial.tscn")
			if escena_radial != null:
				radial = escena_radial.instantiate()
				radial.name = "EvolucionRadial"
				personaje_ref.add_child(radial)
				radial.personaje_padre = personaje_ref
		if radial != null:
			modal_instancia = radial
			var base_clase = _obtener_arquetipo_base_personaje()
			if radial.has_method("configurar_modo_tier"):
				radial.configurar_modo_tier(tier, base_clase)
			if not radial.evolucion_seleccionada.is_connected(_on_clase_elegida_en_modal):
				radial.evolucion_seleccionada.connect(_on_clase_elegida_en_modal)
			radial.abrir()
			return

	var escena_modal = load("res://modal_evolucion.tscn")
	if escena_modal != null:
		modal_instancia = escena_modal.instantiate()
		var tree = _obtener_tree()
		if tree != null and tree.root != null:
			tree.root.add_child(modal_instancia)
			if modal_instancia.has_signal("clase_seleccionada"):
				modal_instancia.clase_seleccionada.connect(_on_clase_elegida_en_modal)

func _obtener_arquetipo_base_personaje() -> String:
	if personaje_ref == null:
		return "Guerrero"
	if "clase_base" in personaje_ref and personaje_ref.clase_base != "Novato" and personaje_ref.clase_base != "":
		return personaje_ref.clase_base
	if personaje_ref.clase != "Novato" and personaje_ref.clase != "":
		return personaje_ref.clase
	return "Guerrero"

func _on_clase_elegida_en_modal(nombre_opcion: String):
	if modal_instancia != null and is_instance_valid(modal_instancia):
		if modal_instancia.has_method("cerrar"):
			modal_instancia.cerrar()
		elif modal_instancia is CanvasLayer:
			modal_instancia.queue_free()
		modal_instancia = null
	var tree = _obtener_tree()
	if tree != null:
		tree.paused = false
		
	if tier_menu_activo == 2 or SUBCLASES_TIER2.has(nombre_opcion):
		ascender_a_subclase_tier2(nombre_opcion)
	else:
		evolucionar_a(nombre_opcion)

func evolucionar_a(nombre_clase: String):
	if estado_actual == EstadoFSM.EVOLUCIONADO or estado_actual == EstadoFSM.ASCENDIDO_TIER_2:
		return
	if not STATS_CLASE.has(nombre_clase):
		push_error("Clase desconocida para evolución: " + nombre_clase)
		return
	
	estado_actual = EstadoFSM.EVOLUCIONADO
	var stats = STATS_CLASE[nombre_clase]
	
	if personaje_ref != null:
		if personaje_ref.has_method("aplicar_clase"):
			personaje_ref.aplicar_clase(nombre_clase)
		
		var nodo_salud = personaje_ref.get_node_or_null("Salud")
		if nodo_salud != null:
			if "vida" in nodo_salud:
				nodo_salud.vida = int(personaje_ref.vida)
			if "vida_inicial" in nodo_salud:
				nodo_salud.vida_inicial = int(personaje_ref.vida_maxima)
		
		var ruta_malla = MALLAS_CLASE.get(nombre_clase, "")
		if ruta_malla != "":
			var nuevo_anim = cambiar_malla_3d(personaje_ref, ruta_malla)
			if nuevo_anim != null:
				personaje_ref.anim = nuevo_anim
				personaje_ref.animar()
		
		_emitir_feedback_metamorfosis(nombre_clase)
		
		personaje_ref.emit_signal("stats_actualizadas",
			personaje_ref.vida,
			personaje_ref.vida_maxima,
			personaje_ref.xp,
			personaje_ref.xp_siguiente_nivel,
			personaje_ref.nivel,
			personaje_ref.oro,
			personaje_ref.bajas
		)
	
	emit_signal("clase_evolucionada", nombre_clase, stats)
	emit_signal("evolucion_completada", nombre_clase)
	_evaluar_hito_evolucion()

func ascender_a_subclase_tier2(nombre_subclase: String):
	if estado_actual == EstadoFSM.ASCENDIDO_TIER_2 or personaje_ref == null:
		return
	var datos_t2 = SUBCLASES_TIER2.get(nombre_subclase, null)
	if datos_t2 == null:
		push_error("Subclase desconocida para Tier 2: " + nombre_subclase)
		return
		
	estado_actual = EstadoFSM.ASCENDIDO_TIER_2
	subclase_activa = nombre_subclase
	
	if personaje_ref.has_method("aplicar_subclase_tier2"):
		personaje_ref.aplicar_subclase_tier2(nombre_subclase)
	elif personaje_ref.has_method("aplicar_clase"):
		personaje_ref.aplicar_clase(nombre_subclase)
		
	if "bono_run_vida_plana" in personaje_ref:
		personaje_ref.bono_run_vida_plana += float(datos_t2.get("bonus_vida", 50.0))
	if "bono_run_dano_mult" in personaje_ref:
		personaje_ref.bono_run_dano_mult *= float(datos_t2.get("mult_dano", 1.35))
	if "bono_run_cadencia_mult" in personaje_ref:
		personaje_ref.bono_run_cadencia_mult *= float(datos_t2.get("mult_cadencia", 0.85))
	if "bono_run_armadura_plana" in personaje_ref and datos_t2.has("bonus_armadura"):
		personaje_ref.bono_run_armadura_plana += float(datos_t2["bonus_armadura"])
	if "bono_run_proyectiles_extra" in personaje_ref and datos_t2.has("proyectiles_extra"):
		personaje_ref.bono_run_proyectiles_extra += int(datos_t2["proyectiles_extra"])
		
	if personaje_ref.has_method("recalcular_stats_incrementales"):
		personaje_ref.recalcular_stats_incrementales()
	personaje_ref.vida = personaje_ref.vida_maxima
	
	if personaje_ref.has_method("equipar_armas_clase"):
		personaje_ref.equipar_armas_clase(nombre_subclase)
	
	MetaprogresoManager.registrar_subclase_descubierta(nombre_subclase)
		
	var tree = _obtener_tree()
	if tree != null:
		var lm = tree.get_first_node_in_group("logros_manager")
		if lm != null and lm.has_method("notificar_subclase"):
			lm.notificar_subclase(nombre_subclase)
	
	AudioManager.play("victoria", 1.25)
	if personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("👑 ¡ASCENSIÓN TIER 2: %s!" % subclase_activa.to_upper(), Color(1.0, 0.85, 0.2))
		
	emit_signal("subclase_ascendida", subclase_activa, datos_t2)
	emit_signal("evolucion_tier2_completada", subclase_activa)
	emit_signal("evolucion_completada", subclase_activa)

func cambiar_malla_3d(personaje: CharacterBody3D, ruta_malla: String) -> AnimationPlayer:
	if not ResourceLoader.exists(ruta_malla):
		push_error("No se encontró recurso de malla: " + ruta_malla)
		return null
	
	var escena_glb = load(ruta_malla)
	if escena_glb == null:
		push_error("Fallo al instanciar modelo .glb: " + ruta_malla)
		return null
	
	var modelo_actual = personaje.get_node_or_null("Modelo")
	var transform_base = Transform3D(Basis(Vector3(-2.6, 0.0, 0.0), Vector3(0.0, 2.6, 0.0), Vector3(0.0, 0.0, -2.6)), Vector3.ZERO)
	
	if modelo_actual != null:
		transform_base = modelo_actual.transform
		modelo_actual.name = "Modelo_Antiguo"
		personaje.remove_child(modelo_actual)
		modelo_actual.queue_free()
	
	var nuevo_modelo = escena_glb.instantiate()
	nuevo_modelo.name = "Modelo"
	nuevo_modelo.transform = transform_base
	personaje.add_child(nuevo_modelo)
	
	var nuevo_anim = AnimadorEntidad.buscar_animation_player(nuevo_modelo)
	if nuevo_anim == null:
		push_warning("El modelo nuevo %s no contiene nodo AnimationPlayer" % ruta_malla)
	emit_signal("malla_cambiada", nuevo_modelo)
	return nuevo_anim

func _emitir_feedback_metamorfosis(nombre_clase: String):
	if personaje_ref == null or not personaje_ref.is_inside_tree():
		return
	if personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("¡EVOLUCIÓN A %s!" % nombre_clase.to_upper(), Color(1.0, 0.9, 0.3))
	
	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.9, 0.4)
	luz.light_energy = 3.5
	luz.omni_range = 8.0
	personaje_ref.add_child(luz)
	luz.position = Vector3(0, 1.2, 0)
	
	var tween = personaje_ref.create_tween()
	if tween != null:
		tween.tween_property(luz, "light_energy", 0.0, 0.65)
		tween.tween_callback(luz.queue_free)
	else:
		luz.queue_free()
