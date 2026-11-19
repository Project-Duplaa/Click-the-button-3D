@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: EL ESPEJO SOMBRÍO (JEFE SECRETO)
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Reflejo Maldito del Campeón: Caballero de obsidiana con yelmo de visor cromado/espejo,
# marco gótico de espejo flotante a sus espaldas con superficie abisal y fragmentos orbitales,
# hombreras angulosas, capa desgarrada y Mandoble del Vacío rúnico.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: EL ESPEJO SOMBRÍO...")

	var raiz = Node3D.new()
	raiz.name = "jefe_espejo_sombrio"

	# --- MATERIALES PBR ESTILIZADOS ---
	# 1. Armadura de Placas de Obsidiana / Acero Sombrío
	var mat_armadura = StandardMaterial3D.new()
	mat_armadura.albedo_color = Color(0.10, 0.08, 0.15)
	mat_armadura.metallic = 0.85
	mat_armadura.roughness = 0.28
	mat_armadura.rim_enabled = true
	mat_armadura.rim = 0.65
	mat_armadura.rim_tint = 0.4

	# 2. Detalles de Oro Antiguo / Bronce Imperial
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.75, 0.58, 0.22)
	mat_oro.metallic = 0.92
	mat_oro.roughness = 0.32
	mat_oro.rim_enabled = true
	mat_oro.rim = 0.5

	# 3. Visor Cromado Refractivo (Efecto Espejo Puro)
	var mat_visor = StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.85, 0.88, 0.95)
	mat_visor.metallic = 0.98
	mat_visor.roughness = 0.05
	mat_visor.clearcoat_enabled = true
	mat_visor.clearcoat = 1.0
	mat_visor.rim_enabled = true
	mat_visor.rim = 0.9

	# 4. Superficie del Gran Espejo (Portal del Vacío)
	var mat_espejo_vidrio = StandardMaterial3D.new()
	mat_espejo_vidrio.albedo_color = Color(0.08, 0.04, 0.16)
	mat_espejo_vidrio.metallic = 0.92
	mat_espejo_vidrio.roughness = 0.12
	mat_espejo_vidrio.clearcoat_enabled = true
	mat_espejo_vidrio.clearcoat = 0.85
	mat_espejo_vidrio.emission_enabled = true
	mat_espejo_vidrio.emission = Color(0.55, 0.18, 0.85)
	mat_espejo_vidrio.emission_energy_multiplier = 0.45

	# 5. Runas y Filos de Energía del Vacío (Magenta / Violeta Cósmico)
	var mat_vacio_runa = StandardMaterial3D.new()
	mat_vacio_runa.albedo_color = Color(0.82, 0.25, 0.95)
	mat_vacio_runa.emission_enabled = true
	mat_vacio_runa.emission = Color(0.88, 0.30, 1.0)
	mat_vacio_runa.emission_energy_multiplier = 0.92

	# 6. Filo de Acero Estelar Templado (Mandoble)
	var mat_filo = StandardMaterial3D.new()
	mat_filo.albedo_color = Color(0.35, 0.32, 0.42)
	mat_filo.metallic = 0.9
	mat_filo.roughness = 0.18
	mat_filo.rim_enabled = true
	mat_filo.rim = 0.8

	# 7. Tela de Capa de Sombra Tenebrosa
	var mat_capa = StandardMaterial3D.new()
	mat_capa.albedo_color = Color(0.06, 0.03, 0.09)
	mat_capa.roughness = 0.92

	# ==============================================================================
	# 1. EL GRAN MARCO DEL ESPEJO SOMBRÍO (Flotando a espaldas del campeón)
	# ==============================================================================
	var nodo_espejo_flotante = Node3D.new()
	nodo_espejo_flotante.name = "MarcoEspejoSombrio"
	nodo_espejo_flotante.position = Vector3(0.0, 1.35, -0.45)
	raiz.add_child(nodo_espejo_flotante)

	# Cristal Principal del Espejo (Ovalado / Octogonal estilizado)
	var m_vidrio = BoxMesh.new()
	m_vidrio.size = Vector3(1.4, 2.3, 0.08)
	m_vidrio.material = mat_espejo_vidrio
	var mi_vidrio = MeshInstance3D.new()
	mi_vidrio.mesh = m_vidrio
	mi_vidrio.name = "SuperficieEspejo"
	nodo_espejo_flotante.add_child(mi_vidrio)

	# Bisel / Marco Interior Dorado
	var m_marco_int_v = BoxMesh.new()
	m_marco_int_v.size = Vector3(0.07, 2.36, 0.12)
	m_marco_int_v.material = mat_oro
	var mi_miv1 = MeshInstance3D.new()
	mi_miv1.mesh = m_marco_int_v
	mi_miv1.position = Vector3(-0.72, 0, 0)
	nodo_espejo_flotante.add_child(mi_miv1)

	var mi_miv2 = MeshInstance3D.new()
	mi_miv2.mesh = m_marco_int_v
	mi_miv2.position = Vector3(0.72, 0, 0)
	nodo_espejo_flotante.add_child(mi_miv2)

	var m_marco_int_h = BoxMesh.new()
	m_marco_int_h.size = Vector3(1.5, 0.07, 0.12)
	m_marco_int_h.material = mat_oro
	var mi_mih1 = MeshInstance3D.new()
	mi_mih1.mesh = m_marco_int_h
	mi_mih1.position = Vector3(0, -1.16, 0)
	nodo_espejo_flotante.add_child(mi_mih1)

	# Marco Gótico Exterior de Obsidiana con columnas
	var m_col_marco = CylinderMesh.new()
	m_col_marco.top_radius = 0.09
	m_col_marco.bottom_radius = 0.12
	m_col_marco.height = 2.45
	m_col_marco.radial_segments = 8
	m_col_marco.material = mat_armadura

	var mi_col_izq = MeshInstance3D.new()
	mi_col_izq.mesh = m_col_marco
	mi_col_izq.position = Vector3(-0.80, 0, 0.02)
	nodo_espejo_flotante.add_child(mi_col_izq)

	var mi_col_der = MeshInstance3D.new()
	mi_col_der.mesh = m_col_marco
	mi_col_der.position = Vector3(0.80, 0, 0.02)
	nodo_espejo_flotante.add_child(mi_col_der)

	# Frontón / Corona Superior de Puntas Góticas
	var m_arco_top = BoxMesh.new()
	m_arco_top.size = Vector3(1.7, 0.15, 0.14)
	m_arco_top.material = mat_armadura
	var mi_arco_top = MeshInstance3D.new()
	mi_arco_top.mesh = m_arco_top
	mi_arco_top.position = Vector3(0, 1.20, 0.02)
	nodo_espejo_flotante.add_child(mi_arco_top)

	# Agujas / Espigas en la corona del espejo
	for pos_x in [-0.8, -0.4, 0.0, 0.4, 0.8]:
		var h_espiga = 0.45 if pos_x == 0.0 else (0.32 if abs(pos_x) == 0.4 else 0.25)
		var m_espiga = PrismMesh.new()
		m_espiga.size = Vector3(0.12, h_espiga, 0.1)
		m_espiga.material = mat_oro if pos_x == 0.0 else mat_armadura
		var mi_esp = MeshInstance3D.new()
		mi_esp.mesh = m_espiga
		mi_esp.position = Vector3(pos_x, 1.28 + h_espiga * 0.5, 0.02)
		nodo_espejo_flotante.add_child(mi_esp)

	# Gema del Ojo Abisal en el tope del marco
	var m_ojo_marco = SphereMesh.new()
	m_ojo_marco.radius = 0.14
	m_ojo_marco.height = 0.28
	m_ojo_marco.material = mat_vacio_runa
	var mi_ojo = MeshInstance3D.new()
	mi_ojo.mesh = m_ojo_marco
	mi_ojo.position = Vector3(0, 1.22, 0.08)
	nodo_espejo_flotante.add_child(mi_ojo)

	# Remates inferiores del marco
	var m_base_marco = BoxMesh.new()
	m_base_marco.size = Vector3(1.7, 0.14, 0.14)
	m_base_marco.material = mat_armadura
	var mi_base_m = MeshInstance3D.new()
	mi_base_m.mesh = m_base_marco
	mi_base_m.position = Vector3(0, -1.22, 0.02)
	nodo_espejo_flotante.add_child(mi_base_m)

	# 4 Fragmentos de Espejo Orbitando el Marco
	var configs_fragmentos = [
		{"pos": Vector3(-1.05, 0.7, 0.15), "rot": Vector3(0, 0.35, -0.25), "scale": Vector3(0.22, 0.45, 0.04)},
		{"pos": Vector3(1.10, 0.55, 0.12), "rot": Vector3(0, -0.4, 0.3), "scale": Vector3(0.25, 0.5, 0.04)},
		{"pos": Vector3(-1.0, -0.65, 0.20), "rot": Vector3(0.2, 0.5, 0.2), "scale": Vector3(0.2, 0.4, 0.04)},
		{"pos": Vector3(1.02, -0.75, 0.18), "rot": Vector3(-0.2, -0.45, -0.25), "scale": Vector3(0.22, 0.42, 0.04)}
	]
	for cfg in configs_fragmentos:
		var mi_frag = MeshInstance3D.new()
		var m_frag = PrismMesh.new()
		m_frag.size = cfg["scale"]
		m_frag.material = mat_espejo_vidrio
		mi_frag.mesh = m_frag
		mi_frag.position = cfg["pos"]
		mi_frag.rotation = cfg["rot"]
		nodo_espejo_flotante.add_child(mi_frag)

	# ==============================================================================
	# 2. EL CABALLERO DE SOMBRAS (CAMPEÓN CORRUPTO)
	# ==============================================================================
	var nodo_caballero = Node3D.new()
	nodo_caballero.name = "CampeonSombrio"
	nodo_caballero.position = Vector3(0.0, 0.0, 0.0)
	raiz.add_child(nodo_caballero)

	# --- TORSO Y PECHERA GÓTICA ---
	# Cuirass / Coraza Central
	var m_pecho = BoxMesh.new()
	m_pecho.size = Vector3(0.55, 0.58, 0.38)
	m_pecho.material = mat_armadura
	var mi_pecho = MeshInstance3D.new()
	mi_pecho.mesh = m_pecho
	mi_pecho.position = Vector3(0, 1.25, 0)
	nodo_caballero.add_child(mi_pecho)

	# Placa pectoral en V
	var m_pectoral = PrismMesh.new()
	m_pectoral.size = Vector3(0.48, 0.42, 0.12)
	m_pectoral.material = mat_oro
	var mi_pectoral = MeshInstance3D.new()
	mi_pectoral.mesh = m_pectoral
	mi_pectoral.position = Vector3(0, 1.30, 0.18)
	mi_pectoral.rotation_degrees = Vector3(180, 0, 0)
	nodo_caballero.add_child(mi_pectoral)

	# Núcleo / Joya del Vacío en el Pecho
	var m_joya_pecho = SphereMesh.new()
	m_joya_pecho.radius = 0.09
	m_joya_pecho.height = 0.18
	m_joya_pecho.material = mat_vacio_runa
	var mi_joya_p = MeshInstance3D.new()
	mi_joya_p.mesh = m_joya_pecho
	mi_joya_p.position = Vector3(0, 1.32, 0.24)
	nodo_caballero.add_child(mi_joya_p)

	# Abdomen / Faja articulada
	var m_cintura = CylinderMesh.new()
	m_cintura.top_radius = 0.22
	m_cintura.bottom_radius = 0.25
	m_cintura.height = 0.28
	m_cintura.material = mat_armadura
	var mi_cintura = MeshInstance3D.new()
	mi_cintura.mesh = m_cintura
	mi_cintura.position = Vector3(0, 0.88, 0)
	nodo_caballero.add_child(mi_cintura)

	# Cinturón con hebilla dorada y runa
	var m_cinturon = CylinderMesh.new()
	m_cinturon.top_radius = 0.26
	m_cinturon.bottom_radius = 0.27
	m_cinturon.height = 0.08
	m_cinturon.material = mat_oro
	var mi_cinturon = MeshInstance3D.new()
	mi_cinturon.mesh = m_cinturon
	mi_cinturon.position = Vector3(0, 0.86, 0)
	nodo_caballero.add_child(mi_cinturon)

	# Escarpelas / Placas de Cadera (Tassets laterales)
	for sgn in [-1.0, 1.0]:
		var m_tasset = BoxMesh.new()
		m_tasset.size = Vector3(0.18, 0.35, 0.30)
		m_tasset.material = mat_armadura
		var mi_tasset = MeshInstance3D.new()
		mi_tasset.mesh = m_tasset
		mi_tasset.position = Vector3(sgn * 0.26, 0.74, 0)
		mi_tasset.rotation_degrees = Vector3(0, 0, sgn * -14.0)
		nodo_caballero.add_child(mi_tasset)

	# --- CABEZA Y YELMO SOMBRÍO ---
	var nodo_cabeza = Node3D.new()
	nodo_cabeza.name = "CabezaYelmo"
	nodo_cabeza.position = Vector3(0, 1.68, 0)
	nodo_caballero.add_child(nodo_cabeza)

	# Casco base
	var m_casco = BoxMesh.new()
	m_casco.size = Vector3(0.32, 0.36, 0.34)
	m_casco.material = mat_armadura
	var mi_casco = MeshInstance3D.new()
	mi_casco.mesh = m_casco
	nodo_cabeza.add_child(mi_casco)

	# Gran Visor Cromado "El Espejo" (Reflectante puro en la cara)
	var m_vis = BoxMesh.new()
	m_vis.size = Vector3(0.24, 0.18, 0.06)
	m_vis.material = mat_visor
	var mi_vis = MeshInstance3D.new()
	mi_vis.mesh = m_vis
	mi_vis.position = Vector3(0, 0.02, 0.16)
	nodo_cabeza.add_child(mi_vis)

	# Hendidura rúnica horizontal brillante sobre el visor
	var m_slit = BoxMesh.new()
	m_slit.size = Vector3(0.22, 0.03, 0.02)
	m_slit.material = mat_vacio_runa
	var mi_slit = MeshInstance3D.new()
	mi_slit.mesh = m_slit
	mi_slit.position = Vector3(0, 0.02, 0.192)
	nodo_cabeza.add_child(mi_slit)

	# Cresta del Yelmo (Cimera Imperial Afilada)
	var m_cimera = BoxMesh.new()
	m_cimera.size = Vector3(0.06, 0.22, 0.38)
	m_cimera.material = mat_oro
	var mi_cimera = MeshInstance3D.new()
	mi_cimera.mesh = m_cimera
	mi_cimera.position = Vector3(0, 0.22, -0.04)
	nodo_cabeza.add_child(mi_cimera)

	# Cuernos laterales de acero oscuro
	for sgn in [-1.0, 1.0]:
		var m_cuerno = CylinderMesh.new()
		m_cuerno.top_radius = 0.02
		m_cuerno.bottom_radius = 0.06
		m_cuerno.height = 0.35
		m_cuerno.material = mat_armadura
		var mi_cuerno = MeshInstance3D.new()
		mi_cuerno.mesh = m_cuerno
		mi_cuerno.position = Vector3(sgn * 0.22, 0.22, 0)
		mi_cuerno.rotation_degrees = Vector3(-15, 0, sgn * -35)
		nodo_cabeza.add_child(mi_cuerno)

	# --- HOMBRERAS GÓTICAS MONUMENTALES ---
	for sgn in [-1.0, 1.0]:
		var nodo_hombro = Node3D.new()
		nodo_hombro.position = Vector3(sgn * 0.44, 1.42, 0)
		nodo_caballero.add_child(nodo_hombro)

		# Capa 1: Hombrera base
		var m_homb1 = BoxMesh.new()
		m_homb1.size = Vector3(0.26, 0.28, 0.34)
		m_homb1.material = mat_armadura
		var mi_homb1 = MeshInstance3D.new()
		mi_homb1.mesh = m_homb1
		mi_homb1.rotation_degrees = Vector3(0, 0, sgn * 20)
		nodo_hombro.add_child(mi_homb1)

		# Capa 2: Espiga superior afilada
		var m_homb_puntas = PrismMesh.new()
		m_homb_puntas.size = Vector3(0.22, 0.32, 0.30)
		m_homb_puntas.material = mat_oro
		var mi_hp = MeshInstance3D.new()
		mi_hp.mesh = m_homb_puntas
		mi_hp.position = Vector3(sgn * 0.04, 0.20, 0)
		mi_hp.rotation_degrees = Vector3(0, 0, sgn * -25)
		nodo_hombro.add_child(mi_hp)

		# Runa brillante en la hombrera
		var m_hruna = SphereMesh.new()
		m_hruna.radius = 0.06
		m_hruna.height = 0.12
		m_hruna.material = mat_vacio_runa
		var mi_hruna = MeshInstance3D.new()
		mi_hruna.mesh = m_hruna
		mi_hruna.position = Vector3(sgn * 0.14, 0.04, 0)
		nodo_hombro.add_child(mi_hruna)

	# --- BRAZOS Y MANOS ---
	# Brazo Izquierdo: Flexionado hacia adelante, canalizando un sello mágico
	var nodo_brazo_izq = Node3D.new()
	nodo_brazo_izq.position = Vector3(-0.42, 1.25, 0)
	nodo_caballero.add_child(nodo_brazo_izq)

	var m_brazo = CylinderMesh.new()
	m_brazo.top_radius = 0.08
	m_brazo.bottom_radius = 0.09
	m_brazo.height = 0.40
	m_brazo.material = mat_armadura
	var mi_bi = MeshInstance3D.new()
	mi_bi.mesh = m_brazo
	mi_bi.position = Vector3(-0.06, -0.16, 0.08)
	mi_bi.rotation_degrees = Vector3(30, 0, 15)
	nodo_brazo_izq.add_child(mi_bi)

	# Antebrazo y Guantelete Izquierdo
	var m_guant = BoxMesh.new()
	m_guant.size = Vector3(0.18, 0.35, 0.18)
	m_guant.material = mat_armadura
	var mi_gi = MeshInstance3D.new()
	mi_gi.mesh = m_guant
	mi_gi.position = Vector3(-0.08, -0.38, 0.28)
	mi_gi.rotation_degrees = Vector3(55, 10, -10)
	nodo_brazo_izq.add_child(mi_gi)

	# Mano / Puño de acero
	var m_mano = BoxMesh.new()
	m_mano.size = Vector3(0.15, 0.14, 0.16)
	m_mano.material = mat_oro
	var mi_mano_izq = MeshInstance3D.new()
	mi_mano_izq.mesh = m_mano
	mi_mano_izq.position = Vector3(-0.10, -0.48, 0.42)
	nodo_brazo_izq.add_child(mi_mano_izq)

	# Mini-espejo / Sello de escudo flotante frente a la mano izquierda
	var m_sello = CylinderMesh.new()
	m_sello.top_radius = 0.28
	m_sello.bottom_radius = 0.28
	m_sello.height = 0.03
	m_sello.radial_segments = 6
	m_sello.material = mat_espejo_vidrio
	var mi_sello = MeshInstance3D.new()
	mi_sello.mesh = m_sello
	mi_sello.position = Vector3(-0.12, -0.48, 0.58)
	mi_sello.rotation_degrees = Vector3(90, 0, 30)
	nodo_brazo_izq.add_child(mi_sello)

	var m_sello_borde = TorusMesh.new()
	m_sello_borde.inner_radius = 0.27
	m_sello_borde.outer_radius = 0.31
	m_sello_borde.material = mat_vacio_runa
	var mi_sb = MeshInstance3D.new()
	mi_sb.mesh = m_sello_borde
	mi_sb.position = Vector3(-0.12, -0.48, 0.58)
	mi_sb.rotation_degrees = Vector3(90, 0, 0)
	nodo_brazo_izq.add_child(mi_sb)

	# Brazo Derecho: Empuñando el Gran Mandoble
	var nodo_brazo_der = Node3D.new()
	nodo_brazo_der.position = Vector3(0.42, 1.25, 0)
	nodo_caballero.add_child(nodo_brazo_der)

	var mi_bd = MeshInstance3D.new()
	mi_bd.mesh = m_brazo
	mi_bd.position = Vector3(0.06, -0.16, 0.05)
	mi_bd.rotation_degrees = Vector3(15, 0, -20)
	nodo_brazo_der.add_child(mi_bd)

	var mi_gd = MeshInstance3D.new()
	mi_gd.mesh = m_guant
	mi_gd.position = Vector3(0.12, -0.38, 0.15)
	mi_gd.rotation_degrees = Vector3(25, -10, 15)
	nodo_brazo_der.add_child(mi_gd)

	var mi_mano_der = MeshInstance3D.new()
	mi_mano_der.mesh = m_mano
	mi_mano_der.position = Vector3(0.16, -0.52, 0.22)
	nodo_brazo_der.add_child(mi_mano_der)

	# --- EL MANDOBLE DEL VACÍO (GREATSWORD) ---
	var nodo_espada = Node3D.new()
	nodo_espada.name = "MandobleVacio"
	nodo_espada.position = Vector3(0.58, 0.65, 0.25)
	nodo_espada.rotation_degrees = Vector3(-12, 10, -8)
	nodo_caballero.add_child(nodo_espada)

	# Empuñadura / Pomo
	var m_pomo = SphereMesh.new()
	m_pomo.radius = 0.06
	m_pomo.height = 0.12
	m_pomo.material = mat_vacio_runa
	var mi_pomo = MeshInstance3D.new()
	mi_pomo.mesh = m_pomo
	mi_pomo.position = Vector3(0, 0.70, 0)
	nodo_espada.add_child(mi_pomo)

	# Mango largo a dos manos
	var m_mango = CylinderMesh.new()
	m_mango.top_radius = 0.035
	m_mango.bottom_radius = 0.035
	m_mango.height = 0.45
	m_mango.material = mat_armadura
	var mi_mango = MeshInstance3D.new()
	mi_mango.mesh = m_mango
	mi_mango.position = Vector3(0, 0.48, 0)
	nodo_espada.add_child(mi_mango)

	# Guarda / Gavilanes en ala gótica
	var m_guarda = BoxMesh.new()
	m_guarda.size = Vector3(0.65, 0.08, 0.12)
	m_guarda.material = mat_oro
	var mi_guarda = MeshInstance3D.new()
	mi_guarda.mesh = m_guarda
	mi_guarda.position = Vector3(0, 0.24, 0)
	nodo_espada.add_child(mi_guarda)

	# Ojo central de la guarda
	var m_joya_espada = SphereMesh.new()
	m_joya_espada.radius = 0.05
	m_joya_espada.height = 0.10
	m_joya_espada.material = mat_vacio_runa
	var mi_je = MeshInstance3D.new()
	mi_je.mesh = m_joya_espada
	mi_je.position = Vector3(0, 0.24, 0.06)
	nodo_espada.add_child(mi_je)

	# Hoja Colosal del Mandoble
	var m_hoja = BoxMesh.new()
	m_hoja.size = Vector3(0.20, 1.45, 0.05)
	m_hoja.material = mat_filo
	var mi_hoja = MeshInstance3D.new()
	mi_hoja.mesh = m_hoja
	mi_hoja.position = Vector3(0, -0.48, 0)
	nodo_espada.add_child(mi_hoja)

	# Canaladura / Runa central brillante de la hoja
	var m_runa_hoja = BoxMesh.new()
	m_runa_hoja.size = Vector3(0.04, 1.25, 0.06)
	m_runa_hoja.material = mat_vacio_runa
	var mi_rh = MeshInstance3D.new()
	mi_rh.mesh = m_runa_hoja
	mi_rh.position = Vector3(0, -0.42, 0)
	nodo_espada.add_child(mi_rh)

	# Punta de la hoja
	var m_punta = PrismMesh.new()
	m_punta.size = Vector3(0.20, 0.28, 0.05)
	m_punta.material = mat_filo
	var mi_punta = MeshInstance3D.new()
	mi_punta.mesh = m_punta
	mi_punta.position = Vector3(0, -1.32, 0)
	mi_punta.rotation_degrees = Vector3(180, 0, 0)
	nodo_espada.add_child(mi_punta)

	# --- PIERNAS Y GREBAS ---
	for sgn in [-1.0, 1.0]:
		var nodo_pierna = Node3D.new()
		nodo_pierna.position = Vector3(sgn * 0.20, 0.8, 0)
		nodo_caballero.add_child(nodo_pierna)

		# Muslo
		var m_muslo = CylinderMesh.new()
		m_muslo.top_radius = 0.12
		m_muslo.bottom_radius = 0.11
		m_muslo.height = 0.40
		m_muslo.material = mat_armadura
		var mi_mus = MeshInstance3D.new()
		mi_mus.mesh = m_muslo
		mi_mus.position = Vector3(0, -0.16, 0)
		nodo_pierna.add_child(mi_mus)

		# Rodillera con remache de diamante
		var m_rod = BoxMesh.new()
		m_rod.size = Vector3(0.18, 0.18, 0.16)
		m_rod.material = mat_oro
		var mi_rod = MeshInstance3D.new()
		mi_rod.mesh = m_rod
		mi_rod.position = Vector3(0, -0.36, 0.06)
		nodo_pierna.add_child(mi_rod)

		# Greba / Espinillera
		var m_greba = CylinderMesh.new()
		m_greba.top_radius = 0.11
		m_greba.bottom_radius = 0.09
		m_greba.height = 0.42
		m_greba.material = mat_armadura
		var mi_greb = MeshInstance3D.new()
		mi_greb.mesh = m_greba
		mi_greb.position = Vector3(0, -0.56, 0.02)
		nodo_pierna.add_child(mi_greb)

		# Escarpe / Bota de acero
		var m_bota = BoxMesh.new()
		m_bota.size = Vector3(0.18, 0.14, 0.32)
		m_bota.material = mat_armadura
		var mi_bota = MeshInstance3D.new()
		mi_bota.mesh = m_bota
		mi_bota.position = Vector3(0, -0.74, 0.08)
		nodo_pierna.add_child(mi_bota)

	# --- CAPA DESGARRADA DE SOMBRAS ---
	var m_capa = BoxMesh.new()
	m_capa.size = Vector3(0.68, 1.15, 0.05)
	m_capa.material = mat_capa
	var mi_capa = MeshInstance3D.new()
	mi_capa.mesh = m_capa
	mi_capa.position = Vector3(0, 0.95, -0.20)
	mi_capa.rotation_degrees = Vector3(-12, 0, 0)
	nodo_caballero.add_child(mi_capa)

	# Puntas inferiores de la capa
	for px in [-0.25, 0.0, 0.25]:
		var m_pcapa = PrismMesh.new()
		m_pcapa.size = Vector3(0.22, 0.35, 0.04)
		m_pcapa.material = mat_capa
		var mi_pc = MeshInstance3D.new()
		mi_pc.mesh = m_pcapa
		mi_pc.position = Vector3(px, 0.30, -0.28)
		mi_pc.rotation_degrees = Vector3(168, 0, 0)
		nodo_caballero.add_child(mi_pc)

	# --- 3. AURA BASE RUNICA EN EL SUELO ---
	var m_halo_piso = TorusMesh.new()
	m_halo_piso.inner_radius = 0.95
	m_halo_piso.outer_radius = 1.05
	m_halo_piso.material = mat_vacio_runa
	var mi_halo_p = MeshInstance3D.new()
	mi_halo_p.mesh = m_halo_piso
	mi_halo_p.position = Vector3(0, 0.04, 0)
	raiz.add_child(mi_halo_p)

	var m_halo_int = TorusMesh.new()
	m_halo_int.inner_radius = 0.65
	m_halo_int.outer_radius = 0.72
	m_halo_int.material = mat_oro
	var mi_halo_i = MeshInstance3D.new()
	mi_halo_i.mesh = m_halo_int
	mi_halo_i.position = Vector3(0, 0.05, 0)
	raiz.add_child(mi_halo_i)

	# --- FIJAR DUEÑO RECURSIVO ---
	_fijar_dueno(raiz, raiz)

	# --- EXPORTAR A GLB ---
	var glb_path = "res://assets/modelos/jefe_espejo_sombrio.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB Espejo Sombrío exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	# Guardar .scn para cache directo si aplica
	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/jefe_espejo_sombrio.glb-cac79bb7ef647660ea9d8e578fae3f16.scn"
	ResourceSaver.save(pack, scn_path)

	print("✓ Generación de El Espejo Sombrío completada con éxito.")
	quit(0)

func _fijar_dueno(n: Node, r: Node):
	for c in n.get_children():
		c.owner = r
		_fijar_dueno(c, r)
