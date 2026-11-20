@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: HERALDO DEL CLIC (MÁQUINA TRAGAMONEDAS INDUSTRIAL)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Gabinete arcade steampunk, rodillos mecánicos, palanca jackpot y monorueda 3D.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: HERALDO DEL CLIC...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_heraldo_clic"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Latón y Oro del Gabinete
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.92, 0.72, 0.22)
	mat_oro.metallic = 0.92
	mat_oro.roughness = 0.25
	mat_oro.rim_enabled = true
	mat_oro.rim = 0.65

	# 2. Chasis de Acero Oscuro / Motor
	var mat_acero = StandardMaterial3D.new()
	mat_acero.albedo_color = Color(0.18, 0.20, 0.24)
	mat_acero.metallic = 0.90
	mat_acero.roughness = 0.32

	# 3. Rodillos de la Tragamonedas (Blanco con Símbolos)
	var mat_rodillo = StandardMaterial3D.new()
	mat_rodillo.albedo_color = Color(0.95, 0.95, 0.92)
	mat_rodillo.roughness = 0.2

	# 4. Luces de Jackpot Neón (Cian Eléctrico y Rojo Jackpot)
	var mat_neon_cian = StandardMaterial3D.new()
	mat_neon_cian.albedo_color = Color(0.2, 0.9, 1.0)
	mat_neon_cian.emission_enabled = true
	mat_neon_cian.emission = Color(0.15, 0.85, 1.0)
	mat_neon_cian.emission_energy_multiplier = 0.95

	var mat_rojo_jackpot = StandardMaterial3D.new()
	mat_rojo_jackpot.albedo_color = Color(1.0, 0.15, 0.2)
	mat_rojo_jackpot.emission_enabled = true
	mat_rojo_jackpot.emission = Color(1.0, 0.1, 0.15)
	mat_rojo_jackpot.emission_energy_multiplier = 0.9

	# 5. Rueda de Caucho y Remaches
	var mat_caucho = StandardMaterial3D.new()
	mat_caucho.albedo_color = Color(0.12, 0.12, 0.14)
	mat_caucho.roughness = 0.75

	# --- 1. GABINETE ARCADE CENTRAL (3D CON BISELES) ---
	var nodo_gabinete = Node3D.new()
	nodo_gabinete.name = "GabineteArcade"
	nodo_gabinete.position = Vector3(0, 1.25, 0)
	raiz.add_child(nodo_gabinete)

	# Caja del gabinete principal
	var m_caja = BoxMesh.new()
	m_caja.size = Vector3(0.85, 0.95, 0.65)
	m_caja.material = mat_oro
	var mi_caja = MeshInstance3D.new()
	mi_caja.mesh = m_caja
	nodo_gabinete.add_child(mi_caja)

	# Moldura frontal biselada
	var m_marco = BoxMesh.new()
	m_marco.size = Vector3(0.72, 0.48, 0.12)
	m_marco.material = mat_acero
	var mi_marco = MeshInstance3D.new()
	mi_marco.mesh = m_marco
	mi_marco.position = Vector3(0, 0.05, 0.32)
	nodo_gabinete.add_child(mi_marco)

	# 3 Tambores / Rodillos mecánicos de la tragamonedas
	for r in range(3):
		var x_r = (r - 1) * 0.18
		var m_tambor = CylinderMesh.new()
		m_tambor.top_radius = 0.14
		m_tambor.bottom_radius = 0.14
		m_tambor.height = 0.14
		m_tambor.radial_segments = 20
		m_tambor.material = mat_rodillo
		var mi_tam = MeshInstance3D.new()
		mi_tam.mesh = m_tambor
		mi_tam.position = Vector3(x_r, 0.05, 0.32)
		mi_tam.rotation_degrees = Vector3(0, 0, 90)
		nodo_gabinete.add_child(mi_tam)

		# Símbolo 7 dorado en el rodillo
		var m_siete = BoxMesh.new()
		m_siete.size = Vector3(0.04, 0.12, 0.02)
		m_siete.material = mat_rojo_jackpot
		var mi_sie = MeshInstance3D.new()
		mi_sie.mesh = m_siete
		mi_sie.position = Vector3(x_r, 0.05, 0.44)
		nodo_gabinete.add_child(mi_sie)

	# Marquesina superior JACKPOT 777 con corona
	var m_marquesina = BoxMesh.new()
	m_marquesina.size = Vector3(0.78, 0.28, 0.45)
	m_marquesina.material = mat_acero
	var mi_marq = MeshInstance3D.new()
	mi_marq.mesh = m_marquesina
	mi_marq.position = Vector3(0, 0.58, 0.05)
	nodo_gabinete.add_child(mi_marq)

	var m_rotulo = BoxMesh.new()
	m_rotulo.size = Vector3(0.65, 0.18, 0.04)
	m_rotulo.material = mat_neon_cian
	var mi_rot = MeshInstance3D.new()
	mi_rot.mesh = m_rotulo
	mi_rot.position = Vector3(0, 0.58, 0.28)
	nodo_gabinete.add_child(mi_rot)

	# Corona dorada sobre la marquesina
	var m_corona = TorusMesh.new()
	m_corona.inner_radius = 0.18
	m_corona.outer_radius = 0.25
	m_corona.material = mat_oro
	var mi_cor = MeshInstance3D.new()
	mi_cor.mesh = m_corona
	mi_cor.position = Vector3(0, 0.78, 0.05)
	nodo_gabinete.add_child(mi_cor)

	for p in range(5):
		var m_pico = PrismMesh.new()
		m_pico.size = Vector3(0.08, 0.18, 0.06)
		m_pico.material = mat_oro
		var mi_pic = MeshInstance3D.new()
		mi_pic.mesh = m_pico
		mi_pic.position = Vector3((p - 2) * 0.09, 0.88, 0.05)
		nodo_gabinete.add_child(mi_pic)

	# --- 2. PALANCA DE JACKPOT EN EL COSTADO ---
	var nodo_palanca = Node3D.new()
	nodo_palanca.name = "PalancaJackpot"
	nodo_palanca.position = Vector3(0.48, 0.05, 0)
	nodo_gabinete.add_child(nodo_palanca)

	var m_buje = SphereMesh.new()
	m_buje.radius = 0.08
	m_buje.height = 0.12
	m_buje.material = mat_acero
	var mi_buje = MeshInstance3D.new()
	mi_buje.mesh = m_buje
	nodo_palanca.add_child(mi_buje)

	var m_asta_p = CylinderMesh.new()
	m_asta_p.top_radius = 0.025
	m_asta_p.bottom_radius = 0.035
	m_asta_p.height = 0.55
	m_asta_p.material = mat_oro
	var mi_ap = MeshInstance3D.new()
	mi_ap.mesh = m_asta_p
	mi_ap.position = Vector3(0.12, 0.22, 0)
	mi_ap.rotation_degrees = Vector3(0, 0, -25)
	nodo_palanca.add_child(mi_ap)

	var m_pomo = SphereMesh.new()
	m_pomo.radius = 0.09
	m_pomo.height = 0.12
	m_pomo.material = mat_rojo_jackpot
	var mi_pomo = MeshInstance3D.new()
	mi_pomo.mesh = m_pomo
	mi_pomo.position = Vector3(0.24, 0.44, 0)
	nodo_palanca.add_child(mi_pomo)

	# --- 3. MONORUEDA PESADA INDUSTRIAL CON AMORTIGUACIÓN ---
	var nodo_rueda = Node3D.new()
	nodo_rueda.name = "Monorueda"
	nodo_rueda.position = Vector3(0, 0.45, 0)
	raiz.add_child(nodo_rueda)

	# Neumático central ancho
	var m_neumatico = TorusMesh.new()
	m_neumatico.inner_radius = 0.22
	m_neumatico.outer_radius = 0.42
	m_neumatico.material = mat_caucho
	var mi_neu = MeshInstance3D.new()
	mi_neu.mesh = m_neumatico
	mi_neu.rotation_degrees = Vector3(0, 0, 90)
	mi_neu.scale = Vector3(1.0, 1.6, 1.0)
	nodo_rueda.add_child(mi_neu)

	# Llanta de latón y cubo central
	var m_llanta = CylinderMesh.new()
	m_llanta.top_radius = 0.28
	m_llanta.bottom_radius = 0.28
	m_llanta.height = 0.28
	m_llanta.material = mat_oro
	var mi_llan = MeshInstance3D.new()
	mi_llan.mesh = m_llanta
	mi_llan.rotation_degrees = Vector3(0, 0, 90)
	nodo_rueda.add_child(mi_llan)

	# Brazos de horquilla de suspensión
	for lado in [-1, 1]:
		var m_horquilla = BoxMesh.new()
		m_horquilla.size = Vector3(0.08, 0.55, 0.14)
		m_horquilla.material = mat_acero
		var mi_hor = MeshInstance3D.new()
		mi_hor.mesh = m_horquilla
		mi_hor.position = Vector3(lado * 0.24, 0.22, 0)
		nodo_rueda.add_child(mi_hor)

	# --- 4. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 5. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_heraldo_clic.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Heraldo del Clic exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_heraldo_clic.glb-77d79f3d11cea924a1f5c30ef83ecc9a.scn"
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
