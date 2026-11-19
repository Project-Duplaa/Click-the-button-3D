class_name AnimadorEntidad
extends RefCounted

## Controlador reutilizable de animaciones esqueléticas y transiciones por prioridad.
## Evita el reinicio de fotograma 0 en bucles activos y resuelve clips de respaldo
## entre variantes de personaje, enemigos y jefes.

const FALLBACKS := {
	"sprint": ["sprint", "run", "walk", "idle"],
	"run": ["run", "sprint", "walk", "idle"],
	"walk": ["walk", "run", "sprint", "idle"],
	"attack-melee-right": ["attack-melee-right", "attack-melee-left", "attack-ranged", "cast"],
	"attack-melee-left": ["attack-melee-left", "attack-melee-right", "attack-ranged", "cast"],
	"attack-ranged": ["attack-ranged", "cast", "holding-right-shoot", "attack-melee-right"],
	"cast": ["cast", "cast-magic", "attack-ranged", "attack-melee-right"],
	"cast-magic": ["cast-magic", "cast", "attack-ranged", "attack-melee-right"],
	"shoot-bow": ["shoot-bow", "holding-right-shoot", "attack-ranged", "attack-melee-right"],
	"whirlwind": ["whirlwind", "attack-melee-right", "spin"],
	"telegraph": ["telegraph", "crouch", "idle"],
	"stunned": ["stunned", "crouch", "idle"],
	"hit": ["hit", "emerge", "idle"],
	"fall": ["fall", "jump", "idle"],
	"jump": ["jump", "fall", "idle"],
	"idle": ["idle", "static"],
}

var _ap: AnimationPlayer = null
var _clips_disponibles: Dictionary = {}
var _clip_actual: String = ""
var _prioridad_bloqueo: int = 0
var _tiempo_bloqueo: float = 0.0
var _en_bucle: bool = false

static var _cache_mallas_fusionadas: Dictionary = {}


func _init(modelo_raiz: Node3D = null) -> void:
	if modelo_raiz != null:
		vincular_modelo(modelo_raiz)


func vincular_modelo(modelo_raiz: Node3D) -> void:
	optimizar_modelo_esqueletico(modelo_raiz)
	var es_jugador: bool = false
	var nodo_check: Node = modelo_raiz
	while nodo_check != null:
		if nodo_check.is_in_group("jugador") or nodo_check.is_in_group("player"):
			es_jugador = true
			break
		nodo_check = nodo_check.get_parent()
	estilizar_entidad_visual(modelo_raiz, es_jugador)
	_ap = buscar_animation_player(modelo_raiz)
	_clips_disponibles.clear()
	_clip_actual = ""
	_prioridad_bloqueo = 0
	_tiempo_bloqueo = 0.0
	_en_bucle = false
	if _ap != null:
		for anim_name in _ap.get_animation_list():
			_clips_disponibles[String(anim_name)] = true


func esta_listo() -> bool:
	return _ap != null and is_instance_valid(_ap)


func obtener_animation_player() -> AnimationPlayer:
	return _ap


func tiene_clip(nombre: String) -> bool:
	return _clips_disponibles.has(nombre)


func esta_bloqueado() -> bool:
	return _tiempo_bloqueo > 0.0


func limpiar_bloqueo() -> void:
	_tiempo_bloqueo = 0.0
	_prioridad_bloqueo = 0


func actualizar(delta: float) -> void:
	if _tiempo_bloqueo > 0.0:
		_tiempo_bloqueo = maxf(0.0, _tiempo_bloqueo - delta)
		if _tiempo_bloqueo <= 0.0:
			_prioridad_bloqueo = 0


func reproducir_bucle(nombre: String, blend: float = 0.14, velocidad: float = 1.0, prioridad: int = 0) -> bool:
	if not esta_listo():
		return false
	if _tiempo_bloqueo > 0.0 and prioridad < _prioridad_bloqueo:
		return false

	var clip := _resolver_clip(nombre)
	if clip.is_empty():
		return false

	var vel := clampf(velocidad, 0.25, 2.5)
	if clip in ["idle", "walk", "run", "sprint", "holding-both", "telegraph", "stunned", "fall", "static"]:
		var anim_res := _ap.get_animation(clip)
		if anim_res != null and anim_res.loop_mode == Animation.LOOP_NONE:
			anim_res.loop_mode = Animation.LOOP_LINEAR
	if _ap.current_animation == clip and _ap.is_playing():
		_ap.speed_scale = vel
		return true

	_ap.speed_scale = vel
	_ap.play(clip, blend)
	_clip_actual = clip
	_en_bucle = true
	return true


func reproducir_accion(nombre: String, prioridad: int = 2, blend: float = 0.07, velocidad: float = 1.0, duracion_bloqueo: float = -1.0) -> bool:
	if not esta_listo():
		return false
	if _tiempo_bloqueo > 0.0 and prioridad < _prioridad_bloqueo:
		return false

	var clip := _resolver_clip(nombre)
	if clip.is_empty():
		return false

	var vel := clampf(velocidad, 0.35, 3.0)
	var anim_res := _ap.get_animation(clip)
	var dur_real := 0.25
	if anim_res != null:
		dur_real = maxf(0.12, anim_res.length / vel)

	var bloqueo := duracion_bloqueo if duracion_bloqueo >= 0.0 else dur_real
	_prioridad_bloqueo = prioridad
	_tiempo_bloqueo = bloqueo
	_en_bucle = false
	_clip_actual = clip
	_ap.speed_scale = vel
	_ap.play(clip, blend)
	if _ap.current_animation_position > dur_real * 0.65:
		_ap.seek(0.0, true)
	return true


func disparar_golpe() -> void:
	# La reacción de daño nunca debe cortar un ataque principal o telegrafía de jefe
	if _tiempo_bloqueo > 0.0 and _prioridad_bloqueo >= 2:
		return
	if tiene_clip("hit"):
		reproducir_accion("hit", 1, 0.04, 1.15, 0.22)


func actualizar_locomocion(velocidad_actual: float, corriendo: bool = false, en_suelo: bool = true, velocidad_ref: float = 4.5) -> void:
	if not esta_listo() or esta_bloqueado():
		return

	if not en_suelo:
		if tiene_clip("fall"):
			reproducir_bucle("fall", 0.12, 1.0, 0)
			return

	if velocidad_actual <= 0.15:
		reproducir_bucle("idle", 0.16, 1.0, 0)
	elif corriendo or (velocidad_ref > 0.0 and velocidad_actual >= velocidad_ref * 1.25):
		var clip_rapido := "sprint" if tiene_clip("sprint") else "run"
		var escala := clampf(velocidad_actual / maxf(1.0, velocidad_ref * 1.35), 0.78, 1.55)
		reproducir_bucle(clip_rapido, 0.12, escala, 0)
	else:
		var escala_walk := clampf(velocidad_actual / maxf(1.0, velocidad_ref), 0.70, 1.45)
		reproducir_bucle("walk", 0.14, escala_walk, 0)


func _resolver_clip(nombre: String) -> String:
	if _clips_disponibles.has(nombre):
		return nombre
	if FALLBACKS.has(nombre):
		var lista: Array = FALLBACKS[nombre]
		for candidato in lista:
			var s := String(candidato)
			if _clips_disponibles.has(s):
				return s
	return ""


## Busca recursivamente un AnimationPlayer dentro del nodo.
static func buscar_animation_player(nodo: Node) -> AnimationPlayer:
	if nodo == null:
		return null
	if nodo.has_node("AnimationPlayer"):
		var directo := nodo.get_node("AnimationPlayer") as AnimationPlayer
		if directo != null:
			return directo
	for hijo in nodo.get_children():
		if hijo is AnimationPlayer:
			return hijo as AnimationPlayer
		var encontrado: AnimationPlayer = buscar_animation_player(hijo)
		if encontrado != null:
			return encontrado
	return null


## Busca recursivamente un Skeleton3D dentro del modelo.
static func buscar_skeleton3d(nodo: Node) -> Skeleton3D:
	if nodo == null:
		return null
	if nodo is Skeleton3D:
		return nodo as Skeleton3D
	for hijo in nodo.get_children():
		if hijo is Skeleton3D:
			return hijo as Skeleton3D
		var encontrado: Skeleton3D = buscar_skeleton3d(hijo)
		if encontrado != null:
			return encontrado
	return null


static func _obtener_o_crear_attachment(skeleton: Skeleton3D, nombre_hueso: String, nombre_nodo: String) -> BoneAttachment3D:
	var attach := skeleton.get_node_or_null(nombre_nodo) as BoneAttachment3D
	if attach == null:
		attach = BoneAttachment3D.new()
		attach.name = nombre_nodo
		var idx := skeleton.find_bone(nombre_hueso)
		if idx != -1:
			attach.bone_name = nombre_hueso
			attach.bone_idx = idx
		skeleton.add_child(attach)
	else:
		for hijo in attach.get_children():
			attach.remove_child(hijo)
			hijo.queue_free()
	return attach


## Monta armas representativas de cada clase directamente sobre arm-right y arm-left del Skeleton3D.
static func equipar_armas_en_esqueleto(modelo: Node3D, nombre_clase: String, incluir_particulas: bool = true) -> Dictionary:
	var skel := buscar_skeleton3d(modelo)
	if skel == null:
		return {}

	var resultado: Dictionary = {}

	# Los modelos oficiales de personaje (.glb) ya vienen con sus texturas de arte conceptual y volumetría 3D.
	# NUNCA inyectar geometría procedural de cajas (BoxMesh) o esferas (SphereMesh).
	var es_modelo_oficial := true

	if es_modelo_oficial:
		# El modelo ya tiene todo su equipamiento 3D horneado en el .glb (ropa, mochila, casco/pelo, armas)
		# No generar geometría procedural duplicada. Enlazar referencias de armas existentes.
		var node_der = skel.get_node_or_null("arm-right")
		var node_izq = skel.get_node_or_null("arm-left")
		if node_der != null:
			resultado["derecha"] = node_der
		if node_izq != null:
			resultado["izquierda"] = node_izq
			resultado["escudo"] = node_izq
		return resultado

	var attach_der := _obtener_o_crear_attachment(skel, "arm-right", "BoneAttach_ArmRight")
	var attach_izq := _obtener_o_crear_attachment(skel, "arm-left", "BoneAttach_ArmLeft")
	var attach_torso := _obtener_o_crear_attachment(skel, "torso", "BoneAttach_Torso")
	var attach_head := _obtener_o_crear_attachment(skel, "head", "BoneAttach_Head")
	var attach_leg_izq := _obtener_o_crear_attachment(skel, "leg-left", "BoneAttach_LegLeft")
	var attach_leg_der := _obtener_o_crear_attachment(skel, "leg-right", "BoneAttach_LegRight")

	# Coordenadas locales exactas de la palma en los rigs Kenney (sin escala)
	var offset_der := Vector3(-0.23, 0.0, 0.02)
	var offset_izq := Vector3(0.23, 0.0, 0.02)

	match nombre_clase:
		"Novato", "Recluta del Coliseo":
			# Bastón taser electrificado de supervivencia (Concept Art: player_rookie.glb)
			var taser_data := _crear_baston_taser_novato(incluir_particulas)
			var baston := taser_data["nodo"] as Node3D
			baston.position = offset_der
			baston.rotation_degrees = Vector3(15.0, 0.0, -10.0)
			attach_der.add_child(baston)
			resultado["derecha"] = baston
			if taser_data.has("luz"):
				resultado["luz_taser"] = taser_data["luz"]

			# Mochila táctica caqui con linterna ámbar y radio walkie-talkie
			var mochila := _crear_mochila_supervivencia_novato()
			mochila.position = Vector3(0.0, 0.12, -0.14)
			attach_torso.add_child(mochila)

			# Chaleco de alta visibilidad reflectante amarillo neón
			var chaleco := _crear_chaleco_seguridad_novato()
			chaleco.position = Vector3(0.0, 0.10, 0.01)
			attach_torso.add_child(chaleco)

			# Casco industrial con visera y barboquejo
			var casco := _crear_casco_novato()
			casco.position = Vector3(0.0, 0.14, 0.0)
			attach_head.add_child(casco)

			# Rodilleras de protección tácticas
			var rod_izq := _crear_rodillera_novato()
			rod_izq.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_izq.add_child(rod_izq)

			var rod_der := _crear_rodillera_novato()
			rod_der.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_der.add_child(rod_der)

		"Guerrero", "Murmillo":
			# Martillo cinético de brecha pesado (Concept Art: player_warrior.glb)
			var martillo_data := _crear_martillo_cinetico_guerrero(incluir_particulas)
			var martillo := martillo_data["nodo"] as Node3D
			martillo.position = offset_der
			martillo.rotation_degrees = Vector3(15.0, 0.0, -10.0)
			attach_der.add_child(martillo)
			resultado["derecha"] = martillo
			if martillo_data.has("luz"):
				resultado["luz_martillo"] = martillo_data["luz"]

			# Escudo de brecha balístico pesado (Concept Art: player_warrior.glb)
			var escudo_data := _crear_escudo_brecha_guerrero(incluir_particulas)
			var escudo := escudo_data["nodo"] as Node3D
			escudo.position = offset_izq
			escudo.rotation_degrees = Vector3(0.0, 0.0, 0.0)
			attach_izq.add_child(escudo)
			resultado["izquierda"] = escudo
			resultado["escudo"] = escudo
			if escudo_data.has("luz"):
				resultado["luz_escudo"] = escudo_data["luz"]

			# Casco balístico pesado con visor cian y máscara de gas de doble filtro
			var casco := _crear_casco_balistico_guerrero()
			casco.position = Vector3(0.0, 0.08, 0.0)
			attach_head.add_child(casco)

			# Armadura de torso: Peto blindado, placas abdominales, hombreras dobles masivas,
			# cinturón táctico naranja con bolsillos, faldón y gran espada envainada en la espalda
			var armadura := _crear_armadura_torso_guerrero()
			armadura.position = Vector3(0.0, 0.12, 0.0)
			attach_torso.add_child(armadura)

			# Guanteletes tácticos pesados en antebrazos
			var guant_izq := _crear_guantelete_pesado_guerrero()
			guant_izq.position = Vector3(0.12, 0.0, 0.0)
			attach_izq.add_child(guant_izq)

			var guant_der := _crear_guantelete_pesado_guerrero()
			guant_der.position = Vector3(-0.12, 0.0, 0.0)
			attach_der.add_child(guant_der)

			# Rodilleras y espinilleras con doble correa naranja
			var pierna_izq := _crear_proteccion_pierna_guerrero()
			pierna_izq.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_izq.add_child(pierna_izq)

			var pierna_der := _crear_proteccion_pierna_guerrero()
			pierna_der.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_der.add_child(pierna_der)
		"Cazador", "Arquero", "Sagittario":
			# Arco tecnológico Sci-Fi (Concept Art: player_archer.glb)
			var arco_data := _crear_arco_tecnologico_cazador(incluir_particulas)
			var arco := arco_data["nodo"] as Node3D
			arco.position = offset_izq
			arco.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			attach_izq.add_child(arco)
			resultado["izquierda"] = arco
			if arco_data.has("luz"):
				resultado["luz_arco"] = arco_data["luz"]

			# Guantelete táctico en antebrazo izquierdo (brazo del arco)
			var guantelete_izq := _crear_guantelete_cazador()
			guantelete_izq.position = Vector3(0.12, 0.0, 0.0)
			attach_izq.add_child(guantelete_izq)

			# Guantelete táctico en antebrazo derecho (brazo que tensa la cuerda)
			var guantelete_der := _crear_guantelete_cazador()
			guantelete_der.position = Vector3(-0.12, 0.0, 0.0)
			attach_der.add_child(guantelete_der)

			# Carcaj tecnológico en la espalda con batería de energía y flechas cian
			var carcaj := _crear_carcaj_tecnologico_cazador(incluir_particulas)
			carcaj.position = Vector3(0.08, 0.14, -0.15)
			carcaj.rotation_degrees = Vector3(15.0, 0.0, -20.0)
			attach_torso.add_child(carcaj)

			# Bufanda / cuello naranja táctico de superviviente
			var bufanda := _crear_bufanda_naranja_cazador()
			bufanda.position = Vector3(0.0, 0.32, 0.02)
			attach_torso.add_child(bufanda)

			# Armadura de hombreras, arnés diagonal con cartuchos, cinturón con bolsillos y pistolera
			var armadura := _crear_armadura_pecho_cazador()
			armadura.position = Vector3(0.0, 0.12, 0.0)
			attach_torso.add_child(armadura)

			# Cabello castaño despeinado, visor HUD holográfico cian y máscara de gas respirador
			var visor := _crear_visor_hud_mascara_cazador()
			visor.position = Vector3(0.0, 0.08, 0.0)
			attach_head.add_child(visor)

			# Rodilleras tácticas con doble correa naranja
			var rod_izq := _crear_rodillera_cazador()
			rod_izq.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_izq.add_child(rod_izq)

			var rod_der := _crear_rodillera_cazador()
			rod_der.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_der.add_child(rod_der)
		"Mago", "Arúspice":
			# Báculo Cápsula de Plasma Arcano (Concept Art: player_mage.glb)
			var baston_data := _crear_baston_capsula_mago(incluir_particulas)
			var baston := baston_data["nodo"] as Node3D
			baston.position = offset_der
			# Inclinación ligera para que el báculo vertical (+Y) luzca erguido en guardia
			baston.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(baston)
			resultado["derecha"] = baston
			if baston_data.has("luz"):
				resultado["luz_orbe"] = baston_data["luz"]

			# Fuego Arcano en mano izquierda y brazal táctico
			var fuego_data := _crear_fuego_arcano_mago(incluir_particulas)
			var fuego := fuego_data["nodo"] as Node3D
			fuego.position = offset_izq
			attach_izq.add_child(fuego)
			resultado["izquierda"] = fuego
			if fuego_data.has("luz"):
				resultado["luz_fuego"] = fuego_data["luz"]

			# Cabeza: Cabello despeinado, gafas HUD cian, máscara de gas y bufanda naranja
			var cabeza := _crear_cabeza_mago()
			cabeza.position = Vector3(0.0, 0.08, 0.0)
			attach_head.add_child(cabeza)

			# Torso: Gabardina larga, arnés con viales verdes, cinturón con viales cian y frascos
			var gabardina := _crear_gabardina_arcanista_mago()
			gabardina.position = Vector3(0.0, 0.12, 0.0)
			attach_torso.add_child(gabardina)

			# Piernas: Rodilleras tácticas, correas de cuero dobles en muslo derecho y botas
			var pierna_izq := _crear_proteccion_pierna_mago(false)
			pierna_izq.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_izq.add_child(pierna_izq)

			var pierna_der := _crear_proteccion_pierna_mago(true)
			pierna_der.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_der.add_child(pierna_der)
		"Secutor Radiante", "Paladín del Sol Invictus", "Paladín Solar":
			var gran_espada_solar := _crear_gran_espada_paladin()
			gran_espada_solar.position = offset_der
			attach_der.add_child(gran_espada_solar)
			resultado["derecha"] = gran_espada_solar

			var escudo_solar := _crear_escudo_paladin()
			escudo_solar.position = offset_izq
			attach_izq.add_child(escudo_solar)
			resultado["izquierda"] = escudo_solar
		"Provocator Sangriento", "Campeón Augusto de Sangre", "Berserker Sangriento":
			var hacha_der := _crear_hacha_berserker(incluir_particulas)
			hacha_der.position = offset_der
			attach_der.add_child(hacha_der)
			resultado["derecha"] = hacha_der

			var hacha_izq := _crear_hacha_berserker(incluir_particulas)
			hacha_izq.position = offset_izq
			hacha_izq.rotation_degrees = Vector3(0.0, 180.0, 0.0)
			attach_izq.add_child(hacha_izq)
			resultado["izquierda"] = hacha_izq
		"Velites Balístico", "Centurión Balístico Astral", "Francotirador Astral":
			var arco_astral := _crear_arco_astral(incluir_particulas)
			arco_astral.position = offset_izq
			arco_astral.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			attach_izq.add_child(arco_astral)
			resultado["izquierda"] = arco_astral

			var carcaj_astral := _crear_carcaj_tecnologico_cazador(incluir_particulas)
			carcaj_astral.position = Vector3(0.08, 0.14, -0.15)
			carcaj_astral.rotation_degrees = Vector3(15.0, 0.0, -20.0)
			attach_torso.add_child(carcaj_astral)

			var bufanda_a := _crear_bufanda_naranja_cazador()
			bufanda_a.position = Vector3(0.0, 0.32, 0.02)
			attach_torso.add_child(bufanda_a)

			var visor_a := _crear_visor_hud_mascara_cazador()
			visor_a.position = Vector3(0.0, 0.08, 0.0)
			attach_head.add_child(visor_a)

			var rod_izq_a := _crear_rodillera_cazador()
			rod_izq_a.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_izq.add_child(rod_izq_a)

			var rod_der_a := _crear_rodillera_cazador()
			rod_der_a.position = Vector3(0.0, -0.22, 0.10)
			attach_leg_der.add_child(rod_der_a)
		"Dimachaerus Espectral", "Sombra del Anfiteatro", "Maestro de Sombras":
			var daga_der := _crear_daga_sombra(incluir_particulas, false)
			daga_der.position = offset_der
			attach_der.add_child(daga_der)
			resultado["derecha"] = daga_der

			var daga_izq := _crear_daga_sombra(incluir_particulas, true)
			daga_izq.position = offset_izq
			attach_izq.add_child(daga_izq)
			resultado["izquierda"] = daga_izq
		"Taumaturgo del Vacío", "Pontífice del Vacío Estelar", "Archimago del Vacío":
			var baston_vacio := _crear_baston_vacio(incluir_particulas)
			var b_v := baston_vacio["nodo"] as Node3D
			b_v.position = offset_der
			b_v.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(b_v)
			resultado["derecha"] = b_v
			if baston_vacio.has("luz"):
				resultado["luz_orbe"] = baston_vacio["luz"]
		"Flamen Volcánico", "Señor del Magma Imperial", "Piromante Cataclísmico":
			var baston_piro := _crear_baston_piromante(incluir_particulas)
			var b_p := baston_piro["nodo"] as Node3D
			b_p.position = offset_der
			b_p.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(b_p)
			resultado["derecha"] = b_p
			if baston_piro.has("luz"):
				resultado["luz_orbe"] = baston_piro["luz"]
		"Custodio del Núcleo", "Titán Supremo del Núcleo", "Avatar del Núcleo":
			var gauntlet := _crear_guantelete_avatar()
			gauntlet.position = offset_der
			attach_der.add_child(gauntlet)
			resultado["derecha"] = gauntlet

			var prisma := _crear_prisma_avatar(incluir_particulas)
			prisma.position = offset_izq + Vector3(0.0, 0.12, 0.0)
			attach_izq.add_child(prisma)
			resultado["izquierda"] = prisma
		_:
			pass

	return resultado


static func _mat_simple(albedo: Color, metallic: float = 0.0, roughness: float = 0.45, emision: Color = Color.BLACK, intensidad_emision: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if intensidad_emision > 0.0:
		mat.emission_enabled = true
		mat.emission = emision
		mat.emission_energy_multiplier = intensidad_emision
	return mat


static func _crear_baston_taser_novato(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "BastonTaserNovato"

	var mat_goma := _mat_simple(Color(0.14, 0.15, 0.18), 0.1, 0.7)
	var mat_acero := _mat_simple(Color(0.72, 0.75, 0.82), 0.85, 0.28)
	var mat_cobre := _mat_simple(Color(0.85, 0.45, 0.16), 0.75, 0.32)
	var mat_cristal_energia := _mat_simple(Color(0.20, 0.95, 0.85, 0.7), 0.1, 0.1, Color(0.15, 0.95, 0.85), 1.8)
	mat_cristal_energia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# 1. Empuñadura de goma acanalada
	var mango := MeshInstance3D.new()
	var cyl_mango := CylinderMesh.new()
	cyl_mango.top_radius = 0.020
	cyl_mango.bottom_radius = 0.022
	cyl_mango.height = 0.18
	mango.mesh = cyl_mango
	mango.rotation_degrees.x = 90.0
	mango.position = Vector3(0, 0, -0.06)
	mango.material_override = mat_goma
	root.add_child(mango)

	# Pomo metálico de seguridad posterior
	var pomo := MeshInstance3D.new()
	var cyl_pomo := CylinderMesh.new()
	cyl_pomo.top_radius = 0.026
	cyl_pomo.bottom_radius = 0.024
	cyl_pomo.height = 0.03
	pomo.mesh = cyl_pomo
	pomo.rotation_degrees.x = 90.0
	pomo.position = Vector3(0, 0, -0.155)
	pomo.material_override = mat_acero
	root.add_child(pomo)

	# Collarín de acople central
	var collar := MeshInstance3D.new()
	var cyl_collar := CylinderMesh.new()
	cyl_collar.top_radius = 0.026
	cyl_collar.bottom_radius = 0.026
	cyl_collar.height = 0.035
	collar.mesh = cyl_collar
	collar.rotation_degrees.x = 90.0
	collar.position = Vector3(0, 0, 0.035)
	collar.material_override = mat_acero
	root.add_child(collar)

	# 2. Vial capacitador de energía cian radiactiva
	var vial := MeshInstance3D.new()
	var cyl_vial := CylinderMesh.new()
	cyl_vial.top_radius = 0.024
	cyl_vial.bottom_radius = 0.024
	cyl_vial.height = 0.16
	vial.mesh = cyl_vial
	vial.rotation_degrees.x = 90.0
	vial.position = Vector3(0, 0, 0.12)
	vial.material_override = mat_cristal_energia
	root.add_child(vial)

	# Anillos/bobinas de inducción de cobre enrollados
	for i in range(3):
		var bobina := MeshInstance3D.new()
		var cyl_bobina := CylinderMesh.new()
		cyl_bobina.top_radius = 0.027
		cyl_bobina.bottom_radius = 0.027
		cyl_bobina.height = 0.015
		bobina.mesh = cyl_bobina
		bobina.rotation_degrees.x = 90.0
		bobina.position = Vector3(0, 0, 0.07 + (float(i) * 0.05))
		bobina.material_override = mat_cobre
		root.add_child(bobina)

	# 3. Cañón de descarga y electrodos metálicos frontales
	var boquilla := MeshInstance3D.new()
	var cyl_boq := CylinderMesh.new()
	cyl_boq.top_radius = 0.023
	cyl_boq.bottom_radius = 0.026
	cyl_boq.height = 0.06
	boquilla.mesh = cyl_boq
	boquilla.rotation_degrees.x = 90.0
	boquilla.position = Vector3(0, 0, 0.22)
	boquilla.material_override = mat_acero
	root.add_child(boquilla)

	# Doble electrodo frontal taser
	for sx in [-0.013, 0.013]:
		var electrodo := MeshInstance3D.new()
		var box_elec := BoxMesh.new()
		box_elec.size = Vector3(0.006, 0.006, 0.055)
		electrodo.mesh = box_elec
		electrodo.position = Vector3(sx, 0, 0.27)
		electrodo.material_override = mat_acero
		root.add_child(electrodo)

	var luz: OmniLight3D = null
	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.name = "ChispasTaser"
		part.amount = 12
		part.lifetime = 0.18
		part.explosiveness = 0.35
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.025
		part.direction = Vector3(0, 0, 1)
		part.spread = 45.0
		part.gravity = Vector3.ZERO
		part.initial_velocity_min = 0.4
		part.initial_velocity_max = 1.0
		part.color = Color(0.3, 0.95, 1.0, 0.9)

		var mesh_p := BoxMesh.new()
		mesh_p.size = Vector3(0.007, 0.007, 0.016)
		part.mesh = mesh_p
		part.position = Vector3(0, 0, 0.30)
		root.add_child(part)

		luz = OmniLight3D.new()
		luz.name = "LuzTaser"
		luz.light_color = Color(0.18, 0.95, 0.92)
		luz.light_energy = 0.75
		luz.omni_range = 1.5
		luz.position = Vector3(0, 0, 0.20)
		root.add_child(luz)

	var res: Dictionary = {"nodo": root}
	if luz != null:
		res["luz"] = luz
	return res


static func _crear_mochila_supervivencia_novato() -> Node3D:
	var root := Node3D.new()
	root.name = "MochilaSupervivencia"

	var mat_lona := _mat_simple(Color(0.55, 0.45, 0.32), 0.05, 0.65)
	var mat_lona_oscura := _mat_simple(Color(0.42, 0.34, 0.24), 0.05, 0.70)
	var mat_cuero := _mat_simple(Color(0.24, 0.15, 0.09), 0.05, 0.55)
	var mat_metal := _mat_simple(Color(0.75, 0.78, 0.82), 0.85, 0.30)
	var mat_linterna := _mat_simple(Color(1.0, 0.72, 0.18), 0.1, 0.1, Color(1.0, 0.65, 0.12), 1.6)
	var mat_radio := _mat_simple(Color(0.16, 0.18, 0.22), 0.2, 0.5)

	# Cuerpo principal de la mochila (lona caqui)
	var cuerpo := MeshInstance3D.new()
	var box_cuerpo := BoxMesh.new()
	box_cuerpo.size = Vector3(0.24, 0.30, 0.14)
	cuerpo.mesh = box_cuerpo
	cuerpo.material_override = mat_lona
	root.add_child(cuerpo)

	# Tapa superior
	var tapa := MeshInstance3D.new()
	var box_tapa := BoxMesh.new()
	box_tapa.size = Vector3(0.25, 0.07, 0.15)
	tapa.mesh = box_tapa
	tapa.position = Vector3(0.0, 0.14, 0.0)
	tapa.material_override = mat_lona_oscura
	root.add_child(tapa)

	# Bolsillo frontal exterior
	var bolsillo := MeshInstance3D.new()
	var box_bolsillo := BoxMesh.new()
	box_bolsillo.size = Vector3(0.18, 0.14, 0.06)
	bolsillo.mesh = box_bolsillo
	bolsillo.position = Vector3(0.0, -0.05, -0.09)
	bolsillo.material_override = mat_lona_oscura
	root.add_child(bolsillo)

	# Correas verticales de cuero con hebillas
	for sx in [-0.06, 0.06]:
		var correa := MeshInstance3D.new()
		var box_correa := BoxMesh.new()
		box_correa.size = Vector3(0.022, 0.28, 0.015)
		correa.mesh = box_correa
		correa.position = Vector3(sx, 0.02, -0.072)
		correa.material_override = mat_cuero
		root.add_child(correa)

		var hebilla := MeshInstance3D.new()
		var box_heb := BoxMesh.new()
		box_heb.size = Vector3(0.026, 0.018, 0.02)
		hebilla.mesh = box_heb
		hebilla.position = Vector3(sx, 0.06, -0.075)
		hebilla.material_override = mat_metal
		root.add_child(hebilla)

	# Lateral izquierdo: Linterna / cilindro de energía ámbar
	var linterna := MeshInstance3D.new()
	var cyl_linterna := CylinderMesh.new()
	cyl_linterna.top_radius = 0.026
	cyl_linterna.bottom_radius = 0.026
	cyl_linterna.height = 0.15
	linterna.mesh = cyl_linterna
	linterna.position = Vector3(-0.14, -0.02, 0.0)
	linterna.material_override = mat_linterna
	root.add_child(linterna)

	var luz_lint := OmniLight3D.new()
	luz_lint.name = "LuzLinternaMochila"
	luz_lint.light_color = Color(1.0, 0.65, 0.15)
	luz_lint.light_energy = 0.55
	luz_lint.omni_range = 1.3
	luz_lint.position = Vector3(-0.14, -0.02, -0.04)
	root.add_child(luz_lint)

	# Lateral derecho: Radio walkie-talkie con antena
	var radio := MeshInstance3D.new()
	var box_radio := BoxMesh.new()
	box_radio.size = Vector3(0.04, 0.10, 0.05)
	radio.mesh = box_radio
	radio.position = Vector3(0.14, 0.02, 0.0)
	radio.material_override = mat_radio
	root.add_child(radio)

	var antena := MeshInstance3D.new()
	var cyl_ant := CylinderMesh.new()
	cyl_ant.top_radius = 0.003
	cyl_ant.bottom_radius = 0.005
	cyl_ant.height = 0.14
	antena.mesh = cyl_ant
	antena.position = Vector3(0.14, 0.13, 0.0)
	antena.material_override = mat_metal
	root.add_child(antena)

	return root


static func _crear_chaleco_seguridad_novato() -> Node3D:
	var root := Node3D.new()
	root.name = "ChalecoSeguridad"

	var mat_chaleco := _mat_simple(Color(0.76, 0.88, 0.08), 0.05, 0.55)
	var mat_reflectante := _mat_simple(Color(0.92, 0.95, 0.98), 0.75, 0.20, Color(0.85, 0.95, 1.0), 0.3)
	var mat_cremallera := _mat_simple(Color(0.20, 0.22, 0.26), 0.6, 0.4)

	var pecho := MeshInstance3D.new()
	var box_pecho := BoxMesh.new()
	box_pecho.size = Vector3(0.27, 0.25, 0.17)
	pecho.mesh = box_pecho
	pecho.position = Vector3(0.0, 0.02, 0.0)
	pecho.material_override = mat_chaleco
	root.add_child(pecho)

	var banda_inf := MeshInstance3D.new()
	var box_inf := BoxMesh.new()
	box_inf.size = Vector3(0.274, 0.032, 0.174)
	banda_inf.mesh = box_inf
	banda_inf.position = Vector3(0.0, -0.05, 0.0)
	banda_inf.material_override = mat_reflectante
	root.add_child(banda_inf)

	var banda_sup := MeshInstance3D.new()
	var box_sup := BoxMesh.new()
	box_sup.size = Vector3(0.274, 0.032, 0.174)
	banda_sup.mesh = box_sup
	banda_sup.position = Vector3(0.0, 0.06, 0.0)
	banda_sup.material_override = mat_reflectante
	root.add_child(banda_sup)

	for sx in [-0.08, 0.08]:
		var tira := MeshInstance3D.new()
		var box_tira := BoxMesh.new()
		box_tira.size = Vector3(0.032, 0.18, 0.174)
		tira.mesh = box_tira
		tira.position = Vector3(sx, 0.05, 0.0)
		tira.material_override = mat_reflectante
		root.add_child(tira)

	var crem := MeshInstance3D.new()
	var box_crem := BoxMesh.new()
	box_crem.size = Vector3(0.016, 0.25, 0.175)
	crem.mesh = box_crem
	crem.position = Vector3(0.0, 0.02, 0.0)
	crem.material_override = mat_cremallera
	root.add_child(crem)

	return root


static func _crear_casco_novato() -> Node3D:
	var root := Node3D.new()
	root.name = "CascoNovato"

	var mat_casco := _mat_simple(Color(0.58, 0.54, 0.46), 0.1, 0.55)
	var mat_correa := _mat_simple(Color(0.18, 0.15, 0.12), 0.05, 0.70)
	var mat_metal := _mat_simple(Color(0.70, 0.72, 0.76), 0.8, 0.30)

	var cupula := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.155
	sph.height = 0.22
	cupula.mesh = sph
	cupula.scale = Vector3(1.05, 0.75, 1.15)
	cupula.position = Vector3(0.0, 0.06, -0.01)
	cupula.material_override = mat_casco
	root.add_child(cupula)

	var visera := MeshInstance3D.new()
	var cyl_vis := CylinderMesh.new()
	cyl_vis.top_radius = 0.18
	cyl_vis.bottom_radius = 0.185
	cyl_vis.height = 0.022
	visera.mesh = cyl_vis
	visera.scale = Vector3(1.0, 1.0, 1.15)
	visera.position = Vector3(0.0, 0.02, 0.02)
	visera.material_override = mat_casco
	root.add_child(visera)

	for sx in [-0.15, 0.15]:
		var remache := MeshInstance3D.new()
		var cyl_rem := CylinderMesh.new()
		cyl_rem.top_radius = 0.01
		cyl_rem.bottom_radius = 0.01
		cyl_rem.height = 0.015
		remache.mesh = cyl_rem
		remache.rotation_degrees.z = 90.0
		remache.position = Vector3(sx, 0.02, 0.0)
		remache.material_override = mat_metal
		root.add_child(remache)

	var barboquejo := MeshInstance3D.new()
	var box_barb := BoxMesh.new()
	box_barb.size = Vector3(0.16, 0.015, 0.015)
	barboquejo.mesh = box_barb
	barboquejo.position = Vector3(0.0, -0.11, 0.06)
	barboquejo.material_override = mat_correa
	root.add_child(barboquejo)

	return root


static func _crear_rodillera_novato() -> Node3D:
	var root := Node3D.new()
	root.name = "RodilleraNovato"

	var mat_placa := _mat_simple(Color(0.24, 0.26, 0.30), 0.15, 0.50)
	var mat_correa := _mat_simple(Color(0.12, 0.12, 0.14), 0.05, 0.70)

	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.08, 0.09, 0.035)
	placa.mesh = box_placa
	placa.material_override = mat_placa
	root.add_child(placa)

	for sy in [-0.03, 0.03]:
		var correa := MeshInstance3D.new()
		var box_c := BoxMesh.new()
		box_c.size = Vector3(0.095, 0.018, 0.06)
		correa.mesh = box_c
		correa.position = Vector3(0, sy, -0.015)
		correa.material_override = mat_correa
		root.add_child(correa)

	return root


static func _crear_gran_espada_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "GranEspadaGuerrero"
	var mat_grip := _mat_simple(Color(0.22, 0.15, 0.10), 0.0, 0.55)
	var mat_oro := _mat_simple(Color(0.92, 0.76, 0.25), 0.92, 0.20)
	var mat_hoja := _mat_simple(Color(0.90, 0.92, 0.98), 0.95, 0.20)
	var mat_runa := _mat_simple(Color(1.0, 0.55, 0.15), 0.0, 0.3, Color(1.0, 0.50, 0.10), 3.2)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.026, 0.026, 0.14)
	grip.mesh = box_grip
	grip.position = Vector3(0, 0, -0.065)
	grip.material_override = mat_grip
	root.add_child(grip)

	var pomo := MeshInstance3D.new()
	var box_pomo := BoxMesh.new()
	box_pomo.size = Vector3(0.04, 0.04, 0.03)
	pomo.mesh = box_pomo
	pomo.position = Vector3(0, 0, -0.14)
	pomo.material_override = mat_oro
	root.add_child(pomo)

	var guard := MeshInstance3D.new()
	var box_guard := BoxMesh.new()
	box_guard.size = Vector3(0.16, 0.034, 0.028)
	guard.mesh = box_guard
	guard.position = Vector3(0, 0, 0.015)
	guard.material_override = mat_oro
	root.add_child(guard)

	var hoja := MeshInstance3D.new()
	var box_hoja := BoxMesh.new()
	box_hoja.size = Vector3(0.068, 0.015, 0.54)
	hoja.mesh = box_hoja
	hoja.position = Vector3(0, 0, 0.295)
	hoja.material_override = mat_hoja
	root.add_child(hoja)

	var runa := MeshInstance3D.new()
	var box_runa := BoxMesh.new()
	box_runa.size = Vector3(0.020, 0.018, 0.38)
	runa.mesh = box_runa
	runa.position = Vector3(0, 0, 0.28)
	runa.material_override = mat_runa
	root.add_child(runa)
	return root


static func _crear_escudo_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "EscudoGuerrero"
	var mat_placa := _mat_simple(Color(0.22, 0.28, 0.38), 0.80, 0.35)
	var mat_borde := _mat_simple(Color(0.92, 0.76, 0.25), 0.92, 0.22)
	var mat_umbo := _mat_simple(Color(0.9, 0.15, 0.22), 0.2, 0.3, Color(0.95, 0.18, 0.25), 2.0)

	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.24, 0.30, 0.025)
	placa.mesh = box_placa
	placa.position = Vector3(0.0, 0.0, 0.05)
	placa.material_override = mat_placa
	root.add_child(placa)

	var borde := MeshInstance3D.new()
	var box_borde := BoxMesh.new()
	box_borde.size = Vector3(0.26, 0.32, 0.020)
	borde.mesh = box_borde
	borde.position = Vector3(0.0, 0.0, 0.044)
	borde.material_override = mat_borde
	root.add_child(borde)

	var umbo := MeshInstance3D.new()
	var box_umbo := BoxMesh.new()
	box_umbo.size = Vector3(0.08, 0.08, 0.032)
	umbo.mesh = box_umbo
	umbo.position = Vector3(0.0, 0.0, 0.062)
	umbo.material_override = mat_umbo
	root.add_child(umbo)
	return root


## Martillo Cinético Pesado de Brecha (Concept Art: player_warrior.glb)
static func _crear_martillo_cinetico_guerrero(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "MartilloCineticoGuerrero"

	var mat_acero := _mat_simple(Color(0.28, 0.30, 0.34), 0.88, 0.32)
	var mat_acero_oscuro := _mat_simple(Color(0.18, 0.20, 0.23), 0.82, 0.45)
	var mat_engranaje := _mat_simple(Color(0.54, 0.58, 0.64), 0.92, 0.22)
	var mat_goma := _mat_simple(Color(0.12, 0.13, 0.15), 0.05, 0.75)
	var mat_naranja := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)
	var mat_plasma_cian := _mat_simple(Color(0.25, 0.95, 1.0), 0.2, 0.1, Color(0.15, 0.90, 1.0), 2.2)

	# 1. Asta / Mango principal reforzado (a lo largo del eje Z)
	var asta := MeshInstance3D.new()
	var mesh_asta := CylinderMesh.new()
	mesh_asta.top_radius = 0.020
	mesh_asta.bottom_radius = 0.020
	mesh_asta.height = 0.68
	mesh_asta.radial_segments = 12
	asta.mesh = mesh_asta
	asta.rotation_degrees = Vector3(90, 0, 0)
	asta.position = Vector3(0, 0, 0.02)
	asta.material_override = mat_acero
	root.add_child(asta)

	# 2. Empuñaduras de goma acanalada (Sección inferior y superior)
	var grip_inf := MeshInstance3D.new()
	var mesh_grip_inf := CylinderMesh.new()
	mesh_grip_inf.top_radius = 0.024
	mesh_grip_inf.bottom_radius = 0.024
	mesh_grip_inf.height = 0.15
	mesh_grip_inf.radial_segments = 12
	grip_inf.mesh = mesh_grip_inf
	grip_inf.rotation_degrees = Vector3(90, 0, 0)
	grip_inf.position = Vector3(0, 0, -0.16)
	grip_inf.material_override = mat_goma
	root.add_child(grip_inf)

	var grip_sup := MeshInstance3D.new()
	var mesh_grip_sup := CylinderMesh.new()
	mesh_grip_sup.top_radius = 0.024
	mesh_grip_sup.bottom_radius = 0.024
	mesh_grip_sup.height = 0.15
	mesh_grip_sup.radial_segments = 12
	grip_sup.mesh = mesh_grip_sup
	grip_sup.rotation_degrees = Vector3(90, 0, 0)
	grip_sup.position = Vector3(0, 0, 0.09)
	grip_sup.material_override = mat_goma
	root.add_child(grip_sup)

	# Anillos acanalados en el mango
	for z_pos in [-0.21, -0.16, -0.11, 0.04, 0.09, 0.14]:
		var anillo := MeshInstance3D.new()
		var mesh_anillo := TorusMesh.new()
		mesh_anillo.inner_radius = 0.022
		mesh_anillo.outer_radius = 0.027
		anillo.mesh = mesh_anillo
		anillo.rotation_degrees = Vector3(90, 0, 0)
		anillo.position = Vector3(0, 0, z_pos)
		anillo.material_override = mat_acero_oscuro
		root.add_child(anillo)

	# 3. Pomo / Contrapeso inferior con aro de anclaje
	var pomo_tapa := MeshInstance3D.new()
	var mesh_pomo := CylinderMesh.new()
	mesh_pomo.top_radius = 0.032
	mesh_pomo.bottom_radius = 0.032
	mesh_pomo.height = 0.035
	pomo_tapa.mesh = mesh_pomo
	pomo_tapa.rotation_degrees = Vector3(90, 0, 0)
	pomo_tapa.position = Vector3(0, 0, -0.32)
	pomo_tapa.material_override = mat_acero_oscuro
	root.add_child(pomo_tapa)

	var pomo_aro := MeshInstance3D.new()
	var mesh_aro := TorusMesh.new()
	mesh_aro.inner_radius = 0.016
	mesh_aro.outer_radius = 0.036
	pomo_aro.mesh = mesh_aro
	pomo_aro.position = Vector3(0, 0, -0.345)
	pomo_aro.material_override = mat_acero
	root.add_child(pomo_aro)

	var anillo_naranja := MeshInstance3D.new()
	var mesh_an_n := TorusMesh.new()
	mesh_an_n.inner_radius = 0.022
	mesh_an_n.outer_radius = 0.028
	anillo_naranja.mesh = mesh_an_n
	anillo_naranja.rotation_degrees = Vector3(90, 0, 0)
	anillo_naranja.position = Vector3(0, 0, -0.30)
	anillo_naranja.material_override = mat_naranja
	root.add_child(anillo_naranja)

	# 4. Cuello y collarín octogonal de fijación a la cabeza
	var cuello := MeshInstance3D.new()
	var mesh_cuello := CylinderMesh.new()
	mesh_cuello.top_radius = 0.040
	mesh_cuello.bottom_radius = 0.036
	mesh_cuello.height = 0.06
	mesh_cuello.radial_segments = 8
	cuello.mesh = mesh_cuello
	cuello.rotation_degrees = Vector3(90, 0, 0)
	cuello.position = Vector3(0, 0, 0.31)
	cuello.material_override = mat_acero_oscuro
	root.add_child(cuello)

	# 5. Cabeza Monolítica del Martillo
	var cabeza := MeshInstance3D.new()
	var box_cabeza := BoxMesh.new()
	box_cabeza.size = Vector3(0.20, 0.22, 0.28)
	cabeza.mesh = box_cabeza
	cabeza.position = Vector3(0, 0.04, 0.46)
	cabeza.material_override = mat_acero
	root.add_child(cabeza)

	# Placas de refuerzo superior e inferior con remaches
	for y_offset in [-0.07, 0.15]:
		var bracket := MeshInstance3D.new()
		var box_br := BoxMesh.new()
		box_br.size = Vector3(0.21, 0.02, 0.27)
		bracket.mesh = box_br
		bracket.position = Vector3(0, y_offset, 0.46)
		bracket.material_override = mat_acero_oscuro
		root.add_child(bracket)

		for rx in [-0.09, 0.09]:
			for rz in [0.35, 0.57]:
				var remache := MeshInstance3D.new()
				var sph := SphereMesh.new()
				sph.radius = 0.009
				sph.height = 0.018
				remache.mesh = sph
				remache.position = Vector3(rx, y_offset + (0.011 if y_offset > 0 else -0.011), rz)
				remache.material_override = mat_acero
				root.add_child(remache)

	# 6. Emblema del Engranaje en los laterales (+X y -X)
	for lado in [-1.0, 1.0]:
		var posX: float = lado * 0.103
		# Núcleo central del engranaje
		var eje_engranaje := MeshInstance3D.new()
		var cyl_eje := CylinderMesh.new()
		cyl_eje.top_radius = 0.045
		cyl_eje.bottom_radius = 0.045
		cyl_eje.height = 0.010
		cyl_eje.radial_segments = 16
		eje_engranaje.mesh = cyl_eje
		eje_engranaje.rotation_degrees = Vector3(0, 0, 90)
		eje_engranaje.position = Vector3(posX, 0.04, 0.46)
		eje_engranaje.material_override = mat_engranaje
		root.add_child(eje_engranaje)

		# Dientes del engranaje radiales
		for i in range(6):
			var angulo_rad: float = deg_to_rad(i * 60.0)
			var diente := MeshInstance3D.new()
			var box_d := BoxMesh.new()
			box_d.size = Vector3(0.012, 0.022, 0.020)
			diente.mesh = box_d
			diente.position = Vector3(
				posX,
				0.04 + sin(angulo_rad) * 0.052,
				0.46 + cos(angulo_rad) * 0.052
			)
			diente.rotation_degrees = Vector3(rad_to_deg(angulo_rad), 0, 0)
			diente.material_override = mat_engranaje
			root.add_child(diente)

	# 7. Cara de Impacto Frontal Estriada y Conductos de Plasma Cian
	var placa_impacto := MeshInstance3D.new()
	var box_imp := BoxMesh.new()
	box_imp.size = Vector3(0.18, 0.20, 0.025)
	placa_impacto.mesh = box_imp
	placa_impacto.position = Vector3(0, 0.04, 0.605)
	placa_impacto.material_override = mat_acero_oscuro
	root.add_child(placa_impacto)

	# Estrías de impacto horizontales
	for dy in [-0.06, 0.0, 0.06]:
		var estria := MeshInstance3D.new()
		var box_est := BoxMesh.new()
		box_est.size = Vector3(0.15, 0.012, 0.008)
		estria.mesh = box_est
		estria.position = Vector3(0, 0.04 + dy, 0.618)
		estria.material_override = mat_acero
		root.add_child(estria)

	# Núcleo emisor de plasma cian frontal
	var nucleo_plasma := MeshInstance3D.new()
	var box_plasma := BoxMesh.new()
	box_plasma.size = Vector3(0.10, 0.12, 0.010)
	nucleo_plasma.mesh = box_plasma
	nucleo_plasma.position = Vector3(0, 0.04, 0.616)
	nucleo_plasma.material_override = mat_plasma_cian
	root.add_child(nucleo_plasma)

	# 8. Pistón Hidráulico de Retroceso Trasero
	var piston := MeshInstance3D.new()
	var cyl_piston := CylinderMesh.new()
	cyl_piston.top_radius = 0.046
	cyl_piston.bottom_radius = 0.046
	cyl_piston.height = 0.07
	cyl_piston.radial_segments = 12
	piston.mesh = cyl_piston
	piston.rotation_degrees = Vector3(90, 0, 0)
	piston.position = Vector3(0, 0.04, 0.29)
	piston.material_override = mat_acero_oscuro
	root.add_child(piston)

	var tapa_trasera := MeshInstance3D.new()
	var box_tapa := BoxMesh.new()
	box_tapa.size = Vector3(0.12, 0.12, 0.02)
	tapa_trasera.mesh = box_tapa
	tapa_trasera.position = Vector3(0, 0.04, 0.25)
	tapa_trasera.material_override = mat_acero
	root.add_child(tapa_trasera)

	var luz_impacto: OmniLight3D = null
	if incluir_particulas:
		# Chispas de descarga eléctrica cinéticas
		var chispas := CPUParticles3D.new()
		chispas.name = "ChispasCineticas"
		chispas.emitting = true
		chispas.amount = 18
		chispas.lifetime = 0.35
		chispas.explosiveness = 0.20
		chispas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		chispas.emission_box_extents = Vector3(0.08, 0.09, 0.015)
		chispas.direction = Vector3(0, 0, 1)
		chispas.spread = 50.0
		chispas.gravity = Vector3(0, -1.2, 0)
		chispas.initial_velocity_min = 0.8
		chispas.initial_velocity_max = 1.8
		chispas.color = Color(0.25, 0.95, 1.0)
		chispas.position = Vector3(0, 0.04, 0.62)
		root.add_child(chispas)

		# Luz dinámica cian de impacto
		luz_impacto = OmniLight3D.new()
		luz_impacto.name = "LuzImpacto"
		luz_impacto.light_color = Color(0.20, 0.92, 1.0)
		luz_impacto.light_energy = 0.95
		luz_impacto.omni_range = 1.4
		luz_impacto.position = Vector3(0, 0.04, 0.66)
		root.add_child(luz_impacto)

	var res := {"nodo": root}
	if luz_impacto != null:
		res["luz"] = luz_impacto
	return res


## Escudo de Brecha Balístico Pesado con Núcleo Cinético (Concept Art: player_warrior.glb)
static func _crear_escudo_brecha_guerrero(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "EscudoBrechaGuerrero"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.30), 0.86, 0.36)
	var mat_acero_oscuro := _mat_simple(Color(0.16, 0.18, 0.20), 0.82, 0.45)
	var mat_marco := _mat_simple(Color(0.36, 0.39, 0.44), 0.90, 0.28)
	var mat_vidrio_blindado := _mat_simple(Color(0.08, 0.12, 0.16), 0.30, 0.10)
	var mat_plasma_cian := _mat_simple(Color(0.20, 0.92, 1.0), 0.2, 0.1, Color(0.15, 0.95, 1.0), 2.4)
	var mat_amarillo_hazard := _mat_simple(Color(0.96, 0.78, 0.12), 0.10, 0.40)
	var mat_negro_hazard := _mat_simple(Color(0.12, 0.12, 0.14), 0.10, 0.50)
	var mat_correa := _mat_simple(Color(0.14, 0.12, 0.10), 0.05, 0.70)

	# 1. Cuerpo principal del Escudo de Brecha (Placa balística)
	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.44, 0.84, 0.035)
	placa.mesh = box_placa
	placa.position = Vector3(0, 0, 0.0)
	placa.material_override = mat_acero
	root.add_child(placa)

	# 2. Marco perimetral reforzado con biseles
	var marco_sup := MeshInstance3D.new()
	var box_m_sup := BoxMesh.new()
	box_m_sup.size = Vector3(0.46, 0.045, 0.045)
	marco_sup.mesh = box_m_sup
	marco_sup.position = Vector3(0, 0.41, 0.005)
	marco_sup.material_override = mat_marco
	root.add_child(marco_sup)

	var marco_inf := MeshInstance3D.new()
	var box_m_inf := BoxMesh.new()
	box_m_inf.size = Vector3(0.46, 0.045, 0.045)
	marco_inf.mesh = box_m_inf
	marco_inf.position = Vector3(0, -0.41, 0.005)
	marco_inf.material_override = mat_marco
	root.add_child(marco_inf)

	var marco_izq := MeshInstance3D.new()
	var box_m_izq := BoxMesh.new()
	box_m_izq.size = Vector3(0.045, 0.80, 0.045)
	marco_izq.mesh = box_m_izq
	marco_izq.position = Vector3(0.21, 0, 0.005)
	marco_izq.material_override = mat_marco
	root.add_child(marco_izq)

	var marco_der := MeshInstance3D.new()
	var box_m_der := BoxMesh.new()
	box_m_der.size = Vector3(0.045, 0.80, 0.045)
	marco_der.mesh = box_m_der
	marco_der.position = Vector3(-0.21, 0, 0.005)
	marco_der.material_override = mat_marco
	root.add_child(marco_der)

	# Remaches perimetrales a lo largo del marco
	for rx in [-0.21, -0.10, 0.0, 0.10, 0.21]:
		for ry in [-0.41, 0.41]:
			var rem := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.009
			sph.height = 0.018
			rem.mesh = sph
			rem.position = Vector3(rx, ry, 0.028)
			rem.material_override = mat_acero_oscuro
			root.add_child(rem)

	for ry in [-0.26, -0.13, 0.13, 0.26]:
		for rx in [-0.21, 0.21]:
			var rem := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.009
			sph.height = 0.018
			rem.mesh = sph
			rem.position = Vector3(rx, ry, 0.028)
			rem.material_override = mat_acero_oscuro
			root.add_child(rem)

	# 3. Ranura de Visión Blindada Superior (Viewing Slit)
	var marco_visor := MeshInstance3D.new()
	var box_mv := BoxMesh.new()
	box_mv.size = Vector3(0.24, 0.09, 0.045)
	marco_visor.mesh = box_mv
	marco_visor.position = Vector3(0, 0.25, 0.012)
	marco_visor.material_override = mat_acero_oscuro
	root.add_child(marco_visor)

	var vidrio_visor := MeshInstance3D.new()
	var box_vv := BoxMesh.new()
	box_vv.size = Vector3(0.18, 0.048, 0.020)
	vidrio_visor.mesh = box_vv
	vidrio_visor.position = Vector3(0, 0.25, 0.026)
	vidrio_visor.material_override = mat_vidrio_blindado
	root.add_child(vidrio_visor)

	# 4. Franja de Peligro Central (Hazard Warning Stripes \ \ \)
	var franja_base := MeshInstance3D.new()
	var box_fb := BoxMesh.new()
	box_fb.size = Vector3(0.44, 0.13, 0.008)
	franja_base.mesh = box_fb
	franja_base.position = Vector3(0, 0, 0.020)
	franja_base.material_override = mat_negro_hazard
	root.add_child(franja_base)

	# Rayas diagonales amarillas alternadas (lado izquierdo y derecho del reactor)
	var x_coords_stripes: Array[float] = [-0.19, -0.15, -0.11, 0.11, 0.15, 0.19]
	for sx in x_coords_stripes:
		var stripe := MeshInstance3D.new()
		var box_st := BoxMesh.new()
		box_st.size = Vector3(0.022, 0.15, 0.004)
		stripe.mesh = box_st
		stripe.position = Vector3(sx, 0, 0.026)
		stripe.rotation_degrees = Vector3(0, 0, 35.0)
		stripe.material_override = mat_amarillo_hazard
		root.add_child(stripe)

	# Franjas de peligro en esquinas inferiores
	for esq_sign in [-1.0, 1.0]:
		var placa_esq := MeshInstance3D.new()
		var box_pe := BoxMesh.new()
		box_pe.size = Vector3(0.09, 0.06, 0.006)
		placa_esq.mesh = box_pe
		placa_esq.position = Vector3(esq_sign * 0.15, -0.36, 0.020)
		placa_esq.material_override = mat_negro_hazard
		root.add_child(placa_esq)

		for k in range(2):
			var rayita := MeshInstance3D.new()
			var box_r := BoxMesh.new()
			box_r.size = Vector3(0.015, 0.08, 0.004)
			rayita.mesh = box_r
			rayita.position = Vector3(esq_sign * (0.13 + k * 0.035), -0.36, 0.025)
			rayita.rotation_degrees = Vector3(0, 0, 35.0)
			rayita.material_override = mat_amarillo_hazard
			root.add_child(rayita)

	# 5. Núcleo Reactor Central (Generador de Campo Cinético)
	var hub_reactor := MeshInstance3D.new()
	var cyl_hub := CylinderMesh.new()
	cyl_hub.top_radius = 0.095
	cyl_hub.bottom_radius = 0.095
	cyl_hub.height = 0.035
	cyl_hub.radial_segments = 8
	hub_reactor.mesh = cyl_hub
	hub_reactor.rotation_degrees = Vector3(90, 0, 0)
	hub_reactor.position = Vector3(0, 0, 0.032)
	hub_reactor.material_override = mat_acero_oscuro
	root.add_child(hub_reactor)

	var iris_anillo := MeshInstance3D.new()
	var mesh_iris := TorusMesh.new()
	mesh_iris.inner_radius = 0.048
	mesh_iris.outer_radius = 0.075
	iris_anillo.mesh = mesh_iris
	iris_anillo.rotation_degrees = Vector3(90, 0, 0)
	iris_anillo.position = Vector3(0, 0, 0.045)
	iris_anillo.material_override = mat_marco
	root.add_child(iris_anillo)

	var lente_plasma := MeshInstance3D.new()
	var cyl_lente := CylinderMesh.new()
	cyl_lente.top_radius = 0.045
	cyl_lente.bottom_radius = 0.045
	cyl_lente.height = 0.022
	cyl_lente.radial_segments = 16
	lente_plasma.mesh = cyl_lente
	lente_plasma.rotation_degrees = Vector3(90, 0, 0)
	lente_plasma.position = Vector3(0, 0, 0.048)
	lente_plasma.material_override = mat_plasma_cian
	root.add_child(lente_plasma)

	# 6. Montaje Posterior para Brazo (Asidero y correas traseras)
	var almohadilla := MeshInstance3D.new()
	var box_alm := BoxMesh.new()
	box_alm.size = Vector3(0.12, 0.22, 0.025)
	almohadilla.mesh = box_alm
	almohadilla.position = Vector3(0, 0, -0.028)
	almohadilla.material_override = mat_correa
	root.add_child(almohadilla)

	for y_c in [-0.08, 0.08]:
		var correa := MeshInstance3D.new()
		var box_c := BoxMesh.new()
		box_c.size = Vector3(0.14, 0.035, 0.020)
		correa.mesh = box_c
		correa.position = Vector3(0, y_c, -0.038)
		correa.material_override = mat_acero_oscuro
		root.add_child(correa)

	var mango_agarre := MeshInstance3D.new()
	var cyl_m := CylinderMesh.new()
	cyl_m.top_radius = 0.016
	cyl_m.bottom_radius = 0.016
	cyl_m.height = 0.16
	mango_agarre.mesh = cyl_m
	mango_agarre.position = Vector3(0, 0, -0.055)
	mango_agarre.material_override = mat_acero
	root.add_child(mango_agarre)

	var luz_escudo: OmniLight3D = null
	if incluir_particulas:
		luz_escudo = OmniLight3D.new()
		luz_escudo.name = "LuzEscudo"
		luz_escudo.light_color = Color(0.15, 0.92, 1.0)
		luz_escudo.light_energy = 0.85
		luz_escudo.omni_range = 1.3
		luz_escudo.position = Vector3(0, 0, 0.075)
		root.add_child(luz_escudo)

	var res := {"nodo": root}
	if luz_escudo != null:
		res["luz"] = luz_escudo
	return res


## Casco Balístico Pesado con Visor Cian y Respirador Naranja (Concept Art: player_warrior.glb)
static func _crear_casco_balistico_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "CascoBalisticoGuerrero"

	var mat_casco := _mat_simple(Color(0.24, 0.26, 0.29), 0.85, 0.38)
	var mat_casco_oscuro := _mat_simple(Color(0.16, 0.18, 0.20), 0.80, 0.45)
	var mat_naranja_tactico := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)
	var mat_visor_cian := _mat_simple(Color(0.12, 0.92, 1.0), 0.2, 0.1, Color(0.15, 0.95, 1.0), 2.2)

	# 1. Cúpula del casco balístico (Cubre la cabeza completa)
	var cupula := MeshInstance3D.new()
	var sph_c := SphereMesh.new()
	sph_c.radius = 0.15
	sph_c.height = 0.30
	cupula.mesh = sph_c
	cupula.scale = Vector3(0.95, 0.92, 1.02)
	cupula.position = Vector3(0, 0.05, 0.0)
	cupula.material_override = mat_casco
	root.add_child(cupula)

	# Borde reforzado de la frente con remaches
	var reborde_frente := MeshInstance3D.new()
	var box_rf := BoxMesh.new()
	box_rf.size = Vector3(0.24, 0.035, 0.035)
	reborde_frente.mesh = box_rf
	reborde_frente.position = Vector3(0, 0.08, 0.125)
	reborde_frente.material_override = mat_casco_oscuro
	root.add_child(reborde_frente)

	for rx in [-0.09, -0.03, 0.03, 0.09]:
		var rem := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.007
		sph.height = 0.014
		rem.mesh = sph
		rem.position = Vector3(rx, 0.08, 0.142)
		rem.material_override = mat_casco
		root.add_child(rem)

	# 2. Módulos / Auriculares laterales de comunicaciones (Ear pods)
	for lado in [-1.0, 1.0]:
		var orejera := MeshInstance3D.new()
		var cyl_o := CylinderMesh.new()
		cyl_o.top_radius = 0.038
		cyl_o.bottom_radius = 0.038
		cyl_o.height = 0.025
		orejera.mesh = cyl_o
		orejera.rotation_degrees = Vector3(0, 0, 90)
		orejera.position = Vector3(lado * 0.145, 0.02, 0.0)
		orejera.material_override = mat_casco_oscuro
		root.add_child(orejera)

		var centro_o := MeshInstance3D.new()
		var sph_co := SphereMesh.new()
		sph_co.radius = 0.015
		sph_co.height = 0.030
		centro_o.mesh = sph_co
		centro_o.position = Vector3(lado * 0.158, 0.02, 0.0)
		centro_o.material_override = mat_casco
		root.add_child(centro_o)

	# 3. Visor Panorámico Cian Brillante (Ballistic HUD Visor)
	var visor := MeshInstance3D.new()
	var box_v := BoxMesh.new()
	box_v.size = Vector3(0.21, 0.065, 0.035)
	visor.mesh = box_v
	visor.position = Vector3(0, 0.03, 0.13)
	visor.material_override = mat_visor_cian
	root.add_child(visor)

	# Marco envolvente oscuro del visor
	var marco_v := MeshInstance3D.new()
	var box_mv := BoxMesh.new()
	box_mv.size = Vector3(0.23, 0.08, 0.025)
	marco_v.mesh = box_mv
	marco_v.position = Vector3(0, 0.03, 0.122)
	marco_v.material_override = mat_casco_oscuro
	root.add_child(marco_v)

	# 4. Máscara de Gas Respirador Pesado (Unidad facial inferior naranja)
	var mascara_cuerpo := MeshInstance3D.new()
	var box_mc := BoxMesh.new()
	box_mc.size = Vector3(0.15, 0.08, 0.09)
	mascara_cuerpo.mesh = box_mc
	mascara_cuerpo.position = Vector3(0, -0.06, 0.11)
	mascara_cuerpo.material_override = mat_naranja_tactico
	root.add_child(mascara_cuerpo)

	# Rejilla de ventilación central frontal
	var rejilla := MeshInstance3D.new()
	var box_rej := BoxMesh.new()
	box_rej.size = Vector3(0.06, 0.05, 0.02)
	rejilla.mesh = box_rej
	rejilla.position = Vector3(0, -0.06, 0.156)
	rejilla.material_override = mat_casco_oscuro
	root.add_child(rejilla)

	# Ranuras de ventilación metálicas
	for dy in [-0.015, 0.0, 0.015]:
		var ranura := MeshInstance3D.new()
		var box_ran := BoxMesh.new()
		box_ran.size = Vector3(0.045, 0.005, 0.005)
		ranura.mesh = box_ran
		ranura.position = Vector3(0, -0.06 + dy, 0.166)
		ranura.material_override = mat_casco
		root.add_child(ranura)

	# Canistros / Filtros laterales dobles con aro naranja
	for lado in [-1.0, 1.0]:
		var canistro := MeshInstance3D.new()
		var cyl_can := CylinderMesh.new()
		cyl_can.top_radius = 0.034
		cyl_can.bottom_radius = 0.034
		cyl_can.height = 0.045
		canistro.mesh = cyl_can
		canistro.rotation_degrees = Vector3(0, lado * 25.0, 90.0)
		canistro.position = Vector3(lado * 0.085, -0.06, 0.085)
		canistro.material_override = mat_casco_oscuro
		root.add_child(canistro)

		# Aro frontal exterior naranja en el filtro
		var aro_filtro := MeshInstance3D.new()
		var mesh_af := TorusMesh.new()
		mesh_af.inner_radius = 0.020
		mesh_af.outer_radius = 0.035
		aro_filtro.mesh = mesh_af
		aro_filtro.rotation_degrees = Vector3(0, lado * 25.0, 90.0)
		aro_filtro.position = Vector3(lado * 0.108, -0.06, 0.085)
		aro_filtro.material_override = mat_naranja_tactico
		root.add_child(aro_filtro)

	# Sello de cuello inferior blindado
	var cuello_sello := MeshInstance3D.new()
	var cyl_cs := CylinderMesh.new()
	cyl_cs.top_radius = 0.12
	cyl_cs.bottom_radius = 0.13
	cyl_cs.height = 0.04
	cuello_sello.mesh = cyl_cs
	cuello_sello.position = Vector3(0, -0.10, 0.0)
	cuello_sello.material_override = mat_casco_oscuro
	root.add_child(cuello_sello)

	return root


## Armadura de Torso Pesada, Hombreras Dobles, Cinturón Naranja y Gran Espada Envainada (Concept Art: player_warrior.glb)
static func _crear_armadura_torso_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "ArmaduraTorsoGuerrero"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.31), 0.86, 0.35)
	var mat_acero_oscuro := _mat_simple(Color(0.16, 0.18, 0.20), 0.80, 0.45)
	var mat_acero_claro := _mat_simple(Color(0.48, 0.52, 0.58), 0.90, 0.25)
	var mat_naranja := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)
	var mat_cuero := _mat_simple(Color(0.18, 0.14, 0.11), 0.05, 0.65)

	# 1. Peto Balístico Pesado (Cuirass)
	var peto := MeshInstance3D.new()
	var box_peto := BoxMesh.new()
	box_peto.size = Vector3(0.33, 0.22, 0.14)
	peto.mesh = box_peto
	peto.position = Vector3(0, 0.17, 0.04)
	peto.material_override = mat_acero
	root.add_child(peto)

	# Ribete superior del cuello y remaches
	var cuello_arriba := MeshInstance3D.new()
	var box_ca := BoxMesh.new()
	box_ca.size = Vector3(0.28, 0.04, 0.08)
	cuello_arriba.mesh = box_ca
	cuello_arriba.position = Vector3(0, 0.28, 0.02)
	cuello_arriba.material_override = mat_acero_oscuro
	root.add_child(cuello_arriba)

	for rx in [-0.12, -0.04, 0.04, 0.12]:
		var rem := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.009
		sph.height = 0.018
		rem.mesh = sph
		rem.position = Vector3(rx, 0.24, 0.112)
		rem.material_override = mat_acero_claro
		root.add_child(rem)

	# 2. Placas Abdominales Segmentadas Tácticas (Rejilla abdominal blindada)
	var ab_cols: Array[float] = [-0.075, 0.0, 0.075]
	var ab_rows: Array[float] = [0.07, 0.01]
	for ry in ab_rows:
		for rx in ab_cols:
			var placa_ab := MeshInstance3D.new()
			var box_ab := BoxMesh.new()
			box_ab.size = Vector3(0.065, 0.045, 0.030)
			placa_ab.mesh = box_ab
			placa_ab.position = Vector3(rx, ry, 0.108)
			placa_ab.material_override = mat_acero_oscuro
			root.add_child(placa_ab)

	# 3. Faldón Táctico Blindado (Groin Flap Protector)
	var faldon := MeshInstance3D.new()
	var box_fal := BoxMesh.new()
	box_fal.size = Vector3(0.14, 0.13, 0.025)
	faldon.mesh = box_fal
	faldon.position = Vector3(0, -0.16, 0.06)
	faldon.material_override = mat_acero
	root.add_child(faldon)

	for fx in [-0.05, 0.05]:
		var rem_f := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.008
		sph.height = 0.016
		rem_f.mesh = sph
		rem_f.position = Vector3(fx, -0.12, 0.074)
		rem_f.material_override = mat_acero_claro
		root.add_child(rem_f)

	# 4. Hombreras Esféricas Dobles Masivas (Pauldrons on BOTH Shoulders)
	for lado in [-1.0, 1.0]:
		var posX: float = lado * 0.24
		# Cúpula principal de la hombrera
		var hombrera := MeshInstance3D.new()
		var sph_h := SphereMesh.new()
		sph_h.radius = 0.10
		sph_h.height = 0.20
		hombrera.mesh = sph_h
		hombrera.scale = Vector3(1.0, 0.88, 1.08)
		hombrera.position = Vector3(posX, 0.22, 0.0)
		hombrera.material_override = mat_acero
		root.add_child(hombrera)

		# Reborde reforzado de doble labio
		var labio := MeshInstance3D.new()
		var torus_l := TorusMesh.new()
		torus_l.inner_radius = 0.082
		torus_l.outer_radius = 0.106
		labio.mesh = torus_l
		labio.position = Vector3(posX, 0.17, 0.0)
		labio.material_override = mat_acero_oscuro
		root.add_child(labio)

		# Remaches perimetrales en cada hombrera
		for i in range(4):
			var angulo_rad: float = deg_to_rad(45.0 + i * 90.0)
			var rem_h := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.009
			sph.height = 0.018
			rem_h.mesh = sph
			rem_h.position = Vector3(
				posX + sin(angulo_rad) * 0.085,
				0.18,
				cos(angulo_rad) * 0.085
			)
			rem_h.material_override = mat_acero_claro
			root.add_child(rem_h)

		# Correa de sujeción naranja de la hombrera al pecho
		var correa_h := MeshInstance3D.new()
		var box_ch := BoxMesh.new()
		box_ch.size = Vector3(0.06, 0.02, 0.18)
		correa_h.mesh = box_ch
		correa_h.position = Vector3(lado * 0.15, 0.25, 0.0)
		correa_h.material_override = mat_naranja
		root.add_child(correa_h)

	# 5. Cinturón Táctico Naranja y Bolsillos de Utilidad
	var cinturon := MeshInstance3D.new()
	var box_cint := BoxMesh.new()
	box_cint.size = Vector3(0.34, 0.065, 0.25)
	cinturon.mesh = box_cint
	cinturon.position = Vector3(0, -0.06, 0.0)
	cinturon.material_override = mat_naranja
	root.add_child(cinturon)

	# Hebilla central metálica
	var hebilla := MeshInstance3D.new()
	var box_heb := BoxMesh.new()
	box_heb.size = Vector3(0.065, 0.075, 0.030)
	hebilla.mesh = box_heb
	hebilla.position = Vector3(0, -0.06, 0.13)
	hebilla.material_override = mat_acero_claro
	root.add_child(hebilla)

	# 4 Bolsillos tácticos de munición naranja (2 frontales, 2 laterales)
	var bolsillos_data: Array[Vector3] = [
		Vector3(-0.09, -0.06, 0.125),
		Vector3(0.09, -0.06, 0.125),
		Vector3(-0.175, -0.06, 0.0),
		Vector3(0.175, -0.06, 0.0)
	]
	for pos in bolsillos_data:
		var pouch := MeshInstance3D.new()
		var box_p := BoxMesh.new()
		box_p.size = Vector3(0.055, 0.070, 0.045) if absf(pos.z) > 0.05 else Vector3(0.045, 0.070, 0.055)
		pouch.mesh = box_p
		pouch.position = pos
		pouch.material_override = mat_naranja
		root.add_child(pouch)

	# Pistolera y correa táctica en muslo derecho
	var pistolera := MeshInstance3D.new()
	var box_pist := BoxMesh.new()
	box_pist.size = Vector3(0.045, 0.10, 0.055)
	pistolera.mesh = box_pist
	pistolera.position = Vector3(-0.18, -0.16, 0.03)
	pistolera.material_override = mat_cuero
	root.add_child(pistolera)

	var correa_pist := MeshInstance3D.new()
	var box_cp := BoxMesh.new()
	box_cp.size = Vector3(0.03, 0.08, 0.02)
	correa_pist.mesh = box_cp
	correa_pist.position = Vector3(-0.18, -0.10, 0.02)
	correa_pist.material_override = mat_naranja
	root.add_child(correa_pist)

	# 6. Gran Espada de Respaldo Envainada en la Espalda (Mounted Diagonally Across Upper Back)
	var rig_espada := Node3D.new()
	rig_espada.name = "EspadaEspalda"
	rig_espada.position = Vector3(0.02, 0.14, -0.14)
	rig_espada.rotation_degrees = Vector3(12.0, -10.0, -28.0)
	root.add_child(rig_espada)

	# Vaina metálica de la espada
	var vaina := MeshInstance3D.new()
	var box_v := BoxMesh.new()
	box_v.size = Vector3(0.065, 0.52, 0.035)
	vaina.mesh = box_v
	vaina.position = Vector3(0, 0.02, 0)
	vaina.material_override = mat_acero_oscuro
	rig_espada.add_child(vaina)

	# Cintas de sujeción / correas de la vaina
	for sy in [-0.15, -0.05, 0.05, 0.15]:
		var cinta := MeshInstance3D.new()
		var box_c := BoxMesh.new()
		box_c.size = Vector3(0.070, 0.018, 0.040)
		cinta.mesh = box_c
		cinta.position = Vector3(0, sy, 0)
		cinta.material_override = mat_naranja
		rig_espada.add_child(cinta)

	# Brocal / Entrada de la vaina
	var brocal := MeshInstance3D.new()
	var box_bro := BoxMesh.new()
	box_bro.size = Vector3(0.080, 0.030, 0.045)
	brocal.mesh = box_bro
	brocal.position = Vector3(0, 0.28, 0)
	brocal.material_override = mat_acero
	rig_espada.add_child(brocal)

	# Guarda de acero de la espada
	var guarda_espada := MeshInstance3D.new()
	var box_ge := BoxMesh.new()
	box_ge.size = Vector3(0.14, 0.028, 0.035)
	guarda_espada.mesh = box_ge
	guarda_espada.position = Vector3(0, 0.31, 0)
	guarda_espada.material_override = mat_acero_claro
	rig_espada.add_child(guarda_espada)

	# Empuñadura / Mango para dos manos envuelto
	var mango_esp := MeshInstance3D.new()
	var cyl_me := CylinderMesh.new()
	cyl_me.top_radius = 0.016
	cyl_me.bottom_radius = 0.016
	cyl_me.height = 0.16
	mango_esp.mesh = cyl_me
	mango_esp.position = Vector3(0, 0.40, 0)
	mango_esp.material_override = mat_cuero
	rig_espada.add_child(mango_esp)

	# Pomo de acero contrapeso en la punta
	var pomo_esp := MeshInstance3D.new()
	var box_pe := BoxMesh.new()
	box_pe.size = Vector3(0.042, 0.036, 0.042)
	pomo_esp.mesh = box_pe
	pomo_esp.position = Vector3(0, 0.49, 0)
	pomo_esp.material_override = mat_acero_claro
	rig_espada.add_child(pomo_esp)

	return root


## Protección Pesada de Piernas: Rodillera de Titanio, Doble Correa Naranja y Espinillera (Concept Art: player_warrior.glb)
static func _crear_proteccion_pierna_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "ProteccionPiernaGuerrero"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.31), 0.86, 0.35)
	var mat_acero_oscuro := _mat_simple(Color(0.16, 0.18, 0.20), 0.80, 0.45)
	var mat_acero_claro := _mat_simple(Color(0.48, 0.52, 0.58), 0.90, 0.25)
	var mat_naranja := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)

	# 1. Placa de rodilla curva de titanio (Knee Plate)
	var rodillera := MeshInstance3D.new()
	var sph_r := SphereMesh.new()
	sph_r.radius = 0.055
	sph_r.height = 0.11
	rodillera.mesh = sph_r
	rodillera.scale = Vector3(1.0, 0.95, 0.65)
	rodillera.position = Vector3(0, 0, 0.02)
	rodillera.material_override = mat_acero
	root.add_child(rodillera)

	# Remaches de la rodillera
	for rx in [-0.03, 0.03]:
		for ry in [-0.025, 0.025]:
			var rem := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.007
			sph.height = 0.014
			rem.mesh = sph
			rem.position = Vector3(rx, ry, 0.055)
			rem.material_override = mat_acero_claro
			root.add_child(rem)

	# 2. Doble correa horizontal naranja de sujeción (Arriba y abajo de la rodilla)
	var correa_sup := MeshInstance3D.new()
	var box_cs := BoxMesh.new()
	box_cs.size = Vector3(0.12, 0.024, 0.11)
	correa_sup.mesh = box_cs
	correa_sup.position = Vector3(0, 0.055, -0.01)
	correa_sup.material_override = mat_naranja
	root.add_child(correa_sup)

	var correa_inf := MeshInstance3D.new()
	var box_ci := BoxMesh.new()
	box_ci.size = Vector3(0.12, 0.024, 0.11)
	correa_inf.mesh = box_ci
	correa_inf.position = Vector3(0, -0.055, -0.01)
	correa_inf.material_override = mat_naranja
	root.add_child(correa_inf)

	# 3. Espinillera táctica blindada (Shin Guard Plate)
	var espinillera := MeshInstance3D.new()
	var box_esp := BoxMesh.new()
	box_esp.size = Vector3(0.075, 0.16, 0.022)
	espinillera.mesh = box_esp
	espinillera.position = Vector3(0, -0.13, 0.015)
	espinillera.material_override = mat_acero_oscuro
	root.add_child(espinillera)

	# Cresta central reforzada de la espinillera
	var cresta := MeshInstance3D.new()
	var box_cr := BoxMesh.new()
	box_cr.size = Vector3(0.020, 0.14, 0.012)
	cresta.mesh = box_cr
	cresta.position = Vector3(0, -0.13, 0.026)
	cresta.material_override = mat_acero
	root.add_child(cresta)

	return root


## Guantelete Táctico Pesado y Codera (Concept Art: player_warrior.glb)
static func _crear_guantelete_pesado_guerrero() -> Node3D:
	var root := Node3D.new()
	root.name = "GuanteletePesadoGuerrero"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.31), 0.86, 0.35)
	var mat_acero_oscuro := _mat_simple(Color(0.16, 0.18, 0.20), 0.80, 0.45)
	var mat_guante := _mat_simple(Color(0.14, 0.15, 0.17), 0.10, 0.70)

	# 1. Brazal reforzado de antebrazo
	var brazal := MeshInstance3D.new()
	var box_br := BoxMesh.new()
	box_br.size = Vector3(0.08, 0.14, 0.04)
	brazal.mesh = box_br
	brazal.position = Vector3(0, -0.06, 0.02)
	brazal.material_override = mat_acero
	root.add_child(brazal)

	# 2. Codera de choque (Elbow protector pad)
	var codera := MeshInstance3D.new()
	var sph_cod := SphereMesh.new()
	sph_cod.radius = 0.042
	sph_cod.height = 0.084
	codera.mesh = sph_cod
	codera.scale = Vector3(1.0, 0.8, 0.6)
	codera.position = Vector3(0, 0.03, -0.035)
	codera.material_override = mat_acero_oscuro
	root.add_child(codera)

	# 3. Manguito y protección de nudillos táctica
	var nudillos := MeshInstance3D.new()
	var box_nud := BoxMesh.new()
	box_nud.size = Vector3(0.075, 0.035, 0.025)
	nudillos.mesh = box_nud
	nudillos.position = Vector3(0, -0.15, 0.02)
	nudillos.material_override = mat_guante
	root.add_child(nudillos)

	return root


static func _crear_arco_tecnologico_cazador(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "ArcoTecnologico"

	var mat_titanio := _mat_simple(Color(0.26, 0.28, 0.34), 0.85, 0.28)
	var mat_cuerpo_gris := _mat_simple(Color(0.40, 0.44, 0.50), 0.75, 0.32)
	var mat_empunadura := _mat_simple(Color(0.15, 0.16, 0.18), 0.10, 0.70)
	var mat_plasma_cian := _mat_simple(Color(0.25, 0.95, 1.0, 0.85), 0.2, 0.1, Color(0.15, 0.90, 1.0), 1.9)
	mat_plasma_cian.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# 1. Empuñadura ergonómica central (Riser)
	var emp := MeshInstance3D.new()
	var box_emp := BoxMesh.new()
	box_emp.size = Vector3(0.032, 0.15, 0.036)
	emp.mesh = box_emp
	emp.material_override = mat_empunadura
	root.add_child(emp)

	# 2. Palas recurvas superior e inferior
	for sy in [-1.0, 1.0]:
		var pala_base := MeshInstance3D.new()
		var box_pb := BoxMesh.new()
		box_pb.size = Vector3(0.026, 0.18, 0.032)
		pala_base.mesh = box_pb
		pala_base.position = Vector3(0, sy * 0.15, -0.03)
		pala_base.rotation_degrees = Vector3(sy * 20.0, 0.0, 0.0)
		pala_base.material_override = mat_titanio
		root.add_child(pala_base)

		var pala_punta := MeshInstance3D.new()
		var box_pp := BoxMesh.new()
		box_pp.size = Vector3(0.022, 0.16, 0.026)
		pala_punta.mesh = box_pp
		pala_punta.position = Vector3(0, sy * 0.29, -0.01)
		pala_punta.rotation_degrees = Vector3(sy * -28.0, 0.0, 0.0)
		pala_punta.material_override = mat_cuerpo_gris
		root.add_child(pala_punta)

		# Emisor circular de energía en cada pala (Arte Conceptual: player_archer.glb)
		var emisor_circular := MeshInstance3D.new()
		var cyl_em := CylinderMesh.new()
		cyl_em.top_radius = 0.018
		cyl_em.bottom_radius = 0.018
		cyl_em.height = 0.028
		emisor_circular.mesh = cyl_em
		emisor_circular.rotation_degrees.x = 90.0
		emisor_circular.position = Vector3(0, sy * 0.12, -0.015)
		emisor_circular.material_override = mat_plasma_cian
		root.add_child(emisor_circular)

		var nodo_energia := MeshInstance3D.new()
		var box_nodo := BoxMesh.new()
		box_nodo.size = Vector3(0.028, 0.055, 0.038)
		nodo_energia.mesh = box_nodo
		nodo_energia.position = Vector3(0, sy * 0.20, -0.045)
		nodo_energia.material_override = mat_plasma_cian
		root.add_child(nodo_energia)

		var tip := MeshInstance3D.new()
		var cyl_tip := CylinderMesh.new()
		cyl_tip.top_radius = 0.012
		cyl_tip.bottom_radius = 0.012
		cyl_tip.height = 0.024
		tip.mesh = cyl_tip
		tip.rotation_degrees.z = 90.0
		tip.position = Vector3(0, sy * 0.36, 0.035)
		tip.material_override = mat_titanio
		root.add_child(tip)

	# 3. Cuerda de energía de plasma cian
	var cuerda := MeshInstance3D.new()
	var cyl_cuerda := CylinderMesh.new()
	cyl_cuerda.top_radius = 0.0035
	cyl_cuerda.bottom_radius = 0.0035
	cyl_cuerda.height = 0.72
	cuerda.mesh = cyl_cuerda
	cuerda.position = Vector3(0, 0, 0.035)
	cuerda.material_override = mat_plasma_cian
	root.add_child(cuerda)

	# 4. Flecha tecnológica montada en el reposaflechas (apuntando al frente)
	var flecha := MeshInstance3D.new()
	var cyl_flecha := CylinderMesh.new()
	cyl_flecha.top_radius = 0.005
	cyl_flecha.bottom_radius = 0.005
	cyl_flecha.height = 0.44
	flecha.mesh = cyl_flecha
	flecha.rotation_degrees.x = 90.0
	flecha.position = Vector3(0, 0, 0.16)
	flecha.material_override = mat_titanio
	root.add_child(flecha)

	var punta_f := MeshInstance3D.new()
	var cyl_pf := CylinderMesh.new()
	cyl_pf.top_radius = 0.002
	cyl_pf.bottom_radius = 0.016
	cyl_pf.height = 0.07
	punta_f.mesh = cyl_pf
	punta_f.rotation_degrees.x = 90.0
	punta_f.position = Vector3(0, 0, 0.40)
	punta_f.material_override = mat_plasma_cian
	root.add_child(punta_f)

	var luz: OmniLight3D = null
	if incluir_particulas:
		luz = OmniLight3D.new()
		luz.name = "LuzArcoTecnologico"
		luz.light_color = Color(0.18, 0.92, 1.0)
		luz.light_energy = 0.75
		luz.omni_range = 1.4
		luz.position = Vector3(0, 0, 0.20)
		root.add_child(luz)

	var res: Dictionary = {"nodo": root}
	if luz != null:
		res["luz"] = luz
	return res


static func _crear_carcaj_tecnologico_cazador(incluir_particulas: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "CarcajTecnologico"

	var mat_carcaj := _mat_simple(Color(0.20, 0.22, 0.28), 0.8, 0.35)
	var mat_carcasa := _mat_simple(Color(0.32, 0.36, 0.42), 0.85, 0.28)
	var mat_bateria := _mat_simple(Color(0.20, 0.95, 1.0, 0.85), 0.2, 0.1, Color(0.15, 0.90, 1.0), 1.8)
	mat_bateria.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mat_flechas := _mat_simple(Color(0.65, 0.70, 0.78), 0.85, 0.25)
	var mat_astiles_energia := _mat_simple(Color(0.25, 0.95, 1.0), 0.1, 0.1, Color(0.20, 0.95, 1.0), 1.6)
	var mat_naranja_hazard := _mat_simple(Color(0.95, 0.44, 0.06), 0.1, 0.5)

	var tubo := MeshInstance3D.new()
	var box_tubo := BoxMesh.new()
	box_tubo.size = Vector3(0.10, 0.36, 0.08)
	tubo.mesh = box_tubo
	tubo.material_override = mat_carcaj
	root.add_child(tubo)

	# Bandas de peligro naranja (Hazard Stripes)
	for sy in [-0.04, 0.04]:
		var banda_haz := MeshInstance3D.new()
		var box_bh := BoxMesh.new()
		box_bh.size = Vector3(0.104, 0.015, 0.084)
		banda_haz.mesh = box_bh
		banda_haz.position = Vector3(0, sy, 0)
		banda_haz.material_override = mat_naranja_hazard
		root.add_child(banda_haz)

	for sy in [-0.10, 0.10]:
		var abrazadera := MeshInstance3D.new()
		var box_abr := BoxMesh.new()
		box_abr.size = Vector3(0.108, 0.03, 0.088)
		abrazadera.mesh = box_abr
		abrazadera.position = Vector3(0, sy, 0)
		abrazadera.material_override = mat_carcasa
		root.add_child(abrazadera)

	var bateria := MeshInstance3D.new()
	var cyl_bat := CylinderMesh.new()
	cyl_bat.top_radius = 0.020
	cyl_bat.bottom_radius = 0.020
	cyl_bat.height = 0.24
	bateria.mesh = cyl_bat
	bateria.position = Vector3(0.065, -0.02, 0.0)
	bateria.material_override = mat_bateria
	root.add_child(bateria)

	# 5 flechas de energía completas sobresaliendo del carcaj (Concept Art: player_archer.glb)
	for i in range(5):
		var ang: float = float(i) * 0.65
		var fx: float = cos(ang) * 0.028
		var fz: float = sin(ang) * 0.022

		var flecha := MeshInstance3D.new()
		var cyl_f := CylinderMesh.new()
		cyl_f.top_radius = 0.005
		cyl_f.bottom_radius = 0.005
		cyl_f.height = 0.18
		flecha.mesh = cyl_f
		flecha.position = Vector3(fx, 0.24, fz)
		flecha.material_override = mat_flechas
		root.add_child(flecha)

		# 3 aletas de plasma cian por flecha
		for a in range(3):
			var rot_a := float(a) * 120.0
			var pluma := MeshInstance3D.new()
			var box_p := BoxMesh.new()
			box_p.size = Vector3(0.006, 0.05, 0.022)
			pluma.mesh = box_p
			pluma.rotation_degrees.y = rot_a
			pluma.position = Vector3(fx, 0.31, fz)
			pluma.material_override = mat_astiles_energia
			root.add_child(pluma)

	if incluir_particulas:
		var luz := OmniLight3D.new()
		luz.name = "LuzCarcaj"
		luz.light_color = Color(0.18, 0.90, 1.0)
		luz.light_energy = 0.55
		luz.omni_range = 1.2
		luz.position = Vector3(0.065, 0.05, 0.0)
		root.add_child(luz)

	return root


static func _crear_bufanda_naranja_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "BufandaNaranja"

	var mat_bufanda := _mat_simple(Color(0.94, 0.42, 0.06), 0.05, 0.65)
	var mat_pliegue := _mat_simple(Color(0.82, 0.34, 0.04), 0.05, 0.70)

	var cuello := MeshInstance3D.new()
	var box_cuello := BoxMesh.new()
	box_cuello.size = Vector3(0.24, 0.08, 0.21)
	cuello.mesh = box_cuello
	cuello.material_override = mat_bufanda
	root.add_child(cuello)

	var solapa := MeshInstance3D.new()
	var box_solapa := BoxMesh.new()
	box_solapa.size = Vector3(0.14, 0.12, 0.05)
	solapa.mesh = box_solapa
	solapa.position = Vector3(0.0, -0.07, 0.10)
	solapa.rotation_degrees.x = -15.0
	solapa.material_override = mat_pliegue
	root.add_child(solapa)

	return root


static func _crear_visor_hud_mascara_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "VisorMascaraCazador"

	var mat_cabello := _mat_simple(Color(0.40, 0.25, 0.15), 0.05, 0.60)
	var mat_goggle := _mat_simple(Color(0.95, 0.44, 0.06), 0.15, 0.50)
	var mat_hud := _mat_simple(Color(0.15, 0.92, 1.0, 0.88), 0.1, 0.1, Color(0.12, 0.90, 1.0), 1.8)
	mat_hud.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mat_reticula := _mat_simple(Color(0.40, 1.0, 1.0), 0.0, 0.1, Color(0.30, 1.0, 1.0), 2.8)
	var mat_mascara := _mat_simple(Color(0.18, 0.20, 0.24), 0.35, 0.50)
	var mat_filtro := _mat_simple(Color(0.12, 0.14, 0.16), 0.45, 0.45)
	var mat_naranja := _mat_simple(Color(0.95, 0.44, 0.06), 0.1, 0.5)
	var mat_correa := _mat_simple(Color(0.12, 0.12, 0.14), 0.05, 0.7)

	# 1. Cabello castaño despeinado anime (Concept Art: player_archer.glb)
	var base_cabello := MeshInstance3D.new()
	var sph_c := SphereMesh.new()
	sph_c.radius = 0.165
	sph_c.height = 0.22
	base_cabello.mesh = sph_c
	base_cabello.scale = Vector3(1.06, 0.85, 1.14)
	base_cabello.position = Vector3(0.0, 0.12, -0.01)
	base_cabello.material_override = mat_cabello
	root.add_child(base_cabello)

	# Mechones de pelo despeinado hacia arriba y atrás
	var mechones_coords = [
		[Vector3(0.0, 0.23, -0.03), Vector3(-25.0, 0.0, 0.0), Vector3(0.06, 0.10, 0.08)],
		[Vector3(-0.08, 0.21, -0.01), Vector3(-20.0, 15.0, 18.0), Vector3(0.05, 0.09, 0.07)],
		[Vector3(0.08, 0.21, -0.01), Vector3(-20.0, -15.0, -18.0), Vector3(0.05, 0.09, 0.07)],
		[Vector3(0.0, 0.24, 0.04), Vector3(15.0, 0.0, 0.0), Vector3(0.05, 0.09, 0.07)],
		# Flequillo frontal despeinado cayendo sobre las gafas
		[Vector3(-0.05, 0.14, 0.12), Vector3(25.0, 15.0, 12.0), Vector3(0.04, 0.07, 0.03)],
		[Vector3(0.01, 0.15, 0.13), Vector3(30.0, -5.0, -15.0), Vector3(0.045, 0.08, 0.03)],
		[Vector3(0.06, 0.13, 0.11), Vector3(20.0, -20.0, -10.0), Vector3(0.04, 0.07, 0.03)]
	]
	for m in mechones_coords:
		var mechon := MeshInstance3D.new()
		var box_m := BoxMesh.new()
		box_m.size = m[2]
		mechon.mesh = box_m
		mechon.position = m[0]
		mechon.rotation_degrees = m[1]
		mechon.material_override = mat_cabello
		root.add_child(mechon)

	# 2. Gafas protectoras tácticas con montura naranja
	var marco := MeshInstance3D.new()
	var box_marco := BoxMesh.new()
	box_marco.size = Vector3(0.20, 0.065, 0.07)
	marco.mesh = box_marco
	marco.position = Vector3(0.0, 0.05, 0.11)
	marco.material_override = mat_goggle
	root.add_child(marco)

	# Lente con visor HUD digital cian
	var lente := MeshInstance3D.new()
	var box_lente := BoxMesh.new()
	box_lente.size = Vector3(0.17, 0.048, 0.022)
	lente.mesh = box_lente
	lente.position = Vector3(0.0, 0.05, 0.148)
	lente.material_override = mat_hud
	root.add_child(lente)

	# Retícula holográfica de puntería en el ojo izquierdo (como en el arte conceptual)
	var reticula := MeshInstance3D.new()
	var box_ret := BoxMesh.new()
	box_ret.size = Vector3(0.018, 0.018, 0.005)
	reticula.mesh = box_ret
	reticula.position = Vector3(-0.042, 0.05, 0.160)
	reticula.material_override = mat_reticula
	root.add_child(reticula)

	# Correa elástica negra alrededor de la cabeza
	var correa := MeshInstance3D.new()
	var box_c := BoxMesh.new()
	box_c.size = Vector3(0.21, 0.030, 0.21)
	correa.mesh = box_c
	correa.position = Vector3(0.0, 0.05, 0.0)
	correa.material_override = mat_correa
	root.add_child(correa)

	# 3. Máscara respiratoria de gas industrial sobre nariz y boca
	var copa := MeshInstance3D.new()
	var box_copa := BoxMesh.new()
	box_copa.size = Vector3(0.12, 0.09, 0.10)
	copa.mesh = box_copa
	copa.position = Vector3(0.0, -0.045, 0.105)
	copa.rotation_degrees.x = -15.0
	copa.material_override = mat_mascara
	root.add_child(copa)

	# Rejilla frontal naranja en la boca
	var rejilla := MeshInstance3D.new()
	var box_rej := BoxMesh.new()
	box_rej.size = Vector3(0.04, 0.05, 0.018)
	rejilla.mesh = box_rej
	rejilla.position = Vector3(0.0, -0.055, 0.155)
	rejilla.material_override = mat_naranja
	root.add_child(rejilla)

	# Filtros circulares laterales con bisel naranja
	for sx in [-0.075, 0.075]:
		var filtro := MeshInstance3D.new()
		var cyl_fil := CylinderMesh.new()
		cyl_fil.top_radius = 0.026
		cyl_fil.bottom_radius = 0.026
		cyl_fil.height = 0.025
		filtro.mesh = cyl_fil
		filtro.rotation_degrees.z = 90.0
		filtro.position = Vector3(sx, -0.048, 0.088)
		filtro.material_override = mat_filtro
		root.add_child(filtro)

		var aro := MeshInstance3D.new()
		var cyl_aro := CylinderMesh.new()
		cyl_aro.top_radius = 0.028
		cyl_aro.bottom_radius = 0.028
		cyl_aro.height = 0.008
		aro.mesh = cyl_aro
		aro.rotation_degrees.z = 90.0
		aro.position = Vector3(sx * 1.05, -0.048, 0.088)
		aro.material_override = mat_naranja
		root.add_child(aro)

	return root


static func _crear_armadura_pecho_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "ArmaduraPechoCazador"

	var mat_hombrera := _mat_simple(Color(0.35, 0.38, 0.44), 0.85, 0.28)
	var mat_correa := _mat_simple(Color(0.18, 0.15, 0.12), 0.05, 0.65)
	var mat_cartucho := _mat_simple(Color(0.95, 0.50, 0.10), 0.2, 0.1, Color(0.95, 0.46, 0.08), 1.6)
	var mat_naranja_tactico := _mat_simple(Color(0.95, 0.44, 0.06), 0.1, 0.55)
	var mat_hebilla := _mat_simple(Color(0.75, 0.78, 0.84), 0.85, 0.25)
	var mat_cuero_funda := _mat_simple(Color(0.18, 0.16, 0.14), 0.10, 0.60)

	# 1. Hombreras blindadas en aleación de titanio sobre hombros
	for sx in [-0.20, 0.20]:
		var hombrera := MeshInstance3D.new()
		var box_h := BoxMesh.new()
		box_h.size = Vector3(0.095, 0.055, 0.13)
		hombrera.mesh = box_h
		hombrera.position = Vector3(sx, 0.19, 0.0)
		hombrera.rotation_degrees.z = -sx * 15.0
		hombrera.material_override = mat_hombrera
		root.add_child(hombrera)

	# 2. Arnés / bandolera diagonal en el pecho con cartuchos de energía
	var bandolera := MeshInstance3D.new()
	var box_b := BoxMesh.new()
	box_b.size = Vector3(0.038, 0.28, 0.17)
	bandolera.mesh = box_b
	bandolera.rotation_degrees.z = 28.0
	bandolera.position = Vector3(0.0, 0.02, 0.005)
	bandolera.material_override = mat_correa
	root.add_child(bandolera)

	for i in range(3):
		var cartucho := MeshInstance3D.new()
		var cyl_c := CylinderMesh.new()
		cyl_c.top_radius = 0.012
		cyl_c.bottom_radius = 0.012
		cyl_c.height = 0.048
		cartucho.mesh = cyl_c
		cartucho.rotation_degrees.z = -62.0
		cartucho.position = Vector3(-0.06 + (float(i) * 0.05), 0.08 - (float(i) * 0.06), 0.098)
		cartucho.material_override = mat_cartucho
		root.add_child(cartucho)

	# 3. Cinturón táctico naranja con bolsillos utilitarios y pistolera (Arte Conceptual)
	var cinturon := MeshInstance3D.new()
	var box_cint := BoxMesh.new()
	box_cint.size = Vector3(0.28, 0.045, 0.18)
	cinturon.mesh = box_cint
	cinturon.position = Vector3(0.0, -0.12, 0.0)
	cinturon.material_override = mat_naranja_tactico
	root.add_child(cinturon)

	var hebilla := MeshInstance3D.new()
	var box_heb := BoxMesh.new()
	box_heb.size = Vector3(0.045, 0.05, 0.02)
	hebilla.mesh = box_heb
	hebilla.position = Vector3(0.0, -0.12, 0.095)
	hebilla.material_override = mat_hebilla
	root.add_child(hebilla)

	# 4 bolsillos tácticos naranjas alrededor de la cintura
	var pos_bolsillos = [
		Vector3(-0.07, -0.13, 0.10),
		Vector3(0.07, -0.13, 0.10),
		Vector3(-0.145, -0.13, 0.0),
		Vector3(0.145, -0.13, 0.0)
	]
	for pb in pos_bolsillos:
		var bolsillo := MeshInstance3D.new()
		var box_bols := BoxMesh.new()
		box_bols.size = Vector3(0.055, 0.06, 0.04)
		bolsillo.mesh = box_bols
		bolsillo.position = pb
		bolsillo.material_override = mat_naranja_tactico
		root.add_child(bolsillo)

	# Funda / pistolera táctica en la cadera derecha
	var funda := MeshInstance3D.new()
	var box_fun := BoxMesh.new()
	box_fun.size = Vector3(0.045, 0.13, 0.065)
	funda.mesh = box_fun
	funda.position = Vector3(0.155, -0.17, 0.02)
	funda.material_override = mat_cuero_funda
	root.add_child(funda)

	var culata := MeshInstance3D.new()
	var box_cul := BoxMesh.new()
	box_cul.size = Vector3(0.02, 0.06, 0.035)
	culata.mesh = box_cul
	culata.position = Vector3(0.165, -0.12, 0.03)
	culata.rotation_degrees.x = 35.0
	culata.material_override = mat_hombrera
	root.add_child(culata)

	return root


static func _crear_rodillera_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "RodilleraCazador"

	var mat_placa := _mat_simple(Color(0.35, 0.38, 0.44), 0.80, 0.28)
	var mat_correa := _mat_simple(Color(0.14, 0.14, 0.16), 0.05, 0.65)
	var mat_naranja_correa := _mat_simple(Color(0.95, 0.44, 0.06), 0.1, 0.50)

	# Placa blindada curva de titanio
	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.088, 0.098, 0.035)
	placa.mesh = box_placa
	placa.material_override = mat_placa
	root.add_child(placa)

	# Doble correa naranja/cuero horizontal superior e inferior (Concept Art: player_archer.glb)
	for sy in [-0.038, 0.038]:
		var correa_naranja := MeshInstance3D.new()
		var box_cn := BoxMesh.new()
		box_cn.size = Vector3(0.098, 0.016, 0.055)
		correa_naranja.mesh = box_cn
		correa_naranja.position = Vector3(0, sy, -0.01)
		correa_naranja.material_override = mat_naranja_correa
		root.add_child(correa_naranja)

		var correa_trasera := MeshInstance3D.new()
		var box_c := BoxMesh.new()
		box_c.size = Vector3(0.095, 0.016, 0.05)
		correa_trasera.mesh = box_c
		correa_trasera.position = Vector3(0, sy, -0.03)
		correa_trasera.material_override = mat_correa
		root.add_child(correa_trasera)

	return root


static func _crear_guantelete_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "GuanteleteCazador"

	var mat_acero := _mat_simple(Color(0.30, 0.34, 0.40), 0.85, 0.30)
	var mat_correa := _mat_simple(Color(0.14, 0.15, 0.18), 0.05, 0.65)

	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.06, 0.04, 0.13)
	placa.mesh = box_placa
	placa.position = Vector3(0, 0.02, 0)
	placa.material_override = mat_acero
	root.add_child(placa)

	var manguito := MeshInstance3D.new()
	var cyl_m := CylinderMesh.new()
	cyl_m.top_radius = 0.032
	cyl_m.bottom_radius = 0.036
	cyl_m.height = 0.12
	manguito.mesh = cyl_m
	manguito.rotation_degrees.x = 90.0
	manguito.material_override = mat_correa
	root.add_child(manguito)

	return root


static func _crear_baston_mago(incluir_particulas: bool = true) -> Dictionary:
	return _crear_baston_capsula_mago(incluir_particulas)


## Báculo Cápsula de Plasma Arcano (Concept Art: player_mage.glb)
static func _crear_baston_capsula_mago(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "BastonCapsulaMago"

	var mat_metal_oxidado := _mat_simple(Color(0.28, 0.27, 0.26), 0.85, 0.42)
	var mat_bronce_caja := _mat_simple(Color(0.42, 0.38, 0.32), 0.88, 0.35)
	var mat_cinta_grip := _mat_simple(Color(0.18, 0.16, 0.15), 0.05, 0.75)
	var mat_cable_negro := _mat_simple(Color(0.12, 0.12, 0.14), 0.10, 0.60)
	var mat_reloj := _mat_simple(Color(0.92, 0.90, 0.85), 0.10, 0.20)
	var mat_aguja := _mat_simple(Color(0.85, 0.15, 0.15), 0.0, 0.30)
	var mat_jaula_acero := _mat_simple(Color(0.38, 0.42, 0.48), 0.92, 0.25)
	var mat_plasma_cian := _mat_simple(Color(0.20, 0.95, 1.0), 0.15, 0.10, Color(0.15, 0.95, 1.0), 2.8)

	var mat_vidrio_capsula := StandardMaterial3D.new()
	mat_vidrio_capsula.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vidrio_capsula.albedo_color = Color(0.65, 0.92, 1.0, 0.35)
	mat_vidrio_capsula.metallic = 0.1
	mat_vidrio_capsula.roughness = 0.08

	# 1. Asta principal de tubería industrial
	var asta := MeshInstance3D.new()
	var cyl_asta := CylinderMesh.new()
	cyl_asta.top_radius = 0.015
	cyl_asta.bottom_radius = 0.015
	cyl_asta.height = 0.82
	cyl_asta.radial_segments = 12
	asta.mesh = cyl_asta
	asta.position = Vector3(0, 0.02, 0)
	asta.material_override = mat_metal_oxidado
	root.add_child(asta)

	# 2. Empuñadura envuelta en cinta táctica
	var grip := MeshInstance3D.new()
	var cyl_grip := CylinderMesh.new()
	cyl_grip.top_radius = 0.019
	cyl_grip.bottom_radius = 0.019
	cyl_grip.height = 0.22
	cyl_grip.radial_segments = 12
	grip.mesh = cyl_grip
	grip.position = Vector3(0, -0.05, 0)
	grip.material_override = mat_cinta_grip
	root.add_child(grip)

	# Anillos de textura de cinta
	for y_cinta in [-0.12, -0.05, 0.02]:
		var aro_c := MeshInstance3D.new()
		var mesh_ac := TorusMesh.new()
		mesh_ac.inner_radius = 0.018
		mesh_ac.outer_radius = 0.022
		aro_c.mesh = mesh_ac
		aro_c.position = Vector3(0, y_cinta, 0)
		aro_c.material_override = mat_metal_oxidado
		root.add_child(aro_c)

	# Cable conductor externo a lo largo del asta inferior
	var cable_asta := MeshInstance3D.new()
	var cyl_ca := CylinderMesh.new()
	cyl_ca.top_radius = 0.005
	cyl_ca.bottom_radius = 0.005
	cyl_ca.height = 0.62
	cable_asta.mesh = cyl_ca
	cable_asta.position = Vector3(0.018, -0.05, 0.005)
	cable_asta.material_override = mat_cable_negro
	root.add_child(cable_asta)

	# Terminal / Pica de tierra en la base del báculo
	var terminal_base := MeshInstance3D.new()
	var cyl_tb := CylinderMesh.new()
	cyl_tb.top_radius = 0.018
	cyl_tb.bottom_radius = 0.008
	cyl_tb.height = 0.08
	terminal_base.mesh = cyl_tb
	terminal_base.position = Vector3(0, -0.41, 0)
	terminal_base.material_override = mat_metal_oxidado
	root.add_child(terminal_base)

	# 3. Caja de Control Industrial, Manómetro y Válvula
	var caja_control := MeshInstance3D.new()
	var box_cc := BoxMesh.new()
	box_cc.size = Vector3(0.065, 0.08, 0.065)
	caja_control.mesh = box_cc
	caja_control.position = Vector3(0, 0.27, 0)
	caja_control.material_override = mat_bronce_caja
	root.add_child(caja_control)

	# Manómetro analógico circular frontal
	var dial_bisel := MeshInstance3D.new()
	var cyl_db := CylinderMesh.new()
	cyl_db.top_radius = 0.022
	cyl_db.bottom_radius = 0.022
	cyl_db.height = 0.010
	cyl_db.radial_segments = 16
	dial_bisel.mesh = cyl_db
	dial_bisel.rotation_degrees = Vector3(90, 0, 0)
	dial_bisel.position = Vector3(0, 0.28, 0.038)
	dial_bisel.material_override = mat_jaula_acero
	root.add_child(dial_bisel)

	var dial_fondo := MeshInstance3D.new()
	var cyl_df := CylinderMesh.new()
	cyl_df.top_radius = 0.019
	cyl_df.bottom_radius = 0.019
	cyl_df.height = 0.005
	cyl_df.radial_segments = 16
	dial_fondo.mesh = cyl_df
	dial_fondo.rotation_degrees = Vector3(90, 0, 0)
	dial_fondo.position = Vector3(0, 0.28, 0.043)
	dial_fondo.material_override = mat_reloj
	root.add_child(dial_fondo)

	var aguja := MeshInstance3D.new()
	var box_ag := BoxMesh.new()
	box_ag.size = Vector3(0.003, 0.016, 0.003)
	aguja.mesh = box_ag
	aguja.rotation_degrees = Vector3(0, 0, 45.0)
	aguja.position = Vector3(0.003, 0.285, 0.046)
	aguja.material_override = mat_aguja
	root.add_child(aguja)

	# Válvula / Escape lateral
	var valvula := MeshInstance3D.new()
	var cyl_val := CylinderMesh.new()
	cyl_val.top_radius = 0.012
	cyl_val.bottom_radius = 0.012
	cyl_val.height = 0.025
	valvula.mesh = cyl_val
	valvula.rotation_degrees = Vector3(0, 0, 90)
	valvula.position = Vector3(0.042, 0.26, 0)
	valvula.material_override = mat_bronce_caja
	root.add_child(valvula)

	# Cable curvo que conecta la caja a la cápsula
	var cable_curvo := MeshInstance3D.new()
	var torus_cc := TorusMesh.new()
	torus_cc.inner_radius = 0.025
	torus_cc.outer_radius = 0.032
	cable_curvo.mesh = torus_cc
	cable_curvo.rotation_degrees = Vector3(0, 0, 45)
	cable_curvo.position = Vector3(-0.035, 0.31, 0)
	cable_curvo.material_override = mat_cable_negro
	root.add_child(cable_curvo)

	# 4. Cuello Inferior y Jaula Protectora de Acero
	var collar_inf := MeshInstance3D.new()
	var cyl_ci := CylinderMesh.new()
	cyl_ci.top_radius = 0.056
	cyl_ci.bottom_radius = 0.045
	cyl_ci.height = 0.035
	cyl_ci.radial_segments = 16
	collar_inf.mesh = cyl_ci
	collar_inf.position = Vector3(0, 0.335, 0)
	collar_inf.material_override = mat_jaula_acero
	root.add_child(collar_inf)

	var tapa_sup := MeshInstance3D.new()
	var cyl_ts := CylinderMesh.new()
	cyl_ts.top_radius = 0.045
	cyl_ts.bottom_radius = 0.056
	cyl_ts.height = 0.035
	cyl_ts.radial_segments = 16
	tapa_sup.mesh = cyl_ts
	tapa_sup.position = Vector3(0, 0.585, 0)
	tapa_sup.material_override = mat_jaula_acero
	root.add_child(tapa_sup)

	var electrodo_punta := MeshInstance3D.new()
	var sph_ep := SphereMesh.new()
	sph_ep.radius = 0.016
	sph_ep.height = 0.032
	electrodo_punta.mesh = sph_ep
	electrodo_punta.position = Vector3(0, 0.608, 0)
	electrodo_punta.material_override = mat_bronce_caja
	root.add_child(electrodo_punta)

	# Aro intermedio de la jaula
	var aro_medio := MeshInstance3D.new()
	var torus_am := TorusMesh.new()
	torus_am.inner_radius = 0.052
	torus_am.outer_radius = 0.060
	aro_medio.mesh = torus_am
	aro_medio.position = Vector3(0, 0.455, 0)
	aro_medio.material_override = mat_jaula_acero
	root.add_child(aro_medio)

	# 4 Barras longitudinales protectoras de la cápsula
	var coords_barras: Array[Vector3] = [
		Vector3(0.056, 0.455, 0.0),
		Vector3(-0.056, 0.455, 0.0),
		Vector3(0.0, 0.455, 0.056),
		Vector3(0.0, 0.455, -0.056)
	]
	for p_bar in coords_barras:
		var barra := MeshInstance3D.new()
		var cyl_b := CylinderMesh.new()
		cyl_b.top_radius = 0.005
		cyl_b.bottom_radius = 0.005
		cyl_b.height = 0.24
		barra.mesh = cyl_b
		barra.position = p_bar
		barra.material_override = mat_jaula_acero
		root.add_child(barra)

	# 5. Cápsula de Vidrio de Contención y Núcleo de Plasma Lóbrego
	var tubo_vidrio := MeshInstance3D.new()
	var cyl_tv := CylinderMesh.new()
	cyl_tv.top_radius = 0.048
	cyl_tv.bottom_radius = 0.048
	cyl_tv.height = 0.22
	cyl_tv.radial_segments = 16
	tubo_vidrio.mesh = cyl_tv
	tubo_vidrio.position = Vector3(0, 0.455, 0)
	tubo_vidrio.material_override = mat_vidrio_capsula
	root.add_child(tubo_vidrio)

	# Cúpula de vidrio superior e inferior para silueta de cápsula
	for dy_vid in [-0.10, 0.10]:
		var cup_v := MeshInstance3D.new()
		var sph_v := SphereMesh.new()
		sph_v.radius = 0.048
		sph_v.height = 0.096
		cup_v.mesh = sph_v
		cup_v.position = Vector3(0, 0.455 + dy_vid, 0)
		cup_v.material_override = mat_vidrio_capsula
		root.add_child(cup_v)

	# Núcleo interior de plasma cian resplandeciente
	var nucleo_plasma := MeshInstance3D.new()
	var cyl_np := CylinderMesh.new()
	cyl_np.top_radius = 0.028
	cyl_np.bottom_radius = 0.028
	cyl_np.height = 0.16
	cyl_np.radial_segments = 16
	nucleo_plasma.mesh = cyl_np
	nucleo_plasma.position = Vector3(0, 0.455, 0)
	nucleo_plasma.material_override = mat_plasma_cian
	root.add_child(nucleo_plasma)

	# Esferas de plasma adicionales
	for dy_p in [-0.06, 0.06]:
		var sph_p := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		s_mesh.radius = 0.026
		s_mesh.height = 0.052
		sph_p.mesh = s_mesh
		sph_p.position = Vector3(0, 0.455 + dy_p, 0)
		sph_p.material_override = mat_plasma_cian
		root.add_child(sph_p)

	# 6. Partículas de Descarga y Luz Dinámica (LuzOrbe)
	var luz: OmniLight3D = null
	if incluir_particulas:
		var chispas := CPUParticles3D.new()
		chispas.name = "ChispasPlasmaMago"
		chispas.emitting = true
		chispas.amount = 22
		chispas.lifetime = 0.45
		chispas.explosiveness = 0.20
		chispas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		chispas.emission_sphere_radius = 0.06
		chispas.direction = Vector3(0, 1, 0)
		chispas.spread = 60.0
		chispas.gravity = Vector3(0, 0.5, 0)
		chispas.initial_velocity_min = 0.6
		chispas.initial_velocity_max = 1.6
		chispas.color = Color(0.25, 0.95, 1.0)
		chispas.position = Vector3(0, 0.46, 0)
		root.add_child(chispas)

		luz = OmniLight3D.new()
		luz.name = "LuzOrbe"
		luz.position = Vector3(0, 0.46, 0)
		luz.light_color = Color(0.18, 0.92, 1.0)
		luz.light_energy = 1.6
		luz.omni_range = 2.2
		root.add_child(luz)

	var res := {"nodo": root}
	if luz != null:
		res["luz"] = luz
	return res


## Fuego Arcano en Mano Izquierda y Brazal Táctico (Concept Art: player_mage.glb)
static func _crear_fuego_arcano_mago(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "FuegoArcanoMago"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.31), 0.86, 0.35)
	var mat_correa := _mat_simple(Color(0.16, 0.14, 0.12), 0.05, 0.65)
	var mat_plasma_cian := _mat_simple(Color(0.20, 0.95, 1.0), 0.15, 0.10, Color(0.15, 0.95, 1.0), 2.5)

	# 1. Brazal reforzado en antebrazo izquierdo
	var brazal := MeshInstance3D.new()
	var box_br := BoxMesh.new()
	box_br.size = Vector3(0.075, 0.14, 0.038)
	brazal.mesh = box_br
	brazal.position = Vector3(0, -0.06, 0.02)
	brazal.material_override = mat_acero
	root.add_child(brazal)

	# Correas del brazal
	for dy in [-0.10, -0.02]:
		var correa := MeshInstance3D.new()
		var box_c := BoxMesh.new()
		box_c.size = Vector3(0.085, 0.02, 0.045)
		correa.mesh = box_c
		correa.position = Vector3(0, dy, 0.015)
		correa.material_override = mat_correa
		root.add_child(correa)

	# 2. Llama Arcana Conjurada en la Palma
	var llama_nucleo := MeshInstance3D.new()
	var sph_ll := SphereMesh.new()
	sph_ll.radius = 0.032
	sph_ll.height = 0.065
	llama_nucleo.mesh = sph_ll
	llama_nucleo.scale = Vector3(0.85, 1.25, 0.85)
	llama_nucleo.position = Vector3(0.02, -0.16, 0.05)
	llama_nucleo.material_override = mat_plasma_cian
	root.add_child(llama_nucleo)

	var llama_punta := MeshInstance3D.new()
	var sph_lp := SphereMesh.new()
	sph_lp.radius = 0.018
	sph_lp.height = 0.040
	llama_punta.mesh = sph_lp
	llama_punta.position = Vector3(0.02, -0.12, 0.05)
	llama_punta.material_override = mat_plasma_cian
	root.add_child(llama_punta)

	var luz_fuego: OmniLight3D = null
	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.name = "ParticulasFuegoArcano"
		part.emitting = true
		part.amount = 14
		part.lifetime = 0.50
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.03
		part.direction = Vector3(0, 1, 0)
		part.spread = 35.0
		part.gravity = Vector3(0, 0.9, 0)
		part.initial_velocity_min = 0.4
		part.initial_velocity_max = 1.0
		part.scale_amount_min = 0.015
		part.scale_amount_max = 0.035
		part.color = Color(0.25, 0.95, 1.0)
		part.position = Vector3(0.02, -0.15, 0.05)
		root.add_child(part)

		luz_fuego = OmniLight3D.new()
		luz_fuego.name = "LuzFuegoArcano"
		luz_fuego.position = Vector3(0.02, -0.15, 0.06)
		luz_fuego.light_color = Color(0.18, 0.92, 1.0)
		luz_fuego.light_energy = 0.75
		luz_fuego.omni_range = 1.2
		root.add_child(luz_fuego)

	var res := {"nodo": root}
	if luz_fuego != null:
		res["luz"] = luz_fuego
	return res


## Cabeza del Mago: Cabello Despeinado, Gafas HUD Cian, Respirador y Bufanda Naranja (Concept Art: player_mage.glb)
static func _crear_cabeza_mago() -> Node3D:
	var root := Node3D.new()
	root.name = "CabezaMago"

	var mat_pelo := _mat_simple(Color(0.12, 0.13, 0.15), 0.05, 0.85)
	var mat_gafas_marco := _mat_simple(Color(0.22, 0.24, 0.28), 0.85, 0.35)
	var mat_visor_cian := _mat_simple(Color(0.12, 0.92, 1.0), 0.2, 0.1, Color(0.15, 0.95, 1.0), 2.2)
	var mat_mascara := _mat_simple(Color(0.20, 0.22, 0.25), 0.75, 0.45)
	var mat_filtro := _mat_simple(Color(0.45, 0.48, 0.52), 0.88, 0.30)
	var mat_naranja := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)

	# 1. Cabello Negro Grafito Despeinado con Mechones en Punta
	var pelo_base := MeshInstance3D.new()
	var sph_pb := SphereMesh.new()
	sph_pb.radius = 0.14
	sph_pb.height = 0.28
	pelo_base.mesh = sph_pb
	pelo_base.scale = Vector3(1.02, 0.95, 1.05)
	pelo_base.position = Vector3(0, 0.06, -0.01)
	pelo_base.material_override = mat_pelo
	root.add_child(pelo_base)

	# Mechones en punta frontales y laterales
	var mechones_data: Array[Vector3] = [
		Vector3(0.0, 0.16, 0.09),
		Vector3(-0.06, 0.15, 0.08),
		Vector3(0.06, 0.15, 0.08),
		Vector3(-0.11, 0.08, 0.04),
		Vector3(0.11, 0.08, 0.04),
		Vector3(0.0, 0.19, -0.03),
		Vector3(-0.07, 0.17, -0.05),
		Vector3(0.07, 0.17, -0.05)
	]
	for m_pos in mechones_data:
		var mechon := MeshInstance3D.new()
		var box_m := BoxMesh.new()
		box_m.size = Vector3(0.045, 0.055, 0.045)
		mechon.mesh = box_m
		mechon.rotation_degrees = Vector3(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0), randf_range(-25.0, 25.0))
		mechon.position = m_pos
		mechon.material_override = mat_pelo
		root.add_child(mechon)

	# 2. Gafas Tácticas HUD Panorámicas Cian
	var visor := MeshInstance3D.new()
	var box_v := BoxMesh.new()
	box_v.size = Vector3(0.20, 0.060, 0.035)
	visor.mesh = box_v
	visor.position = Vector3(0, 0.035, 0.125)
	visor.material_override = mat_visor_cian
	root.add_child(visor)

	# Marco envolvente oscuro de las gafas
	var marco_g := MeshInstance3D.new()
	var box_mg := BoxMesh.new()
	box_mg.size = Vector3(0.22, 0.075, 0.025)
	marco_g.mesh = box_mg
	marco_g.position = Vector3(0, 0.035, 0.118)
	marco_g.material_override = mat_gafas_marco
	root.add_child(marco_g)

	# Correa lateral envolvente de las gafas
	var correa_g := MeshInstance3D.new()
	var torus_cg := TorusMesh.new()
	torus_cg.inner_radius = 0.135
	torus_cg.outer_radius = 0.145
	correa_g.mesh = torus_cg
	correa_g.position = Vector3(0, 0.035, 0)
	correa_g.material_override = mat_pelo
	root.add_child(correa_g)

	# 3. Máscara de Gas Respirador con Filtros Laterales Circulares
	var mascara := MeshInstance3D.new()
	var box_masc := BoxMesh.new()
	box_masc.size = Vector3(0.14, 0.075, 0.08)
	mascara.mesh = box_masc
	mascara.position = Vector3(0, -0.055, 0.11)
	mascara.material_override = mat_mascara
	root.add_child(mascara)

	# Rejilla frontal
	var rejilla := MeshInstance3D.new()
	var box_rej := BoxMesh.new()
	box_rej.size = Vector3(0.05, 0.04, 0.018)
	rejilla.mesh = box_rej
	rejilla.position = Vector3(0, -0.055, 0.152)
	rejilla.material_override = mat_filtro
	root.add_child(rejilla)

	# Canistros / Filtros circulares en las mejillas
	for lado in [-1.0, 1.0]:
		var filtro := MeshInstance3D.new()
		var cyl_f := CylinderMesh.new()
		cyl_f.top_radius = 0.030
		cyl_f.bottom_radius = 0.030
		cyl_f.height = 0.025
		filtro.mesh = cyl_f
		filtro.rotation_degrees = Vector3(0, lado * 20.0, 90.0)
		filtro.position = Vector3(lado * 0.075, -0.055, 0.085)
		filtro.material_override = mat_filtro
		root.add_child(filtro)

	# 4. Bufanda Táctica Naranja en el Cuello
	var bufanda := MeshInstance3D.new()
	var torus_buf := TorusMesh.new()
	torus_buf.inner_radius = 0.11
	torus_buf.outer_radius = 0.145
	bufanda.mesh = torus_buf
	bufanda.position = Vector3(0, -0.09, 0.02)
	bufanda.material_override = mat_naranja
	root.add_child(bufanda)

	return root


## Gabardina Larga de Arcanista, Arnés con Viales Verdes y Cinturón con Viales Cian (Concept Art: player_mage.glb)
static func _crear_gabardina_arcanista_mago() -> Node3D:
	var root := Node3D.new()
	root.name = "GabardinaArcanistaMago"

	var mat_gabardina := _mat_simple(Color(0.20, 0.24, 0.28), 0.15, 0.75)
	var mat_gabardina_oscura := _mat_simple(Color(0.14, 0.17, 0.20), 0.10, 0.80)
	var mat_cuero := _mat_simple(Color(0.22, 0.16, 0.12), 0.05, 0.65)
	var mat_naranja := _mat_simple(Color(0.92, 0.44, 0.12), 0.15, 0.40)
	var mat_metal := _mat_simple(Color(0.48, 0.52, 0.58), 0.90, 0.25)
	var mat_cable := _mat_simple(Color(0.12, 0.12, 0.14), 0.10, 0.60)
	var mat_vial_verde := _mat_simple(Color(0.25, 0.95, 0.35), 0.20, 0.10, Color(0.25, 0.95, 0.35), 2.2)
	var mat_vial_cian := _mat_simple(Color(0.18, 0.92, 1.0), 0.20, 0.10, Color(0.18, 0.92, 1.0), 2.4)

	# 1. Cuerpo Superior y Cuello Alzado de la Gabardina
	var cuerpo_abrigo := MeshInstance3D.new()
	var box_ca := BoxMesh.new()
	box_ca.size = Vector3(0.32, 0.24, 0.14)
	cuerpo_abrigo.mesh = box_ca
	cuerpo_abrigo.position = Vector3(0, 0.16, 0.02)
	cuerpo_abrigo.material_override = mat_gabardina
	root.add_child(cuerpo_abrigo)

	# Cuello alto alzado detrás del cuello
	var cuello_alto := MeshInstance3D.new()
	var box_cu := BoxMesh.new()
	box_cu.size = Vector3(0.28, 0.12, 0.06)
	cuello_alto.mesh = box_cu
	cuello_alto.position = Vector3(0, 0.29, -0.05)
	cuello_alto.material_override = mat_gabardina
	root.add_child(cuello_alto)

	# Solapas frontales abiertas
	for lado in [-1.0, 1.0]:
		var solapa := MeshInstance3D.new()
		var box_s := BoxMesh.new()
		box_s.size = Vector3(0.06, 0.20, 0.025)
		solapa.mesh = box_s
		solapa.rotation_degrees = Vector3(0, 0, lado * -15.0)
		solapa.position = Vector3(lado * 0.09, 0.18, 0.095)
		solapa.material_override = mat_gabardina_oscura
		root.add_child(solapa)

	# Hombrera de refuerzo en hombro izquierdo
	var hombrera_izq := MeshInstance3D.new()
	var box_hi := BoxMesh.new()
	box_hi.size = Vector3(0.10, 0.035, 0.12)
	hombrera_izq.mesh = box_hi
	hombrera_izq.position = Vector3(0.21, 0.24, 0)
	hombrera_izq.material_override = mat_metal
	root.add_child(hombrera_izq)

	# 2. Faldones Largos y Rasgados de la Gabardina (Se extienden hasta las rodillas)
	# Faldón trasero
	var faldon_trasero := MeshInstance3D.new()
	var box_ft := BoxMesh.new()
	box_ft.size = Vector3(0.30, 0.44, 0.025)
	faldon_trasero.mesh = box_ft
	faldon_trasero.rotation_degrees = Vector3(12.0, 0, 0)
	faldon_trasero.position = Vector3(0, -0.22, -0.10)
	faldon_trasero.material_override = mat_gabardina
	root.add_child(faldon_trasero)

	# Faldones laterales acampanados
	for lado in [-1.0, 1.0]:
		var faldon_lat := MeshInstance3D.new()
		var box_fl := BoxMesh.new()
		box_fl.size = Vector3(0.025, 0.44, 0.22)
		faldon_lat.mesh = box_fl
		faldon_lat.rotation_degrees = Vector3(0, 0, lado * -10.0)
		faldon_lat.position = Vector3(lado * 0.18, -0.22, 0)
		faldon_lat.material_override = mat_gabardina
		root.add_child(faldon_lat)

		# Puntas rasgadas inferiores
		for k in range(3):
			var punta := MeshInstance3D.new()
			var box_p := BoxMesh.new()
			box_p.size = Vector3(0.022, 0.065, 0.035)
			punta.mesh = box_p
			punta.rotation_degrees = Vector3(randf_range(-15, 15), 0, randf_range(-20, 20))
			punta.position = Vector3(lado * 0.175, -0.45, -0.06 + k * 0.06)
			punta.material_override = mat_gabardina_oscura
			root.add_child(punta)

	# 3. Cable Conductor que rodea el flanco derecho
	var cable_flanco := MeshInstance3D.new()
	var torus_cf := TorusMesh.new()
	torus_cf.inner_radius = 0.14
	torus_cf.outer_radius = 0.155
	cable_flanco.mesh = torus_cf
	cable_flanco.rotation_degrees = Vector3(15.0, 0, -25.0)
	cable_flanco.position = Vector3(-0.06, 0.14, 0)
	cable_flanco.material_override = mat_cable
	root.add_child(cable_flanco)

	# 4. Arnés Diagonal de Pecho con 2 Viales Verdes de Suero Químico
	var arnes := MeshInstance3D.new()
	var box_arn := BoxMesh.new()
	box_arn.size = Vector3(0.040, 0.34, 0.020)
	arnes.mesh = box_arn
	arnes.rotation_degrees = Vector3(0, 0, 30.0)
	arnes.position = Vector3(-0.02, 0.12, 0.10)
	arnes.material_override = mat_cuero
	root.add_child(arnes)

	# 2 Viales de suero verde brillante montados en el arnés
	var pos_viales_verdes: Array[Vector3] = [
		Vector3(-0.05, 0.15, 0.118),
		Vector3(0.01, 0.10, 0.118)
	]
	for pos_v in pos_viales_verdes:
		var vial := MeshInstance3D.new()
		var cyl_v := CylinderMesh.new()
		cyl_v.top_radius = 0.012
		cyl_v.bottom_radius = 0.012
		cyl_v.height = 0.065
		vial.mesh = cyl_v
		vial.rotation_degrees = Vector3(0, 0, -35.0)
		vial.position = pos_v
		vial.material_override = mat_vial_verde
		root.add_child(vial)

		# Tapas metálicas en los extremos del vial
		for dy in [-0.035, 0.035]:
			var tapa := MeshInstance3D.new()
			var cyl_t := CylinderMesh.new()
			cyl_t.top_radius = 0.014
			cyl_t.bottom_radius = 0.014
			cyl_t.height = 0.010
			tapa.mesh = cyl_t
			tapa.rotation_degrees = Vector3(0, 0, -35.0)
			tapa.position = pos_v + Vector3(sin(deg_to_rad(35.0)) * dy, cos(deg_to_rad(35.0)) * dy, 0)
			tapa.material_override = mat_metal
			root.add_child(tapa)

	# 5. Cinturón Táctico con 3 Viales Cian y Frasco Colgante
	var cinturon := MeshInstance3D.new()
	var box_cint := BoxMesh.new()
	box_cint.size = Vector3(0.33, 0.060, 0.24)
	cinturon.mesh = box_cint
	cinturon.position = Vector3(0, -0.06, 0.0)
	cinturon.material_override = mat_naranja
	root.add_child(cinturon)

	var hebilla := MeshInstance3D.new()
	var box_heb := BoxMesh.new()
	box_heb.size = Vector3(0.065, 0.070, 0.025)
	hebilla.mesh = box_heb
	hebilla.position = Vector3(0, -0.06, 0.125)
	hebilla.material_override = mat_metal
	root.add_child(hebilla)

	# 3 Viales de plasma cian alineados en la cadera derecha
	var x_coords_cian: Array[float] = [-0.10, -0.135, -0.165]
	for k in range(3):
		var posX: float = x_coords_cian[k]
		var posZ: float = 0.12 - k * 0.015
		var vial_c := MeshInstance3D.new()
		var cyl_vc := CylinderMesh.new()
		cyl_vc.top_radius = 0.010
		cyl_vc.bottom_radius = 0.010
		cyl_vc.height = 0.055
		vial_c.mesh = cyl_vc
		vial_c.position = Vector3(posX, -0.06, posZ)
		vial_c.material_override = mat_vial_cian
		root.add_child(vial_c)

		# Soporte metálico del vial
		var soporte := MeshInstance3D.new()
		var box_sop := BoxMesh.new()
		box_sop.size = Vector3(0.024, 0.022, 0.015)
		soporte.mesh = box_sop
		soporte.position = Vector3(posX, -0.06, posZ - 0.005)
		soporte.material_override = mat_metal
		root.add_child(soporte)

	# Frasco / Botella química vertical colgante en la cadera izquierda
	var frasco := MeshInstance3D.new()
	var cyl_fr := CylinderMesh.new()
	cyl_fr.top_radius = 0.024
	cyl_fr.bottom_radius = 0.024
	cyl_fr.height = 0.075
	frasco.mesh = cyl_fr
	frasco.position = Vector3(0.17, -0.14, 0.02)
	frasco.material_override = mat_vial_cian
	root.add_child(frasco)

	var tapa_frasco := MeshInstance3D.new()
	var cyl_tf := CylinderMesh.new()
	cyl_tf.top_radius = 0.014
	cyl_tf.bottom_radius = 0.014
	cyl_tf.height = 0.020
	tapa_frasco.mesh = cyl_tf
	tapa_frasco.position = Vector3(0.17, -0.09, 0.02)
	tapa_frasco.material_override = mat_metal
	root.add_child(tapa_frasco)

	var correa_frasco := MeshInstance3D.new()
	var box_cfr := BoxMesh.new()
	box_cfr.size = Vector3(0.02, 0.05, 0.02)
	correa_frasco.mesh = box_cfr
	correa_frasco.position = Vector3(0.17, -0.07, 0.02)
	correa_frasco.material_override = mat_cuero
	root.add_child(correa_frasco)

	# Bolsillo utilitario de cuero en cadera izquierda
	var bolsillo := MeshInstance3D.new()
	var box_bol := BoxMesh.new()
	box_bol.size = Vector3(0.045, 0.065, 0.055)
	bolsillo.mesh = box_bol
	bolsillo.position = Vector3(0.145, -0.06, 0.08)
	bolsillo.material_override = mat_cuero
	root.add_child(bolsillo)

	return root


## Protección de Piernas del Mago: Rodilleras Tácticas y Correas de Cuero en Muslo (Concept Art: player_mage.glb)
static func _crear_proteccion_pierna_mago(es_derecha: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "ProteccionPiernaMago"

	var mat_acero := _mat_simple(Color(0.25, 0.27, 0.31), 0.86, 0.35)
	var mat_acero_claro := _mat_simple(Color(0.48, 0.52, 0.58), 0.90, 0.25)
	var mat_cuero := _mat_simple(Color(0.22, 0.16, 0.12), 0.05, 0.65)

	# 1. Rodillera táctica de acero redondeada
	var rodillera := MeshInstance3D.new()
	var sph_r := SphereMesh.new()
	sph_r.radius = 0.055
	sph_r.height = 0.11
	rodillera.mesh = sph_r
	rodillera.scale = Vector3(0.95, 0.95, 0.60)
	rodillera.position = Vector3(0, 0, 0.02)
	rodillera.material_override = mat_acero
	root.add_child(rodillera)

	# Remaches de la rodillera
	for rx in [-0.03, 0.03]:
		for ry in [-0.025, 0.025]:
			var rem := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.007
			sph.height = 0.014
			rem.mesh = sph
			rem.position = Vector3(rx, ry, 0.052)
			rem.material_override = mat_acero_claro
			root.add_child(rem)

	# 2. Doble correa horizontal de cuero con hebilla en el muslo derecho
	if es_derecha:
		for dy in [0.035, 0.075]:
			var correa := MeshInstance3D.new()
			var box_c := BoxMesh.new()
			box_c.size = Vector3(0.11, 0.020, 0.11)
			correa.mesh = box_c
			correa.position = Vector3(0, dy, -0.01)
			correa.material_override = mat_cuero
			root.add_child(correa)

			var hebilla_m := MeshInstance3D.new()
			var box_hm := BoxMesh.new()
			box_hm.size = Vector3(0.025, 0.024, 0.010)
			hebilla_m.mesh = box_hm
			hebilla_m.position = Vector3(0, dy, 0.052)
			hebilla_m.material_override = mat_acero_claro
			root.add_child(hebilla_m)

	# 3. Correa de caña de bota
	var correa_bota := MeshInstance3D.new()
	var box_cb := BoxMesh.new()
	box_cb.size = Vector3(0.09, 0.020, 0.09)
	correa_bota.mesh = box_cb
	correa_bota.position = Vector3(0, -0.12, 0.0)
	correa_bota.material_override = mat_cuero
	root.add_child(correa_bota)

	return root


# ==============================================================================
# ARMAS PROCEDURALES EVOLUCIONADAS TIER 2
# ==============================================================================

static func _crear_gran_espada_paladin() -> Node3D:
	var root := Node3D.new()
	root.name = "GranEspadaPaladin"
	var mat_oro := _mat_simple(Color(1.0, 0.85, 0.32), 0.95, 0.18, Color(1.0, 0.75, 0.20), 1.2)
	var mat_hoja := _mat_simple(Color(0.96, 0.98, 1.0), 0.98, 0.15)
	var mat_solar := _mat_simple(Color(1.0, 0.92, 0.50), 0.0, 0.2, Color(1.0, 0.80, 0.15), 4.5)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.028, 0.028, 0.16)
	grip.mesh = box_grip
	grip.position = Vector3(0, 0, -0.08)
	grip.material_override = mat_oro
	root.add_child(grip)

	var guard := MeshInstance3D.new()
	var box_guard := BoxMesh.new()
	box_guard.size = Vector3(0.22, 0.045, 0.035)
	guard.mesh = box_guard
	guard.position = Vector3(0, 0, 0.02)
	guard.material_override = mat_oro
	root.add_child(guard)

	var hoja := MeshInstance3D.new()
	var box_hoja := BoxMesh.new()
	box_hoja.size = Vector3(0.085, 0.016, 0.68)
	hoja.mesh = box_hoja
	hoja.position = Vector3(0, 0, 0.37)
	hoja.material_override = mat_hoja
	root.add_child(hoja)

	var canal_solar := MeshInstance3D.new()
	var box_solar := BoxMesh.new()
	box_solar.size = Vector3(0.030, 0.022, 0.52)
	canal_solar.mesh = box_solar
	canal_solar.position = Vector3(0, 0, 0.35)
	canal_solar.material_override = mat_solar
	root.add_child(canal_solar)
	return root

static func _crear_escudo_paladin() -> Node3D:
	var root := Node3D.new()
	root.name = "EscudoPaladin"
	var mat_oro := _mat_simple(Color(1.0, 0.85, 0.32), 0.95, 0.20, Color(1.0, 0.78, 0.25), 1.0)
	var mat_placa := _mat_simple(Color(0.88, 0.92, 0.98), 0.90, 0.25)
	var mat_crest := _mat_simple(Color(1.0, 0.90, 0.35), 0.2, 0.1, Color(1.0, 0.82, 0.18), 3.8)

	var placa := MeshInstance3D.new()
	var box_placa := BoxMesh.new()
	box_placa.size = Vector3(0.30, 0.38, 0.030)
	placa.mesh = box_placa
	placa.position = Vector3(0.0, 0.0, 0.05)
	placa.material_override = mat_placa
	root.add_child(placa)

	var borde := MeshInstance3D.new()
	var box_borde := BoxMesh.new()
	box_borde.size = Vector3(0.33, 0.41, 0.025)
	borde.mesh = box_borde
	borde.position = Vector3(0.0, 0.0, 0.044)
	borde.material_override = mat_oro
	root.add_child(borde)

	var sol_crest := MeshInstance3D.new()
	var box_crest := BoxMesh.new()
	box_crest.size = Vector3(0.12, 0.12, 0.040)
	sol_crest.mesh = box_crest
	sol_crest.position = Vector3(0.0, 0.0, 0.065)
	sol_crest.rotation_degrees = Vector3(0, 0, 45.0)
	sol_crest.material_override = mat_crest
	root.add_child(sol_crest)
	return root

static func _crear_hacha_berserker(incluir_particulas: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "HachaBerserker"
	var mat_mango := _mat_simple(Color(0.20, 0.15, 0.12), 0.1, 0.6)
	var mat_hoja := _mat_simple(Color(0.85, 0.12, 0.16), 0.85, 0.22, Color(0.95, 0.10, 0.15), 2.8)

	var mango := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.013
	cyl.height = 0.58
	mango.mesh = cyl
	mango.position = Vector3(0, 0.08, 0)
	mango.material_override = mat_mango
	root.add_child(mango)

	var hoja_frente := MeshInstance3D.new()
	var box_hf := BoxMesh.new()
	box_hf.size = Vector3(0.018, 0.19, 0.14)
	hoja_frente.mesh = box_hf
	hoja_frente.position = Vector3(0, 0.28, 0.08)
	hoja_frente.material_override = mat_hoja
	root.add_child(hoja_frente)

	var hoja_atras := MeshInstance3D.new()
	var box_ha := BoxMesh.new()
	box_ha.size = Vector3(0.016, 0.14, 0.09)
	hoja_atras.mesh = box_ha
	hoja_atras.position = Vector3(0, 0.28, -0.06)
	hoja_atras.material_override = mat_hoja
	root.add_child(hoja_atras)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 6
		part.lifetime = 0.45
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.06
		part.gravity = Vector3(0, 0.4, 0)
		part.color = Color(1.0, 0.2, 0.1, 0.8)
		part.position = Vector3(0, 0.28, 0.05)
		root.add_child(part)
	return root

static func _crear_arco_astral(incluir_particulas: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "ArcoAstral"
	var mat_arco := _mat_simple(Color(0.12, 0.22, 0.38), 0.92, 0.15)
	var mat_plasma := _mat_simple(Color(0.18, 0.95, 1.0), 0.0, 0.1, Color(0.15, 0.92, 1.0), 4.2)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.026, 0.08, 0.034)
	grip.mesh = box_grip
	grip.material_override = mat_arco
	root.add_child(grip)

	var box_pala := BoxMesh.new()
	box_pala.size = Vector3(0.020, 0.26, 0.024)

	var pala_up := MeshInstance3D.new()
	pala_up.mesh = box_pala
	pala_up.position = Vector3(0, 0.15, -0.035)
	pala_up.rotation_degrees = Vector3(22.0, 0.0, 0.0)
	pala_up.material_override = mat_arco
	root.add_child(pala_up)

	var pala_down := MeshInstance3D.new()
	pala_down.mesh = box_pala
	pala_down.position = Vector3(0, -0.15, -0.035)
	pala_down.rotation_degrees = Vector3(-22.0, 0.0, 0.0)
	pala_down.material_override = mat_arco
	root.add_child(pala_down)

	var rail_plasma := MeshInstance3D.new()
	var cyl_rail := CylinderMesh.new()
	cyl_rail.top_radius = 0.005
	cyl_rail.bottom_radius = 0.005
	cyl_rail.height = 0.54
	rail_plasma.mesh = cyl_rail
	rail_plasma.position = Vector3(0, 0, -0.08)
	rail_plasma.material_override = mat_plasma
	root.add_child(rail_plasma)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 8
		part.lifetime = 0.5
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.04
		part.color = Color(0.2, 0.95, 1.0, 0.9)
		part.position = Vector3(0, 0, 0.0)
		root.add_child(part)
	return root

static func _crear_daga_sombra(incluir_particulas: bool = true, invertida: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "DagaSombra"
	var mat_grip := _mat_simple(Color(0.12, 0.10, 0.16), 0.1, 0.5)
	var mat_hoja := _mat_simple(Color(0.65, 0.18, 1.0), 0.85, 0.20, Color(0.70, 0.20, 1.0), 3.2)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.018, 0.018, 0.08)
	grip.mesh = box_grip
	grip.position = Vector3(0, 0, -0.03 if not invertida else 0.03)
	grip.material_override = mat_grip
	root.add_child(grip)

	var hoja := MeshInstance3D.new()
	var box_hoja := BoxMesh.new()
	box_hoja.size = Vector3(0.026, 0.009, 0.24)
	hoja.mesh = box_hoja
	hoja.position = Vector3(0, 0, 0.13 if not invertida else -0.13)
	hoja.material_override = mat_hoja
	root.add_child(hoja)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 5
		part.lifetime = 0.4
		part.color = Color(0.75, 0.25, 1.0, 0.75)
		part.position = Vector3(0, 0, 0.12 if not invertida else -0.12)
		root.add_child(part)
	return root

static func _crear_baston_vacio(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "BastonVacio"
	var mat_asta := _mat_simple(Color(0.15, 0.12, 0.22), 0.85, 0.25)
	var mat_vacio := _mat_simple(Color(0.48, 0.06, 0.90), 0.1, 0.1, Color(0.60, 0.12, 1.0), 4.2)

	var asta := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.014
	cyl.bottom_radius = 0.012
	cyl.height = 0.82
	asta.mesh = cyl
	asta.position = Vector3(0, 0.08, 0)
	asta.material_override = mat_asta
	root.add_child(asta)

	var orbe_vacio := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.052
	sph.height = 0.104
	orbe_vacio.mesh = sph
	orbe_vacio.position = Vector3(0, 0.54, 0)
	orbe_vacio.material_override = mat_vacio
	root.add_child(orbe_vacio)

	var luz := OmniLight3D.new()
	luz.name = "LuzVacio"
	luz.position = Vector3(0, 0.54, 0)
	luz.light_color = Color(0.65, 0.15, 1.0)
	luz.light_energy = 2.2
	luz.omni_range = 2.4
	root.add_child(luz)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 12
		part.lifetime = 0.75
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.08
		part.gravity = Vector3(0, 0.35, 0)
		part.color = Color(0.7, 0.2, 1.0, 0.95)
		part.position = Vector3(0, 0.54, 0)
		root.add_child(part)
	return {"nodo": root, "luz": luz}

static func _crear_baston_piromante(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "BastonPiromante"
	var mat_basalto := _mat_simple(Color(0.18, 0.16, 0.15), 0.4, 0.6)
	var mat_magma := _mat_simple(Color(1.0, 0.40, 0.05), 0.1, 0.15, Color(1.0, 0.48, 0.08), 4.5)

	var asta := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.013
	cyl.height = 0.84
	asta.mesh = cyl
	asta.position = Vector3(0, 0.08, 0)
	asta.material_override = mat_basalto
	root.add_child(asta)

	var orbe_magma := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.058
	sph.height = 0.116
	orbe_magma.mesh = sph
	orbe_magma.position = Vector3(0, 0.55, 0)
	orbe_magma.material_override = mat_magma
	root.add_child(orbe_magma)

	var luz := OmniLight3D.new()
	luz.name = "LuzMagma"
	luz.position = Vector3(0, 0.55, 0)
	luz.light_color = Color(1.0, 0.55, 0.12)
	luz.light_energy = 2.8
	luz.omni_range = 2.6
	root.add_child(luz)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 14
		part.lifetime = 0.65
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.07
		part.gravity = Vector3(0, 0.5, 0)
		part.color = Color(1.0, 0.6, 0.1, 0.95)
		part.position = Vector3(0, 0.55, 0)
		root.add_child(part)
	return {"nodo": root, "luz": luz}

static func _crear_guantelete_avatar() -> Node3D:
	var root := Node3D.new()
	root.name = "GuanteleteAvatar"
	var mat_oro := _mat_simple(Color(1.0, 0.85, 0.28), 0.95, 0.20)
	var mat_energia := _mat_simple(Color(0.25, 0.95, 0.85), 0.0, 0.1, Color(0.20, 0.95, 0.85), 4.2)

	var brazal := MeshInstance3D.new()
	var box_b := BoxMesh.new()
	box_b.size = Vector3(0.045, 0.045, 0.14)
	brazal.mesh = box_b
	brazal.position = Vector3(0, 0, -0.04)
	brazal.material_override = mat_oro
	root.add_child(brazal)

	var hoja := MeshInstance3D.new()
	var box_h := BoxMesh.new()
	box_h.size = Vector3(0.038, 0.012, 0.42)
	hoja.mesh = box_h
	hoja.position = Vector3(0, 0, 0.22)
	hoja.material_override = mat_energia
	root.add_child(hoja)
	return root

static func _crear_prisma_avatar(incluir_particulas: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "PrismaAvatar"
	var mat_prisma := _mat_simple(Color(0.25, 0.95, 0.85), 0.2, 0.1, Color(0.30, 0.95, 0.90), 3.8)

	var prisma := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 0.09, 0.09)
	prisma.mesh = box
	prisma.rotation_degrees = Vector3(45.0, 45.0, 45.0)
	prisma.material_override = mat_prisma
	root.add_child(prisma)

	var luz := OmniLight3D.new()
	luz.light_color = Color(0.25, 0.95, 0.88)
	luz.light_energy = 1.8
	luz.omni_range = 1.6
	root.add_child(luz)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 8
		part.lifetime = 0.6
		part.color = Color(0.3, 0.95, 0.9, 0.85)
		root.add_child(part)
	return root


## Fusiona sub-mallas esqueléticas redundantes por material en un solo ArrayMesh cacheado por archivo .glb.
static func optimizar_modelo_esqueletico(modelo_raiz: Node3D) -> void:
	if modelo_raiz == null or modelo_raiz.has_meta(&"malla_optimizada"):
		return
	var skel: Skeleton3D = buscar_skeleton3d(modelo_raiz)
	if skel == null:
		return
	var mallas: Array[MeshInstance3D] = []
	var skins_unicos: Dictionary = {}
	var skin_compartido: Skin = null
	for hijo in skel.get_children():
		if hijo is MeshInstance3D:
			var mi: MeshInstance3D = hijo as MeshInstance3D
			if mi.mesh == null or not mi.visible:
				continue
			if mi.get_blend_shape_count() > 0 or not mi.transform.is_equal_approx(Transform3D.IDENTITY):
				return
			if mi.skin == null:
				return
			mallas.append(mi)
			skin_compartido = mi.skin
			skins_unicos[mi.skin.get_rid().get_id()] = true
	if mallas.size() <= 6 or skins_unicos.size() != 1 or skin_compartido == null:
		return

	var clave_cache: String = modelo_raiz.scene_file_path
	if clave_cache == "":
		clave_cache = "sk_%d_%d" % [mallas[0].mesh.get_rid().get_id(), mallas.size()]

	var malla_cache: ArrayMesh = _cache_mallas_fusionadas.get(clave_cache, null) as ArrayMesh
	if malla_cache == null:
		malla_cache = _construir_malla_fusionada(mallas)
		if malla_cache == null:
			return
		_cache_mallas_fusionadas[clave_cache] = malla_cache

	var mi_merged := MeshInstance3D.new()
	mi_merged.name = "MallaUnificada"
	mi_merged.mesh = malla_cache
	mi_merged.skin = skin_compartido
	mi_merged.skeleton = NodePath("..")
	mi_merged.cast_shadow = mallas[0].cast_shadow
	mi_merged.layers = mallas[0].layers
	skel.add_child(mi_merged)

	for mi in mallas:
		skel.remove_child(mi)
		mi.queue_free()

	modelo_raiz.set_meta(&"malla_optimizada", true)


static func _construir_malla_fusionada(mallas: Array[MeshInstance3D]) -> ArrayMesh:
	const ATTR_SLOTS: Array[int] = [
		Mesh.ARRAY_VERTEX,
		Mesh.ARRAY_NORMAL,
		Mesh.ARRAY_TANGENT,
		Mesh.ARRAY_COLOR,
		Mesh.ARRAY_TEX_UV,
		Mesh.ARRAY_TEX_UV2,
		Mesh.ARRAY_CUSTOM0,
		Mesh.ARRAY_CUSTOM1,
		Mesh.ARRAY_CUSTOM2,
		Mesh.ARRAY_CUSTOM3,
		Mesh.ARRAY_BONES,
		Mesh.ARRAY_WEIGHTS,
	]
	var buckets: Dictionary = {}
	var bucket_orden: Array[String] = []
	for mi in mallas:
		var m: Mesh = mi.mesh
		for s_idx in m.get_surface_count():
			if m.surface_get_primitive_type(s_idx) != Mesh.PRIMITIVE_TRIANGLES:
				return null
			var mat: Material = mi.get_active_material(s_idx)
			var fmt: int = m.surface_get_format(s_idx)
			var mat_id: int = mat.get_rid().get_id() if mat != null else 0
			var base_key: String = "%d_%d" % [mat_id, fmt]
			var arrs: Array = m.surface_get_arrays(s_idx)
			if arrs.size() < Mesh.ARRAY_MAX or arrs[Mesh.ARRAY_VERTEX] == null:
				return null
			var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
			var v_count: int = verts.size()
			var parte: int = 0
			var bucket_key: String = "%s_%d" % [base_key, parte]
			while buckets.has(bucket_key):
				var existing: Dictionary = buckets[bucket_key]
				if int(existing["v_offset"]) + v_count <= 65000:
					break
				parte += 1
				bucket_key = "%s_%d" % [base_key, parte]
			if not buckets.has(bucket_key):
				var init_arrs: Array = []
				init_arrs.resize(Mesh.ARRAY_MAX)
				buckets[bucket_key] = {
					"mat": mat,
					"fmt": fmt,
					"v_offset": 0,
					"arrs": init_arrs,
				}
				bucket_orden.append(bucket_key)
			var b: Dictionary = buckets[bucket_key]
			var out_arrs: Array = b["arrs"]
			var v_offset: int = int(b["v_offset"])
			for slot in ATTR_SLOTS:
				if arrs[slot] != null:
					if out_arrs[slot] == null:
						out_arrs[slot] = _duplicar_array_empaquetado(arrs[slot])
					else:
						out_arrs[slot] = _adjuntar_array_empaquetado(out_arrs[slot], arrs[slot])
			if arrs[Mesh.ARRAY_INDEX] != null:
				var src_idx: PackedInt32Array = arrs[Mesh.ARRAY_INDEX]
				var dst_idx: PackedInt32Array = PackedInt32Array()
				if out_arrs[Mesh.ARRAY_INDEX] != null:
					dst_idx = out_arrs[Mesh.ARRAY_INDEX] as PackedInt32Array
				var old_len: int = dst_idx.size()
				var add_len: int = src_idx.size()
				dst_idx.resize(old_len + add_len)
				for i in add_len:
					dst_idx[old_len + i] = src_idx[i] + v_offset
				out_arrs[Mesh.ARRAY_INDEX] = dst_idx
			b["v_offset"] = v_offset + v_count

	if bucket_orden.is_empty():
		return null

	var merged := ArrayMesh.new()
	var surf_out_idx: int = 0
	for k in bucket_orden:
		var b: Dictionary = buckets[k]
		var fmt: int = int(b["fmt"])
		var surf_flags: int = fmt & (
			Mesh.ARRAY_FLAG_USE_2D_VERTICES
			| Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE
			| Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		)
		var out_arrs: Array = b["arrs"]
		merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out_arrs, [], {}, surf_flags)
		var mat: Material = b["mat"] as Material
		if mat != null:
			merged.surface_set_material(surf_out_idx, mat)
		surf_out_idx += 1
	return merged


static func _duplicar_array_empaquetado(src: Variant) -> Variant:
	if src is PackedVector3Array:
		return (src as PackedVector3Array).duplicate()
	if src is PackedVector2Array:
		return (src as PackedVector2Array).duplicate()
	if src is PackedFloat32Array:
		return (src as PackedFloat32Array).duplicate()
	if src is PackedInt32Array:
		return (src as PackedInt32Array).duplicate()
	if src is PackedColorArray:
		return (src as PackedColorArray).duplicate()
	if src is PackedByteArray:
		return (src as PackedByteArray).duplicate()
	if src is PackedFloat64Array:
		return (src as PackedFloat64Array).duplicate()
	return src


static func _adjuntar_array_empaquetado(dst: Variant, src: Variant) -> Variant:
	if dst is PackedVector3Array:
		var a := dst as PackedVector3Array
		a.append_array(src as PackedVector3Array)
		return a
	if dst is PackedVector2Array:
		var a := dst as PackedVector2Array
		a.append_array(src as PackedVector2Array)
		return a
	if dst is PackedFloat32Array:
		var a := dst as PackedFloat32Array
		a.append_array(src as PackedFloat32Array)
		return a
	if dst is PackedInt32Array:
		var a := dst as PackedInt32Array
		a.append_array(src as PackedInt32Array)
		return a
	if dst is PackedColorArray:
		var a := dst as PackedColorArray
		a.append_array(src as PackedColorArray)
		return a
	if dst is PackedByteArray:
		var a := dst as PackedByteArray
		a.append_array(src as PackedByteArray)
		return a
	if dst is PackedFloat64Array:
		var a := dst as PackedFloat64Array
		a.append_array(src as PackedFloat64Array)
		return a
	return dst


static var _outline_enemigo: StandardMaterial3D = null
static var _outline_heroe: StandardMaterial3D = null

static func estilizar_entidad_visual(modelo_raiz: Node3D, es_jugador: bool) -> void:
	if modelo_raiz == null or modelo_raiz.has_meta(&"estilo_visual_aplicado"):
		return
	modelo_raiz.set_meta(&"estilo_visual_aplicado", true)

	if _outline_enemigo == null:
		_outline_enemigo = StandardMaterial3D.new()
		_outline_enemigo.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline_enemigo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_enemigo.albedo_color = Color(0.04, 0.05, 0.07, 1.0)
		_outline_enemigo.grow = true
		_outline_enemigo.grow_amount = 0.022

	if _outline_heroe == null:
		_outline_heroe = StandardMaterial3D.new()
		_outline_heroe.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline_heroe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_heroe.albedo_color = Color(0.08, 0.10, 0.14, 1.0)
		_outline_heroe.grow = true
		_outline_heroe.grow_amount = 0.020

	var outline_usar = _outline_heroe if es_jugador else _outline_enemigo
	_procesar_mallas_estilo_recursivo(modelo_raiz, es_jugador, outline_usar)

static func _procesar_mallas_estilo_recursivo(nodo: Node, es_jugador: bool, outline_mat: StandardMaterial3D) -> void:
	if nodo is MeshInstance3D:
		var mi: MeshInstance3D = nodo as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var mat_orig: Material = mi.get_active_material(s)
				if mat_orig is BaseMaterial3D:
					var mat_nuevo = _transformar_material_estilo(mat_orig, es_jugador, outline_mat, mi.name)
					mi.set_surface_override_material(s, mat_nuevo)
	for hijo in nodo.get_children():
		_procesar_mallas_estilo_recursivo(hijo, es_jugador, outline_mat)

static func _transformar_material_estilo(mat_in: BaseMaterial3D, es_jugador: bool, outline_mat: StandardMaterial3D, nombre_mesh: String = "") -> StandardMaterial3D:
	var mat_dup: StandardMaterial3D = mat_in.duplicate() as StandardMaterial3D
	if mat_dup == null:
		mat_dup = StandardMaterial3D.new()
		mat_dup.albedo_color = mat_in.albedo_color

	if es_jugador:
		mat_dup.rim_enabled = true
		mat_dup.rim = 0.55
		mat_dup.rim_tint = 0.4
		mat_dup.roughness = clampf(mat_dup.roughness, 0.35, 0.8)
		mat_dup.next_pass = outline_mat
		return mat_dup

	# =========================================================================
	# OVERHAUL VISUAL DE ENEMIGOS RADIOACTIVOS
	# Quitina bio-oscura amenazante + espinas/venas verde tóxico y cian hiper-brillantes
	# =========================================================================
	var mname := mat_in.resource_name
	var col := mat_dup.albedo_color

	# 1. Espinas, cuernos, conos o fragmentos cristalinos
	var es_espina := mname.contains("Thorn") or mname.contains("Glass") or nombre_mesh.begins_with("Cone")
	if es_espina:
		mat_dup.albedo_color = Color(0.10, 0.95, 0.30, 1.0)
		mat_dup.metallic = 0.15
		mat_dup.roughness = 0.20
		mat_dup.emission_enabled = true
		mat_dup.emission = Color(0.15, 1.0, 0.32, 1.0)
		mat_dup.emission_energy_multiplier = 3.6
		mat_dup.rim_enabled = true
		mat_dup.rim = 0.8
		mat_dup.rim_tint = 0.5
		mat_dup.next_pass = outline_mat
		return mat_dup

	# 2. Ojos, glándulas y núcleos vitales
	var es_ojos_o_nucleo := mname.contains("Eyes") or mname.contains("Glow") or (mat_dup.emission_enabled and mat_dup.emission_energy_multiplier > 1.5)
	if es_ojos_o_nucleo:
		mat_dup.albedo_color = Color(0.95, 1.0, 0.20, 1.0)
		mat_dup.metallic = 0.1
		mat_dup.roughness = 0.15
		mat_dup.emission_enabled = true
		mat_dup.emission = Color(0.95, 1.0, 0.20, 1.0)
		mat_dup.emission_energy_multiplier = 4.5
		mat_dup.next_pass = outline_mat
		return mat_dup

	# 3. Fauces / bocado tóxico
	if mname.contains("Mouth"):
		mat_dup.albedo_color = Color(0.95, 0.22, 0.05, 1.0)
		mat_dup.emission_enabled = true
		mat_dup.emission = Color(1.0, 0.28, 0.05, 1.0)
		mat_dup.emission_energy_multiplier = 3.8
		mat_dup.next_pass = outline_mat
		return mat_dup

	# 4. Slime de plasma o tejido mutagénico
	if mname.contains("PlasmaSlime"):
		mat_dup.albedo_color = Color(0.06, 0.14, 0.09, 1.0)
		mat_dup.metallic = 0.20
		mat_dup.roughness = 0.18
		mat_dup.emission_enabled = true
		mat_dup.emission = Color(0.12, 0.95, 0.35, 1.0)
		mat_dup.emission_energy_multiplier = 2.4
		mat_dup.rim_enabled = true
		mat_dup.rim = 0.7
		mat_dup.next_pass = outline_mat
		return mat_dup

	# 5. Cuerpo, caparazón, enredaderas y quitina oscura (Petals, Vines, PlasmaDark, etc.)
	# Reemplazar tonos pastel / deslavados por obsidiana bio-mecánica brillante
	mat_dup.albedo_color = Color(0.08, 0.09, 0.12, 1.0)
	mat_dup.metallic = 0.35
	mat_dup.roughness = 0.35
	mat_dup.rim_enabled = true
	mat_dup.rim = 0.65
	mat_dup.rim_tint = 0.4
	mat_dup.emission_enabled = false
	mat_dup.next_pass = outline_mat
	return mat_dup
