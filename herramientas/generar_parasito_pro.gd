@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: PARÁSITO DEL CURSOR (ESCARABAJO CIBER-NANÍTICO)
# Modelo 100% tridimensional volumétrico en 360°, sin cubos verdes planos.
# Caparazón iridiscente esmeralda, mandíbulas mecánicas, 6 patas articuladas y núcleo de nanitas.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: PARÁSITO DEL CURSOR...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_parasito_cursor"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Caparazón Quitinoso Verde Iridiscente / Cromo Tóxico
	var mat_caparazon = StandardMaterial3D.new()
	mat_caparazon.albedo_color = Color(0.18, 0.85, 0.28)
	mat_caparazon.metallic = 0.85
	mat_caparazon.roughness = 0.18
	mat_caparazon.rim_enabled = true
	mat_caparazon.rim = 0.8
	mat_caparazon.rim_tint = 0.45

	# 2. Exoesqueleto de Acero Titanio Oscuro (Juntas y patas)
	var mat_chasis = StandardMaterial3D.new()
	mat_chasis.albedo_color = Color(0.16, 0.18, 0.20)
	mat_chasis.metallic = 0.92
	mat_chasis.roughness = 0.28
	mat_chasis.rim_enabled = true
	mat_chasis.rim = 0.5

	# 3. Mandíbulas / Pinzas de Cromo Afilado
	var mat_cromo = StandardMaterial3D.new()
	mat_cromo.albedo_color = Color(0.85, 0.88, 0.92)
	mat_cromo.metallic = 0.98
	mat_cromo.roughness = 0.12

	# 4. Sensores Ópticos / Ojos de Nanitas (Cian Eléctrico)
	var mat_ojos = StandardMaterial3D.new()
	mat_ojos.albedo_color = Color(0.2, 0.95, 1.0)
	mat_ojos.emission_enabled = true
	mat_ojos.emission = Color(0.15, 0.9, 1.0)
	mat_ojos.emission_energy_multiplier = 0.95

	# 5. Núcleo Abdominal de Fusión de Clics (Verde Lima Incandescente)
	var mat_nucleo = StandardMaterial3D.new()
	mat_nucleo.albedo_color = Color(0.4, 1.0, 0.3)
	mat_nucleo.emission_enabled = true
	mat_nucleo.emission = Color(0.35, 1.0, 0.25)
	mat_nucleo.emission_energy_multiplier = 0.85

	# 6. Cúpula de Cristal de Contención
	var mat_vidrio = StandardMaterial3D.new()
	mat_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vidrio.albedo_color = Color(0.8, 1.0, 0.85, 0.35)
	mat_vidrio.roughness = 0.08
	mat_vidrio.rim_enabled = true
	mat_vidrio.rim = 0.9

	# --- 1. CUERPO Y CAPARAZÓN METÁLICO (3D ELIPSOIDAL SEGMENTADO) ---
	var nodo_cuerpo = Node3D.new()
	nodo_cuerpo.name = "CuerpoBicho"
	nodo_cuerpo.position = Vector3(0, 0.65, 0)
	raiz.add_child(nodo_cuerpo)

	# Élitros / Caparazón dorsal principal
	var m_dorsal = SphereMesh.new()
	m_dorsal.radius = 0.48
	m_dorsal.height = 0.55
	m_dorsal.radial_segments = 28
	m_dorsal.rings = 14
	m_dorsal.material = mat_caparazon
	var mi_dorsal = MeshInstance3D.new()
	mi_dorsal.mesh = m_dorsal
	mi_dorsal.scale = Vector3(1.15, 0.72, 1.45)
	nodo_cuerpo.add_child(mi_dorsal)

	# Hendidura longitudinal entre élitros
	var m_hendidura = BoxMesh.new()
	m_hendidura.size = Vector3(0.04, 0.12, 0.95)
	m_hendidura.material = mat_chasis
	var mi_hen = MeshInstance3D.new()
	mi_hen.mesh = m_hendidura
	mi_hen.position = Vector3(0, 0.22, -0.05)
	nodo_cuerpo.add_child(mi_hen)

	# Placas de blindaje segmentadas en el lomo
	for s in range(3):
		var m_placa_lomo = TorusMesh.new()
		m_placa_lomo.inner_radius = 0.35 - (s * 0.04)
		m_placa_lomo.outer_radius = 0.44 - (s * 0.04)
		m_placa_lomo.material = mat_chasis
		var mi_pl = MeshInstance3D.new()
		mi_pl.mesh = m_placa_lomo
		mi_pl.position = Vector3(0, 0.14 - (s * 0.02), (s - 1) * 0.22)
		mi_pl.scale = Vector3(1.15, 0.45, 0.85)
		nodo_cuerpo.add_child(mi_pl)

	# --- 2. CABEZA ROBÓTICA Y PINZAS/MANDÍBULAS DE CLIC ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaRobotica"
	nodo_cabeza.position = Vector3(0, 0.04, 0.62)
	nodo_cuerpo.add_child(nodo_cabeza)

	var m_craneo_bicho = SphereMesh.new()
	m_craneo_bicho.radius = 0.26
	m_craneo_bicho.height = 0.34
	m_craneo_bicho.material = mat_chasis
	var mi_cb = MeshInstance3D.new()
	mi_cb.mesh = m_craneo_bicho
	mi_cb.scale = Vector3(1.2, 0.8, 1.0)
	nodo_cabeza.add_child(mi_cb)

	# Ojos multifacetados cian
	for lado in [-1, 1]:
		var m_ojo = SphereMesh.new()
		m_ojo.radius = 0.075
		m_ojo.height = 0.11
		m_ojo.material = mat_ojos
		var mi_ojo = MeshInstance3D.new()
		mi_ojo.mesh = m_ojo
		mi_ojo.position = Vector3(lado * 0.22, 0.06, 0.08)
		mi_ojo.rotation_degrees = Vector3(0, lado * 35, 0)
		nodo_cabeza.add_child(mi_ojo)

	# Mandíbulas / Tenazas de captura de cursor (Pincers curvados)
	for lado in [-1, 1]:
		var nodo_mandibula = Node3D.new()
		nodo_mandibula.position = Vector3(lado * 0.14, -0.06, 0.22)
		nodo_mandibula.rotation_degrees = Vector3(0, lado * -25, 0)
		nodo_cabeza.add_child(nodo_mandibula)

		var m_pincer = CylinderMesh.new()
		m_pincer.top_radius = 0.015
		m_pincer.bottom_radius = 0.05
		m_pincer.height = 0.38
		m_pincer.material = mat_cromo
		var mi_pin = MeshInstance3D.new()
		mi_pin.mesh = m_pincer
		mi_pin.position = Vector3(0, 0, 0.16)
		mi_pin.rotation_degrees = Vector3(85, lado * -35, 0)
		nodo_mandibula.add_child(mi_pin)

	# Antenas tácticas con sensores
	for lado in [-1, 1]:
		var m_antena = CylinderMesh.new()
		m_antena.top_radius = 0.008
		m_antena.bottom_radius = 0.018
		m_antena.height = 0.48
		m_antena.material = mat_chasis
		var mi_ant = MeshInstance3D.new()
		mi_ant.mesh = m_antena
		mi_ant.position = Vector3(lado * 0.12, 0.24, 0.18)
		mi_ant.rotation_degrees = Vector3(35, lado * 25, lado * 20)
		nodo_cabeza.add_child(mi_ant)

		var m_bulbo_ant = SphereMesh.new()
		m_bulbo_ant.radius = 0.025
		m_bulbo_ant.height = 0.035
		m_bulbo_ant.material = mat_ojos
		var mi_ba = MeshInstance3D.new()
		mi_ba.mesh = m_bulbo_ant
		mi_ba.position = mi_ant.position + Vector3(lado * 0.08, 0.22, 0.12)
		nodo_cabeza.add_child(mi_ba)

	# --- 3. NÚCLEO ABDOMINAL POSTERIOR DE NANITAS ---
	var nodo_abdomen = Node3D.new()
	nodo_abdomen.name = "AbdomenNanitas"
	nodo_abdomen.position = Vector3(0, 0.08, -0.62)
	nodo_cuerpo.add_child(nodo_abdomen)

	var m_nucleo_fluido = SphereMesh.new()
	m_nucleo_fluido.radius = 0.24
	m_nucleo_fluido.height = 0.32
	m_nucleo_fluido.material = mat_nucleo
	var mi_nf = MeshInstance3D.new()
	mi_nf.mesh = m_nucleo_fluido
	nodo_abdomen.add_child(mi_nf)

	var m_vidrio_domo = SphereMesh.new()
	m_vidrio_domo.radius = 0.28
	m_vidrio_domo.height = 0.38
	m_vidrio_domo.material = mat_vidrio
	var mi_vd = MeshInstance3D.new()
	mi_vd.mesh = m_vidrio_domo
	nodo_abdomen.add_child(mi_vd)

	# --- 4. 6 PATAS ARTICULADAS INSECTOIDES (3 POR LADO) ---
	var posiciones_patas_z = [0.32, 0.0, -0.32]
	var angulos_patas_y = [25.0, 0.0, -25.0]

	for i in range(3):
		for lado in [-1, 1]:
			var nodo_pata = Node3D.new()
			nodo_pata.name = "Pata_%d_%s" % [i + 1, "I" if lado < 0 else "D"]
			nodo_pata.position = Vector3(lado * 0.42, -0.05, posiciones_patas_z[i])
			nodo_pata.rotation_degrees = Vector3(0, lado * angulos_patas_y[i], 0)
			nodo_cuerpo.add_child(nodo_pata)

			# Coxa / Rótula de la cadera
			var m_rotula_pata = SphereMesh.new()
			m_rotula_pata.radius = 0.06
			m_rotula_pata.height = 0.08
			m_rotula_pata.material = mat_cromo
			var mi_rp = MeshInstance3D.new()
			mi_rp.mesh = m_rotula_pata
			nodo_pata.add_child(mi_rp)

			# Fémur (hacia arriba y afuera)
			var m_femur = CylinderMesh.new()
			m_femur.top_radius = 0.035
			m_femur.bottom_radius = 0.045
			m_femur.height = 0.38
			m_femur.material = mat_chasis
			var mi_fem = MeshInstance3D.new()
			mi_fem.mesh = m_femur
			mi_fem.position = Vector3(lado * 0.16, 0.12, 0)
			mi_fem.rotation_degrees = Vector3(0, 0, lado * -45)
			nodo_pata.add_child(mi_fem)

			# Rodilla
			var m_rodilla = SphereMesh.new()
			m_rodilla.radius = 0.045
			m_rodilla.height = 0.06
			m_rodilla.material = mat_cromo
			var mi_rod = MeshInstance3D.new()
			mi_rod.mesh = m_rodilla
			mi_rod.position = Vector3(lado * 0.32, 0.24, 0)
			nodo_pata.add_child(mi_rod)

			# Tibia (hacia abajo y clavándose en el suelo)
			var m_tibia = CylinderMesh.new()
			m_tibia.top_radius = 0.015
			m_tibia.bottom_radius = 0.035
			m_tibia.height = 0.65
			m_tibia.material = mat_chasis
			var mi_tib = MeshInstance3D.new()
			mi_tib.mesh = m_tibia
			mi_tib.position = Vector3(lado * 0.48, -0.15, 0)
			mi_tib.rotation_degrees = Vector3(0, 0, lado * 28)
			nodo_pata.add_child(mi_tib)

			# Garra afilada
			var m_garrita = PrismMesh.new()
			m_garrita.size = Vector3(0.04, 0.12, 0.03)
			m_garrita.material = mat_cromo
			var mi_gar = MeshInstance3D.new()
			mi_gar.mesh = m_garrita
			mi_gar.position = Vector3(lado * 0.62, -0.48, 0)
			nodo_pata.add_child(mi_gar)

	# --- 5. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 6. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_parasito_cursor.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Parásito exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_parasito_cursor.glb-0220b8ee5c3e055bff3c4fbfc7cb0fae.scn"
	var err_scn = ResourceSaver.save(pack, scn_path)
	if err_scn == OK:
		print("✓ Escena SCN sincronizada directamente en: ", scn_path)
	else:
		printerr("Error guardando SCN: ", err_scn)

	# Guardar directamente como PackedScene en res://parasito_cursor.tscn
	var err_tscn = ResourceSaver.save(pack, "res://parasito_cursor.tscn")
	if err_tscn == OK:
		print("✓ parasito_cursor.tscn actualizado directamente con el modelo 3D!")
	else:
		printerr("Error guardando parasito_cursor.tscn: ", err_tscn)

	quit(0)

func _fijar_dueno(n: Node, r: Node) -> void:
	for h in n.get_children():
		h.owner = r
		_fijar_dueno(h, r)

