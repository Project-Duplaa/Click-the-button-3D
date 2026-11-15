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

	var attach_der := _obtener_o_crear_attachment(skel, "arm-right", "BoneAttach_ArmRight")
	var attach_izq := _obtener_o_crear_attachment(skel, "arm-left", "BoneAttach_ArmLeft")
	var resultado: Dictionary = {}

	# Coordenadas locales exactas de la palma en los rigs Kenney (sin escala)
	var offset_der := Vector3(-0.23, 0.0, 0.02)
	var offset_izq := Vector3(0.23, 0.0, 0.02)

	match nombre_clase:
		"Novato":
			var espada := _crear_espada_novato()
			espada.position = offset_der
			attach_der.add_child(espada)
			resultado["derecha"] = espada
		"Guerrero":
			var gran_espada := _crear_gran_espada_guerrero()
			gran_espada.position = offset_der
			attach_der.add_child(gran_espada)
			resultado["derecha"] = gran_espada

			var escudo := _crear_escudo_guerrero()
			escudo.position = offset_izq
			attach_izq.add_child(escudo)
			resultado["izquierda"] = escudo
		"Cazador":
			var arco := _crear_arco_cazador()
			arco.position = offset_izq
			# Rotar +90° Y alinea el arco vertical (+Y) hacia +X del hueso, apuntando al frente al tensar
			arco.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			attach_izq.add_child(arco)
			resultado["izquierda"] = arco
		"Mago":
			var baston_data := _crear_baston_mago(incluir_particulas)
			var baston := baston_data["nodo"] as Node3D
			baston.position = offset_der
			# Inclinación ligera para que el báculo vertical (+Y) luzca erguido en guardia
			baston.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(baston)
			resultado["derecha"] = baston
			if baston_data.has("luz"):
				resultado["luz_orbe"] = baston_data["luz"]
		"Paladín Solar":
			var gran_espada_solar := _crear_gran_espada_paladin()
			gran_espada_solar.position = offset_der
			attach_der.add_child(gran_espada_solar)
			resultado["derecha"] = gran_espada_solar

			var escudo_solar := _crear_escudo_paladin()
			escudo_solar.position = offset_izq
			attach_izq.add_child(escudo_solar)
			resultado["izquierda"] = escudo_solar
		"Berserker Sangriento":
			var hacha_der := _crear_hacha_berserker(incluir_particulas)
			hacha_der.position = offset_der
			attach_der.add_child(hacha_der)
			resultado["derecha"] = hacha_der

			var hacha_izq := _crear_hacha_berserker(incluir_particulas)
			hacha_izq.position = offset_izq
			hacha_izq.rotation_degrees = Vector3(0.0, 180.0, 0.0)
			attach_izq.add_child(hacha_izq)
			resultado["izquierda"] = hacha_izq
		"Francotirador Astral":
			var arco_astral := _crear_arco_astral(incluir_particulas)
			arco_astral.position = offset_izq
			arco_astral.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			attach_izq.add_child(arco_astral)
			resultado["izquierda"] = arco_astral
		"Maestro de Sombras":
			var daga_der := _crear_daga_sombra(incluir_particulas, false)
			daga_der.position = offset_der
			attach_der.add_child(daga_der)
			resultado["derecha"] = daga_der

			var daga_izq := _crear_daga_sombra(incluir_particulas, true)
			daga_izq.position = offset_izq
			attach_izq.add_child(daga_izq)
			resultado["izquierda"] = daga_izq
		"Archimago del Vacío":
			var baston_vacio := _crear_baston_vacio(incluir_particulas)
			var b_v := baston_vacio["nodo"] as Node3D
			b_v.position = offset_der
			b_v.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(b_v)
			resultado["derecha"] = b_v
			if baston_vacio.has("luz"):
				resultado["luz_orbe"] = baston_vacio["luz"]
		"Piromante Cataclísmico":
			var baston_piro := _crear_baston_piromante(incluir_particulas)
			var b_p := baston_piro["nodo"] as Node3D
			b_p.position = offset_der
			b_p.rotation_degrees = Vector3(12.0, 0.0, -28.0)
			attach_der.add_child(b_p)
			resultado["derecha"] = b_p
			if baston_piro.has("luz"):
				resultado["luz_orbe"] = baston_piro["luz"]
		"Avatar del Núcleo":
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


static func _crear_espada_novato() -> Node3D:
	var root := Node3D.new()
	root.name = "EspadaNovato"
	var mat_grip := _mat_simple(Color(0.35, 0.22, 0.14), 0.0, 0.6)
	var mat_bronce := _mat_simple(Color(0.78, 0.62, 0.28), 0.85, 0.3)
	var mat_acero := _mat_simple(Color(0.86, 0.89, 0.95), 0.9, 0.25)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.022, 0.022, 0.09)
	grip.mesh = box_grip
	grip.position = Vector3(0, 0, -0.04)
	grip.material_override = mat_grip
	root.add_child(grip)

	var guard := MeshInstance3D.new()
	var box_guard := BoxMesh.new()
	box_guard.size = Vector3(0.09, 0.024, 0.020)
	guard.mesh = box_guard
	guard.position = Vector3(0, 0, 0.01)
	guard.material_override = mat_bronce
	root.add_child(guard)

	var hoja := MeshInstance3D.new()
	var box_hoja := BoxMesh.new()
	box_hoja.size = Vector3(0.038, 0.012, 0.36)
	hoja.mesh = box_hoja
	hoja.position = Vector3(0, 0, 0.20)
	hoja.material_override = mat_acero
	root.add_child(hoja)
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


static func _crear_arco_cazador() -> Node3D:
	var root := Node3D.new()
	root.name = "ArcoCazador"
	var mat_grip := _mat_simple(Color(0.30, 0.18, 0.10), 0.0, 0.55)
	var mat_madera := _mat_simple(Color(0.56, 0.33, 0.18), 0.05, 0.42)
	var mat_oro := _mat_simple(Color(0.88, 0.72, 0.28), 0.85, 0.25)
	var mat_cuerda := _mat_simple(Color(0.96, 0.96, 0.98), 0.0, 0.3, Color(0.75, 0.95, 0.85), 0.8)

	var grip := MeshInstance3D.new()
	var box_grip := BoxMesh.new()
	box_grip.size = Vector3(0.026, 0.075, 0.034)
	grip.mesh = box_grip
	grip.material_override = mat_grip
	root.add_child(grip)

	var box_pala := BoxMesh.new()
	box_pala.size = Vector3(0.022, 0.22, 0.026)

	var pala_up := MeshInstance3D.new()
	pala_up.mesh = box_pala
	pala_up.position = Vector3(0, 0.13, -0.028)
	pala_up.rotation_degrees = Vector3(18.0, 0.0, 0.0)
	pala_up.material_override = mat_madera
	root.add_child(pala_up)

	var pala_down := MeshInstance3D.new()
	pala_down.mesh = box_pala
	pala_down.position = Vector3(0, -0.13, -0.028)
	pala_down.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	pala_down.material_override = mat_madera
	root.add_child(pala_down)

	for sy in [-1.0, 1.0]:
		var punta := MeshInstance3D.new()
		var box_punta := BoxMesh.new()
		box_punta.size = Vector3(0.026, 0.035, 0.026)
		punta.mesh = box_punta
		punta.position = Vector3(0, sy * 0.23, -0.062)
		punta.material_override = mat_oro
		root.add_child(punta)

	var cuerda := MeshInstance3D.new()
	var box_cuerda := BoxMesh.new()
	box_cuerda.size = Vector3(0.005, 0.46, 0.005)
	cuerda.mesh = box_cuerda
	cuerda.position = Vector3(0, 0, -0.062)
	cuerda.material_override = mat_cuerda
	root.add_child(cuerda)
	return root


static func _crear_baston_mago(incluir_particulas: bool = true) -> Dictionary:
	var root := Node3D.new()
	root.name = "BastonMago"
	var mat_asta := _mat_simple(Color(0.32, 0.20, 0.13), 0.05, 0.5)
	var mat_bronce := _mat_simple(Color(0.85, 0.72, 0.32), 0.88, 0.25)
	var mat_orbe := _mat_simple(Color(0.2, 0.85, 1.0), 0.1, 0.15, Color(0.15, 0.9, 1.0), 3.4)

	var asta := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.013
	cyl.bottom_radius = 0.011
	cyl.height = 0.76
	asta.mesh = cyl
	asta.position = Vector3(0, 0.06, 0)
	asta.material_override = mat_asta
	root.add_child(asta)

	var corona := MeshInstance3D.new()
	var box_cor := BoxMesh.new()
	box_cor.size = Vector3(0.052, 0.032, 0.052)
	corona.mesh = box_cor
	corona.position = Vector3(0, 0.43, 0)
	corona.material_override = mat_bronce
	root.add_child(corona)

	var orbe := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.044
	sph.height = 0.088
	orbe.mesh = sph
	orbe.position = Vector3(0, 0.49, 0)
	orbe.material_override = mat_orbe
	root.add_child(orbe)

	var luz := OmniLight3D.new()
	luz.name = "LuzOrbe"
	luz.position = Vector3(0, 0.49, 0)
	luz.light_color = Color(0.25, 0.88, 1.0)
	luz.light_energy = 1.6
	luz.omni_range = 1.8
	root.add_child(luz)

	if incluir_particulas:
		var part := CPUParticles3D.new()
		part.emitting = true
		part.amount = 10
		part.lifetime = 0.65
		part.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		part.emission_sphere_radius = 0.05
		part.gravity = Vector3(0, 0.28, 0)
		part.scale_amount_min = 0.015
		part.scale_amount_max = 0.035
		part.color = Color(0.3, 0.9, 1.0, 0.9)
		part.position = Vector3(0, 0.49, 0)
		root.add_child(part)

	return {"nodo": root, "luz": luz}


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
