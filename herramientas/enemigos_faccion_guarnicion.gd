@tool
class_name EnemigosFaccionGuarnicion
extends RefCounted

const Kit = preload("res://herramientas/enemigos_pbr_kit.gd")

## ==============================================================================
## FACCIÓN GUARNICIÓN / PRETORIANOS DEL COLISEO (5 MODELOS PBR PROCEDURALES)
## - Orientación nativa +Z dentro de RigVisual (rotado 180° en Y -> frente -Z)
## - Uso exclusivo de Kit.mat_pbr y Kit.mat_emissive
## - Base apoyada en y = 0.0 antes de generar clips glTF-compatibles
## ==============================================================================


# ==============================================================================
# HELPERS INTERNOS DE CONSTRUCCIÓN
# ==============================================================================

static func _crear_hombrera_montada(
	nombre: String,
	radio: float,
	grosor: float,
	alto: float,
	arco_deg: float,
	mat: Material,
	pos: Vector3,
	es_izq: bool,
	inclinacion_deg: float = 24.0
) -> Node3D:
	var pivote := Node3D.new()
	pivote.name = nombre
	pivote.position = pos
	pivote.rotation_degrees = Vector3(0.0, 0.0, -inclinacion_deg if es_izq else inclinacion_deg)
	var arco := Kit.hombrera_curva(
		radio,
		grosor,
		alto,
		arco_deg,
		mat,
		Vector3.ZERO,
		Vector3(0.0, -90.0 if es_izq else 90.0, 0.0)
	)
	arco.name = nombre + "Placa"
	pivote.add_child(arco)
	return pivote


static func _agregar_pierna_bipeda(
	rig: Node3D,
	nombre: String,
	pos_cadera: Vector3,
	dims: Dictionary,
	mat_primario: Material,
	mat_oscuro: Material,
	mat_detalle: Material,
	segs_rodilla: int = 12
) -> Node3D:
	var pierna := Node3D.new()
	pierna.name = nombre
	pierna.position = pos_cadera
	rig.add_child(pierna)

	var h_total: float = pos_cadera.y
	var h_muslo: float = float(dims["h_muslo"])
	var h_greba: float = float(dims["h_greba"])
	var h_bota: float = float(dims["h_bota"])
	var r_muslo: Vector2 = dims["r_muslo"]
	var r_greba: Vector2 = dims["r_greba"]
	var s_bota: Vector3 = dims["s_bota"]

	var cadera := Kit.esfera(r_muslo.x * 0.52, mat_oscuro, Vector3(0.0, -0.02, 0.0))
	cadera.name = "ArticulacionCadera"
	pierna.add_child(cadera)

	var muslo := Kit.prisma_biselado(
		Vector3(r_muslo.x, h_muslo, r_muslo.y),
		r_muslo.x * 0.14,
		mat_primario,
		Vector3(0.0, -h_muslo * 0.5 - 0.02, 0.0),
		Vector3.ZERO,
		Vector2(1.06, 1.05)
	)
	muslo.name = "Muslo"
	pierna.add_child(muslo)

	var y_rodilla := -(h_muslo + 0.04)
	var rodilla := Kit.prisma_biselado(
		Vector3(r_muslo.x * 0.88, 0.16, r_muslo.y * 0.72),
		0.032,
		mat_detalle,
		Vector3(0.0, y_rodilla, r_muslo.y * 0.36),
		Vector3(8.0, 0.0, 0.0),
		Vector2(0.86, 0.86),
		segs_rodilla
	)
	rodilla.name = "Rodillera"
	pierna.add_child(rodilla)

	var y_greba := y_rodilla - h_greba * 0.5 + 0.02
	var greba := Kit.prisma_biselado(
		Vector3(r_greba.x, h_greba, r_greba.y),
		r_greba.x * 0.15,
		mat_primario,
		Vector3(0.0, y_greba, -0.01),
		Vector3.ZERO,
		Vector2(1.06, 1.06)
	)
	greba.name = "Greba"
	pierna.add_child(greba)

	var bota := Kit.prisma_biselado(
		Vector3(s_bota.x, h_bota, s_bota.z),
		0.024,
		mat_oscuro,
		Vector3(0.0, -h_total + h_bota * 0.5, s_bota.z * 0.18),
		Vector3.ZERO,
		Vector2(0.84, 0.86)
	)
	bota.name = "Bota"
	pierna.add_child(bota)

	return pierna


# ==============================================================================
# 1. GUARDIA PRETORIANO (~2.45m)
# ==============================================================================

static func guardia() -> Node3D:
	var raiz_dict := Kit.crear_raiz_enemigo("GuardiaPretoriano")
	var raiz: Node3D = raiz_dict["raiz"]
	var rig: Node3D = raiz_dict["rig"]

	var tex_acero := Kit.tex_acero_bunker(Color(0.20, 0.23, 0.27), 311)
	var tex_bronce := Kit.tex_bronce_oxidado(Color(0.50, 0.37, 0.20), 421)
	var tex_hazard := Kit.tex_hazard_desgastado(509)

	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.52, 0.46, tex_acero)
	var mat_acero_oscuro := Kit.mat_pbr(Color(0.68, 0.70, 0.74), 0.48, 0.54, tex_acero)
	var mat_bronce := Kit.mat_pbr(Color.WHITE, 0.52, 0.46, tex_bronce)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.28, 0.60, tex_hazard)
	var mat_cobre := Kit.mat_pbr(Color(0.58, 0.33, 0.17), 0.54, 0.44)
	var mat_obsidiana := Kit.mat_pbr(Color(0.05, 0.06, 0.08), 0.45, 0.36)
	var mat_ambar_45 := Kit.mat_emissive(Color(0.95, 0.62, 0.14), Color(1.0, 0.58, 0.10), 0.45)
	var mat_ambar_40 := Kit.mat_emissive(Color(0.92, 0.58, 0.14), Color(1.0, 0.56, 0.10), 0.40)

	# Piernas (h_total = 1.00m -> suela exacta en y = 0.0)
	var dims_pierna := {
		"h_muslo": 0.44,
		"h_greba": 0.40,
		"h_bota": 0.14,
		"r_muslo": Vector2(0.21, 0.23),
		"r_greba": Vector2(0.19, 0.21),
		"s_bota": Vector3(0.22, 0.14, 0.34),
	}
	_agregar_pierna_bipeda(rig, "PiernaIzq", Vector3(-0.20, 1.00, 0.0), dims_pierna, mat_acero, mat_acero_oscuro, mat_bronce, 6)
	_agregar_pierna_bipeda(rig, "PiernaDer", Vector3(0.20, 1.00, 0.0), dims_pierna, mat_acero, mat_acero_oscuro, mat_bronce, 6)

	# Torso acorazado (base en y = 1.02)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.02, 0.0)
	rig.add_child(torso)

	var nucleo_torso := Kit.loft_perfil([
		{"y": -0.04, "rx": 0.23, "rz": 0.17, "bevel": 0.65},
		{"y": 0.12, "rx": 0.25, "rz": 0.18, "bevel": 0.70},
		{"y": 0.44, "rx": 0.34, "rz": 0.24, "bevel": 0.72},
		{"y": 0.72, "rx": 0.38, "rz": 0.25, "bevel": 0.70},
		{"y": 0.88, "rx": 0.28, "rz": 0.19, "bevel": 0.60},
	], mat_acero_oscuro, 16)
	nucleo_torso.name = "NucleoTorso"
	torso.add_child(nucleo_torso)

	var peto := Kit.prisma_biselado(Vector3(0.56, 0.44, 0.16), 0.035, mat_acero, Vector3(0.0, 0.56, 0.20), Vector3(-6.0, 0.0, 0.0), Vector2(1.06, 0.90))
	peto.name = "PetoRemachado"
	torso.add_child(peto)

	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var placa_bronce := Kit.prisma_biselado(
			Vector3(0.20, 0.32, 0.08),
			0.02,
			mat_bronce,
			Vector3(lado * 0.16, 0.57, 0.26),
			Vector3(-6.0, lado * 12.0, 0.0)
		)
		placa_bronce.name = "PlacaBronce" + suf
		torso.add_child(placa_bronce)

		var escarcela := Kit.prisma_biselado(
			Vector3(0.18, 0.20, 0.09),
			0.02,
			mat_bronce,
			Vector3(lado * 0.20, 0.00, 0.16),
			Vector3(10.0, lado * 18.0, 0.0)
		)
		escarcela.name = "Escarcela" + suf
		torso.add_child(escarcela)

	var cresta_peto := Kit.prisma_biselado(Vector3(0.10, 0.38, 0.08), 0.02, mat_bronce, Vector3(0.0, 0.56, 0.28), Vector3(-6.0, 0.0, 0.0))
	cresta_peto.name = "BlindajePectoral"
	torso.add_child(cresta_peto)

	var cinturon := Kit.prisma_biselado(Vector3(0.54, 0.11, 0.40), 0.015, mat_acero_oscuro, Vector3(0.0, 0.12, 0.0))
	cinturon.name = "CinturonUtilitario"
	torso.add_child(cinturon)

	var hebilla := Kit.prisma_biselado(Vector3(0.16, 0.12, 0.06), 0.015, mat_bronce, Vector3(0.0, 0.12, 0.21))
	hebilla.name = "HebillaMetalica"
	torso.add_child(hebilla)

	var mochila := Kit.prisma_biselado(Vector3(0.38, 0.48, 0.22), 0.035, mat_acero_oscuro, Vector3(0.0, 0.56, -0.25))
	mochila.name = "ModuloDorsal"
	torso.add_child(mochila)

	# Cabeza (pivot en world y = 1.92 -> tope yelmo en 2.45m)
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 0.90, 0.0)
	torso.add_child(cabeza)

	var cuello := Kit.cyl(0.11, 0.13, 0.14, mat_acero_oscuro, Vector3(0.0, 0.05, 0.0))
	cuello.name = "Cuello"
	cabeza.add_child(cuello)

	var yelmo := Kit.prisma_biselado(Vector3(0.32, 0.38, 0.36), 0.05, mat_acero_oscuro, Vector3(0.0, 0.28, 0.02), Vector3(7.0, 0.0, 0.0), Vector2(0.84, 0.88))
	yelmo.name = "YelmoBalistico"
	cabeza.add_child(yelmo)

	var cresta_yelmo := Kit.prisma_biselado(Vector3(0.22, 0.08, 0.30), 0.02, mat_bronce, Vector3(0.0, 0.49, 0.01), Vector3(4.0, 0.0, 0.0), Vector2(0.80, 0.85))
	cresta_yelmo.name = "CimeraYelmo"
	cabeza.add_child(cresta_yelmo)

	var visor := Kit.prisma_biselado(Vector3(0.24, 0.11, 0.08), 0.015, mat_obsidiana, Vector3(0.0, 0.27, 0.18), Vector3(7.0, 0.0, 0.0))
	visor.name = "VisorObsidiana"
	cabeza.add_child(visor)

	var hendidura := Kit.caja(Vector3(0.19, 0.020, 0.025), mat_ambar_45, Vector3(0.0, 0.275, 0.218), Vector3(7.0, 0.0, 0.0))
	hendidura.name = "HendiduraOptica"
	cabeza.add_child(hendidura)

	# Brazos (hijos de Torso)
	var brazo_l := Node3D.new()
	brazo_l.name = "BrazoIzq"
	brazo_l.position = Vector3(-0.44, 0.74, 0.0)
	torso.add_child(brazo_l)

	brazo_l.add_child(_crear_hombrera_montada("HombreraIzq", 0.16, 0.045, 0.28, 125.0, mat_bronce, Vector3(-0.02, 0.04, 0.0), true, 24.0))

	var sup_l := Kit.cyl(0.095, 0.085, 0.32, mat_acero_oscuro, Vector3(0.0, -0.18, 0.0))
	sup_l.name = "BrazoSupIzq"
	brazo_l.add_child(sup_l)

	var codo_l := Kit.esfera(0.085, mat_acero, Vector3(0.0, -0.35, 0.0))
	codo_l.name = "CodoIzq"
	brazo_l.add_child(codo_l)

	var ant_l := Kit.prisma_biselado(Vector3(0.17, 0.34, 0.18), 0.025, mat_acero, Vector3(0.0, -0.52, 0.05), Vector3(-12.0, 0.0, 0.0), Vector2(1.08, 1.08))
	ant_l.name = "AntebrazoIzq"
	brazo_l.add_child(ant_l)

	# Pavés táctico rectangular en BrazoIzq
	var paves := Node3D.new()
	paves.name = "PavesBlindado"
	paves.position = Vector3(-0.14, -0.48, 0.22)
	paves.rotation_degrees = Vector3(-6.0, -14.0, 0.0)
	brazo_l.add_child(paves)

	var cuerpo_paves := Kit.prisma_biselado(Vector3(0.62, 1.22, 0.09), 0.03, mat_acero, Vector3.ZERO)
	cuerpo_paves.name = "PlacaPaves"
	paves.add_child(cuerpo_paves)

	var borde_sup := Kit.prisma_biselado(Vector3(0.64, 0.08, 0.11), 0.015, mat_bronce, Vector3(0.0, 0.56, 0.01))
	borde_sup.name = "BordeSupPaves"
	paves.add_child(borde_sup)

	var borde_inf := Kit.prisma_biselado(Vector3(0.64, 0.08, 0.11), 0.015, mat_bronce, Vector3(0.0, -0.56, 0.01))
	borde_inf.name = "BordeInfPaves"
	paves.add_child(borde_inf)

	var franja_paves := Kit.prisma_biselado(Vector3(0.54, 0.16, 0.025), 0.008, mat_hazard, Vector3(0.0, -0.34, 0.048))
	franja_paves.name = "FranjaHazardPaves"
	paves.add_child(franja_paves)

	var marco_mirilla := Kit.prisma_biselado(Vector3(0.24, 0.075, 0.03), 0.01, mat_acero_oscuro, Vector3(0.0, 0.36, 0.046))
	marco_mirilla.name = "ViseraMirilla"
	paves.add_child(marco_mirilla)

	var mirilla := Kit.caja(Vector3(0.18, 0.032, 0.022), mat_ambar_40, Vector3(0.0, 0.36, 0.056))
	mirilla.name = "MirillaOptica"
	paves.add_child(mirilla)

	# BrazoDer + pica/porra industrial
	var brazo_r := Node3D.new()
	brazo_r.name = "BrazoDer"
	brazo_r.position = Vector3(0.44, 0.74, 0.0)
	torso.add_child(brazo_r)

	brazo_r.add_child(_crear_hombrera_montada("HombreraDer", 0.16, 0.045, 0.28, 125.0, mat_bronce, Vector3(0.02, 0.04, 0.0), false, 24.0))

	var sup_r := Kit.cyl(0.095, 0.085, 0.32, mat_acero_oscuro, Vector3(0.0, -0.18, 0.0))
	sup_r.name = "BrazoSupDer"
	brazo_r.add_child(sup_r)

	var codo_r := Kit.esfera(0.085, mat_acero, Vector3(0.0, -0.35, 0.0))
	codo_r.name = "CodoDer"
	brazo_r.add_child(codo_r)

	var ant_r := Kit.prisma_biselado(Vector3(0.17, 0.34, 0.18), 0.025, mat_acero, Vector3(0.0, -0.52, 0.05), Vector3(-12.0, 0.0, 0.0), Vector2(1.08, 1.08))
	ant_r.name = "AntebrazoDer"
	brazo_r.add_child(ant_r)

	var porra := Node3D.new()
	porra.name = "PorraContencion"
	porra.position = Vector3(0.02, -0.66, 0.10)
	porra.rotation_degrees = Vector3(74.0, 0.0, 0.0)
	brazo_r.add_child(porra)

	var asta := Kit.cyl(0.032, 0.035, 1.00, mat_acero_oscuro, Vector3(0.0, 0.20, 0.0))
	asta.name = "AstaPorra"
	porra.add_child(asta)

	var amortiguador := Kit.cyl(0.058, 0.058, 0.14, mat_cobre, Vector3(0.0, 0.72, 0.0))
	amortiguador.name = "AnilloAmortiguador"
	porra.add_child(amortiguador)

	var aro_cobre := Kit.toro(0.070, 0.052, mat_cobre, Vector3(0.0, 0.72, 0.0))
	aro_cobre.name = "AroAmortiguador"
	porra.add_child(aro_cobre)

	var punta := Kit.cyl(0.005, 0.068, 0.32, mat_acero, Vector3(0.0, 0.95, 0.0))
	punta.name = "PuntaConica"
	porra.add_child(punta)

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig)
	return raiz


# ==============================================================================
# 2. ARQUERO BALÍSTICO (~2.30m)
# ==============================================================================

static func arquero() -> Node3D:
	var raiz_dict := Kit.crear_raiz_enemigo("ArqueroBalistico")
	var raiz: Node3D = raiz_dict["raiz"]
	var rig: Node3D = raiz_dict["rig"]

	var tex_oliva := Kit.tex_acero_bunker(Color(0.26, 0.30, 0.25), 347)
	var tex_acero := Kit.tex_acero_bunker(Color(0.32, 0.35, 0.38), 353)
	var tex_tela := Kit.tex_tela_tactica(Color(0.18, 0.21, 0.17), Color(0.09, 0.11, 0.09), Color(0.14, 0.13, 0.10), true, 619)

	var mat_oliva := Kit.mat_pbr(Color.WHITE, 0.34, 0.62, tex_oliva)
	var mat_oscuro := Kit.mat_pbr(Color(0.18, 0.20, 0.22), 0.42, 0.54)
	var mat_acero_cepillado := Kit.mat_pbr(Color.WHITE, 0.56, 0.40, tex_acero)
	var mat_cobre_mate := Kit.mat_pbr(Color(0.55, 0.34, 0.18), 0.48, 0.44)
	var mat_tela := Kit.mat_pbr(Color.WHITE, 0.04, 0.86, tex_tela, 0.995, true)
	var mat_obsidiana := Kit.mat_pbr(Color(0.05, 0.06, 0.07), 0.44, 0.36)
	var mat_ambar_48 := Kit.mat_emissive(Color(0.95, 0.62, 0.15), Color(1.0, 0.58, 0.10), 0.48)
	var mat_cian_45 := Kit.mat_emissive(Color(0.22, 0.72, 0.82), Color(0.18, 0.76, 0.90), 0.45)

	# Piernas esbeltas (h_total = 1.02m -> y_min = 0.0)
	var dims_pierna := {
		"h_muslo": 0.46,
		"h_greba": 0.42,
		"h_bota": 0.12,
		"r_muslo": Vector2(0.15, 0.16),
		"r_greba": Vector2(0.13, 0.15),
		"s_bota": Vector3(0.15, 0.12, 0.28),
	}
	_agregar_pierna_bipeda(rig, "PiernaIzq", Vector3(-0.15, 1.02, 0.0), dims_pierna, mat_oliva, mat_oscuro, mat_oscuro, 10)
	_agregar_pierna_bipeda(rig, "PiernaDer", Vector3(0.15, 1.02, 0.0), dims_pierna, mat_oliva, mat_oscuro, mat_oscuro, 10)

	# Torso esbelto (base en y = 1.04)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.04, 0.0)
	rig.add_child(torso)

	var cuerpo_torso := Kit.loft_perfil([
		{"y": -0.02, "rx": 0.17, "rz": 0.13, "bevel": 0.60},
		{"y": 0.14, "rx": 0.18, "rz": 0.14, "bevel": 0.66},
		{"y": 0.44, "rx": 0.25, "rz": 0.18, "bevel": 0.70},
		{"y": 0.68, "rx": 0.27, "rz": 0.19, "bevel": 0.66},
		{"y": 0.80, "rx": 0.19, "rz": 0.14, "bevel": 0.56},
	], mat_oliva, 16)
	cuerpo_torso.name = "CuerpoTorso"
	torso.add_child(cuerpo_torso)

	var arnes := Kit.prisma_biselado(Vector3(0.38, 0.34, 0.08), 0.02, mat_oscuro, Vector3(0.0, 0.50, 0.16))
	arnes.name = "ArnesBalistico"
	torso.add_child(arnes)

	for sx in [-1.0, 1.0]:
		var tirante := Kit.prisma_biselado(Vector3(0.065, 0.42, 0.03), 0.008, mat_cobre_mate, Vector3(sx * 0.11, 0.49, 0.205), Vector3(0.0, 0.0, sx * 22.0))
		tirante.name = "TiranteCobre" + ("Izq" if sx < 0.0 else "Der")
		torso.add_child(tirante)

	var cinturon := Kit.prisma_biselado(Vector3(0.38, 0.08, 0.30), 0.012, mat_oscuro, Vector3(0.0, 0.12, 0.0))
	cinturon.name = "CinturonTactico"
	torso.add_child(cinturon)

	# Capa corta dorsal desgarrada
	var capa := Kit.capa_colgante(0.76, -0.18, 0.27, 0.20, 0.40, 0.26, 130.0, 230.0, mat_tela, 0.06)
	capa.name = "CapaDorsal"
	torso.add_child(capa)

	# Carcaj condensador dorsal con 3 bobinas de cobre y 3 flechas metálicas
	var carcaj := Node3D.new()
	carcaj.name = "CarcajCondensador"
	carcaj.position = Vector3(-0.12, 0.46, -0.24)
	carcaj.rotation_degrees = Vector3(-12.0, 0.0, -18.0)
	torso.add_child(carcaj)

	var tubo_carcaj := Kit.cyl(0.082, 0.075, 0.56, mat_oscuro, Vector3.ZERO)
	tubo_carcaj.name = "CilindroCondensador"
	carcaj.add_child(tubo_carcaj)

	for i in range(3):
		var y_bobina := -0.14 + float(i) * 0.14
		var bobina := Kit.toro(0.098, 0.079, mat_cobre_mate, Vector3(0.0, y_bobina, 0.0))
		bobina.name = "BobinaCobre" + str(i + 1)
		carcaj.add_child(bobina)

	var offsets_flechas := [Vector2(-0.025, 0.02), Vector2(0.025, 0.01), Vector2(0.0, -0.025)]
	for i in range(3):
		var off: Vector2 = offsets_flechas[i]
		var fl := Node3D.new()
		fl.name = "FlechaCarcaj" + str(i + 1)
		fl.position = Vector3(off.x, 0.28, off.y)
		carcaj.add_child(fl)

		var asta_f := Kit.cyl(0.008, 0.008, 0.24, mat_acero_cepillado, Vector3(0.0, 0.06, 0.0))
		asta_f.name = "Asta"
		fl.add_child(asta_f)

		var pluma_f := Kit.caja(Vector3(0.028, 0.07, 0.004), mat_cobre_mate, Vector3(0.0, 0.16, 0.0))
		pluma_f.name = "Estabilizador"
		fl.add_child(pluma_f)

	# Cabeza (pivot en world y = 1.86 -> tope casco en 2.30m)
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 0.82, 0.0)
	torso.add_child(cabeza)

	var cuello := Kit.cyl(0.085, 0.10, 0.12, mat_oscuro, Vector3(0.0, 0.04, 0.0))
	cuello.name = "Cuello"
	cabeza.add_child(cuello)

	var casco := Kit.prisma_biselado(Vector3(0.25, 0.34, 0.32), 0.04, mat_oliva, Vector3(0.0, 0.22, 0.01), Vector3(4.0, 0.0, 0.0), Vector2(0.84, 0.88))
	casco.name = "CascoTelemetro"
	cabeza.add_child(casco)

	var modulo_telemetro := Kit.prisma_biselado(Vector3(0.18, 0.10, 0.26), 0.02, mat_oscuro, Vector3(0.0, 0.39, 0.02), Vector3.ZERO, Vector2(0.84, 0.86))
	modulo_telemetro.name = "ModuloTelemetro"
	cabeza.add_child(modulo_telemetro)

	var visor := Kit.prisma_biselado(Vector3(0.21, 0.11, 0.07), 0.015, mat_obsidiana, Vector3(0.0, 0.21, 0.155), Vector3(4.0, 0.0, 0.0))
	visor.name = "VisorObsidiana"
	cabeza.add_child(visor)

	var lentes := [
		{"pos": Vector3(-0.048, 0.22, 0.195), "r": 0.020},
		{"pos": Vector3(0.004, 0.205, 0.198), "r": 0.024},
		{"pos": Vector3(0.055, 0.225, 0.194), "r": 0.017},
	]
	for i in range(lentes.size()):
		var ld: Dictionary = lentes[i]
		var aro := Kit.cyl(float(ld["r"]) + 0.007, float(ld["r"]) + 0.007, 0.020, mat_oscuro, ld["pos"] as Vector3, Vector3(90.0, 0.0, 0.0))
		aro.name = "AroLente" + str(i + 1)
		cabeza.add_child(aro)
		var lente := Kit.esfera(float(ld["r"]), mat_ambar_48, (ld["pos"] as Vector3) + Vector3(0.0, 0.0, 0.006))
		lente.name = "LenteAmbar" + str(i + 1)
		cabeza.add_child(lente)

	# Brazos
	var brazo_l := Node3D.new()
	brazo_l.name = "BrazoIzq"
	brazo_l.position = Vector3(-0.32, 0.70, 0.0)
	brazo_l.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	torso.add_child(brazo_l)

	brazo_l.add_child(_crear_hombrera_montada("HombreraIzq", 0.11, 0.032, 0.22, 115.0, mat_oliva, Vector3(-0.01, 0.02, 0.0), true, 22.0))

	var sup_l := Kit.cyl(0.070, 0.064, 0.30, mat_oscuro, Vector3(0.0, -0.16, 0.0))
	sup_l.name = "BrazoSupIzq"
	brazo_l.add_child(sup_l)

	var ant_l := Kit.prisma_biselado(Vector3(0.12, 0.30, 0.13), 0.018, mat_oliva, Vector3(0.0, -0.44, 0.06), Vector3(-16.0, 0.0, 0.0))
	ant_l.name = "AntebrazoIzq"
	brazo_l.add_child(ant_l)

	# Gran arco compuesto balístico en BrazoIzq apuntando hacia +Z
	var arco := Node3D.new()
	arco.name = "ArcoCompuesto"
	arco.position = Vector3(-0.04, -0.46, 0.24)
	arco.rotation_degrees = Vector3(-16.0, -14.0, 0.0)
	brazo_l.add_child(arco)

	var cuerpo_arco := Kit.prisma_biselado(Vector3(0.055, 0.44, 0.095), 0.012, mat_acero_cepillado, Vector3(0.0, 0.0, 0.06))
	cuerpo_arco.name = "CuerpoArco"
	arco.add_child(cuerpo_arco)

	var rama_sup := Kit.tubo_curvo([
		Vector3(0.0, 0.20, 0.06),
		Vector3(0.0, 0.42, 0.02),
		Vector3(0.0, 0.62, -0.12),
		Vector3(0.0, 0.68, -0.22),
	], 0.026, 0.016, mat_acero_cepillado, 10)
	rama_sup.name = "RamaSup"
	arco.add_child(rama_sup)

	var rama_inf := Kit.tubo_curvo([
		Vector3(0.0, -0.20, 0.06),
		Vector3(0.0, -0.42, 0.02),
		Vector3(0.0, -0.62, -0.12),
		Vector3(0.0, -0.68, -0.22),
	], 0.026, 0.016, mat_acero_cepillado, 10)
	rama_inf.name = "RamaInf"
	arco.add_child(rama_inf)

	for s_y in [-1.0, 1.0]:
		var suf_p := "Inf" if s_y < 0.0 else "Sup"
		var polea := Kit.cyl(0.068, 0.068, 0.028, mat_cobre_mate, Vector3(0.0, s_y * 0.68, -0.23), Vector3(0.0, 0.0, 90.0))
		polea.name = "PoleaExcentrica" + suf_p
		arco.add_child(polea)
		var eje_p := Kit.cyl(0.022, 0.022, 0.044, mat_oscuro, Vector3(0.0, s_y * 0.66, -0.21), Vector3(0.0, 0.0, 90.0))
		eje_p.name = "EjePolea" + suf_p
		arco.add_child(eje_p)

	var cuerda := Kit.cyl(0.005, 0.005, 1.36, mat_acero_cepillado, Vector3(0.0, 0.0, -0.24))
	cuerda.name = "CuerdaArco"
	arco.add_child(cuerda)

	var riel := Kit.caja(Vector3(0.022, 0.022, 0.40), mat_cian_45, Vector3(0.0, 0.04, 0.18))
	riel.name = "RielTensor"
	arco.add_child(riel)

	var flecha_armada := Node3D.new()
	flecha_armada.name = "FlechaArmada"
	flecha_armada.position = Vector3(0.0, 0.07, 0.0)
	arco.add_child(flecha_armada)

	var asta_armada := Kit.cyl(0.009, 0.009, 0.72, mat_acero_cepillado, Vector3(0.0, 0.0, 0.14), Vector3(90.0, 0.0, 0.0))
	asta_armada.name = "AstaArmada"
	flecha_armada.add_child(asta_armada)

	var punta_armada := Kit.hoja_filo(0.12, 0.055, 0.018, 0.0, mat_acero_cepillado, 4, Vector3(0.0, 0.0, 0.50), Vector3(90.0, 0.0, 0.0))
	punta_armada.name = "PuntaArmada"
	flecha_armada.add_child(punta_armada)

	var brazo_r := Node3D.new()
	brazo_r.name = "BrazoDer"
	brazo_r.position = Vector3(0.32, 0.70, 0.0)
	torso.add_child(brazo_r)

	brazo_r.add_child(_crear_hombrera_montada("HombreraDer", 0.11, 0.032, 0.22, 115.0, mat_oliva, Vector3(0.01, 0.02, 0.0), false, 22.0))

	var sup_r := Kit.cyl(0.070, 0.064, 0.30, mat_oscuro, Vector3(0.0, -0.16, 0.0))
	sup_r.name = "BrazoSupDer"
	brazo_r.add_child(sup_r)

	var ant_r := Kit.prisma_biselado(Vector3(0.12, 0.30, 0.13), 0.018, mat_oliva, Vector3(0.0, -0.44, 0.06), Vector3(-16.0, 0.0, 0.0))
	ant_r.name = "AntebrazoDer"
	brazo_r.add_child(ant_r)

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig)
	return raiz


# ==============================================================================
# 3. CENTURIÓN CORRUPTO (~3.20m, FLOTANTE / ERGUIDO BÍPEDO)
# ==============================================================================

static func centurion() -> Node3D:
	var raiz_dict := Kit.crear_raiz_enemigo("CenturionCorrupto")
	var raiz: Node3D = raiz_dict["raiz"]
	var rig: Node3D = raiz_dict["rig"]

	var tex_acero := Kit.tex_acero_bunker(Color(0.16, 0.18, 0.22), 331)
	var tex_bronce := Kit.tex_bronce_oxidado(Color(0.54, 0.39, 0.20), 439)
	var tex_hazard := Kit.tex_hazard_desgastado(523)

	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.54, 0.46, tex_acero)
	var mat_acero_oscuro := Kit.mat_pbr(Color(0.62, 0.64, 0.68), 0.48, 0.54, tex_acero)
	var mat_bronce := Kit.mat_pbr(Color.WHITE, 0.54, 0.44, tex_bronce)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.28, 0.58, tex_hazard)
	var mat_obsidiana := Kit.mat_pbr(Color(0.04, 0.05, 0.07), 0.46, 0.36)
	var mat_carmesi_52 := Kit.mat_emissive(Color(0.95, 0.28, 0.12), Color(1.0, 0.24, 0.08), 0.52)
	var mat_cian_42 := Kit.mat_emissive(Color(0.24, 0.78, 0.88), Color(0.20, 0.74, 0.90), 0.42)
	var mat_tobera_tenue := Kit.mat_pbr(Color(0.10, 0.12, 0.14), 0.25, 0.72)

	var cuerpo := Node3D.new()
	cuerpo.name = "Cuerpo"
	rig.add_child(cuerpo)

	# Piernas blindadas con toberas y peana en y = 0.0
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var x_p: float = lado * 0.26

		var muslo := Kit.prisma_biselado(Vector3(0.24, 0.56, 0.26), 0.035, mat_acero, Vector3(x_p, 1.12, 0.0))
		muslo.name = "MusloBlindado" + suf
		cuerpo.add_child(muslo)

		var rodilla := Kit.prisma_biselado(Vector3(0.20, 0.18, 0.18), 0.03, mat_bronce, Vector3(x_p, 0.80, 0.10), Vector3(8.0, 0.0, 0.0), Vector2(0.86, 0.86), 6)
		rodilla.name = "Rodillera" + suf
		cuerpo.add_child(rodilla)

		var greba := Kit.prisma_biselado(Vector3(0.26, 0.52, 0.28), 0.035, mat_acero, Vector3(x_p, 0.48, -0.02), Vector3.ZERO, Vector2(0.82, 0.82))
		greba.name = "GrebaPropulsora" + suf
		cuerpo.add_child(greba)

		var tobera := Kit.cyl(0.14, 0.17, 0.18, mat_acero_oscuro, Vector3(x_p, 0.13, 0.0))
		tobera.name = "Tobera" + suf
		cuerpo.add_child(tobera)

		var interior_tobera := Kit.cyl(0.11, 0.11, 0.04, mat_tobera_tenue, Vector3(x_p, 0.07, 0.0))
		interior_tobera.name = "InteriorTobera" + suf
		cuerpo.add_child(interior_tobera)

		var peana := Kit.prisma_biselado(Vector3(0.32, 0.06, 0.36), 0.015, mat_bronce, Vector3(x_p, 0.03, 0.02))
		peana.name = "PeanaEstabilizador" + suf
		cuerpo.add_child(peana)

	# Torso masivo imperial
	var nucleo := Kit.loft_perfil([
		{"y": 1.38, "rx": 0.30, "rz": 0.22, "bevel": 0.68},
		{"y": 1.62, "rx": 0.28, "rz": 0.21, "bevel": 0.72},
		{"y": 2.04, "rx": 0.48, "rz": 0.32, "bevel": 0.74},
		{"y": 2.38, "rx": 0.52, "rz": 0.30, "bevel": 0.70},
		{"y": 2.50, "rx": 0.32, "rz": 0.24, "bevel": 0.60},
	], mat_acero, 16)
	nucleo.name = "NucleoExoesqueleto"
	cuerpo.add_child(nucleo)

	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var placa_pec := Kit.prisma_biselado(
			Vector3(0.32, 0.48, 0.14),
			0.03,
			mat_bronce,
			Vector3(lado * 0.22, 2.06, 0.28),
			Vector3(-6.0, lado * 14.0, 0.0)
		)
		placa_pec.name = "BlindajePectoral" + suf
		cuerpo.add_child(placa_pec)

		var deflector := Kit.prisma_biselado(
			Vector3(0.34, 0.26, 0.40),
			0.035,
			mat_hazard,
			Vector3(lado * 0.58, 2.36, 0.0),
			Vector3(0.0, 0.0, lado * -20.0),
			Vector2(0.84, 0.88)
		)
		deflector.name = "DeflectorHombro" + suf
		cuerpo.add_child(deflector)

	var medallon := Kit.prisma_biselado(Vector3(0.18, 0.24, 0.10), 0.025, mat_bronce, Vector3(0.0, 2.06, 0.34), Vector3.ZERO, Vector2(0.86, 0.86), 6)
	medallon.name = "MedallonPectoral"
	cuerpo.add_child(medallon)

	var cinturon := Kit.prisma_biselado(Vector3(0.62, 0.12, 0.46), 0.02, mat_bronce, Vector3(0.0, 1.56, 0.0))
	cinturon.name = "CinturonImperial"
	cuerpo.add_child(cinturon)

	var yugo := Kit.prisma_biselado(Vector3(0.42, 0.54, 0.24), 0.04, mat_acero_oscuro, Vector3(0.0, 2.10, -0.28))
	yugo.name = "YugoDorsal"
	cuerpo.add_child(yugo)

	# Cabeza con cresta metálica transversal -> tope en y = 3.20m
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 2.52, 0.04)
	cuerpo.add_child(cabeza)

	var yelmo := Kit.prisma_biselado(Vector3(0.34, 0.38, 0.38), 0.05, mat_acero, Vector3(0.0, 0.20, 0.0), Vector3(4.0, 0.0, 0.0), Vector2(0.86, 0.88))
	yelmo.name = "YelmoCenturion"
	cabeza.add_child(yelmo)

	var base_cresta := Kit.prisma_biselado(Vector3(0.24, 0.10, 0.16), 0.02, mat_bronce, Vector3(0.0, 0.38, 0.0))
	base_cresta.name = "BaseCresta"
	cabeza.add_child(base_cresta)

	var cresta := Kit.loft_perfil([
		{"y": 0.36, "rx": 0.14, "rz": 0.055, "bevel": 0.55},
		{"y": 0.52, "rx": 0.29, "rz": 0.050, "bevel": 0.65},
		{"y": 0.68, "rx": 0.23, "rz": 0.030, "bevel": 0.55},
	], mat_bronce, 14)
	cresta.name = "CrestaTransversal"
	cabeza.add_child(cresta)

	var visor := Kit.prisma_biselado(Vector3(0.26, 0.12, 0.08), 0.015, mat_obsidiana, Vector3(0.0, 0.20, 0.19), Vector3(4.0, 0.0, 0.0))
	visor.name = "VisorCenturion"
	cabeza.add_child(visor)

	var hendidura := Kit.caja(Vector3(0.21, 0.024, 0.025), mat_carmesi_52, Vector3(0.0, 0.20, 0.23), Vector3(4.0, 0.0, 0.0))
	hendidura.name = "HendiduraCarmesi"
	cabeza.add_child(hendidura)

	# Anillo1 repetidor dorsal/orbital con 4 nodos cian discretos
	var anillo1 := Node3D.new()
	anillo1.name = "Anillo1"
	anillo1.position = Vector3(0.0, 2.22, -0.46)
	anillo1.rotation_degrees = Vector3(82.0, 0.0, 0.0)
	cuerpo.add_child(anillo1)

	var aro_ext := Kit.toro(0.62, 0.54, mat_acero, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 24)
	aro_ext.name = "AroRepetidor"
	anillo1.add_child(aro_ext)

	var aro_int := Kit.toro(0.52, 0.48, mat_bronce, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 24)
	aro_int.name = "AroBronce"
	anillo1.add_child(aro_int)

	var pos_nodos := [
		Vector3(0.58, 0.0, 0.0),
		Vector3(-0.58, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.58),
		Vector3(0.0, 0.0, -0.58),
	]
	for i in range(4):
		var p_n: Vector3 = pos_nodos[i]
		var caja_n := Kit.prisma_biselado(Vector3(0.10, 0.10, 0.10), 0.02, mat_acero_oscuro, p_n)
		caja_n.name = "CarcasaNodo" + str(i + 1)
		anillo1.add_child(caja_n)

		var nodo_cian := Kit.esfera(0.036, mat_cian_42, p_n + p_n.normalized() * 0.045)
		nodo_cian.name = "NodoCian" + str(i + 1)
		anillo1.add_child(nodo_cian)

	# BrazoIzq + Broquel de mando
	var brazo_l := Node3D.new()
	brazo_l.name = "BrazoIzq"
	brazo_l.position = Vector3(-0.56, 2.22, 0.0)
	cuerpo.add_child(brazo_l)

	var sup_l := Kit.cyl(0.11, 0.10, 0.40, mat_acero_oscuro, Vector3(0.0, -0.22, 0.0))
	sup_l.name = "BrazoSupIzq"
	brazo_l.add_child(sup_l)

	var ant_l := Kit.prisma_biselado(Vector3(0.19, 0.42, 0.21), 0.03, mat_acero, Vector3(0.0, -0.58, 0.06), Vector3(-12.0, 0.0, 0.0))
	ant_l.name = "AntebrazoIzq"
	brazo_l.add_child(ant_l)

	var paves_mando := Node3D.new()
	paves_mando.name = "PavesMando"
	paves_mando.position = Vector3(-0.14, -0.56, 0.22)
	paves_mando.rotation_degrees = Vector3(-8.0, -18.0, 0.0)
	brazo_l.add_child(paves_mando)

	var disco_broquel := Kit.prisma_biselado(Vector3(0.76, 0.92, 0.10), 0.035, mat_acero, Vector3.ZERO, Vector3.ZERO, Vector2(0.84, 0.84), 6)
	disco_broquel.name = "PlacaPavesMando"
	paves_mando.add_child(disco_broquel)

	var umbo_broquel := Kit.prisma_biselado(Vector3(0.32, 0.38, 0.08), 0.03, mat_bronce, Vector3(0.0, 0.0, 0.06), Vector3.ZERO, Vector2(0.80, 0.80), 6)
	umbo_broquel.name = "UmboBronce"
	paves_mando.add_child(umbo_broquel)

	# BrazoDer + Alabarda/guja cinética pesada
	var brazo_r := Node3D.new()
	brazo_r.name = "BrazoDer"
	brazo_r.position = Vector3(0.56, 2.22, 0.0)
	cuerpo.add_child(brazo_r)

	var sup_r := Kit.cyl(0.11, 0.10, 0.40, mat_acero_oscuro, Vector3(0.0, -0.22, 0.0))
	sup_r.name = "BrazoSupDer"
	brazo_r.add_child(sup_r)

	var ant_r := Kit.prisma_biselado(Vector3(0.19, 0.42, 0.21), 0.03, mat_acero, Vector3(0.0, -0.58, 0.06), Vector3(-12.0, 0.0, 0.0))
	ant_r.name = "AntebrazoDer"
	brazo_r.add_child(ant_r)

	var alabarda := Node3D.new()
	alabarda.name = "AlabardaCinetica"
	alabarda.position = Vector3(0.04, -0.68, 0.10)
	alabarda.rotation_degrees = Vector3(64.0, 0.0, 0.0)
	brazo_r.add_child(alabarda)

	var asta_a := Kit.cyl(0.032, 0.034, 1.95, mat_acero_oscuro, Vector3(0.0, 0.45, 0.0))
	asta_a.name = "AstaAlabarda"
	alabarda.add_child(asta_a)

	var collar_a := Kit.cyl(0.062, 0.056, 0.18, mat_bronce, Vector3(0.0, 1.38, 0.0))
	collar_a.name = "CollarBronce"
	alabarda.add_child(collar_a)

	var hoja_a := Kit.hoja_filo(0.62, 0.24, 0.046, 0.06, mat_acero, 8, Vector3(0.0, 1.44, 0.0))
	hoja_a.name = "HojaGuja"
	alabarda.add_child(hoja_a)

	var pico_a := Kit.hoja_filo(0.28, 0.11, 0.03, -0.05, mat_bronce, 6, Vector3(-0.04, 1.38, 0.0), Vector3(0.0, 0.0, 68.0))
	pico_a.name = "PicoAlabarda"
	alabarda.add_child(pico_a)

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_flote(raiz, rig)
	return raiz


# ==============================================================================
# 4. MINI-JEFE: HERALDO DE LA ARENA (~3.40m)
# ==============================================================================

static func mini_jefe() -> Node3D:
	var raiz_dict := Kit.crear_raiz_enemigo("HeraldoArena")
	var raiz: Node3D = raiz_dict["raiz"]
	var rig: Node3D = raiz_dict["rig"]

	var tex_acero := Kit.tex_acero_bunker(Color(0.27, 0.29, 0.33), 367)
	var tex_bronce := Kit.tex_bronce_oxidado(Color(0.54, 0.39, 0.20), 449)
	var tex_hazard := Kit.tex_hazard_desgastado(541)

	var mat_acero := Kit.mat_pbr(Color.WHITE, 0.50, 0.48, tex_acero)
	var mat_acero_oscuro := Kit.mat_pbr(Color(0.72, 0.73, 0.76), 0.48, 0.56, tex_acero)
	var mat_bronce := Kit.mat_pbr(Color.WHITE, 0.52, 0.46, tex_bronce)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.28, 0.60, tex_hazard)
	var mat_cobre := Kit.mat_pbr(Color(0.58, 0.34, 0.18), 0.54, 0.44)
	var mat_penacho := Kit.mat_pbr(Color(0.44, 0.10, 0.12), 0.18, 0.72)
	var mat_ambar_45 := Kit.mat_emissive(Color(0.95, 0.60, 0.14), Color(1.0, 0.56, 0.10), 0.45)
	var mat_ambar_52 := Kit.mat_emissive(Color(0.96, 0.62, 0.14), Color(1.0, 0.58, 0.10), 0.52)

	# Piernas blindadas gruesas (h_total = 1.24m -> y_min = 0.0)
	var dims_pierna := {
		"h_muslo": 0.54,
		"h_greba": 0.52,
		"h_bota": 0.22,
		"r_muslo": Vector2(0.36, 0.38),
		"r_greba": Vector2(0.36, 0.38),
		"s_bota": Vector3(0.42, 0.22, 0.56),
	}
	_agregar_pierna_bipeda(rig, "PiernaIzq", Vector3(-0.34, 1.24, 0.0), dims_pierna, mat_acero, mat_acero_oscuro, mat_bronce, 8)
	_agregar_pierna_bipeda(rig, "PiernaDer", Vector3(0.34, 1.24, 0.0), dims_pierna, mat_acero, mat_acero_oscuro, mat_bronce, 8)

	# Torso Dreadnought ancho (base en y = 1.26)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.26, 0.0)
	rig.add_child(torso)

	var casco_torso := Kit.loft_perfil([
		{"y": -0.06, "rx": 0.44, "rz": 0.32, "bevel": 0.72},
		{"y": 0.20, "rx": 0.48, "rz": 0.34, "bevel": 0.74},
		{"y": 0.80, "rx": 0.68, "rz": 0.46, "bevel": 0.76},
		{"y": 1.30, "rx": 0.74, "rz": 0.48, "bevel": 0.74},
		{"y": 1.54, "rx": 0.54, "rz": 0.36, "bevel": 0.66},
	], mat_acero, 16)
	casco_torso.name = "CascoTorso"
	torso.add_child(casco_torso)

	var faja_bronce := Kit.prisma_biselado(Vector3(1.02, 0.20, 0.72), 0.03, mat_bronce, Vector3(0.0, 0.16, 0.0))
	faja_bronce.name = "FajaBronce"
	torso.add_child(faja_bronce)

	var bloque_sup := Kit.prisma_biselado(Vector3(1.24, 0.42, 0.76), 0.05, mat_bronce, Vector3(0.0, 1.44, -0.02), Vector3.ZERO, Vector2(0.88, 0.88))
	bloque_sup.name = "CaparazonSuperior"
	torso.add_child(bloque_sup)

	# Matriz cruciforme de 4 morteros cortos en el pecho
	var centro_cruz := Vector3(0.0, 0.82, 0.45)
	var cruceta_h := Kit.prisma_biselado(Vector3(0.76, 0.12, 0.12), 0.02, mat_bronce, centro_cruz - Vector3(0.0, 0.0, 0.04))
	cruceta_h.name = "CrucetaBronceH"
	torso.add_child(cruceta_h)

	var cruceta_v := Kit.prisma_biselado(Vector3(0.14, 0.76, 0.12), 0.02, mat_bronce, centro_cruz - Vector3(0.0, 0.0, 0.04))
	cruceta_v.name = "CrucetaBronceV"
	torso.add_child(cruceta_v)

	var morteros := [
		{"n": "MorteroSup", "pos": Vector3(0.0, 1.15, 0.46), "rot": Vector3(76.0, 0.0, 0.0)},
		{"n": "MorteroInf", "pos": Vector3(0.0, 0.49, 0.46), "rot": Vector3(104.0, 0.0, 0.0)},
		{"n": "MorteroIzq", "pos": Vector3(-0.34, 0.82, 0.46), "rot": Vector3(90.0, -14.0, 0.0)},
		{"n": "MorteroDer", "pos": Vector3(0.34, 0.82, 0.46), "rot": Vector3(90.0, 14.0, 0.0)},
	]
	for md in morteros:
		var m_piv := Node3D.new()
		m_piv.name = String(md["n"])
		m_piv.position = md["pos"] as Vector3
		m_piv.rotation_degrees = md["rot"] as Vector3
		torso.add_child(m_piv)

		var recamara := Kit.cyl(0.105, 0.11, 0.14, mat_bronce, Vector3(0.0, 0.02, 0.0))
		recamara.name = "Recamara"
		m_piv.add_child(recamara)

		var canon := Kit.cyl(0.082, 0.092, 0.28, mat_acero_oscuro, Vector3(0.0, 0.18, 0.0))
		canon.name = "CanoMortero"
		m_piv.add_child(canon)

		var bocacha := Kit.cyl(0.050, 0.050, 0.03, mat_ambar_45, Vector3(0.0, 0.305, 0.0))
		bocacha.name = "BocachaAmbar"
		m_piv.add_child(bocacha)

	# Halo dorsal angular de comandante pretoriano (diferencia silueta respecto al Coloso)
	var halo := Node3D.new()
	halo.name = "HaloGladiador"
	halo.position = Vector3(0.0, 1.56, -0.22)
	torso.add_child(halo)
	var arco_halo := Kit.arco_curvo(0.68, 0.08, -0.05, 0.05, -72.0, 72.0, mat_bronce, 14)
	arco_halo.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	halo.add_child(arco_halo)
	for lado in [-1.0, 1.0]:
		var punta := Kit.hoja_filo(0.42, 0.11, 0.04, lado * 0.05, mat_acero_oscuro, 6, Vector3(lado * 0.54, 0.04, 0.0), Vector3(-8.0, 0.0, lado * -36.0))
		punta.name = "AletaHalo" + ("Izq" if lado < 0.0 else "Der")
		halo.add_child(punta)

	# Hombreras masivas flanqueando cabeza erguida
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var homb := Kit.prisma_biselado(
			Vector3(0.46, 0.56, 0.62),
			0.055,
			mat_bronce,
			Vector3(lado * 0.72, 1.34, 0.0),
			Vector3(0.0, 0.0, lado * -12.0),
			Vector2(0.82, 0.86)
		)
		homb.name = "BastionHombro" + suf
		torso.add_child(homb)

	# Cabeza erguida con casco de rejilla, cimera gladiadora en abanico y penacho carmesí (~3.40m total)
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.44, 0.14)
	torso.add_child(cabeza)

	var cuello_g := Kit.cyl(0.18, 0.22, 0.18, mat_acero_oscuro, Vector3(0.0, 0.02, -0.02))
	cuello_g.name = "CuelloGladiador"
	cabeza.add_child(cuello_g)

	var casco_r := Kit.prisma_biselado(Vector3(0.42, 0.44, 0.44), 0.05, mat_acero_oscuro, Vector3(0.0, 0.22, 0.0), Vector3.ZERO, Vector2(0.88, 0.88))
	casco_r.name = "CascoRejilla"
	cabeza.add_child(casco_r)

	var base_cresta := Kit.prisma_biselado(Vector3(0.16, 0.09, 0.48), 0.02, mat_bronce, Vector3(0.0, 0.46, -0.02))
	base_cresta.name = "BaseCimera"
	cabeza.add_child(base_cresta)

	var penacho := Kit.prisma_biselado(Vector3(0.11, 0.24, 0.58), 0.025, mat_penacho, Vector3(0.0, 0.60, -0.06), Vector3(-6.0, 0.0, 0.0), Vector2(0.85, 1.15))
	penacho.name = "PenachoCarmesi"
	cabeza.add_child(penacho)

	for side_c in [-1.0, 1.0]:
		var cuerno := Kit.hoja_filo(0.32, 0.08, 0.04, side_c * -0.06, mat_bronce, 6, Vector3(side_c * 0.21, 0.36, 0.04), Vector3(12.0, 0.0, side_c * -28.0))
		cuerno.name = "CuernoYelmo" + ("Izq" if side_c < 0.0 else "Der")
		cabeza.add_child(cuerno)

	for i in range(3):
		var y_r := 0.15 + float(i) * 0.065
		var ranura := Kit.caja(Vector3(0.26, 0.022, 0.03), mat_ambar_52, Vector3(0.0, y_r, 0.215))
		ranura.name = "RanuraOptica" + str(i + 1)
		cabeza.add_child(ranura)

	for x_b in [-0.075, 0.0, 0.075]:
		var barrote := Kit.prisma_biselado(Vector3(0.026, 0.24, 0.04), 0.006, mat_acero, Vector3(x_b, 0.215, 0.235))
		barrote.name = "BarroteRejilla"
		cabeza.add_child(barrote)

	# Guanteletes-cañón hidráulicos pesados
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var brazo := Node3D.new()
		brazo.name = "Brazo" + suf
		brazo.position = Vector3(lado * 0.82, 1.16, 0.0)
		torso.add_child(brazo)

		var sup := Kit.cyl(0.16, 0.15, 0.46, mat_acero_oscuro, Vector3(0.0, -0.24, 0.0))
		sup.name = "BrazoSup" + suf
		brazo.add_child(sup)

		var guantelete := Node3D.new()
		guantelete.name = "GuanteleteCanon" + suf
		guantelete.position = Vector3(0.0, -0.66, 0.14)
		guantelete.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
		brazo.add_child(guantelete)

		var cuerpo_g := Kit.prisma_biselado(Vector3(0.34, 0.56, 0.48), 0.04, mat_acero, Vector3.ZERO)
		cuerpo_g.name = "BloqueCanon"
		guantelete.add_child(cuerpo_g)

		var franja_g := Kit.prisma_biselado(Vector3(0.36, 0.14, 0.34), 0.015, mat_hazard, Vector3(0.0, -0.10, 0.02))
		franja_g.name = "FranjaHazard" + suf
		guantelete.add_child(franja_g)

		for p_x in [-0.14, 0.14]:
			var camisa := Kit.cyl(0.046, 0.046, 0.32, mat_cobre, Vector3(p_x, 0.06, -0.12))
			camisa.name = "PistonCobre"
			guantelete.add_child(camisa)
			var vastago := Kit.cyl(0.024, 0.024, 0.22, mat_acero, Vector3(p_x, 0.24, -0.12))
			vastago.name = "VastagoPiston"
			guantelete.add_child(vastago)

		for b_x in [-0.075, 0.075]:
			var cano := Kit.cyl(0.056, 0.062, 0.26, mat_acero_oscuro, Vector3(b_x, -0.02, 0.30), Vector3(90.0, 0.0, 0.0))
			cano.name = "BocaCanon"
			guantelete.add_child(cano)

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig)
	return raiz


# ==============================================================================
# 5. COLOSO DE BRONCE (~4.85m, amp_paso = 22.0)
# ==============================================================================

static func coloso() -> Node3D:
	var raiz_dict := Kit.crear_raiz_enemigo("ColosoBronce")
	var raiz: Node3D = raiz_dict["raiz"]
	var rig: Node3D = raiz_dict["rig"]

	var tex_bronce := Kit.tex_bronce_oxidado(Color(0.52, 0.38, 0.20), 431)
	var tex_hierro := Kit.tex_acero_bunker(Color(0.14, 0.13, 0.13), 389)
	var tex_hazard := Kit.tex_hazard_desgastado(521)

	var mat_bronce := Kit.mat_pbr(Color.WHITE, 0.52, 0.48, tex_bronce)
	var mat_hierro := Kit.mat_pbr(Color.WHITE, 0.45, 0.58, tex_hierro)
	var mat_cobre := Kit.mat_pbr(Color(0.58, 0.34, 0.18), 0.54, 0.44)
	var mat_hazard := Kit.mat_pbr(Color.WHITE, 0.25, 0.62, tex_hazard)
	var mat_brasa_55 := Kit.mat_emissive(Color(0.32, 0.09, 0.02), Color(0.95, 0.32, 0.05), 0.55)
	var mat_brasa_52 := Kit.mat_emissive(Color(0.92, 0.42, 0.08), Color(0.98, 0.38, 0.06), 0.52)

	# Piernas columnas de pistón pesadas con zapatas remachadas en y = 0.0
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var pierna := Node3D.new()
		pierna.name = "Pierna" + suf
		pierna.position = Vector3(lado * 0.52, 1.78, 0.0)
		rig.add_child(pierna)

		var cadera := Kit.esfera(0.26, mat_hierro, Vector3(0.0, -0.04, 0.0))
		cadera.name = "ArticulacionCadera"
		pierna.add_child(cadera)

		var muslo := Kit.prisma_biselado(Vector3(0.50, 0.78, 0.52), 0.06, mat_bronce, Vector3(0.0, -0.44, 0.0), Vector3.ZERO, Vector2(1.06, 1.06))
		muslo.name = "MusloFundicion"
		pierna.add_child(muslo)

		var rodilla := Kit.prisma_biselado(Vector3(0.44, 0.34, 0.32), 0.05, mat_bronce, Vector3(0.0, -0.86, 0.20), Vector3(6.0, 0.0, 0.0), Vector2(0.86, 0.86), 6)
		rodilla.name = "Rodillera"
		pierna.add_child(rodilla)

		var columna := Kit.cyl(0.22, 0.25, 0.76, mat_hierro, Vector3(0.0, -1.24, 0.0))
		columna.name = "ColumnaPiston"
		pierna.add_child(columna)

		for p_x in [-0.22, 0.22]:
			var camisa_p := Kit.cyl(0.075, 0.075, 0.48, mat_bronce, Vector3(p_x, -1.32, -0.06))
			camisa_p.name = "CamisaPiston"
			pierna.add_child(camisa_p)
			var vastago_p := Kit.cyl(0.042, 0.042, 0.36, mat_hierro, Vector3(p_x, -1.04, -0.06))
			vastago_p.name = "VastagoPiston"
			pierna.add_child(vastago_p)

		var zapata := Kit.prisma_biselado(Vector3(0.62, 0.28, 0.78), 0.045, mat_hierro, Vector3(0.0, -1.64, 0.10), Vector3.ZERO, Vector2(0.84, 0.86))
		zapata.name = "ZapataRemachada"
		pierna.add_child(zapata)

		var puntera := Kit.prisma_biselado(Vector3(0.54, 0.20, 0.26), 0.03, mat_bronce, Vector3(0.0, -1.68, 0.38))
		puntera.name = "PunteraBronce"
		pierna.add_child(puntera)

	# Torso titánico de fundición (base en y = 1.80)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.80, 0.0)
	rig.add_child(torso)

	var bloque_torso := Kit.loft_perfil([
		{"y": -0.10, "rx": 0.64, "rz": 0.44, "bevel": 0.74},
		{"y": 0.24, "rx": 0.68, "rz": 0.46, "bevel": 0.76},
		{"y": 1.06, "rx": 1.02, "rz": 0.68, "bevel": 0.78},
		{"y": 1.72, "rx": 1.08, "rz": 0.66, "bevel": 0.76},
		{"y": 2.02, "rx": 0.78, "rz": 0.50, "bevel": 0.68},
	], mat_hierro, 16)
	bloque_torso.name = "NucleoFundicion"
	torso.add_child(bloque_torso)

	var cinturon := Kit.prisma_biselado(Vector3(1.42, 0.26, 0.98), 0.04, mat_bronce, Vector3(0.0, 0.22, 0.0))
	cinturon.name = "CinturonFundicion"
	torso.add_child(cinturon)

	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var plancha_p := Kit.prisma_biselado(
			Vector3(0.56, 1.12, 0.24),
			0.05,
			mat_bronce,
			Vector3(lado * 0.58, 1.16, 0.50),
			Vector3(-4.0, lado * 14.0, 0.0)
		)
		plancha_p.name = "PlanchaBronce" + suf
		torso.add_child(plancha_p)

	var lamina_dorsal := Kit.prisma_biselado(Vector3(1.36, 1.24, 0.36), 0.06, mat_bronce, Vector3(0.0, 1.20, -0.54))
	lamina_dorsal.name = "PlanchaDorsal"
	torso.add_child(lamina_dorsal)

	# Horno pectoral enrejado sobre núcleo brasa hundido
	var horno := Node3D.new()
	horno.name = "HornoPectoral"
	horno.position = Vector3(0.0, 1.06, 0.64)
	torso.add_child(horno)

	var marco_h_sup := Kit.prisma_biselado(Vector3(0.68, 0.12, 0.16), 0.02, mat_hierro, Vector3(0.0, 0.32, 0.0))
	marco_h_sup.name = "MarcoHornoSup"
	horno.add_child(marco_h_sup)

	var marco_h_inf := Kit.prisma_biselado(Vector3(0.68, 0.12, 0.16), 0.02, mat_hierro, Vector3(0.0, -0.32, 0.0))
	marco_h_inf.name = "MarcoHornoInf"
	horno.add_child(marco_h_inf)

	for lado in [-1.0, 1.0]:
		var marco_v := Kit.prisma_biselado(Vector3(0.12, 0.72, 0.16), 0.02, mat_hierro, Vector3(lado * 0.30, 0.0, 0.0))
		marco_v.name = "MarcoHornoLat" + ("Izq" if lado < 0.0 else "Der")
		horno.add_child(marco_v)

	var nucleo_brasa := Kit.prisma_biselado(Vector3(0.48, 0.50, 0.08), 0.02, mat_brasa_55, Vector3(0.0, 0.0, -0.02))
	nucleo_brasa.name = "NucleoBrasa"
	horno.add_child(nucleo_brasa)

	for i in range(4):
		var x_bar := -0.15 + float(i) * 0.10
		var bar_v := Kit.prisma_biselado(Vector3(0.036, 0.56, 0.05), 0.008, mat_hierro, Vector3(x_bar, 0.0, 0.045))
		bar_v.name = "BarroteVertical" + str(i + 1)
		horno.add_child(bar_v)

	for i in range(3):
		var y_bar := -0.14 + float(i) * 0.14
		var bar_h := Kit.prisma_biselado(Vector3(0.54, 0.036, 0.05), 0.008, mat_hierro, Vector3(0.0, y_bar, 0.055))
		bar_h.name = "BarroteHorizontal" + str(i + 1)
		horno.add_child(bar_h)

	# Chimeneas gemelas de fundición biseladas con aros de cobre (tope exacto en 4.85m)
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var chim := Node3D.new()
		chim.name = "Chimenea" + suf
		chim.position = Vector3(lado * 0.64, 2.367, -0.34)
		chim.rotation_degrees = Vector3(-5.0, 0.0, lado * 4.0)
		torso.add_child(chim)

		var cuerpo_chim := Kit.prisma_biselado(Vector3(0.34, 1.34, 0.36), 0.05, mat_hierro, Vector3.ZERO, Vector3.ZERO, Vector2(0.78, 0.78))
		cuerpo_chim.name = "CuerpoChimenea" + suf
		chim.add_child(cuerpo_chim)

		for j in range(3):
			var y_aro := -0.25 + float(j) * 0.36
			var esc_r := 1.0 - float(j) * 0.08
			var aro := Kit.toro(0.22 * esc_r, 0.175 * esc_r, mat_cobre, Vector3(0.0, y_aro, 0.0), Vector3.ZERO, Vector3(1.0, 1.0, 1.04))
			aro.name = "AroCobre" + suf + str(j + 1)
			chim.add_child(aro)

	# Cabeza monolítica encastrada con ranura óptica estrecha
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0.0, 1.72, 0.24)
	torso.add_child(cabeza)

	var monolito := Kit.prisma_biselado(Vector3(0.56, 0.54, 0.52), 0.06, mat_hierro, Vector3(0.0, 0.16, 0.0), Vector3.ZERO, Vector2(0.86, 0.88))
	monolito.name = "CascoMonolito"
	cabeza.add_child(monolito)

	var visera_m := Kit.prisma_biselado(Vector3(0.50, 0.14, 0.22), 0.03, mat_bronce, Vector3(0.0, 0.29, 0.18), Vector3(8.0, 0.0, 0.0))
	visera_m.name = "ViseraBronce"
	cabeza.add_child(visera_m)

	var ranura_c := Kit.caja(Vector3(0.32, 0.032, 0.03), mat_brasa_52, Vector3(0.0, 0.16, 0.26))
	ranura_c.name = "RanuraOptica"
	cabeza.add_child(ranura_c)

	# Enormes brazos martinete hidráulicos con cilindros de pistón y bandas hazard
	for lado in [-1.0, 1.0]:
		var suf := "Izq" if lado < 0.0 else "Der"
		var brazo := Node3D.new()
		brazo.name = "Brazo" + suf
		brazo.position = Vector3(lado * 1.24, 1.66, 0.0)
		torso.add_child(brazo)

		brazo.add_child(_crear_hombrera_montada("HombreraColoso" + suf, 0.42, 0.10, 0.74, 130.0, mat_bronce, Vector3(lado * -0.06, 0.12, 0.0), lado < 0.0, 20.0))

		var sup := Kit.cyl(0.24, 0.22, 0.72, mat_hierro, Vector3(0.0, -0.38, 0.0))
		sup.name = "BrazoSup" + suf
		brazo.add_child(sup)

		var codo := Kit.esfera(0.24, mat_bronce, Vector3(0.0, -0.74, 0.0))
		codo.name = "Codo" + suf
		brazo.add_child(codo)

		var martinete := Node3D.new()
		martinete.name = "Martinete" + suf
		martinete.position = Vector3(0.0, -1.08, 0.08)
		martinete.rotation_degrees = Vector3(-6.0, 0.0, 0.0)
		brazo.add_child(martinete)

		var bloque_m := Kit.prisma_biselado(Vector3(0.46, 0.92, 0.48), 0.055, mat_bronce, Vector3.ZERO, Vector3.ZERO, Vector2(0.88, 0.88))
		bloque_m.name = "BloqueMartinete" + suf
		martinete.add_child(bloque_m)

		var banda_h := Kit.prisma_biselado(Vector3(0.48, 0.20, 0.50), 0.02, mat_hazard, Vector3(0.0, -0.22, 0.0))
		banda_h.name = "BandaHazard" + suf
		martinete.add_child(banda_h)

		var yunque := Kit.prisma_biselado(Vector3(0.40, 0.16, 0.42), 0.03, mat_hierro, Vector3(0.0, -0.44, 0.02))
		yunque.name = "YunquePuno" + suf
		martinete.add_child(yunque)

		for p_x in [-0.24, 0.24]:
			var camisa_b := Kit.cyl(0.075, 0.075, 0.52, mat_cobre, Vector3(p_x, 0.06, -0.08))
			camisa_b.name = "PistonMartinete"
			martinete.add_child(camisa_b)
			var vastago_b := Kit.cyl(0.042, 0.042, 0.42, mat_hierro, Vector3(p_x, 0.36, -0.08))
			vastago_b.name = "VastagoMartinete"
			martinete.add_child(vastago_b)

	Kit.normalizar_base_suelo(rig)
	Kit.agregar_animaciones_bipedo(raiz, rig, 22.0)
	return raiz


# ==============================================================================
# REGISTRO COMPLETO DE LA FACCIÓN
# ==============================================================================

static func construir_todos() -> Dictionary:
	return {
		"guardia": {
			"nodo": guardia(),
			"ruta": "res://assets/modelos/enemigo_guardia_pretoriano.glb",
		},
		"arquero": {
			"nodo": arquero(),
			"ruta": "res://assets/modelos/enemigo_arquero_balistico.glb",
		},
		"centurion": {
			"nodo": centurion(),
			"ruta": "res://assets/modelos/enemigo_centurion_corrupto.glb",
		},
		"mini_jefe": {
			"nodo": mini_jefe(),
			"ruta": "res://assets/modelos/jefe_heraldo_arena.glb",
		},
		"coloso": {
			"nodo": coloso(),
			"ruta": "res://assets/modelos/jefe_coloso_bronce.glb",
		},
	}
