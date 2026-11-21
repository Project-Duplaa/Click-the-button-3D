@tool
class_name EnemigosFaccionFoso
extends RefCounted

## ==============================================================================
## CONSTRUCTORES PROCEDURALES PBR — FACCIÓN DEL FOSO (5 ENEMIGOS)
## - Orientación de esculpido: +Z dentro de RigVisual (rotado 180° -> -Z nativo)
## - Materiales exclusivos: Kit.mat_pbr / Kit.mat_emissive
## - Base apoyada en y = 0.0 via normalizar_base_suelo antes de animar
## ==============================================================================

const Kit = preload("res://herramientas/enemigos_pbr_kit.gd")


static func _validar_altura(nombre: String, altura: float, objetivo: float) -> void:
	var tol: float = objetivo * 0.08
	if absf(altura - objetivo) > tol:
		push_warning("%s altura=%.3fm fuera de ±8%% respecto a objetivo=%.2fm" % [nombre, altura, objetivo])


static func _agregar_eslabones_cadena(
	padre: Node3D,
	p_ini: Vector3,
	p_fin: Vector3,
	cantidad: int,
	r_ext: float,
	r_int: float,
	mat: Material
) -> void:
	var dir: Vector3 = p_fin - p_ini
	var len_seg: float = dir.length()
	if len_seg < 0.001 or cantidad <= 0:
		return
	var q_dir := Quaternion(Vector3.UP, dir.normalized())
	var euler_base := q_dir.get_euler()
	for i in range(cantidad):
		var t: float = (float(i) + 0.5) / float(cantidad)
		var pos: Vector3 = p_ini.lerp(p_fin, t)
		var twist: float = 0.0 if (i % 2 == 0) else 90.0
		var link := Kit.toro(
			r_ext,
			r_int,
			mat,
			pos,
			Vector3(rad_to_deg(euler_base.x), rad_to_deg(euler_base.y), rad_to_deg(euler_base.z) + twist),
			Vector3(0.85, 1.0, 1.25),
			12
		)
		padre.add_child(link)


# ==============================================================================
# 1. ESPECTRO DEL FOSO (~2.00m) — Flote
# ==============================================================================

static func espectro() -> Node3D:
	var pack := Kit.crear_raiz_enemigo("EspectroFoso")
	var raiz: Node3D = pack["raiz"]
	var rig: Node3D = pack["rig"]

	var tex_sudario := Kit.tex_tela_tactica(
		Color(0.16, 0.18, 0.20),
		Color(0.08, 0.09, 0.11),
		Color(0.18, 0.15, 0.12),
		true,
		641
	)
	var tex_tela_solida := Kit.tex_tela_tactica(
		Color(0.14, 0.16, 0.18),
		Color(0.07, 0.08, 0.10),
		Color(0.16, 0.14, 0.11),
		false,
		643
	)
	var tex_hierro := Kit.tex_acero_bunker(Color(0.22, 0.19, 0.17), 311)
	var tex_hueso := Kit.tex_hueso_ceramico(911)
	var tex_acero_filo := Kit.tex_acero_bunker(Color(0.32, 0.34, 0.36), 317)

	var mat_sudario := Kit.mat_pbr(Color.WHITE, 0.05, 0.88, tex_sudario, 0.995, true)
	var mat_cuerpo_tela := Kit.mat_pbr(Color.WHITE, 0.06, 0.85, tex_tela_solida, 1.0, false)
	var mat_hierro := Kit.mat_pbr(Color.WHITE, 0.56, 0.64, tex_hierro)
	var mat_hueso := Kit.mat_pbr(Color.WHITE, 0.04, 0.72, tex_hueso)
	var mat_filo := Kit.mat_pbr(Color.WHITE, 0.60, 0.40, tex_acero_filo)
	var mat_sombra := Kit.mat_pbr(Color(0.05, 0.06, 0.07), 0.05, 0.90)
	var mat_optico := Kit.mat_emissive(Color(0.18, 0.62, 0.55), Color(0.20, 0.85, 0.74), 0.45, 0.30)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.position = Vector3(0.0, 1.05, 0.0)
	rig.add_child(cuerpo)

	var sec_torso := [
		{"y": -0.86, "rx": 0.11, "rz": 0.10, "z_off": -0.11, "bevel": 0.25},
		{"y": -0.45, "rx": 0.16, "rz": 0.13, "z_off": -0.05, "bevel": 0.30},
		{"y": 0.00, "rx": 0.15, "rz": 0.12, "z_off": 0.00, "bevel": 0.35},
		{"y": 0.32, "rx": 0.21, "rz": 0.15, "z_off": 0.04, "bevel": 0.40},
		{"y": 0.50, "rx": 0.23, "rz": 0.16, "z_off": 0.09, "bevel": 0.42},
		{"y": 0.60, "rx": 0.09, "rz": 0.09, "z_off": 0.13, "bevel": 0.20},
	]
	cuerpo.add_child(Kit.loft_perfil(sec_torso, mat_cuerpo_tela, 14, true))

	var sudario_trasero := Kit.capa_colgante(0.52, -0.99, 0.26, 0.19, 0.33, 0.25, 32.0, 328.0, mat_sudario, 0.06)
	sudario_trasero.position = Vector3(0.0, 0.0, 0.02)
	cuerpo.add_child(sudario_trasero)

	var sudario_frontal := Kit.capa_colgante(0.44, -0.78, 0.22, 0.17, 0.19, 0.16, -34.0, 34.0, mat_sudario, 0.05)
	sudario_frontal.position = Vector3(0.0, 0.0, 0.04)
	cuerpo.add_child(sudario_frontal)

	cuerpo.add_child(Kit.toro(0.155, 0.115, mat_hierro, Vector3(0.0, 0.56, 0.12), Vector3(16.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.05), 16))
	cuerpo.add_child(Kit.prisma_biselado(Vector3(0.08, 0.06, 0.08), 0.012, mat_hierro, Vector3(0.0, 0.53, 0.23), Vector3(16.0, 0.0, 0.0)))
	for sx in [-1.0, 1.0]:
		cuerpo.add_child(Kit.toro(0.11, 0.075, mat_hierro, Vector3(sx * 0.24, 0.47, 0.06), Vector3(0.0, 0.0, sx * 68.0), Vector3.ONE, 14))
		cuerpo.add_child(Kit.prisma_biselado(Vector3(0.06, 0.06, 0.06), 0.01, mat_hierro, Vector3(sx * 0.22, 0.52, 0.08)))
		_agregar_eslabones_cadena(cuerpo, Vector3(sx * 0.11, 0.54, 0.14), Vector3(sx * 0.23, 0.48, 0.08), 3, 0.028, 0.016, mat_hierro)

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 0.63, 0.15)
	cabeza.rotation_degrees = Vector3(12.0, 0.0, 0.0)
	cuerpo.add_child(cabeza)

	cabeza.add_child(Kit.esfera(0.105, mat_sombra, Vector3(0.0, 0.14, 0.01), Vector3(0.88, 1.08, 0.96), 12, 8))
	cabeza.add_child(Kit.toro(0.135, 0.110, mat_hierro, Vector3(0.0, 0.04, 0.02), Vector3.ZERO, Vector3(0.95, 1.0, 1.05), 14))
	cabeza.add_child(Kit.toro(0.138, 0.112, mat_hierro, Vector3(0.0, 0.16, 0.02), Vector3.ZERO, Vector3(0.95, 1.0, 1.05), 14))
	cabeza.add_child(Kit.toro(0.120, 0.095, mat_hierro, Vector3(0.0, 0.26, 0.02), Vector3.ZERO, Vector3(0.95, 1.0, 1.05), 14))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.15, 0.05, 0.16), 0.014, mat_hierro, Vector3(0.0, 0.30, 0.01)))
	cabeza.add_child(Kit.cyl(0.008, 0.024, 0.06, mat_hierro, Vector3(0.0, 0.33, 0.01)))

	for bx in [-0.066, -0.022, 0.022, 0.066]:
		var bz: float = 0.128 if absf(bx) < 0.04 else 0.112
		cabeza.add_child(Kit.cyl(0.009, 0.009, 0.27, mat_hierro, Vector3(bx, 0.15, bz), Vector3.ZERO, 8))
	for sx in [-1.0, 1.0]:
		cabeza.add_child(Kit.cyl(0.009, 0.009, 0.25, mat_hierro, Vector3(sx * 0.122, 0.15, 0.02), Vector3.ZERO, 8))
	cabeza.add_child(Kit.cyl(0.010, 0.010, 0.25, mat_hierro, Vector3(0.0, 0.15, -0.10), Vector3.ZERO, 8))

	cabeza.add_child(Kit.esfera(0.015, mat_optico, Vector3(0.043, 0.165, 0.085), Vector3.ONE, 10, 6))
	cabeza.add_child(Kit.esfera(0.015, mat_optico, Vector3(-0.043, 0.165, 0.085), Vector3.ONE, 10, 6))

	for lado in [["BrazoIzq", 1.0], ["BrazoDer", -1.0]]:
		var b_nombre: String = lado[0]
		var sx: float = lado[1]
		var brazo := Node3D.new()
		brazo.name = b_nombre
		brazo.position = Vector3(sx * 0.27, 0.45, 0.06)
		brazo.rotation_degrees = Vector3(-18.0, 0.0, sx * 6.0)
		cuerpo.add_child(brazo)

		brazo.add_child(Kit.esfera(0.048, mat_hueso, Vector3.ZERO, Vector3.ONE, 10, 6))
		brazo.add_child(Kit.cyl(0.024, 0.020, 0.34, mat_hueso, Vector3(0.0, -0.18, 0.0), Vector3.ZERO, 10))
		brazo.add_child(Kit.esfera(0.038, mat_hueso, Vector3(0.0, -0.36, 0.0), Vector3.ONE, 10, 6))
		brazo.add_child(Kit.cyl(0.022, 0.026, 0.32, mat_hueso, Vector3(0.0, -0.52, 0.04), Vector3(-14.0, 0.0, 0.0), 10))
		brazo.add_child(Kit.toro(0.048, 0.032, mat_hierro, Vector3(0.0, -0.62, 0.07), Vector3(-14.0, 0.0, 0.0), Vector3.ONE, 12))
		_agregar_eslabones_cadena(brazo, Vector3(sx * 0.02, -0.64, 0.07), Vector3(sx * 0.05, -0.82, 0.05), 3, 0.024, 0.014, mat_hierro)
		brazo.add_child(Kit.prisma_biselado(Vector3(0.055, 0.14, 0.065), 0.012, mat_hierro, Vector3(sx * 0.025, -0.53, 0.05), Vector3(-14.0, 0.0, 0.0)))
		var filo := Kit.hoja_filo(0.46, 0.075, 0.024, sx * 0.04, mat_filo, 8, Vector3(sx * 0.03, -0.58, 0.07), Vector3(145.0, 0.0, 0.0))
		brazo.add_child(filo)

	var altura := Kit.normalizar_base_suelo(rig)
	_validar_altura("espectro", altura, 2.00)
	Kit.agregar_animaciones_flote(raiz, rig)
	return raiz


# ==============================================================================
# 2. BERSERKER RABIOSO (~2.70m) — Bípedo asimétrico
# ==============================================================================

static func berserker() -> Node3D:
	var pack := Kit.crear_raiz_enemigo("BerserkerRabioso")
	var raiz: Node3D = pack["raiz"]
	var rig: Node3D = pack["rig"]

	var tex_acero := Kit.tex_acero_bunker(Color(0.30, 0.32, 0.35), 331)
	var tex_acero_filo := Kit.tex_acero_bunker(Color(0.46, 0.48, 0.52), 337)
	var tex_traje := Kit.tex_tela_tactica(Color(0.24, 0.14, 0.14), Color(0.12, 0.07, 0.07), Color(0.22, 0.16, 0.14), false, 653)
	var tex_hazard := Kit.tex_hazard_desgastado(521)

	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.56, 0.48, tex_acero)
	var mat_filo := Kit.mat_pbr(Color.WHITE, 0.60, 0.39, tex_acero_filo)
	var mat_traje := Kit.mat_pbr(Color.WHITE, 0.12, 0.72, tex_traje)
	var mat_oxido := Kit.mat_pbr(Color(0.46, 0.14, 0.12), 0.34, 0.56)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.30, 0.58, tex_hazard)
	var mat_carmesi := Kit.mat_emissive(Color(0.45, 0.07, 0.09), Color(0.88, 0.12, 0.16), 0.45, 0.30)
	var mat_visor_rojo := Kit.mat_emissive(Color(0.55, 0.08, 0.08), Color(0.95, 0.14, 0.14), 0.50, 0.25)

	for p_info in [["PiernaIzq", 1.0], ["PiernaDer", -1.0]]:
		var p_nom: String = p_info[0]
		var sx: float = p_info[1]
		var pierna := Node3D.new()
		pierna.name = p_nom
		pierna.position = Vector3(sx * 0.25, 1.08, 0.0)
		rig.add_child(pierna)

		var sec_muslo := [
			{"y": -0.52, "rx": 0.14, "rz": 0.14, "bevel": 0.50},
			{"y": -0.22, "rx": 0.17, "rz": 0.17, "bevel": 0.55},
			{"y": 0.02, "rx": 0.18, "rz": 0.17, "bevel": 0.50},
		]
		pierna.add_child(Kit.loft_perfil(sec_muslo, mat_traje, 14, true))
		pierna.add_child(Kit.hombrera_curva(0.175, 0.045, 0.22, 130.0, mat_acero, Vector3(0.0, -0.50, 0.03)))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.24, 0.46, 0.26), 0.045, mat_acero, Vector3(0.0, -0.78, 0.01), Vector3.ZERO, Vector2(0.92, 0.92)))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.28, 0.16, 0.38), 0.038, mat_acero, Vector3(0.0, -1.00, 0.06), Vector3.ZERO, Vector2(0.86, 0.88)))

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.08, 0.0)
	rig.add_child(torso)

	var sec_torso := [
		{"y": 0.00, "rx": 0.34, "rz": 0.23, "bevel": 0.55},
		{"y": 0.32, "rx": 0.39, "rz": 0.26, "bevel": 0.60},
		{"y": 0.72, "rx": 0.51, "rz": 0.33, "z_off": 0.04, "bevel": 0.62},
		{"y": 1.06, "rx": 0.46, "rz": 0.30, "z_off": 0.06, "bevel": 0.55},
		{"y": 1.22, "rx": 0.22, "rz": 0.20, "z_off": 0.07, "bevel": 0.45},
	]
	torso.add_child(Kit.loft_perfil(sec_torso, mat_traje, 16, true))

	torso.add_child(Kit.prisma_biselado(Vector3(0.74, 0.16, 0.50), 0.035, mat_oxido, Vector3(0.0, 0.08, 0.0)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.84, 0.44, 0.16), 0.040, mat_oxido, Vector3(0.0, 0.76, 0.29), Vector3(-6.0, 0.0, 0.0)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.56, 0.52, 0.22), 0.045, mat_acero, Vector3(0.0, 0.78, -0.29)))
	for sx in [-1.0, 1.0]:
		torso.add_child(Kit.cyl(0.038, 0.042, 0.44, mat_acero, Vector3(sx * 0.24, 0.74, 0.34), Vector3(-6.0, 0.0, sx * 12.0), 12))

	torso.add_child(Kit.tubo_curvo(
		[Vector3(0.18, 0.90, -0.34), Vector3(0.32, 1.06, -0.14), Vector3(0.30, 1.02, 0.16), Vector3(0.20, 0.84, 0.34)],
		0.015, 0.013, mat_carmesi, 8
	))
	torso.add_child(Kit.tubo_curvo(
		[Vector3(-0.18, 0.90, -0.34), Vector3(-0.32, 1.06, -0.14), Vector3(-0.30, 1.02, 0.16), Vector3(-0.20, 0.84, 0.34)],
		0.015, 0.013, mat_carmesi, 8
	))

	var hombrera := Node3D.new()
	hombrera.name = "HombreraAriete"
	hombrera.position = Vector3(0.56, 0.98, 0.04)
	hombrera.rotation_degrees = Vector3(4.0, 0.0, -24.0)
	torso.add_child(hombrera)

	hombrera.add_child(Kit.hombrera_curva(0.30, 0.09, 0.54, 155.0, mat_hazard, Vector3.ZERO, Vector3(0.0, 90.0, 0.0)))
	hombrera.add_child(Kit.prisma_biselado(Vector3(0.32, 0.44, 0.52), 0.05, mat_hazard, Vector3(0.12, 0.04, 0.04)))
	hombrera.add_child(Kit.prisma_biselado(Vector3(0.36, 0.12, 0.56), 0.025, mat_acero, Vector3(0.12, -0.16, 0.04)))
	for sp_pos in [Vector3(0.24, 0.22, 0.16), Vector3(0.28, 0.24, 0.0), Vector3(0.24, 0.22, -0.16)]:
		hombrera.add_child(Kit.cyl(0.005, 0.046, 0.24, mat_acero, sp_pos, Vector3(0.0, 0.0, -56.0), 10))

	torso.add_child(Kit.hombrera_curva(0.20, 0.055, 0.28, 120.0, mat_acero, Vector3(-0.48, 0.96, 0.04), Vector3(0.0, -90.0, 18.0)))

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.20, 0.08)
	torso.add_child(cabeza)

	cabeza.add_child(Kit.prisma_biselado(Vector3(0.30, 0.38, 0.32), 0.055, mat_acero, Vector3(0.0, 0.20, 0.0), Vector3.ZERO, Vector2(0.88, 0.92)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.33, 0.30, 0.10), 0.022, mat_acero, Vector3(0.0, 0.18, 0.16)))
	cabeza.add_child(Kit.caja(Vector3(0.20, 0.026, 0.03), mat_visor_rojo, Vector3(0.0, 0.23, 0.205)))
	for rx in [-0.075, -0.025, 0.025, 0.075]:
		cabeza.add_child(Kit.cyl(0.011, 0.011, 0.16, mat_acero, Vector3(rx, 0.11, 0.22), Vector3.ZERO, 8))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.10, 0.07, 0.24), 0.018, mat_oxido, Vector3(0.0, 0.40, -0.02)))

	for b_info in [["BrazoIzq", 1.0], ["BrazoDer", -1.0]]:
		var b_nom: String = b_info[0]
		var sx: float = b_info[1]
		var brazo := Node3D.new()
		brazo.name = b_nom
		brazo.position = Vector3(sx * 0.58, 0.94, 0.04)
		brazo.rotation_degrees = Vector3(-22.0, 0.0, sx * 8.0)
		torso.add_child(brazo)

		brazo.add_child(Kit.esfera(0.14, mat_traje, Vector3.ZERO, Vector3.ONE, 12, 8))
		brazo.add_child(Kit.cyl(0.115, 0.105, 0.40, mat_traje, Vector3(0.0, -0.22, 0.0), Vector3.ZERO, 12))
		brazo.add_child(Kit.esfera(0.105, mat_acero, Vector3(0.0, -0.44, 0.0), Vector3.ONE, 12, 8))
		brazo.add_child(Kit.prisma_biselado(Vector3(0.24, 0.44, 0.24), 0.042, mat_acero, Vector3(0.0, -0.66, 0.06), Vector3(-12.0, 0.0, 0.0)))

		var arma := Node3D.new()
		arma.name = "HachaMachete"
		arma.position = Vector3(0.0, -0.84, 0.12)
		arma.rotation_degrees = Vector3(48.0, sx * -16.0, sx * 8.0)
		brazo.add_child(arma)

		arma.add_child(Kit.cyl(0.032, 0.034, 0.72, mat_acero, Vector3(0.0, 0.22, 0.0), Vector3.ZERO, 10))
		arma.add_child(Kit.hoja_filo(0.68, 0.19, 0.048, -0.05, mat_filo, 8, Vector3(0.0, 0.26, 0.05), Vector3(0.0, 90.0, 0.0)))
		arma.add_child(Kit.prisma_biselado(Vector3(0.045, 0.52, 0.075), 0.010, mat_acero, Vector3(0.0, 0.50, -0.04)))
		for d_idx in range(4):
			var dy: float = 0.30 + float(d_idx) * 0.12
			arma.add_child(Kit.prisma_biselado(Vector3(0.036, 0.055, 0.065), 0.006, mat_filo, Vector3(0.0, dy, -0.09), Vector3(28.0, 0.0, 0.0)))

	var altura := Kit.normalizar_base_suelo(rig)
	_validar_altura("berserker", altura, 2.70)
	Kit.agregar_animaciones_bipedo(raiz, rig, 28.0)
	return raiz


# ==============================================================================
# 3. MINERO KAMIKAZE (~1.65m) — Bípedo compacto y encorvado
# ==============================================================================

static func kamikaze() -> Node3D:
	var pack := Kit.crear_raiz_enemigo("MineroKamikaze")
	var raiz: Node3D = pack["raiz"]
	var rig: Node3D = pack["rig"]

	var tex_hazard := Kit.tex_hazard_desgastado(541)
	var tex_acero := Kit.tex_acero_bunker(Color(0.25, 0.27, 0.30), 353)
	var tex_acero_broca := Kit.tex_acero_bunker(Color(0.32, 0.34, 0.38), 359)

	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.25, 0.58, tex_hazard)
	var mat_amarillo := Kit.mat_pbr(Color(0.56, 0.42, 0.14), 0.32, 0.58)
	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.54, 0.50, tex_acero)
	var mat_broca := Kit.mat_pbr(Color.WHITE, 0.60, 0.42, tex_acero_broca)
	var mat_cartucho := Kit.mat_pbr(Color(0.56, 0.13, 0.11), 0.14, 0.55)
	var mat_presion := Kit.mat_emissive(Color(0.75, 0.36, 0.08), Color(0.95, 0.45, 0.10), 0.55, 0.28)
	var mat_foco := Kit.mat_emissive(Color(0.75, 0.52, 0.14), Color(0.95, 0.66, 0.16), 0.40, 0.25)

	for p_info in [["PiernaIzq", 1.0], ["PiernaDer", -1.0]]:
		var p_nom: String = p_info[0]
		var sx: float = p_info[1]
		var pierna := Node3D.new()
		pierna.name = p_nom
		pierna.position = Vector3(sx * 0.18, 0.62, 0.0)
		rig.add_child(pierna)

		pierna.add_child(Kit.cyl(0.11, 0.10, 0.28, mat_acero, Vector3(0.0, -0.14, 0.0), Vector3.ZERO, 12))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.18, 0.24, 0.20), 0.032, mat_acero, Vector3(0.0, -0.38, 0.01)))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.22, 0.14, 0.30), 0.030, mat_acero, Vector3(0.0, -0.55, 0.05)))

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 0.62, 0.0)
	rig.add_child(torso)

	var sec_torso := [
		{"y": 0.00, "rx": 0.26, "rz": 0.20, "z_off": 0.00, "bevel": 0.55},
		{"y": 0.28, "rx": 0.31, "rz": 0.23, "z_off": 0.06, "bevel": 0.62},
		{"y": 0.56, "rx": 0.35, "rz": 0.24, "z_off": 0.13, "bevel": 0.65},
		{"y": 0.72, "rx": 0.20, "rz": 0.17, "z_off": 0.18, "bevel": 0.45},
	]
	torso.add_child(Kit.loft_perfil(sec_torso, mat_acero, 14, true))
	torso.add_child(Kit.prisma_biselado(Vector3(0.56, 0.26, 0.18), 0.032, mat_hazard, Vector3(0.0, 0.40, 0.23), Vector3(14.0, 0.0, 0.0)))
	torso.add_child(Kit.prisma_biselado(Vector3(0.60, 0.11, 0.44), 0.022, mat_hazard, Vector3(0.0, 0.07, 0.01)))

	var tambor := Node3D.new()
	tambor.name = "TamborFision"
	tambor.position = Vector3(0.0, 0.56, -0.18)
	tambor.rotation_degrees = Vector3(22.0, 0.0, 0.0)
	torso.add_child(tambor)

	tambor.add_child(Kit.cyl(0.20, 0.20, 0.44, mat_acero, Vector3.ZERO, Vector3(0.0, 0.0, 90.0), 16))
	tambor.add_child(Kit.cyl(0.206, 0.206, 0.14, mat_hazard, Vector3.ZERO, Vector3(0.0, 0.0, 90.0), 16))
	for rx in [-0.18, 0.0, 0.18]:
		tambor.add_child(Kit.toro(0.235, 0.205, mat_acero, Vector3(rx, 0.0, 0.0), Vector3(0.0, 0.0, 90.0), Vector3.ONE, 16))
	for a_bar in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var rad: float = deg_to_rad(a_bar)
		tambor.add_child(Kit.cyl(0.015, 0.015, 0.46, mat_acero, Vector3(0.0, cos(rad) * 0.22, sin(rad) * 0.22), Vector3(0.0, 0.0, 90.0), 8))
	tambor.add_child(Kit.cyl(0.065, 0.065, 0.05, mat_presion, Vector3(0.0, 0.19, 0.08), Vector3(32.0, 0.0, 0.0), 12))

	for sx in [-1.0, 1.0]:
		torso.add_child(Kit.cyl(0.065, 0.065, 0.30, mat_cartucho, Vector3(sx * 0.25, 0.34, -0.14), Vector3(16.0, 0.0, sx * 8.0), 12))
		torso.add_child(Kit.toro(0.072, 0.058, mat_acero, Vector3(sx * 0.25, 0.44, -0.11), Vector3(16.0, 0.0, sx * 8.0), Vector3.ONE, 12))
		torso.add_child(Kit.cyl(0.030, 0.036, 0.22, mat_acero, Vector3(sx * 0.14, 0.78, -0.18), Vector3(-18.0, 0.0, sx * 10.0), 10))
		torso.add_child(Kit.toro(0.042, 0.026, mat_acero, Vector3(sx * 0.16, 0.88, -0.21), Vector3(-18.0, 0.0, sx * 10.0), Vector3.ONE, 10))

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 0.70, 0.22)
	cabeza.rotation_degrees = Vector3(10.0, 0.0, 0.0)
	torso.add_child(cabeza)

	cabeza.add_child(Kit.esfera(0.175, mat_amarillo, Vector3(0.0, 0.16, 0.0), Vector3(1.04, 0.92, 1.10), 14, 8))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.28, 0.04, 0.14), 0.012, mat_amarillo, Vector3(0.0, 0.14, 0.14), Vector3(10.0, 0.0, 0.0)))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.24, 0.14, 0.22), 0.028, mat_acero, Vector3(0.0, 0.07, 0.05)))
	cabeza.add_child(Kit.cyl(0.044, 0.048, 0.08, mat_acero, Vector3(0.0, 0.23, 0.18), Vector3(90.0, 0.0, 0.0), 12))
	cabeza.add_child(Kit.esfera(0.034, mat_foco, Vector3(0.0, 0.23, 0.215), Vector3(1.0, 1.0, 0.6), 10, 6))

	var brazo_r := Node3D.new()
	brazo_r.name = "BrazoDer"
	brazo_r.position = Vector3(-0.38, 0.56, 0.13)
	torso.add_child(brazo_r)

	brazo_r.add_child(Kit.esfera(0.095, mat_acero, Vector3.ZERO, Vector3.ONE, 10, 6))
	brazo_r.add_child(Kit.cyl(0.075, 0.068, 0.26, mat_acero, Vector3(0.0, -0.14, 0.0), Vector3.ZERO, 10))
	var taladro := Node3D.new()
	taladro.name = "TaladroRotativo"
	taladro.position = Vector3(0.0, -0.28, 0.04)
	taladro.rotation_degrees = Vector3(76.0, 0.0, 0.0)
	brazo_r.add_child(taladro)
	taladro.add_child(Kit.cyl(0.11, 0.12, 0.18, mat_acero, Vector3(0.0, 0.04, 0.0), Vector3.ZERO, 12))
	taladro.add_child(Kit.cyl(0.008, 0.105, 0.42, mat_broca, Vector3(0.0, 0.34, 0.0), Vector3.ZERO, 12))
	for fl_y in [0.18, 0.27, 0.36, 0.45]:
		var rr: float = lerpf(0.108, 0.032, (fl_y - 0.15) / 0.38)
		taladro.add_child(Kit.toro(rr + 0.016, rr - 0.006, mat_broca, Vector3(0.0, fl_y, 0.0), Vector3(16.0, 0.0, 12.0), Vector3.ONE, 12))

	var brazo_l := Node3D.new()
	brazo_l.name = "BrazoIzq"
	brazo_l.position = Vector3(0.38, 0.56, 0.13)
	torso.add_child(brazo_l)

	brazo_l.add_child(Kit.esfera(0.095, mat_acero, Vector3.ZERO, Vector3.ONE, 10, 6))
	brazo_l.add_child(Kit.cyl(0.072, 0.064, 0.26, mat_acero, Vector3(0.0, -0.14, 0.0), Vector3.ZERO, 10))
	brazo_l.add_child(Kit.prisma_biselado(Vector3(0.12, 0.24, 0.12), 0.024, mat_acero, Vector3(0.0, -0.34, 0.06), Vector3(-16.0, 0.0, 0.0)))
	brazo_l.add_child(Kit.prisma_biselado(Vector3(0.13, 0.07, 0.13), 0.012, mat_hazard, Vector3(0.0, -0.26, 0.04), Vector3(-16.0, 0.0, 0.0)))
	brazo_l.add_child(Kit.hoja_filo(0.18, 0.05, 0.03, 0.03, mat_acero, 6, Vector3(0.04, -0.44, 0.12), Vector3(82.0, 0.0, 0.0)))
	brazo_l.add_child(Kit.hoja_filo(0.18, 0.05, 0.03, -0.03, mat_acero, 6, Vector3(-0.04, -0.44, 0.12), Vector3(82.0, 0.0, 0.0)))
	brazo_l.add_child(Kit.tubo_curvo(
		[Vector3(-0.08, -0.04, -0.08), Vector3(0.09, -0.18, -0.05), Vector3(0.06, -0.34, 0.04)],
		0.018, 0.016, mat_cartucho, 8
	))

	var altura := Kit.normalizar_base_suelo(rig)
	_validar_altura("kamikaze", altura, 1.65)
	Kit.agregar_animaciones_bipedo(raiz, rig, 28.0)
	return raiz


# ==============================================================================
# 4. BRUTO APLASTADOR (~2.95m) — Gólem de basalto y titanio (amp_paso = 24.0)
# ==============================================================================

static func bruto() -> Node3D:
	var pack := Kit.crear_raiz_enemigo("BrutoAplastador")
	var raiz: Node3D = pack["raiz"]
	var rig: Node3D = pack["rig"]

	var tex_basalto := Kit.tex_basalto_hormigon(Color(0.35, 0.36, 0.34), true, 733)
	var tex_titanio := Kit.tex_acero_bunker(Color(0.24, 0.26, 0.29), 367)
	var tex_hierro := Kit.tex_acero_bunker(Color(0.17, 0.16, 0.16), 373)
	var tex_bronce := Kit.tex_bronce_oxidado(Color(0.52, 0.38, 0.20), 739)
	var tex_hazard := Kit.tex_hazard_desgastado(557)

	var mat_basalto := Kit.mat_pbr(Color.WHITE, 0.08, 0.86, tex_basalto)
	var mat_titanio := Kit.mat_pbr(Color.WHITE, 0.56, 0.46, tex_titanio)
	var mat_hierro := Kit.mat_pbr(Color.WHITE, 0.52, 0.60, tex_hierro)
	var mat_bronce := Kit.mat_pbr(Color.WHITE, 0.50, 0.48, tex_bronce)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.28, 0.58, tex_hazard)
	var mat_jade := Kit.mat_emissive(Color(0.12, 0.38, 0.24), Color(0.16, 0.66, 0.40), 0.35, 0.32)

	for p_info in [["PiernaIzq", 1.0], ["PiernaDer", -1.0]]:
		var p_nom: String = p_info[0]
		var sx: float = p_info[1]
		var pierna := Node3D.new()
		pierna.name = p_nom
		pierna.position = Vector3(sx * 0.35, 1.12, 0.0)
		rig.add_child(pierna)

		var sec_pilar := [
			{"y": -0.96, "rx": 0.24, "rz": 0.26, "bevel": 0.65},
			{"y": -0.45, "rx": 0.22, "rz": 0.24, "bevel": 0.62},
			{"y": 0.04, "rx": 0.26, "rz": 0.25, "bevel": 0.60},
		]
		pierna.add_child(Kit.loft_perfil(sec_pilar, mat_basalto, 8, true))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.42, 0.18, 0.52), 0.035, mat_hierro, Vector3(0.0, -1.03, 0.05), Vector3.ZERO, Vector2(0.88, 0.88), 8))
		pierna.add_child(Kit.prisma_biselado(Vector3(0.46, 0.22, 0.44), 0.030, mat_bronce, Vector3(0.0, -0.52, 0.02), Vector3.ZERO, Vector2.ONE, 8))

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.12, 0.0)
	rig.add_child(torso)

	var sec_bloque := [
		{"y": 0.00, "rx": 0.46, "rz": 0.32, "bevel": 0.65},
		{"y": 0.48, "rx": 0.56, "rz": 0.38, "z_off": 0.03, "bevel": 0.68},
		{"y": 1.05, "rx": 0.68, "rz": 0.44, "z_off": 0.07, "bevel": 0.65},
		{"y": 1.44, "rx": 0.60, "rz": 0.39, "z_off": 0.08, "bevel": 0.62},
		{"y": 1.62, "rx": 0.36, "rz": 0.28, "z_off": 0.04, "bevel": 0.58},
	]
	torso.add_child(Kit.loft_perfil(sec_bloque, mat_basalto, 8, true))

	torso.add_child(Kit.prisma_biselado(Vector3(1.16, 0.16, 0.16), 0.025, mat_bronce, Vector3(0.0, 1.12, 0.44), Vector3.ZERO, Vector2.ONE, 8))
	torso.add_child(Kit.prisma_biselado(Vector3(0.20, 0.86, 0.16), 0.025, mat_titanio, Vector3(0.32, 0.72, 0.39), Vector3(0.0, 0.0, -10.0), Vector2.ONE, 8))
	torso.add_child(Kit.prisma_biselado(Vector3(0.20, 0.86, 0.16), 0.025, mat_titanio, Vector3(-0.32, 0.72, 0.39), Vector3(0.0, 0.0, 10.0), Vector2.ONE, 8))
	torso.add_child(Kit.prisma_biselado(Vector3(0.92, 0.24, 0.22), 0.030, mat_bronce, Vector3(0.0, 1.24, -0.34), Vector3.ZERO, Vector2.ONE, 8))

	torso.add_child(Kit.caja(Vector3(0.36, 0.024, 0.03), mat_jade, Vector3(0.0, 0.78, 0.44), Vector3(0.0, 0.0, 14.0)))

	_agregar_eslabones_cadena(torso, Vector3(-0.56, 1.28, 0.44), Vector3(0.48, 0.26, 0.42), 9, 0.062, 0.038, mat_hierro)
	_agregar_eslabones_cadena(torso, Vector3(0.48, 1.02, 0.48), Vector3(-0.46, 0.30, 0.42), 8, 0.058, 0.035, mat_hierro)

	var barril := Node3D.new()
	barril.name = "BarrilContencion"
	barril.position = Vector3(0.56, 1.32, 0.04)
	barril.rotation_degrees = Vector3(14.0, 0.0, -34.0)
	torso.add_child(barril)

	barril.add_child(Kit.cyl(0.24, 0.23, 0.62, mat_hazard, Vector3.ZERO, Vector3.ZERO, 14))
	barril.add_child(Kit.toro(0.265, 0.235, mat_hierro, Vector3(0.0, 0.28, 0.0), Vector3.ZERO, Vector3.ONE, 14))
	barril.add_child(Kit.toro(0.265, 0.235, mat_hierro, Vector3(0.0, -0.28, 0.0), Vector3.ZERO, Vector3.ONE, 14))
	barril.add_child(Kit.toro(0.260, 0.232, mat_hierro, Vector3(0.0, 0.0, 0.0), Vector3.ZERO, Vector3.ONE, 14))

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.46, 0.24)
	torso.add_child(cabeza)

	cabeza.add_child(Kit.prisma_biselado(Vector3(0.44, 0.36, 0.40), 0.055, mat_basalto, Vector3(0.0, 0.18, 0.0), Vector3.ZERO, Vector2(0.86, 0.90), 8))
	cabeza.add_child(Kit.prisma_biselado(Vector3(0.38, 0.16, 0.12), 0.022, mat_titanio, Vector3(0.0, 0.19, 0.20), Vector3.ZERO, Vector2.ONE, 8))
	cabeza.add_child(Kit.caja(Vector3(0.09, 0.022, 0.025), mat_jade, Vector3(0.085, 0.19, 0.255)))
	cabeza.add_child(Kit.caja(Vector3(0.09, 0.022, 0.025), mat_jade, Vector3(-0.085, 0.19, 0.255)))

	for b_info in [["BrazoIzq", 1.0], ["BrazoDer", -1.0]]:
		var b_nom: String = b_info[0]
		var sx: float = b_info[1]
		var brazo := Node3D.new()
		brazo.name = b_nom
		brazo.position = Vector3(sx * 0.78, 1.24, 0.04)
		torso.add_child(brazo)

		brazo.add_child(Kit.esfera(0.20, mat_basalto, Vector3.ZERO, Vector3(1.0, 1.1, 1.0), 10, 6))
		brazo.add_child(Kit.cyl(0.16, 0.15, 0.44, mat_basalto, Vector3(0.0, -0.24, 0.0), Vector3.ZERO, 8))
		brazo.add_child(Kit.esfera(0.16, mat_bronce, Vector3(0.0, -0.48, 0.0), Vector3.ONE, 10, 6))
		var sec_maza := [
			{"y": -1.16, "rx": 0.25, "rz": 0.26, "bevel": 0.65},
			{"y": -0.82, "rx": 0.28, "rz": 0.28, "bevel": 0.68},
			{"y": -0.52, "rx": 0.19, "rz": 0.20, "bevel": 0.58},
		]
		brazo.add_child(Kit.loft_perfil(sec_maza, mat_basalto, 8, true))
		brazo.add_child(Kit.prisma_biselado(Vector3(0.56, 0.16, 0.56), 0.032, mat_bronce, Vector3(0.0, -0.88, 0.0), Vector3.ZERO, Vector2.ONE, 8))
		brazo.add_child(Kit.prisma_biselado(Vector3(0.48, 0.14, 0.48), 0.030, mat_hierro, Vector3(0.0, -1.10, 0.0), Vector3.ZERO, Vector2.ONE, 8))

	var altura := Kit.normalizar_base_suelo(rig)
	_validar_altura("bruto", altura, 2.95)
	Kit.agregar_animaciones_bipedo(raiz, rig, 24.0)
	return raiz


# ==============================================================================
# 5. PARÁSITO DE CURSOR (~0.90m alto, ~1.15m ancho) — Arácnido
# ==============================================================================

static func _construir_pata_aracnido(
	nombre: String,
	sx: float,
	pos_coxa: Vector3,
	z_rodilla: float,
	z_punta: float,
	mat_quitina: Material,
	mat_acero: Material
) -> Node3D:
	var pata := Node3D.new()
	pata.name = nombre
	pata.position = pos_coxa

	var p0 := Vector3.ZERO
	var p1 := Vector3(sx * 0.22, 0.16, z_rodilla)
	var p2 := Vector3(sx * 0.375, -0.38, z_punta)

	pata.add_child(Kit.esfera(0.044, mat_acero, p0, Vector3.ONE, 10, 6))
	pata.add_child(Kit.tubo_curvo([p0, p1], 0.032, 0.026, mat_quitina, 8))
	pata.add_child(Kit.esfera(0.036, mat_acero, p1, Vector3.ONE, 10, 6))
	pata.add_child(Kit.tubo_curvo([p1, p1.lerp(p2, 0.72)], 0.026, 0.015, mat_acero, 8))
	var dir_tibia := (p2 - p1).normalized()
	var q_punta := Quaternion(Vector3.DOWN, dir_tibia)
	var eul_punta := q_punta.get_euler()
	var len_punta: float = (p2 - p1).length() * 0.28
	var mid_punta: Vector3 = p1.lerp(p2, 0.86)
	pata.add_child(Kit.cyl(
		0.016,
		0.003,
		len_punta,
		mat_acero,
		mid_punta,
		Vector3(rad_to_deg(eul_punta.x), rad_to_deg(eul_punta.y), rad_to_deg(eul_punta.z)),
		8
	))
	return pata


static func parasito_cursor() -> Node3D:
	var pack := Kit.crear_raiz_enemigo("ParasitoCursor")
	var raiz: Node3D = pack["raiz"]
	var rig: Node3D = pack["rig"]

	var tex_quitina := Kit.tex_quitina_bio(Color(0.14, 0.20, 0.14), 841)
	var tex_acero := Kit.tex_acero_bunker(Color(0.22, 0.24, 0.27), 383)
	var tex_hazard := Kit.tex_hazard_desgastado(571)

	var mat_quitina := Kit.mat_pbr(Color.WHITE, 0.18, 0.52, tex_quitina)
	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.54, 0.48, tex_acero)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.28, 0.56, tex_hazard)
	var mat_nucleo := Kit.mat_emissive(Color(0.14, 0.56, 0.50), Color(0.18, 0.86, 0.72), 0.45, 0.26)
	var mat_optico := Kit.mat_emissive(Color(0.14, 0.58, 0.62), Color(0.18, 0.86, 0.90), 0.40, 0.25)

	var cuerpo := Node3D.new()
	cuerpo.name = "CuerpoBicho"
	cuerpo.position = Vector3(0.0, 0.42, 0.0)
	rig.add_child(cuerpo)

	cuerpo.add_child(Kit.prisma_biselado(Vector3(0.38, 0.14, 0.44), 0.032, mat_acero, Vector3(0.0, 0.0, 0.0)))

	for seg_info in [
		[Vector3(0.0, 0.12, 0.12), Vector3(0.38, 0.16, 0.20), -10.0],
		[Vector3(0.0, 0.17, -0.02), Vector3(0.42, 0.18, 0.22), 0.0],
		[Vector3(0.0, 0.14, -0.16), Vector3(0.36, 0.15, 0.18), 10.0],
	]:
		cuerpo.add_child(Kit.prisma_biselado(seg_info[1], 0.042, mat_quitina, seg_info[0], Vector3(seg_info[2], 0.0, 0.0), Vector2(0.84, 0.86)))

	cuerpo.add_child(Kit.esfera(0.085, mat_nucleo, Vector3(0.0, 0.30, -0.02), Vector3(1.0, 0.95, 1.0), 12, 8))
	cuerpo.add_child(Kit.toro(0.145, 0.120, mat_acero, Vector3(0.0, 0.24, -0.02), Vector3.ZERO, Vector3.ONE, 14))
	for a_arco in [-45.0, 45.0]:
		var arco_n := Kit.arco_curvo(0.135, 0.024, -0.02, 0.02, -90.0, 90.0, mat_acero, 12)
		arco_n.position = Vector3(0.0, 0.28, -0.02)
		arco_n.rotation_degrees = Vector3(-90.0, a_arco, 0.0)
		cuerpo.add_child(arco_n)
	cuerpo.add_child(Kit.cyl(0.012, 0.022, 0.10, mat_acero, Vector3(0.0, 0.43, -0.02), Vector3.ZERO, 8))

	var cabeza := Node3D.new()
	cabeza.name = "CabezaRobotica"
	cabeza.position = Vector3(0.0, -0.01, 0.24)
	cuerpo.add_child(cabeza)

	cabeza.add_child(Kit.prisma_biselado(Vector3(0.24, 0.14, 0.18), 0.028, mat_acero, Vector3(0.0, 0.02, 0.04)))
	cabeza.add_child(Kit.esfera(0.020, mat_optico, Vector3(0.052, 0.035, 0.132), Vector3.ONE, 8, 6))
	cabeza.add_child(Kit.esfera(0.020, mat_optico, Vector3(-0.052, 0.035, 0.132), Vector3.ONE, 8, 6))
	cabeza.add_child(Kit.esfera(0.013, mat_optico, Vector3(0.088, 0.015, 0.118), Vector3.ONE, 8, 6))
	cabeza.add_child(Kit.esfera(0.013, mat_optico, Vector3(-0.088, 0.015, 0.118), Vector3.ONE, 8, 6))
	for sx in [-1.0, 1.0]:
		cabeza.add_child(Kit.hoja_filo(0.22, 0.048, 0.026, -sx * 0.055, mat_acero, 6, Vector3(sx * 0.095, -0.03, 0.09), Vector3(92.0, 0.0, 0.0)))

	var abdomen := Node3D.new()
	abdomen.name = "AbdomenNanitas"
	abdomen.position = Vector3(0.0, 0.05, -0.24)
	abdomen.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	cuerpo.add_child(abdomen)

	var sec_abd := [
		{"y": 0.00, "rx": 0.16, "rz": 0.14, "bevel": 0.50},
		{"y": 0.14, "rx": 0.21, "rz": 0.19, "bevel": 0.55},
		{"y": 0.28, "rx": 0.15, "rz": 0.14, "bevel": 0.45},
	]
	abdomen.add_child(Kit.loft_perfil(sec_abd, mat_hazard, 12, true, Vector3.ZERO, Vector3(-90.0, 0.0, 0.0)))
	abdomen.add_child(Kit.toro(0.215, 0.190, mat_acero, Vector3(0.0, 0.0, -0.14), Vector3(90.0, 0.0, 0.0), Vector3.ONE, 14))
	abdomen.add_child(Kit.cyl(0.024, 0.038, 0.08, mat_acero, Vector3(0.0, 0.0, -0.31), Vector3(-90.0, 0.0, 0.0), 10))

	var patas_cfg := [
		["Pata_1_I", 1.0, Vector3(0.20, -0.04, 0.16), 0.12, 0.22],
		["Pata_1_D", -1.0, Vector3(-0.20, -0.04, 0.16), 0.12, 0.22],
		["Pata_2_I", 1.0, Vector3(0.20, -0.04, 0.00), 0.00, 0.00],
		["Pata_2_D", -1.0, Vector3(-0.20, -0.04, 0.00), 0.00, 0.00],
		["Pata_3_I", 1.0, Vector3(0.20, -0.04, -0.16), -0.12, -0.22],
		["Pata_3_D", -1.0, Vector3(-0.20, -0.04, -0.16), -0.12, -0.22],
	]
	for pc in patas_cfg:
		cuerpo.add_child(_construir_pata_aracnido(pc[0], pc[1], pc[2], pc[3], pc[4], mat_quitina, mat_acero))

	var altura := Kit.normalizar_base_suelo(rig)
	_validar_altura("parasito_cursor", altura, 0.90)
	Kit.agregar_animaciones_aracnido(raiz, rig)
	return raiz


# ==============================================================================
# REGISTRO GLOBAL DE CONSTRUCTORES
# ==============================================================================

static func construir_todos() -> Dictionary:
	return {
		"espectro": {
			"nodo": espectro(),
			"ruta": "res://assets/modelos/enemigo_espectro_foso.glb",
		},
		"berserker": {
			"nodo": berserker(),
			"ruta": "res://assets/modelos/enemigo_berserker_rabioso.glb",
		},
		"kamikaze": {
			"nodo": kamikaze(),
			"ruta": "res://assets/modelos/enemigo_minero_kamikaze.glb",
		},
		"bruto": {
			"nodo": bruto(),
			"ruta": "res://assets/modelos/enemigo_bruto_aplastador.glb",
		},
		"parasito_cursor": {
			"nodo": parasito_cursor(),
			"ruta": "res://assets/modelos/enemigo_parasito_cursor.glb",
		},
	}
