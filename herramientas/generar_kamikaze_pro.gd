@tool
extends SceneTree

# ==============================================================================
# MODELADOR 3D ESTILIZADO: MINERO INESTABLE / KAMIKAZE
# Modelo 100% tridimensional volumétrico en 360°, sin planos 2D extruidos.
# Amalgama gelatinosa de plasma tóxico con taladro industrial, dinamita y chimeneas.
# ==============================================================================

func _init():
	print(">>> GENERANDO MODELO 3D ESTILIZADO: MINERO INESTABLE (KAMIKAZE)...")

	var raiz = Node3D.new()
	raiz.name = "enemigo_minero_kamikaze"

	# --- MATERIALES ESTILIZADOS CARTOON / PBR ---
	# 1. Gelatina de Plasma Tóxico (Luminoso, translúcido con brillo especular pulido)
	var mat_plasma = StandardMaterial3D.new()
	mat_plasma.albedo_color = Color(0.22, 0.92, 0.38, 0.94)
	mat_plasma.metallic = 0.08
	mat_plasma.roughness = 0.14
	mat_plasma.rim_enabled = true
	mat_plasma.rim = 0.85
	mat_plasma.rim_tint = 0.45
	mat_plasma.emission_enabled = true
	mat_plasma.emission = Color(0.12, 0.45, 0.18)
	mat_plasma.emission_energy_multiplier = 0.55

	# 2. Núcleo Fisión Interno (Calor inestable contenido)
	var mat_nucleo = StandardMaterial3D.new()
	mat_nucleo.albedo_color = Color(1.0, 0.55, 0.1)
	mat_nucleo.emission_enabled = true
	mat_nucleo.emission = Color(1.0, 0.45, 0.05)
	mat_nucleo.emission_energy_multiplier = 0.9

	# 3. Metal Industrial de Minería (Taladro y collarín de acero reforzado)
	var mat_metal_taladro = StandardMaterial3D.new()
	mat_metal_taladro.albedo_color = Color(0.45, 0.48, 0.52)
	mat_metal_taladro.metallic = 0.92
	mat_metal_taladro.roughness = 0.28
	mat_metal_taladro.rim_enabled = true
	mat_metal_taladro.rim = 0.4

	# 4. Latón / Bronce de maquinaria pesada
	var mat_bronce = StandardMaterial3D.new()
	mat_bronce.albedo_color = Color(0.82, 0.62, 0.22)
	mat_bronce.metallic = 0.88
	mat_bronce.roughness = 0.32

	# 5. Chimeneas de Escape (Hierro fundido oscuro)
	var mat_chimenea = StandardMaterial3D.new()
	mat_chimenea.albedo_color = Color(0.18, 0.19, 0.22)
	mat_chimenea.metallic = 0.85
	mat_chimenea.roughness = 0.42

	# 6. Dinamita Roja y Correa
	var mat_dinamita = StandardMaterial3D.new()
	mat_dinamita.albedo_color = Color(0.85, 0.15, 0.12)
	mat_dinamita.roughness = 0.35

	var mat_correa = StandardMaterial3D.new()
	mat_correa.albedo_color = Color(0.15, 0.12, 0.1)
	mat_correa.roughness = 0.7

	var mat_mecha = StandardMaterial3D.new()
	mat_mecha.albedo_color = Color(0.95, 0.85, 0.5)
	mat_mecha.roughness = 0.8

	var mat_chispa = StandardMaterial3D.new()
	mat_chispa.albedo_color = Color(1.0, 0.7, 0.1)
	mat_chispa.emission_enabled = true
	mat_chispa.emission = Color(1.0, 0.6, 0.0)
	mat_chispa.emission_energy_multiplier = 1.1

	# --- 1. CUERPO VOLUMÉTRICO: SLIME BIO-PLÁSMICO (Composición de volúmenes 3D redondeados) ---
	var nodo_cuerpo = Node3D.new()
	nodo_cuerpo.name = "CuerpoGelatina"
	raiz.add_child(nodo_cuerpo)

	# Base inferior ancha
	var m_base = SphereMesh.new()
	m_base.radius = 0.68
	m_base.height = 0.62
	m_base.radial_segments = 32
	m_base.rings = 16
	m_base.material = mat_plasma
	var mi_base = MeshInstance3D.new()
	mi_base.name = "BaseBulbosa"
	mi_base.mesh = m_base
	mi_base.position = Vector3(0, 0.35, 0)
	nodo_cuerpo.add_child(mi_base)

	# Torso medio que desborda orgánicamente
	var m_medio = SphereMesh.new()
	m_medio.radius = 0.56
	m_medio.height = 0.65
	m_medio.radial_segments = 32
	m_medio.rings = 16
	m_medio.material = mat_plasma
	var mi_medio = MeshInstance3D.new()
	mi_medio.name = "TorsoMedio"
	mi_medio.mesh = m_medio
	mi_medio.position = Vector3(0.02, 0.68, -0.04)
	nodo_cuerpo.add_child(mi_medio)

	# Joroba / cabeza redondeada inclinada hacia adelante
	var m_cabeza = SphereMesh.new()
	m_cabeza.radius = 0.44
	m_cabeza.height = 0.52
	m_cabeza.radial_segments = 28
	m_cabeza.rings = 14
	m_cabeza.material = mat_plasma
	var mi_cabeza = MeshInstance3D.new()
	mi_cabeza.name = "CabezaJoroba"
	mi_cabeza.mesh = m_cabeza
	mi_cabeza.position = Vector3(0, 1.02, 0.08)
	nodo_cuerpo.add_child(mi_cabeza)

	# Bultos laterales secundarios (asimetría viva del monstruo de slime)
	var m_bulto_izq = SphereMesh.new()
	m_bulto_izq.radius = 0.38
	m_bulto_izq.height = 0.42
	m_bulto_izq.radial_segments = 20
	m_bulto_izq.rings = 10
	m_bulto_izq.material = mat_plasma
	var mi_bulto_izq = MeshInstance3D.new()
	mi_bulto_izq.mesh = m_bulto_izq
	mi_bulto_izq.position = Vector3(-0.45, 0.42, 0.12)
	nodo_cuerpo.add_child(mi_bulto_izq)

	var m_bulto_der = SphereMesh.new()
	m_bulto_der.radius = 0.42
	m_bulto_der.height = 0.46
	m_bulto_der.radial_segments = 20
	m_bulto_der.rings = 10
	m_bulto_der.material = mat_plasma
	var mi_bulto_der = MeshInstance3D.new()
	mi_bulto_der.mesh = m_bulto_der
	mi_bulto_der.position = Vector3(0.48, 0.38, -0.1)
	nodo_cuerpo.add_child(mi_bulto_der)

	# Gotas y charco viscoso perimetral en la base (volumen 3D elipsoidal)
	for i in range(8):
		var angulo = i * (PI * 2.0 / 8.0) + (i * 0.15)
		var dist = randf_range(0.68, 0.88)
		var gota_m = SphereMesh.new()
		gota_m.radius = randf_range(0.18, 0.28)
		gota_m.height = randf_range(0.12, 0.18)
		gota_m.radial_segments = 16
		gota_m.rings = 8
		gota_m.material = mat_plasma
		var mi_gota = MeshInstance3D.new()
		mi_gota.mesh = gota_m
		mi_gota.position = Vector3(cos(angulo) * dist, 0.08, sin(angulo) * dist)
		nodo_cuerpo.add_child(mi_gota)

	# --- 2. NÚCLEO INTERNO DE FISIÓN QUE BRILLA DENTRO DEL SLIME ---
	var m_fision = SphereMesh.new()
	m_fision.radius = 0.26
	m_fision.height = 0.28
	m_fision.radial_segments = 16
	m_fision.rings = 8
	m_fision.material = mat_nucleo
	var mi_fision = MeshInstance3D.new()
	mi_fision.name = "NucleoFisionInterno"
	mi_fision.mesh = m_fision
	mi_fision.position = Vector3(0, 0.65, 0.05)
	nodo_cuerpo.add_child(mi_fision)

	# Ojos amenazantes cartoon (orbes con brillo amarillento)
	var mat_ojo = StandardMaterial3D.new()
	mat_ojo.albedo_color = Color(1.0, 0.9, 0.2)
	mat_ojo.emission_enabled = true
	mat_ojo.emission = Color(1.0, 0.85, 0.1)
	mat_ojo.emission_energy_multiplier = 0.9

	var m_ojo = SphereMesh.new()
	m_ojo.radius = 0.09
	m_ojo.height = 0.14
	m_ojo.material = mat_ojo

	var mi_ojo_izq = MeshInstance3D.new()
	mi_ojo_izq.mesh = m_ojo
	mi_ojo_izq.position = Vector3(-0.18, 1.08, 0.38)
	mi_ojo_izq.rotation_degrees = Vector3(15, -15, -10)
	nodo_cuerpo.add_child(mi_ojo_izq)

	var mi_ojo_der = MeshInstance3D.new()
	mi_ojo_der.mesh = m_ojo
	mi_ojo_der.position = Vector3(0.18, 1.08, 0.38)
	mi_ojo_der.rotation_degrees = Vector3(15, 15, 10)
	nodo_cuerpo.add_child(mi_ojo_der)

	# --- 3. TALADRO INDUSTRIAL DE MINERÍA 3D REAL (Modelado cónico y helicoidal) ---
	var nodo_taladro = Node3D.new()
	nodo_taladro.name = "TaladroIndustrial"
	nodo_taladro.position = Vector3(0.35, 0.82, 0.42)
	nodo_taladro.rotation_degrees = Vector3(-18, 28, 5)
	raiz.add_child(nodo_taladro)

	# Collarín / anillo de anclaje de latón
	var m_anillo = TorusMesh.new()
	m_anillo.inner_radius = 0.16
	m_anillo.outer_radius = 0.28
	m_anillo.material = mat_bronce
	var mi_anillo = MeshInstance3D.new()
	mi_anillo.mesh = m_anillo
	mi_anillo.rotation_degrees = Vector3(90, 0, 0)
	nodo_taladro.add_child(mi_anillo)

	# Carcasa base del motor del taladro
	var m_motor = CylinderMesh.new()
	m_motor.top_radius = 0.22
	m_motor.bottom_radius = 0.24
	m_motor.height = 0.22
	m_motor.radial_segments = 20
	m_motor.material = mat_metal_taladro
	var mi_motor = MeshInstance3D.new()
	mi_motor.mesh = m_motor
	mi_motor.position = Vector3(0, 0, 0.1)
	mi_motor.rotation_degrees = Vector3(90, 0, 0)
	nodo_taladro.add_child(mi_motor)

	# Cono principal del taladro
	var m_cono_taladro = CylinderMesh.new()
	m_cono_taladro.top_radius = 0.02
	m_cono_taladro.bottom_radius = 0.22
	m_cono_taladro.height = 0.65
	m_cono_taladro.radial_segments = 24
	m_cono_taladro.material = mat_metal_taladro
	var mi_cono_taladro = MeshInstance3D.new()
	mi_cono_taladro.mesh = m_cono_taladro
	mi_cono_taladro.position = Vector3(0, 0, 0.48)
	mi_cono_taladro.rotation_degrees = Vector3(90, 0, 0)
	nodo_taladro.add_child(mi_cono_taladro)

	# Espirales cortantes del taladro (3 anillos escalonados con estrías afiladas)
	var radios_taladro = [0.20, 0.15, 0.10, 0.06]
	var pos_z_taladro = [0.26, 0.42, 0.58, 0.72]
	for idx in range(radios_taladro.size()):
		var m_filo = TorusMesh.new()
		m_filo.inner_radius = radios_taladro[idx] * 0.7
		m_filo.outer_radius = radios_taladro[idx] * 1.15
		m_filo.material = mat_bronce
		var mi_filo = MeshInstance3D.new()
		mi_filo.mesh = m_filo
		mi_filo.position = Vector3(0, 0, pos_z_taladro[idx])
		mi_filo.rotation_degrees = Vector3(90, idx * 35.0, 0)
		nodo_taladro.add_child(mi_filo)

	# --- 4. DOS CHIMENEAS DE ESCAPE INDUSTRIALES EN LA ESPALDA ---
	var nodo_escape = Node3D.new()
	nodo_escape.name = "ChimeneasEscape"
	nodo_escape.position = Vector3(-0.15, 0.98, -0.32)
	raiz.add_child(nodo_escape)

	for lado in [-1, 1]:
		var nodo_tubo = Node3D.new()
		nodo_tubo.position = Vector3(lado * 0.18, 0, 0)
		nodo_tubo.rotation_degrees = Vector3(-25, lado * 12, lado * 6)
		nodo_escape.add_child(nodo_tubo)

		# Tubo principal
		var m_tubo = CylinderMesh.new()
		m_tubo.top_radius = 0.09
		m_tubo.bottom_radius = 0.10
		m_tubo.height = 0.52
		m_tubo.radial_segments = 16
		m_tubo.material = mat_chimenea
		var mi_tubo = MeshInstance3D.new()
		mi_tubo.mesh = m_tubo
		mi_tubo.position = Vector3(0, 0.26, 0)
		nodo_tubo.add_child(mi_tubo)

		# Borde superior biselado de la chimenea
		var m_boca = TorusMesh.new()
		m_boca.inner_radius = 0.06
		m_boca.outer_radius = 0.11
		m_boca.material = mat_bronce
		var mi_boca = MeshInstance3D.new()
		mi_boca.mesh = m_boca
		mi_boca.position = Vector3(0, 0.52, 0)
		nodo_tubo.add_child(mi_boca)

		# Resplandor de calor dentro de la boca
		var m_fuego = SphereMesh.new()
		m_fuego.radius = 0.05
		m_fuego.height = 0.06
		m_fuego.material = mat_nucleo
		var mi_fuego = MeshInstance3D.new()
		mi_fuego.mesh = m_fuego
		mi_fuego.position = Vector3(0, 0.48, 0)
		nodo_tubo.add_child(mi_fuego)

	# --- 5. FARDOS DE DINAMITA Y CORREAS INDUSTRIALES ---
	var nodo_dinamita = Node3D.new()
	nodo_dinamita.name = "DinamitaIncrustada"
	nodo_dinamita.position = Vector3(-0.48, 0.58, 0.15)
	nodo_dinamita.rotation_degrees = Vector3(10, -35, -20)
	raiz.add_child(nodo_dinamita)

	# 3 Cartuchos de dinamita
	var offsets_dinamita = [
		Vector3(-0.06, 0, -0.04),
		Vector3(0.06, 0, -0.04),
		Vector3(0, 0.08, 0.03)
	]
	for pos_d in offsets_dinamita:
		var m_cartucho = CylinderMesh.new()
		m_cartucho.top_radius = 0.045
		m_cartucho.bottom_radius = 0.045
		m_cartucho.height = 0.38
		m_cartucho.radial_segments = 14
		m_cartucho.material = mat_dinamita
		var mi_cart = MeshInstance3D.new()
		mi_cart.mesh = m_cartucho
		mi_cart.position = pos_d
		nodo_dinamita.add_child(mi_cart)

		# Mecha
		var m_cordon = CylinderMesh.new()
		m_cordon.top_radius = 0.008
		m_cordon.bottom_radius = 0.01
		m_cordon.height = 0.10
		m_cordon.material = mat_mecha
		var mi_cord = MeshInstance3D.new()
		mi_cord.mesh = m_cordon
		mi_cord.position = pos_d + Vector3(0, 0.23, 0)
		mi_cord.rotation_degrees = Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		nodo_dinamita.add_child(mi_cord)

		# Chispa incandescente
		var m_chis = SphereMesh.new()
		m_chis.radius = 0.016
		m_chis.height = 0.025
		m_chis.material = mat_chispa
		var mi_chis = MeshInstance3D.new()
		mi_chis.mesh = m_chis
		mi_chis.position = mi_cord.position + Vector3(0, 0.06, 0)
		nodo_dinamita.add_child(mi_chis)

	# Correa que sujeta los cartuchos
	var m_cinturon = TorusMesh.new()
	m_cinturon.inner_radius = 0.09
	m_cinturon.outer_radius = 0.14
	m_cinturon.material = mat_correa
	var mi_cin = MeshInstance3D.new()
	mi_cin.mesh = m_cinturon
	mi_cin.position = Vector3(0, 0.02, 0)
	mi_cin.scale = Vector3(1.1, 0.6, 1.1)
	nodo_dinamita.add_child(mi_cin)

	# --- 6. FIJAR DUEÑO RECURSIVO PARA EMPAQUETADO ---
	_fijar_dueno(raiz, raiz)

	# --- 7. EXPORTAR A GLB Y GUARDAR EN CACHÉ SCN DIRECTA ---
	var glb_path = "res://assets/modelos/enemigo_minero_kamikaze.glb"
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	gltf.append_from_scene(raiz, state)
	var err_glb = gltf.write_to_filesystem(state, glb_path)
	if err_glb == OK:
		print("✓ GLB exportado exitosamente a: ", glb_path)
	else:
		printerr("Error exportando GLB: ", err_glb)

	# Empacar escena y guardar directamente en la caché del editor .scn
	var pack = PackedScene.new()
	pack.pack(raiz)
	var scn_path = "res://.godot/imported/enemigo_minero_kamikaze.glb-9514f285b656a6f57a4e706e42c7fdb2.scn"
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
