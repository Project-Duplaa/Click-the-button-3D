@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: BRUTO APLASTADOR (BIO-GÓLEM MASIVO)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Titán de roca volcánica, barril radiactivo 3D, cadenas de hierro y cristales esmeralda.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: BRUTO APLASTADOR...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_bruto_aplastador"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Roca Volcánica / Granito Musgoso
	var mat_roca = StandardMaterial3D.new()
	mat_roca.albedo_color = Color(0.25, 0.26, 0.24)
	mat_roca.roughness = 0.72
	mat_roca.metallic = 0.05
	mat_roca.rim_enabled = true
	mat_roca.rim = 0.55
	mat_roca.rim_tint = 0.25

	# 2. Coraza de Roca Oscura / Titanio
	var mat_placa = StandardMaterial3D.new()
	mat_placa.albedo_color = Color(0.16, 0.17, 0.16)
	mat_placa.roughness = 0.52
	mat_placa.metallic = 0.55
	mat_placa.rim_enabled = true
	mat_placa.rim = 0.45

	# 3. Cristales Radiactivos Esmeralda (Brillo verde puro y nítido, sin quemado blanco)
	var mat_cristal = StandardMaterial3D.new()
	mat_cristal.albedo_color = Color(0.15, 0.90, 0.28, 0.92)
	mat_cristal.metallic = 0.1
	mat_cristal.roughness = 0.12
	mat_cristal.emission_enabled = true
	mat_cristal.emission = Color(0.16, 0.85, 0.25)
	mat_cristal.emission_energy_multiplier = 0.82
	mat_cristal.rim_enabled = true
	mat_cristal.rim = 0.9
	mat_cristal.rim_tint = 0.5

	# 4. Barril de Biopeligro Amarillo Industrial
	var mat_barril_amarillo = StandardMaterial3D.new()
	mat_barril_amarillo.albedo_color = Color(0.92, 0.70, 0.08)
	mat_barril_amarillo.roughness = 0.38
	mat_barril_amarillo.metallic = 0.45

	var mat_barril_franjas = StandardMaterial3D.new()
	mat_barril_franjas.albedo_color = Color(0.12, 0.12, 0.12)
	mat_barril_franjas.roughness = 0.4

	# 5. Cadenas de Hierro Fundido
	var mat_hierro = StandardMaterial3D.new()
	mat_hierro.albedo_color = Color(0.35, 0.36, 0.38)
	mat_hierro.metallic = 0.9
	mat_hierro.roughness = 0.32

	# 6. Ojos incandescentes de bio-plasma
	var mat_ojos = StandardMaterial3D.new()
	mat_ojos.albedo_color = Color(0.2, 1.0, 0.4)
	mat_ojos.emission_enabled = true
	mat_ojos.emission = Color(0.2, 1.0, 0.35)
	mat_ojos.emission_energy_multiplier = 1.0

	# --- 1. TORSO Y PECHO ROCOSO VOLUMÉTRICO ---
	var nodo_torso = Node3D.new()
	nodo_torso.name = "TorsoTitan"
	nodo_torso.position = Vector3(0, 1.15, 0)
	raiz.add_child(nodo_torso)

	# Masa torácica central (búlder masivo)
	var m_pecho = SphereMesh.new()
	m_pecho.radius = 0.62
	m_pecho.height = 0.85
	m_pecho.radial_segments = 24
	m_pecho.rings = 14
	m_pecho.material = mat_roca
	var mi_pecho = MeshInstance3D.new()
	mi_pecho.mesh = m_pecho
	mi_pecho.scale = Vector3(1.25, 1.0, 0.9)
	nodo_torso.add_child(mi_pecho)

	# Placas pectorales cinceladas izquierda y derecha
	for lado in [-1, 1]:
		var m_pectoral = BoxMesh.new()
		m_pectoral.size = Vector3(0.48, 0.42, 0.28)
		m_pectoral.material = mat_placa
		var mi_pectoral = MeshInstance3D.new()
		mi_pectoral.mesh = m_pectoral
		mi_pectoral.position = Vector3(lado * 0.32, 0.15, 0.42)
		mi_pectoral.rotation_degrees = Vector3(10, lado * -15, lado * -5)
		nodo_torso.add_child(mi_pectoral)

	# Abdomen inferior rocoso segmentado
	var m_abdomen = SphereMesh.new()
	m_abdomen.radius = 0.48
	m_abdomen.height = 0.55
	m_abdomen.material = mat_roca
	var mi_abdomen = MeshInstance3D.new()
	mi_abdomen.mesh = m_abdomen
	mi_abdomen.position = Vector3(0, -0.42, 0.05)
	nodo_torso.add_child(mi_abdomen)

	# --- 2. JOROBA Y ESPALDA CON CHIMENEAS INDUSTRIALES ---
	var m_joroba = SphereMesh.new()
	m_joroba.radius = 0.58
	m_joroba.height = 0.72
	m_joroba.material = mat_roca
	var mi_joroba = MeshInstance3D.new()
	mi_joroba.mesh = m_joroba
	mi_joroba.position = Vector3(0, 0.32, -0.32)
	nodo_torso.add_child(mi_joroba)

	# Chimeneas gemelas de escape en la joroba
	for lado in [-1, 1]:
		var nodo_chimenea = Node3D.new()
		nodo_chimenea.position = Vector3(lado * 0.26, 0.62, -0.38)
		nodo_chimenea.rotation_degrees = Vector3(-20, lado * 10, lado * 5)
		nodo_torso.add_child(nodo_chimenea)

		var m_chim = CylinderMesh.new()
		m_chim.top_radius = 0.11
		m_chim.bottom_radius = 0.13
		m_chim.height = 0.55
		m_chim.radial_segments = 16
		m_chim.material = mat_hierro
		var mi_chim = MeshInstance3D.new()
		mi_chim.mesh = m_chim
		mi_chim.position = Vector3(0, 0.27, 0)
		nodo_chimenea.add_child(mi_chim)

		var m_anillo_chim = TorusMesh.new()
		m_anillo_chim.inner_radius = 0.08
		m_anillo_chim.outer_radius = 0.14
		m_anillo_chim.material = mat_placa
		var mi_anillo_chim = MeshInstance3D.new()
		mi_anillo_chim.mesh = m_anillo_chim
		mi_anillo_chim.position = Vector3(0, 0.54, 0)
		nodo_chimenea.add_child(mi_anillo_chim)

	# --- 3. BARRIL DE BIOPELIGRO 3D REAL ENCASTRADO EN EL COSTADO/ESPALDA ---
	var nodo_barril = Node3D.new()
	nodo_barril.name = "BarrilRadiactivo"
	nodo_barril.position = Vector3(0.52, 0.18, -0.35)
	nodo_barril.rotation_degrees = Vector3(25, -30, 18)
	nodo_torso.add_child(nodo_barril)

	var m_cuerpo_barril = CylinderMesh.new()
	m_cuerpo_barril.top_radius = 0.24
	m_cuerpo_barril.bottom_radius = 0.24
	m_cuerpo_barril.height = 0.68
	m_cuerpo_barril.radial_segments = 20
	m_cuerpo_barril.material = mat_barril_amarillo
	var mi_cuerpo_barril = MeshInstance3D.new()
	mi_cuerpo_barril.mesh = m_cuerpo_barril
	nodo_barril.add_child(mi_cuerpo_barril)

	# Aros negros de refuerzo del barril
	for pos_y in [-0.22, 0.0, 0.22]:
		var m_aro_barril = TorusMesh.new()
		m_aro_barril.inner_radius = 0.22
		m_aro_barril.outer_radius = 0.26
		m_aro_barril.material = mat_barril_franjas
		var mi_aro = MeshInstance3D.new()
		mi_aro.mesh = m_aro_barril
		mi_aro.position = Vector3(0, pos_y, 0)
		nodo_barril.add_child(mi_aro)

	# --- 4. CADENAS INDUSTRIALES 3D QUE ENVOLVEN EL PECHO ---
	for i in range(10):
		var t = float(i) / 9.0
		var x_pos = lerp(-0.65, 0.58, t)
		var y_pos = lerp(0.45, -0.25, t)
		var z_pos = 0.55 * sin(t * PI) + 0.15

		var m_eslabon = TorusMesh.new()
		m_eslabon.inner_radius = 0.05
		m_eslabon.outer_radius = 0.09
		m_eslabon.material = mat_hierro
		var mi_esl = MeshInstance3D.new()
		mi_esl.mesh = m_eslabon
		mi_esl.position = Vector3(x_pos, y_pos, z_pos)
		mi_esl.rotation_degrees = Vector3(30, 45, i * 40.0)
		mi_esl.scale = Vector3(1.0, 0.55, 1.4)
		nodo_torso.add_child(mi_esl)

	# --- 5. CABEZA HUNDIDA Y MÁSCARA PETREA ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaGolem"
	nodo_cabeza.position = Vector3(0, 0.38, 0.36)
	nodo_torso.add_child(nodo_cabeza)

	var m_craneo = SphereMesh.new()
	m_craneo.radius = 0.28
	m_craneo.height = 0.35
	m_craneo.material = mat_roca
	var mi_craneo = MeshInstance3D.new()
	mi_craneo.mesh = m_craneo
	nodo_cabeza.add_child(mi_craneo)

	# Mandíbula y ceja pesada de titanio/roca
	var m_ceja = BoxMesh.new()
	m_ceja.size = Vector3(0.42, 0.14, 0.24)
	m_ceja.material = mat_placa
	var mi_ceja = MeshInstance3D.new()
	mi_ceja.mesh = m_ceja
	mi_ceja.position = Vector3(0, 0.08, 0.18)
	mi_ceja.rotation_degrees = Vector3(15, 0, 0)
	nodo_cabeza.add_child(mi_ceja)

	# Ojos radiactivos verdes
	for lado in [-1, 1]:
		var m_ojo = SphereMesh.new()
		m_ojo.radius = 0.045
		m_ojo.height = 0.07
		m_ojo.material = mat_ojos
		var mi_ojo = MeshInstance3D.new()
		mi_ojo.mesh = m_ojo
		mi_ojo.position = Vector3(lado * 0.11, 0.04, 0.26)
		nodo_cabeza.add_child(mi_ojo)

	# --- 6. CRISTALES RADIACTIVOS ESMERALDA EN HOMBROS Y ESPALDA ---
	var clusters = [
		{"pos": Vector3(-0.48, 0.52, -0.15), "rot": Vector3(-15, -30, -35), "escala": 1.2},
		{"pos": Vector3(-0.62, 0.45, 0.10), "rot": Vector3(20, -45, -45), "escala": 0.9},
		{"pos": Vector3(0.15, 0.68, -0.22), "rot": Vector3(-35, 15, 18), "escala": 1.1},
		{"pos": Vector3(0.55, 0.48, 0.12), "rot": Vector3(15, 40, 38), "escala": 0.85}
	]
	for cl in clusters:
		var nodo_cl = Node3D.new()
		nodo_cl.position = cl["pos"]
		nodo_cl.rotation_degrees = cl["rot"]
		nodo_cl.scale = Vector3.ONE * cl["escala"]
		nodo_torso.add_child(nodo_cl)

		# Cristal central grande de 6 caras
		var m_cristal_p = CylinderMesh.new()
		m_cristal_p.top_radius = 0.01
		m_cristal_p.bottom_radius = 0.11
		m_cristal_p.height = 0.65
		m_cristal_p.radial_segments = 6
		m_cristal_p.material = mat_cristal
		var mi_c1 = MeshInstance3D.new()
		mi_c1.mesh = m_cristal_p
		mi_c1.position = Vector3(0, 0.32, 0)
		nodo_cl.add_child(mi_c1)

		# Cristal secundario menor adyacente
		var m_cristal_s = CylinderMesh.new()
		m_cristal_s.top_radius = 0.01
		m_cristal_s.bottom_radius = 0.07
		m_cristal_s.height = 0.42
		m_cristal_s.radial_segments = 6
		m_cristal_s.material = mat_cristal
		var mi_c2 = MeshInstance3D.new()
		mi_c2.mesh = m_cristal_s
		mi_c2.position = Vector3(0.08, 0.18, 0.05)
		mi_c2.rotation_degrees = Vector3(12, 25, 18)
		nodo_cl.add_child(mi_c2)

	# --- 7. BRAZOS TITÁNICOS CON GUANTELETES DE ROCA Y PUÑOS APLASTADORES ---
	for lado in [-1, 1]:
		var nodo_brazo = Node3D.new()
		nodo_brazo.name = "Brazo_" + ("Izq" if lado < 0 else "Der")
		nodo_brazo.position = Vector3(lado * 0.72, 0.28, 0.05)
		nodo_torso.add_child(nodo_brazo)

		# Hombrera de bÃºlder masivo
		var m_hombrera = SphereMesh.new()
		m_hombrera.radius = 0.38
		m_hombrera.height = 0.52
		m_hombrera.material = mat_roca
		var mi_hombrera = MeshInstance3D.new()
		mi_hombrera.mesh = m_hombrera
		nodo_brazo.add_child(mi_hombrera)

		# Bíceps pétreo articulado
		var m_biceps = CylinderMesh.new()
		m_biceps.top_radius = 0.24
		m_biceps.bottom_radius = 0.28
		m_biceps.height = 0.55
		m_biceps.radial_segments = 16
		m_biceps.material = mat_roca
		var mi_biceps = MeshInstance3D.new()
		mi_biceps.mesh = m_biceps
		mi_biceps.position = Vector3(lado * 0.15, -0.38, 0.08)
		mi_biceps.rotation_degrees = Vector3(15, 0, lado * -18)
		nodo_brazo.add_child(mi_biceps)

		# Antebrazo masivo (con placa de refuerzo de titanio con franjas de precaución)
		var m_antebrazo = BoxMesh.new()
		m_antebrazo.size = Vector3(0.46, 0.58, 0.46)
		m_antebrazo.material = mat_placa
		var mi_antebrazo = MeshInstance3D.new()
		mi_antebrazo.mesh = m_antebrazo
		mi_antebrazo.position = Vector3(lado * 0.22, -0.88, 0.28)
		mi_antebrazo.rotation_degrees = Vector3(25, lado * -10, lado * -8)
		nodo_brazo.add_child(mi_antebrazo)

		# Puño triturador de roca maciza
		var m_puno = SphereMesh.new()
		m_puno.radius = 0.34
		m_puno.height = 0.44
		m_puno.material = mat_roca
		var mi_puno = MeshInstance3D.new()
		mi_puno.mesh = m_puno
		mi_puno.position = Vector3(lado * 0.25, -1.22, 0.48)
		nodo_brazo.add_child(mi_puno)

		# Nudillos pétreos cincelados
		for k in range(3):
			var m_nudillo = BoxMesh.new()
			m_nudillo.size = Vector3(0.14, 0.18, 0.16)
			m_nudillo.material = mat_placa
			var mi_nud = MeshInstance3D.new()
			mi_nud.mesh = m_nudillo
			mi_nud.position = mi_puno.position + Vector3((k - 1) * 0.12, -0.15, 0.15)
			nodo_brazo.add_child(mi_nud)

	# --- 8. PIERNAS TRONCONICAS DE ROCA Y PIES PLANOS DE IMPACTO ---
	for lado in [-1, 1]:
		var nodo_pierna = Node3D.new()
		nodo_pierna.name = "Pierna_" + ("Izq" if lado < 0 else "Der")
		nodo_pierna.position = Vector3(lado * 0.42, 0.65, 0)
		raiz.add_child(nodo_pierna)

		var m_muslo = CylinderMesh.new()
		m_muslo.top_radius = 0.32
		m_muslo.bottom_radius = 0.38
		m_muslo.height = 0.55
		m_muslo.radial_segments = 16
		m_muslo.material = mat_roca
		var mi_muslo = MeshInstance3D.new()
		mi_muslo.mesh = m_muslo
		mi_muslo.position = Vector3(0, -0.22, 0)
		nodo_pierna.add_child(mi_muslo)

		var m_pie = BoxMesh.new()
		m_pie.size = Vector3(0.48, 0.24, 0.65)
		m_pie.material = mat_placa
		var mi_pie = MeshInstance3D.new()
		mi_pie.mesh = m_pie
		mi_pie.position = Vector3(0, -0.55, 0.1)
		nodo_pierna.add_child(mi_pie)

	# --- 9. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 10. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_bruto_aplastador.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Bruto exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_bruto_aplastador.glb-af8d05df4c64d8d296eb3292b6fbe5ad.scn"
	var err_scn = ResourceSaver.save(pack, scn_path)
	if err_scn == OK:
		print("✓ Escena SCN sincronizada directamente en: ", scn_path)
	else:
		printerr("Error guardando SCN: ", err_scn)

	quit(0)

func _fijar_dueno(n: Node, r: Node):
	for c in n.get_children():
		c.owner = r
		_fijar_dueno(c, r)
