@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: CENTURIÓN CORRUPTO (DRON DE CONTENCIÓN GEOMÉTRICO)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Prisma octogonal metálico, orbe de plasma flotante, escudos con espesor 3D y aura sutil.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: CENTURIÓN CORRUPTO...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_centurion_corrupto"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Chasis Metálico Oscuro / Obsidiana Tecnológica
	var mat_chasis = StandardMaterial3D.new()
	mat_chasis.albedo_color = Color(0.18, 0.20, 0.24)
	mat_chasis.metallic = 0.88
	mat_chasis.roughness = 0.22
	mat_chasis.rim_enabled = true
	mat_chasis.rim = 0.65
	mat_chasis.rim_tint = 0.45

	# 2. Detalles de Armadura Imperial / Oro Corrupto
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.85, 0.65, 0.2)
	mat_oro.metallic = 0.92
	mat_oro.roughness = 0.28

	# 3. Núcleo de Plasma Arcano (Púrpura / Violeta vibrante)
	var mat_plasma_interno = StandardMaterial3D.new()
	mat_plasma_interno.albedo_color = Color(0.75, 0.15, 0.95)
	mat_plasma_interno.emission_enabled = true
	mat_plasma_interno.emission = Color(0.8, 0.2, 1.0)
	mat_plasma_interno.emission_energy_multiplier = 0.95

	# 4. Capa Exterior de Plasma (Cian eléctrico translúcido)
	var mat_plasma_externo = StandardMaterial3D.new()
	mat_plasma_externo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_plasma_externo.albedo_color = Color(0.2, 0.85, 1.0, 0.55)
	mat_plasma_externo.emission_enabled = true
	mat_plasma_externo.emission = Color(0.15, 0.75, 0.95)
	mat_plasma_externo.emission_energy_multiplier = 0.7
	mat_plasma_externo.rim_enabled = true
	mat_plasma_externo.rim = 0.8

	# 5. Franjas de Alerta Hazard y Líneas de Energía
	var mat_hazard_amarillo = StandardMaterial3D.new()
	mat_hazard_amarillo.albedo_color = Color(0.95, 0.78, 0.1)
	mat_hazard_amarillo.roughness = 0.35

	var mat_hazard_negro = StandardMaterial3D.new()
	mat_hazard_negro.albedo_color = Color(0.1, 0.1, 0.12)
	mat_hazard_negro.roughness = 0.4

	# 6. Aura Rúnica de Soporte en el Suelo (Translúcida, SIN quemado blanco)
	var mat_aura = StandardMaterial3D.new()
	mat_aura.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_aura.albedo_color = Color(0.15, 0.85, 1.0, 0.65)
	mat_aura.emission_enabled = true
	mat_aura.emission = Color(0.1, 0.7, 0.95)
	mat_aura.emission_energy_multiplier = 0.75

	# --- 1. CHASSIS PRINCIPAL: PRISMA DE CONTENCIÓN FLOTANTE ---
	var nodo_dron = Node3D.new()
	nodo_dron.name = "ChasisDron"
	nodo_dron.position = Vector3(0, 1.35, 0)
	raiz.add_child(nodo_dron)

	# Corona superior piramidal octogonal
	var m_corona_sup = CylinderMesh.new()
	m_corona_sup.top_radius = 0.02
	m_corona_sup.bottom_radius = 0.46
	m_corona_sup.height = 0.55
	m_corona_sup.radial_segments = 8
	m_corona_sup.material = mat_chasis
	var mi_corona_sup = MeshInstance3D.new()
	mi_corona_sup.mesh = m_corona_sup
	mi_corona_sup.position = Vector3(0, 0.58, 0)
	nodo_dron.add_child(mi_corona_sup)

	# Remate dorado en el ápice de la pirámide
	var m_punta = SphereMesh.new()
	m_punta.radius = 0.08
	m_punta.height = 0.12
	m_punta.material = mat_oro
	var mi_punta = MeshInstance3D.new()
	mi_punta.mesh = m_punta
	mi_punta.position = Vector3(0, 0.88, 0)
	nodo_dron.add_child(mi_punta)

	# Puntales estructurales de la cámara central (4 columnas angulares)
	for i in range(4):
		var ang = i * (PI * 2.0 / 4.0) + (PI / 4.0)
		var m_pilar = BoxMesh.new()
		m_pilar.size = Vector3(0.09, 0.52, 0.09)
		m_pilar.material = mat_chasis
		var mi_pilar = MeshInstance3D.new()
		mi_pilar.mesh = m_pilar
		mi_pilar.position = Vector3(cos(ang) * 0.38, 0.18, sin(ang) * 0.38)
		mi_pilar.rotation_degrees = Vector3(0, rad_to_deg(-ang), 0)
		nodo_dron.add_child(mi_pilar)

	# Base inferior piramidal invertida (propulsión antigravitatoria)
	var m_cono_inf = CylinderMesh.new()
	m_cono_inf.top_radius = 0.44
	m_cono_inf.bottom_radius = 0.08
	m_cono_inf.height = 0.52
	m_cono_inf.radial_segments = 8
	m_cono_inf.material = mat_chasis
	var mi_cono_inf = MeshInstance3D.new()
	mi_cono_inf.mesh = m_cono_inf
	mi_cono_inf.position = Vector3(0, -0.22, 0)
	nodo_dron.add_child(mi_cono_inf)

	# Tobera de empuje magnético
	var m_tobera = TorusMesh.new()
	m_tobera.inner_radius = 0.08
	m_tobera.outer_radius = 0.18
	m_tobera.material = mat_oro
	var mi_tob = MeshInstance3D.new()
	mi_tob.mesh = m_tobera
	mi_tob.position = Vector3(0, -0.48, 0)
	nodo_dron.add_child(mi_tob)

	# --- 2. ORBE DE PLASMA FLOTANTE EN EL CORAZÓN DE LA CÁMARA ---
	var m_orbe_int = SphereMesh.new()
	m_orbe_int.radius = 0.18
	m_orbe_int.height = 0.18
	m_orbe_int.material = mat_plasma_interno
	var mi_orbe_int = MeshInstance3D.new()
	mi_orbe_int.mesh = m_orbe_int
	mi_orbe_int.position = Vector3(0, 0.18, 0)
	nodo_dron.add_child(mi_orbe_int)

	var m_orbe_ext = SphereMesh.new()
	m_orbe_ext.radius = 0.25
	m_orbe_ext.height = 0.25
	m_orbe_ext.material = mat_plasma_externo
	var mi_orbe_ext = MeshInstance3D.new()
	mi_orbe_ext.mesh = m_orbe_ext
	mi_orbe_ext.position = Vector3(0, 0.18, 0)
	nodo_dron.add_child(mi_orbe_ext)

	# Anillo orbital giroscópico alrededor del núcleo
	var m_giro = TorusMesh.new()
	m_giro.inner_radius = 0.27
	m_giro.outer_radius = 0.31
	m_giro.material = mat_oro
	var mi_giro = MeshInstance3D.new()
	mi_giro.mesh = m_giro
	mi_giro.position = Vector3(0, 0.18, 0)
	mi_giro.rotation_degrees = Vector3(35, 25, 0)
	nodo_dron.add_child(mi_giro)

	# --- 3. PLACAS ESCUDO LATERALES CON AUTÉNTICO ESPESOR 3D Y BISIELES 360° ---
	for lado in [-1, 1]:
		var nodo_ala = Node3D.new()
		nodo_ala.name = "AlaDron_" + ("Izq" if lado < 0 else "Der")
		nodo_ala.position = Vector3(lado * 0.58, 0.22, 0)
		nodo_ala.rotation_degrees = Vector3(0, lado * -22, lado * 8)
		nodo_dron.add_child(nodo_ala)

		# Brazo mecánico de conexión con rótula
		var m_rotula = SphereMesh.new()
		m_rotula.radius = 0.08
		m_rotula.height = 0.08
		m_rotula.material = mat_oro
		var mi_rot = MeshInstance3D.new()
		mi_rot.mesh = m_rotula
		mi_rot.position = Vector3(lado * -0.15, 0, 0)
		nodo_ala.add_child(mi_rot)

		var m_soporte = BoxMesh.new()
		m_soporte.size = Vector3(0.18, 0.06, 0.08)
		m_soporte.material = mat_chasis
		var mi_sop = MeshInstance3D.new()
		mi_sop.mesh = m_soporte
		mi_sop.position = Vector3(lado * -0.05, 0, 0)
		nodo_ala.add_child(mi_sop)

		# Placa de escudo principal con grosor real
		var m_escudo_cuerpo = BoxMesh.new()
		m_escudo_cuerpo.size = Vector3(0.14, 0.88, 0.48)
		m_escudo_cuerpo.material = mat_chasis
		var mi_escudo = MeshInstance3D.new()
		mi_escudo.mesh = m_escudo_cuerpo
		nodo_ala.add_child(mi_escudo)

		# Bisel superior e inferior del escudo
		for fin_y in [-1, 1]:
			var m_bisel = PrismMesh.new()
			m_bisel.size = Vector3(0.14, 0.22, 0.48)
			m_bisel.material = mat_oro
			var mi_bis = MeshInstance3D.new()
			mi_bis.mesh = m_bisel
			mi_bis.position = Vector3(0, fin_y * 0.48, 0)
			mi_bis.rotation_degrees = Vector3(0, 0, 0 if fin_y > 0 else 180)
			nodo_ala.add_child(mi_bis)

		# Franjas Chevron de Precaución en la cara exterior
		for k in range(3):
			var m_chev = BoxMesh.new()
			m_chev.size = Vector3(0.015, 0.08, 0.32)
			m_chev.material = mat_hazard_amarillo if (k % 2 == 0) else mat_hazard_negro
			var mi_ch = MeshInstance3D.new()
			mi_ch.mesh = m_chev
			mi_ch.position = Vector3(lado * 0.075, (k - 1) * 0.16, 0)
			mi_ch.rotation_degrees = Vector3(lado * 15, 0, 0)
			nodo_ala.add_child(mi_ch)

		# Panel de bobina magnética en la cara interior (hacia el núcleo)
		var m_panel_in = BoxMesh.new()
		m_panel_in.size = Vector3(0.02, 0.55, 0.28)
		m_panel_in.material = mat_plasma_externo
		var mi_pin = MeshInstance3D.new()
		mi_pin.mesh = m_panel_in
		mi_pin.position = Vector3(lado * -0.075, 0, 0)
		nodo_ala.add_child(mi_pin)

	# --- 4. AURA DE SOPORTE HOLOGRÁFICA ORBITAL (Halo de contención flotante) ---
	var m_anillo_suelo = TorusMesh.new()
	m_anillo_suelo.inner_radius = 0.58
	m_anillo_suelo.outer_radius = 0.64
	m_anillo_suelo.material = mat_aura
	var mi_anillo_suelo = MeshInstance3D.new()
	mi_anillo_suelo.name = "HaloOrbital"
	mi_anillo_suelo.mesh = m_anillo_suelo
	mi_anillo_suelo.position = Vector3(0, 0.18, 0)
	mi_anillo_suelo.rotation_degrees = Vector3(15, 0, -10)
	nodo_dron.add_child(mi_anillo_suelo)

	# Runas / marcas del anillo proyectadas
	for r in range(6):
		var r_ang = r * (PI * 2.0 / 6.0)
		var m_runa = BoxMesh.new()
		m_runa.size = Vector3(0.04, 0.04, 0.12)
		m_runa.material = mat_plasma_interno
		var mi_r = MeshInstance3D.new()
		mi_r.mesh = m_runa
		mi_r.position = Vector3(cos(r_ang) * 0.61, 0.18, sin(r_ang) * 0.61)
		mi_r.rotation_degrees = Vector3(15, rad_to_deg(-r_ang), -10)
		nodo_dron.add_child(mi_r)

	# --- 5. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 6. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_centurion_corrupto.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Centurión exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_centurion_corrupto.glb-4186a0fc6b3c5e37e48c067f2bee2be0.scn"
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
