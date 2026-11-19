@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: GÓLEM DE TESORO (PRESA RARA DE FORTUNA)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Gólem de lingotes de oro, bóveda acorazada, gran saco de gemas y botín desbordante.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: GÓLEM DE TESORO...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_golem_tesoro"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Oro Pulido de Ley (Cuerpo, Lingotes, Monedas)
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(1.0, 0.82, 0.22)
	mat_oro.metallic = 0.95
	mat_oro.roughness = 0.22
	mat_oro.rim_enabled = true
	mat_oro.rim = 0.75
	mat_oro.rim_tint = 0.35

	# 2. Oro Oscuro / Bronce (Remaches, Marcos, Ruedas de Bóveda)
	var mat_oro_oscuro = StandardMaterial3D.new()
	mat_oro_oscuro.albedo_color = Color(0.78, 0.58, 0.16)
	mat_oro_oscuro.metallic = 0.90
	mat_oro_oscuro.roughness = 0.35

	# 3. Saco de Cuero / Arpillera de Botín
	var mat_saco = StandardMaterial3D.new()
	mat_saco.albedo_color = Color(0.48, 0.32, 0.16)
	mat_saco.roughness = 0.85

	# 4. Cuerda de Yute
	var mat_cuerda = StandardMaterial3D.new()
	mat_cuerda.albedo_color = Color(0.74, 0.62, 0.42)
	mat_cuerda.roughness = 0.9

	# 5. Ojos y Gemas de Rubí Radiante
	var mat_rubi = StandardMaterial3D.new()
	mat_rubi.albedo_color = Color(0.98, 0.12, 0.22)
	mat_rubi.metallic = 0.3
	mat_rubi.roughness = 0.1
	mat_rubi.emission_enabled = true
	mat_rubi.emission = Color(0.95, 0.08, 0.18)
	mat_rubi.emission_energy_multiplier = 0.85

	# 6. Gemas Esmeralda
	var mat_esmeralda = StandardMaterial3D.new()
	mat_esmeralda.albedo_color = Color(0.12, 0.92, 0.35)
	mat_esmeralda.metallic = 0.2
	mat_esmeralda.roughness = 0.12
	mat_esmeralda.emission_enabled = true
	mat_esmeralda.emission = Color(0.10, 0.88, 0.30)
	mat_esmeralda.emission_energy_multiplier = 0.85

	# 7. Gran Diamante de Cian Eléctrico
	var mat_diamante = StandardMaterial3D.new()
	mat_diamante.albedo_color = Color(0.25, 0.92, 1.0)
	mat_diamante.metallic = 0.15
	mat_diamante.roughness = 0.08
	mat_diamante.emission_enabled = true
	mat_diamante.emission = Color(0.20, 0.85, 1.0)
	mat_diamante.emission_energy_multiplier = 0.90

	# --- 1. TORSO DE BÓVEDA ACORAZADA (LINGOTES DE ORO) ---
	var nodo_torso = Node3D.new()
	nodo_torso.name = "TorsoGolem"
	nodo_torso.position = Vector3(0, 0.95, 0)
	raiz.add_child(nodo_torso)

	# Cofre central trapezoidal
	var m_pecho = BoxMesh.new()
	m_pecho.size = Vector3(0.85, 0.72, 0.65)
	m_pecho.material = mat_oro
	var mi_pecho = MeshInstance3D.new()
	mi_pecho.mesh = m_pecho
	nodo_torso.add_child(mi_pecho)

	# Timón / Rueda de Bóveda en el pecho
	var m_timon_aro = TorusMesh.new()
	m_timon_aro.inner_radius = 0.12
	m_timon_aro.outer_radius = 0.18
	m_timon_aro.material = mat_oro_oscuro
	var mi_timon = MeshInstance3D.new()
	mi_timon.mesh = m_timon_aro
	mi_timon.position = Vector3(0, 0.04, 0.33)
	mi_timon.rotation_degrees = Vector3(90, 0, 0)
	nodo_torso.add_child(mi_timon)

	var m_timon_eje = CylinderMesh.new()
	m_timon_eje.top_radius = 0.05
	m_timon_eje.bottom_radius = 0.05
	m_timon_eje.height = 0.08
	m_timon_eje.material = mat_oro_oscuro
	var mi_eje = MeshInstance3D.new()
	mi_eje.mesh = m_timon_eje
	mi_eje.position = Vector3(0, 0.04, 0.35)
	mi_eje.rotation_degrees = Vector3(90, 0, 0)
	nodo_torso.add_child(mi_eje)

	# Cerradura con joya incrustada
	var m_joya_pecho = SphereMesh.new()
	m_joya_pecho.radius = 0.06
	m_joya_pecho.height = 0.08
	m_joya_pecho.material = mat_esmeralda
	var mi_jp = MeshInstance3D.new()
	mi_jp.mesh = m_joya_pecho
	mi_jp.position = Vector3(0, 0.04, 0.38)
	nodo_torso.add_child(mi_jp)

	# Cinturón de lingotes
	var m_cinturon = BoxMesh.new()
	m_cinturon.size = Vector3(0.92, 0.12, 0.72)
	m_cinturon.material = mat_oro_oscuro
	var mi_cin = MeshInstance3D.new()
	mi_cin.mesh = m_cinturon
	mi_cin.position = Vector3(0, -0.32, 0)
	nodo_torso.add_child(mi_cin)

	# --- 2. CABEZA DE LINGOTE CON CORONA Y OJOS DE RUBÍ ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaGolem"
	nodo_cabeza.position = Vector3(0, 0.55, 0.08)
	nodo_torso.add_child(nodo_cabeza)

	var m_cab = BoxMesh.new()
	m_cab.size = Vector3(0.55, 0.45, 0.48)
	m_cab.material = mat_oro
	var mi_cab = MeshInstance3D.new()
	mi_cab.mesh = m_cab
	nodo_cabeza.add_child(mi_cab)

	# Ceño simpático / visera
	var m_ceja = BoxMesh.new()
	m_ceja.size = Vector3(0.48, 0.08, 0.12)
	m_ceja.material = mat_oro_oscuro
	var mi_ceja = MeshInstance3D.new()
	mi_ceja.mesh = m_ceja
	mi_ceja.position = Vector3(0, 0.12, 0.24)
	nodo_cabeza.add_child(mi_ceja)

	# Ojos de rubí brillante
	for lado in [-1, 1]:
		var m_ojo = SphereMesh.new()
		m_ojo.radius = 0.07
		m_ojo.height = 0.08
		m_ojo.material = mat_rubi
		var mi_ojo = MeshInstance3D.new()
		mi_ojo.mesh = m_ojo
		mi_ojo.position = Vector3(lado * 0.14, 0.02, 0.25)
		nodo_cabeza.add_child(mi_ojo)

	# Corona dorada con 3 picos enjoyados
	var nodo_corona = Node3D.new()
	nodo_corona.name = "Corona"
	nodo_corona.position = Vector3(0, 0.28, 0)
	nodo_cabeza.add_child(nodo_corona)

	var m_aro_c = CylinderMesh.new()
	m_aro_c.top_radius = 0.24
	m_aro_c.bottom_radius = 0.26
	m_aro_c.height = 0.08
	m_aro_c.material = mat_oro_oscuro
	var mi_ac = MeshInstance3D.new()
	mi_ac.mesh = m_aro_c
	nodo_corona.add_child(mi_ac)

	for p in [-1, 0, 1]:
		var m_pico = PrismMesh.new()
		m_pico.size = Vector3(0.12, 0.18, 0.06)
		m_pico.material = mat_oro
		var mi_pico = MeshInstance3D.new()
		mi_pico.mesh = m_pico
		mi_pico.position = Vector3(p * 0.16, 0.12, 0.16)
		nodo_corona.add_child(mi_pico)

		var m_g_pico = SphereMesh.new()
		m_g_pico.radius = 0.035
		m_g_pico.height = 0.035
		m_g_pico.material = mat_rubi if p != 0 else mat_esmeralda
		var mi_gp = MeshInstance3D.new()
		mi_gp.mesh = m_g_pico
		mi_gp.position = Vector3(p * 0.16, 0.22, 0.16)
		nodo_corona.add_child(mi_gp)

	# --- 3. GRAN SACO DE TESOROS EN LA ESPALDA (REBOSANTE) ---
	var nodo_saco = Node3D.new()
	nodo_saco.name = "SacoTesoros"
	nodo_saco.position = Vector3(0, 0.15, -0.48)
	nodo_torso.add_child(nodo_saco)

	# Cuerpo abultado del saco
	var m_saco_cuerpo = SphereMesh.new()
	m_saco_cuerpo.radius = 0.55
	m_saco_cuerpo.height = 0.95
	m_saco_cuerpo.material = mat_saco
	var mi_sc = MeshInstance3D.new()
	mi_sc.mesh = m_saco_cuerpo
	mi_sc.scale = Vector3(1.15, 1.1, 0.95)
	nodo_saco.add_child(mi_sc)

	# Cuello atado del saco con cuerda
	var m_cuerda_aro = TorusMesh.new()
	m_cuerda_aro.inner_radius = 0.16
	m_cuerda_aro.outer_radius = 0.26
	m_cuerda_aro.material = mat_cuerda
	var mi_cuerd = MeshInstance3D.new()
	mi_cuerd.mesh = m_cuerda_aro
	mi_cuerd.position = Vector3(0, 0.48, 0)
	nodo_saco.add_child(mi_cuerd)

	# Boca abierta del saco con monedas y lingotes desbordando
	for i in range(5):
		var ling = BoxMesh.new()
		ling.size = Vector3(0.12, 0.08, 0.24)
		ling.material = mat_oro
		var mi_l = MeshInstance3D.new()
		mi_l.mesh = ling
		var ang_l = i * 0.9
		mi_l.position = Vector3(cos(ang_l) * 0.14, 0.58 + (i * 0.03), sin(ang_l) * 0.14)
		mi_l.rotation_degrees = Vector3(15 + i * 10, i * 45, -20)
		nodo_saco.add_child(mi_l)

	# Monedas de oro gigantes saliendo
	for m in range(8):
		var m_moneda = CylinderMesh.new()
		m_moneda.top_radius = 0.10
		m_moneda.bottom_radius = 0.10
		m_moneda.height = 0.03
		m_moneda.material = mat_oro
		var mi_m = MeshInstance3D.new()
		mi_m.mesh = m_moneda
		var ang_m = m * (TAU / 8.0)
		mi_m.position = Vector3(cos(ang_m) * 0.28, 0.42 + (m % 3) * 0.08, sin(ang_m) * 0.22 - 0.05)
		mi_m.rotation_degrees = Vector3(randf_range(-30, 30), randf_range(0, 180), randf_range(-30, 30))
		nodo_saco.add_child(mi_m)

	# Gemas de corte radiante asomando en el saco
	var m_gema1 = PrismMesh.new()
	m_gema1.size = Vector3(0.16, 0.24, 0.12)
	m_gema1.material = mat_diamante
	var mi_g1 = MeshInstance3D.new()
	mi_g1.mesh = m_gema1
	mi_g1.position = Vector3(0.18, 0.62, 0.05)
	mi_g1.rotation_degrees = Vector3(-20, 45, 15)
	nodo_saco.add_child(mi_g1)

	var m_gema2 = PrismMesh.new()
	m_gema2.size = Vector3(0.14, 0.20, 0.10)
	m_gema2.material = mat_rubi
	var mi_g2 = MeshInstance3D.new()
	mi_g2.mesh = m_gema2
	mi_g2.position = Vector3(-0.16, 0.58, -0.06)
	mi_g2.rotation_degrees = Vector3(25, -30, -20)
	nodo_saco.add_child(mi_g2)

	# --- 4. BRAZOS DE ORO ARTICULADOS Y DIAMANTE ---
	# Brazo Derecho: sostiene en alto un diamante monumental
	var nodo_brazo_der = Node3D.new()
	nodo_brazo_der.name = "BrazoDer"
	nodo_brazo_der.position = Vector3(0.55, 0.18, 0.0)
	nodo_torso.add_child(nodo_brazo_der)

	var m_hombrera_der = SphereMesh.new()
	m_hombrera_der.radius = 0.20
	m_hombrera_der.height = 0.24
	m_hombrera_der.material = mat_oro_oscuro
	var mi_hd = MeshInstance3D.new()
	mi_hd.mesh = m_hombrera_der
	nodo_brazo_der.add_child(mi_hd)

	var m_brazo_d = CylinderMesh.new()
	m_brazo_d.top_radius = 0.14
	m_brazo_d.bottom_radius = 0.12
	m_brazo_d.height = 0.35
	m_brazo_d.material = mat_oro
	var mi_bd = MeshInstance3D.new()
	mi_bd.mesh = m_brazo_d
	mi_bd.position = Vector3(0.12, -0.22, 0.12)
	mi_bd.rotation_degrees = Vector3(-45, 0, -35)
	nodo_brazo_der.add_child(mi_bd)

	var m_puno_d = BoxMesh.new()
	m_puno_d.size = Vector3(0.24, 0.22, 0.24)
	m_puno_d.material = mat_oro_oscuro
	var mi_pd = MeshInstance3D.new()
	mi_pd.mesh = m_puno_d
	mi_pd.position = Vector3(0.24, -0.38, 0.28)
	nodo_brazo_der.add_child(mi_pd)

	# Diamante precioso en la mano derecha (gema facetada)
	var m_diam = SphereMesh.new()
	m_diam.radius = 0.16
	m_diam.height = 0.32
	m_diam.radial_segments = 6
	m_diam.rings = 3
	m_diam.material = mat_diamante
	var mi_diam = MeshInstance3D.new()
	mi_diam.mesh = m_diam
	mi_diam.position = Vector3(0.28, -0.22, 0.38)
	mi_diam.rotation_degrees = Vector3(15, 30, 20)
	nodo_brazo_der.add_child(mi_diam)

	# Brazo Izquierdo: balanceo al correr
	var nodo_brazo_izq = Node3D.new()
	nodo_brazo_izq.name = "BrazoIzq"
	nodo_brazo_izq.position = Vector3(-0.55, 0.18, 0.0)
	nodo_torso.add_child(nodo_brazo_izq)

	var m_hombrera_izq = SphereMesh.new()
	m_hombrera_izq.radius = 0.20
	m_hombrera_izq.height = 0.24
	m_hombrera_izq.material = mat_oro_oscuro
	var mi_hi = MeshInstance3D.new()
	mi_hi.mesh = m_hombrera_izq
	nodo_brazo_izq.add_child(mi_hi)

	var m_brazo_i = CylinderMesh.new()
	m_brazo_i.top_radius = 0.14
	m_brazo_i.bottom_radius = 0.12
	m_brazo_i.height = 0.35
	m_brazo_i.material = mat_oro
	var mi_bi = MeshInstance3D.new()
	mi_bi.mesh = m_brazo_i
	mi_bi.position = Vector3(-0.12, -0.22, -0.12)
	mi_bi.rotation_degrees = Vector3(35, 0, 25)
	nodo_brazo_izq.add_child(mi_bi)

	var m_puno_i = BoxMesh.new()
	m_puno_i.size = Vector3(0.22, 0.22, 0.22)
	m_puno_i.material = mat_oro_oscuro
	var mi_pi = MeshInstance3D.new()
	mi_pi.mesh = m_puno_i
	mi_pi.position = Vector3(-0.20, -0.38, -0.22)
	nodo_brazo_izq.add_child(mi_pi)

	# --- 5. PIERNAS DE LINGOTE CORTO CON BOTAS MACIZAS ---
	for lado in [-1, 1]:
		var nodo_p = Node3D.new()
		nodo_p.name = "Pierna_" + ("Izq" if lado < 0 else "Der")
		nodo_p.position = Vector3(lado * 0.28, -0.42, 0)
		nodo_torso.add_child(nodo_p)

		var m_mus = CylinderMesh.new()
		m_mus.top_radius = 0.15
		m_mus.bottom_radius = 0.14
		m_mus.height = 0.32
		m_mus.material = mat_oro
		var mi_mus = MeshInstance3D.new()
		mi_mus.mesh = m_mus
		mi_mus.position = Vector3(0, -0.14, 0)
		nodo_p.add_child(mi_mus)

		var m_pie = BoxMesh.new()
		m_pie.size = Vector3(0.24, 0.16, 0.36)
		m_pie.material = mat_oro_oscuro
		var mi_pie = MeshInstance3D.new()
		mi_pie.mesh = m_pie
		mi_pie.position = Vector3(0, -0.32, 0.08)
		nodo_p.add_child(mi_pie)

	# --- 6. FIJAR DUEÑO RECURSIVO ---
	_fijar_dueno(raiz, raiz)

	# --- 7. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_golem_tesoro.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Gólem de Tesoro exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_golem_tesoro.glb-cac79bb7ef647660ea9d8e578fae3f16.scn"
	ResourceSaver.save(pack, scn_path)

	# Actualizar golem_tesoro.tscn
	var tscn_path = "res://golem_tesoro.tscn"
	var pack_tscn = PackedScene.new()
	pack_tscn.pack(raiz)
	var err_tscn = ResourceSaver.save(pack_tscn, tscn_path)
	if err_tscn == OK:
		print("✓ Escena golem_tesoro.tscn actualizada con el nuevo modelo 3D")

	quit(0)

func _fijar_dueno(n: Node, r: Node):
	for c in n.get_children():
		c.owner = r
		_fijar_dueno(c, r)
