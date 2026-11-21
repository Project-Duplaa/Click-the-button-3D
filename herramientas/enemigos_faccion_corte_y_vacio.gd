@tool
class_name EnemigosFaccionCorteYVacio
extends RefCounted

const Kit = preload("res://herramientas/enemigos_pbr_kit.gd")


static func _agregar_hijos(padre: Node3D, hijos: Array) -> void:
	for h in hijos:
		if h is Node:
			padre.add_child(h)


static func _garantizar_y_raiz(nodo: Node3D, rig: Node3D, y_objetivo_raiz: float) -> void:
	if nodo == null or rig == null:
		return
	var offset_acum: float = rig.position.y
	var p := nodo.get_parent()
	while p != null and p != rig:
		if p is Node3D:
			offset_acum += (p as Node3D).position.y
		p = p.get_parent()
	nodo.position.y = y_objetivo_raiz - offset_acum


# ==============================================================================
# 1. MAESTRA SANGUINARIA (~3.45m)
# ==============================================================================

static func maestra() -> Node3D:
	var res := Kit.crear_raiz_enemigo("MaestraSanguinaria")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_obs := Kit.tex_acero_bunker(Color(0.18, 0.17, 0.22), 1101)
	var t_lat := Kit.tex_bronce_oxidado(Color(0.50, 0.37, 0.18), 1102)
	var t_tel := Kit.tex_tela_tactica(Color(0.36, 0.08, 0.12), Color(0.16, 0.04, 0.06), Color(0.14, 0.10, 0.10), true, 1103)

	var m_obs := Kit.mat_pbr(Color(0.86, 0.86, 0.90), 0.48, 0.44, t_obs)
	var m_carb := Kit.mat_pbr(Color(0.14, 0.14, 0.17), 0.34, 0.54, t_obs)
	var m_lat := Kit.mat_pbr(Color(0.92, 0.88, 0.78), 0.56, 0.44, t_lat)
	var m_tela := Kit.mat_pbr(Color(1.0, 1.0, 1.0), 0.04, 0.82, t_tel, 0.99, true)
	var m_masc := Kit.mat_pbr(Color(0.42, 0.08, 0.12), 0.36, 0.48)
	var m_ala := Kit.mat_pbr(Color(0.24, 0.05, 0.09), 0.12, 0.62, {}, 0.88, true)
	var m_acero_filo := Kit.mat_pbr(Color(0.18, 0.19, 0.23), 0.58, 0.38, t_obs)

	var m_rubi := Kit.mat_emissive(Color(0.45, 0.05, 0.12), Color(0.92, 0.12, 0.24), 0.55, 0.32)
	var m_nervio_ala := Kit.mat_emissive(Color(0.22, 0.04, 0.08), Color(0.70, 0.10, 0.20), 0.15, 0.48)

	for lado in [-1.0, 1.0]:
		var p_nodo := Node3D.new()
		p_nodo.name = "PiernaDer" if lado < 0.0 else "PiernaIzq"
		p_nodo.position = Vector3(lado * 0.14, 1.50, 0.0)
		rig.add_child(p_nodo)

		var muslo := Kit.loft_perfil([
			{"y": -0.68, "rx": 0.075, "rz": 0.080, "bevel": 0.2},
			{"y": -0.34, "rx": 0.095, "rz": 0.105, "bevel": 0.25},
			{"y": 0.0, "rx": 0.105, "rz": 0.110, "bevel": 0.25},
		], m_carb, 14)
		var rodillera := Kit.prisma_biselado(Vector3(0.14, 0.16, 0.11), 0.025, m_lat, Vector3(0.0, -0.68, 0.06))
		var bota := Kit.loft_perfil([
			{"y": -1.42, "rx": 0.065, "rz": 0.075, "bevel": 0.3},
			{"y": -1.10, "rx": 0.082, "rz": 0.092, "bevel": 0.3},
			{"y": -0.72, "rx": 0.092, "rz": 0.102, "bevel": 0.35},
		], m_obs, 14)
		var ribete_bota := Kit.toro(0.098, 0.086, m_lat, Vector3(0.0, -0.75, 0.0))
		var pie := Kit.prisma_biselado(Vector3(0.13, 0.11, 0.28), 0.025, m_obs, Vector3(0.0, -1.445, 0.055), Vector3.ZERO, Vector2(0.85, 0.72))
		var tacon := Kit.caja(Vector3(0.07, 0.09, 0.08), m_lat, Vector3(0.0, -1.455, -0.055))
		_agregar_hijos(p_nodo, [muslo, rodillera, bota, ribete_bota, pie, tacon])

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.50, 0.0)
	rig.add_child(torso)

	var peto := Kit.loft_perfil([
		{"y": -0.04, "rx": 0.18, "rz": 0.14, "bevel": 0.35},
		{"y": 0.28, "rx": 0.145, "rz": 0.115, "bevel": 0.35},
		{"y": 0.68, "rx": 0.23, "rz": 0.16, "bevel": 0.40},
		{"y": 0.98, "rx": 0.25, "rz": 0.165, "bevel": 0.38},
		{"y": 1.12, "rx": 0.11, "rz": 0.10, "bevel": 0.2},
	], m_obs, 16)
	torso.add_child(peto)

	torso.add_child(Kit.loft_perfil([
		{"y": 0.02, "rx": 0.198, "rz": 0.155, "bevel": 0.45},
		{"y": 0.16, "rx": 0.182, "rz": 0.142, "bevel": 0.45},
	], m_lat, 16))
	torso.add_child(Kit.prisma_biselado(Vector3(0.11, 0.11, 0.05), 0.015, m_lat, Vector3(0.0, 0.09, 0.155)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.18, 0.24, 0.06), 0.02, m_lat, Vector3(0.0, 0.72, 0.145), Vector3(-6.0, 0.0, 0.0), Vector2(1.2, 0.9)))

	var faldon_izq := Kit.capa_colgante(0.06, -0.92, 0.20, 0.16, 0.34, 0.26, 72.0, 168.0, m_tela, 0.055)
	var faldon_der := Kit.capa_colgante(0.06, -0.92, 0.20, 0.16, 0.34, 0.26, -168.0, -72.0, m_tela, 0.055)
	var faldon_espalda := Kit.capa_colgante(0.10, -1.04, 0.19, 0.15, 0.36, 0.28, 138.0, 222.0, m_tela, 0.065)
	_agregar_hijos(torso, [faldon_izq, faldon_der, faldon_espalda])

	torso.add_child(Kit.hombrera_curva(0.17, 0.04, 0.22, 135.0, m_obs, Vector3(-0.27, 0.98, 0.0), Vector3(0.0, -90.0, 18.0)))
	torso.add_child(Kit.hombrera_curva(0.15, 0.035, 0.19, 125.0, m_lat, Vector3(0.26, 0.97, 0.0), Vector3(0.0, 90.0, -16.0)))

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.15, 0.02)
	torso.add_child(cabeza)

	cabeza.add_child(Kit.loft_perfil([
		{"y": 0.0, "rx": 0.09, "rz": 0.09, "bevel": 0.2},
		{"y": 0.14, "rx": 0.135, "rz": 0.155, "bevel": 0.3},
		{"y": 0.34, "rx": 0.145, "rz": 0.17, "bevel": 0.3},
		{"y": 0.48, "rx": 0.105, "rz": 0.125, "bevel": 0.25},
	], m_obs, 16))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.18, 0.28, 0.11), 0.03, m_masc, Vector3(0.0, 0.24, 0.125), Vector3(6.0, 0.0, 0.0), Vector2(0.76, 0.72)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.036, 0.26, 0.05), 0.008, m_lat, Vector3(0.0, 0.24, 0.172), Vector3(6.0, 0.0, 0.0)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.13, 0.025, 0.05), 0.006, m_lat, Vector3(0.0, 0.14, 0.17), Vector3(6.0, 0.0, 0.0)))
	cabeza.add_child(Kit.caja(Vector3(0.048, 0.014, 0.022), m_rubi, Vector3(-0.042, 0.28, 0.178), Vector3(0.0, -10.0, -12.0)))
	cabeza.add_child(Kit.caja(Vector3(0.048, 0.014, 0.022), m_rubi, Vector3(0.042, 0.28, 0.178), Vector3(0.0, 10.0, 12.0)))
	cabeza.add_child(Kit.toro(0.145, 0.125, m_lat, Vector3(0.0, 0.42, 0.0), Vector3(-8.0, 0.0, 0.0)))
	for i in range(5):
		var ang_deg: float = -64.0 + float(i) * 32.0
		var rad := deg_to_rad(ang_deg)
		var h_pua := 0.34 if i == 2 else (0.27 if (i == 1 or i == 3) else 0.21)
		var px := sin(rad) * 0.125
		var pz := cos(rad) * 0.125
		cabeza.add_child(Kit.cyl(0.004, 0.026, h_pua, m_lat, Vector3(px, 0.43 + h_pua * 0.5, pz), Vector3(-12.0 * cos(rad), 0.0, -14.0 * sin(rad)), 8))

	var alas := Node3D.new()
	alas.name = "Alas"
	alas.position = Vector3(0.0, 0.88, -0.17)
	torso.add_child(alas)

	for lado in [-1.0, 1.0]:
		var ala_sub := Node3D.new()
		ala_sub.name = "AletaDer" if lado < 0.0 else "AletaIzq"
		ala_sub.position = Vector3(lado * 0.12, 0.0, 0.0)
		ala_sub.rotation_degrees = Vector3(-10.0, lado * -24.0, lado * -20.0)
		alas.add_child(ala_sub)

		for f_idx in range(3):
			var ang_f := float(f_idx) * 16.0 - 8.0
			var largo_f := 1.05 - float(f_idx) * 0.16
			var bastidor := Kit.prisma_biselado(Vector3(0.036, largo_f, 0.042), 0.008, m_carb, Vector3(lado * (0.28 + float(f_idx) * 0.10), 0.20 - float(f_idx) * 0.14, -0.05), Vector3(0.0, 0.0, lado * (-32.0 - ang_f)), Vector2(0.45, 0.65))
			var panel := Kit.prisma_biselado(Vector3(0.18, largo_f * 0.88, 0.014), 0.004, m_ala, Vector3(lado * (0.34 + float(f_idx) * 0.10), 0.14 - float(f_idx) * 0.14, -0.06), Vector3(0.0, 0.0, lado * (-32.0 - ang_f)), Vector2(0.38, 1.0))
			var nervio := Kit.caja(Vector3(0.009, largo_f * 0.72, 0.018), m_nervio_ala, Vector3(lado * (0.33 + float(f_idx) * 0.10), 0.16 - float(f_idx) * 0.14, -0.058), Vector3(0.0, 0.0, lado * (-32.0 - ang_f)))
			_agregar_hijos(ala_sub, [bastidor, panel, nervio])

	var brazo_der := Node3D.new()
	brazo_der.name = "BrazoDer"
	brazo_der.position = Vector3(-0.30, 0.96, 0.0)
	torso.add_child(brazo_der)

	brazo_der.add_child(Kit.cyl(0.055, 0.048, 0.44, m_carb, Vector3(0.0, -0.22, 0.0)))
	brazo_der.add_child(Kit.cyl(0.052, 0.044, 0.42, m_obs, Vector3(0.0, -0.62, 0.05), Vector3(-16.0, 0.0, 0.0)))
	brazo_der.add_child(Kit.toro(0.058, 0.048, m_lat, Vector3(0.0, -0.44, 0.0)))

	var estoque := Node3D.new()
	estoque.name = "EstoqueMonomolecular"
	estoque.position = Vector3(0.0, -0.82, 0.12)
	estoque.rotation_degrees = Vector3(74.0, 0.0, 0.0)
	brazo_der.add_child(estoque)

	estoque.add_child(Kit.cyl(0.022, 0.024, 0.22, m_lat, Vector3(0.0, -0.04, 0.0)))
	estoque.add_child(Kit.cyl(0.11, 0.05, 0.07, m_lat, Vector3(0.0, 0.06, 0.0)))
	estoque.add_child(Kit.hoja_filo(1.38, 0.055, 0.022, 0.0, m_acero_filo, 8, Vector3(0.0, 0.09, 0.0)))
	estoque.add_child(Kit.caja(Vector3(0.008, 1.12, 0.025), m_rubi, Vector3(0.0, 0.68, 0.0)))

	var brazo_izq := Node3D.new()
	brazo_izq.name = "BrazoIzq"
	brazo_izq.position = Vector3(0.30, 0.96, 0.0)
	torso.add_child(brazo_izq)

	brazo_izq.add_child(Kit.cyl(0.055, 0.048, 0.44, m_carb, Vector3(0.0, -0.22, 0.0)))
	brazo_izq.add_child(Kit.prisma_biselado(Vector3(0.11, 0.44, 0.12), 0.02, m_obs, Vector3(0.0, -0.62, 0.05), Vector3(-14.0, 0.0, 0.0), Vector2(0.85, 0.85)))
	brazo_izq.add_child(Kit.prisma_biselado(Vector3(0.125, 0.12, 0.135), 0.015, m_lat, Vector3(0.0, -0.58, 0.05), Vector3(-14.0, 0.0, 0.0)))
	for g_idx in range(3):
		var gz := -0.03 + float(g_idx) * 0.03
		brazo_izq.add_child(Kit.hoja_filo(0.24, 0.022, 0.012, 0.015, m_lat, 4, Vector3(0.04, -0.84, 0.10 + gz), Vector3(145.0, 0.0, 0.0)))

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig, 26.0)
	return raiz


# ==============================================================================
# 2. LA PARCA ROJA (~4.15m)
# ==============================================================================

static func parca() -> Node3D:
	var res := Kit.crear_raiz_enemigo("ParcaRoja")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_tel_ext := Kit.tex_tela_tactica(Color(0.32, 0.06, 0.10), Color(0.10, 0.03, 0.05), Color(0.10, 0.08, 0.08), true, 2101)
	var t_tel_int := Kit.tex_tela_tactica(Color(0.22, 0.04, 0.07), Color(0.07, 0.02, 0.03), Color(0.08, 0.06, 0.06), true, 2102)
	var t_hierro := Kit.tex_acero_bunker(Color(0.12, 0.12, 0.14), 2103)
	var t_bronce := Kit.tex_bronce_oxidado(Color(0.46, 0.34, 0.18), 2104)
	var t_hue := Kit.tex_hueso_ceramico(2105)

	var m_manto_ext := Kit.mat_pbr(Color(1.0, 1.0, 1.0), 0.02, 0.85, t_tel_ext, 0.99, true)
	var m_manto_int := Kit.mat_pbr(Color(0.95, 0.95, 0.95), 0.02, 0.86, t_tel_int, 0.99, true)
	var m_sombra := Kit.mat_pbr(Color(0.04, 0.04, 0.05), 0.0, 0.90, {}, 1.0, true)
	var m_hierro := Kit.mat_pbr(Color(0.84, 0.84, 0.88), 0.56, 0.48, t_hierro)
	var m_bronce := Kit.mat_pbr(Color(0.90, 0.86, 0.78), 0.52, 0.50, t_bronce)
	var m_hueso := Kit.mat_pbr(Color(0.94, 0.90, 0.84), 0.08, 0.54, t_hue)

	var m_brasa := Kit.mat_emissive(Color(0.24, 0.03, 0.04), Color(0.86, 0.18, 0.06), 0.45, 0.45)
	var m_ojos := Kit.mat_emissive(Color(0.50, 0.04, 0.08), Color(0.95, 0.14, 0.18), 0.65, 0.25)
	var m_filo_cal := Kit.mat_emissive(Color(0.42, 0.08, 0.05), Color(0.94, 0.24, 0.08), 0.55, 0.35)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.position = Vector3.ZERO
	rig.add_child(cuerpo)

	cuerpo.add_child(Kit.loft_perfil([
		{"y": 0.18, "rx": 0.38, "rz": 0.34, "bevel": 0.1},
		{"y": 1.65, "rx": 0.30, "rz": 0.25, "bevel": 0.2},
		{"y": 2.95, "rx": 0.42, "rz": 0.26, "bevel": 0.3},
		{"y": 3.22, "rx": 0.18, "rz": 0.16, "bevel": 0.2},
	], m_sombra, 16))

	var capa_interna := Kit.capa_colgante(3.10, 0.08, 0.44, 0.28, 0.72, 0.52, -165.0, 165.0, m_manto_int, 0.08)
	var capa_externa := Kit.capa_colgante(3.26, 0.0, 0.52, 0.34, 0.84, 0.60, 42.0, 318.0, m_manto_ext, 0.10)
	_agregar_hijos(cuerpo, [capa_interna, capa_externa])

	for lado in [-1.0, 1.0]:
		cuerpo.add_child(Kit.hombrera_curva(0.32, 0.07, 0.36, 150.0, m_hierro, Vector3(lado * 0.52, 3.04, 0.0), Vector3(0.0, lado * 90.0, lado * -20.0)))
		cuerpo.add_child(Kit.hombrera_curva(0.28, 0.05, 0.14, 140.0, m_bronce, Vector3(lado * 0.50, 3.16, 0.02), Vector3(0.0, lado * 90.0, lado * -14.0)))

	cuerpo.add_child(Kit.esfera(0.20, m_brasa, Vector3(0.0, 2.50, 0.14), Vector3(0.95, 1.25, 0.72)))
	cuerpo.add_child(Kit.prisma_biselado(Vector3(0.14, 0.78, 0.12), 0.025, m_hierro, Vector3(0.0, 2.52, 0.28)))
	for r_idx in range(4):
		var ry := 2.24 + float(r_idx) * 0.18
		var rad_c := 0.24 + sin(float(r_idx) * 0.6) * 0.04
		var costilla := Kit.arco_curvo(rad_c, 0.042, ry - 0.032, ry + 0.032, -78.0, 78.0, m_hierro, 12)
		costilla.position = Vector3(0.0, 0.0, 0.11)
		cuerpo.add_child(costilla)

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 3.22, 0.04)
	cuerpo.add_child(cabeza)

	cabeza.add_child(Kit.loft_perfil([
		{"y": 0.0, "rx": 0.22, "rz": 0.22, "bevel": 0.2},
		{"y": 0.34, "rx": 0.29, "rz": 0.34, "z_off": 0.04, "bevel": 0.28},
		{"y": 0.68, "rx": 0.23, "rz": 0.32, "z_off": -0.02, "bevel": 0.22},
		{"y": 0.84, "rx": 0.05, "rz": 0.10, "z_off": -0.14, "bevel": 0.1},
	], m_manto_ext, 16))
	cabeza.add_child(Kit.esfera(0.19, m_sombra, Vector3(0.0, 0.34, 0.02), Vector3(0.92, 1.15, 0.96)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.22, 0.32, 0.14), 0.04, m_hueso, Vector3(0.0, 0.33, 0.15), Vector3(6.0, 0.0, 0.0), Vector2(0.84, 0.78)))
	cabeza.add_child(Kit.cyl(0.05, 0.06, 0.09, m_hierro, Vector3(0.0, 0.20, 0.22), Vector3(85.0, 0.0, 0.0), 10))
	cabeza.add_child(Kit.esfera(0.024, m_ojos, Vector3(-0.055, 0.38, 0.225)))
	cabeza.add_child(Kit.esfera(0.024, m_ojos, Vector3(0.055, 0.38, 0.225)))

	var anillo1 := Node3D.new()
	anillo1.name = "Anillo1"
	anillo1.position = Vector3(0.0, 3.16, -0.28)
	anillo1.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	cuerpo.add_child(anillo1)

	for seg in [[18.0, 78.0], [96.0, 158.0], [182.0, 246.0], [268.0, 342.0]]:
		var arc := Kit.arco_curvo(0.94, 0.08, -0.045, 0.045, float(seg[0]), float(seg[1]), m_bronce, 10)
		anillo1.add_child(arc)

	var brazo_izq := Node3D.new()
	brazo_izq.name = "BrazoIzq"
	brazo_izq.position = Vector3(0.60, 2.94, 0.04)
	cuerpo.add_child(brazo_izq)
	brazo_izq.add_child(Kit.cyl(0.095, 0.08, 0.68, m_sombra, Vector3(0.0, -0.34, 0.0)))
	brazo_izq.add_child(Kit.prisma_biselado(Vector3(0.18, 0.62, 0.18), 0.03, m_hierro, Vector3(0.0, -0.92, 0.12), Vector3(-24.0, 0.0, 0.0)))

	var brazo_der := Node3D.new()
	brazo_der.name = "BrazoDer"
	brazo_der.position = Vector3(-0.60, 2.94, 0.04)
	cuerpo.add_child(brazo_der)
	brazo_der.add_child(Kit.cyl(0.095, 0.08, 0.68, m_sombra, Vector3(0.0, -0.34, 0.0)))
	brazo_der.add_child(Kit.prisma_biselado(Vector3(0.18, 0.62, 0.18), 0.03, m_hierro, Vector3(0.0, -0.92, 0.14), Vector3(-28.0, 0.0, 0.0)))

	var guadana := Node3D.new()
	guadana.name = "GuadanaSentencia"
	guadana.position = Vector3(-0.04, -1.16, 0.28)
	guadana.rotation_degrees = Vector3(58.0, 0.0, -8.0)
	brazo_der.add_child(guadana)

	guadana.add_child(Kit.cyl(0.042, 0.046, 3.35, m_hierro, Vector3(0.0, 0.28, 0.0), Vector3.ZERO, 12))
	for ay in [-1.05, -0.30, 0.45, 1.25, 1.85]:
		guadana.add_child(Kit.toro(0.068, 0.044, m_bronce, Vector3(0.0, ay, 0.0)))
	guadana.add_child(Kit.prisma_biselado(Vector3(0.22, 0.28, 0.16), 0.03, m_hierro, Vector3(0.05, 1.92, 0.0)))
	var hoja_base := Kit.hoja_filo(1.52, 0.26, 0.055, 0.56, m_hierro, 12, Vector3(0.06, 1.95, 0.0), Vector3(0.0, 90.0, -96.0))
	var filo_estrecho := Kit.hoja_filo(1.48, 0.042, 0.022, 0.56, m_filo_cal, 12, Vector3(0.06, 1.95, 0.115), Vector3(0.0, 90.0, -96.0))
	_agregar_hijos(guadana, [hoja_base, filo_estrecho])

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_flote(raiz, rig)
	return raiz


# ==============================================================================
# 3. CANALIZADOR DEL VACÍO (~2.45m, NucleoSingularidad obligatorio en y = 1.85)
# ==============================================================================

static func canalizador_vacio() -> Node3D:
	var res := Kit.crear_raiz_enemigo("CanalizadorVacio")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_obs := Kit.tex_acero_bunker(Color(0.13, 0.12, 0.17), 3101)
	var t_cobre := Kit.tex_bronce_oxidado(Color(0.56, 0.34, 0.19), 3102)
	var t_tit := Kit.tex_acero_bunker(Color(0.20, 0.21, 0.27), 3103)

	var m_obs := Kit.mat_pbr(Color(0.86, 0.85, 0.92), 0.48, 0.54, t_obs)
	var m_cobre := Kit.mat_pbr(Color(0.92, 0.84, 0.78), 0.58, 0.44, t_cobre)
	var m_tit := Kit.mat_pbr(Color(0.84, 0.86, 0.94), 0.55, 0.46, t_tit)

	var m_nucleo := Kit.mat_emissive(Color(0.03, 0.02, 0.05), Color(0.42, 0.16, 0.78), 0.42, 0.68)
	var m_indigo := Kit.mat_emissive(Color(0.14, 0.12, 0.32), Color(0.32, 0.24, 0.78), 0.48, 0.36)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.position = Vector3.ZERO
	rig.add_child(cuerpo)

	for i in range(3):
		var ang := deg_to_rad(60.0 + float(i) * 120.0)
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var pata := Kit.tubo_curvo([
			dir * 0.18 + Vector3(0.0, 0.48, 0.0),
			dir * 0.44 + Vector3(0.0, 0.26, 0.0),
			dir * 0.68 + Vector3(0.0, 0.05, 0.0),
		], 0.09, 0.07, m_obs, 10)
		var zapata := Kit.prisma_biselado(Vector3(0.22, 0.10, 0.26), 0.02, m_obs, dir * 0.70 + Vector3(0.0, 0.05, 0.0), Vector3(0.0, rad_to_deg(ang), 0.0), Vector2(0.75, 0.75))
		_agregar_hijos(cuerpo, [pata, zapata])

	cuerpo.add_child(Kit.loft_perfil([
		{"y": 0.16, "rx": 0.24, "rz": 0.24, "bevel": 0.55},
		{"y": 0.55, "rx": 0.30, "rz": 0.30, "bevel": 0.60},
		{"y": 1.15, "rx": 0.21, "rz": 0.21, "bevel": 0.55},
		{"y": 1.46, "rx": 0.26, "rz": 0.26, "bevel": 0.60},
	], m_obs, 12))
	cuerpo.add_child(Kit.toro(0.30, 0.23, m_cobre, Vector3(0.0, 1.38, 0.0)))

	for i in range(4):
		var ang := deg_to_rad(45.0 + float(i) * 90.0)
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var aleta := Kit.tubo_curvo([
			dir * 0.24 + Vector3(0.0, 1.36, 0.0),
			dir * 0.56 + Vector3(0.0, 1.66, 0.0),
			dir * 0.58 + Vector3(0.0, 2.02, 0.0),
			dir * 0.30 + Vector3(0.0, 2.38, 0.0),
		], 0.075, 0.036, m_obs, 8)
		var bobina := Kit.cyl(0.072, 0.072, 0.22, m_cobre, dir * 0.52 + Vector3(0.0, 1.72, 0.0), Vector3.ZERO, 10)
		var remate := Kit.prisma_biselado(Vector3(0.09, 0.14, 0.09), 0.015, m_cobre, dir * 0.29 + Vector3(0.0, 2.38, 0.0))
		_agregar_hijos(cuerpo, [aleta, bobina, remate])

	var anillo1 := Node3D.new()
	anillo1.name = "Anillo1"
	anillo1.position = Vector3(0.0, 1.85, 0.0)
	anillo1.rotation_degrees = Vector3(22.0, 0.0, 16.0)
	cuerpo.add_child(anillo1)
	anillo1.add_child(Kit.toro(0.45, 0.39, m_tit, Vector3.ZERO))
	for k in range(4):
		var a := deg_to_rad(float(k) * 90.0)
		anillo1.add_child(Kit.caja(Vector3(0.05, 0.05, 0.07), m_indigo, Vector3(sin(a) * 0.42, 0.0, cos(a) * 0.42), Vector3(0.0, rad_to_deg(a), 0.0)))

	var anillo2 := Node3D.new()
	anillo2.name = "Anillo2"
	anillo2.position = Vector3(0.0, 1.85, 0.0)
	anillo2.rotation_degrees = Vector3(-28.0, 45.0, -24.0)
	cuerpo.add_child(anillo2)
	anillo2.add_child(Kit.toro(0.36, 0.31, m_tit, Vector3.ZERO, Vector3(90.0, 0.0, 0.0)))
	for k in range(4):
		var a := deg_to_rad(float(k) * 90.0)
		anillo2.add_child(Kit.caja(Vector3(0.04, 0.06, 0.04), m_indigo, Vector3(sin(a) * 0.335, cos(a) * 0.335, 0.0)))

	var nucleo := Kit.esfera(0.24, m_nucleo, Vector3(0.0, 1.85, 0.0), Vector3.ONE, 20, 12)
	nucleo.name = "NucleoSingularidad"
	cuerpo.add_child(nucleo)

	Kit.normalizar_base_suelo(rig)
	_garantizar_y_raiz(nucleo, rig, 1.85)
	_garantizar_y_raiz(anillo1, rig, 1.85)
	_garantizar_y_raiz(anillo2, rig, 1.85)
	Kit.agregar_animaciones_flote(raiz, rig)
	return raiz


# ==============================================================================
# 4. ESPEJO SOMBRÍO (~2.90m)
# ==============================================================================

static func espejo_sombrio() -> Node3D:
	var res := Kit.crear_raiz_enemigo("EspejoSombrio")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_obs := Kit.tex_acero_bunker(Color(0.20, 0.19, 0.26), 4101)
	var t_peltre := Kit.tex_acero_bunker(Color(0.44, 0.45, 0.52), 4102)
	var t_lat := Kit.tex_bronce_oxidado(Color(0.42, 0.34, 0.22), 4103)
	var t_capa := Kit.tex_tela_tactica(Color(0.13, 0.12, 0.15), Color(0.05, 0.05, 0.07), Color(0.08, 0.08, 0.10), true, 4104)

	var m_obs := Kit.mat_pbr(Color(0.86, 0.86, 0.92), 0.48, 0.48, t_obs)
	var m_peltre := Kit.mat_pbr(Color(0.88, 0.89, 0.94), 0.56, 0.44, t_peltre)
	var m_lat_opaco := Kit.mat_pbr(Color(0.84, 0.80, 0.72), 0.46, 0.56, t_lat)
	var m_capa := Kit.mat_pbr(Color(0.95, 0.95, 0.95), 0.02, 0.86, t_capa, 0.99, true)
	var m_visor := Kit.mat_pbr(Color(0.12, 0.12, 0.16), 0.58, 0.36)

	var m_cristal := Kit.mat_emissive(Color(0.06, 0.04, 0.10), Color(0.38, 0.16, 0.62), 0.22, 0.32)
	var m_grieta_v := Kit.mat_emissive(Color(0.24, 0.10, 0.42), Color(0.64, 0.24, 0.92), 0.50, 0.30)

	for lado in [-1.0, 1.0]:
		var p_nodo := Node3D.new()
		p_nodo.name = "PiernaDer" if lado < 0.0 else "PiernaIzq"
		p_nodo.position = Vector3(lado * 0.19, 1.24, 0.0)
		rig.add_child(p_nodo)

		var muslo := Kit.prisma_biselado(Vector3(0.20, 0.58, 0.21), 0.03, m_obs, Vector3(0.0, -0.29, 0.0), Vector3.ZERO, Vector2(1.06, 1.06))
		var rodilla := Kit.prisma_biselado(Vector3(0.21, 0.18, 0.16), 0.025, m_peltre, Vector3(0.0, -0.58, 0.06))
		var greba := Kit.prisma_biselado(Vector3(0.19, 0.58, 0.20), 0.03, m_obs, Vector3(0.0, -0.88, 0.0), Vector3.ZERO, Vector2(1.05, 1.05))
		var bota := Kit.prisma_biselado(Vector3(0.21, 0.14, 0.34), 0.03, m_peltre, Vector3(0.0, -1.17, 0.06), Vector3.ZERO, Vector2(0.86, 0.78))
		_agregar_hijos(p_nodo, [muslo, rodilla, greba, bota])

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.24, 0.0)
	rig.add_child(torso)

	torso.add_child(Kit.loft_perfil([
		{"y": 0.0, "rx": 0.26, "rz": 0.18, "bevel": 0.55},
		{"y": 0.36, "rx": 0.24, "rz": 0.17, "bevel": 0.55},
		{"y": 0.78, "rx": 0.34, "rz": 0.22, "bevel": 0.55},
		{"y": 1.02, "rx": 0.28, "rz": 0.19, "bevel": 0.45},
	], m_obs, 16))
	torso.add_child(Kit.prisma_biselado(Vector3(0.46, 0.38, 0.20), 0.04, m_peltre, Vector3(0.0, 0.68, 0.13), Vector3(-6.0, 0.0, 0.0)))
	torso.add_child(Kit.capa_colgante(0.96, -0.88, 0.29, 0.19, 0.52, 0.30, 130.0, 230.0, m_capa, 0.08))

	for lado in [-1.0, 1.0]:
		torso.add_child(Kit.hombrera_curva(0.24, 0.055, 0.28, 130.0, m_obs, Vector3(lado * 0.38, 0.92, 0.0), Vector3(0.0, lado * 90.0, lado * -22.0)))
		torso.add_child(Kit.prisma_biselado(Vector3(0.18, 0.14, 0.26), 0.02, m_peltre, Vector3(lado * 0.40, 1.00, 0.0), Vector3(0.0, 0.0, lado * -24.0), Vector2(0.7, 0.8)))

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.05, 0.02)
	torso.add_child(cabeza)

	cabeza.add_child(Kit.prisma_biselado(Vector3(0.28, 0.38, 0.32), 0.06, m_obs, Vector3(0.0, 0.24, 0.0), Vector3.ZERO, Vector2(0.86, 0.88)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.23, 0.13, 0.12), 0.025, m_visor, Vector3(0.0, 0.27, 0.125)))
	cabeza.add_child(Kit.caja(Vector3(0.20, 0.014, 0.022), m_grieta_v, Vector3(0.01, 0.27, 0.182), Vector3(0.0, 0.0, 22.0)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.06, 0.22, 0.26), 0.015, m_peltre, Vector3(0.0, 0.48, -0.02)))

	var marco := Node3D.new()
	marco.name = "MarcoEspejoFracturado"
	marco.position = Vector3(0.0, 0.72, -0.34)
	torso.add_child(marco)

	marco.add_child(Kit.prisma_biselado(Vector3(0.96, 1.62, 0.08), 0.02, m_obs, Vector3.ZERO))
	marco.add_child(Kit.prisma_biselado(Vector3(0.84, 1.48, 0.095), 0.015, m_lat_opaco, Vector3.ZERO))
	marco.add_child(Kit.caja(Vector3(0.72, 1.34, 0.05), m_cristal, Vector3(0.0, 0.0, -0.015)))
	marco.add_child(Kit.prisma_biselado(Vector3(0.18, 0.34, 0.04), 0.01, m_cristal, Vector3(-0.62, 0.56, 0.04), Vector3(8.0, 12.0, 24.0), Vector2(0.45, 1.0)))
	marco.add_child(Kit.prisma_biselado(Vector3(0.16, 0.30, 0.04), 0.01, m_cristal, Vector3(0.64, 0.38, 0.05), Vector3(-6.0, -14.0, -28.0), Vector2(0.40, 1.0)))
	marco.add_child(Kit.prisma_biselado(Vector3(0.20, 0.28, 0.04), 0.01, m_cristal, Vector3(0.54, -0.58, 0.03), Vector3(10.0, -8.0, 18.0), Vector2(0.55, 1.0)))

	var brazo_izq := Node3D.new()
	brazo_izq.name = "BrazoIzq"
	brazo_izq.position = Vector3(0.40, 0.88, 0.0)
	torso.add_child(brazo_izq)
	brazo_izq.add_child(Kit.prisma_biselado(Vector3(0.15, 0.42, 0.15), 0.025, m_obs, Vector3(0.0, -0.21, 0.0)))
	brazo_izq.add_child(Kit.prisma_biselado(Vector3(0.16, 0.44, 0.16), 0.025, m_peltre, Vector3(0.0, -0.62, 0.05), Vector3(-16.0, 0.0, 0.0)))

	var brazo_der := Node3D.new()
	brazo_der.name = "BrazoDer"
	brazo_der.position = Vector3(-0.40, 0.88, 0.0)
	brazo_der.rotation_degrees = Vector3(-24.0, 0.0, -8.0)
	torso.add_child(brazo_der)
	brazo_der.add_child(Kit.prisma_biselado(Vector3(0.15, 0.42, 0.15), 0.025, m_obs, Vector3(0.0, -0.21, 0.0)))
	brazo_der.add_child(Kit.prisma_biselado(Vector3(0.16, 0.44, 0.16), 0.025, m_peltre, Vector3(0.0, -0.62, 0.05), Vector3(-16.0, 0.0, 0.0)))

	var mandoble := Node3D.new()
	mandoble.name = "MandobleVacio"
	mandoble.position = Vector3(-0.04, -0.78, 0.16)
	mandoble.rotation_degrees = Vector3(44.0, 12.0, -18.0)
	brazo_der.add_child(mandoble)
	mandoble.add_child(Kit.cyl(0.028, 0.028, 0.34, m_obs, Vector3(0.0, -0.06, 0.0)))
	mandoble.add_child(Kit.prisma_biselado(Vector3(0.40, 0.06, 0.09), 0.015, m_peltre, Vector3(0.0, 0.12, 0.0)))
	mandoble.add_child(Kit.hoja_filo(1.42, 0.16, 0.042, 0.0, m_obs, 8, Vector3(0.0, 0.15, 0.0)))
	mandoble.add_child(Kit.caja(Vector3(0.022, 1.05, 0.048), m_grieta_v, Vector3(0.0, 0.72, 0.0)))

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig, 24.0)
	return raiz


# ==============================================================================
# 5. GÓLEM DE TESORO (~1.65m)
# ==============================================================================

static func golem_tesoro() -> Node3D:
	var res := Kit.crear_raiz_enemigo("GolemTesoro")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_acero := Kit.tex_acero_bunker(Color(0.15, 0.16, 0.19), 5101)
	var t_oro := Kit.tex_bronce_oxidado(Color(0.58, 0.44, 0.17), 5102)
	var t_cuero := Kit.tex_tela_tactica(Color(0.34, 0.21, 0.12), Color(0.16, 0.09, 0.05), Color(0.14, 0.11, 0.09), false, 5103)

	var m_acero := Kit.mat_pbr(Color(0.86, 0.87, 0.90), 0.50, 0.48, t_acero)
	var m_oro := Kit.mat_pbr(Color(0.95, 0.88, 0.72), 0.56, 0.42, t_oro)
	var m_cuero := Kit.mat_pbr(Color(1.0, 1.0, 1.0), 0.04, 0.80, t_cuero)
	var m_cuerda := Kit.mat_pbr(Color(0.46, 0.37, 0.24), 0.0, 0.88)
	var m_lingote := Kit.mat_pbr(Color(0.72, 0.56, 0.22), 0.54, 0.44)

	var m_ojo_ambar := Kit.mat_emissive(Color(0.48, 0.30, 0.06), Color(0.92, 0.62, 0.12), 0.45, 0.34)
	var m_gema_rubi := Kit.mat_emissive(Color(0.38, 0.06, 0.10), Color(0.82, 0.18, 0.24), 0.30, 0.30)
	var m_gema_esm := Kit.mat_emissive(Color(0.06, 0.32, 0.18), Color(0.16, 0.72, 0.40), 0.30, 0.30)

	for lado in [-1.0, 1.0]:
		var p_nodo := Node3D.new()
		p_nodo.name = "PiernaDer" if lado < 0.0 else "PiernaIzq"
		p_nodo.position = Vector3(lado * 0.24, 0.56, 0.0)
		rig.add_child(p_nodo)

		p_nodo.add_child(Kit.prisma_biselado(Vector3(0.22, 0.44, 0.24), 0.03, m_acero, Vector3(0.0, -0.22, 0.0)))
		p_nodo.add_child(Kit.toro(0.14, 0.11, m_oro, Vector3(0.0, -0.22, 0.0)))
		p_nodo.add_child(Kit.prisma_biselado(Vector3(0.26, 0.16, 0.34), 0.03, m_oro, Vector3(0.0, -0.48, 0.04)))

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 0.56, 0.0)
	rig.add_child(torso)

	torso.add_child(Kit.prisma_biselado(Vector3(0.84, 0.88, 0.68), 0.075, m_acero, Vector3(0.0, 0.44, 0.0)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.70, 0.72, 0.07), 0.025, m_oro, Vector3(0.0, 0.44, 0.335)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.78, 0.08, 0.62), 0.02, m_oro, Vector3(0.0, 0.89, 0.0)))
	for hy in [0.24, 0.64]:
		torso.add_child(Kit.cyl(0.042, 0.042, 0.14, m_oro, Vector3(0.36, hy, 0.35), Vector3.ZERO, 10))
	torso.add_child(Kit.cyl(0.06, 0.06, 0.08, m_acero, Vector3(0.0, 0.40, 0.38), Vector3(90.0, 0.0, 0.0), 12))
	torso.add_child(Kit.toro(0.18, 0.145, m_oro, Vector3(0.0, 0.40, 0.41), Vector3(90.0, 0.0, 0.0)))
	for r_ang in [0.0, 60.0, 120.0]:
		torso.add_child(Kit.cyl(0.016, 0.016, 0.31, m_acero, Vector3(0.0, 0.40, 0.41), Vector3(0.0, 0.0, r_ang), 8))

	torso.add_child(Kit.cyl(0.055, 0.055, 0.06, m_acero, Vector3(-0.15, 0.72, 0.35), Vector3(90.0, 0.0, 0.0), 12))
	torso.add_child(Kit.esfera(0.040, m_ojo_ambar, Vector3(-0.15, 0.72, 0.375)))
	torso.add_child(Kit.cyl(0.055, 0.055, 0.06, m_acero, Vector3(0.15, 0.72, 0.35), Vector3(90.0, 0.0, 0.0), 12))
	torso.add_child(Kit.esfera(0.040, m_ojo_ambar, Vector3(0.15, 0.72, 0.375)))

	var mochila := Node3D.new()
	mochila.name = "MochilaBotin"
	mochila.position = Vector3(0.0, 0.48, -0.44)
	torso.add_child(mochila)

	mochila.add_child(Kit.prisma_biselado(Vector3(0.66, 0.64, 0.34), 0.07, m_cuero, Vector3.ZERO, Vector3.ZERO, Vector2(1.08, 1.06)))
	for cy in [-0.14, 0.12]:
		mochila.add_child(Kit.toro(0.36, 0.33, m_cuerda, Vector3(0.0, cy, 0.06), Vector3.ZERO, Vector3(1.0, 1.0, 0.65)))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.24, 0.11, 0.13), 0.018, m_lingote, Vector3(-0.14, 0.38, -0.02), Vector3(8.0, 18.0, -14.0), Vector2(0.75, 0.75)))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.24, 0.11, 0.13), 0.018, m_lingote, Vector3(0.14, 0.40, 0.02), Vector3(-6.0, -16.0, 12.0), Vector2(0.75, 0.75)))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.22, 0.10, 0.12), 0.018, m_lingote, Vector3(0.02, 0.48, -0.04), Vector3(12.0, 28.0, 6.0), Vector2(0.75, 0.75)))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.11, 0.18, 0.11), 0.02, m_gema_rubi, Vector3(-0.20, 0.46, 0.08), Vector3(14.0, 22.0, -16.0), Vector2(0.25, 0.25), 6))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.10, 0.20, 0.10), 0.02, m_gema_esm, Vector3(0.20, 0.49, -0.04), Vector3(-12.0, 10.0, 18.0), Vector2(0.25, 0.25), 6))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.09, 0.16, 0.09), 0.018, m_gema_rubi, Vector3(0.05, 0.56, 0.06), Vector3(6.0, -25.0, -8.0), Vector2(0.25, 0.25), 6))
	mochila.add_child(Kit.prisma_biselado(Vector3(0.09, 0.14, 0.09), 0.018, m_gema_esm, Vector3(-0.08, 0.52, -0.09), Vector3(-16.0, 14.0, 10.0), Vector2(0.25, 0.25), 6))

	for lado in [-1.0, 1.0]:
		var b_nodo := Node3D.new()
		b_nodo.name = "BrazoDer" if lado < 0.0 else "BrazoIzq"
		b_nodo.position = Vector3(lado * 0.52, 0.64, 0.0)
		torso.add_child(b_nodo)

		b_nodo.add_child(Kit.prisma_biselado(Vector3(0.20, 0.24, 0.22), 0.03, m_oro, Vector3(0.0, -0.08, 0.0)))
		b_nodo.add_child(Kit.prisma_biselado(Vector3(0.18, 0.36, 0.19), 0.028, m_acero, Vector3(0.0, -0.34, 0.04), Vector3(-12.0, 0.0, 0.0)))
		b_nodo.add_child(Kit.prisma_biselado(Vector3(0.20, 0.16, 0.20), 0.025, m_oro, Vector3(0.0, -0.56, 0.08), Vector3(-12.0, 0.0, 0.0)))

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig, 22.0)
	return raiz


# ==============================================================================
# 6. HERALDO DEL CLIC (~2.55m, monorrueda)
# ==============================================================================

static func heraldo_clic() -> Node3D:
	var res := Kit.crear_raiz_enemigo("HeraldoClic")
	var raiz: Node3D = res["raiz"]
	var rig: Node3D = res["rig"]

	var t_acero := Kit.tex_acero_bunker(Color(0.18, 0.20, 0.24), 6101)
	var t_lat := Kit.tex_bronce_oxidado(Color(0.52, 0.38, 0.19), 6102)
	var t_cobre := Kit.tex_bronce_oxidado(Color(0.58, 0.33, 0.17), 6103)
	var t_haz := Kit.tex_hazard_desgastado(6104)
	var t_rod := Kit.tex_rodillo_jackpot()

	var m_acero := Kit.mat_pbr(Color(0.88, 0.90, 0.94), 0.52, 0.46, t_acero)
	var m_lat := Kit.mat_pbr(Color(0.94, 0.88, 0.78), 0.55, 0.44, t_lat)
	var m_cobre := Kit.mat_pbr(Color(0.92, 0.84, 0.78), 0.56, 0.44, t_cobre)
	var m_haz := Kit.mat_pbr(Color(1.0, 1.0, 1.0), 0.24, 0.58, t_haz)
	var m_caucho := Kit.mat_pbr(Color(0.08, 0.08, 0.10), 0.0, 0.88)
	var m_rodillo := Kit.mat_pbr(Color(1.0, 1.0, 1.0), 0.05, 0.64, t_rod)
	var m_pomo := Kit.mat_pbr(Color(0.58, 0.10, 0.12), 0.08, 0.52)

	var m_nixie := Kit.mat_emissive(Color(0.12, 0.28, 0.30), Color(0.28, 0.82, 0.86), 0.45, 0.34)
	var m_nixie_amb := Kit.mat_emissive(Color(0.32, 0.20, 0.06), Color(0.88, 0.54, 0.12), 0.45, 0.34)

	var monorueda := Node3D.new()
	monorueda.name = "Monorueda"
	monorueda.position = Vector3.ZERO
	rig.add_child(monorueda)

	var rueda_giro := Node3D.new()
	rueda_giro.name = "RuedaGiro"
	rueda_giro.position = Vector3(0.0, 0.45, 0.0)
	monorueda.add_child(rueda_giro)

	rueda_giro.add_child(Kit.cyl(0.45, 0.45, 0.32, m_caucho, Vector3.ZERO, Vector3(0.0, 0.0, 90.0), 24))
	rueda_giro.add_child(Kit.cyl(0.27, 0.27, 0.34, m_lat, Vector3.ZERO, Vector3(0.0, 0.0, 90.0), 18))
	rueda_giro.add_child(Kit.cyl(0.09, 0.09, 0.44, m_acero, Vector3.ZERO, Vector3(0.0, 0.0, 90.0), 12))
	for r_ang in [0.0, 45.0, 90.0, 135.0]:
		rueda_giro.add_child(Kit.caja(Vector3(0.35, 0.50, 0.06), m_lat, Vector3.ZERO, Vector3(r_ang, 0.0, 0.0)))

	for lado in [-1.0, 1.0]:
		monorueda.add_child(Kit.prisma_biselado(Vector3(0.11, 0.62, 0.20), 0.02, m_acero, Vector3(lado * 0.26, 0.66, 0.0), Vector3.ZERO, Vector2(0.9, 0.9)))
	monorueda.add_child(Kit.prisma_biselado(Vector3(0.68, 0.16, 0.56), 0.025, m_acero, Vector3(0.0, 0.94, 0.0)))

	var gabinete := Node3D.new()
	gabinete.name = "GabineteArcade"
	gabinete.position = Vector3(0.0, 1.00, 0.0)
	rig.add_child(gabinete)

	gabinete.add_child(Kit.prisma_biselado(Vector3(0.84, 1.10, 0.64), 0.055, m_acero, Vector3(0.0, 0.55, 0.0)))
	gabinete.add_child(Kit.prisma_biselado(Vector3(0.88, 0.20, 0.68), 0.025, m_haz, Vector3(0.0, 0.16, 0.0)))
	gabinete.add_child(Kit.prisma_biselado(Vector3(0.68, 0.42, 0.10), 0.02, m_lat, Vector3(0.0, 0.58, 0.30)))
	gabinete.add_child(Kit.caja(Vector3(0.56, 0.28, 0.08), Kit.mat_pbr(Color(0.06, 0.06, 0.08), 0.1, 0.85), Vector3(0.0, 0.58, 0.28)))
	for r_x in [-0.17, 0.0, 0.17]:
		gabinete.add_child(Kit.cyl(0.115, 0.115, 0.13, m_rodillo, Vector3(r_x, 0.58, 0.25), Vector3(0.0, 0.0, 90.0), 16))
	gabinete.add_child(Kit.prisma_biselado(Vector3(0.58, 0.11, 0.08), 0.015, m_lat, Vector3(0.0, 0.90, 0.30)))
	gabinete.add_child(Kit.caja(Vector3(0.32, 0.05, 0.03), m_nixie, Vector3(-0.08, 0.90, 0.335)))
	gabinete.add_child(Kit.caja(Vector3(0.14, 0.05, 0.03), m_nixie_amb, Vector3(0.18, 0.90, 0.335)))

	gabinete.add_child(Kit.prisma_biselado(Vector3(0.76, 0.14, 0.58), 0.03, m_lat, Vector3(0.0, 1.15, 0.0)))
	for cx in [-0.24, 0.24]:
		gabinete.add_child(Kit.cyl(0.055, 0.075, 0.34, m_lat, Vector3(cx, 1.37, -0.10), Vector3(-12.0, 0.0, 0.0), 12))
		gabinete.add_child(Kit.toro(0.072, 0.052, m_cobre, Vector3(cx, 1.53, -0.135), Vector3(-12.0, 0.0, 0.0)))
	gabinete.add_child(Kit.cyl(0.08, 0.10, 0.28, m_acero, Vector3(0.0, 1.32, 0.05), Vector3.ZERO, 12))

	var palanca := Node3D.new()
	palanca.name = "PalancaJackpot"
	palanca.position = Vector3(0.46, 0.54, 0.06)
	gabinete.add_child(palanca)

	palanca.add_child(Kit.cyl(0.075, 0.075, 0.12, m_lat, Vector3(0.04, 0.0, 0.0), Vector3(0.0, 0.0, 90.0), 12))
	palanca.add_child(Kit.cyl(0.025, 0.028, 0.56, m_acero, Vector3(0.10, 0.26, 0.04), Vector3(10.0, 0.0, -8.0), 10))
	palanca.add_child(Kit.esfera(0.082, m_pomo, Vector3(0.14, 0.55, 0.09)))

	var brazo_pinza := Node3D.new()
	brazo_pinza.name = "BrazoPinza"
	brazo_pinza.position = Vector3(-0.48, 0.72, 0.04)
	gabinete.add_child(brazo_pinza)

	brazo_pinza.add_child(Kit.prisma_biselado(Vector3(0.22, 0.24, 0.24), 0.03, m_cobre, Vector3(-0.08, 0.0, 0.0)))
	brazo_pinza.add_child(Kit.prisma_biselado(Vector3(0.16, 0.44, 0.18), 0.025, m_acero, Vector3(-0.12, -0.22, 0.10), Vector3(-28.0, 0.0, 0.0)))
	brazo_pinza.add_child(Kit.cyl(0.04, 0.04, 0.34, m_cobre, Vector3(-0.12, -0.20, 0.16), Vector3(-28.0, 0.0, 0.0), 10))
	brazo_pinza.add_child(Kit.prisma_biselado(Vector3(0.20, 0.18, 0.46), 0.025, m_acero, Vector3(-0.12, -0.36, 0.44)))
	brazo_pinza.add_child(Kit.toro(0.11, 0.085, m_cobre, Vector3(-0.12, -0.36, 0.64), Vector3(90.0, 0.0, 0.0)))
	brazo_pinza.add_child(Kit.prisma_biselado(Vector3(0.075, 0.12, 0.34), 0.015, m_acero, Vector3(-0.20, -0.36, 0.80), Vector3(0.0, 14.0, 0.0), Vector2(0.55, 1.0)))
	brazo_pinza.add_child(Kit.prisma_biselado(Vector3(0.075, 0.12, 0.34), 0.015, m_acero, Vector3(-0.04, -0.36, 0.80), Vector3(0.0, -14.0, 0.0), Vector2(0.55, 1.0)))

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_monorrueda(raiz, rig)
	return raiz


# ==============================================================================
# 7. REGISTRO CENTRAL
# ==============================================================================

static func construir_todos() -> Dictionary:
	return {
		"maestra": {
			"nodo": maestra(),
			"ruta": "res://assets/modelos/jefe_maestra_sanguinaria.glb",
		},
		"parca": {
			"nodo": parca(),
			"ruta": "res://assets/modelos/jefe_parca_roja.glb",
		},
		"canalizador_vacio": {
			"nodo": canalizador_vacio(),
			"ruta": "res://assets/modelos/enemigo_canalizador_vacio.glb",
		},
		"espejo_sombrio": {
			"nodo": espejo_sombrio(),
			"ruta": "res://assets/modelos/jefe_espejo_sombrio.glb",
		},
		"golem_tesoro": {
			"nodo": golem_tesoro(),
			"ruta": "res://assets/modelos/enemigo_golem_tesoro.glb",
		},
		"heraldo_clic": {
			"nodo": heraldo_clic(),
			"ruta": "res://assets/modelos/enemigo_heraldo_clic.glb",
		},
	}
