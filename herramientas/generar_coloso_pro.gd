@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: COLOSO DE BRONCE (TITÁN DE BRONCE REMACHADO Y MAGMA)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Armadura de bronce ancestral remachada, grietas de magma incandescente y reactores.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: COLOSO DE BRONCE...")

	var raiz = Node3D.new()
	raiz.name = "jefe_coloso_bronce"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Bronce Remachado Ancestral
	var mat_bronce = StandardMaterial3D.new()
	mat_bronce.albedo_color = Color(0.82, 0.58, 0.22)
	mat_bronce.metallic = 0.90
	mat_bronce.roughness = 0.32
	mat_bronce.rim_enabled = true
	mat_bronce.rim = 0.65
	mat_bronce.rim_tint = 0.4

	# 2. Placas de Hierro Forjado Oscuro y Remaches
	var mat_hierro = StandardMaterial3D.new()
	mat_hierro.albedo_color = Color(0.22, 0.20, 0.18)
	mat_hierro.metallic = 0.88
	mat_hierro.roughness = 0.40

	# 3. Magma Fundido Incandescente (Juntas y Grietas)
	var mat_magma = StandardMaterial3D.new()
	mat_magma.albedo_color = Color(1.0, 0.45, 0.05)
	mat_magma.emission_enabled = true
	mat_magma.emission = Color(1.0, 0.38, 0.02)
	mat_magma.emission_energy_multiplier = 0.92

	# 4. Burbuja Hexagonal de Energía Protectora (Ámbar translúcida sutil)
	var mat_burbuja = StandardMaterial3D.new()
	mat_burbuja.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_burbuja.albedo_color = Color(1.0, 0.65, 0.15, 0.16)
	mat_burbuja.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_burbuja.roughness = 0.1
	mat_burbuja.rim_enabled = true
	mat_burbuja.rim = 0.9
	mat_burbuja.rim_tint = 0.6

	# --- 1. TORSO Y PECHO TITÁNICO DE BRONCE ---
	var nodo_torso = Node3D.new()
	nodo_torso.name = "TorsoColoso"
	nodo_torso.position = Vector3(0, 1.45, 0)
	raiz.add_child(nodo_torso)

	# Caja torácica masiva
	var m_pecho = CylinderMesh.new()
	m_pecho.top_radius = 0.72
	m_pecho.bottom_radius = 0.55
	m_pecho.height = 0.95
	m_pecho.radial_segments = 20
	m_pecho.material = mat_bronce
	var mi_pecho = MeshInstance3D.new()
	mi_pecho.mesh = m_pecho
	nodo_torso.add_child(mi_pecho)

	# Placas pectorales remachadas
	for lado in [-1, 1]:
		var m_placa = BoxMesh.new()
		m_placa.size = Vector3(0.55, 0.45, 0.25)
		m_placa.material = mat_bronce
		var mi_pl = MeshInstance3D.new()
		mi_pl.mesh = m_placa
		mi_pl.position = Vector3(lado * 0.35, 0.22, 0.45)
		mi_pl.rotation_degrees = Vector3(8, lado * -12, 0)
		nodo_torso.add_child(mi_pl)

		# Remaches dorados
		for rx in [-0.18, 0.18]:
			for ry in [-0.14, 0.14]:
				var m_rem = SphereMesh.new()
				m_rem.radius = 0.035
				m_rem.height = 0.045
				m_rem.material = mat_hierro
				var mi_rem = MeshInstance3D.new()
				mi_rem.mesh = m_rem
				mi_rem.position = mi_pl.position + Vector3(rx, ry, 0.14)
				nodo_torso.add_child(mi_rem)

	# Corazón / reactor de magma central
	var m_core = SphereMesh.new()
	m_core.radius = 0.22
	m_core.height = 0.28
	m_core.material = mat_magma
	var mi_core = MeshInstance3D.new()
	mi_core.mesh = m_core
	mi_core.position = Vector3(0, 0.15, 0.52)
	nodo_torso.add_child(mi_core)

	# Reactores de hombro en la espalda
	for lado in [-1, 1]:
		var nodo_reactor = Node3D.new()
		nodo_reactor.position = Vector3(lado * 0.48, 0.65, -0.35)
		nodo_reactor.rotation_degrees = Vector3(-18, lado * 15, 0)
		nodo_torso.add_child(nodo_reactor)

		var m_tubo = CylinderMesh.new()
		m_tubo.top_radius = 0.14
		m_tubo.bottom_radius = 0.16
		m_tubo.height = 0.65
		m_tubo.radial_segments = 16
		m_tubo.material = mat_hierro
		var mi_tubo = MeshInstance3D.new()
		mi_tubo.mesh = m_tubo
		nodo_reactor.add_child(mi_tubo)

		var m_fuego_core = SphereMesh.new()
		m_fuego_core.radius = 0.11
		m_fuego_core.height = 0.12
		m_fuego_core.material = mat_magma
		var mi_fc = MeshInstance3D.new()
		mi_fc.mesh = m_fuego_core
		mi_fc.position = Vector3(0, 0.32, 0)
		nodo_reactor.add_child(mi_fc)

	# --- 2. CABEZA DE MÁSCARA ANCESTRAL DE BRONCE ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaTitan"
	nodo_cabeza.position = Vector3(0, 0.68, 0.22)
	nodo_torso.add_child(nodo_cabeza)

	var m_yelmo = CylinderMesh.new()
	m_yelmo.top_radius = 0.26
	m_yelmo.bottom_radius = 0.32
	m_yelmo.height = 0.48
	m_yelmo.radial_segments = 16
	m_yelmo.material = mat_bronce
	var mi_yel = MeshInstance3D.new()
	mi_yel.mesh = m_yelmo
	nodo_cabeza.add_child(mi_yel)

	# Ojos y hendidura de magma
	var m_visor = BoxMesh.new()
	m_visor.size = Vector3(0.38, 0.08, 0.24)
	m_visor.material = mat_magma
	var mi_vis = MeshInstance3D.new()
	mi_vis.mesh = m_visor
	mi_vis.position = Vector3(0, 0.05, 0.18)
	nodo_cabeza.add_child(mi_vis)

	# --- 3. BRAZOS TITÁNICOS CON GUANTELETES APLASTADORES ---
	for lado in [-1, 1]:
		var nodo_brazo = Node3D.new()
		nodo_brazo.name = "BrazoColoso_" + ("Izq" if lado < 0 else "Der")
		nodo_brazo.position = Vector3(lado * 0.92, 0.35, 0)
		nodo_torso.add_child(nodo_brazo)

		# Hombrera de campana de bronce
		var m_hombrera = SphereMesh.new()
		m_hombrera.radius = 0.44
		m_hombrera.height = 0.58
		m_hombrera.material = mat_bronce
		var mi_hom = MeshInstance3D.new()
		mi_hom.mesh = m_hombrera
		nodo_brazo.add_child(mi_hom)

		# Articulación de magma del hombro
		var m_art_m = SphereMesh.new()
		m_art_m.radius = 0.22
		m_art_m.height = 0.26
		m_art_m.material = mat_magma
		var mi_am = MeshInstance3D.new()
		mi_am.mesh = m_art_m
		mi_am.position = Vector3(0, -0.32, 0)
		nodo_brazo.add_child(mi_am)

		# Antebrazo masivo de bronce
		var m_antebrazo = CylinderMesh.new()
		m_antebrazo.top_radius = 0.32
		m_antebrazo.bottom_radius = 0.38
		m_antebrazo.height = 0.72
		m_antebrazo.material = mat_bronce
		var mi_ant = MeshInstance3D.new()
		mi_ant.mesh = m_antebrazo
		mi_ant.position = Vector3(lado * 0.12, -0.72, 0.18)
		mi_ant.rotation_degrees = Vector3(25, 0, lado * -10)
		nodo_brazo.add_child(mi_ant)

		# Puño de bronce pesado
		var m_puno = BoxMesh.new()
		m_puno.size = Vector3(0.48, 0.48, 0.55)
		m_puno.material = mat_hierro
		var mi_puno = MeshInstance3D.new()
		mi_puno.mesh = m_puno
		mi_puno.position = Vector3(lado * 0.18, -1.18, 0.35)
		nodo_brazo.add_child(mi_puno)

	# --- 4. PIERNAS TRONCÓNICAS DE BRONCE ---
	for lado in [-1, 1]:
		var nodo_pierna = Node3D.new()
		nodo_pierna.name = "PiernaColoso_" + ("Izq" if lado < 0 else "Der")
		nodo_pierna.position = Vector3(lado * 0.48, 0.75, 0)
		raiz.add_child(nodo_pierna)

		var m_muslo = CylinderMesh.new()
		m_muslo.top_radius = 0.36
		m_muslo.bottom_radius = 0.42
		m_muslo.height = 0.65
		m_muslo.material = mat_bronce
		var mi_mus = MeshInstance3D.new()
		mi_mus.mesh = m_muslo
		mi_mus.position = Vector3(0, -0.25, 0)
		nodo_pierna.add_child(mi_mus)

		var m_pie = BoxMesh.new()
		m_pie.size = Vector3(0.55, 0.32, 0.75)
		m_pie.material = mat_hierro
		var mi_pie = MeshInstance3D.new()
		mi_pie.mesh = m_pie
		mi_pie.position = Vector3(0, -0.68, 0.12)
		nodo_pierna.add_child(mi_pie)

	# --- 5. BURBUJA HEXAGONAL DE ENERGÍA TITÁNICA ---
	var m_esfera_burbuja = SphereMesh.new()
	m_esfera_burbuja.radius = 1.95
	m_esfera_burbuja.height = 3.9
	m_esfera_burbuja.radial_segments = 32
	m_esfera_burbuja.rings = 16
	m_esfera_burbuja.material = mat_burbuja
	var mi_burbuja = MeshInstance3D.new()
	mi_burbuja.name = "BurbujaHexagonal"
	mi_burbuja.mesh = m_esfera_burbuja
	raiz.add_child(mi_burbuja)

	# --- 6. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 7. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/jefe_coloso_bronce.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Coloso de Bronce exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/jefe_coloso_bronce.glb-cf960907254f1b6a35eab02ec43f6619.scn"
	var err_scn = ResourceSaver.save(pack, scn_path)
	if err_scn == OK:
		print("✓ Escena SCN sincronizada directamente en: ", scn_path)
	else:
		printerr("Error guardando SCN: ", err_scn)

	quit(0)

func _fijar_dueno(n: Node, r: Node) -> void:
	for h in n.get_children():
		h.owner = r
		_fijar_dueno(h, r)

