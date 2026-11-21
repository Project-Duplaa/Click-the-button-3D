@tool
extends SceneTree

const AnimacionesHeroeKit = preload("res://herramientas/animaciones_heroe_kit.gd")

## ==============================================================================
## GENERADOR MAESTRO DE MODELOS 3D ESTILIZADOS PARA GODOT 4 (CLICKLIKE 3D)
## Reconstruye desde cero con geometría esculpida (SurfaceTool), ejes anatómicos
## exactos del rig Kenney (±X en brazos), texturas PBR embebidas (albedo/normal/
## emisión) y cero OmniLight3D internas:
##   1. Novato:   res://personaje/player_rookie.glb   (0.605m)
##   2. Guerrero: res://personaje/player_warrior.glb  (0.635m)
##   3. Arquero:  res://personaje/player_archer.glb   (0.615m)
##   4. Mago:     res://personaje/player_mage.glb     (0.625m)
## ==============================================================================


func _initialize() -> void:
	print("==================================================================")
	print("RECONSTRUYENDO 4 HÉROES 3D ESTILIZADOS CON TEXTURAS PBR Y LOFTS")
	print("==================================================================")

	var base_male_a := "res://personaje/character-male-a.glb"
	var base_male_d := "res://personaje/character-male-d.glb"

	if not FileAccess.file_exists(base_male_a) or not FileAccess.file_exists(base_male_d):
		printerr("ERROR: No se encontraron character-male-a.glb o character-male-d.glb en res://personaje/")
		quit(1)
		return

	_generar_novato(base_male_a, "res://personaje/player_rookie.glb")
	_generar_guerrero(base_male_d, "res://personaje/player_warrior.glb")
	_generar_arquero(base_male_a, "res://personaje/player_archer.glb")
	_generar_mago(base_male_a, "res://personaje/player_mage.glb")

	print("==================================================================")
	print("EXITO: Los 4 modelos .glb heroicos fueron exportados limpiamente.")
	print("==================================================================")
	quit(0)


# ==============================================================================
# HELPERS DETERMINISTAS DE RUIDO, TEXTURAS PROCEDURALES Y MATERIALES PBR
# ==============================================================================

static func _hash2(x: int, y: int, seed_val: int = 1337) -> float:
	var n: int = (x * 374761393 + y * 668265263 + seed_val * 1442695041) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


static func _suave_ruido(u: float, v: float, freq: float, seed_val: int = 1337) -> float:
	var gx: float = u * freq
	var gy: float = v * freq
	var ix: int = int(floor(gx))
	var iy: int = int(floor(gy))
	var fx: float = gx - float(ix)
	var fy: float = gy - float(iy)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a: float = _hash2(ix, iy, seed_val)
	var b: float = _hash2(ix + 1, iy, seed_val)
	var c: float = _hash2(ix, iy + 1, seed_val)
	var d: float = _hash2(ix + 1, iy + 1, seed_val)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func _dist_segmento(px: float, py: float, ax: float, ay: float, bx: float, by: float) -> float:
	var abx: float = bx - ax
	var aby: float = by - ay
	var len_sq: float = abx * abx + aby * aby
	if len_sq < 0.000001:
		return Vector2(px - ax, py - ay).length()
	var t: float = clampf(((px - ax) * abx + (py - ay) * aby) / len_sq, 0.0, 1.0)
	return Vector2(px - (ax + abx * t), py - (ay + aby * t)).length()


static func _finalizar_textura(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _tex_rostro_operador() -> ImageTexture:
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_piel_centro := Color(0.76, 0.56, 0.43)
	var c_piel_borde := Color(0.56, 0.39, 0.30)
	var c_sombra_ojo := Color(0.42, 0.28, 0.22)
	var c_barba := Color(0.32, 0.24, 0.20)
	var c_contorno := Color(0.10, 0.09, 0.09)
	var c_esclera := Color(0.84, 0.85, 0.87)
	var c_iris := Color(0.18, 0.25, 0.32)
	var c_pupila := Color(0.06, 0.07, 0.09)
	var c_ceja := Color(0.24, 0.18, 0.13)
	var c_boca := Color(0.28, 0.15, 0.14)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var df := clampf(Vector2((u - 0.5) * 1.45, (v - 0.52) * 1.25).length(), 0.0, 1.0)
			var col := c_piel_centro.lerp(c_piel_borde, df * 0.78)

			# Sombra marcada bajo el arco superciliar y pómulos
			if v > 0.40 and v < 0.56 and absf(u - 0.5) < 0.22:
				var sb := (1.0 - absf(v - 0.48) / 0.08) * (1.0 - absf(u - 0.5) / 0.22)
				col = col.lerp(c_sombra_ojo, clampf(sb * 0.42, 0.0, 0.42))

			# Sombra de barba incipiente en mandíbula/mentón
			if v > 0.62 and absf(u - 0.5) < 0.20:
				var grano := _hash2(x, y, 77)
				var bf := clampf((v - 0.62) / 0.26, 0.0, 1.0) * (1.0 - absf(u - 0.5) / 0.20)
				col = col.lerp(c_barba, bf * (0.28 + 0.14 * grano))

			# Cicatriz táctica sutil en pómulo izquierdo
			var d_cic := _dist_segmento(u, v, 0.60, 0.53, 0.64, 0.61)
			if d_cic < 0.0055:
				col = col.lerp(Color(0.55, 0.34, 0.28), (1.0 - d_cic / 0.0055) * 0.65)

			# Sombra bajo la nariz
			var dn := Vector2((u - 0.5) * 28.0, (v - 0.60) * 32.0).length()
			if dn < 1.0:
				col = col.lerp(c_sombra_ojo, (1.0 - dn) * 0.38)

			# Ojos estrechos concentrados y serios
			for side: float in [-1.0, 1.0]:
				var ex: float = 0.5 + side * 0.068
				var ey: float = 0.498
				var de := Vector2((u - ex) / 0.032, (v - ey) / 0.017).length()
				if de < 1.15:
					if v < ey - 0.007 and de < 1.05:
						col = col.lerp(c_contorno, clampf((1.05 - de) * 5.0, 0.0, 1.0))
					elif de <= 1.0:
						var ojo_col := c_esclera
						if v < ey - 0.003:
							ojo_col = c_sombra_ojo.lerp(c_esclera, 0.45)
						var di := Vector2((u - ex) / 0.016, (v - ey) / 0.016).length()
						if di < 1.0:
							ojo_col = c_iris if di > 0.54 else c_pupila
						var dc := Vector2((u - (ex - 0.005)) / 0.004, (v - (ey - 0.004)) / 0.004).length()
						if dc < 1.0:
							ojo_col = Color(0.85, 0.88, 0.90)
						col = c_contorno.lerp(ojo_col, clampf((1.0 - de) * 8.0, 0.0, 1.0))

				# Cejas rectas y tensas inclinadas al entrecejo
				var c0x: float = ex - side * 0.038
				var c0y: float = 0.464 + (0.008 if side < 0.0 else -0.002)
				var c1x: float = ex + side * 0.038
				var c1y: float = 0.464 + (0.008 if side > 0.0 else -0.002)
				var d_ceja := _dist_segmento(u, v, c0x, c0y, c1x, c1y)
				if d_ceja < 0.013:
					col = col.lerp(c_ceja, clampf((0.013 - d_ceja) / 0.005, 0.0, 1.0))

			# Boca recta seria / determinada
			var d_boca := _dist_segmento(u, v, 0.455, 0.708, 0.545, 0.704)
			if d_boca < 0.0065:
				col = col.lerp(c_boca, clampf((0.0065 - d_boca) / 0.003, 0.0, 1.0))

			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _tex_rostro_ojos_visor(color_ceja: Color) -> ImageTexture:
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_base := Color(0.75, 0.55, 0.42)
	var c_sombra := Color(0.54, 0.37, 0.28)
	var c_esclera := Color(0.84, 0.86, 0.88)
	var c_parpado := Color(0.45, 0.30, 0.23)
	var c_pupila := Color(0.06, 0.09, 0.14)
	var c_iris := Color(0.20, 0.44, 0.62)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var df := clampf(Vector2((u - 0.5) * 1.4, (v - 0.5) * 1.2).length(), 0.0, 1.0)
			var col := c_base.lerp(c_sombra, df * 0.65)
			for side: float in [-1.0, 1.0]:
				var ex: float = 0.5 + side * 0.068
				var ey: float = 0.502
				var de := Vector2((u - ex) / 0.032, (v - ey) / 0.017).length()
				if de < 1.08:
					if v < ey - 0.006 and de < 1.02:
						col = col.lerp(Color(0.12, 0.10, 0.10), clampf((1.02 - de) * 5.0, 0.0, 1.0))
					elif de <= 1.02:
						var eye_col := c_parpado.lerp(c_esclera, clampf((v - (ey - 0.007)) * 75.0, 0.0, 1.0))
						var di := Vector2((u - ex) / 0.017, (v - ey) / 0.016).length()
						if di < 1.0:
							eye_col = eye_col.lerp(c_iris if di > 0.50 else c_pupila, clampf((1.0 - di) * 6.0, 0.0, 1.0))
						var edge := clampf((1.02 - de) * 7.0, 0.0, 1.0)
						col = col.lerp(c_sombra.lerp(eye_col, clampf((0.86 - de) * 7.0, 0.0, 1.0)), edge)
				var dcj := _dist_segmento(u, v, ex - 0.034, 0.464 - side * 0.005, ex + 0.034, 0.464 + side * 0.005)
				if dcj < 0.012:
					col = col.lerp(color_ceja, clampf((0.012 - dcj) / 0.005, 0.0, 1.0))
			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _tex_chaleco_novato() -> ImageTexture:
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_chaqueta := Color(0.15, 0.19, 0.24)
	var c_camiseta := Color(0.32, 0.35, 0.38)
	var c_chaleco := Color(0.22, 0.25, 0.29)
	var c_placa := Color(0.16, 0.18, 0.21)
	var c_ambar := Color(0.62, 0.47, 0.14)
	var c_costura := Color(0.10, 0.11, 0.13)
	var c_tierra := Color(0.28, 0.24, 0.19)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := (_suido_wrap(u, v, 14.0, 101) - 0.5) * 0.05
			var col := c_chaleco
			var dist_centro := absf(u - 0.5)

			# Escote táctico y cremallera central sobria
			var ancho_cuello := 0.080 if v < 0.25 else 0.056
			if dist_centro < ancho_cuello:
				col = c_camiseta if (v < 0.18 and dist_centro < (0.18 - v) * 0.30) else c_chaqueta
				if absf(dist_centro - ancho_cuello) < 0.009:
					col = c_costura
				if v >= 0.18 and dist_centro < 0.008:
					col = Color(0.38, 0.41, 0.45) if ((y / 4) % 2 == 0) else c_costura
			else:
				# Panel balístico oscuro + bandas industriales ocre-ámbar apagado
				if v > 0.22 and v < 0.72 and dist_centro > 0.075 and dist_centro < 0.34:
					col = c_placa
				var en_h1 := absf(v - 0.36) < 0.032
				var en_h2 := absf(v - 0.68) < 0.032
				var en_vert := (dist_centro > 0.115 and dist_centro < 0.155 and v < 0.68)
				if en_h1 or en_h2 or en_vert:
					col = c_ambar
					if absf(absf(v - 0.36) - 0.032) < 0.007 or absf(absf(v - 0.68) - 0.032) < 0.007:
						col = c_costura

			if v > 0.72:
				var suc := clampf((v - 0.72) / 0.25 * _suave_ruido(u, v, 9.0, 202), 0.0, 0.40)
				col = col.lerp(c_tierra, suc)

			col = Color(clampf(col.r + n, 0.0, 1.0), clampf(col.g + n, 0.0, 1.0), clampf(col.b + n, 0.0, 1.0))
			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _suido_wrap(u: float, v: float, freq: float, seed_val: int) -> float:
	return _suave_ruido(u, v, freq, seed_val) * 0.65 + _suave_ruido(u, v, freq * 2.3, seed_val + 17) * 0.35


static func _tex_acero_desgastado() -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_acero := Color(0.36, 0.40, 0.46)
	var c_hollin := Color(0.20, 0.22, 0.26)
	var c_oxido := Color(0.42, 0.26, 0.18)
	var c_bisel := Color(0.68, 0.73, 0.78)

	var remaches := [
		Vector2(0.12, 0.12), Vector2(0.88, 0.12),
		Vector2(0.12, 0.88), Vector2(0.88, 0.88),
		Vector2(0.12, 0.50), Vector2(0.88, 0.50),
		Vector2(0.50, 0.12), Vector2(0.50, 0.88),
	]

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var ruido := _suido_wrap(u, v, 10.0, 303)
			var col := c_acero.lerp(c_hollin, clampf((ruido - 0.35) * 1.4, 0.0, 0.75))
			var hv := 0.50 + (ruido - 0.5) * 0.10

			# Marco biselado y desgaste de borde + óxido
			var borde := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
			if borde < 0.065:
				col = col.lerp(c_oxido, 0.45 * _suave_ruido(u, v, 16.0, 311))
				if borde < 0.025:
					col = col.lerp(c_bisel, 0.55)
					hv = 0.62
				elif absf(borde - 0.060) < 0.008:
					col = c_hollin
					hv = 0.25

			# Rasguños diagonales metálicos
			for r_idx in range(4):
				var ax := 0.18 + float(r_idx) * 0.18
				var ay := 0.22 + float(r_idx % 2) * 0.34
				if _dist_segmento(u, v, ax, ay, ax + 0.16, ay + 0.11) < 0.005:
					col = c_bisel
					hv = 0.22

			# 8 Remaches metálicos con relieve real en normal map
			for rem in remaches:
				var dr := Vector2(u - rem.x, v - rem.y).length()
				if dr < 0.028:
					if dr > 0.021:
						col = c_hollin
						hv = 0.22
					else:
						col = c_bisel if (v < rem.y) else c_acero
						hv = 0.92 - dr * 8.0

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(2.2)
	return {
		"albedo": _finalizar_textura(img_a),
		"normal": _finalizar_textura(img_h),
	}


static func _tex_hazard_escudo() -> ImageTexture:
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_amarillo := Color(0.76, 0.58, 0.10)
	var c_negro := Color(0.11, 0.12, 0.14)
	var c_rasguno := Color(0.58, 0.63, 0.68)
	var c_polvo := Color(0.28, 0.24, 0.19)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var stripe: int = int(floor(float(x + y * 2) / 28.0)) % 2
			var col := c_amarillo if stripe == 0 else c_negro
			if v < 0.08 or v > 0.92:
				col = col.lerp(c_polvo, 0.55)
			if _dist_segmento(u, v, 0.18, 0.20, 0.34, 0.68) < 0.011 or _dist_segmento(u, v, 0.64, 0.30, 0.80, 0.76) < 0.010:
				col = c_rasguno
			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _tex_traje_ceramico_tactico() -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_base := Color(0.64, 0.67, 0.71)
	var c_panel := Color(0.24, 0.27, 0.31)
	var c_pliegue := Color(0.45, 0.49, 0.54)
	var c_costura := Color(0.16, 0.18, 0.21)
	var c_arena := Color(0.38, 0.34, 0.29)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var onda := 0.5 + 0.5 * sin(u * 18.0 + sin(v * 10.0) * 1.6)
			var n := _suido_wrap(u, v, 12.0, 404)
			var col := c_base.lerp(c_pliegue, onda * 0.34 + n * 0.18)
			var hv := 0.52 + (onda - 0.5) * 0.16

			if (u < 0.14 or u > 0.86) or (v > 0.48 and v < 0.56):
				col = col.lerp(c_panel, 0.75)
				hv = 0.42
			if absf(u - 0.5) < 0.008 or absf(u - 0.25) < 0.007 or absf(u - 0.75) < 0.007 or absf(v - 0.45) < 0.008:
				col = c_costura
				hv = 0.26
			if v > 0.76:
				col = col.lerp(c_arena, clampf((v - 0.76) * 2.4 * n, 0.0, 0.45))

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(1.5)
	return {
		"albedo": _finalizar_textura(img_a),
		"normal": _finalizar_textura(img_h),
	}


static func _tex_gabardina_mago() -> ImageTexture:
	var w := 256
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_tela := Color(0.14, 0.17, 0.21)
	var c_sombra := Color(0.08, 0.10, 0.13)
	var c_costura := Color(0.32, 0.36, 0.41)
	var c_ceniza := Color(0.22, 0.19, 0.17)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _suido_wrap(u, v, 11.0, 505)
			var col := c_tela.lerp(c_sombra, clampf(n * 0.75, 0.0, 1.0))

			if u < 0.035 or u > 0.965:
				col = c_costura
			if v > 0.74:
				col = col.lerp(c_ceniza, clampf((v - 0.74) * 2.6 * n, 0.0, 0.52))

			# Borde inferior desgarrado real mediante alpha_scissor
			var corte := 0.87 + 0.10 * absf(sin(u * PI * 7.0 + 0.4)) + 0.03 * _hash2(x / 8, 9, 512)
			var alpha := 0.0 if v > corte else 1.0
			col.a = alpha
			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _tex_vial_liquido(color_liq: Color) -> Dictionary:
	var w := 64
	var h := 128
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_e := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_tapon := Color(0.28, 0.31, 0.34)
	var c_vidrio := Color(0.62, 0.80, 0.86)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var col := Color.BLACK
			var em := Color.BLACK
			if v < 0.16 or v > 0.91:
				col = c_tapon
			elif v < 0.27:
				col = c_vidrio
				if absf(u - 0.32) < 0.06:
					col = Color.WHITE
			else:
				col = color_liq
				em = color_liq
				var d_burb := Vector2((u - 0.55) * 4.0, (v - 0.56) * 8.0).length()
				if d_burb < 0.42 or absf(u - 0.28) < 0.055:
					col = color_liq.lightened(0.45)
			img_a.set_pixel(x, y, col)
			img_e.set_pixel(x, y, em)

	return {
		"albedo": _finalizar_textura(img_a),
		"emission": _finalizar_textura(img_e),
	}


static func _tex_pelo_gradiente(c_raiz: Color, c_punta: Color) -> ImageTexture:
	var w := 128
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var estria := 0.5 + 0.5 * sin(u * 36.0)
			var t := clampf((v - 0.12) / 0.72, 0.0, 1.0)
			var col := c_raiz.lerp(c_punta, t)
			col = col.lerp(c_punta.lightened(0.12), estria * 0.16 * (0.4 + 0.6 * t))
			img.set_pixel(x, y, col)
	return _finalizar_textura(img)


static func _mat(
	albedo: Color,
	metallic: float = 0.0,
	roughness: float = 0.6,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0,
	res_name: String = ""
) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		# Regla estricta anti-quemado Bloom en gl_compatibility
		m.emission_energy_multiplier = minf(emission_energy, 0.95)
	if res_name != "":
		m.resource_name = res_name
	return m


# ==============================================================================
# CONSTRUCTORES GEOMÉTRICOS ESCULPIDOS (SurfaceTool / ArrayMesh BISELADOS)
# ==============================================================================

static func _eval_superelipse(ang: float, rx: float, rz: float, bevel: float) -> Vector2:
	var sx := sin(ang)
	var cz := cos(ang)
	var p := lerpf(1.0, 0.36, clampf(bevel, 0.0, 1.0))
	var px: float = (1.0 if sx >= 0.0 else -1.0) * pow(absf(sx), p) * rx
	var pz: float = (1.0 if cz >= 0.0 else -1.0) * pow(absf(cz), p) * rz
	return Vector2(px, pz)


static func _agregar_quad_cw(st: SurfaceTool, v00: Vector3, v10: Vector3, v01: Vector3, v11: Vector3, uv00: Vector2, uv10: Vector2, uv01: Vector2, uv11: Vector2) -> void:
	# Winding verificado en Godot 4: (0,0,1)->(0,1,1)->(+dx,0,1) apunta normal hacia +Z.
	st.set_uv(uv00)
	st.add_vertex(v00)
	st.set_uv(uv10)
	st.add_vertex(v10)
	st.set_uv(uv01)
	st.add_vertex(v01)

	st.set_uv(uv01)
	st.add_vertex(v01)
	st.set_uv(uv10)
	st.add_vertex(v10)
	st.set_uv(uv11)
	st.add_vertex(v11)


static func _loft_perfil(secciones: Array, mat: Material, segs: int = 18, cerrar_tapas: bool = true) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var num_sec := secciones.size()
	var rings: Array = []
	for s_idx in range(num_sec):
		var s: Dictionary = secciones[s_idx]
		var y: float = float(s.get("y", 0.0))
		var rx: float = maxf(0.0005, float(s.get("rx", 0.05)))
		var rz: float = maxf(0.0005, float(s.get("rz", 0.05)))
		var x_off: float = float(s.get("x_off", 0.0))
		var z_off: float = float(s.get("z_off", 0.0))
		var bevel: float = float(s.get("bevel", 0.0))
		var ring: Array[Vector3] = []
		for j in range(segs + 1):
			var u: float = float(j) / float(segs)
			# u = 0.5 al frente (+Z), costura u = 0/1 en espalda (-Z)
			var ang: float = (u * TAU) - PI
			var pt := _eval_superelipse(ang, rx, rz, bevel)
			ring.append(Vector3(x_off + pt.x, y, z_off + pt.y))
		rings.append(ring)

	for i in range(num_sec - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var v0: float = 1.0 - float(i) / float(num_sec - 1)
		var v1: float = 1.0 - float(i + 1) / float(num_sec - 1)
		for j in range(segs):
			var u0: float = float(j) / float(segs)
			var u1: float = float(j + 1) / float(segs)
			_agregar_quad_cw(st, r0[j], r1[j], r0[j + 1], r1[j + 1], Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v0), Vector2(u1, v1))

	if cerrar_tapas and num_sec >= 2:
		var s_bot: Dictionary = secciones[0]
		var r_bot: Array = rings[0]
		var c_bot := Vector3(float(s_bot.get("x_off", 0.0)), float(s_bot.get("y", 0.0)), float(s_bot.get("z_off", 0.0)))
		for j in range(segs):
			st.set_uv(Vector2(0.5, 1.0))
			st.add_vertex(c_bot)
			st.set_uv(Vector2(float(j + 1) / float(segs), 1.0))
			st.add_vertex(r_bot[j + 1])
			st.set_uv(Vector2(float(j) / float(segs), 1.0))
			st.add_vertex(r_bot[j])

		var s_top: Dictionary = secciones[num_sec - 1]
		var r_top: Array = rings[num_sec - 1]
		var c_top := Vector3(float(s_top.get("x_off", 0.0)), float(s_top.get("y", 0.0)), float(s_top.get("z_off", 0.0)))
		for j in range(segs):
			st.set_uv(Vector2(0.5, 0.0))
			st.add_vertex(c_top)
			st.set_uv(Vector2(float(j) / float(segs), 0.0))
			st.add_vertex(r_top[j])
			st.set_uv(Vector2(float(j + 1) / float(segs), 0.0))
			st.add_vertex(r_top[j + 1])

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _loft_perfil_x(secciones: Array, mat: Material, segs: int = 16, cerrar_tapas: bool = true) -> MeshInstance3D:
	# Construye el loft sobre +Y y rota a lo largo de +X para alinear directamente con arm-left / arm-right.
	var mi := _loft_perfil(secciones, mat, segs, cerrar_tapas)
	mi.rotation_degrees = Vector3(0.0, 0.0, -90.0)
	return mi


static func _st_prisma_biselado(size: Vector3, bevel_xy: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, taper_top: Vector2 = Vector2.ONE, segs: int = 16) -> MeshInstance3D:
	var rx := size.x * 0.5
	var ry := size.y * 0.5
	var rz := size.z * 0.5
	var bev_y := minf(bevel_xy, ry * 0.35)
	var shrink := clampf(1.0 - bevel_xy / maxf(minf(rx, rz), 0.001) * 0.38, 0.65, 0.94)
	var secs := [
		{"y": -ry, "rx": rx * shrink, "rz": rz * shrink, "bevel": 0.65},
		{"y": -ry + bev_y, "rx": rx, "rz": rz, "bevel": 0.72},
		{"y": ry - bev_y, "rx": rx * taper_top.x, "rz": rz * taper_top.y, "bevel": 0.72},
		{"y": ry, "rx": rx * taper_top.x * shrink, "rz": rz * taper_top.y * shrink, "bevel": 0.65},
	]
	var mi := _loft_perfil(secs, mat, segs, true)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func _st_arco_curvo(r_medio: float, espesor: float, y_bot: float, y_top: float, ang_ini_deg: float, ang_fin_deg: float, mat: Material, segs: int = 14) -> MeshInstance3D:
	# Arco volumétrico cerrado centrado en ángulo 0 = +Z, ángulo +90 = +X.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var a0 := deg_to_rad(ang_ini_deg)
	var a1 := deg_to_rad(ang_fin_deg)
	var ri := maxf(0.002, r_medio - espesor * 0.5)
	var ro := r_medio + espesor * 0.5

	var pts_out_b: Array[Vector3] = []
	var pts_out_t: Array[Vector3] = []
	var pts_in_b: Array[Vector3] = []
	var pts_in_t: Array[Vector3] = []

	for j in range(segs + 1):
		var u := float(j) / float(segs)
		var a := lerpf(a0, a1, u)
		var sx := sin(a)
		var cz := cos(a)
		pts_out_b.append(Vector3(sx * ro, y_bot, cz * ro))
		pts_out_t.append(Vector3(sx * ro, y_top, cz * ro))
		pts_in_b.append(Vector3(sx * ri, y_bot, cz * ri))
		pts_in_t.append(Vector3(sx * ri, y_top, cz * ri))

	for j in range(segs):
		var u0 := float(j) / float(segs)
		var u1 := float(j + 1) / float(segs)
		# Cara exterior (+radial)
		_agregar_quad_cw(st, pts_out_b[j], pts_out_t[j], pts_out_b[j + 1], pts_out_t[j + 1], Vector2(u0, 1.0), Vector2(u0, 0.0), Vector2(u1, 1.0), Vector2(u1, 0.0))
		# Cara interior (-radial)
		_agregar_quad_cw(st, pts_in_b[j + 1], pts_in_t[j + 1], pts_in_b[j], pts_in_t[j], Vector2(u1, 1.0), Vector2(u1, 0.0), Vector2(u0, 1.0), Vector2(u0, 0.0))
		# Tapa superior (+Y)
		_agregar_quad_cw(st, pts_out_t[j], pts_in_t[j], pts_out_t[j + 1], pts_in_t[j + 1], Vector2(u0, 0.0), Vector2(u0, 0.2), Vector2(u1, 0.0), Vector2(u1, 0.2))
		# Tapa inferior (-Y)
		_agregar_quad_cw(st, pts_in_b[j], pts_out_b[j], pts_in_b[j + 1], pts_out_b[j + 1], Vector2(u0, 0.8), Vector2(u0, 1.0), Vector2(u1, 0.8), Vector2(u1, 1.0))

	# Tapas laterales de cierre
	_agregar_quad_cw(st, pts_in_b[0], pts_in_t[0], pts_out_b[0], pts_out_t[0], Vector2(0, 1), Vector2(0, 0), Vector2(0.1, 1), Vector2(0.1, 0))
	_agregar_quad_cw(st, pts_out_b[segs], pts_out_t[segs], pts_in_b[segs], pts_in_t[segs], Vector2(0.9, 1), Vector2(0.9, 0), Vector2(1, 1), Vector2(1, 0))

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _st_hombrera_curva(radio: float, grosor: float, alto: float, arco_deg: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := _st_arco_curvo(radio, grosor, -alto * 0.5, alto * 0.5, -arco_deg * 0.5, arco_deg * 0.5, mat, 12)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func _agregar_anillos_outward(st: SurfaceTool, rings: Array, centers: Array, segs: int, v_ini: float = 0.0, v_fin: float = 1.0) -> void:
	# Garantiza winding exterior (+radial desde el centro del anillo) sin importar hacia dónde apunte la tangente.
	var n := rings.size()
	for i in range(n - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var c0: Vector3 = centers[i]
		var v0 := lerpf(v_ini, v_fin, float(i) / float(n - 1))
		var v1 := lerpf(v_ini, v_fin, float(i + 1) / float(n - 1))
		for j in range(segs):
			var u0 := float(j) / float(segs)
			var u1 := float(j + 1) / float(segs)
			var p00: Vector3 = r0[j]
			var p10: Vector3 = r1[j]
			var p01: Vector3 = r0[j + 1]
			var p11: Vector3 = r1[j + 1]
			var tri_n := (p01 - p00).cross(p10 - p00)
			var radial := (p00 - c0)
			if tri_n.dot(radial) >= 0.0:
				_agregar_quad_cw(st, p00, p10, p01, p11, Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v0), Vector2(u1, v1))
			else:
				_agregar_quad_cw(st, p00, p01, p10, p11, Vector2(u0, v0), Vector2(u1, v0), Vector2(u0, v1), Vector2(u1, v1))


static func _st_tubo_curvo(puntos: Array, r_ini: float, r_fin: float, mat: Material, segs: int = 8) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := puntos.size()
	if n < 2:
		return MeshInstance3D.new()

	var rings: Array = []
	for i in range(n):
		var t := float(i) / float(n - 1)
		var r := lerpf(r_ini, r_fin, t)
		var tang: Vector3
		if i == 0:
			tang = (puntos[1] - puntos[0]).normalized()
		elif i == n - 1:
			tang = (puntos[n - 1] - puntos[n - 2]).normalized()
		else:
			tang = (puntos[i + 1] - puntos[i - 1]).normalized()
		if tang.length_squared() < 0.0001:
			tang = Vector3.UP
		var up_ref := Vector3.UP if absf(tang.dot(Vector3.UP)) < 0.94 else Vector3.RIGHT
		var binorm := tang.cross(up_ref).normalized()
		var norm := binorm.cross(tang).normalized()
		var ring: Array[Vector3] = []
		for j in range(segs + 1):
			var a := float(j) / float(segs) * TAU
			ring.append(puntos[i] + (norm * cos(a) + binorm * sin(a)) * r)
		rings.append(ring)

	_agregar_anillos_outward(st, rings, puntos, segs, 0.0, 1.0)

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _st_mechon_pelo(puntos: Array, rx_base: float, rz_base: float, mat: Material) -> MeshInstance3D:
	# Mechón de cabello estilizado ahusado con orientación exterior garantizada y punta gruesa legible.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := puntos.size()
	var segs := 8
	var rings: Array = []

	for i in range(n):
		var t := float(i) / float(n - 1)
		var perfil := sin(minf(1.0, t * 0.85 + 0.15) * PI) * (1.0 - t * 0.30)
		if i == n - 1:
			perfil = 0.24
		var rx := maxf(0.0065, rx_base * maxf(0.36, 1.0 - t * 0.68) * (0.82 + 0.32 * perfil))
		var rz := maxf(0.0065, rz_base * maxf(0.36, 1.0 - t * 0.68) * (0.82 + 0.32 * perfil))
		var tang: Vector3 = (puntos[min(i + 1, n - 1)] - puntos[max(i - 1, 0)]).normalized()
		if tang.length_squared() < 0.0001:
			tang = Vector3.UP
		var ref := Vector3.FORWARD if absf(tang.dot(Vector3.FORWARD)) < 0.92 else Vector3.UP
		var right := tang.cross(ref).normalized()
		var fwd := right.cross(tang).normalized()
		var ring: Array[Vector3] = []
		for j in range(segs + 1):
			var a := float(j) / float(segs) * TAU
			ring.append(puntos[i] + right * (cos(a) * rx) + fwd * (sin(a) * rz))
		rings.append(ring)

	_agregar_anillos_outward(st, rings, puntos, segs, 0.35, 1.0)

	# Tapa en la punta para que nunca quede hueca
	var tip_c: Vector3 = puntos[n - 1]
	var r_tip: Array = rings[n - 1]
	for j in range(segs):
		st.set_uv(Vector2(0.5, 1.0))
		st.add_vertex(tip_c)
		st.set_uv(Vector2(float(j) / float(segs), 1.0))
		st.add_vertex(r_tip[j])
		st.set_uv(Vector2(float(j + 1) / float(segs), 1.0))
		st.add_vertex(r_tip[j + 1])

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _st_llama_espiral(alto: float, radio_base: float, vueltas: float, mat: Material) -> MeshInstance3D:
	var n := 10
	var pts: Array[Vector3] = []
	for i in range(n):
		var t := float(i) / float(n - 1)
		var ang := t * TAU * vueltas
		var rad := radio_base * (1.0 - t * 0.78) * sin(t * PI * 0.9 + 0.15)
		pts.append(Vector3(cos(ang) * rad, t * alto, sin(ang) * rad))
	return _st_tubo_curvo(pts, radio_base * 0.42, 0.0015, mat, 7)


static func _st_gabardina_panel(ancho_sup: float, ancho_inf: float, alto: float, espesor: float, curvatura_z: float, mat: Material) -> MeshInstance3D:
	# Panel independiente de gabardina abierto y curvado con bordes limpios para walking/sprinting sin clipping.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 6
	var rows := 6
	var grid_out: Array = []
	var grid_in: Array = []

	for iy in range(rows + 1):
		var v := float(iy) / float(rows)
		var y := -v * alto
		var ancho := lerpf(ancho_sup, ancho_inf, v)
		var vuelo := v * v * curvatura_z
		var row_out: Array[Vector3] = []
		var row_in: Array[Vector3] = []
		for ix in range(cols + 1):
			var u := float(ix) / float(cols)
			var sx := (u - 0.5) * ancho
			var arco := -(sx * sx) * 2.2
			row_out.append(Vector3(sx, y, vuelo + arco))
			row_in.append(Vector3(sx, y, vuelo + arco + espesor))
		grid_out.append(row_out)
		grid_in.append(row_in)

	for iy in range(rows):
		var v0 := float(iy) / float(rows)
		var v1 := float(iy + 1) / float(rows)
		for ix in range(cols):
			var u0 := float(ix) / float(cols)
			var u1 := float(ix + 1) / float(cols)
			# Superficie única con CULL_DISABLED + textura con borde desgarrado
			_agregar_quad_cw(st, grid_out[iy + 1][ix], grid_out[iy][ix], grid_out[iy + 1][ix + 1], grid_out[iy][ix + 1], Vector2(u0, v1), Vector2(u0, v0), Vector2(u1, v1), Vector2(u1, v0))

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _st_abrigo_abierto(y_top: float, y_bot: float, rx_top: float, rz_top: float, rx_bot: float, rz_bot: float, ang_ini_deg: float, ang_fin_deg: float, mat: Material) -> MeshInstance3D:
	# Falda envolvente en arco abierto (+48°..+312°) dejando frente +Z libre sin faldones rígidos.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 6
	var cols := 18
	var a0 := deg_to_rad(ang_ini_deg)
	var a1 := deg_to_rad(ang_fin_deg)
	var grid: Array = []

	for iy in range(rows + 1):
		var v := float(iy) / float(rows)
		var y := lerpf(y_top, y_bot, v)
		var rx := lerpf(rx_top, rx_bot, v * 0.85 + 0.15 * v * v)
		var rz := lerpf(rz_top, rz_bot, v * 0.85 + 0.15 * v * v)
		var z_tail := -0.022 * v * v
		var row: Array[Vector3] = []
		for ix in range(cols + 1):
			var u := float(ix) / float(cols)
			var a := lerpf(a0, a1, u)
			row.append(Vector3(sin(a) * rx, y, cos(a) * rz + z_tail))
		grid.append(row)

	for iy in range(rows):
		var v0 := float(iy) / float(rows)
		var v1 := float(iy + 1) / float(rows)
		for ix in range(cols):
			var u0 := float(ix) / float(cols)
			var u1 := float(ix + 1) / float(cols)
			_agregar_quad_cw(st, grid[iy + 1][ix], grid[iy][ix], grid[iy + 1][ix + 1], grid[iy][ix + 1], Vector2(u0, v1), Vector2(u0, v0), Vector2(u1, v1), Vector2(u1, v0))

	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


static func _st_engranaje(r_int: float, r_ext: float, grosor: float, dientes: int, mat: Material) -> Node3D:
	var n := dientes * 2
	var mi := Node3D.new()
	var root_hub := _st_prisma_biselado(Vector3(r_int * 2.0, grosor, r_int * 2.0), 0.001, mat, Vector3.ZERO, Vector3.ZERO, Vector2.ONE, 12)
	mi.add_child(root_hub)
	for i in range(n):
		if i % 2 == 0:
			var a := float(i) / float(n) * TAU
			var tooth := _st_prisma_biselado(Vector3((r_ext - r_int) * 1.4, grosor * 0.9, r_int * 0.48), 0.001, mat, Vector3(cos(a) * r_ext * 0.85, 0.0, sin(a) * r_ext * 0.85), Vector3(0.0, rad_to_deg(-a), 0.0), Vector2(0.85, 0.85), 8)
			mi.add_child(tooth)
	return mi


static func _esfera_suave(r: float, mat: Material, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, segs: int = 16, rings: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	return mi


static func _cyl_suave(rt: float, rb: float, h: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, segs: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = segs
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func _torus_suave(r_ext: float, r_int: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.outer_radius = r_ext
	t.inner_radius = r_int
	t.rings = 18
	t.ring_segments = 10
	mi.mesh = t
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	return mi


# ==============================================================================
# CONSTRUCTORES ANATÓMICOS COMPARTIDOS (RIG KENNEY 7 HUESOS, EJES EXACTOS)
# ==============================================================================

static func _crear_bone_attachment(skel: Skeleton3D, bone_name: String) -> BoneAttachment3D:
	var att := BoneAttachment3D.new()
	att.name = "att_" + bone_name
	att.bone_name = bone_name
	var idx := skel.find_bone(bone_name)
	if idx != -1:
		att.bone_idx = idx
	skel.add_child(att)
	return att


static func _q_euler(rx_deg: float, ry_deg: float, rz_deg: float) -> Quaternion:
	return Basis.from_euler(Vector3(deg_to_rad(rx_deg), deg_to_rad(ry_deg), deg_to_rad(rz_deg))).get_rotation_quaternion().normalized()


static func _asegurar_hueso_hijo(skel: Skeleton3D, nombre: String, padre_nombre: String, pos_reposo: Vector3) -> void:
	var idx: int = skel.find_bone(nombre)
	var p_idx: int = skel.find_bone(padre_nombre)
	if idx == -1:
		idx = skel.add_bone(nombre)
	if p_idx != -1:
		skel.set_bone_parent(idx, p_idx)
	skel.set_bone_rest(idx, Transform3D(Basis.IDENTITY, pos_reposo))
	skel.set_bone_pose_position(idx, pos_reposo)


static func _reproporcionar_esqueleto_adulto(
	escena: Node,
	skel: Skeleton3D,
	w_mult: float = 1.0,
	clase_id: String = "rookie"
) -> void:
	var nuevos_reposos: Dictionary = {
		"root": Vector3.ZERO,
		"leg-left": Vector3(0.056 * w_mult, 0.305, -0.010),
		"leg-right": Vector3(-0.056 * w_mult, 0.305, -0.010),
		"torso": Vector3(0.0, 0.305, -0.010),
		"arm-left": Vector3(0.112 * w_mult, 0.192, 0.004),
		"arm-right": Vector3(-0.112 * w_mult, 0.192, 0.004),
		"head": Vector3(0.0, 0.236, 0.008),
	}
	for bone_name: String in nuevos_reposos.keys():
		var idx: int = skel.find_bone(bone_name)
		if idx == -1:
			continue
		var new_origin: Vector3 = nuevos_reposos[bone_name]
		skel.set_bone_rest(idx, Transform3D(Basis.IDENTITY, new_origin))
		skel.set_bone_pose_position(idx, new_origin)

	# Sub-articulaciones reales (rodillas, tobillos, codos y muñecas) preservando los 7 huesos base
	var sub_huesos: Array = [
		["shin-left", "leg-left", Vector3(0.0, -0.145, 0.0)],
		["foot-left", "shin-left", Vector3(0.0, -0.123, 0.0)],
		["shin-right", "leg-right", Vector3(0.0, -0.145, 0.0)],
		["foot-right", "shin-right", Vector3(0.0, -0.123, 0.0)],
		["forearm-left", "arm-left", Vector3(0.114, 0.0, 0.0)],
		["hand-left", "forearm-left", Vector3(0.106, 0.0, 0.0)],
		["forearm-right", "arm-right", Vector3(-0.114, 0.0, 0.0)],
		["hand-right", "forearm-right", Vector3(-0.106, 0.0, 0.0)],
	]
	for spec in sub_huesos:
		var h_nom: String = spec[0]
		var h_pad: String = spec[1]
		var h_pos: Vector3 = spec[2]
		_asegurar_hueso_hijo(skel, h_nom, h_pad, h_pos)
		nuevos_reposos[h_nom] = h_pos

	AnimacionesHeroeKit.construir_animaciones_heroe(escena, skel, nuevos_reposos, clase_id)
	skel.reset_bone_poses()


static func _preparar_esqueleto(escena: Node, w_mult: float = 1.0, clase_id: String = "rookie") -> Dictionary:
	var skel: Skeleton3D = escena.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		return {}
	var to_remove: Array[Node] = []
	for c in skel.get_children():
		if c is MeshInstance3D or c is BoneAttachment3D:
			to_remove.append(c)
	for c in to_remove:
		skel.remove_child(c)
		c.free()

	_reproporcionar_esqueleto_adulto(escena, skel, w_mult, clase_id)

	return {
		"skel": skel,
		"torso": _crear_bone_attachment(skel, "torso"),
		"head": _crear_bone_attachment(skel, "head"),
		"arm_l": _crear_bone_attachment(skel, "arm-left"),
		"forearm_l": _crear_bone_attachment(skel, "forearm-left"),
		"hand_l": _crear_bone_attachment(skel, "hand-left"),
		"arm_r": _crear_bone_attachment(skel, "arm-right"),
		"forearm_r": _crear_bone_attachment(skel, "forearm-right"),
		"hand_r": _crear_bone_attachment(skel, "hand-right"),
		"leg_l": _crear_bone_attachment(skel, "leg-left"),
		"shin_l": _crear_bone_attachment(skel, "shin-left"),
		"foot_l": _crear_bone_attachment(skel, "foot-left"),
		"leg_r": _crear_bone_attachment(skel, "leg-right"),
		"shin_r": _crear_bone_attachment(skel, "shin-right"),
		"foot_r": _crear_bone_attachment(skel, "foot-right"),
	}


static func _construir_cabeza_base(mat_cabeza: Material, mat_cuello: Material, es_guerrero: bool = false) -> Node3D:
	var cabeza := Node3D.new()
	var sc := 1.06 if es_guerrero else 1.0
	# Cuello adulto firme solapando dentro del trapecio
	var cuello_secs := [
		{"y": -0.024, "rx": 0.028 * sc, "rz": 0.028 * sc, "bevel": 0.25},
		{"y": 0.016, "rx": 0.026 * sc, "rz": 0.026 * sc, "bevel": 0.25},
	]
	cabeza.add_child(_loft_perfil(cuello_secs, mat_cuello, 14, true))

	# Cráneo adulto estilizado y anguloso (y = 0.008..0.122m -> ~5.5 cabezas de proporción)
	var craneo_secs := [
		{"y": 0.008, "rx": 0.028 * sc, "rz": 0.036 * sc, "z_off": 0.012, "bevel": 0.55},
		{"y": 0.032, "rx": 0.041 * sc, "rz": 0.045 * sc, "z_off": 0.010, "bevel": 0.55},
		{"y": 0.068, "rx": 0.046 * sc, "rz": 0.050 * sc, "z_off": 0.008, "bevel": 0.42},
		{"y": 0.104, "rx": 0.043 * sc, "rz": 0.047 * sc, "z_off": 0.002, "bevel": 0.30},
		{"y": 0.122, "rx": 0.016 * sc, "rz": 0.018 * sc, "z_off": 0.000, "bevel": 0.12},
	]
	cabeza.add_child(_loft_perfil(craneo_secs, mat_cabeza, 20, true))

	if not es_guerrero:
		for side: float in [-1.0, 1.0]:
			var oreja := _esfera_suave(0.010, mat_cuello, Vector3(side * 0.046, 0.058, 0.004), Vector3(0.50, 1.10, 0.78), 10, 8)
			oreja.rotation_degrees = Vector3(0.0, side * -12.0, 0.0)
			cabeza.add_child(oreja)
	return cabeza


static func _construir_torso_base(mat_torso: Material, es_guerrero: bool = false) -> MeshInstance3D:
	var g := 1.12 if es_guerrero else 1.0
	var secs := [
		{"y": -0.020, "rx": 0.048 * g, "rz": 0.028 * g, "z_off": 0.001, "bevel": 0.45},
		{"y": -0.004, "rx": 0.066 * g, "rz": 0.040 * g, "z_off": 0.002, "bevel": 0.55},
		{"y": 0.012, "rx": 0.069 * g, "rz": 0.043 * g, "z_off": 0.003, "bevel": 0.55},
		{"y": 0.062, "rx": 0.064 * g, "rz": 0.045 * g, "z_off": 0.007, "bevel": 0.50},
		{"y": 0.140, "rx": 0.092 * g, "rz": 0.056 * g, "z_off": 0.011, "bevel": 0.58},
		{"y": 0.188, "rx": 0.106 * g, "rz": 0.062 * g, "z_off": 0.013, "bevel": 0.62},
		{"y": 0.218, "rx": 0.056 * g, "rz": 0.042 * g, "z_off": 0.015, "bevel": 0.40},
		{"y": 0.238, "rx": 0.030 * g, "rz": 0.032 * g, "z_off": 0.016, "bevel": 0.25},
	]
	return _loft_perfil(secs, mat_torso, 20, true)


static func _construir_brazo_articulado(
	lado_s: float,
	att_arm: BoneAttachment3D,
	att_forearm: BoneAttachment3D,
	att_hand: BoneAttachment3D,
	mat_manga: Material,
	mat_brazal: Material,
	mat_mano: Material,
	mat_codera: Material,
	es_guerrero: bool = false
) -> void:
	# Brazo largo atlético alineado en +X (izquierda) o -X (derecha), articulado en hombro, codo (±0.114) y muñeca (±0.220).
	var g := 1.14 if es_guerrero else 1.0
	var s := lado_s

	# 1. Segmento superior (hombro -> codo)
	att_arm.add_child(_esfera_suave(0.032 * g, mat_manga, Vector3(s * 0.006, 0.0, 0.0)))
	var bicep_secs := [
		{"y": 0.000, "rx": 0.029 * g, "rz": 0.029 * g, "bevel": 0.25},
		{"y": 0.058, "rx": 0.026 * g, "rz": 0.026 * g, "bevel": 0.25},
		{"y": 0.114, "rx": 0.0235 * g, "rz": 0.0235 * g, "bevel": 0.25},
	]
	var bicep_mi := _loft_perfil(bicep_secs, mat_manga, 14, true)
	bicep_mi.rotation_degrees = Vector3(0.0, 0.0, -90.0 * s)
	att_arm.add_child(bicep_mi)
	att_arm.add_child(_esfera_suave(0.0238 * g, mat_manga, Vector3(s * 0.114, 0.0, 0.0)))

	# 2. Antebrazo (codo local 0.0 -> muñeca +0.106)
	att_forearm.add_child(_st_prisma_biselado(Vector3(0.026 * g, 0.026 * g, 0.014), 0.004, mat_codera, Vector3(0.0, 0.0, -0.020 * g), Vector3.ZERO, Vector2(0.85, 0.85), 8))
	var ant_secs := [
		{"y": -0.006, "rx": 0.0235 * g, "rz": 0.0235 * g, "bevel": 0.30},
		{"y": 0.051, "rx": 0.022 * g, "rz": 0.022 * g, "bevel": 0.35},
		{"y": 0.104, "rx": 0.0185 * g, "rz": 0.019 * g, "bevel": 0.40},
	]
	var ant_mi := _loft_perfil(ant_secs, mat_brazal, 14, true)
	ant_mi.rotation_degrees = Vector3(0.0, 0.0, -90.0 * s)
	att_forearm.add_child(ant_mi)
	att_forearm.add_child(_esfera_suave(0.0188 * g, mat_brazal, Vector3(s * 0.106, 0.0, 0.0)))

	# 3. Mano / Puño (muñeca local 0.0 -> punta dedos)
	att_hand.add_child(_st_prisma_biselado(Vector3(0.028, 0.021, 0.030), 0.004, mat_mano, Vector3(s * 0.008, -0.002, 0.004), Vector3.ZERO, Vector2(0.95, 0.95), 10))
	att_hand.add_child(_st_prisma_biselado(Vector3(0.015, 0.020, 0.028), 0.004, mat_mano, Vector3(s * 0.020, -0.007, 0.011), Vector3(0.0, s * -14.0, 0.0), Vector2(0.9, 0.9), 8))
	att_hand.add_child(_st_prisma_biselado(Vector3(0.012, 0.022, 0.012), 0.003, mat_mano, Vector3(s * 0.004, 0.010, 0.017), Vector3(35.0, s * 25.0, s * 20.0), Vector2(0.75, 0.75), 8))


static func _construir_pierna_articulada(
	att_leg: BoneAttachment3D,
	att_shin: BoneAttachment3D,
	att_foot: BoneAttachment3D,
	mat_pantalon: Material,
	mat_rodillera: Material,
	mat_bota: Material,
	mat_suela: Material,
	mat_acento: Material,
	es_guerrero: bool = false,
	lado_s: float = 0.0
) -> void:
	# Pierna articulada en cadera (0.0), rodilla (-0.145) y tobillo (-0.268); suela exacta en y = -0.305 (mundo 0.0).
	var g := 1.10 if es_guerrero else 1.0
	var x_in := -0.004 * lado_s

	# 1. Muslo (att_leg)
	att_leg.add_child(_esfera_suave(0.026 * g, mat_pantalon, Vector3(x_in, -0.006, 0.0)))
	var muslo_secs := [
		{"y": -0.148, "x_off": x_in, "rx": 0.026 * g, "rz": 0.028 * g, "z_off": 0.000, "bevel": 0.28},
		{"y": -0.068, "x_off": x_in, "rx": 0.030 * g, "rz": 0.032 * g, "z_off": 0.000, "bevel": 0.28},
		{"y": 0.008, "x_off": x_in, "rx": 0.032 * g, "rz": 0.035 * g, "z_off": 0.000, "bevel": 0.28},
	]
	att_leg.add_child(_loft_perfil(muslo_secs, mat_pantalon, 16, true))
	att_leg.add_child(_esfera_suave(0.0265 * g, mat_pantalon, Vector3(x_in, -0.145, 0.0)))

	# 2. Pantorrilla y caña (att_shin, origen rodilla = -0.145)
	var fin_pantalon_loc := (-0.180 if es_guerrero else -0.205) + 0.145
	var pant_inf_secs := [
		{"y": fin_pantalon_loc, "x_off": x_in, "rx": 0.023 * g, "rz": 0.025 * g, "z_off": 0.000, "bevel": 0.28},
		{"y": 0.004, "x_off": x_in, "rx": 0.026 * g, "rz": 0.028 * g, "z_off": 0.000, "bevel": 0.28},
	]
	att_shin.add_child(_loft_perfil(pant_inf_secs, mat_pantalon, 16, true))
	att_shin.add_child(_st_prisma_biselado(Vector3(0.036 * g, 0.034 * g, 0.013), 0.004, mat_rodillera, Vector3(x_in, 0.0, 0.028 * g), Vector3.ZERO, Vector2(0.88, 0.88), 6))
	att_shin.add_child(_cyl_suave(0.027 * g, 0.027 * g, 0.009, mat_acento, Vector3(x_in, 0.0, 0.0)))

	var top_bota_loc := (-0.172 if es_guerrero else -0.196) + 0.145
	var cana_secs := [
		{"y": -0.125, "x_off": x_in, "rx": 0.027 * g, "rz": 0.030 * g, "z_off": 0.003, "bevel": 0.45},
		{"y": top_bota_loc, "x_off": x_in, "rx": 0.030 * g, "rz": 0.033 * g, "z_off": 0.002, "bevel": 0.45},
	]
	att_shin.add_child(_loft_perfil(cana_secs, mat_bota, 14, true))
	att_shin.add_child(_esfera_suave(0.026 * g, mat_bota, Vector3(x_in, -0.123, 0.002)))

	# 3. Pie y suela (att_foot, origen tobillo = -0.268 -> suela local y = -0.037)
	var bota_secs := [
		{"y": -0.024, "x_off": x_in, "rx": 0.028 * g, "rz": 0.056, "z_off": 0.016, "bevel": 0.62},
		{"y": -0.004, "x_off": x_in, "rx": 0.026 * g, "rz": 0.050, "z_off": 0.013, "bevel": 0.56},
		{"y": 0.012, "x_off": x_in, "rx": 0.025 * g, "rz": 0.036, "z_off": 0.004, "bevel": 0.45},
	]
	att_foot.add_child(_loft_perfil(bota_secs, mat_bota, 16, true))

	var suela_secs := [
		{"y": -0.037, "x_off": x_in, "rx": 0.030 * g, "rz": 0.058, "z_off": 0.016, "bevel": 0.65},
		{"y": -0.023, "x_off": x_in, "rx": 0.030 * g, "rz": 0.058, "z_off": 0.016, "bevel": 0.65},
	]
	att_foot.add_child(_loft_perfil(suela_secs, mat_suela, 16, true))


static func _exportar_glb(escena: Node, ruta_salida: String) -> void:
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var err := gltf_doc.append_from_scene(escena, gltf_state)
	if err != OK:
		printerr("Error serializando GLB %s: %d" % [ruta_salida, err])
		return
	err = gltf_doc.write_to_filesystem(gltf_state, ruta_salida)
	if err != OK:
		printerr("Error escribiendo GLB %s: %d" % [ruta_salida, err])
	else:
		var bytes := FileAccess.get_file_as_bytes(ruta_salida).size()
		print("  -> Exportado: %s (%d bytes)" % [ruta_salida, bytes])


# ==============================================================================
# 1. HÉROE: NOVATO — OPERADOR RECLUTA TÁCTICO (player_rookie.glb — ~0.655m)
# ==============================================================================

func _generar_novato(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Esculpiendo NOVATO OPERADOR TÁCTICO (~0.655m)...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena, 1.0, "rookie")
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_forearm_l: BoneAttachment3D = bones["forearm_l"]
	var att_hand_l: BoneAttachment3D = bones["hand_l"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_forearm_r: BoneAttachment3D = bones["forearm_r"]
	var att_hand_r: BoneAttachment3D = bones["hand_r"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_shin_l: BoneAttachment3D = bones["shin_l"]
	var att_foot_l: BoneAttachment3D = bones["foot_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]
	var att_shin_r: BoneAttachment3D = bones["shin_r"]
	var att_foot_r: BoneAttachment3D = bones["foot_r"]

	var tex_rostro := _tex_rostro_operador()
	var tex_chaleco := _tex_chaleco_novato()
	var tex_pelo := _tex_pelo_gradiente(Color(0.24, 0.21, 0.18), Color(0.44, 0.39, 0.32))
	var acero := _tex_acero_desgastado()

	var mat_rostro := _mat(Color(1.0, 1.0, 1.0), 0.0, 0.65)
	mat_rostro.albedo_texture = tex_rostro
	var mat_piel := _mat(Color(0.74, 0.54, 0.41), 0.0, 0.65)
	var mat_pelo := _mat(Color(1.0, 1.0, 1.0), 0.0, 0.72)
	mat_pelo.albedo_texture = tex_pelo
	var mat_chaqueta := _mat(Color(0.16, 0.20, 0.26), 0.04, 0.80)
	var mat_chaleco := _mat(Color(1.0, 1.0, 1.0), 0.06, 0.66, Color.BLACK, 0.0, "TierAccent")
	mat_chaleco.albedo_texture = tex_chaleco
	var mat_placaporta := _mat(Color(0.18, 0.20, 0.24), 0.12, 0.64, Color.BLACK, 0.0, "TierAccent")
	var mat_ambar_opaco := _mat(Color(0.62, 0.45, 0.14), 0.08, 0.58, Color.BLACK, 0.0, "TierAccent")
	var mat_pantalon := _mat(Color(0.20, 0.23, 0.20), 0.02, 0.84)
	var mat_cuero := _mat(Color(0.16, 0.12, 0.09), 0.08, 0.64)
	var mat_suela := _mat(Color(0.09, 0.09, 0.10), 0.10, 0.88)
	var mat_mochila := _mat(Color(0.24, 0.26, 0.22), 0.02, 0.82)
	var mat_esterilla := _mat(Color(0.18, 0.21, 0.17), 0.02, 0.84)
	var mat_acero := _mat(Color(0.92, 0.94, 0.96), 0.72, 0.38)
	mat_acero.albedo_texture = acero["albedo"]
	mat_acero.normal_enabled = true
	mat_acero.normal_texture = acero["normal"]
	var mat_linterna := _mat(Color(0.84, 0.56, 0.14), 0.05, 0.18, Color(0.84, 0.54, 0.12), 0.70)
	var mat_cobre := _mat(Color(0.55, 0.30, 0.15), 0.84, 0.34)
	var mat_core := _mat(Color(0.16, 0.84, 0.90), 0.10, 0.14, Color(0.18, 0.86, 0.92), 0.85, "TierCore")
	var mat_grafito := _mat(Color(0.13, 0.14, 0.17), 0.45, 0.48)
	var mat_gafa_lente := _mat(Color(0.07, 0.09, 0.12), 0.82, 0.10)
	mat_gafa_lente.clearcoat_enabled = true
	mat_gafa_lente.clearcoat = 1.0

	# --- 1. CABEZA ADULTA + PELO CORTO BARRIDO + GAFAS AHUMADAS + BRAGA TÁCTICA ---
	var cabeza := _construir_cabeza_base(mat_rostro, mat_piel, false)
	cabeza.name = "NovatoCabeza"
	# Puente nasal firme
	cabeza.add_child(_st_prisma_biselado(Vector3(0.008, 0.015, 0.010), 0.002, mat_piel, Vector3(0.0, 0.054, 0.054), Vector3(-12.0, 0.0, 0.0)))

	# Casco capilar corto barrido hacia atrás (sin gorra hacia atrás!)
	cabeza.add_child(_loft_perfil([
		{"y": 0.078, "rx": 0.047, "rz": 0.050, "z_off": 0.000, "bevel": 0.32},
		{"y": 0.104, "rx": 0.046, "rz": 0.049, "z_off": -0.002, "bevel": 0.32},
		{"y": 0.122, "rx": 0.026, "rz": 0.032, "z_off": -0.004, "bevel": 0.24},
		{"y": 0.129, "rx": 0.004, "rz": 0.004, "z_off": -0.006, "bevel": 0.10},
	], mat_pelo, 18, true))

	# Mechones cortos angulosos barridos hacia atrás pegados al cráneo
	var mechones_nov := [
		[Vector3(-0.018, 0.098, 0.034), Vector3(-0.022, 0.113, 0.006), Vector3(-0.022, 0.114, -0.022)],
		[Vector3(0.0, 0.100, 0.036), Vector3(0.002, 0.116, 0.004), Vector3(0.002, 0.116, -0.026)],
		[Vector3(0.018, 0.098, 0.034), Vector3(0.022, 0.113, 0.006), Vector3(0.022, 0.114, -0.022)],
	]
	for pts_raw in mechones_nov:
		var pts: Array[Vector3] = [pts_raw[0], pts_raw[1], pts_raw[2]]
		cabeza.add_child(_st_mechon_pelo(pts, 0.011, 0.007, mat_pelo))

	# Gafas balísticas oscuras ahumadas opacas proyectadas sobre los ojos + cinta trasera
	var visor_nov := Node3D.new()
	visor_nov.position = Vector3(0.0, 0.0, 0.011)
	cabeza.add_child(visor_nov)
	visor_nov.add_child(_st_arco_curvo(0.051, 0.005, 0.062, 0.077, -48.0, 48.0, mat_grafito, 14))
	visor_nov.add_child(_st_arco_curvo(0.053, 0.004, 0.064, 0.075, -43.0, 43.0, mat_gafa_lente, 14))
	cabeza.add_child(_st_arco_curvo(0.050, 0.004, 0.066, 0.074, 42.0, 318.0, mat_grafito, 14))

	# Diadema/auricular táctico con micrófono en mejilla izquierda (+X)
	cabeza.add_child(_cyl_suave(0.012, 0.012, 0.010, mat_grafito, Vector3(0.048, 0.058, 0.004), Vector3(0.0, 0.0, 90.0), 10))
	cabeza.add_child(_st_tubo_curvo([
		Vector3(0.050, 0.054, 0.006),
		Vector3(0.044, 0.044, 0.030),
		Vector3(0.024, 0.038, 0.050),
	], 0.0022, 0.0018, mat_grafito, 6))

	# Braga / pañuelo de cuello táctico carbón envolviendo mentón bajo
	cabeza.add_child(_st_arco_curvo(0.038, 0.012, -0.012, 0.026, -155.0, 155.0, mat_grafito, 16))

	att_head.add_child(cabeza)

	# --- 2. TORSO PORTA-PLACAS TÁCTICO Y MOCHILA DE CAMPAÑA ---
	var torso := Node3D.new()
	torso.name = "NovatoTorso"
	torso.add_child(_construir_torso_base(mat_chaleco, false))

	# Cuello subido de chaqueta y placas balísticas pectorales/dorsales biseladas
	torso.add_child(_st_arco_curvo(0.044, 0.010, 0.205, 0.242, 75.0, 285.0, mat_chaqueta, 14))
	torso.add_child(_st_prisma_biselado(Vector3(0.118, 0.088, 0.024), 0.006, mat_placaporta, Vector3(0.0, 0.146, 0.062), Vector3(-5.0, 0.0, 0.0), Vector2(0.88, 0.90), 10))
	torso.add_child(_st_prisma_biselado(Vector3(0.110, 0.094, 0.020), 0.005, mat_placaporta, Vector3(0.0, 0.144, -0.046), Vector3(4.0, 0.0, 0.0), Vector2(0.90, 0.90), 10))
	# Bolsillos tácticos abdominales al ras
	for sx: float in [-0.038, 0.038]:
		torso.add_child(_st_prisma_biselado(Vector3(0.032, 0.034, 0.014), 0.003, mat_mochila, Vector3(sx, 0.068, 0.056), Vector3(0.0, sx * 12.0, 0.0), Vector2(0.92, 0.92), 8))

	# Cinturón táctico oscuro + hebilla acero + pistolera muslo/cadera derecha (-X)
	torso.add_child(_st_arco_curvo(0.066, 0.014, -0.004, 0.024, -180.0, 180.0, mat_cuero, 18))
	torso.add_child(_st_prisma_biselado(Vector3(0.032, 0.024, 0.012), 0.003, mat_acero, Vector3(0.0, 0.010, 0.070)))
	torso.add_child(_st_prisma_biselado(Vector3(0.020, 0.056, 0.026), 0.004, mat_cuero, Vector3(-0.072, -0.012, 0.010), Vector3(0.0, 0.0, -6.0)))
	torso.add_child(_st_prisma_biselado(Vector3(0.013, 0.022, 0.028), 0.003, mat_grafito, Vector3(-0.074, 0.016, 0.018), Vector3(14.0, 0.0, -6.0)))

	# Mochila militar compacta en espalda alta (y=0.125, z=-0.080)
	var mochila := Node3D.new()
	mochila.position = Vector3(0.0, 0.128, -0.078)
	mochila.add_child(_st_prisma_biselado(Vector3(0.118, 0.145, 0.058), 0.008, mat_mochila, Vector3.ZERO, Vector3.ZERO, Vector2(0.92, 0.90), 12))
	mochila.add_child(_st_prisma_biselado(Vector3(0.124, 0.032, 0.064), 0.005, mat_placaporta, Vector3(0.0, 0.068, 0.0)))
	mochila.add_child(_st_prisma_biselado(Vector3(0.086, 0.070, 0.026), 0.005, mat_esterilla, Vector3(0.0, -0.024, -0.038)))
	for sx: float in [-0.030, 0.030]:
		mochila.add_child(_st_prisma_biselado(Vector3(0.009, 0.125, 0.007), 0.002, mat_cuero, Vector3(sx, 0.005, -0.042)))
	mochila.add_child(_cyl_suave(0.020, 0.020, 0.132, mat_esterilla, Vector3(0.0, 0.094, 0.0), Vector3(0.0, 0.0, 90.0)))
	# Baliza ámbar sobria izquierda + radio con antena derecha
	mochila.add_child(_cyl_suave(0.014, 0.014, 0.010, mat_grafito, Vector3(0.068, 0.018, 0.0)))
	mochila.add_child(_cyl_suave(0.011, 0.011, 0.038, mat_linterna, Vector3(0.068, -0.006, 0.0)))
	mochila.add_child(_cyl_suave(0.014, 0.014, 0.009, mat_grafito, Vector3(0.068, -0.028, 0.0)))
	mochila.add_child(_st_prisma_biselado(Vector3(0.016, 0.048, 0.022), 0.003, mat_grafito, Vector3(-0.066, 0.014, 0.0)))
	mochila.add_child(_cyl_suave(0.002, 0.003, 0.068, mat_acero, Vector3(-0.066, 0.068, 0.0)))
	torso.add_child(mochila)

	att_torso.add_child(torso)

	# --- 3. BRAZOS ARTICULADOS EN ±X + GUANTES CARBÓN + BASTÓN ELÉCTRICO EN MANO DERECHA ---
	_construir_brazo_articulado(1.0, att_arm_l, att_forearm_l, att_hand_l, mat_chaqueta, mat_chaqueta, mat_grafito, mat_grafito, false)
	att_forearm_l.add_child(_cyl_suave(0.022, 0.022, 0.014, mat_ambar_opaco, Vector3(0.091, 0.0, 0.0), Vector3(0.0, 0.0, 90.0)))

	_construir_brazo_articulado(-1.0, att_arm_r, att_forearm_r, att_hand_r, mat_chaqueta, mat_chaqueta, mat_grafito, mat_grafito, false)
	att_forearm_r.add_child(_cyl_suave(0.022, 0.022, 0.014, mat_ambar_opaco, Vector3(-0.091, 0.0, 0.0), Vector3(0.0, 0.0, 90.0)))

	var taser := Node3D.new()
	taser.name = "BastonTaser"
	taser.position = Vector3(-0.016, -0.005, 0.014)
	taser.rotation_degrees = Vector3(0.0, 18.0, 0.0)
	taser.add_child(_cyl_suave(0.010, 0.011, 0.12, mat_grafito, Vector3(0, 0, -0.03), Vector3(90, 0, 0)))
	taser.add_child(_cyl_suave(0.015, 0.014, 0.018, mat_acero, Vector3(0, 0, 0.035), Vector3(90, 0, 0)))
	taser.add_child(_cyl_suave(0.011, 0.011, 0.105, mat_core, Vector3(0, 0, 0.092), Vector3(90, 0, 0)))
	taser.add_child(_cyl_suave(0.015, 0.013, 0.038, mat_acero, Vector3(0, 0, 0.160), Vector3(90, 0, 0)))
	for sy: float in [-0.007, 0.007]:
		taser.add_child(_cyl_suave(0.0022, 0.0028, 0.032, mat_core, Vector3(0, sy, 0.194), Vector3(90, 0, 0)))
	for sy: float in [-1.0, 1.0]:
		taser.add_child(_st_tubo_curvo([
			Vector3(0.0, sy * 0.014, 0.036),
			Vector3(sy * 0.015, sy * 0.016, 0.072),
			Vector3(-sy * 0.012, sy * 0.016, 0.112),
			Vector3(0.0, sy * 0.014, 0.150),
		], 0.0026, 0.0026, mat_cobre, 6))
	att_hand_r.add_child(taser)

	# --- 4. PIERNAS ARTICULADAS CARGO OLIVA Y BOTAS MILITARES ---
	_construir_pierna_articulada(att_leg_l, att_shin_l, att_foot_l, mat_pantalon, mat_grafito, mat_cuero, mat_suela, mat_grafito, false, 1.0)
	_construir_pierna_articulada(att_leg_r, att_shin_r, att_foot_r, mat_pantalon, mat_grafito, mat_cuero, mat_suela, mat_grafito, false, -1.0)

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 2. HÉROE: GUERRERO / MURMILLO — JUGGERNAUT DE VANGUARDIA (~0.680m)
# ==============================================================================

func _generar_guerrero(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Esculpiendo GUERRERO JUGGERNAUT (~0.680m)...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena, 1.12, "warrior")
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_forearm_l: BoneAttachment3D = bones["forearm_l"]
	var att_hand_l: BoneAttachment3D = bones["hand_l"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_forearm_r: BoneAttachment3D = bones["forearm_r"]
	var att_hand_r: BoneAttachment3D = bones["hand_r"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_shin_l: BoneAttachment3D = bones["shin_l"]
	var att_foot_l: BoneAttachment3D = bones["foot_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]
	var att_shin_r: BoneAttachment3D = bones["shin_r"]
	var att_foot_r: BoneAttachment3D = bones["foot_r"]

	var acero := _tex_acero_desgastado()
	var ceramico := _tex_traje_ceramico_tactico()
	var hazard := _tex_hazard_escudo()

	var mat_acero := _mat(Color(0.92, 0.94, 0.96), 0.84, 0.34, Color.BLACK, 0.0, "TierAccent")
	mat_acero.albedo_texture = acero["albedo"]
	mat_acero.normal_enabled = true
	mat_acero.normal_texture = acero["normal"]

	var mat_acero_oscuro := _mat(Color(0.16, 0.18, 0.21), 0.78, 0.40)
	var mat_ceramico := _mat(Color(0.78, 0.80, 0.84), 0.04, 0.76)
	mat_ceramico.albedo_texture = ceramico["albedo"]
	mat_ceramico.normal_enabled = true
	mat_ceramico.normal_texture = ceramico["normal"]

	var mat_cobre := _mat(Color(0.64, 0.28, 0.09), 0.25, 0.48, Color.BLACK, 0.0, "TierAccent")
	var mat_visor := _mat(Color(0.16, 0.82, 0.94), 0.12, 0.08, Color(0.16, 0.84, 0.96), 0.82, "TierCore")
	mat_visor.clearcoat_enabled = true
	mat_visor.clearcoat = 1.0

	var mat_core := _mat(Color(0.20, 0.88, 0.96), 0.10, 0.12, Color(0.18, 0.90, 0.98), 0.88, "TierCore")
	var mat_hazard := _mat(Color(1.0, 1.0, 1.0), 0.15, 0.50)
	mat_hazard.albedo_texture = hazard
	var mat_hoja := _mat(Color(0.48, 0.52, 0.58), 0.90, 0.22)
	var mat_suela := _mat(Color(0.09, 0.10, 0.12), 0.25, 0.82)

	# --- 1. YELMO BALÍSTICO FACETADO + T-VISOR ESTRECHO + RESPIRADOR GRAFITO/COBRE ---
	var cabeza := _construir_cabeza_base(mat_acero_oscuro, mat_acero_oscuro, true)
	cabeza.name = "GuerreroCabeza"

	# Cúpula facetada de 8 lados (cero forma de campana infantil, tope ~0.138 -> 0.679m mundo)
	var casco_secs := [
		{"y": 0.068, "rx": 0.056, "rz": 0.062, "z_off": 0.002, "bevel": 0.65},
		{"y": 0.096, "rx": 0.056, "rz": 0.062, "z_off": 0.002, "bevel": 0.68},
		{"y": 0.122, "rx": 0.044, "rz": 0.050, "z_off": 0.000, "bevel": 0.60},
		{"y": 0.136, "rx": 0.022, "rz": 0.026, "z_off": -0.002, "bevel": 0.45},
	]
	cabeza.add_child(_loft_perfil(casco_secs, mat_acero, 8, true))
	# Cresta dorsal murmillo angular
	cabeza.add_child(_st_prisma_biselado(Vector3(0.016, 0.020, 0.088), 0.003, mat_acero_oscuro, Vector3(0.0, 0.134, -0.004), Vector3(-6.0, 0.0, 0.0), Vector2(0.75, 0.88), 8))
	for sx: float in [-1.0, 1.0]:
		cabeza.add_child(_cyl_suave(0.016, 0.015, 0.012, mat_acero_oscuro, Vector3(sx * 0.054, 0.068, 0.004), Vector3(0.0, 0.0, 90.0), 8))
		cabeza.add_child(_cyl_suave(0.009, 0.009, 0.014, mat_acero, Vector3(sx * 0.055, 0.068, 0.004), Vector3(0.0, 0.0, 90.0), 8))

	# Ceja blindada angulosa + T-visor estrecho amenazante cian
	var ceja_casco := _st_arco_curvo(0.060, 0.010, 0.074, 0.090, -54.0, 54.0, mat_acero_oscuro, 12)
	ceja_casco.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	cabeza.add_child(ceja_casco)
	cabeza.add_child(_st_arco_curvo(0.055, 0.009, 0.052, 0.075, -56.0, 56.0, mat_acero_oscuro, 12))
	cabeza.add_child(_st_arco_curvo(0.058, 0.006, 0.061, 0.070, -44.0, 44.0, mat_visor, 12))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.007, 0.022, 0.008), 0.001, mat_visor, Vector3(0.0, 0.056, 0.059)))

	# Protectores de mejilla y respirador mandibular grafito con detalles cobre quemado
	cabeza.add_child(_st_arco_curvo(0.052, 0.014, 0.010, 0.052, -52.0, 52.0, mat_acero_oscuro, 12))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.042, 0.036, 0.022), 0.005, mat_acero_oscuro, Vector3(0.0, 0.028, 0.054), Vector3(8.0, 0.0, 0.0), Vector2(0.80, 0.88), 8))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.018, 0.024, 0.012), 0.002, mat_cobre, Vector3(0.0, 0.028, 0.066), Vector3(8.0, 0.0, 0.0)))
	for sx: float in [-1.0, 1.0]:
		var f_node := Node3D.new()
		f_node.position = Vector3(sx * 0.032, 0.024, 0.052)
		f_node.rotation_degrees = Vector3(10.0, sx * 38.0, 0.0)
		f_node.add_child(_cyl_suave(0.012, 0.012, 0.018, mat_acero_oscuro, Vector3.ZERO, Vector3(90.0, 0.0, 0.0), 8))
		f_node.add_child(_cyl_suave(0.009, 0.009, 0.006, mat_cobre, Vector3(0.0, 0.0, 0.010), Vector3(90.0, 0.0, 0.0), 8))
		cabeza.add_child(f_node)

	att_head.add_child(cabeza)

	# --- 2. TORSO ADULTO BLINDADO + HOMBRERAS DOBLES ANGULOSAS + ESPADA DORSAL ---
	var torso := Node3D.new()
	torso.name = "GuerreroTorso"
	torso.add_child(_construir_torso_base(mat_ceramico, true))

	# Coraza pectoral pesada con biseles agresivos
	torso.add_child(_st_prisma_biselado(Vector3(0.205, 0.105, 0.138), 0.010, mat_acero, Vector3(0.0, 0.158, 0.016), Vector3.ZERO, Vector2(0.96, 0.92), 10))
	for sx: float in [-1.0, 1.0]:
		torso.add_child(_st_prisma_biselado(Vector3(0.082, 0.068, 0.026), 0.006, mat_acero, Vector3(sx * 0.050, 0.158, 0.086), Vector3(-6.0, sx * -14.0, 0.0), Vector2(0.92, 0.92), 8))
		torso.add_child(_st_prisma_biselado(Vector3(0.020, 0.036, 0.040), 0.003, mat_cobre, Vector3(sx * 0.056, 0.200, 0.032), Vector3(-16.0, 0.0, 0.0)))

	# 6 Placas abdominales segmentadas bien alineadas
	for row in range(3):
		var py := 0.092 - float(row) * 0.023
		for sx: float in [-0.026, 0.026]:
			torso.add_child(_st_prisma_biselado(Vector3(0.038, 0.018, 0.016), 0.004, mat_ceramico, Vector3(sx, py, 0.072), Vector3.ZERO, Vector2(0.92, 0.92), 8))

	# Hombreras dobles superpuestas angulosas (TierAccent)
	for sx: float in [-1.0, 1.0]:
		var pauldron := Node3D.new()
		pauldron.position = Vector3(sx * 0.128, 0.194, 0.006)
		pauldron.rotation_degrees = Vector3(0.0, sx * 90.0, sx * -8.0)
		pauldron.add_child(_st_hombrera_curva(0.052, 0.014, 0.052, 130.0, mat_acero, Vector3(0.0, 0.015, 0.0)))
		pauldron.add_child(_st_hombrera_curva(0.048, 0.012, 0.030, 120.0, mat_acero_oscuro, Vector3(0.0, -0.016, 0.0)))
		pauldron.add_child(_st_prisma_biselado(Vector3(0.016, 0.016, 0.016), 0.003, mat_cobre, Vector3(0.0, 0.036, 0.048)))
		torso.add_child(pauldron)

	# Cinturón táctico acero/cobre con pouches
	torso.add_child(_st_arco_curvo(0.075, 0.018, -0.004, 0.026, -180.0, 180.0, mat_acero_oscuro, 18))
	torso.add_child(_st_prisma_biselado(Vector3(0.040, 0.030, 0.016), 0.004, mat_acero, Vector3(0.0, 0.011, 0.080)))
	for sx: float in [-0.052, 0.052]:
		torso.add_child(_st_prisma_biselado(Vector3(0.028, 0.034, 0.020), 0.004, mat_cobre, Vector3(sx, 0.011, 0.076), Vector3(0.0, sx * 120.0, 0.0)))

	# Espada pesada de acero oscuro cruzada en espalda (-16° X)
	var espada := Node3D.new()
	espada.position = Vector3(-0.018, 0.135, -0.082)
	espada.rotation_degrees = Vector3(-16.0, 0.0, 30.0)
	espada.add_child(_cyl_suave(0.010, 0.010, 0.125, mat_cobre, Vector3(0.0, 0.155, 0.0)))
	espada.add_child(_esfera_suave(0.016, mat_acero, Vector3(0.0, 0.220, 0.0)))
	espada.add_child(_st_prisma_biselado(Vector3(0.098, 0.018, 0.026), 0.004, mat_acero_oscuro, Vector3(0.0, 0.092, 0.0)))
	espada.add_child(_st_prisma_biselado(Vector3(0.046, 0.280, 0.018), 0.005, mat_hoja, Vector3(0.0, -0.055, 0.0), Vector3.ZERO, Vector2(0.85, 0.85), 8))
	torso.add_child(espada)

	att_torso.add_child(torso)

	# --- 3. BRAZOS ARTICULADOS BLINDADOS + ESCUDO EN ANTEBRAZO (+X = +0.054) + MARTILLO EN MANO (-X = -0.016) ---
	_construir_brazo_articulado(1.0, att_arm_l, att_forearm_l, att_hand_l, mat_ceramico, mat_acero, mat_acero_oscuro, mat_acero_oscuro, true)
	_construir_brazo_articulado(-1.0, att_arm_r, att_forearm_r, att_hand_r, mat_ceramico, mat_acero, mat_acero_oscuro, mat_acero_oscuro, true)

	var escudo := Node3D.new()
	escudo.name = "EscudoBalistico"
	escudo.position = Vector3(0.054, 0.026, 0.046)
	escudo.rotation_degrees = Vector3(68.0, 14.0, -18.0)
	escudo.add_child(_st_prisma_biselado(Vector3(0.285, 0.024, 0.180), 0.006, mat_acero, Vector3.ZERO, Vector3.ZERO, Vector2(0.94, 0.94), 8))
	escudo.add_child(_st_prisma_biselado(Vector3(0.270, 0.010, 0.168), 0.004, mat_acero_oscuro, Vector3(0.0, -0.009, 0.0), Vector3.ZERO, Vector2(0.95, 0.95), 8))
	escudo.add_child(_st_prisma_biselado(Vector3(0.028, 0.008, 0.092), 0.002, mat_acero_oscuro, Vector3(-0.088, 0.014, 0.0)))
	escudo.add_child(_st_prisma_biselado(Vector3(0.018, 0.010, 0.078), 0.002, mat_visor, Vector3(-0.088, 0.015, 0.0)))
	var hazard_mi := MeshInstance3D.new()
	var hazard_box := BoxMesh.new()
	hazard_box.size = Vector3(0.098, 0.008, 0.172)
	hazard_mi.mesh = hazard_box
	hazard_mi.material_override = mat_hazard
	hazard_mi.position = Vector3(0.010, 0.014, 0.0)
	escudo.add_child(hazard_mi)
	escudo.add_child(_cyl_suave(0.038, 0.040, 0.014, mat_acero_oscuro, Vector3(0.010, 0.021, 0.0), Vector3.ZERO, 8))
	escudo.add_child(_cyl_suave(0.025, 0.025, 0.018, mat_core, Vector3(0.010, 0.023, 0.0), Vector3.ZERO, 16))
	att_forearm_l.add_child(escudo)

	var martillo := Node3D.new()
	martillo.name = "MartilloCinetico"
	martillo.position = Vector3(-0.016, -0.005, 0.014)
	martillo.rotation_degrees = Vector3(-16.0, 20.0, 0.0)
	martillo.add_child(_cyl_suave(0.012, 0.012, 0.42, mat_acero_oscuro, Vector3(0, 0, 0.09), Vector3(90, 0, 0), 8))
	martillo.add_child(_cyl_suave(0.015, 0.015, 0.13, mat_cobre, Vector3(0, 0, -0.01), Vector3(90, 0, 0), 10))
	martillo.add_child(_esfera_suave(0.018, mat_acero, Vector3(0, 0, -0.115)))
	martillo.add_child(_cyl_suave(0.024, 0.022, 0.038, mat_acero_oscuro, Vector3(0, 0, 0.25), Vector3(90, 0, 0), 8))
	martillo.add_child(_st_prisma_biselado(Vector3(0.098, 0.090, 0.142), 0.012, mat_acero, Vector3(0, 0, 0.325), Vector3.ZERO, Vector2(0.95, 0.95), 8))
	for sx: float in [-0.052, 0.052]:
		var eng := _st_engranaje(0.019, 0.029, 0.008, 8, mat_acero_oscuro)
		eng.position = Vector3(sx, 0.0, 0.325)
		eng.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		martillo.add_child(eng)
	martillo.add_child(_st_prisma_biselado(Vector3(0.074, 0.068, 0.012), 0.003, mat_acero_oscuro, Vector3(0, 0, 0.398)))
	martillo.add_child(_torus_suave(0.026, 0.004, mat_core, Vector3(0, 0, 0.404), Vector3(90.0, 0.0, 0.0)))
	martillo.add_child(_st_prisma_biselado(Vector3(0.060, 0.007, 0.008), 0.002, mat_core, Vector3(0, 0, 0.404)))
	att_hand_r.add_child(martillo)

	# --- 4. PIERNAS ARTICULADAS CERÁMICO-GRIS + GREBAS PESADAS + BOTAS DE ASALTO ---
	_construir_pierna_articulada(att_leg_l, att_shin_l, att_foot_l, mat_ceramico, mat_acero, mat_acero_oscuro, mat_suela, mat_cobre, true, 1.0)
	_construir_pierna_articulada(att_leg_r, att_shin_r, att_foot_r, mat_ceramico, mat_acero, mat_acero_oscuro, mat_suela, mat_cobre, true, -1.0)

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 3. HÉROE: ARQUERO / SAGITTARIO — RECON FRANCOTIRADOR (~0.665m)
# ==============================================================================

func _generar_arquero(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Esculpiendo ARQUERO RECON FRANCOTIRADOR (~0.665m)...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena, 0.96, "archer")
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_forearm_l: BoneAttachment3D = bones["forearm_l"]
	var att_hand_l: BoneAttachment3D = bones["hand_l"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_forearm_r: BoneAttachment3D = bones["forearm_r"]
	var att_hand_r: BoneAttachment3D = bones["hand_r"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_shin_l: BoneAttachment3D = bones["shin_l"]
	var att_foot_l: BoneAttachment3D = bones["foot_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]
	var att_shin_r: BoneAttachment3D = bones["shin_r"]
	var att_foot_r: BoneAttachment3D = bones["foot_r"]

	var acero := _tex_acero_desgastado()
	var ceramico := _tex_traje_ceramico_tactico()
	var tex_ojos := _tex_rostro_ojos_visor(Color(0.22, 0.14, 0.08))
	var tex_pelo := _tex_pelo_gradiente(Color(0.18, 0.11, 0.07), Color(0.32, 0.20, 0.12))

	var mat_rostro := _mat(Color(1.0, 1.0, 1.0), 0.0, 0.65)
	mat_rostro.albedo_texture = tex_ojos
	var mat_piel := _mat(Color(0.74, 0.54, 0.41), 0.0, 0.65)
	var mat_pelo := _mat(Color(1.0, 1.0, 1.0), 0.02, 0.72)
	mat_pelo.albedo_texture = tex_pelo
	var mat_ceramico := _mat(Color(0.78, 0.80, 0.84), 0.04, 0.76)
	mat_ceramico.albedo_texture = ceramico["albedo"]
	mat_ceramico.normal_enabled = true
	mat_ceramico.normal_texture = ceramico["normal"]

	var mat_terracota := _mat(Color(0.62, 0.26, 0.10), 0.04, 0.70, Color.BLACK, 0.0, "TierAccent")
	var mat_cuero := _mat(Color(0.24, 0.16, 0.10), 0.08, 0.60)
	var mat_capa := _mat(Color(0.17, 0.19, 0.22), 0.04, 0.80, Color.BLACK, 0.0, "TierAccent")
	mat_capa.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mat_acero := _mat(Color(0.88, 0.90, 0.92), 0.80, 0.34, Color.BLACK, 0.0, "TierAccent")
	mat_acero.albedo_texture = acero["albedo"]
	mat_acero.normal_enabled = true
	mat_acero.normal_texture = acero["normal"]

	var mat_mascara := _mat(Color(0.13, 0.14, 0.17), 0.58, 0.38)
	# Visor balístico opaco espejado en ámbar-oro oscuro (elimina ojos infantiles)
	var mat_hud := _mat(Color(0.82, 0.44, 0.10), 0.88, 0.10, Color(0.75, 0.38, 0.08), 0.45, "TierCore")
	mat_hud.clearcoat_enabled = true
	mat_hud.clearcoat = 1.0

	var mat_arco := _mat(Color(0.32, 0.36, 0.40), 0.86, 0.26)
	var mat_energia := _mat(Color(0.18, 0.88, 0.96), 0.05, 0.12, Color(0.18, 0.90, 0.98), 0.86, "TierCore")
	var mat_suela := _mat(Color(0.10, 0.11, 0.13), 0.15, 0.86)

	# --- 1. CABEZA ADULTA + PELO BARRIDO + VISOR ESPEJADO OPACO + RESPIRADOR CARBONO ---
	var cabeza := _construir_cabeza_base(mat_rostro, mat_piel, false)
	cabeza.name = "ArqueroCabeza"

	# Corona de pelo castaño oscuro afilada barrida hacia atrás pegada al cráneo
	cabeza.add_child(_loft_perfil([
		{"y": 0.076, "rx": 0.047, "rz": 0.050, "z_off": 0.000, "bevel": 0.32},
		{"y": 0.104, "rx": 0.046, "rz": 0.049, "z_off": -0.002, "bevel": 0.32},
		{"y": 0.122, "rx": 0.026, "rz": 0.032, "z_off": -0.004, "bevel": 0.24},
		{"y": 0.129, "rx": 0.004, "rz": 0.004, "z_off": -0.006, "bevel": 0.10},
	], mat_pelo, 18, true))

	var mechones_arq := [
		[Vector3(-0.018, 0.098, 0.033), Vector3(-0.022, 0.113, 0.005), Vector3(-0.022, 0.114, -0.024)],
		[Vector3(0.0, 0.100, 0.035), Vector3(0.002, 0.116, 0.004), Vector3(0.002, 0.115, -0.028)],
		[Vector3(0.018, 0.098, 0.033), Vector3(0.022, 0.113, 0.005), Vector3(0.022, 0.114, -0.024)],
	]
	for pts_raw in mechones_arq:
		var pts: Array[Vector3] = [pts_raw[0], pts_raw[1], pts_raw[2]]
		cabeza.add_child(_st_mechon_pelo(pts, 0.011, 0.007, mat_pelo))

	# Diadema táctica oscura + visor balístico espejado opaco ámbar-oro proyectado sobre los ojos
	var visor_arq := Node3D.new()
	visor_arq.position = Vector3(0.0, 0.0, 0.011)
	cabeza.add_child(visor_arq)
	visor_arq.add_child(_st_arco_curvo(0.052, 0.006, 0.057, 0.077, -50.0, 50.0, mat_mascara, 14))
	visor_arq.add_child(_st_arco_curvo(0.054, 0.004, 0.059, 0.074, -46.0, 46.0, mat_hud, 14))
	cabeza.add_child(_st_arco_curvo(0.050, 0.004, 0.062, 0.072, 44.0, 316.0, mat_cuero, 14))

	# Respirador mandibular angular de fibra de carbono con filtros
	cabeza.add_child(_st_arco_curvo(0.047, 0.010, 0.008, 0.042, -46.0, 46.0, mat_mascara, 14))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.034, 0.028, 0.018), 0.004, mat_mascara, Vector3(0.0, 0.024, 0.051), Vector3(12.0, 0.0, 0.0), Vector2(0.75, 0.85), 8))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.014, 0.018, 0.010), 0.002, mat_terracota, Vector3(0.0, 0.026, 0.059), Vector3(12.0, 0.0, 0.0)))
	for sx: float in [-1.0, 1.0]:
		cabeza.add_child(_cyl_suave(0.008, 0.008, 0.014, mat_acero, Vector3(sx * 0.024, 0.020, 0.048), Vector3(10.0, sx * 38.0, 0.0)))

	att_head.add_child(cabeza)

	# --- 2. TORSO ADULTO CERÁMICO + SHEMAGH + HOMBRERA ASIMÉTRICA (+X) + MEDIA CAPA + CARCAJ ---
	var torso := Node3D.new()
	torso.name = "ArqueroTorso"
	torso.add_child(_construir_torso_base(mat_ceramico, false))

	# Shemagh / bufanda táctica terracota oxidado
	torso.add_child(_torus_suave(0.052, 0.015, mat_terracota, Vector3(0.0, 0.222, 0.014), Vector3(82.0, 0.0, 0.0), Vector3(1.0, 0.90, 1.0)))
	torso.add_child(_st_prisma_biselado(Vector3(0.042, 0.068, 0.014), 0.004, mat_terracota, Vector3(-0.020, 0.168, 0.060), Vector3(-14.0, 8.0, 12.0), Vector2(1.12, 0.9)))

	# Hombrera metálica asimétrica angular SOLO en hombro izquierdo (+X)
	var homb_izq := _st_hombrera_curva(0.046, 0.012, 0.042, 125.0, mat_acero, Vector3(0.114, 0.190, 0.006), Vector3(0.0, 90.0, -8.0))
	torso.add_child(homb_izq)
	# Hombro derecho (-X): refuerzo compacto de cuero
	torso.add_child(_st_prisma_biselado(Vector3(0.014, 0.032, 0.028), 0.003, mat_cuero, Vector3(-0.104, 0.184, 0.008)))

	# Media capa táctica asimétrica cayendo por costado trasero izquierdo (+X, -Z)
	var media_capa := _st_abrigo_abierto(0.192, -0.095, 0.102, 0.062, 0.125, 0.088, 108.0, 198.0, mat_capa)
	torso.add_child(media_capa)

	# Bandolera curva de cuero oscuro fuera del pecho + 4 celdas de energía cian
	torso.add_child(_st_tubo_curvo([
		Vector3(-0.070, 0.205, 0.062),
		Vector3(-0.026, 0.148, 0.088),
		Vector3(0.026, 0.088, 0.085),
		Vector3(0.066, 0.026, 0.066),
	], 0.011, 0.010, mat_cuero, 8))
	for i in range(4):
		var py := 0.160 - float(i) * 0.028
		var px := -0.028 + float(i) * 0.021
		torso.add_child(_cyl_suave(0.005, 0.005, 0.022, mat_energia, Vector3(px, py, 0.094), Vector3(0.0, 0.0, -34.0)))

	# Cinturón oscuro + pouches
	torso.add_child(_st_arco_curvo(0.068, 0.014, -0.004, 0.024, -180.0, 180.0, mat_cuero, 18))
	for sx: float in [-0.044, 0.044]:
		torso.add_child(_st_prisma_biselado(Vector3(0.024, 0.028, 0.018), 0.003, mat_cuero, Vector3(sx, 0.010, 0.070)))

	# Carcaj dorsal angular (-18° X) con 4 saetas afiladas
	var carcaj := Node3D.new()
	carcaj.position = Vector3(0.046, 0.142, -0.074)
	carcaj.rotation_degrees = Vector3(-18.0, 0.0, -24.0)
	carcaj.add_child(_cyl_suave(0.024, 0.020, 0.205, mat_acero, Vector3.ZERO, Vector3.ZERO, 8))
	carcaj.add_child(_cyl_suave(0.026, 0.026, 0.016, mat_mascara, Vector3(0.0, 0.096, 0.0), Vector3.ZERO, 8))
	carcaj.add_child(_st_prisma_biselado(Vector3(0.009, 0.120, 0.014), 0.002, mat_energia, Vector3(0.024, 0.0, 0.0)))
	for fx: float in [-0.009, 0.009]:
		for fz: float in [-0.009, 0.009]:
			carcaj.add_child(_cyl_suave(0.0022, 0.0022, 0.100, mat_arco, Vector3(fx, 0.122, fz), Vector3.ZERO, 6))
			carcaj.add_child(_st_prisma_biselado(Vector3(0.008, 0.022, 0.008), 0.002, mat_energia, Vector3(fx, 0.164, fz), Vector3.ZERO, Vector2(0.45, 0.45), 6))
	torso.add_child(carcaj)

	att_torso.add_child(torso)

	# --- 3. BRAZOS ARTICULADOS EN ±X + ARCO COMPUESTO DE RIEL EN MANO IZQUIERDA ---
	_construir_brazo_articulado(1.0, att_arm_l, att_forearm_l, att_hand_l, mat_ceramico, mat_acero, mat_mascara, mat_mascara, false)
	_construir_brazo_articulado(-1.0, att_arm_r, att_forearm_r, att_hand_r, mat_ceramico, mat_acero, mat_mascara, mat_mascara, false)

	var arco := Node3D.new()
	arco.name = "ArcoTecnologico"
	arco.position = Vector3(0.016, -0.005, 0.014)
	arco.rotation_degrees = Vector3(-24.0, 90.0, 0.0)
	arco.add_child(_st_prisma_biselado(Vector3(0.022, 0.082, 0.028), 0.004, mat_mascara))
	for sy: float in [-1.0, 1.0]:
		arco.add_child(_st_tubo_curvo([
			Vector3(0.0, sy * 0.032, 0.002),
			Vector3(0.0, sy * 0.110, -0.022),
			Vector3(0.0, sy * 0.175, -0.044),
			Vector3(0.0, sy * 0.210, -0.068),
		], 0.011, 0.006, mat_arco, 8))
		arco.add_child(_cyl_suave(0.014, 0.014, 0.022, mat_mascara, Vector3(0.0, sy * 0.205, -0.066), Vector3(0.0, 0.0, 90.0), 10))
		arco.add_child(_cyl_suave(0.012, 0.012, 0.022, mat_energia, Vector3(0.0, sy * 0.125, -0.030), Vector3(0.0, 0.0, 90.0), 10))
	arco.add_child(_cyl_suave(0.0018, 0.0018, 0.420, mat_energia, Vector3(0.0, 0.0, -0.068), Vector3.ZERO, 6))
	arco.add_child(_cyl_suave(0.0025, 0.0025, 0.145, mat_arco, Vector3(0.0, 0.0, 0.008), Vector3(90.0, 0.0, 0.0), 6))
	arco.add_child(_st_prisma_biselado(Vector3(0.010, 0.010, 0.024), 0.002, mat_energia, Vector3(0.0, 0.0, 0.084), Vector3(90.0, 0.0, 0.0), Vector2(0.25, 0.25), 6))
	att_hand_l.add_child(arco)

	# --- 4. PIERNAS ARTICULADAS CERÁMICO-GRIS + FUNDA MUSLO + BOTAS ÁGILES ---
	_construir_pierna_articulada(att_leg_l, att_shin_l, att_foot_l, mat_ceramico, mat_acero, mat_mascara, mat_suela, mat_cuero, false, 1.0)
	_construir_pierna_articulada(att_leg_r, att_shin_r, att_foot_r, mat_ceramico, mat_acero, mat_mascara, mat_suela, mat_cuero, false, -1.0)
	att_leg_r.add_child(_st_prisma_biselado(Vector3(0.016, 0.048, 0.034), 0.003, mat_cuero, Vector3(-0.028, -0.065, 0.0)))

	_exportar_glb(escena, ruta_salida)
	escena.free()


# ==============================================================================
# 4. HÉROE: MAGO / ARÚSPICE — TECNOMAGO / ALQUIMISTA DE GUERRA (~0.675m)
# ==============================================================================

func _generar_mago(ruta_base: String, ruta_salida: String) -> void:
	print("\n>>> Esculpiendo MAGO TECNOMAGO (~0.675m)...")
	var escena: Node = (load(ruta_base) as PackedScene).instantiate()
	var bones := _preparar_esqueleto(escena, 1.0, "mage")
	var att_head: BoneAttachment3D = bones["head"]
	var att_torso: BoneAttachment3D = bones["torso"]
	var att_arm_l: BoneAttachment3D = bones["arm_l"]
	var att_forearm_l: BoneAttachment3D = bones["forearm_l"]
	var att_hand_l: BoneAttachment3D = bones["hand_l"]
	var att_arm_r: BoneAttachment3D = bones["arm_r"]
	var att_forearm_r: BoneAttachment3D = bones["forearm_r"]
	var att_hand_r: BoneAttachment3D = bones["hand_r"]
	var att_leg_l: BoneAttachment3D = bones["leg_l"]
	var att_shin_l: BoneAttachment3D = bones["shin_l"]
	var att_foot_l: BoneAttachment3D = bones["foot_l"]
	var att_leg_r: BoneAttachment3D = bones["leg_r"]
	var att_shin_r: BoneAttachment3D = bones["shin_r"]
	var att_foot_r: BoneAttachment3D = bones["foot_r"]

	var ceramico := _tex_traje_ceramico_tactico()
	var gabardina := _tex_gabardina_mago()
	var tex_ojos := _tex_rostro_ojos_visor(Color(0.75, 0.79, 0.84))
	var tex_pelo := _tex_pelo_gradiente(Color(0.68, 0.72, 0.78), Color(0.92, 0.94, 0.97))
	var vial_v := _tex_vial_liquido(Color(0.20, 0.86, 0.34))
	var vial_c := _tex_vial_liquido(Color(0.18, 0.84, 0.94))

	var mat_rostro := _mat(Color(1.0, 1.0, 1.0), 0.0, 0.65)
	mat_rostro.albedo_texture = tex_ojos
	var mat_piel := _mat(Color(0.73, 0.53, 0.40), 0.0, 0.65)
	var mat_pelo := _mat(Color(1.0, 1.0, 1.0), 0.02, 0.68)
	mat_pelo.albedo_texture = tex_pelo

	var mat_gabardina := _mat(Color(0.95, 0.96, 0.98), 0.12, 0.80, Color.BLACK, 0.0, "TierAccent")
	mat_gabardina.albedo_texture = gabardina
	mat_gabardina.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_gabardina.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat_gabardina.alpha_scissor_threshold = 0.5

	var mat_gab_opaca := _mat(Color(0.14, 0.17, 0.21), 0.12, 0.78, Color.BLACK, 0.0, "TierAccent")
	var mat_ceramico := _mat(Color(0.78, 0.80, 0.84), 0.04, 0.76)
	mat_ceramico.albedo_texture = ceramico["albedo"]
	mat_ceramico.normal_enabled = true
	mat_ceramico.normal_texture = ceramico["normal"]

	var mat_bufanda := _mat(Color(0.62, 0.27, 0.10), 0.04, 0.70)
	var mat_cuero := _mat(Color(0.22, 0.14, 0.09), 0.08, 0.60)
	var mat_metal := _mat(Color(0.24, 0.27, 0.32), 0.86, 0.30, Color.BLACK, 0.0, "TierAccent")
	var mat_cobre := _mat(Color(0.56, 0.30, 0.14), 0.84, 0.32)

	# Visor cibernético obsidiana opaco + hendidura fina cian-eléctrico
	var mat_visor_obs := _mat(Color(0.08, 0.09, 0.12), 0.88, 0.08)
	mat_visor_obs.clearcoat_enabled = true
	mat_visor_obs.clearcoat = 1.0
	var mat_visor_slit := _mat(Color(0.18, 0.88, 0.98), 0.10, 0.10, Color(0.18, 0.90, 1.00), 0.88, "TierCore")

	var mat_vial_v := _mat(Color(1.0, 1.0, 1.0), 0.10, 0.14, Color(1.0, 1.0, 1.0), 0.82, "TierCore")
	mat_vial_v.albedo_texture = vial_v["albedo"]
	mat_vial_v.emission_texture = vial_v["emission"]
	var mat_vial_c := _mat(Color(1.0, 1.0, 1.0), 0.10, 0.14, Color(1.0, 1.0, 1.0), 0.82, "TierCore")
	mat_vial_c.albedo_texture = vial_c["albedo"]
	mat_vial_c.emission_texture = vial_c["emission"]

	var mat_vidrio := _mat(Color(0.50, 0.86, 0.96, 0.34), 0.10, 0.06, Color(0.16, 0.82, 0.92), 0.25)
	mat_vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_vidrio.clearcoat_enabled = true
	mat_vidrio.clearcoat = 1.0

	var mat_core := _mat(Color(0.22, 0.92, 0.98), 0.0, 0.10, Color(0.22, 0.92, 0.98), 0.92, "TierCore")
	var mat_llama_halo := _mat(Color(0.20, 0.86, 0.96, 0.45), 0.0, 0.10, Color(0.20, 0.86, 0.96), 0.56, "TierCore")
	mat_llama_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mat_suela := _mat(Color(0.09, 0.10, 0.12), 0.15, 0.86)

	# --- 1. CABEZA ADULTA + PELO PLATINO AFILADO BARRIDO ATRÁS + VISOR OBSIDIANA + RESPIRADOR ---
	var cabeza := _construir_cabeza_base(mat_rostro, mat_piel, false)
	cabeza.name = "MagoCabeza"

	# Casco capilar blanco platino barrido atrás pegado al cráneo
	cabeza.add_child(_loft_perfil([
		{"y": 0.078, "rx": 0.047, "rz": 0.050, "z_off": 0.000, "bevel": 0.32},
		{"y": 0.104, "rx": 0.046, "rz": 0.049, "z_off": -0.002, "bevel": 0.32},
		{"y": 0.122, "rx": 0.026, "rz": 0.032, "z_off": -0.004, "bevel": 0.24},
		{"y": 0.129, "rx": 0.004, "rz": 0.004, "z_off": -0.006, "bevel": 0.10},
	], mat_pelo, 18, true))
	var mechones_mago := [
		[Vector3(-0.020, 0.100, 0.031), Vector3(-0.023, 0.115, -0.002), Vector3(-0.023, 0.116, -0.034)],
		[Vector3(-0.009, 0.102, 0.034), Vector3(-0.011, 0.117, -0.002), Vector3(-0.012, 0.118, -0.038)],
		[Vector3(0.009, 0.102, 0.034), Vector3(0.011, 0.117, -0.002), Vector3(0.012, 0.118, -0.038)],
		[Vector3(0.020, 0.100, 0.031), Vector3(0.023, 0.115, -0.002), Vector3(0.023, 0.116, -0.034)],
		[Vector3(0.0, 0.110, 0.004), Vector3(0.002, 0.120, -0.024), Vector3(0.003, 0.114, -0.050)],
	]
	for pts_raw in mechones_mago:
		var pts: Array[Vector3] = [pts_raw[0], pts_raw[1], pts_raw[2]]
		cabeza.add_child(_st_mechon_pelo(pts, 0.011, 0.007, mat_pelo))

	# Visor cibernético obsidiana opaco + hendidura cian-eléctrico estrecha proyectados sobre los ojos
	var visor_mago := Node3D.new()
	visor_mago.position = Vector3(0.0, 0.0, 0.011)
	cabeza.add_child(visor_mago)
	visor_mago.add_child(_st_arco_curvo(0.053, 0.008, 0.056, 0.077, -52.0, 52.0, mat_visor_obs, 16))
	visor_mago.add_child(_st_arco_curvo(0.0575, 0.003, 0.064, 0.070, -44.0, 44.0, mat_visor_slit, 16))
	cabeza.add_child(_st_arco_curvo(0.050, 0.004, 0.062, 0.072, 44.0, 316.0, mat_cuero, 16))

	# Respirador mandibular en titanio oscuro
	cabeza.add_child(_st_arco_curvo(0.047, 0.010, 0.008, 0.042, -46.0, 46.0, mat_metal, 14))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.034, 0.028, 0.018), 0.004, mat_metal, Vector3(0.0, 0.024, 0.051), Vector3(12.0, 0.0, 0.0), Vector2(0.75, 0.85), 8))
	cabeza.add_child(_st_prisma_biselado(Vector3(0.014, 0.018, 0.010), 0.002, mat_bufanda, Vector3(0.0, 0.026, 0.059), Vector3(12.0, 0.0, 0.0)))
	att_head.add_child(cabeza)

	# --- 2. TORSO (INTERIOR CERÁMICO + GABARDINA LARGA CARBÓN-OBSIDIANA EN C + VIALES) ---
	var torso := Node3D.new()
	torso.name = "MagoTorso"
	torso.add_child(_construir_torso_base(mat_ceramico, false))

	# Cuello alto rígido de gabardina y solapas en V + hombreras angulosas
	torso.add_child(_torus_suave(0.050, 0.014, mat_bufanda, Vector3(0.0, 0.220, 0.014), Vector3(82.0, 0.0, 0.0), Vector3(1.0, 0.90, 1.0)))
	var cuello_abrigo := _st_arco_curvo(0.064, 0.012, 0.190, 0.258, 92.0, 268.0, mat_gab_opaca, 16)
	cuello_abrigo.position = Vector3(0.0, 0.0, 0.014)
	torso.add_child(cuello_abrigo)
	for sx: float in [-1.0, 1.0]:
		torso.add_child(_st_prisma_biselado(Vector3(0.034, 0.150, 0.018), 0.004, mat_gab_opaca, Vector3(sx * 0.062, 0.128, 0.054), Vector3(-5.0, sx * -22.0, sx * -10.0)))
		torso.add_child(_st_hombrera_curva(0.044, 0.010, 0.036, 120.0, mat_metal, Vector3(sx * 0.112, 0.190, 0.006), Vector3(0.0, sx * 90.0, sx * -8.0)))

	# Cuerpo de gabardina alrededor de espalda/costados + faldón largo hasta media pantorrilla (-0.205m)
	var cuerpo_abrigo := _st_arco_curvo(0.090, 0.014, 0.025, 0.205, 52.0, 308.0, mat_gab_opaca, 18)
	cuerpo_abrigo.position = Vector3(0.0, 0.0, 0.008)
	torso.add_child(cuerpo_abrigo)
	torso.add_child(_st_abrigo_abierto(0.045, -0.205, 0.084, 0.060, 0.122, 0.095, 46.0, 314.0, mat_gabardina))

	# Bandolera curva por fuera del pecho con 2 viales verdes + cinturón con 4 viales
	torso.add_child(_st_tubo_curvo([
		Vector3(-0.070, 0.205, 0.062),
		Vector3(-0.026, 0.148, 0.088),
		Vector3(0.026, 0.088, 0.085),
		Vector3(0.066, 0.026, 0.066),
	], 0.011, 0.010, mat_cuero, 8))
	for i in range(2):
		torso.add_child(_cyl_suave(0.007, 0.007, 0.030, mat_vial_v, Vector3(-0.016 + float(i) * 0.026, 0.142 - float(i) * 0.028, 0.094), Vector3(0.0, 0.0, -34.0), 10))
	torso.add_child(_st_arco_curvo(0.068, 0.016, -0.004, 0.024, -180.0, 180.0, mat_cuero, 18))
	torso.add_child(_st_prisma_biselado(Vector3(0.032, 0.024, 0.014), 0.003, mat_metal, Vector3(0.0, 0.010, 0.072)))
	for i in range(3):
		torso.add_child(_cyl_suave(0.0065, 0.0065, 0.036, mat_vial_v, Vector3(-0.034 - float(i) * 0.016, -0.010, 0.064 - float(i) * 0.006), Vector3(8.0, 0.0, -10.0), 10))
	torso.add_child(_cyl_suave(0.0075, 0.0075, 0.038, mat_vial_c, Vector3(0.056, -0.010, 0.056), Vector3(8.0, 0.0, 12.0), 10))

	att_torso.add_child(torso)

	# --- 3. BRAZOS ARTICULADOS EN ±X + LLAMA ARCANA EN MANO IZQ + BÁCULO EN MANO DER ---
	_construir_brazo_articulado(1.0, att_arm_l, att_forearm_l, att_hand_l, mat_ceramico, mat_metal, mat_metal, mat_cuero, false)
	_construir_brazo_articulado(-1.0, att_arm_r, att_forearm_r, att_hand_r, mat_ceramico, mat_metal, mat_metal, mat_cuero, false)

	var fuego := Node3D.new()
	fuego.name = "FuegoArcano"
	fuego.position = Vector3(0.018, 0.008, 0.016)
	for f_idx in range(3):
		var fl := _st_llama_espiral(0.048, 0.019, 0.90, mat_core)
		fl.rotation_degrees = Vector3(0.0, float(f_idx) * 120.0, 0.0)
		fuego.add_child(fl)
	fuego.add_child(_esfera_suave(0.024, mat_llama_halo, Vector3(0.0, 0.018, 0.0), Vector3(1.0, 1.35, 1.0), 12, 8))
	att_hand_l.add_child(fuego)

	var baston := Node3D.new()
	baston.name = "BastonPlasma"
	baston.position = Vector3(-0.016, -0.005, 0.014)
	baston.rotation_degrees = Vector3(80.0, 45.0, 0.0)
	baston.add_child(_cyl_suave(0.011, 0.012, 0.49, mat_metal, Vector3(0, 0.06, 0), Vector3.ZERO, 10))
	baston.add_child(_cyl_suave(0.014, 0.014, 0.12, mat_cuero, Vector3(0, 0.0, 0), Vector3.ZERO, 10))
	baston.add_child(_esfera_suave(0.015, mat_cobre, Vector3(0, -0.185, 0)))
	baston.add_child(_cyl_suave(0.022, 0.017, 0.028, mat_cobre, Vector3(0, 0.255, 0), Vector3.ZERO, 12))
	for my: float in [0.215, 0.238]:
		baston.add_child(_cyl_suave(0.011, 0.011, 0.010, mat_cobre, Vector3(0.018, my, 0.0), Vector3(0, 0, 90), 10))
	for side: float in [-1.0, 1.0]:
		baston.add_child(_st_tubo_curvo([
			Vector3(side * 0.012, 0.14, 0.0),
			Vector3(side * 0.026, 0.18, side * 0.014),
			Vector3(side * 0.022, 0.22, 0.008),
			Vector3(side * 0.016, 0.26, 0.0),
		], 0.0032, 0.0032, mat_cobre, 6))
	baston.add_child(_cyl_suave(0.036, 0.026, 0.022, mat_metal, Vector3(0, 0.280, 0), Vector3.ZERO, 14))
	baston.add_child(_cyl_suave(0.024, 0.036, 0.024, mat_metal, Vector3(0, 0.395, 0), Vector3.ZERO, 14))
	baston.add_child(_cyl_suave(0.014, 0.014, 0.018, mat_cobre, Vector3(0, 0.412, 0), Vector3.ZERO, 10))
	for i in range(4):
		var a := float(i) * PI * 0.5 + PI * 0.25
		baston.add_child(_cyl_suave(0.004, 0.004, 0.112, mat_metal, Vector3(cos(a) * 0.032, 0.338, sin(a) * 0.032), Vector3.ZERO, 6))
	baston.add_child(_cyl_suave(0.025, 0.025, 0.095, mat_vidrio, Vector3(0, 0.338, 0), Vector3.ZERO, 14))
	var esp_baculo := _st_llama_espiral(0.082, 0.015, 1.2, mat_core)
	esp_baculo.position = Vector3(0, 0.296, 0)
	baston.add_child(esp_baculo)
	att_hand_r.add_child(baston)

	# --- 4. PIERNAS ARTICULADAS CERÁMICO-GRIS + BOTAS BLINDADAS ---
	_construir_pierna_articulada(att_leg_l, att_shin_l, att_foot_l, mat_ceramico, mat_metal, mat_gab_opaca, mat_suela, mat_cuero, false, 1.0)
	_construir_pierna_articulada(att_leg_r, att_shin_r, att_foot_r, mat_ceramico, mat_metal, mat_gab_opaca, mat_suela, mat_cuero, false, -1.0)

	_exportar_glb(escena, ruta_salida)
	escena.free()
