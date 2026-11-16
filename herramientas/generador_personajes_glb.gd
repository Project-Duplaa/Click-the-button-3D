extends SceneTree

## ==============================================================================
## GENERADOR MAESTRO DE MODELOS 3D VOLUMÉTRICOS OFICIALES PARA GODOT 4
## Implementación fiel desde cero con anatomía estilizada, vestimenta, accesorios y armas:
## 1. Novato:    res://personaje/player_rookie.glb
## 2. Guerrero:  res://personaje/player_warrior.glb
## 3. Arquero:   res://personaje/player_archer.glb
## 4. Mago:      res://personaje/player_mage.glb
## ==============================================================================

func _init():
	print("==================================================================")
	print("GENERANDO MODELOS 3D OFICIALES CON ANATOMÍA ESTILIZADA COMPLETA")
	print("==================================================================")

	var base_male_a := "res://personaje/character-male-a.glb"
	var base_male_d := "res://personaje/character-male-d.glb"

	if not FileAccess.file_exists(base_male_a) or not FileAccess.file_exists(base_male_d):
		printerr("ERROR: No se encontraron los rigs base Kenney en res://personaje/")
		quit(1)
		return

	_generar_novato(base_male_a, "res://personaje/player_rookie.glb")
	_generar_guerrero(base_male_d, "res://personaje/player_warrior.glb")
	_generar_arquero(base_male_a, "res://personaje/player_archer.glb")
	_generar_mago(base_male_a, "res://personaje/player_mage.glb")

	print("==================================================================")
	print("¡LOS 4 MODELOS 3D VOLUMÉTRICOS HAN SIDO GENERADOS CON ÉXITO!")
	print("==================================================================")
	quit(0)


# ==============================================================================
# HELPERS DE MATERIALES Y PRIMITIVAS 3D SUAVES
# ==============================================================================

static func _mat(albedo: Color, metallic: float = 0.0, roughness: float = 0.55, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	return m

static func _box(size: Vector3, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi

static func _cyl(r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, segs: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi

static func _sphere(r: float, mat: Material, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, segs: int = 18, rings: int = 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	return mi

static func _capsule(r: float, h: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, segs: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = segs
	c.rings = 6
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi

static func _torus(r_ext: float, r_int: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.outer_radius = r_ext
	t.inner_radius = r_int
	t.rings = 18
	t.ring_segments = 10
	mi.mesh = t
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi

static func _crear_bone_attachment(skel: Skeleton3D, bone_name: String) -> BoneAttachment3D:
	var att := BoneAttachment3D.new()
	att.name = "att_" + bone_name
	att.bone_name = bone_name
	var idx := skel.find_bone(bone_name)
	if idx != -1:
		att.bone_idx = idx
	skel.add_child(att)
	return att

static func _preparar_esqueleto(escena: Node) -> Dictionary:
	var skel: Skeleton3D = escena.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		return {}
	var to_remove = []
	for c in skel.get_children():
		if c is MeshInstance3D or c is BoneAttachment3D:
			to_remove.append(c)
	for c in to_remove:
		skel.remove_child(c)
		c.free()

	return {
		"skel": skel,
		"root": _crear_bone_attachment(skel, "root"),
		"torso": _crear_bone_attachment(skel, "torso"),
		"head": _crear_bone_attachment(skel, "head"),
		"arm_l": _crear_bone_attachment(skel, "arm-left"),
		"arm_r": _crear_bone_attachment(skel, "arm-right"),
		"leg_l": _crear_bone_attachment(skel, "leg-left"),
		"leg_r": _crear_bone_attachment(skel, "leg-right"),
	}

static func _exportar_glb(escena: Node, ruta_salida: String) -> void:
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var err := gltf_doc.append_from_scene(escena, gltf_state)
	if err != OK:
		printerr("Error serializando GLB %s: %d" % [ruta_salida, err])
		return
	err = gltf_doc.write_to_filesystem(gltf_state, ruta_salida)
	if err != OK:
		printerr("Error escribiendo archivo GLB %s: %d" % [ruta_salida, err])
	else:
		var size = FileAccess.get_file_as_bytes(ruta_salida).size()
		print("  -> Exportado con éxito: %s (%d bytes)" % [ruta_salida, size])


# ==============================================================================
# 1. MODELADO 3D: NOVATO (player_rookie.glb)
# ==============================================================================
func _generar_novato(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Modelando 3D: NOVATO...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena)
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]

	var mat_piel := _mat(Color(0.92, 0.74, 0.62), 0.0, 0.55)
	var mat_pelo := _mat(Color(0.85, 0.68, 0.42), 0.05, 0.6)
	var mat_gorra := _mat(Color(0.20, 0.32, 0.48), 0.1, 0.5)
	var mat_gorra_visera := _mat(Color(0.16, 0.25, 0.40), 0.1, 0.45)
	var mat_ojos := _mat(Color(0.12, 0.12, 0.14), 0.1, 0.2)
	var mat_pupila_azul := _mat(Color(0.2, 0.6, 0.9), 0.0, 0.3)
	var mat_esclera := _mat(Color(0.96, 0.96, 0.98), 0.0, 0.3)

	var mat_sudadera := _mat(Color(0.20, 0.26, 0.36), 0.05, 0.65)
	var mat_naranja_forro := _mat(Color(0.90, 0.45, 0.12), 0.05, 0.55)
	var mat_chaleco := _mat(Color(0.84, 0.92, 0.10), 0.05, 0.45)
	var mat_reflectante := _mat(Color(0.94, 0.96, 0.98), 0.4, 0.2, Color(0.85, 0.95, 1.0), 0.35)
	var mat_cremallera := _mat(Color(0.18, 0.20, 0.24), 0.6, 0.4)
	var mat_cinturon := _mat(Color(0.28, 0.18, 0.11), 0.1, 0.6)
	var mat_hebilla := _mat(Color(0.82, 0.84, 0.88), 0.85, 0.25)

	var mat_mochila := _mat(Color(0.58, 0.48, 0.34), 0.05, 0.7)
	var mat_mochila_bolsillo := _mat(Color(0.46, 0.37, 0.26), 0.05, 0.75)
	var mat_esterilla := _mat(Color(0.38, 0.44, 0.32), 0.05, 0.8)
	var mat_linterna_vidrio := _mat(Color(1.0, 0.75, 0.18), 0.1, 0.1, Color(1.0, 0.68, 0.15), 2.0)
	var mat_walkie := _mat(Color(0.15, 0.16, 0.18), 0.2, 0.5)

	var mat_pantalon := _mat(Color(0.35, 0.38, 0.36), 0.05, 0.75)
	var mat_rodillera := _mat(Color(0.20, 0.22, 0.25), 0.3, 0.5)
	var mat_bota := _mat(Color(0.32, 0.24, 0.18), 0.1, 0.65)
	var mat_suela := _mat(Color(0.12, 0.12, 0.14), 0.05, 0.85)

	var mat_taser_metal := _mat(Color(0.72, 0.75, 0.80), 0.85, 0.25)
	var mat_taser_empunadura := _mat(Color(0.14, 0.15, 0.18), 0.1, 0.6)
	var mat_taser_cobre := _mat(Color(0.85, 0.46, 0.18), 0.8, 0.3)
	var mat_taser_core := _mat(Color(0.20, 1.0, 0.75), 0.1, 0.1, Color(0.18, 1.0, 0.8), 2.5)

	# --- CABEZA (Anclada a Bone 'head') ---
	var cabeza_node := Node3D.new()
	cabeza_node.name = "NovatoCabeza"
	# Cuello
	cabeza_node.add_child(_cyl(0.028, 0.034, 0.045, mat_piel, Vector3(0.0, 0.015, 0.0)))
	# Cráneo
	cabeza_node.add_child(_sphere(0.058, mat_piel, Vector3(0.0, 0.065, 0.008), Vector3(1.0, 1.12, 1.05)))
	# Mandíbula / Mentón
	cabeza_node.add_child(_sphere(0.035, mat_piel, Vector3(0.0, 0.032, 0.035), Vector3(0.85, 0.75, 0.8)))

	# Ojos estilo cómic/anime
	for sx in [-0.020, 0.020]:
		cabeza_node.add_child(_sphere(0.013, mat_esclera, Vector3(sx, 0.068, 0.056), Vector3(1.0, 0.9, 0.4)))
		cabeza_node.add_child(_sphere(0.007, mat_pupila_azul, Vector3(sx, 0.068, 0.062), Vector3(0.8, 0.8, 0.3)))
		cabeza_node.add_child(_sphere(0.004, mat_ojos, Vector3(sx, 0.068, 0.064), Vector3(0.8, 0.8, 0.3)))
		cabeza_node.add_child(_box(Vector3(0.018, 0.004, 0.008), mat_pelo, Vector3(sx, 0.082, 0.054), Vector3(0, 0, -sx * 140.0)))
	# Nariz
	cabeza_node.add_child(_sphere(0.006, mat_piel, Vector3(0.0, 0.054, 0.065), Vector3(0.8, 1.1, 1.1)))
	# Boca
	cabeza_node.add_child(_box(Vector3(0.018, 0.004, 0.008), mat_ojos, Vector3(0.0, 0.038, 0.058)))

	# Mechones de pelo rubio
	for dx in [-0.040, -0.020, 0.0, 0.020, 0.040]:
		cabeza_node.add_child(_capsule(0.014, 0.050, mat_pelo, Vector3(dx, 0.096, 0.038), Vector3(25.0, 0.0, -dx * 250.0)))
	cabeza_node.add_child(_capsule(0.013, 0.045, mat_pelo, Vector3(-0.055, 0.055, 0.015), Vector3(0, 0, -20)))
	cabeza_node.add_child(_capsule(0.013, 0.045, mat_pelo, Vector3(0.055, 0.055, 0.015), Vector3(0, 0, 20)))

	# Gorra de béisbol hacia atrás
	cabeza_node.add_child(_sphere(0.064, mat_gorra, Vector3(0.0, 0.086, -0.005), Vector3(1.05, 0.72, 1.1)))
	# Visera curvada hacia atrás (-Z)
	cabeza_node.add_child(_box(Vector3(0.090, 0.008, 0.055), mat_gorra_visera, Vector3(0.0, 0.068, -0.072), Vector3(-18.0, 0.0, 0.0)))
	cabeza_node.add_child(_box(Vector3(0.050, 0.009, 0.012), mat_gorra_visera, Vector3(0.0, 0.096, 0.046)))

	att_head.add_child(cabeza_node)

	# --- TORSO & CHALECO (Anclado a Bone 'torso') ---
	var torso_node := Node3D.new()
	torso_node.name = "NovatoTorso"

	# Capucha naranja doblada tras la nuca
	torso_node.add_child(_torus(0.052, 0.020, mat_naranja_forro, Vector3(0.0, 0.145, -0.01), Vector3(80, 0, 0)))

	# Sudadera base azul marino
	torso_node.add_child(_capsule(0.068, 0.13, mat_sudadera, Vector3(0.0, 0.075, 0.018)))

	# Chaleco reflectante amarillo neón envolvente
	torso_node.add_child(_capsule(0.076, 0.115, mat_chaleco, Vector3(0.0, 0.075, 0.020)))

	# Bandas reflectantes horizontales
	torso_node.add_child(_cyl(0.078, 0.078, 0.018, mat_reflectante, Vector3(0.0, 0.095, 0.020)))
	torso_node.add_child(_cyl(0.078, 0.078, 0.018, mat_reflectante, Vector3(0.0, 0.040, 0.020)))

	# Bandas reflectantes verticales
	for sx in [-0.038, 0.038]:
		torso_node.add_child(_box(Vector3(0.016, 0.11, 0.095), mat_reflectante, Vector3(sx, 0.09, 0.020)))

	# Cremallera y clip
	torso_node.add_child(_box(Vector3(0.008, 0.12, 0.012), mat_cremallera, Vector3(0.0, 0.075, 0.094)))
	torso_node.add_child(_box(Vector3(0.020, 0.014, 0.016), mat_cremallera, Vector3(0.0, 0.100, 0.096)))

	# Bolsillos
	for sx in [-0.038, 0.038]:
		torso_node.add_child(_box(Vector3(0.032, 0.035, 0.018), mat_chaleco, Vector3(sx, 0.032, 0.092)))
		torso_node.add_child(_box(Vector3(0.033, 0.008, 0.020), mat_reflectante, Vector3(sx, 0.046, 0.093)))

	# Cinturón con hebilla
	torso_node.add_child(_cyl(0.074, 0.074, 0.022, mat_cinturon, Vector3(0.0, 0.005, 0.018)))
	torso_node.add_child(_box(Vector3(0.026, 0.022, 0.014), mat_hebilla, Vector3(0.0, 0.005, 0.094)))

	# Pistolera en cadera derecha
	torso_node.add_child(_box(Vector3(0.026, 0.070, 0.032), mat_cinturon, Vector3(-0.085, -0.010, 0.028), Vector3(0, 0, -10)))
	torso_node.add_child(_box(Vector3(0.014, 0.028, 0.036), mat_ojos, Vector3(-0.087, 0.020, 0.038), Vector3(15, 0, -10)))

	# Mochila de supervivencia dorsal
	var mochila_node := Node3D.new()
	mochila_node.position = Vector3(0.0, 0.075, -0.072)
	mochila_node.add_child(_box(Vector3(0.12, 0.14, 0.075), mat_mochila))
	mochila_node.add_child(_box(Vector3(0.125, 0.035, 0.080), mat_mochila_bolsillo, Vector3(0.0, 0.070, 0.0)))
	mochila_node.add_child(_box(Vector3(0.090, 0.070, 0.038), mat_mochila_bolsillo, Vector3(0.0, -0.025, -0.052)))
	for sx in [-0.032, 0.032]:
		mochila_node.add_child(_box(Vector3(0.010, 0.13, 0.008), mat_cinturon, Vector3(sx, 0.0, -0.056)))
		mochila_node.add_child(_box(Vector3(0.013, 0.009, 0.010), mat_hebilla, Vector3(sx, 0.02, -0.060)))
	mochila_node.add_child(_cyl(0.022, 0.022, 0.14, mat_esterilla, Vector3(0.0, 0.105, 0.0), Vector3(0, 0, 90)))
	mochila_node.add_child(_cyl(0.015, 0.015, 0.080, mat_linterna_vidrio, Vector3(-0.075, -0.015, 0.0)))
	var luz_lint := OmniLight3D.new()
	luz_lint.light_color = Color(1.0, 0.70, 0.18)
	luz_lint.light_energy = 1.0
	luz_lint.omni_range = 1.8
	luz_lint.position = Vector3(-0.085, -0.015, -0.02)
	mochila_node.add_child(luz_lint)
	mochila_node.add_child(_box(Vector3(0.020, 0.055, 0.028), mat_walkie, Vector3(0.075, 0.015, 0.0)))
	mochila_node.add_child(_cyl(0.002, 0.003, 0.075, mat_taser_metal, Vector3(0.075, 0.070, 0.0)))

	torso_node.add_child(mochila_node)
	att_torso.add_child(torso_node)

	# --- BRAZOS Y MANOS ---
	for lado in ["L", "R"]:
		var att = att_arm_l if lado == "L" else att_arm_r
		var brazo_node := Node3D.new()
		brazo_node.name = "NovatoBrazo_" + lado

		brazo_node.add_child(_sphere(0.030, mat_sudadera, Vector3(0.0, 0.0, 0.0)))
		brazo_node.add_child(_capsule(0.026, 0.08, mat_sudadera, Vector3(0.0, -0.045, 0.0)))
		brazo_node.add_child(_cyl(0.027, 0.027, 0.014, mat_naranja_forro, Vector3(0.0, -0.085, 0.0)))
		brazo_node.add_child(_capsule(0.022, 0.07, mat_piel, Vector3(0.0, -0.12, 0.0)))
		brazo_node.add_child(_sphere(0.022, mat_cinturon, Vector3(0.0, -0.155, 0.0)))

		att.add_child(brazo_node)

	# --- ARMA: BASTÓN TASER (Mano derecha) ---
	var taser_node := Node3D.new()
	taser_node.name = "BastonTaser"
	taser_node.position = Vector3(0.0, -0.16, 0.03)
	taser_node.rotation_degrees = Vector3(30.0, 0.0, -10.0)

	taser_node.add_child(_cyl(0.010, 0.011, 0.10, mat_taser_empunadura, Vector3(0, 0, -0.04), Vector3(90, 0, 0)))
	taser_node.add_child(_cyl(0.014, 0.013, 0.02, mat_taser_metal, Vector3(0, 0, -0.095), Vector3(90, 0, 0)))
	taser_node.add_child(_cyl(0.013, 0.013, 0.09, mat_taser_core, Vector3(0, 0, 0.045), Vector3(90, 0, 0)))
	for sy in [-0.013, 0.013]:
		taser_node.add_child(_cyl(0.003, 0.003, 0.09, mat_taser_cobre, Vector3(0, sy, 0.045), Vector3(90, 0, 0)))
	taser_node.add_child(_cyl(0.014, 0.012, 0.045, mat_taser_metal, Vector3(0, 0, 0.11), Vector3(90, 0, 0)))
	for sy in [-0.007, 0.007]:
		taser_node.add_child(_cyl(0.002, 0.002, 0.025, mat_taser_metal, Vector3(0, sy, 0.14), Vector3(90, 0, 0)))

	var taser_light := OmniLight3D.new()
	taser_light.name = "LuzTaser"
	taser_light.light_color = Color(0.20, 0.95, 1.0)
	taser_light.light_energy = 2.0
	taser_light.omni_range = 2.2
	taser_light.position = Vector3(0, 0, 0.14)
	taser_node.add_child(taser_light)

	att_arm_r.add_child(taser_node)

	# --- PIERNAS Y BOTAS ---
	for lado in ["L", "R"]:
		var att = att_leg_l if lado == "L" else att_leg_r
		var pierna_node := Node3D.new()
		pierna_node.name = "NovatoPierna_" + lado

		pierna_node.add_child(_capsule(0.033, 0.09, mat_pantalon, Vector3(0.0, -0.045, 0.0)))
		var px = 0.033 if lado == "L" else -0.033
		pierna_node.add_child(_box(Vector3(0.016, 0.042, 0.038), mat_pantalon, Vector3(px, -0.045, 0.0)))

		# Rodillera
		pierna_node.add_child(_box(Vector3(0.045, 0.040, 0.020), mat_rodillera, Vector3(0.0, -0.085, 0.026)))
		pierna_node.add_child(_sphere(0.005, mat_taser_metal, Vector3(-0.015, -0.085, 0.036)))
		pierna_node.add_child(_sphere(0.005, mat_taser_metal, Vector3(0.015, -0.085, 0.036)))

		pierna_node.add_child(_capsule(0.028, 0.08, mat_pantalon, Vector3(0.0, -0.125, 0.0)))

		# Bota
		pierna_node.add_child(_box(Vector3(0.045, 0.045, 0.090), mat_bota, Vector3(0.0, -0.155, 0.015)))
		pierna_node.add_child(_sphere(0.024, mat_suela, Vector3(0.0, -0.160, 0.050), Vector3(0.9, 0.6, 1.0)))
		pierna_node.add_child(_box(Vector3(0.048, 0.014, 0.100), mat_suela, Vector3(0.0, -0.170, 0.015)))

		att.add_child(pierna_node)

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 2. MODELADO 3D: GUERRERO / TANQUE (player_warrior.glb)
# ==============================================================================
func _generar_guerrero(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Modelando 3D: GUERRERO...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena)
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]

	var mat_armadura_acero := _mat(Color(0.28, 0.31, 0.35), 0.75, 0.35)
	var mat_armadura_oscura := _mat(Color(0.18, 0.20, 0.24), 0.5, 0.45)
	var mat_remaches := _mat(Color(0.65, 0.68, 0.74), 0.9, 0.2)
	var mat_visor_cian := _mat(Color(0.15, 0.95, 1.0), 0.1, 0.1, Color(0.15, 0.95, 1.0), 3.0)
	var mat_respirador_naranja := _mat(Color(0.90, 0.45, 0.12), 0.2, 0.45)
	var mat_filtro_rejilla := _mat(Color(0.15, 0.15, 0.17), 0.8, 0.3)

	var mat_traje_tactico := _mat(Color(0.16, 0.18, 0.22), 0.05, 0.7)
	var mat_cinturon_naranja := _mat(Color(0.85, 0.42, 0.12), 0.15, 0.5)
	var mat_hebilla_acero := _mat(Color(0.70, 0.72, 0.78), 0.85, 0.25)
	var mat_hazard_amarillo := _mat(Color(0.95, 0.82, 0.08), 0.1, 0.4)
	var mat_hazard_negro := _mat(Color(0.12, 0.12, 0.14), 0.2, 0.5)

	# --- CABEZA: CASCO BALÍSTICO PESADO ---
	var cabeza_node := Node3D.new()
	cabeza_node.name = "GuerreroCabeza"

	cabeza_node.add_child(_sphere(0.066, mat_armadura_acero, Vector3(0.0, 0.068, 0.005), Vector3(1.05, 1.1, 1.15)))
	cabeza_node.add_child(_box(Vector3(0.11, 0.030, 0.035), mat_armadura_oscura, Vector3(0.0, 0.105, 0.040), Vector3(-15, 0, 0)))

	# Gran Visor Curvo Cian
	cabeza_node.add_child(_sphere(0.045, mat_visor_cian, Vector3(0.0, 0.070, 0.052), Vector3(1.35, 0.55, 0.75)))

	# Máscara y respiradores
	cabeza_node.add_child(_box(Vector3(0.065, 0.045, 0.045), mat_armadura_oscura, Vector3(0.0, 0.030, 0.045)))
	for sx in [-0.038, 0.038]:
		cabeza_node.add_child(_cyl(0.016, 0.016, 0.040, mat_respirador_naranja, Vector3(sx, 0.030, 0.065), Vector3(70, -sx * 200, 0)))
		cabeza_node.add_child(_cyl(0.015, 0.015, 0.010, mat_filtro_rejilla, Vector3(sx, 0.034, 0.082), Vector3(70, -sx * 200, 0)))

	att_head.add_child(cabeza_node)

	# --- TORSO: CORAZA PESADA Y HOMBRERAS ---
	var torso_node := Node3D.new()
	torso_node.name = "GuerreroTorso"

	torso_node.add_child(_cyl(0.045, 0.050, 0.040, mat_armadura_oscura, Vector3(0.0, 0.145, 0.0)))
	torso_node.add_child(_capsule(0.095, 0.14, mat_armadura_acero, Vector3(0.0, 0.075, 0.015)))

	# Placas pectorales
	for sx in [-0.045, 0.045]:
		torso_node.add_child(_box(Vector3(0.068, 0.055, 0.032), mat_armadura_acero, Vector3(sx, 0.095, 0.090), Vector3(0, sx * 100, 0)))

	# Placas abdominales (6-pack)
	for row in range(3):
		var py = 0.055 - float(row) * 0.024
		for col in [-0.028, 0.028]:
			torso_node.add_child(_box(Vector3(0.026, 0.020, 0.022), mat_armadura_oscura, Vector3(col, py, 0.098)))

	# Hombreras dobles curvadas (pauldrons)
	for sx in [-0.11, 0.11]:
		torso_node.add_child(_sphere(0.055, mat_armadura_acero, Vector3(sx, 0.12, 0.0), Vector3(1.2, 0.9, 1.2)))
		torso_node.add_child(_sphere(0.058, mat_armadura_oscura, Vector3(sx, 0.115, 0.0), Vector3(1.22, 0.4, 1.22)))

	# Cinturón naranja con bolsillos
	torso_node.add_child(_cyl(0.090, 0.090, 0.026, mat_cinturon_naranja, Vector3(0.0, 0.005, 0.015)))
	torso_node.add_child(_box(Vector3(0.035, 0.028, 0.020), mat_hebilla_acero, Vector3(0.0, 0.005, 0.105)))
	for sx in [-0.065, -0.035, 0.035, 0.065]:
		torso_node.add_child(_box(Vector3(0.022, 0.032, 0.022), mat_cinturon_naranja, Vector3(sx, 0.005, 0.100)))

	# Espada diagonal en espalda
	var espada_node := Node3D.new()
	espada_node.position = Vector3(-0.025, 0.08, -0.095)
	espada_node.rotation_degrees = Vector3(15, 0, 35)
	espada_node.add_child(_cyl(0.010, 0.010, 0.12, mat_cinturon_naranja, Vector3(0, 0.15, 0)))
	espada_node.add_child(_sphere(0.016, mat_armadura_acero, Vector3(0, 0.21, 0)))
	espada_node.add_child(_box(Vector3(0.090, 0.016, 0.025), mat_armadura_acero, Vector3(0, 0.09, 0)))
	espada_node.add_child(_box(Vector3(0.045, 0.32, 0.020), mat_armadura_oscura, Vector3(0, -0.08, 0)))
	torso_node.add_child(espada_node)

	att_torso.add_child(torso_node)

	# --- BRAZOS Y GUANTELETES PESADOS ---
	for lado in ["L", "R"]:
		var att = att_arm_l if lado == "L" else att_arm_r
		var brazo_node := Node3D.new()
		brazo_node.name = "GuerreroBrazo_" + lado

		brazo_node.add_child(_capsule(0.034, 0.09, mat_traje_tactico, Vector3(0.0, -0.045, 0.0)))
		brazo_node.add_child(_cyl(0.033, 0.028, 0.08, mat_armadura_acero, Vector3(0.0, -0.115, 0.0)))
		brazo_node.add_child(_sphere(0.022, mat_armadura_oscura, Vector3(0.0, -0.08, -0.028)))
		brazo_node.add_child(_sphere(0.028, mat_armadura_oscura, Vector3(0.0, -0.160, 0.0)))

		att.add_child(brazo_node)

	# --- ESCUDO BALÍSTICO DE BRECHA (Mano izquierda) ---
	var escudo_node := Node3D.new()
	escudo_node.name = "EscudoBalistico"
	escudo_node.position = Vector3(0.10, -0.10, 0.04)
	escudo_node.rotation_degrees = Vector3(0, 15, 0)

	escudo_node.add_child(_box(Vector3(0.18, 0.40, 0.025), mat_armadura_acero))
	escudo_node.add_child(_box(Vector3(0.19, 0.41, 0.015), mat_armadura_oscura, Vector3(0, 0, -0.008)))
	escudo_node.add_child(_box(Vector3(0.10, 0.035, 0.035), mat_armadura_oscura, Vector3(0.0, 0.12, 0.0)))
	escudo_node.add_child(_box(Vector3(0.09, 0.022, 0.038), mat_visor_cian, Vector3(0.0, 0.12, 0.0)))

	# Chevrones Hazard
	escudo_node.add_child(_box(Vector3(0.19, 0.09, 0.030), mat_hazard_amarillo, Vector3(0.0, 0.0, 0.0)))
	for sx in [-0.07, -0.035, 0.0, 0.035, 0.07]:
		escudo_node.add_child(_box(Vector3(0.018, 0.092, 0.034), mat_hazard_negro, Vector3(sx, 0.0, 0.0), Vector3(0, 0, 45)))

	escudo_node.add_child(_cyl(0.040, 0.040, 0.038, mat_armadura_oscura, Vector3(0.0, 0.0, 0.015), Vector3(90, 0, 0)))
	escudo_node.add_child(_cyl(0.028, 0.028, 0.045, mat_visor_cian, Vector3(0.0, 0.0, 0.020), Vector3(90, 0, 0)))

	var escudo_light := OmniLight3D.new()
	escudo_light.name = "LuzEscudo"
	escudo_light.light_color = Color(0.15, 0.95, 1.0)
	escudo_light.light_energy = 2.0
	escudo_light.omni_range = 2.2
	escudo_light.position = Vector3(0.0, 0.0, 0.06)
	escudo_node.add_child(escudo_light)

	att_arm_l.add_child(escudo_node)

	# --- ARMA: MARTILLO CINÉTICO (Mano derecha) ---
	var martillo_node := Node3D.new()
	martillo_node.name = "MartilloCinetico"
	martillo_node.position = Vector3(-0.03, -0.16, 0.03)
	martillo_node.rotation_degrees = Vector3(25, 0, -15)

	martillo_node.add_child(_cyl(0.014, 0.015, 0.44, mat_armadura_oscura, Vector3(0, 0.06, 0)))
	martillo_node.add_child(_cyl(0.016, 0.016, 0.14, mat_cinturon_naranja, Vector3(0, -0.03, 0)))
	martillo_node.add_child(_sphere(0.020, mat_armadura_acero, Vector3(0, -0.15, 0)))

	martillo_node.add_child(_box(Vector3(0.10, 0.10, 0.16), mat_armadura_acero, Vector3(0, 0.26, 0)))
	for sx in [-0.052, 0.052]:
		martillo_node.add_child(_cyl(0.032, 0.032, 0.010, mat_armadura_oscura, Vector3(sx, 0.26, 0), Vector3(0, 0, 90)))
	martillo_node.add_child(_box(Vector3(0.088, 0.088, 0.020), mat_visor_cian, Vector3(0, 0.26, 0.085)))

	var martillo_light := OmniLight3D.new()
	martillo_light.name = "LuzMartillo"
	martillo_light.light_color = Color(0.18, 0.95, 1.0)
	martillo_light.light_energy = 2.4
	martillo_light.omni_range = 2.4
	martillo_light.position = Vector3(0, 0.26, 0.10)
	martillo_node.add_child(martillo_light)

	att_arm_r.add_child(martillo_node)

	# --- PIERNAS Y GREBAS ---
	for lado in ["L", "R"]:
		var att = att_leg_l if lado == "L" else att_leg_r
		var pierna_node := Node3D.new()
		pierna_node.name = "GuerreroPierna_" + lado

		pierna_node.add_child(_capsule(0.040, 0.10, mat_traje_tactico, Vector3(0.0, -0.045, 0.0)))
		pierna_node.add_child(_cyl(0.042, 0.042, 0.018, mat_cinturon_naranja, Vector3(0.0, -0.045, 0.0)))

		# Rodillera
		pierna_node.add_child(_box(Vector3(0.055, 0.050, 0.028), mat_armadura_acero, Vector3(0.0, -0.085, 0.035)))
		pierna_node.add_child(_box(Vector3(0.058, 0.012, 0.032), mat_cinturon_naranja, Vector3(0.0, -0.070, 0.032)))
		pierna_node.add_child(_box(Vector3(0.058, 0.012, 0.032), mat_cinturon_naranja, Vector3(0.0, -0.100, 0.032)))

		pierna_node.add_child(_cyl(0.034, 0.030, 0.10, mat_armadura_oscura, Vector3(0.0, -0.130, 0.0)))
		pierna_node.add_child(_box(Vector3(0.044, 0.085, 0.020), mat_armadura_acero, Vector3(0.0, -0.130, 0.028)))

		# Bota
		pierna_node.add_child(_box(Vector3(0.052, 0.055, 0.105), mat_armadura_oscura, Vector3(0.0, -0.160, 0.015)))
		pierna_node.add_child(_box(Vector3(0.054, 0.030, 0.045), mat_armadura_acero, Vector3(0.0, -0.160, 0.050)))
		pierna_node.add_child(_box(Vector3(0.058, 0.015, 0.115), mat_hazard_negro, Vector3(0.0, -0.175, 0.015)))

		att.add_child(pierna_node)

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 3. MODELADO 3D: ARQUERO (player_archer.glb)
# ==============================================================================
func _generar_arquero(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Modelando 3D: ARQUERO...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena)
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]

	var mat_piel := _mat(Color(0.92, 0.74, 0.62), 0.0, 0.55)
	var mat_pelo_castano := _mat(Color(0.42, 0.28, 0.16), 0.05, 0.7)
	var mat_gafas_naranja := _mat(Color(0.92, 0.45, 0.10), 0.2, 0.45)
	var mat_visor_hud := _mat(Color(0.15, 0.95, 1.0), 0.1, 0.1, Color(0.15, 0.95, 1.0), 2.8)
	var mat_mascara := _mat(Color(0.20, 0.22, 0.26), 0.5, 0.4)
	var mat_bufanda := _mat(Color(0.92, 0.46, 0.12), 0.05, 0.65)

	var mat_traje := _mat(Color(0.22, 0.26, 0.34), 0.05, 0.7)
	var mat_armadura_placas := _mat(Color(0.35, 0.38, 0.44), 0.7, 0.35)
	var mat_correas_naranja := _mat(Color(0.88, 0.45, 0.12), 0.1, 0.5)
	var mat_metal_arco := _mat(Color(0.65, 0.68, 0.74), 0.85, 0.25)
	var mat_laser_cian := _mat(Color(0.15, 0.95, 1.0), 0.0, 0.0, Color(0.15, 0.95, 1.0), 3.5)

	# --- CABEZA ---
	var cabeza_node := Node3D.new()
	cabeza_node.name = "ArqueroCabeza"

	cabeza_node.add_child(_sphere(0.058, mat_piel, Vector3(0.0, 0.065, 0.008), Vector3(1.0, 1.12, 1.05)))

	for dx in [-0.045, -0.022, 0.0, 0.022, 0.045]:
		cabeza_node.add_child(_capsule(0.016, 0.055, mat_pelo_castano, Vector3(dx, 0.10, 0.015), Vector3(20, 0, -dx * 220)))
	for dz in [-0.04, -0.01, 0.02]:
		cabeza_node.add_child(_capsule(0.018, 0.060, mat_pelo_castano, Vector3(0.0, 0.10, dz), Vector3(-15, 0, 0)))

	# Gafas HUD naranja y cian
	cabeza_node.add_child(_box(Vector3(0.10, 0.028, 0.022), mat_gafas_naranja, Vector3(0.0, 0.068, 0.058)))
	cabeza_node.add_child(_box(Vector3(0.085, 0.022, 0.026), mat_visor_hud, Vector3(0.0, 0.068, 0.060)))
	cabeza_node.add_child(_box(Vector3(0.12, 0.010, 0.11), mat_correas_naranja, Vector3(0.0, 0.068, 0.0)))

	# Máscara respirador
	cabeza_node.add_child(_sphere(0.034, mat_mascara, Vector3(0.0, 0.035, 0.052), Vector3(1.1, 0.9, 1.0)))
	for sx in [-0.025, 0.025]:
		cabeza_node.add_child(_cyl(0.010, 0.010, 0.022, mat_gafas_naranja, Vector3(sx, 0.035, 0.068), Vector3(90, 0, 0)))

	att_head.add_child(cabeza_node)

	# --- TORSO ---
	var torso_node := Node3D.new()
	torso_node.name = "ArqueroTorso"

	# Bufanda naranja voluminosa
	torso_node.add_child(_torus(0.055, 0.024, mat_bufanda, Vector3(0.0, 0.145, 0.005), Vector3(85, 0, 0)))
	torso_node.add_child(_capsule(0.072, 0.13, mat_traje, Vector3(0.0, 0.075, 0.015)))

	for sx in [-0.08, 0.08]:
		torso_node.add_child(_sphere(0.040, mat_armadura_placas, Vector3(sx, 0.11, 0.0), Vector3(1.1, 0.8, 1.1)))

	# Canana diagonal con cartuchos
	torso_node.add_child(_box(Vector3(0.022, 0.18, 0.15), mat_correas_naranja, Vector3(0.0, 0.075, 0.015), Vector3(0, 0, -35)))
	for i in range(4):
		var py = 0.11 - float(i) * 0.026
		var px = -0.024 + float(i) * 0.015
		torso_node.add_child(_cyl(0.006, 0.006, 0.030, mat_visor_hud, Vector3(px, py, 0.085), Vector3(0, 0, -35)))

	torso_node.add_child(_cyl(0.075, 0.075, 0.022, mat_correas_naranja, Vector3(0.0, 0.005, 0.015)))
	for sx in [-0.05, -0.02, 0.02, 0.05]:
		torso_node.add_child(_box(Vector3(0.022, 0.028, 0.020), mat_correas_naranja, Vector3(sx, 0.005, 0.088)))

	# Carcaj tecnológico dorsal
	var carcaj_node := Node3D.new()
	carcaj_node.position = Vector3(0.05, 0.08, -0.085)
	carcaj_node.rotation_degrees = Vector3(18, 0, -22)
	carcaj_node.add_child(_cyl(0.028, 0.025, 0.20, mat_armadura_placas, Vector3(0, 0, 0)))
	carcaj_node.add_child(_box(Vector3(0.012, 0.14, 0.015), mat_visor_hud, Vector3(0.028, 0, 0)))

	for fx in [-0.012, 0.012]:
		for fz in [-0.012, 0.012]:
			carcaj_node.add_child(_cyl(0.003, 0.003, 0.11, mat_metal_arco, Vector3(fx, 0.12, fz)))
			carcaj_node.add_child(_box(Vector3(0.011, 0.025, 0.011), mat_visor_hud, Vector3(fx, 0.16, fz)))

	var carcaj_light := OmniLight3D.new()
	carcaj_light.name = "LuzCarcaj"
	carcaj_light.light_color = Color(0.15, 0.95, 1.0)
	carcaj_light.light_energy = 1.4
	carcaj_light.omni_range = 1.8
	carcaj_light.position = Vector3(0.0, 0.16, 0.0)
	carcaj_node.add_child(carcaj_light)

	torso_node.add_child(carcaj_node)
	att_torso.add_child(torso_node)

	# --- BRAZOS Y GUANTELETES ---
	for lado in ["L", "R"]:
		var att = att_arm_l if lado == "L" else att_arm_r
		var brazo_node := Node3D.new()
		brazo_node.name = "ArqueroBrazo_" + lado

		brazo_node.add_child(_capsule(0.028, 0.09, mat_traje, Vector3(0.0, -0.045, 0.0)))
		brazo_node.add_child(_cyl(0.027, 0.023, 0.08, mat_armadura_placas, Vector3(0.0, -0.115, 0.0)))
		brazo_node.add_child(_sphere(0.024, mat_mascara, Vector3(0.0, -0.155, 0.0)))

		att.add_child(brazo_node)

	# --- ARMA: ARCO TECNOLÓGICO (Mano izquierda) ---
	var arco_node := Node3D.new()
	arco_node.name = "ArcoTecnologico"
	arco_node.position = Vector3(0.0, -0.15, 0.05)
	arco_node.rotation_degrees = Vector3(0, 90, 0)

	arco_node.add_child(_box(Vector3(0.022, 0.075, 0.028), mat_armadura_placas))
	for sy in [-1.0, 1.0]:
		arco_node.add_child(_box(Vector3(0.018, 0.14, 0.022), mat_metal_arco, Vector3(0.0, sy * 0.09, -0.025), Vector3(sy * 18, 0, 0)))
		arco_node.add_child(_box(Vector3(0.015, 0.11, 0.018), mat_metal_arco, Vector3(0.0, sy * 0.20, -0.050), Vector3(sy * -25, 0, 0)))
		arco_node.add_child(_cyl(0.014, 0.014, 0.022, mat_visor_hud, Vector3(0.0, sy * 0.15, -0.038), Vector3(0, 0, 90)))

	arco_node.add_child(_cyl(0.002, 0.002, 0.46, mat_laser_cian, Vector3(0.0, 0.0, -0.075)))
	arco_node.add_child(_cyl(0.003, 0.003, 0.28, mat_metal_arco, Vector3(0.0, 0.0, 0.05), Vector3(90, 0, 0)))
	arco_node.add_child(_sphere(0.010, mat_laser_cian, Vector3(0.0, 0.0, 0.19)))

	var arco_light := OmniLight3D.new()
	arco_light.name = "LuzArco"
	arco_light.light_color = Color(0.15, 0.95, 1.0)
	arco_light.light_energy = 2.2
	arco_light.omni_range = 2.4
	arco_light.position = Vector3(0.0, 0.0, 0.19)
	arco_node.add_child(arco_light)

	att_arm_l.add_child(arco_node)

	# --- PIERNAS ---
	for lado in ["L", "R"]:
		var att = att_leg_l if lado == "L" else att_leg_r
		var pierna_node := Node3D.new()
		pierna_node.name = "ArqueroPierna_" + lado

		pierna_node.add_child(_capsule(0.034, 0.09, mat_traje, Vector3(0.0, -0.045, 0.0)))
		pierna_node.add_child(_box(Vector3(0.046, 0.040, 0.022), mat_armadura_placas, Vector3(0.0, -0.085, 0.028)))
		pierna_node.add_child(_box(Vector3(0.049, 0.011, 0.025), mat_correas_naranja, Vector3(0.0, -0.075, 0.028)))

		pierna_node.add_child(_capsule(0.030, 0.08, mat_traje, Vector3(0.0, -0.125, 0.0)))

		pierna_node.add_child(_box(Vector3(0.046, 0.048, 0.092), mat_mascara, Vector3(0.0, -0.155, 0.015)))
		pierna_node.add_child(_box(Vector3(0.050, 0.014, 0.102), mat_mascara, Vector3(0.0, -0.170, 0.015)))

		att.add_child(pierna_node)

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 4. MODELADO 3D: MAGO / ARCANISTA (player_mage.glb)
# ==============================================================================
func _generar_mago(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Modelando 3D: MAGO...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena)
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]

	var mat_piel := _mat(Color(0.92, 0.74, 0.62), 0.0, 0.55)
	var mat_pelo_oscuro := _mat(Color(0.18, 0.20, 0.24), 0.05, 0.75)
	var mat_visor_cian := _mat(Color(0.15, 0.95, 1.0), 0.1, 0.1, Color(0.15, 0.95, 1.0), 3.0)
	var mat_mascara := _mat(Color(0.22, 0.24, 0.28), 0.3, 0.45)
	var mat_bufanda := _mat(Color(0.92, 0.46, 0.12), 0.05, 0.65)

	var mat_gabardina := _mat(Color(0.18, 0.22, 0.30), 0.05, 0.75)
	var mat_cuero := _mat(Color(0.28, 0.18, 0.11), 0.1, 0.6)
	var mat_vial_verde := _mat(Color(0.20, 0.95, 0.35), 0.1, 0.1, Color(0.18, 0.95, 0.35), 2.5)
	var mat_vial_cian := _mat(Color(0.15, 0.95, 1.0), 0.1, 0.1, Color(0.15, 0.95, 1.0), 2.8)

	var mat_baston_metal := _mat(Color(0.55, 0.58, 0.64), 0.8, 0.3)
	var mat_baston_cobre := _mat(Color(0.85, 0.46, 0.18), 0.8, 0.3)
	var mat_plasma_vidrio := _mat(Color(0.7, 0.95, 1.0, 0.6), 0.1, 0.1, Color(0.15, 0.95, 1.0), 1.5)
	mat_plasma_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mat_plasma_core := _mat(Color(0.25, 1.0, 1.0), 0.0, 0.0, Color(0.20, 1.0, 1.0), 4.0)

	# --- CABEZA ---
	var cabeza_node := Node3D.new()
	cabeza_node.name = "MagoCabeza"

	cabeza_node.add_child(_sphere(0.058, mat_piel, Vector3(0.0, 0.065, 0.008), Vector3(1.0, 1.12, 1.05)))

	for dx in [-0.045, -0.022, 0.0, 0.022, 0.045]:
		cabeza_node.add_child(_capsule(0.016, 0.060, mat_pelo_oscuro, Vector3(dx, 0.10, 0.015), Vector3(25, 0, -dx * 200)))
	for dz in [-0.04, -0.01, 0.02]:
		cabeza_node.add_child(_capsule(0.018, 0.065, mat_pelo_oscuro, Vector3(0.0, 0.10, dz), Vector3(-18, 0, 0)))

	cabeza_node.add_child(_box(Vector3(0.10, 0.028, 0.024), mat_visor_cian, Vector3(0.0, 0.068, 0.058)))
	cabeza_node.add_child(_sphere(0.034, mat_mascara, Vector3(0.0, 0.035, 0.052), Vector3(1.1, 0.9, 1.0)))

	att_head.add_child(cabeza_node)

	# --- TORSO & GABARDINA ---
	var torso_node := Node3D.new()
	torso_node.name = "MagoTorso"

	torso_node.add_child(_torus(0.055, 0.024, mat_bufanda, Vector3(0.0, 0.145, 0.005), Vector3(85, 0, 0)))
	torso_node.add_child(_capsule(0.076, 0.14, mat_gabardina, Vector3(0.0, 0.070, 0.015)))

	# Cuello / Solapas
	torso_node.add_child(_box(Vector3(0.11, 0.085, 0.020), mat_gabardina, Vector3(0.0, 0.105, 0.082), Vector3(-15, 0, 0)))

	# Faldones de la gabardina (bajan hasta mitad de piernas)
	torso_node.add_child(_cyl(0.085, 0.13, 0.22, mat_gabardina, Vector3(0.0, -0.09, 0.015)))

	# Canana con 3 viales verdes
	torso_node.add_child(_box(Vector3(0.020, 0.20, 0.15), mat_cuero, Vector3(0.0, 0.075, 0.015), Vector3(0, 0, -32)))
	for i in range(3):
		var py = 0.10 - float(i) * 0.028
		var px = -0.02 + float(i) * 0.016
		torso_node.add_child(_cyl(0.007, 0.007, 0.028, mat_vial_verde, Vector3(px, py, 0.086), Vector3(0, 0, -32)))

	# Cinturón con viales cian
	torso_node.add_child(_cyl(0.080, 0.080, 0.022, mat_cuero, Vector3(0.0, 0.005, 0.015)))
	for sx in [-0.055, -0.025, 0.025, 0.055]:
		torso_node.add_child(_cyl(0.007, 0.007, 0.038, mat_vial_cian, Vector3(sx, -0.020, 0.084)))

	att_torso.add_child(torso_node)

	# --- BRAZOS Y LLAMA ARCANA ---
	for lado in ["L", "R"]:
		var att = att_arm_l if lado == "L" else att_arm_r
		var brazo_node := Node3D.new()
		brazo_node.name = "MagoBrazo_" + lado

		brazo_node.add_child(_capsule(0.030, 0.10, mat_gabardina, Vector3(0.0, -0.045, 0.0)))
		brazo_node.add_child(_cyl(0.028, 0.024, 0.075, mat_baston_metal, Vector3(0.0, -0.115, 0.0)))
		brazo_node.add_child(_sphere(0.024, mat_cuero, Vector3(0.0, -0.155, 0.0)))

		att.add_child(brazo_node)

	# Llama Arcana en mano izquierda
	var fuego_node := Node3D.new()
	fuego_node.name = "FuegoArcano"
	fuego_node.position = Vector3(0.0, -0.16, 0.03)
	fuego_node.add_child(_sphere(0.025, mat_plasma_core))
	fuego_node.add_child(_sphere(0.040, mat_plasma_vidrio))

	var fuego_light := OmniLight3D.new()
	fuego_light.name = "LuzFuego"
	fuego_light.light_color = Color(0.15, 0.95, 1.0)
	fuego_light.light_energy = 2.0
	fuego_light.omni_range = 2.2
	fuego_node.add_child(fuego_light)

	att_arm_l.add_child(fuego_node)

	# --- ARMA: BÁCULO DE PLASMA (Mano derecha) ---
	var baston_node := Node3D.new()
	baston_node.name = "BastonPlasma"
	baston_node.position = Vector3(0.0, -0.16, 0.03)
	baston_node.rotation_degrees = Vector3(12.0, 0.0, -28.0)

	baston_node.add_child(_cyl(0.012, 0.013, 0.52, mat_baston_metal, Vector3(0, 0.10, 0)))
	baston_node.add_child(_cyl(0.015, 0.015, 0.11, mat_cuero, Vector3(0, 0.0, 0)))
	baston_node.add_child(_cyl(0.017, 0.017, 0.030, mat_baston_cobre, Vector3(0, 0.24, 0)))

	# Manómetro
	baston_node.add_child(_cyl(0.015, 0.015, 0.012, mat_baston_cobre, Vector3(0.022, 0.25, 0), Vector3(0, 0, 90)))

	# Jaula
	for rot_y in [0.0, 60.0, 120.0]:
		baston_node.add_child(_box(Vector3(0.005, 0.15, 0.070), mat_baston_metal, Vector3(0, 0.34, 0), Vector3(0, rot_y, 0)))

	# Ampolla de vidrio con plasma
	baston_node.add_child(_cyl(0.030, 0.030, 0.12, mat_plasma_vidrio, Vector3(0, 0.34, 0)))
	baston_node.add_child(_sphere(0.022, mat_plasma_core, Vector3(0, 0.34, 0)))

	var staff_light := OmniLight3D.new()
	staff_light.name = "LuzBaston"
	staff_light.light_color = Color(0.18, 0.95, 1.0)
	staff_light.light_energy = 2.8
	staff_light.omni_range = 2.8
	staff_light.position = Vector3(0, 0.34, 0)
	baston_node.add_child(staff_light)

	att_arm_r.add_child(baston_node)

	# --- PIERNAS ---
	for lado in ["L", "R"]:
		var att = att_leg_l if lado == "L" else att_leg_r
		var pierna_node := Node3D.new()
		pierna_node.name = "MagoPierna_" + lado

		pierna_node.add_child(_capsule(0.034, 0.09, mat_pelo_oscuro, Vector3(0.0, -0.045, 0.0)))
		pierna_node.add_child(_box(Vector3(0.046, 0.040, 0.022), mat_baston_metal, Vector3(0.0, -0.085, 0.028)))

		pierna_node.add_child(_capsule(0.030, 0.08, mat_pelo_oscuro, Vector3(0.0, -0.125, 0.0)))

		pierna_node.add_child(_box(Vector3(0.046, 0.048, 0.092), mat_cuero, Vector3(0.0, -0.155, 0.015)))
		pierna_node.add_child(_box(Vector3(0.050, 0.014, 0.102), mat_cuero, Vector3(0.0, -0.170, 0.015)))

		att.add_child(pierna_node)

	_exportar_glb(escena, ruta_salida)
	escena.free()
