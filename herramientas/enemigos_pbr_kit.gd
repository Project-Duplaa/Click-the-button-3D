@tool
class_name EnemigosPBRKit
extends RefCounted

## ==============================================================================
## KIT MAESTRO PBR Y ESCULPIDO PARA LOS 16 ENEMIGOS DEL COLISEO (GODOT 4.7.2)
## - Estética unificada "Coliseo Industrial / Bio-Contención Táctica PBR"
## - Reglas estrictas anti-brillo: metallic <= 0.62, roughness >= 0.36,
##   emisivos solo en micro-acentos <= 0.68 y rim_enabled = false dentro del .glb
## - Orientación nativa hacia -Z mediante RigVisual rotado 180° en Y
## - Base apoyada en y = 0.0 y animaciones glTF-compatibles (Position/Rotation/Scale)
## ==============================================================================


# ==============================================================================
# 1. RUIDO DETERMINISTA Y GENERADORES DE TEXTURAS PROCEDURALES (256x256 ALBEDO + NORMAL)
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


static func _ruido_fbm(u: float, v: float, freq: float, seed_val: int = 1337) -> float:
	return _suave_ruido(u, v, freq, seed_val) * 0.65 + _suave_ruido(u, v, freq * 2.3, seed_val + 17) * 0.35


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


static func tex_acero_bunker(tint: Color = Color(0.20, 0.23, 0.28), seed_val: int = 303) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_base := tint
	var c_hollin := tint.darkened(0.45)
	var c_oxido := Color(0.32, 0.20, 0.14)
	var c_bisel := tint.lightened(0.26)

	var remaches := [
		Vector2(0.11, 0.11), Vector2(0.89, 0.11),
		Vector2(0.11, 0.89), Vector2(0.89, 0.89),
		Vector2(0.11, 0.50), Vector2(0.89, 0.50),
		Vector2(0.50, 0.11), Vector2(0.50, 0.89),
	]

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var ruido := _ruido_fbm(u, v, 10.0, seed_val)
			var col := c_base.lerp(c_hollin, clampf((ruido - 0.35) * 1.4, 0.0, 0.72))
			var hv := 0.50 + (ruido - 0.5) * 0.12

			# Costura central de panel y borde biselado
			var borde := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
			if borde < 0.068:
				col = col.lerp(c_oxido, 0.38 * _suave_ruido(u, v, 15.0, seed_val + 11))
				if borde < 0.022:
					col = col.lerp(c_bisel, 0.45)
					hv = 0.60
				elif absf(borde - 0.060) < 0.008:
					col = c_hollin
					hv = 0.24
			if absf(u - 0.50) < 0.006 or absf(v - 0.50) < 0.006:
				col = c_hollin
				hv = 0.28

			# Rasguños metálicos discretos
			for r_idx in range(4):
				var ax := 0.18 + float(r_idx) * 0.17
				var ay := 0.20 + float(r_idx % 2) * 0.35
				if _dist_segmento(u, v, ax, ay, ax + 0.15, ay + 0.10) < 0.0045:
					col = c_bisel
					hv = 0.22

			# 8 Remaches en relieve
			for rem in remaches:
				var dr := Vector2(u - rem.x, v - rem.y).length()
				if dr < 0.026:
					if dr > 0.019:
						col = c_hollin
						hv = 0.22
					else:
						col = c_bisel if (v < rem.y) else c_base
						hv = 0.88 - dr * 7.0

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(2.1)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_bronce_oxidado(tint: Color = Color(0.52, 0.38, 0.20), seed_val: int = 419) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_osc := tint.darkened(0.42)
	var c_patina := Color(0.20, 0.31, 0.27)
	var c_borde := tint.lightened(0.18)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _ruido_fbm(u, v, 9.0, seed_val)
			var n2 := _suave_ruido(u, v, 20.0, seed_val + 31)
			var col := tint.lerp(c_osc, clampf(n * 0.78, 0.0, 1.0))
			var hv := 0.50 + (n - 0.5) * 0.14

			# Pátina verdosa oxidada en juntas y bordes
			var borde := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
			if borde < 0.095 or n2 > 0.72:
				var factor_p := clampf((0.095 - borde) * 6.5 if borde < 0.095 else (n2 - 0.72) * 2.4, 0.0, 0.55)
				col = col.lerp(c_patina, factor_p)
				hv -= factor_p * 0.08
			if borde < 0.025:
				col = col.lerp(c_borde, 0.35)
				hv = 0.62

			# Remaches en esquinas
			for rx in [0.12, 0.88]:
				for ry in [0.12, 0.88]:
					var dr := Vector2(u - rx, v - ry).length()
					if dr < 0.028:
						col = c_osc if dr > 0.020 else c_borde
						hv = 0.24 if dr > 0.020 else 0.86

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(2.2)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_hazard_desgastado(seed_val: int = 507) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_amarillo := Color(0.68, 0.50, 0.09)
	var c_negro := Color(0.09, 0.10, 0.12)
	var c_rasguno := Color(0.42, 0.45, 0.48)
	var c_polvo := Color(0.22, 0.19, 0.16)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var stripe: int = int(floor(float(x + y) / 32.0)) % 2
			var n := _ruido_fbm(u, v, 12.0, seed_val)
			var col := c_amarillo if stripe == 0 else c_negro
			col = col.lerp(c_polvo, clampf(n * 0.42, 0.0, 0.42))
			var hv := 0.50 + (n - 0.5) * 0.12

			if v < 0.08 or v > 0.92:
				col = col.lerp(c_polvo, 0.60)
				hv = 0.40
			if _dist_segmento(u, v, 0.16, 0.22, 0.38, 0.72) < 0.011 or _dist_segmento(u, v, 0.62, 0.24, 0.84, 0.70) < 0.010:
				col = c_rasguno
				hv = 0.25

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(1.6)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_tela_tactica(base_col: Color, shadow_col: Color, grime_col: Color, con_desgarro: bool = false, seed_val: int = 611) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_costura := base_col.lightened(0.16)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _ruido_fbm(u, v, 11.0, seed_val)
			var trama := 0.5 + 0.5 * sin(u * 90.0) * sin(v * 90.0)
			var col := base_col.lerp(shadow_col, clampf(n * 0.78, 0.0, 1.0))
			col = col.lerp(shadow_col, trama * 0.12)
			var hv := 0.50 + trama * 0.08 + (n - 0.5) * 0.12

			if u < 0.032 or u > 0.968:
				col = c_costura
				hv = 0.62
			if v > 0.72:
				col = col.lerp(grime_col, clampf((v - 0.72) * 2.5 * n, 0.0, 0.58))

			if con_desgarro:
				var corte := 0.86 + 0.10 * absf(sin(u * PI * 6.0 + 0.5)) + 0.03 * _hash2(x / 8, 9, seed_val)
				col.a = 0.0 if v > corte else 1.0

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(1.4)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_basalto_hormigon(tint: Color = Color(0.20, 0.21, 0.20), con_veta_jade: bool = false, seed_val: int = 727) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_osc := tint.darkened(0.45)
	var c_claro := tint.lightened(0.20)
	var c_jade := Color(0.11, 0.34, 0.20)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _ruido_fbm(u, v, 8.0, seed_val)
			var grieta := absf(_suave_ruido(u, v, 14.0, seed_val + 9) - 0.5)
			var col := tint.lerp(c_osc, clampf(n * 0.8, 0.0, 1.0))
			var hv := 0.55 + (n - 0.5) * 0.22

			if grieta < 0.028:
				col = c_jade if (con_veta_jade and grieta < 0.012) else c_osc
				hv = 0.18
			elif n > 0.72:
				col = col.lerp(c_claro, 0.35)
				hv = 0.72

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(2.5)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_quitina_bio(base_col: Color = Color(0.15, 0.19, 0.14), seed_val: int = 833) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_surco := base_col.darkened(0.50)
	var c_cresta := base_col.lightened(0.18)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _ruido_fbm(u, v, 10.0, seed_val)
			var banda := absf(sin(v * PI * 7.0 + _suave_ruido(u, v, 6.0, seed_val) * 1.4))
			var col := base_col.lerp(c_surco, clampf((1.0 - banda) * 0.65 + n * 0.25, 0.0, 1.0))
			var hv := 0.42 + banda * 0.30 + (n - 0.5) * 0.10
			if banda > 0.88:
				col = col.lerp(c_cresta, 0.30)

			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(1.9)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_hueso_ceramico(seed_val: int = 919) -> Dictionary:
	var w := 256
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var img_h := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_base := Color(0.72, 0.69, 0.62)
	var c_sombra := Color(0.46, 0.42, 0.36)
	var c_fisura := Color(0.20, 0.18, 0.16)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var n := _ruido_fbm(u, v, 9.0, seed_val)
			var col := c_base.lerp(c_sombra, clampf(n * 0.65, 0.0, 1.0))
			var hv := 0.55 + (n - 0.5) * 0.12
			if _dist_segmento(u, v, 0.28, 0.18, 0.44, 0.48) < 0.006 or _dist_segmento(u, v, 0.68, 0.55, 0.78, 0.82) < 0.005:
				col = c_fisura
				hv = 0.20
			img_a.set_pixel(x, y, col)
			img_h.set_pixel(x, y, Color(hv, hv, hv, 1.0))

	img_h.bump_map_to_normal_map(1.5)
	return {"albedo": _finalizar_textura(img_a), "normal": _finalizar_textura(img_h)}


static func tex_rodillo_jackpot() -> Dictionary:
	var w := 128
	var h := 256
	var img_a := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c_marfil := Color(0.76, 0.73, 0.65)
	var c_borde := Color(0.32, 0.28, 0.22)
	var c_siete := Color(0.62, 0.11, 0.14)

	for y in range(h):
		var v: float = float(y) / float(h - 1)
		for x in range(w):
			var u: float = float(x) / float(w - 1)
			var col := c_marfil
			if u < 0.08 or u > 0.92:
				col = c_borde
			# Repetir dígitos "7" en 4 franjas verticales alrededor del cilindro
			var v_loc := fmod(v * 4.0, 1.0)
			if v_loc > 0.22 and v_loc < 0.78:
				var d_top := _dist_segmento(u, v_loc, 0.28, 0.28, 0.72, 0.28)
				var d_diag := _dist_segmento(u, v_loc, 0.70, 0.28, 0.40, 0.74)
				if d_top < 0.065 or d_diag < 0.065:
					col = c_siete
			img_a.set_pixel(x, y, col)

	return {"albedo": _finalizar_textura(img_a)}


# ==============================================================================
# 2. FÁBRICAS DE MATERIALES PBR CON TOPES ANTI-BRILLO ESTRICTOS
# ==============================================================================

static func mat_pbr(
	albedo: Color,
	metallic: float = 0.45,
	roughness: float = 0.52,
	tex_dict: Dictionary = {},
	alpha: float = 1.0,
	double_sided: bool = false
) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(albedo.r, albedo.g, albedo.b, clampf(alpha, 0.0, 1.0))
	m.metallic = clampf(metallic, 0.0, 0.62)
	m.roughness = clampf(roughness, 0.36, 0.95)
	m.rim_enabled = false
	m.emission_enabled = false

	if tex_dict.has("albedo") and tex_dict["albedo"] is Texture2D:
		m.albedo_texture = tex_dict["albedo"] as Texture2D
		if alpha < 0.999:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	elif alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	if tex_dict.has("normal") and tex_dict["normal"] is Texture2D:
		m.normal_enabled = true
		m.normal_texture = tex_dict["normal"] as Texture2D
		m.normal_scale = 0.85

	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func mat_emissive(
	albedo: Color,
	emission_col: Color,
	energy: float = 0.45,
	roughness: float = 0.30,
	alpha: float = 1.0
) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(albedo.r, albedo.g, albedo.b, clampf(alpha, 0.0, 1.0))
	m.metallic = 0.12
	m.roughness = clampf(roughness, 0.20, 0.85)
	m.rim_enabled = false
	m.emission_enabled = true
	m.emission = emission_col
	m.emission_energy_multiplier = clampf(energy, 0.08, 0.68)
	if alpha < 0.999:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


# ==============================================================================
# 3. CONSTRUCTORES GEOMÉTRICOS (SurfaceTool / Primitivos con Material Directo)
# ==============================================================================

static func _eval_superelipse(ang: float, rx: float, rz: float, bevel: float) -> Vector2:
	var sx := sin(ang)
	var cz := cos(ang)
	var p := lerpf(1.0, 0.36, clampf(bevel, 0.0, 1.0))
	var px: float = (1.0 if sx >= 0.0 else -1.0) * pow(absf(sx), p) * rx
	var pz: float = (1.0 if cz >= 0.0 else -1.0) * pow(absf(cz), p) * rz
	return Vector2(px, pz)


static func _agregar_quad_cw(st: SurfaceTool, v00: Vector3, v10: Vector3, v01: Vector3, v11: Vector3, uv00: Vector2, uv10: Vector2, uv01: Vector2, uv11: Vector2) -> void:
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


static func _agregar_anillos_outward(st: SurfaceTool, rings: Array, centers: Array, segs: int, v_ini: float = 0.0, v_fin: float = 1.0) -> void:
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


static func _commit_mesh(st: SurfaceTool, mat: Material) -> MeshInstance3D:
	st.index()
	st.generate_normals()
	var arr_mesh := st.commit()
	if mat != null and arr_mesh.get_surface_count() > 0:
		arr_mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = arr_mesh
	return mi


static func loft_perfil(secciones: Array, mat: Material, segs: int = 16, cerrar_tapas: bool = true, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
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

	var mi := _commit_mesh(st, mat)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func prisma_biselado(size: Vector3, bevel_xy: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, taper_top: Vector2 = Vector2.ONE, segs: int = 16) -> MeshInstance3D:
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
	return loft_perfil(secs, mat, segs, true, pos, rot_deg)


static func arco_curvo(r_medio: float, espesor: float, y_bot: float, y_top: float, ang_ini_deg: float, ang_fin_deg: float, mat: Material, segs: int = 14) -> MeshInstance3D:
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
		_agregar_quad_cw(st, pts_out_b[j], pts_out_t[j], pts_out_b[j + 1], pts_out_t[j + 1], Vector2(u0, 1.0), Vector2(u0, 0.0), Vector2(u1, 1.0), Vector2(u1, 0.0))
		_agregar_quad_cw(st, pts_in_b[j + 1], pts_in_t[j + 1], pts_in_b[j], pts_in_t[j], Vector2(u1, 1.0), Vector2(u1, 0.0), Vector2(u0, 1.0), Vector2(u0, 0.0))
		_agregar_quad_cw(st, pts_out_t[j], pts_in_t[j], pts_out_t[j + 1], pts_in_t[j + 1], Vector2(u0, 0.0), Vector2(u0, 0.2), Vector2(u1, 0.0), Vector2(u1, 0.2))
		_agregar_quad_cw(st, pts_in_b[j], pts_out_b[j], pts_in_b[j + 1], pts_out_b[j + 1], Vector2(u0, 0.8), Vector2(u0, 1.0), Vector2(u1, 0.8), Vector2(u1, 1.0))

	_agregar_quad_cw(st, pts_in_b[0], pts_in_t[0], pts_out_b[0], pts_out_t[0], Vector2(0, 1), Vector2(0, 0), Vector2(0.1, 1), Vector2(0.1, 0))
	_agregar_quad_cw(st, pts_out_b[segs], pts_out_t[segs], pts_in_b[segs], pts_in_t[segs], Vector2(0.9, 1), Vector2(0.9, 0), Vector2(1, 1), Vector2(1, 0))

	return _commit_mesh(st, mat)


static func hombrera_curva(radio: float, grosor: float, alto: float, arco_deg: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := arco_curvo(radio, grosor, -alto * 0.5, alto * 0.5, -arco_deg * 0.5, arco_deg * 0.5, mat, 12)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func tubo_curvo(puntos: Array, r_ini: float, r_fin: float, mat: Material, segs: int = 8) -> MeshInstance3D:
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
	return _commit_mesh(st, mat)


static func hoja_filo(largo: float, ancho_base: float, grosor: float, curvatura_x: float, mat: Material, segs_y: int = 8, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var centers: Array[Vector3] = []

	for i in range(segs_y + 1):
		var t := float(i) / float(segs_y)
		var y := t * largo
		var x_c := curvatura_x * (t * t)
		var w := ancho_base * (1.0 - pow(t, 1.45) * 0.92)
		var g := grosor * (1.0 - t * 0.85)
		var c := Vector3(x_c, y, 0.0)
		centers.append(c)
		# Sección rómbica de doble bisel (4 vértices + cierre)
		var ring: Array[Vector3] = [
			c + Vector3(w * 0.5, 0.0, 0.0),
			c + Vector3(0.0, 0.0, g * 0.5),
			c + Vector3(-w * 0.5, 0.0, 0.0),
			c + Vector3(0.0, 0.0, -g * 0.5),
			c + Vector3(w * 0.5, 0.0, 0.0),
		]
		rings.append(ring)

	_agregar_anillos_outward(st, rings, centers, 4, 0.0, 1.0)
	var mi := _commit_mesh(st, mat)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func capa_colgante(
	y_top: float,
	y_bot: float,
	rx_top: float,
	rz_top: float,
	rx_bot: float,
	rz_bot: float,
	ang_ini_deg: float,
	ang_fin_deg: float,
	mat: Material,
	tatter_amp: float = 0.06
) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := 7
	var cols := 18
	var a0 := deg_to_rad(ang_ini_deg)
	var a1 := deg_to_rad(ang_fin_deg)
	var grid: Array = []

	for iy in range(rows + 1):
		var v := float(iy) / float(rows)
		var y_base := lerpf(y_top, y_bot, v)
		var rx := lerpf(rx_top, rx_bot, v * 0.85 + 0.15 * v * v)
		var rz := lerpf(rz_top, rz_bot, v * 0.85 + 0.15 * v * v)
		var z_tail := -0.08 * v * v
		var row: Array[Vector3] = []
		for ix in range(cols + 1):
			var u := float(ix) / float(cols)
			var a := lerpf(a0, a1, u)
			var onda := sin(u * PI * 7.0) * tatter_amp * v * v
			var pliegue := 1.0 + 0.05 * sin(u * PI * 10.0) * v
			row.append(Vector3(sin(a) * rx * pliegue, y_base + onda, cos(a) * rz * pliegue + z_tail))
		grid.append(row)

	for iy in range(rows):
		var v0 := float(iy) / float(rows)
		var v1 := float(iy + 1) / float(rows)
		for ix in range(cols):
			var u0 := float(ix) / float(cols)
			var u1 := float(ix + 1) / float(cols)
			_agregar_quad_cw(st, grid[iy + 1][ix], grid[iy][ix], grid[iy + 1][ix + 1], grid[iy][ix + 1], Vector2(u0, v1), Vector2(u0, v0), Vector2(u1, v1), Vector2(u1, v0))

	return _commit_mesh(st, mat)


static func cyl(rt: float, rb: float, h: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, segs: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = segs
	c.material = mat
	mi.mesh = c
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


static func esfera(r: float, mat: Material, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, segs: int = 16, rings: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	s.material = mat
	mi.mesh = s
	mi.position = pos
	mi.scale = scl
	return mi


static func toro(r_ext: float, r_int: float, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, segs: int = 18) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.outer_radius = r_ext
	t.inner_radius = r_int
	t.rings = segs
	t.ring_segments = 10
	t.material = mat
	mi.mesh = t
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	return mi


static func caja(size: Vector3, mat: Material, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	mi.mesh = b
	mi.position = pos
	mi.rotation_degrees = rot_deg
	return mi


# ==============================================================================
# 4. ENSAMBLAJE, ORIENTACIÓN -Z, SUELO Y = 0 Y EXPORTACIÓN GLB
# ==============================================================================

static func crear_raiz_enemigo(nombre: String) -> Dictionary:
	var raiz := Node3D.new()
	raiz.name = nombre
	var rig := Node3D.new()
	rig.name = "RigVisual"
	# Esculpimos en +Z (frente intuitivo); rotar 180° en Y alinea el frente real con -Z (look_at)
	rig.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	raiz.add_child(rig)
	return {"raiz": raiz, "rig": rig}


static func calcular_aabb_raiz(nodo: Node, xform_actual: Transform3D = Transform3D.IDENTITY) -> AABB:
	var xf := xform_actual
	if nodo is Node3D and nodo.get_parent() != null:
		xf = xform_actual * (nodo as Node3D).transform
	var res := AABB()
	var tiene := false
	if nodo is MeshInstance3D:
		var mi := nodo as MeshInstance3D
		if mi.mesh != null:
			res = xf * mi.mesh.get_aabb()
			tiene = true
	for hijo in nodo.get_children():
		var h_box := calcular_aabb_raiz(hijo, xf)
		if h_box.size != Vector3.ZERO or h_box.position != Vector3.ZERO:
			if not tiene:
				res = h_box
				tiene = true
			else:
				res = res.merge(h_box)
	return res


static func normalizar_base_suelo(rig: Node3D) -> float:
	if rig == null or rig.get_parent() == null:
		return 0.0
	rig.position.y = 0.0
	var aabb := calcular_aabb_raiz(rig, Transform3D.IDENTITY)
	rig.position.y = -aabb.position.y
	return aabb.size.y


static func fijar_dueno_recursivo(nodo: Node, raiz: Node) -> void:
	for hijo in nodo.get_children():
		hijo.owner = raiz
		fijar_dueno_recursivo(hijo, raiz)


static func exportar_glb(raiz: Node3D, ruta_glb: String) -> float:
	var rig := raiz.get_node_or_null("RigVisual") as Node3D
	var altura := 0.0
	if rig != null:
		altura = normalizar_base_suelo(rig)
	else:
		altura = calcular_aabb_raiz(raiz, Transform3D.IDENTITY).size.y

	fijar_dueno_recursivo(raiz, raiz)

	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_scene(raiz, state)
	if err != OK:
		printerr("ERROR serializando GLB %s: %d" % [ruta_glb, err])
		return altura
	err = gltf.write_to_filesystem(state, ruta_glb)
	if err != OK:
		printerr("ERROR escribiendo GLB %s: %d" % [ruta_glb, err])
		return altura

	var bytes := FileAccess.get_file_as_bytes(ruta_glb).size()
	print("  ✓ Exportado: %s | altura=%.2fm | %d bytes" % [ruta_glb, altura, bytes])
	return altura


# ==============================================================================
# 5. ANIMACIONES PROCEDURALES GLTF-COMPATIBLES (POSITION_3D / ROTATION_3D / SCALE_3D)
# ==============================================================================

static func _crear_anim_lib(raiz: Node3D) -> AnimationLibrary:
	var prev := raiz.get_node_or_null("AnimationPlayer")
	if prev != null:
		raiz.remove_child(prev)
		prev.free()
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	raiz.add_child(ap)
	var lib := AnimationLibrary.new()
	ap.add_animation_library("", lib)
	return lib


static func _add_rot_keys(anim: Animation, raiz: Node3D, node: Node3D, keys: Array) -> void:
	if node == null or not raiz.is_ancestor_of(node):
		return
	var p := String(raiz.get_path_to(node))
	var t := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, NodePath(p))
	var q_base: Quaternion = node.quaternion
	for k in keys:
		var tm: float = float(k[0])
		var eul_deg: Vector3 = k[1] as Vector3
		var q_off := Quaternion.from_euler(Vector3(deg_to_rad(eul_deg.x), deg_to_rad(eul_deg.y), deg_to_rad(eul_deg.z)))
		anim.rotation_track_insert_key(t, tm, (q_base * q_off).normalized())


static func _add_pos_keys(anim: Animation, raiz: Node3D, node: Node3D, keys: Array) -> void:
	if node == null or not raiz.is_ancestor_of(node):
		return
	var p := String(raiz.get_path_to(node))
	var t := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t, NodePath(p))
	var p_base: Vector3 = node.position
	for k in keys:
		var tm: float = float(k[0])
		var off: Vector3 = k[1] as Vector3
		anim.position_track_insert_key(t, tm, p_base + off)


static func _add_scl_keys(anim: Animation, raiz: Node3D, node: Node3D, keys: Array) -> void:
	if node == null or not raiz.is_ancestor_of(node):
		return
	var p := String(raiz.get_path_to(node))
	var t := anim.add_track(Animation.TYPE_SCALE_3D)
	anim.track_set_path(t, NodePath(p))
	var s_base: Vector3 = node.scale
	for k in keys:
		var tm: float = float(k[0])
		var mult: Vector3 = k[1] as Vector3
		anim.scale_track_insert_key(t, tm, Vector3(s_base.x * mult.x, s_base.y * mult.y, s_base.z * mult.z))


static func _registrar_clip(lib: AnimationLibrary, nombre: String, dur: float, bucle: bool) -> Animation:
	var a := Animation.new()
	a.length = dur
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	lib.add_animation(nombre, a)
	return a


static func agregar_animaciones_bipedo(raiz: Node3D, rig: Node3D, amp_paso: float = 28.0) -> void:
	var lib := _crear_anim_lib(raiz)
	var torso := rig.get_node_or_null("Torso") as Node3D
	var cabeza := rig.find_child("Cabeza", true, false) as Node3D
	var brazo_l := rig.find_child("BrazoIzq", true, false) as Node3D
	var brazo_r := rig.find_child("BrazoDer", true, false) as Node3D
	var pierna_l := rig.get_node_or_null("PiernaIzq") as Node3D
	var pierna_r := rig.get_node_or_null("PiernaDer") as Node3D
	var alas := rig.find_child("Alas", true, false) as Node3D
	var sl: float = (1.0 if brazo_l != null and brazo_l.position.x >= 0.0 else -1.0)
	var sr: float = (1.0 if brazo_r != null and brazo_r.position.x >= 0.0 else -1.0)

	# IDLE (2.0s)
	var idle := _registrar_clip(lib, "idle", 2.0, true)
	_add_pos_keys(idle, raiz, torso, [[0.0, Vector3.ZERO], [1.0, Vector3(0, 0.035, 0)], [2.0, Vector3.ZERO]])
	_add_rot_keys(idle, raiz, cabeza, [[0.0, Vector3.ZERO], [1.0, Vector3(2.5, 4.0, 0)], [2.0, Vector3.ZERO]])
	_add_rot_keys(idle, raiz, brazo_l, [[0.0, Vector3(0, 0, sl * 4.0)], [1.0, Vector3(4, 0, sl * 7.0)], [2.0, Vector3(0, 0, sl * 4.0)]])
	_add_rot_keys(idle, raiz, brazo_r, [[0.0, Vector3(0, 0, sr * 4.0)], [1.0, Vector3(-4, 0, sr * 7.0)], [2.0, Vector3(0, 0, sr * 4.0)]])
	if alas != null:
		_add_rot_keys(idle, raiz, alas, [[0.0, Vector3.ZERO], [1.0, Vector3(-5, 0, 0)], [2.0, Vector3.ZERO]])

	# WALK (0.8s)
	var walk := _registrar_clip(lib, "walk", 0.8, true)
	_add_pos_keys(walk, raiz, torso, [[0.0, Vector3.ZERO], [0.2, Vector3(0, 0.04, 0)], [0.4, Vector3.ZERO], [0.6, Vector3(0, 0.04, 0)], [0.8, Vector3.ZERO]])
	_add_rot_keys(walk, raiz, torso, [[0.0, Vector3(4, -4, 0)], [0.4, Vector3(4, 4, 0)], [0.8, Vector3(4, -4, 0)]])
	_add_rot_keys(walk, raiz, pierna_l, [[0.0, Vector3(amp_paso, 0, 0)], [0.4, Vector3(-amp_paso, 0, 0)], [0.8, Vector3(amp_paso, 0, 0)]])
	_add_rot_keys(walk, raiz, pierna_r, [[0.0, Vector3(-amp_paso, 0, 0)], [0.4, Vector3(amp_paso, 0, 0)], [0.8, Vector3(-amp_paso, 0, 0)]])
	_add_rot_keys(walk, raiz, brazo_l, [[0.0, Vector3(-amp_paso * 0.6, 0, sl * 5.0)], [0.4, Vector3(amp_paso * 0.6, 0, sl * 5.0)], [0.8, Vector3(-amp_paso * 0.6, 0, sl * 5.0)]])
	_add_rot_keys(walk, raiz, brazo_r, [[0.0, Vector3(amp_paso * 0.6, 0, sr * 5.0)], [0.4, Vector3(-amp_paso * 0.6, 0, sr * 5.0)], [0.8, Vector3(amp_paso * 0.6, 0, sr * 5.0)]])

	# RUN / SPRINT (0.56s)
	for clip_n in ["run", "sprint"]:
		var mult := 1.28 if clip_n == "sprint" else 1.08
		var run := _registrar_clip(lib, clip_n, 0.56, true)
		_add_pos_keys(run, raiz, torso, [[0.0, Vector3.ZERO], [0.14, Vector3(0, 0.06, 0)], [0.28, Vector3.ZERO], [0.42, Vector3(0, 0.06, 0)], [0.56, Vector3.ZERO]])
		_add_rot_keys(run, raiz, torso, [[0.0, Vector3(10, -6, 0)], [0.28, Vector3(10, 6, 0)], [0.56, Vector3(10, -6, 0)]])
		_add_rot_keys(run, raiz, pierna_l, [[0.0, Vector3(amp_paso * mult, 0, 0)], [0.28, Vector3(-amp_paso * mult, 0, 0)], [0.56, Vector3(amp_paso * mult, 0, 0)]])
		_add_rot_keys(run, raiz, pierna_r, [[0.0, Vector3(-amp_paso * mult, 0, 0)], [0.28, Vector3(amp_paso * mult, 0, 0)], [0.56, Vector3(-amp_paso * mult, 0, 0)]])
		_add_rot_keys(run, raiz, brazo_l, [[0.0, Vector3(-amp_paso * 0.8 * mult, 0, sl * 8.0)], [0.28, Vector3(amp_paso * 0.8 * mult, 0, sl * 8.0)], [0.56, Vector3(-amp_paso * 0.8 * mult, 0, sl * 8.0)]])
		_add_rot_keys(run, raiz, brazo_r, [[0.0, Vector3(amp_paso * 0.8 * mult, 0, sr * 8.0)], [0.28, Vector3(-amp_paso * 0.8 * mult, 0, sr * 8.0)], [0.56, Vector3(amp_paso * 0.8 * mult, 0, sr * 8.0)]])

	# ATTACK MELEE RIGHT (0.45s)
	var atk := _registrar_clip(lib, "attack-melee-right", 0.45, false)
	_add_rot_keys(atk, raiz, torso, [[0.0, Vector3.ZERO], [0.14, Vector3(-8, -14, 0)], [0.26, Vector3(16, 18, 0)], [0.45, Vector3.ZERO]])
	_add_rot_keys(atk, raiz, brazo_r, [[0.0, Vector3.ZERO], [0.14, Vector3(-55, 0, sr * 22.0)], [0.26, Vector3(68, -15, sr * 10.0)], [0.45, Vector3.ZERO]])
	_add_rot_keys(atk, raiz, brazo_l, [[0.0, Vector3.ZERO], [0.22, Vector3(-18, 0, sl * 18.0)], [0.45, Vector3.ZERO]])

	# ATTACK RANGED (0.5s)
	var rng_atk := _registrar_clip(lib, "attack-ranged", 0.50, false)
	_add_rot_keys(rng_atk, raiz, torso, [[0.0, Vector3.ZERO], [0.18, Vector3(-5, 18, 0)], [0.32, Vector3(6, 10, 0)], [0.50, Vector3.ZERO]])
	_add_rot_keys(rng_atk, raiz, brazo_l, [[0.0, Vector3.ZERO], [0.18, Vector3(62, 12, 0)], [0.50, Vector3.ZERO]])
	_add_rot_keys(rng_atk, raiz, brazo_r, [[0.0, Vector3.ZERO], [0.18, Vector3(58, -18, 0)], [0.30, Vector3(32, -28, 0)], [0.50, Vector3.ZERO]])

	# CAST (0.55s)
	var cst := _registrar_clip(lib, "cast", 0.55, false)
	_add_rot_keys(cst, raiz, torso, [[0.0, Vector3.ZERO], [0.25, Vector3(-12, 0, 0)], [0.55, Vector3.ZERO]])
	_add_rot_keys(cst, raiz, brazo_l, [[0.0, Vector3.ZERO], [0.25, Vector3(72, 0, sl * 20.0)], [0.55, Vector3.ZERO]])
	_add_rot_keys(cst, raiz, brazo_r, [[0.0, Vector3.ZERO], [0.25, Vector3(72, 0, sr * 20.0)], [0.55, Vector3.ZERO]])

	# TELEGRAPH (0.6s, loop)
	var tel := _registrar_clip(lib, "telegraph", 0.60, true)
	_add_pos_keys(tel, raiz, torso, [[0.0, Vector3(0, -0.04, 0)], [0.3, Vector3(0, -0.09, 0)], [0.6, Vector3(0, -0.04, 0)]])
	_add_rot_keys(tel, raiz, torso, [[0.0, Vector3(-10, 0, 0)], [0.3, Vector3(-14, 0, 0)], [0.6, Vector3(-10, 0, 0)]])
	_add_rot_keys(tel, raiz, brazo_l, [[0.0, Vector3(-25, 0, sl * 28.0)], [0.3, Vector3(-35, 0, sl * 34.0)], [0.6, Vector3(-25, 0, sl * 28.0)]])
	_add_rot_keys(tel, raiz, brazo_r, [[0.0, Vector3(-25, 0, sr * 28.0)], [0.3, Vector3(-35, 0, sr * 34.0)], [0.6, Vector3(-25, 0, sr * 28.0)]])

	# HIT (0.26s)
	var hit := _registrar_clip(lib, "hit", 0.26, false)
	_add_rot_keys(hit, raiz, torso, [[0.0, Vector3.ZERO], [0.09, Vector3(-16, 0, -6)], [0.26, Vector3.ZERO]])
	_add_scl_keys(hit, raiz, torso, [[0.0, Vector3.ONE], [0.09, Vector3(1.06, 0.94, 1.06)], [0.26, Vector3.ONE]])

	# STUNNED (0.8s, loop)
	var stn := _registrar_clip(lib, "stunned", 0.80, true)
	_add_rot_keys(stn, raiz, torso, [[0.0, Vector3(14, -7, -6)], [0.4, Vector3(16, 7, 6)], [0.8, Vector3(14, -7, -6)]])
	_add_rot_keys(stn, raiz, cabeza, [[0.0, Vector3(12, 10, 0)], [0.4, Vector3(12, -10, 0)], [0.8, Vector3(12, 10, 0)]])


static func agregar_animaciones_flote(raiz: Node3D, rig: Node3D) -> void:
	var lib := _crear_anim_lib(raiz)
	var cuerpo := rig.get_node_or_null("Cuerpo") as Node3D
	var brazo_l := rig.find_child("BrazoIzq", true, false) as Node3D
	var brazo_r := rig.find_child("BrazoDer", true, false) as Node3D
	var anillo1 := rig.find_child("Anillo1", true, false) as Node3D
	var anillo2 := rig.find_child("Anillo2", true, false) as Node3D
	var nucleo := rig.find_child("NucleoSingularidad", true, false) as Node3D
	var sl: float = (1.0 if brazo_l != null and brazo_l.position.x >= 0.0 else -1.0)
	var sr: float = (1.0 if brazo_r != null and brazo_r.position.x >= 0.0 else -1.0)

	var idle := _registrar_clip(lib, "idle", 2.0, true)
	_add_pos_keys(idle, raiz, cuerpo, [[0.0, Vector3.ZERO], [1.0, Vector3(0, 0.09, 0)], [2.0, Vector3.ZERO]])
	_add_rot_keys(idle, raiz, anillo1, [[0.0, Vector3.ZERO], [1.0, Vector3(0, 180, 0)], [2.0, Vector3(0, 360, 0)]])
	_add_rot_keys(idle, raiz, anillo2, [[0.0, Vector3.ZERO], [1.0, Vector3(180, -180, 0)], [2.0, Vector3(360, -360, 0)]])
	if nucleo != null:
		_add_scl_keys(idle, raiz, nucleo, [[0.0, Vector3.ONE], [1.0, Vector3.ONE * 1.08], [2.0, Vector3.ONE]])

	for clip_n in ["walk", "run", "sprint"]:
		var vel_d := 0.8 if clip_n == "walk" else 0.56
		var tilt := 8.0 if clip_n == "walk" else 14.0
		var mov := _registrar_clip(lib, clip_n, vel_d, true)
		_add_pos_keys(mov, raiz, cuerpo, [[0.0, Vector3.ZERO], [vel_d * 0.5, Vector3(0, 0.08, 0)], [vel_d, Vector3.ZERO]])
		_add_rot_keys(mov, raiz, cuerpo, [[0.0, Vector3(tilt, 0, -4)], [vel_d * 0.5, Vector3(tilt + 3, 0, 4)], [vel_d, Vector3(tilt, 0, -4)]])
		_add_rot_keys(mov, raiz, brazo_l, [[0.0, Vector3(-12, 0, sl * 10.0)], [vel_d * 0.5, Vector3(12, 0, sl * 10.0)], [vel_d, Vector3(-12, 0, sl * 10.0)]])
		_add_rot_keys(mov, raiz, brazo_r, [[0.0, Vector3(12, 0, sr * 10.0)], [vel_d * 0.5, Vector3(-12, 0, sr * 10.0)], [vel_d, Vector3(12, 0, sr * 10.0)]])
		_add_rot_keys(mov, raiz, anillo1, [[0.0, Vector3.ZERO], [vel_d * 0.5, Vector3(0, 180, 0)], [vel_d, Vector3(0, 360, 0)]])

	for atk_n in ["attack-melee-right", "attack-ranged", "cast"]:
		var atk := _registrar_clip(lib, atk_n, 0.45, false)
		_add_rot_keys(atk, raiz, cuerpo, [[0.0, Vector3.ZERO], [0.15, Vector3(-12, -10, 0)], [0.28, Vector3(18, 12, 0)], [0.45, Vector3.ZERO]])
		_add_rot_keys(atk, raiz, brazo_r, [[0.0, Vector3.ZERO], [0.15, Vector3(-50, 0, sr * 20.0)], [0.28, Vector3(68, 0, sr * 10.0)], [0.45, Vector3.ZERO]])
		_add_rot_keys(atk, raiz, brazo_l, [[0.0, Vector3.ZERO], [0.22, Vector3(38, 0, sl * 18.0)], [0.45, Vector3.ZERO]])

	var tel := _registrar_clip(lib, "telegraph", 0.6, true)
	_add_pos_keys(tel, raiz, cuerpo, [[0.0, Vector3(0, 0.08, 0)], [0.3, Vector3(0, 0.16, 0)], [0.6, Vector3(0, 0.08, 0)]])
	_add_rot_keys(tel, raiz, cuerpo, [[0.0, Vector3(-12, 0, 0)], [0.3, Vector3(-16, 0, 0)], [0.6, Vector3(-12, 0, 0)]])

	var hit := _registrar_clip(lib, "hit", 0.26, false)
	_add_rot_keys(hit, raiz, cuerpo, [[0.0, Vector3.ZERO], [0.09, Vector3(-18, 0, 0)], [0.26, Vector3.ZERO]])

	var stn := _registrar_clip(lib, "stunned", 0.8, true)
	_add_pos_keys(stn, raiz, cuerpo, [[0.0, Vector3(0, -0.06, 0)], [0.4, Vector3(0, -0.10, 0)], [0.8, Vector3(0, -0.06, 0)]])
	_add_rot_keys(stn, raiz, cuerpo, [[0.0, Vector3(12, -8, -8)], [0.4, Vector3(12, 8, 8)], [0.8, Vector3(12, -8, -8)]])


static func agregar_animaciones_aracnido(raiz: Node3D, rig: Node3D) -> void:
	var lib := _crear_anim_lib(raiz)
	var cuerpo := rig.get_node_or_null("CuerpoBicho") as Node3D
	var patas_a: Array[Node3D] = []
	var patas_b: Array[Node3D] = []
	for p_n in ["Pata_1_I", "Pata_2_D", "Pata_3_I"]:
		var n := rig.find_child(p_n, true, false) as Node3D
		if n != null: patas_a.append(n)
	for p_n in ["Pata_1_D", "Pata_2_I", "Pata_3_D"]:
		var n := rig.find_child(p_n, true, false) as Node3D
		if n != null: patas_b.append(n)

	var idle := _registrar_clip(lib, "idle", 1.2, true)
	_add_pos_keys(idle, raiz, cuerpo, [[0.0, Vector3.ZERO], [0.6, Vector3(0, 0.03, 0)], [1.2, Vector3.ZERO]])

	for clip_n in ["walk", "run", "sprint"]:
		var d := 0.48 if clip_n == "walk" else 0.34
		var m := _registrar_clip(lib, clip_n, d, true)
		_add_pos_keys(m, raiz, cuerpo, [[0.0, Vector3.ZERO], [d * 0.5, Vector3(0, 0.04, 0)], [d, Vector3.ZERO]])
		for pa in patas_a:
			_add_rot_keys(m, raiz, pa, [[0.0, Vector3(18, 12, 0)], [d * 0.5, Vector3(-18, -12, 0)], [d, Vector3(18, 12, 0)]])
		for pb in patas_b:
			_add_rot_keys(m, raiz, pb, [[0.0, Vector3(-18, -12, 0)], [d * 0.5, Vector3(18, 12, 0)], [d, Vector3(-18, -12, 0)]])

	var atk := _registrar_clip(lib, "attack-melee-right", 0.35, false)
	_add_rot_keys(atk, raiz, cuerpo, [[0.0, Vector3.ZERO], [0.12, Vector3(-16, 0, 0)], [0.22, Vector3(20, 0, 0)], [0.35, Vector3.ZERO]])

	var tel := _registrar_clip(lib, "telegraph", 0.5, true)
	_add_scl_keys(tel, raiz, cuerpo, [[0.0, Vector3.ONE], [0.25, Vector3(1.08, 0.92, 1.08)], [0.5, Vector3.ONE]])

	var hit := _registrar_clip(lib, "hit", 0.24, false)
	_add_pos_keys(hit, raiz, cuerpo, [[0.0, Vector3.ZERO], [0.08, Vector3(0, 0.08, -0.05)], [0.24, Vector3.ZERO]])

	var stn := _registrar_clip(lib, "stunned", 0.6, true)
	_add_rot_keys(stn, raiz, cuerpo, [[0.0, Vector3(0, 0, -10)], [0.3, Vector3(0, 0, 10)], [0.6, Vector3(0, 0, -10)]])


static func agregar_animaciones_monorrueda(raiz: Node3D, rig: Node3D) -> void:
	var lib := _crear_anim_lib(raiz)
	var gab := rig.get_node_or_null("GabineteArcade") as Node3D
	var rueda := rig.find_child("RuedaGiro", true, false) as Node3D
	var pinza := rig.find_child("BrazoPinza", true, false) as Node3D
	var palanca := rig.find_child("PalancaJackpot", true, false) as Node3D

	var idle := _registrar_clip(lib, "idle", 1.6, true)
	_add_pos_keys(idle, raiz, gab, [[0.0, Vector3.ZERO], [0.8, Vector3(0, 0.04, 0)], [1.6, Vector3.ZERO]])
	_add_rot_keys(idle, raiz, palanca, [[0.0, Vector3.ZERO], [0.8, Vector3(12, 0, 0)], [1.6, Vector3.ZERO]])

	for clip_n in ["walk", "run", "sprint"]:
		var d := 0.6 if clip_n == "walk" else 0.4
		var m := _registrar_clip(lib, clip_n, d, true)
		_add_rot_keys(m, raiz, gab, [[0.0, Vector3(8, 0, -3)], [d * 0.5, Vector3(8, 0, 3)], [d, Vector3(8, 0, -3)]])
		_add_rot_keys(m, raiz, rueda, [[0.0, Vector3.ZERO], [d * 0.5, Vector3(180, 0, 0)], [d, Vector3(360, 0, 0)]])
		_add_rot_keys(m, raiz, pinza, [[0.0, Vector3(-10, 0, 0)], [d * 0.5, Vector3(10, 0, 0)], [d, Vector3(-10, 0, 0)]])

	var atk := _registrar_clip(lib, "attack-melee-right", 0.45, false)
	_add_rot_keys(atk, raiz, gab, [[0.0, Vector3.ZERO], [0.15, Vector3(-12, -12, 0)], [0.28, Vector3(16, 12, 0)], [0.45, Vector3.ZERO]])
	_add_rot_keys(atk, raiz, pinza, [[0.0, Vector3.ZERO], [0.15, Vector3(-45, 0, 12)], [0.28, Vector3(72, 0, 6)], [0.45, Vector3.ZERO]])

	var tel := _registrar_clip(lib, "telegraph", 0.5, true)
	_add_rot_keys(tel, raiz, palanca, [[0.0, Vector3.ZERO], [0.25, Vector3(45, 0, 0)], [0.5, Vector3.ZERO]])

	var hit := _registrar_clip(lib, "hit", 0.25, false)
	_add_rot_keys(hit, raiz, gab, [[0.0, Vector3.ZERO], [0.09, Vector3(-14, 0, 0)], [0.25, Vector3.ZERO]])

	var stn := _registrar_clip(lib, "stunned", 0.7, true)
	_add_rot_keys(stn, raiz, gab, [[0.0, Vector3(0, 0, -10)], [0.35, Vector3(0, 0, 10)], [0.7, Vector3(0, 0, -10)]])
