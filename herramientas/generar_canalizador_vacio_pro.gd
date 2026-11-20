@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: CANALIZADOR DEL VACÍO (PILAR DE INVOCACIÓN / ANCLA GRAVITATORIA)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Obelisco eldritch de obsidiana, 4 pilares de contención, singularidad cósmica y anillos orbitales.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: CANALIZADOR DEL VACÍO...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_canalizador_vacio"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Obsidiana Abisal (Base, Estructura, Pilares)
	var mat_obsidiana = StandardMaterial3D.new()
	mat_obsidiana.albedo_color = Color(0.14, 0.11, 0.20)
	mat_obsidiana.metallic = 0.35
	mat_obsidiana.roughness = 0.38
	mat_obsidiana.rim_enabled = true
	mat_obsidiana.rim = 0.70
	mat_obsidiana.rim_tint = 0.45

	# 2. Hierro Rúnico Oscuro (Cinchas, Remaches, Marcos)
	var mat_hierro = StandardMaterial3D.new()
	mat_hierro.albedo_color = Color(0.22, 0.18, 0.30)
	mat_hierro.metallic = 0.88
	mat_hierro.roughness = 0.30

	# 3. Plasma del Vacío (Runas, Glifos Púrpuras)
	var mat_plasma_purpura = StandardMaterial3D.new()
	mat_plasma_purpura.albedo_color = Color(0.75, 0.22, 0.98)
	mat_plasma_purpura.emission_enabled = true
	mat_plasma_purpura.emission = Color(0.72, 0.18, 0.95)
	mat_plasma_purpura.emission_energy_multiplier = 0.90

	# 4. Singularidad Cósmica y Disco de Acreción (Cian / Turquesa Eléctrico)
	var mat_singularidad_cian = StandardMaterial3D.new()
	mat_singularidad_cian.albedo_color = Color(0.30, 0.95, 1.0)
	mat_singularidad_cian.emission_enabled = true
	mat_singularidad_cian.emission = Color(0.25, 0.90, 1.0)
	mat_singularidad_cian.emission_energy_multiplier = 0.95

	# 5. Núcleo Oscuro (Agujero Negro Central)
	var mat_nucleo_negro = StandardMaterial3D.new()
	mat_nucleo_negro.albedo_color = Color(0.04, 0.02, 0.08)
	mat_nucleo_negro.metallic = 0.95
	mat_nucleo_negro.roughness = 0.08

	# 6. Cristal de Vacío Translúcido
	var mat_cristal = StandardMaterial3D.new()
	mat_cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cristal.albedo_color = Color(0.60, 0.18, 0.90, 0.82)
	mat_cristal.roughness = 0.15
	mat_cristal.emission_enabled = true
	mat_cristal.emission = Color(0.55, 0.15, 0.85)
	mat_cristal.emission_energy_multiplier = 0.65

	# --- 1. ALTAR Y PEDESTAL ESCALONADO HEXAGONAL ---
	var nodo_base = Node3D.new()
	nodo_base.name = "AltarBase"
	raiz.add_child(nodo_base)

	# Nivel 1 (plataforma inferior ancha)
	var m_base1 = CylinderMesh.new()
	m_base1.top_radius = 0.82
	m_base1.bottom_radius = 0.94
	m_base1.height = 0.18
	m_base1.radial_segments = 6
	m_base1.material = mat_obsidiana
	var mi_b1 = MeshInstance3D.new()
	mi_b1.mesh = m_base1
	mi_b1.position = Vector3(0, 0.09, 0)
	nodo_base.add_child(mi_b1)

	# Nivel 2 (plataforma intermedia con moldura de hierro)
	var m_base2 = CylinderMesh.new()
	m_base2.top_radius = 0.68
	m_base2.bottom_radius = 0.76
	m_base2.height = 0.16
	m_base2.radial_segments = 6
	m_base2.material = mat_hierro
	var mi_b2 = MeshInstance3D.new()
	mi_b2.mesh = m_base2
	mi_b2.position = Vector3(0, 0.25, 0)
	nodo_base.add_child(mi_b2)

	# Anillo rúnico concéntrico sobre el pedestal
	var m_aro_ped = TorusMesh.new()
	m_aro_ped.inner_radius = 0.52
	m_aro_ped.outer_radius = 0.62
	m_aro_ped.material = mat_plasma_purpura
	var mi_ap = MeshInstance3D.new()
	mi_ap.mesh = m_aro_ped
	mi_ap.position = Vector3(0, 0.33, 0)
	nodo_base.add_child(mi_ap)

	# --- 2. 4 PILARES MONOLÍTICOS DE CONTENCIÓN (GÓTICO/ELDRITCH) ---
	var nodo_pilares = Node3D.new()
	nodo_pilares.name = "PilaresContencion"
	nodo_pilares.position = Vector3(0, 0.35, 0)
	raiz.add_child(nodo_pilares)

	# 4 pilares dispuestos en cruz cuadrangular envolviendo la singularidad
	for p in range(4):
		var ang = p * (PI * 0.5)
		var nodo_pilar_ind = Node3D.new()
		nodo_pilar_ind.name = "Pilar_%d" % p
		nodo_pilar_ind.position = Vector3(cos(ang) * 0.46, 0, sin(ang) * 0.46)
		nodo_pilar_ind.rotation_degrees = Vector3(0, rad_to_deg(-ang), 0)
		nodo_pilares.add_child(nodo_pilar_ind)

		# Columna inferior del pilar
		var m_col_inf = CylinderMesh.new()
		m_col_inf.top_radius = 0.12
		m_col_inf.bottom_radius = 0.16
		m_col_inf.height = 0.85
		m_col_inf.radial_segments = 6
		m_col_inf.material = mat_obsidiana
		var mi_ci = MeshInstance3D.new()
		mi_ci.mesh = m_col_inf
		mi_ci.position = Vector3(0, 0.42, 0)
		nodo_pilar_ind.add_child(mi_ci)

		# Faja metálica con remaches en el medio del pilar
		var m_faja = BoxMesh.new()
		m_faja.size = Vector3(0.28, 0.10, 0.28)
		m_faja.material = mat_hierro
		var mi_faja = MeshInstance3D.new()
		mi_faja.mesh = m_faja
		mi_faja.position = Vector3(0, 0.85, 0)
		nodo_pilar_ind.add_child(mi_faja)

		# Codo / Pilar superior curvado hacia adentro para abrazar el orbe
		var m_col_sup = CylinderMesh.new()
		m_col_sup.top_radius = 0.08
		m_col_sup.bottom_radius = 0.12
		m_col_sup.height = 0.80
		m_col_sup.radial_segments = 6
		m_col_sup.material = mat_obsidiana
		var mi_cs = MeshInstance3D.new()
		mi_cs.mesh = m_col_sup
		mi_cs.position = Vector3(-0.06, 1.25, 0)
		mi_cs.rotation_degrees = Vector3(0, 0, 10)
		nodo_pilar_ind.add_child(mi_cs)

		# Punta afilada gótica en el remate del pilar
		var m_punta = PrismMesh.new()
		m_punta.size = Vector3(0.14, 0.32, 0.14)
		m_punta.material = mat_hierro
		var mi_pu = MeshInstance3D.new()
		mi_pu.mesh = m_punta
		mi_pu.position = Vector3(-0.12, 1.74, 0)
		nodo_pilar_ind.add_child(mi_pu)

		# Cristal de vacío resonante en la punta
		var m_gem_pilar = SphereMesh.new()
		m_gem_pilar.radius = 0.06
		m_gem_pilar.height = 0.10
		m_gem_pilar.radial_segments = 6
		m_gem_pilar.rings = 3
		m_gem_pilar.material = mat_cristal
		var mi_gp = MeshInstance3D.new()
		mi_gp.mesh = m_gem_pilar
		mi_gp.position = Vector3(-0.12, 1.94, 0)
		nodo_pilar_ind.add_child(mi_gp)

		# Estandarte etéreo púrpura que cuelga del pilar hacia el suelo
		var m_banner = BoxMesh.new()
		m_banner.size = Vector3(0.015, 0.75, 0.18)
		m_banner.material = mat_plasma_purpura
		var mi_ban = MeshInstance3D.new()
		mi_ban.mesh = m_banner
		mi_ban.position = Vector3(0.08, 0.55, 0)
		nodo_pilar_ind.add_child(mi_ban)

	# --- 3. SINGULARIDAD CÓSMICA / ORBE DEL VACÍO CLICABLE ---
	var nodo_singularidad = Node3D.new()
	nodo_singularidad.name = "SingularidadVacio"
	nodo_singularidad.position = Vector3(0, 1.85, 0)
	raiz.add_child(nodo_singularidad)

	# Agujero negro central súper denso
	var m_agujero_negro = SphereMesh.new()
	m_agujero_negro.radius = 0.28
	m_agujero_negro.height = 0.56
	m_agujero_negro.radial_segments = 24
	m_agujero_negro.rings = 16
	m_agujero_negro.material = mat_nucleo_negro
	var mi_an = MeshInstance3D.new()
	mi_an.name = "NucleoSingularidad"
	mi_an.mesh = m_agujero_negro
	nodo_singularidad.add_child(mi_an)

	# Velo de plasma etéreo exterior pulsante (Halo cian)
	var m_halo = SphereMesh.new()
	m_halo.radius = 0.35
	m_halo.height = 0.70
	m_halo.radial_segments = 24
	m_halo.rings = 16
	m_halo.material = mat_singularidad_cian
	var mi_halo = MeshInstance3D.new()
	mi_halo.mesh = m_halo
	nodo_singularidad.add_child(mi_halo)

	# Disco de acreción estelar plano
	var m_acrecion = TorusMesh.new()
	m_acrecion.inner_radius = 0.38
	m_acrecion.outer_radius = 0.52
	m_acrecion.material = mat_plasma_purpura
	var mi_acr = MeshInstance3D.new()
	mi_acr.mesh = m_acrecion
	mi_acr.rotation_degrees = Vector3(22, 0, 15)
	nodo_singularidad.add_child(mi_acr)

	# Anillo orbital giroscópico perpendicular
	var m_acrecion_2 = TorusMesh.new()
	m_acrecion_2.inner_radius = 0.44
	m_acrecion_2.outer_radius = 0.49
	m_acrecion_2.material = mat_singularidad_cian
	var mi_acr2 = MeshInstance3D.new()
	mi_acr2.mesh = m_acrecion_2
	mi_acr2.rotation_degrees = Vector3(-60, 45, -30)
	nodo_singularidad.add_child(mi_acr2)

	# 3 Fragmentos de cristal de vacío en órbita
	for k in range(3):
		var k_ang = k * (TAU / 3.0)
		var m_shard = PrismMesh.new()
		m_shard.size = Vector3(0.10, 0.22, 0.08)
		m_shard.material = mat_cristal
		var mi_sh = MeshInstance3D.new()
		mi_sh.mesh = m_shard
		mi_sh.position = Vector3(cos(k_ang) * 0.62, sin(k_ang) * 0.12, sin(k_ang) * 0.62)
		mi_sh.rotation_degrees = Vector3(25, rad_to_deg(-k_ang) + 45, 15)
		nodo_singularidad.add_child(mi_sh)

	# --- 4. FIJAR DUEÑO RECURSIVO ---
	_fijar_dueno(raiz, raiz)

	# --- 5. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_canalizador_vacio.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Canalizador del Vacío exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_canalizador_vacio.glb-df5ec2b4ef647660ea9d8e578fae3f16.scn"
	ResourceSaver.save(pack, scn_path)

	# Actualizar canalizador_vacio.tscn
	var tscn_path = "res://canalizador_vacio.tscn"
	var pack_tscn = PackedScene.new()
	pack_tscn.pack(raiz)
	var err_tscn = ResourceSaver.save(pack_tscn, tscn_path)
	if err_tscn == OK:
		print("✓ Escena canalizador_vacio.tscn actualizada con el nuevo modelo 3D")

	quit(0)

func _fijar_dueno(n: Node, r: Node):
	for c in n.get_children():
		c.owner = r
		_fijar_dueno(c, r)
