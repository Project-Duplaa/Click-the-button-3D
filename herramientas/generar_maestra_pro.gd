@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: MAESTRA SANGUINARIA (DUELISTA VAMPÍRICA GÓTICA)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Duelista esbelta, máscara de porcelana, alas espinosas de murciélago y estoque de rubí.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: MAESTRA SANGUINARIA...")

	var raiz = Node3D.new()
	raiz.name = "jefe_maestra_sanguinaria"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Armadura de Obsidiana y Cuero Gótico
	var mat_cuero_negro = StandardMaterial3D.new()
	mat_cuero_negro.albedo_color = Color(0.12, 0.12, 0.14)
	mat_cuero_negro.metallic = 0.82
	mat_cuero_negro.roughness = 0.25
	mat_cuero_negro.rim_enabled = true
	mat_cuero_negro.rim = 0.7
	mat_cuero_negro.rim_tint = 0.4

	# 2. Terciopelo Carmesí Imperial
	var mat_terciopelo = StandardMaterial3D.new()
	mat_terciopelo.albedo_color = Color(0.72, 0.08, 0.18)
	mat_terciopelo.roughness = 0.42
	mat_terciopelo.rim_enabled = true
	mat_terciopelo.rim = 0.8
	mat_terciopelo.rim_tint = 0.6

	# 3. Filigrana de Oro Viejo
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.88, 0.68, 0.22)
	mat_oro.metallic = 0.95
	mat_oro.roughness = 0.26

	# 4. Máscara de Porcelana Blanca
	var mat_mascara = StandardMaterial3D.new()
	mat_mascara.albedo_color = Color(0.94, 0.92, 0.90)
	mat_mascara.roughness = 0.18
	mat_mascara.rim_enabled = true
	mat_mascara.rim = 0.5

	# 5. Membrana Alar Translúcida Carmesí (Alas de Murciélago Espinosas)
	var mat_ala_membrana = StandardMaterial3D.new()
	mat_ala_membrana.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_ala_membrana.albedo_color = Color(0.85, 0.08, 0.22, 0.68)
	mat_ala_membrana.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_ala_membrana.roughness = 0.22
	mat_ala_membrana.emission_enabled = true
	mat_ala_membrana.emission = Color(0.65, 0.05, 0.15)
	mat_ala_membrana.emission_energy_multiplier = 0.75
	mat_ala_membrana.rim_enabled = true
	mat_ala_membrana.rim = 0.85

	# 6. Cristal de Rubí para el Estoque y Gemas
	var mat_rubi = StandardMaterial3D.new()
	mat_rubi.albedo_color = Color(1.0, 0.12, 0.28, 0.9)
	mat_rubi.metallic = 0.2
	mat_rubi.roughness = 0.14
	mat_rubi.emission_enabled = true
	mat_rubi.emission = Color(0.95, 0.1, 0.22)
	mat_rubi.emission_energy_multiplier = 0.85
	mat_rubi.rim_enabled = true
	mat_rubi.rim = 0.9

	# --- 1. TORSO Y SILUETA HUMANOIDE ESBELTA ---
	var nodo_torso = Node3D.new()
	nodo_torso.name = "TorsoDuelista"
	nodo_torso.position = Vector3(0, 1.25, 0)
	nodo_torso.rotation_degrees = Vector3(5, -12, 0)
	raiz.add_child(nodo_torso)

	# Corsé entallado carmesí
	var m_corse = CapsuleMesh.new()
	m_corse.radius = 0.22
	m_corse.height = 0.68
	m_corse.radial_segments = 24
	m_corse.material = mat_terciopelo
	var mi_corse = MeshInstance3D.new()
	mi_corse.mesh = m_corse
	mi_corse.scale = Vector3(1.1, 1.0, 0.85)
	nodo_torso.add_child(mi_corse)

	# Placas de armadura sobre el pecho y cinturón dorado
	var m_placa_pecho = BoxMesh.new()
	m_placa_pecho.size = Vector3(0.32, 0.24, 0.22)
	m_placa_pecho.material = mat_cuero_negro
	var mi_placa = MeshInstance3D.new()
	mi_placa.mesh = m_placa_pecho
	mi_placa.position = Vector3(0, 0.14, 0.1)
	nodo_torso.add_child(mi_placa)

	var m_cinturon = TorusMesh.new()
	m_cinturon.inner_radius = 0.18
	m_cinturon.outer_radius = 0.24
	m_cinturon.material = mat_oro
	var mi_cin = MeshInstance3D.new()
	mi_cin.mesh = m_cinturon
	mi_cin.position = Vector3(0, -0.15, 0)
	mi_cin.scale = Vector3(1.15, 0.6, 0.95)
	nodo_torso.add_child(mi_cin)

	# Cuello alto gótico / esclavina
	var m_cuello = CylinderMesh.new()
	m_cuello.top_radius = 0.24
	m_cuello.bottom_radius = 0.16
	m_cuello.height = 0.22
	m_cuello.material = mat_terciopelo
	var mi_cuello = MeshInstance3D.new()
	mi_cuello.mesh = m_cuello
	mi_cuello.position = Vector3(0, 0.38, -0.05)
	nodo_torso.add_child(mi_cuello)

	# --- 2. CABEZA, MÁSCARA DE PORCELANA Y TIARA DE ESPINAS ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaVampirica"
	nodo_cabeza.position = Vector3(0, 0.54, 0.05)
	nodo_torso.add_child(nodo_cabeza)

	var m_cabeza = SphereMesh.new()
	m_cabeza.radius = 0.15
	m_cabeza.height = 0.22
	m_cabeza.material = mat_mascara
	var mi_cab = MeshInstance3D.new()
	mi_cab.mesh = m_cabeza
	nodo_cabeza.add_child(mi_cab)

	# Tiara gótica de espinas de oro y rubí
	var m_tiara = TorusMesh.new()
	m_tiara.inner_radius = 0.12
	m_tiara.outer_radius = 0.16
	m_tiara.material = mat_oro
	var mi_tia = MeshInstance3D.new()
	mi_tia.mesh = m_tiara
	mi_tia.position = Vector3(0, 0.08, 0)
	nodo_cabeza.add_child(mi_tia)

	for p in range(5):
		var ang_p = (p - 2) * 22.0
		var m_pincho = CylinderMesh.new()
		m_pincho.top_radius = 0.005
		m_pincho.bottom_radius = 0.02
		m_pincho.height = 0.18 - (abs(p - 2) * 0.03)
		m_pincho.material = mat_rubi
		var mi_pin = MeshInstance3D.new()
		mi_pin.mesh = m_pincho
		mi_pin.position = Vector3(sin(deg_to_rad(ang_p)) * 0.14, 0.14, cos(deg_to_rad(ang_p)) * 0.14)
		mi_pin.rotation_degrees = Vector3(15, 0, -ang_p)
		nodo_cabeza.add_child(mi_pin)

	# --- 3. ALAS ESPINOSAS DE MURCIÉLAGO 3D (Extensión alar imponente) ---
	for lado in [-1, 1]:
		var nodo_ala = Node3D.new()
		nodo_ala.name = "Ala_" + ("Izq" if lado < 0 else "Der")
		nodo_ala.position = Vector3(lado * 0.18, 0.22, -0.15)
		nodo_ala.rotation_degrees = Vector3(15, lado * -35, lado * -18)
		nodo_torso.add_child(nodo_ala)

		# Hueso principal del ala (brazo alar)
		var m_brazo_alar = CylinderMesh.new()
		m_brazo_alar.top_radius = 0.03
		m_brazo_alar.bottom_radius = 0.045
		m_brazo_alar.height = 0.75
		m_brazo_alar.material = mat_cuero_negro
		var mi_bal = MeshInstance3D.new()
		mi_bal.mesh = m_brazo_alar
		mi_bal.position = Vector3(lado * 0.32, 0.35, -0.05)
		mi_bal.rotation_degrees = Vector3(0, 0, lado * -50)
		nodo_ala.add_child(mi_bal)

		# Rótula y espina articular
		var m_articulacion = SphereMesh.new()
		m_articulacion.radius = 0.06
		m_articulacion.height = 0.08
		m_articulacion.material = mat_oro
		var mi_art = MeshInstance3D.new()
		mi_art.mesh = m_articulacion
		mi_art.position = Vector3(lado * 0.62, 0.58, -0.08)
		nodo_ala.add_child(mi_art)

		# 3 Dedos espinosos articulados que tensan la membrana
		var def_dedos = [
			{"rot": Vector3(10, 0, lado * 25), "len": 0.85, "off": Vector3(lado * 0.35, -0.32, 0)},
			{"rot": Vector3(0, 0, lado * 55), "len": 0.72, "off": Vector3(lado * 0.52, -0.22, 0)},
			{"rot": Vector3(-15, 0, lado * 80), "len": 0.58, "off": Vector3(lado * 0.65, -0.08, 0)}
		]
		for d in def_dedos:
			var m_falange = CylinderMesh.new()
			m_falange.top_radius = 0.015
			m_falange.bottom_radius = 0.03
			m_falange.height = d["len"]
			m_falange.material = mat_cuero_negro
			var mi_fal = MeshInstance3D.new()
			mi_fal.mesh = m_falange
			mi_fal.position = mi_art.position + d["off"]
			mi_fal.rotation_degrees = d["rot"]
			nodo_ala.add_child(mi_fal)

		# Velos / membranas alares carmesí (Placas con volumen biselado)
		var m_vela = BoxMesh.new()
		m_vela.size = Vector3(0.72, 0.55, 0.02)
		m_vela.material = mat_ala_membrana
		var mi_vela = MeshInstance3D.new()
		mi_vela.mesh = m_vela
		mi_vela.position = Vector3(lado * 0.58, 0.22, -0.06)
		mi_vela.rotation_degrees = Vector3(5, lado * 10, lado * -15)
		nodo_ala.add_child(mi_vela)

	# --- 4. FALDONES Y VESTIDO GÓTICO FLOTANTE ---
	var m_faldon = CylinderMesh.new()
	m_faldon.top_radius = 0.22
	m_faldon.bottom_radius = 0.42
	m_faldon.height = 0.85
	m_faldon.radial_segments = 20
	m_faldon.material = mat_cuero_negro
	var mi_fal = MeshInstance3D.new()
	mi_fal.mesh = m_faldon
	mi_fal.position = Vector3(0, -0.55, 0)
	nodo_torso.add_child(mi_fal)

	# Abertura frontal con terciopelo interior
	var m_abertura = BoxMesh.new()
	m_abertura.size = Vector3(0.18, 0.82, 0.32)
	m_abertura.material = mat_terciopelo
	var mi_abe = MeshInstance3D.new()
	mi_abe.mesh = m_abertura
	mi_abe.position = Vector3(0, -0.55, 0.22)
	nodo_torso.add_child(mi_abe)

	# --- 5. BRAZOS Y ESTOQUE DE SANGRE CRISTALINO (RAPIER) ---
	var nodo_brazo_arma = Node3D.new()
	nodo_brazo_arma.name = "BrazoEstoque"
	nodo_brazo_arma.position = Vector3(0.32, 0.18, 0.12)
	nodo_brazo_arma.rotation_degrees = Vector3(-20, 25, 0)
	nodo_torso.add_child(nodo_brazo_arma)

	var m_antebrazo = CylinderMesh.new()
	m_antebrazo.top_radius = 0.06
	m_antebrazo.bottom_radius = 0.08
	m_antebrazo.height = 0.52
	m_antebrazo.material = mat_terciopelo
	var mi_ant = MeshInstance3D.new()
	mi_ant.mesh = m_antebrazo
	mi_ant.position = Vector3(0, -0.22, 0.15)
	mi_ant.rotation_degrees = Vector3(45, 0, 0)
	nodo_brazo_arma.add_child(mi_ant)

	# Guantelete de esgrima negro
	var m_guante = SphereMesh.new()
	m_guante.radius = 0.09
	m_guante.height = 0.12
	m_guante.material = mat_cuero_negro
	var mi_gua = MeshInstance3D.new()
	mi_gua.mesh = m_guante
	mi_gua.position = Vector3(0, -0.42, 0.35)
	nodo_brazo_arma.add_child(mi_gua)

	# Cazoleta / guarnición del estoque de rubí
	var nodo_espada = Node3D.new()
	nodo_espada.position = mi_gua.position
	nodo_espada.rotation_degrees = Vector3(75, 10, 0)
	nodo_brazo_arma.add_child(nodo_espada)

	var m_guarnicion = SphereMesh.new()
	m_guarnicion.radius = 0.14
	m_guarnicion.height = 0.12
	m_guarnicion.material = mat_oro
	var mi_guar = MeshInstance3D.new()
	mi_guar.mesh = m_guarnicion
	nodo_espada.add_child(mi_guar)

	# Hoja del estoque de rubí flamígero
	var m_hoja = CylinderMesh.new()
	m_hoja.top_radius = 0.006
	m_hoja.bottom_radius = 0.025
	m_hoja.height = 1.35
	m_hoja.radial_segments = 12
	m_hoja.material = mat_rubi
	var mi_hoja = MeshInstance3D.new()
	mi_hoja.mesh = m_hoja
	mi_hoja.position = Vector3(0, 0.72, 0)
	nodo_espada.add_child(mi_hoja)

	# --- 6. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 7. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/jefe_maestra_sanguinaria.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Maestra exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/jefe_maestra_sanguinaria.glb-3333dff899046a5e01ea9ec19c425a1f.scn"
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
