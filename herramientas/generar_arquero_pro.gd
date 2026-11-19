@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: ARQUERO BALÍSTICO (ACECHADOR DE ESPINAS Y GRAN ARCO)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Humanoide ágil de madera férrea, bulbos de esporas ámbar y gran arco recurvo 3D.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: ARQUERO BALÍSTICO...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_arquero_balistico"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Madera Férrea y Enredaderas Espinosas Oscuras
	var mat_madera = StandardMaterial3D.new()
	mat_madera.albedo_color = Color(0.26, 0.20, 0.15)
	mat_madera.roughness = 0.68
	mat_madera.metallic = 0.05
	mat_madera.rim_enabled = true
	mat_madera.rim = 0.65
	mat_madera.rim_tint = 0.35

	# 2. Espinas Afiladas de Corteza Verde Musgo
	var mat_espinas = StandardMaterial3D.new()
	mat_espinas.albedo_color = Color(0.18, 0.32, 0.16)
	mat_espinas.roughness = 0.45
	mat_espinas.metallic = 0.15

	# 3. Bulbos de Esporas Ámbar Luminosos (Cálidos, sin quemado blanco)
	var mat_espora = StandardMaterial3D.new()
	mat_espora.albedo_color = Color(1.0, 0.72, 0.15, 0.95)
	mat_espora.roughness = 0.15
	mat_espora.metallic = 0.05
	mat_espora.emission_enabled = true
	mat_espora.emission = Color(1.0, 0.62, 0.1)
	mat_espora.emission_energy_multiplier = 0.85
	mat_espora.rim_enabled = true
	mat_espora.rim = 0.85
	mat_espora.rim_tint = 0.5

	# 4. Madera Pulida del Arco Recurvo
	var mat_arco = StandardMaterial3D.new()
	mat_arco.albedo_color = Color(0.38, 0.26, 0.14)
	mat_arco.roughness = 0.38
	mat_arco.metallic = 0.25

	# 5. Cuerda y Flecha de Energía Plasmática
	var mat_energia_flecha = StandardMaterial3D.new()
	mat_energia_flecha.albedo_color = Color(0.2, 0.95, 0.7)
	mat_energia_flecha.emission_enabled = true
	mat_energia_flecha.emission = Color(0.15, 0.9, 0.65)
	mat_energia_flecha.emission_energy_multiplier = 0.9

	# 6. Ojos del Acechador
	var mat_ojos = StandardMaterial3D.new()
	mat_ojos.albedo_color = Color(1.0, 0.85, 0.2)
	mat_ojos.emission_enabled = true
	mat_ojos.emission = Color(1.0, 0.8, 0.15)
	mat_ojos.emission_energy_multiplier = 0.95

	# --- 1. TORSO Y COLUMNA ENCORVADA DE ENREDADERAS ---
	var nodo_cuerpo = Node3D.new()
	nodo_cuerpo.name = "TorsoAcechador"
	nodo_cuerpo.position = Vector3(0, 1.15, 0)
	nodo_cuerpo.rotation_degrees = Vector3(12, 10, 0)
	raiz.add_child(nodo_cuerpo)

	# Pecho / caja torácica de lianas trenzadas
	var m_pecho = CapsuleMesh.new()
	m_pecho.radius = 0.28
	m_pecho.height = 0.72
	m_pecho.radial_segments = 20
	m_pecho.material = mat_madera
	var mi_pecho = MeshInstance3D.new()
	mi_pecho.mesh = m_pecho
	mi_pecho.rotation_degrees = Vector3(18, 0, 0)
	nodo_cuerpo.add_child(mi_pecho)

	# Lianas envolventes en el torso
	for i in range(5):
		var m_liana = TorusMesh.new()
		m_liana.inner_radius = 0.22
		m_liana.outer_radius = 0.28
		m_liana.material = mat_espinas
		var mi_lia = MeshInstance3D.new()
		mi_lia.mesh = m_liana
		mi_lia.position = Vector3(0, (i - 2) * 0.12, 0)
		mi_lia.rotation_degrees = Vector3(15, i * 35.0, 10)
		nodo_cuerpo.add_child(mi_lia)

	# Cabeza de acechador con máscara de corteza y cuernos de espina
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.position = Vector3(0, 0.42, 0.22)
	nodo_cabeza.rotation_degrees = Vector3(-8, 0, 0)
	nodo_cuerpo.add_child(nodo_cabeza)

	var m_craneo = SphereMesh.new()
	m_craneo.radius = 0.18
	m_craneo.height = 0.26
	m_craneo.material = mat_madera
	var mi_craneo = MeshInstance3D.new()
	mi_craneo.mesh = m_craneo
	nodo_cabeza.add_child(mi_craneo)

	# Cuernos de espina
	for lado in [-1, 1]:
		var m_cuerno = CylinderMesh.new()
		m_cuerno.top_radius = 0.01
		m_cuerno.bottom_radius = 0.04
		m_cuerno.height = 0.32
		m_cuerno.material = mat_espinas
		var mi_cue = MeshInstance3D.new()
		mi_cue.mesh = m_cuerno
		mi_cue.position = Vector3(lado * 0.14, 0.16, -0.05)
		mi_cue.rotation_degrees = Vector3(-25, lado * 15, lado * 20)
		nodo_cabeza.add_child(mi_cue)

		# Ojos ópticos ámbar
		var m_ojo = SphereMesh.new()
		m_ojo.radius = 0.035
		m_ojo.height = 0.06
		m_ojo.material = mat_ojos
		var mi_ojo = MeshInstance3D.new()
		mi_ojo.mesh = m_ojo
		mi_ojo.position = Vector3(lado * 0.08, 0.02, 0.15)
		nodo_cabeza.add_child(mi_ojo)

	# --- 2. BULBOS LUMINOSOS DE ESPORAS EN LA ESPALDA Y HOMBRO ---
	var bulbos_config = [
		{"pos": Vector3(0.02, 0.28, -0.28), "r": 0.15, "h": 0.22},
		{"pos": Vector3(-0.16, 0.18, -0.24), "r": 0.13, "h": 0.18},
		{"pos": Vector3(0.14, 0.08, -0.26), "r": 0.12, "h": 0.17},
		{"pos": Vector3(-0.02, -0.05, -0.26), "r": 0.14, "h": 0.20},
		{"pos": Vector3(-0.25, 0.32, -0.08), "r": 0.16, "h": 0.22} # Bulbo de hombro
	]
	for b in bulbos_config:
		var m_bulbo = SphereMesh.new()
		m_bulbo.radius = b["r"]
		m_bulbo.height = b["h"]
		m_bulbo.radial_segments = 20
		m_bulbo.rings = 10
		m_bulbo.material = mat_espora
		var mi_bul = MeshInstance3D.new()
		mi_bul.mesh = m_bulbo
		mi_bul.position = b["pos"]
		nodo_cuerpo.add_child(mi_bul)

		# Anillo de cáliz leñoso que sostiene el bulbo
		var m_caliz = TorusMesh.new()
		m_caliz.inner_radius = b["r"] * 0.7
		m_caliz.outer_radius = b["r"] * 1.15
		m_caliz.material = mat_espinas
		var mi_cal = MeshInstance3D.new()
		mi_cal.mesh = m_caliz
		mi_cal.position = b["pos"] + Vector3(0, -0.04, 0)
		nodo_cuerpo.add_child(mi_cal)

	# --- 3. EXTREMIDADES ÁGILES (PIERNAS DIGITÍGRADAS DE RAÍZ) ---
	for lado in [-1, 1]:
		var nodo_pierna = Node3D.new()
		nodo_pierna.name = "Pierna_" + ("Izq" if lado < 0 else "Der")
		nodo_pierna.position = Vector3(lado * 0.26, 0.68, 0)
		raiz.add_child(nodo_pierna)

		# Muslo inclinado hacia adelante
		var m_muslo = CylinderMesh.new()
		m_muslo.top_radius = 0.11
		m_muslo.bottom_radius = 0.09
		m_muslo.height = 0.52
		m_muslo.material = mat_madera
		var mi_muslo = MeshInstance3D.new()
		mi_muslo.mesh = m_muslo
		mi_muslo.position = Vector3(0, -0.18, 0.1)
		mi_muslo.rotation_degrees = Vector3(28, 0, lado * -8)
		nodo_pierna.add_child(mi_muslo)

		# Espinilla inclinada hacia atrás (digitígrada)
		var m_pantorrilla = CylinderMesh.new()
		m_pantorrilla.top_radius = 0.08
		m_pantorrilla.bottom_radius = 0.06
		m_pantorrilla.height = 0.55
		m_pantorrilla.material = mat_madera
		var mi_pan = MeshInstance3D.new()
		mi_pan.mesh = m_pantorrilla
		mi_pan.position = Vector3(0, -0.52, -0.05)
		mi_pan.rotation_degrees = Vector3(-35, 0, 0)
		nodo_pierna.add_child(mi_pan)

		# Garras de raíz en el pie
		var m_garra = BoxMesh.new()
		m_garra.size = Vector3(0.18, 0.08, 0.35)
		m_garra.material = mat_espinas
		var mi_gar = MeshInstance3D.new()
		mi_gar.mesh = m_garra
		mi_gar.position = Vector3(0, -0.74, 0.12)
		nodo_pierna.add_child(mi_gar)

	# --- 4. BRAZOS Y GRAN ARCO RECURVO 3D ---
	# Brazo izquierdo sosteniendo el arco
	var nodo_arco_padre = Node3D.new()
	nodo_arco_padre.name = "ArmaArcoRecurvo"
	nodo_arco_padre.position = Vector3(0.38, 0.18, 0.45)
	nodo_arco_padre.rotation_degrees = Vector3(-15, 35, 12)
	nodo_cuerpo.add_child(nodo_arco_padre)

	# Pala superior del arco recurvo (compuesta por 3 cilindros curvados)
	var angulos_arco = [12, 35, 65]
	var pos_y_arco = [0.25, 0.58, 0.88]
	for i in range(3):
		var m_pala = CylinderMesh.new()
		m_pala.top_radius = 0.04 - (i * 0.008)
		m_pala.bottom_radius = 0.05 - (i * 0.008)
		m_pala.height = 0.38
		m_pala.material = mat_arco
		var mi_pala = MeshInstance3D.new()
		mi_pala.mesh = m_pala
		mi_pala.position = Vector3(0, pos_y_arco[i], -0.06 * (i + 1))
		mi_pala.rotation_degrees = Vector3(-angulos_arco[i], 0, 0)
		nodo_arco_padre.add_child(mi_pala)

	# Pala inferior del arco recurvo
	for i in range(3):
		var m_pala_inf = CylinderMesh.new()
		m_pala_inf.top_radius = 0.05 - (i * 0.008)
		m_pala_inf.bottom_radius = 0.04 - (i * 0.008)
		m_pala_inf.height = 0.38
		m_pala_inf.material = mat_arco
		var mi_pala_inf = MeshInstance3D.new()
		mi_pala_inf.mesh = m_pala_inf
		mi_pala_inf.position = Vector3(0, -pos_y_arco[i], -0.06 * (i + 1))
		mi_pala_inf.rotation_degrees = Vector3(angulos_arco[i], 0, 0)
		nodo_arco_padre.add_child(mi_pala_inf)

	# Empuñadura central del arco con ramas espinosas
	var m_mango = CylinderMesh.new()
	m_mango.top_radius = 0.06
	m_mango.bottom_radius = 0.06
	m_mango.height = 0.22
	m_mango.material = mat_espinas
	var mi_mango = MeshInstance3D.new()
	mi_mango.mesh = m_mango
	nodo_arco_padre.add_child(mi_mango)

	# Cuerda de energía tensada
	var m_cuerda = CylinderMesh.new()
	m_cuerda.top_radius = 0.008
	m_cuerda.bottom_radius = 0.008
	m_cuerda.height = 1.75
	m_cuerda.material = mat_energia_flecha
	var mi_cuerda = MeshInstance3D.new()
	mi_cuerda.mesh = m_cuerda
	mi_cuerda.position = Vector3(0, 0, -0.28)
	nodo_arco_padre.add_child(mi_cuerda)

	# Flecha de plasma nockada lista para disparar
	var m_flecha_asta = CylinderMesh.new()
	m_flecha_asta.top_radius = 0.015
	m_flecha_asta.bottom_radius = 0.015
	m_flecha_asta.height = 1.15
	m_flecha_asta.material = mat_madera
	var mi_asta = MeshInstance3D.new()
	mi_asta.mesh = m_flecha_asta
	mi_asta.position = Vector3(0, 0, 0.32)
	mi_asta.rotation_degrees = Vector3(90, 0, 0)
	nodo_arco_padre.add_child(mi_asta)

	# Punta de flecha de energía cristalina
	var m_punta_flecha = PrismMesh.new()
	m_punta_flecha.size = Vector3(0.08, 0.22, 0.03)
	m_punta_flecha.material = mat_energia_flecha
	var mi_punta_f = MeshInstance3D.new()
	mi_punta_f.mesh = m_punta_flecha
	mi_punta_f.position = Vector3(0, 0, 0.92)
	mi_punta_f.rotation_degrees = Vector3(90, 0, 0)
	nodo_arco_padre.add_child(mi_punta_f)

	# --- 5. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 6. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_arquero_balistico.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Arquero exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_arquero_balistico.glb-40586bf22837c1b8cc5e20250944d1e8.scn"
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
