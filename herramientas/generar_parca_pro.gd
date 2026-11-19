@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: LA PARCA ROJA (SENTENCIA SUPREMA - JEFE FINAL)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Espectro encapuchado majestuoso, costillar gótico, gran guadaña de sangre 3D y anillos.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: LA PARCA ROJA...")

	var raiz = Node3D.new()
	raiz.name = "jefe_parca_roja"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Hábito / Capucha Carmesí Oscuro
	var mat_habito = StandardMaterial3D.new()
	mat_habito.albedo_color = Color(0.55, 0.05, 0.12)
	mat_habito.roughness = 0.55
	mat_habito.metallic = 0.12
	mat_habito.rim_enabled = true
	mat_habito.rim = 0.75
	mat_habito.rim_tint = 0.5

	# 2. Interior de la Capucha / Sombras del Vacío
	var mat_sombra_interior = StandardMaterial3D.new()
	mat_sombra_interior.albedo_color = Color(0.04, 0.04, 0.05)
	mat_sombra_interior.roughness = 0.85

	# 3. Armadura de Hueso y Costillar Esquelético
	var mat_hueso = StandardMaterial3D.new()
	mat_hueso.albedo_color = Color(0.88, 0.86, 0.80)
	mat_hueso.roughness = 0.32
	mat_hueso.metallic = 0.15
	mat_hueso.rim_enabled = true
	mat_hueso.rim = 0.6

	# 4. Oro Antiguo de las Coronas y Ribetes
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.85, 0.68, 0.22)
	mat_oro.metallic = 0.95
	mat_oro.roughness = 0.25

	# 5. Ojos y Núcleo de Alma Carmesí Incandescente
	var mat_alma_fuego = StandardMaterial3D.new()
	mat_alma_fuego.albedo_color = Color(1.0, 0.15, 0.2)
	mat_alma_fuego.emission_enabled = true
	mat_alma_fuego.emission = Color(1.0, 0.1, 0.18)
	mat_alma_fuego.emission_energy_multiplier = 0.95

	# 6. Cristal de Rubí para la Hoja de la Guadaña
	var mat_hoja_guadana = StandardMaterial3D.new()
	mat_hoja_guadana.albedo_color = Color(0.95, 0.08, 0.22, 0.92)
	mat_hoja_guadana.metallic = 0.25
	mat_hoja_guadana.roughness = 0.12
	mat_hoja_guadana.emission_enabled = true
	mat_hoja_guadana.emission = Color(0.85, 0.06, 0.18)
	mat_hoja_guadana.emission_energy_multiplier = 0.85
	mat_hoja_guadana.rim_enabled = true
	mat_hoja_guadana.rim = 0.9

	# 7. Astil de Ébano y Metal Oscuro
	var mat_astil = StandardMaterial3D.new()
	mat_astil.albedo_color = Color(0.18, 0.16, 0.18)
	mat_astil.metallic = 0.8
	mat_astil.roughness = 0.35

	# 8. Barrera Espectral Geodésica (Translúcida y Delicada)
	var mat_barrera = StandardMaterial3D.new()
	mat_barrera.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_barrera.albedo_color = Color(0.85, 0.1, 0.35, 0.14)
	mat_barrera.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_barrera.roughness = 0.1
	mat_barrera.rim_enabled = true
	mat_barrera.rim = 0.95
	mat_barrera.rim_tint = 0.7

	# 9. Anillos Rúnicos Orbitales (Magenta / Cian Neón Sutil, sin quemado blanco)
	var mat_anillo_runico = StandardMaterial3D.new()
	mat_anillo_runico.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_anillo_runico.albedo_color = Color(0.95, 0.15, 0.65, 0.75)
	mat_anillo_runico.emission_enabled = true
	mat_anillo_runico.emission = Color(0.9, 0.1, 0.55)
	mat_anillo_runico.emission_energy_multiplier = 0.85

	# --- 1. FIGURA ESPECTRAL: CAPUCHA Y TORSO SUSPENDIDO ---
	var nodo_cuerpo = Node3D.new()
	nodo_cuerpo.name = "CuerpoEspectral"
	nodo_cuerpo.position = Vector3(0, 1.45, 0)
	raiz.add_child(nodo_cuerpo)

	# Capucha cavernosa profunda
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.position = Vector3(0, 0.55, 0.05)
	nodo_cuerpo.add_child(nodo_cabeza)

	var m_capucha_ext = SphereMesh.new()
	m_capucha_ext.radius = 0.28
	m_capucha_ext.height = 0.42
	m_capucha_ext.material = mat_habito
	var mi_cap_ext = MeshInstance3D.new()
	mi_cap_ext.mesh = m_capucha_ext
	mi_cap_ext.scale = Vector3(1.0, 1.15, 1.25)
	nodo_cabeza.add_child(mi_cap_ext)

	# Cavidad oscura interior de la capucha
	var m_cavidad = SphereMesh.new()
	m_cavidad.radius = 0.22
	m_cavidad.height = 0.32
	m_cavidad.material = mat_sombra_interior
	var mi_cav = MeshInstance3D.new()
	mi_cav.mesh = m_cavidad
	mi_cav.position = Vector3(0, -0.04, 0.12)
	nodo_cabeza.add_child(mi_cav)

	# Máscara esquelética de calavera asomando
	var m_craneo = SphereMesh.new()
	m_craneo.radius = 0.12
	m_craneo.height = 0.18
	m_craneo.material = mat_hueso
	var mi_cra = MeshInstance3D.new()
	mi_cra.mesh = m_craneo
	mi_cra.position = Vector3(0, -0.06, 0.14)
	nodo_cabeza.add_child(mi_cra)

	# Ojos incandescentes de fuego carmesí
	for lado in [-1, 1]:
		var m_ojo = SphereMesh.new()
		m_ojo.radius = 0.035
		m_ojo.height = 0.05
		m_ojo.material = mat_alma_fuego
		var mi_ojo = MeshInstance3D.new()
		mi_ojo.mesh = m_ojo
		mi_ojo.position = Vector3(lado * 0.065, -0.04, 0.24)
		nodo_cabeza.add_child(mi_ojo)

	# Corona espectral de puntas doradas
	var m_corona = TorusMesh.new()
	m_corona.inner_radius = 0.22
	m_corona.outer_radius = 0.28
	m_corona.material = mat_oro
	var mi_cor = MeshInstance3D.new()
	mi_cor.mesh = m_corona
	mi_cor.position = Vector3(0, 0.22, 0.02)
	nodo_cabeza.add_child(mi_cor)

	# --- 2. PECHO GÓTICO: COSTILLAR ESQUELÉTICO Y CORAZÓN DE ALMA ---
	var m_torso = CylinderMesh.new()
	m_torso.top_radius = 0.32
	m_torso.bottom_radius = 0.24
	m_torso.height = 0.65
	m_torso.material = mat_habito
	var mi_tor = MeshInstance3D.new()
	mi_tor.mesh = m_torso
	nodo_cuerpo.add_child(mi_tor)

	# Costillas de hueso talladas en el pecho
	for r in range(4):
		var y_costilla = 0.18 - (r * 0.12)
		var rad_cost = 0.32 - (r * 0.025)
		var m_costilla = TorusMesh.new()
		m_costilla.inner_radius = rad_cost * 0.8
		m_costilla.outer_radius = rad_cost * 1.08
		m_costilla.material = mat_hueso
		var mi_cos = MeshInstance3D.new()
		mi_cos.mesh = m_costilla
		mi_cos.position = Vector3(0, y_costilla, 0.04)
		mi_cos.scale = Vector3(1.1, 0.45, 0.95)
		nodo_cuerpo.add_child(mi_cos)

	# Núcleo de alma carmesí brillando en el centro del pecho
	var m_nucleo_alma = SphereMesh.new()
	m_nucleo_alma.radius = 0.11
	m_nucleo_alma.height = 0.15
	m_nucleo_alma.material = mat_alma_fuego
	var mi_nuc = MeshInstance3D.new()
	mi_nuc.mesh = m_nucleo_alma
	mi_nuc.position = Vector3(0, 0.06, 0.22)
	nodo_cuerpo.add_child(mi_nuc)

	# Faldón inferior y tentáculos de sombra espectral (suspendidos en el aire)
	var m_manto_inf = CylinderMesh.new()
	m_manto_inf.top_radius = 0.25
	m_manto_inf.bottom_radius = 0.42
	m_manto_inf.height = 0.95
	m_manto_inf.material = mat_habito
	var mi_man = MeshInstance3D.new()
	mi_man.mesh = m_manto_inf
	mi_man.position = Vector3(0, -0.65, 0)
	nodo_cuerpo.add_child(mi_man)

	# 5 Tentáculos de sombra inferiores curvados
	for t in range(5):
		var ang_t = t * (PI * 2.0 / 5.0)
		var m_tent = CylinderMesh.new()
		m_tent.top_radius = 0.08
		m_tent.bottom_radius = 0.015
		m_tent.height = 0.72
		m_tent.material = mat_habito
		var mi_tent = MeshInstance3D.new()
		mi_tent.mesh = m_tent
		mi_tent.position = Vector3(cos(ang_t) * 0.28, -1.25, sin(ang_t) * 0.28)
		mi_tent.rotation_degrees = Vector3(sin(ang_t) * 25.0, 0, -cos(ang_t) * 25.0)
		nodo_cuerpo.add_child(mi_tent)

	# --- 3. HOMBROS Y BRAZOS SOSTENIENDO LA GRAN GUADAÑA CARMESÍ ---
	var nodo_guadana = Node3D.new()
	nodo_guadana.name = "GranGuadanaSangre"
	nodo_guadana.position = Vector3(0.48, 0.15, 0.25)
	nodo_guadana.rotation_degrees = Vector3(-15, 30, -25)
	nodo_cuerpo.add_child(nodo_guadana)

	# Astil largo de ébano reforzado
	var m_astil_g = CylinderMesh.new()
	m_astil_g.top_radius = 0.04
	m_astil_g.bottom_radius = 0.045
	m_astil_g.height = 2.5
	m_astil_g.material = mat_astil
	var mi_astil = MeshInstance3D.new()
	mi_astil.mesh = m_astil_g
	nodo_guadana.add_child(mi_astil)

	# Aros dorados decorativos a lo largo del astil
	for pos_y in [-0.9, -0.3, 0.4, 0.9, 1.15]:
		var m_aro_a = TorusMesh.new()
		m_aro_a.inner_radius = 0.042
		m_aro_a.outer_radius = 0.065
		m_aro_a.material = mat_oro
		var mi_aa = MeshInstance3D.new()
		mi_aa.mesh = m_aro_a
		mi_aa.position = Vector3(0, pos_y, 0)
		nodo_guadana.add_child(mi_aa)

	# Garganta / calavera de engarce en el tope del astil
	var m_engarce = SphereMesh.new()
	m_engarce.radius = 0.12
	m_engarce.height = 0.16
	m_engarce.material = mat_hueso
	var mi_eng = MeshInstance3D.new()
	mi_eng.mesh = m_engarce
	mi_eng.position = Vector3(0, 1.25, 0)
	nodo_guadana.add_child(mi_eng)

	# Gran Hoja Curva de la Guadaña (Rubí cristalino en 3 segmentos articulados)
	var curvaturas = [
		{"pos": Vector3(-0.35, 1.38, 0), "rot": Vector3(0, 0, -28), "dim": Vector3(0.55, 0.18, 0.04)},
		{"pos": Vector3(-0.78, 1.28, 0), "rot": Vector3(0, 0, -58), "dim": Vector3(0.52, 0.14, 0.03)},
		{"pos": Vector3(-1.12, 0.98, 0), "rot": Vector3(0, 0, -88), "dim": Vector3(0.48, 0.09, 0.02)}
	]
	for c in curvaturas:
		var m_seg_hoja = BoxMesh.new()
		m_seg_hoja.size = c["dim"]
		m_seg_hoja.material = mat_hoja_guadana
		var mi_seg = MeshInstance3D.new()
		mi_seg.mesh = m_seg_hoja
		mi_seg.position = c["pos"]
		mi_seg.rotation_degrees = c["rot"]
		nodo_guadana.add_child(mi_seg)

	# Punta afilada final de la guadaña
	var m_punta_g = PrismMesh.new()
	m_punta_g.size = Vector3(0.08, 0.35, 0.02)
	m_punta_g.material = mat_hoja_guadana
	var mi_pg = MeshInstance3D.new()
	mi_pg.mesh = m_punta_g
	mi_pg.position = Vector3(-1.26, 0.72, 0)
	mi_pg.rotation_degrees = Vector3(0, 0, 120)
	nodo_guadana.add_child(mi_pg)

	# Espina dorsal dentada en la parte posterior de la hoja
	var m_diente = PrismMesh.new()
	m_diente.size = Vector3(0.12, 0.22, 0.03)
	m_diente.material = mat_oro
	var mi_die = MeshInstance3D.new()
	mi_die.mesh = m_diente
	mi_die.position = Vector3(-0.48, 1.52, 0)
	mi_die.rotation_degrees = Vector3(0, 0, 45)
	nodo_guadana.add_child(mi_die)

	# --- 4. BARRERA ESPECTRAL GEODÉSICA Y ANILLOS RÚNICOS ORBITALES ---
	var m_esfera_barrera = SphereMesh.new()
	m_esfera_barrera.radius = 1.65
	m_esfera_barrera.height = 3.3
	m_esfera_barrera.radial_segments = 32
	m_esfera_barrera.rings = 16
	m_esfera_barrera.material = mat_barrera
	var mi_barrera = MeshInstance3D.new()
	mi_barrera.name = "BarreraEspectral"
	mi_barrera.mesh = m_esfera_barrera
	raiz.add_child(mi_barrera)

	# 2 Anillos orbitales rúnicos giratorios cruzados
	var m_aro_orb1 = TorusMesh.new()
	m_aro_orb1.inner_radius = 1.35
	m_aro_orb1.outer_radius = 1.42
	m_aro_orb1.material = mat_anillo_runico
	var mi_ao1 = MeshInstance3D.new()
	mi_ao1.mesh = m_aro_orb1
	mi_ao1.rotation_degrees = Vector3(35, 20, 0)
	raiz.add_child(mi_ao1)

	var m_aro_orb2 = TorusMesh.new()
	m_aro_orb2.inner_radius = 1.35
	m_aro_orb2.outer_radius = 1.42
	m_aro_orb2.material = mat_anillo_runico
	var mi_ao2 = MeshInstance3D.new()
	mi_ao2.mesh = m_aro_orb2
	mi_ao2.rotation_degrees = Vector3(-45, -25, 0)
	raiz.add_child(mi_ao2)

	# --- 5. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 6. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/jefe_parca_roja.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Parca Roja exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/jefe_parca_roja.glb-81ed22679202d0e9503e7661f1b902d6.scn"
	var err_scn = ResourceSaver.save(pack, scn_path)
	if err_scn == OK:
		print("✓ Escena SCN sincronizada directamente en: ", scn_path)
	else:
		printerr("Error guardando SCN: ", err_scn)

	# También sincronizar a la segunda clave SCN detectada en imported
	var scn_path_alt = "res://.godot/imported/jefe_parca_roja.glb-dogulk2wxbsc2.scn"
	ResourceSaver.save(pack, scn_path_alt)

	quit(0)

func _fijar_dueno(n: Node, r: Node):
	for c in n.get_children():
		c.owner = r
		_fijar_dueno(c, r)
