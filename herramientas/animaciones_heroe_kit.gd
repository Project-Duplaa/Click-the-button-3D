@tool
extends RefCounted

## ==============================================================================
## MOTOR BIOMECÁNICO DE ANIMACIONES PARA HÉROES ARTICULADOS (15 HUESOS)
## ==============================================================================
## Jerarquía esperada en Skeleton3D (ejes modelo: +Z frente, +Y arriba, +X izq, -X der):
##   root
##   ├── leg-left   -> shin-left  (rodilla y=-0.145) -> foot-left  (tobillo y=-0.123, suela -0.037)
##   ├── leg-right  -> shin-right (rodilla y=-0.145) -> foot-right (tobillo y=-0.123, suela -0.037)
##   └── torso
##       ├── arm-left  -> forearm-left  (codo x=+0.114) -> hand-left  (muñeca x=+0.106)
##       ├── arm-right -> forearm-right (codo x=-0.114) -> hand-right (muñeca x=-0.106)
##       └── head
##
## Todos los ángulos están en grados; rodillas (shin.rx >= 0) doblan hacia atrás (-Z)
## y codos (bend_deg >= 0) doblan hacia adelante (+Z). Los pies se fijan a y = 0.000
## mediante cinemática directa 3D exacta sobre talón y puntera.
## ==============================================================================

const HUESOS_15: Array[String] = [
	"root",
	"leg-left",
	"shin-left",
	"foot-left",
	"leg-right",
	"shin-right",
	"foot-right",
	"torso",
	"arm-left",
	"forearm-left",
	"hand-left",
	"arm-right",
	"forearm-right",
	"hand-right",
	"head",
]

# Geometría exacta de la bota respecto al origen del hueso foot-* (tobillo en y = -0.268 en reposo)
const SOLE_SAMPLE_POINTS: Array[Vector3] = [
	Vector3(0.0, -0.037, -0.042),   # Talón trasero
	Vector3(0.0, -0.037, 0.016),    # Arco / metatarso medio
	Vector3(-0.022, -0.037, 0.072), # Puntera exterior/interior
	Vector3(0.022, -0.037, 0.072),
]


static func _q_euler(rx_deg: float, ry_deg: float, rz_deg: float) -> Quaternion:
	return Basis.from_euler(Vector3(
		deg_to_rad(rx_deg),
		deg_to_rad(ry_deg),
		deg_to_rad(rz_deg)
	)).get_rotation_quaternion().normalized()


static func _rot_brazo(
	lado: float,
	bajar_deg: float,
	frente_deg: float,
	adentro_deg: float,
	roll_deg: float = 0.0
) -> Quaternion:
	# lado = +1.0 izquierda (+X), -1.0 derecha (-X)
	var q_down := Quaternion(Vector3.BACK, deg_to_rad(-lado * bajar_deg))
	var q_yaw := Quaternion(Vector3.UP, deg_to_rad(-lado * adentro_deg))
	var q_pitch := Quaternion(Vector3.RIGHT, deg_to_rad(-frente_deg))
	var q_roll := Quaternion(Vector3.RIGHT, deg_to_rad(lado * roll_deg))
	return (q_pitch * q_yaw * q_down * q_roll).normalized()


static func _rot_codo(lado: float, bend_deg: float, twist_deg: float = 0.0) -> Quaternion:
	# Dobla siempre hacia la cara flexora (+Z) evitando hiperextensiones antinaturales.
	var q_bend := Quaternion(Vector3.UP, deg_to_rad(-lado * clampf(bend_deg, 0.0, 138.0)))
	var q_twist := Quaternion(Vector3.RIGHT, deg_to_rad(lado * twist_deg))
	return (q_bend * q_twist).normalized()


static func _rot_muneca(lado: float, flex_deg: float, dev_deg: float = 0.0, twist_deg: float = 0.0) -> Quaternion:
	var q_flex := Quaternion(Vector3.UP, deg_to_rad(-lado * flex_deg))
	var q_dev := Quaternion(Vector3.BACK, deg_to_rad(-lado * dev_deg))
	var q_twist := Quaternion(Vector3.RIGHT, deg_to_rad(lado * twist_deg))
	return (q_flex * q_dev * q_twist).normalized()


static func _pose_pierna(
	hip_rx: float,
	knee_rx: float,
	foot_world_pitch: float,
	hip_ry: float = 0.0,
	hip_rz: float = 0.0,
	ankle_yaw: float = 0.0,
	ankle_roll: float = 0.0,
	knee_es_absoluto: bool = true
) -> Dictionary:
	var k_clamped := clampf(knee_rx, 0.0, 132.0)
	var ankle_rx := (foot_world_pitch - hip_rx - k_clamped) if knee_es_absoluto else foot_world_pitch
	return {
		"hip": _q_euler(hip_rx, hip_ry, hip_rz),
		"shin": _q_euler(k_clamped, 0.0, 0.0),
		"foot": _q_euler(ankle_rx, ankle_yaw, ankle_roll),
	}


static func _calcular_min_sole_y(reposos: Dictionary, pose: Dictionary) -> float:
	var q_root: Quaternion = pose.get("root", Quaternion.IDENTITY)
	var xf_root := Transform3D(Basis(q_root), Vector3.ZERO)
	var min_y := 999.0

	for side_pair in [
		["leg-left", "shin-left", "foot-left"],
		["leg-right", "shin-right", "foot-right"],
	]:
		var b_hip: String = side_pair[0]
		var b_shin: String = side_pair[1]
		var b_foot: String = side_pair[2]

		var xf_hip := Transform3D(
			Basis(pose.get(b_hip, Quaternion.IDENTITY)),
			reposos.get(b_hip, Vector3.ZERO)
		)
		var xf_shin := Transform3D(
			Basis(pose.get(b_shin, Quaternion.IDENTITY)),
			reposos.get(b_shin, Vector3.ZERO)
		)
		var xf_foot := Transform3D(
			Basis(pose.get(b_foot, Quaternion.IDENTITY)),
			reposos.get(b_foot, Vector3.ZERO)
		)
		var xf_total := xf_root * xf_hip * xf_shin * xf_foot
		for pt: Vector3 in SOLE_SAMPLE_POINTS:
			var w_pt := xf_total * pt
			if w_pt.y < min_y:
				min_y = w_pt.y
	return min_y


static func _fijar_suelo(pose: Dictionary, reposos: Dictionary, vuelo: float = 0.0, x_shift: float = 0.0, z_shift: float = 0.0) -> Dictionary:
	var out := pose.duplicate(true)
	var min_y := _calcular_min_sole_y(reposos, out)
	out["root_pos"] = Vector3(x_shift, -min_y + vuelo, z_shift)
	return out


static func _aplicar_easing(u: float, modo: String) -> float:
	var t := clampf(u, 0.0, 1.0)
	match modo:
		"ease_in_out":
			return t * t * (3.0 - 2.0 * t)
		"smoother":
			return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
		"ease_out":
			var inv := 1.0 - t
			return 1.0 - inv * inv * inv
		"ease_in":
			return t * t * t
		"snap":
			var inv := 1.0 - t
			return 1.0 - inv * inv * inv * inv
		"ease_out_back":
			var c1 := 1.70158
			var c3 := c1 + 1.0
			var tm1 := t - 1.0
			return 1.0 + c3 * tm1 * tm1 * tm1 + c1 * tm1 * tm1
		_:
			return t


static func _slerp_suave(a: Quaternion, b: Quaternion, w: float) -> Quaternion:
	var qa := a.normalized()
	var qb := b.normalized()
	if qa.dot(qb) < 0.0:
		qb = -qb
	return qa.slerp(qb, clampf(w, 0.0, 1.0)).normalized()


static func _interpolar_poses(pa: Dictionary, pb: Dictionary, w: float) -> Dictionary:
	var res: Dictionary = {}
	var ra: Vector3 = pa.get("root_pos", Vector3.ZERO)
	var rb: Vector3 = pb.get("root_pos", Vector3.ZERO)
	res["root_pos"] = ra.lerp(rb, w)
	for h: String in HUESOS_15:
		var qa: Quaternion = pa.get(h, Quaternion.IDENTITY)
		var qb: Quaternion = pb.get(h, Quaternion.IDENTITY)
		res[h] = _slerp_suave(qa, qb, w)
	return res


static func _hornear_secuencia(
	duracion: float,
	fps: int,
	keyframes: Array
) -> Array:
	var pasos: int = maxi(4, int(round(duracion * float(fps))))
	var out: Array = []
	for i in range(pasos + 1):
		var t: float = duracion * (float(i) / float(pasos))
		var seg_idx := 0
		while seg_idx < keyframes.size() - 2 and t > float(keyframes[seg_idx + 1]["t"]):
			seg_idx += 1
		var k0: Dictionary = keyframes[seg_idx]
		var k1: Dictionary = keyframes[mini(seg_idx + 1, keyframes.size() - 1)]
		var t0: float = float(k0["t"])
		var t1: float = float(k1["t"])
		var u := 0.0 if t1 <= t0 + 0.00001 else clampf((t - t0) / (t1 - t0), 0.0, 1.0)
		var ease_modo: String = String(k1.get("ease", "ease_in_out"))
		var w := _aplicar_easing(u, ease_modo)
		var pose := _interpolar_poses(k0, k1, w)
		pose["t"] = t
		out.append(pose)
	return out


static func _crear_clip_15huesos(
	skel_rel: String,
	nombre: String,
	duracion: float,
	loop: bool,
	reposos: Dictionary,
	poses: Array
) -> Animation:
	var anim := Animation.new()
	anim.resource_name = nombre
	anim.length = duracion
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	var tracks_pos: Dictionary = {}
	var tracks_rot: Dictionary = {}
	for h: String in HUESOS_15:
		var np := NodePath(skel_rel + ":" + h)
		var tp := anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(tp, np)
		anim.track_set_interpolation_type(tp, Animation.INTERPOLATION_LINEAR)
		tracks_pos[h] = tp
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, np)
		anim.track_set_interpolation_type(tr, Animation.INTERPOLATION_LINEAR)
		tracks_rot[h] = tr

	for p: Dictionary in poses:
		var t: float = float(p.get("t", 0.0))
		var r_off: Vector3 = p.get("root_pos", Vector3.ZERO)
		for h: String in HUESOS_15:
			var base_pos: Vector3 = reposos.get(h, Vector3.ZERO)
			var pos_val: Vector3 = r_off if h == "root" else base_pos
			anim.position_track_insert_key(int(tracks_pos[h]), t, pos_val)
			var rot_val: Quaternion = p.get(h, Quaternion.IDENTITY)
			anim.rotation_track_insert_key(int(tracks_rot[h]), t, rot_val.normalized())

	return anim


# ==============================================================================
# POSE BASE DE REPOSO / PORTE DE ARMAS POR CLASE
# ==============================================================================

static func _armar_pose_pose(
	reposos: Dictionary,
	pelvis_rot: Quaternion,
	leg_l: Dictionary,
	leg_r: Dictionary,
	torso_rot: Quaternion,
	head_rot: Quaternion,
	arm_l: Quaternion,
	forearm_l: Quaternion,
	hand_l: Quaternion,
	arm_r: Quaternion,
	forearm_r: Quaternion,
	hand_r: Quaternion,
	grounded: bool = true,
	lift: float = 0.0,
	shift_x: float = 0.0,
	shift_z: float = 0.0
) -> Dictionary:
	var pose := {
		"root": pelvis_rot,
		"leg-left": leg_l["hip"],
		"shin-left": leg_l["shin"],
		"foot-left": leg_l["foot"],
		"leg-right": leg_r["hip"],
		"shin-right": leg_r["shin"],
		"foot-right": leg_r["foot"],
		"torso": torso_rot,
		"arm-left": arm_l,
		"forearm-left": forearm_l,
		"hand-left": hand_l,
		"arm-right": arm_r,
		"forearm-right": forearm_r,
		"hand-right": hand_r,
		"head": head_rot,
	}
	if grounded:
		return _fijar_suelo(pose, reposos, lift, shift_x, shift_z)
	pose["root_pos"] = Vector3(shift_x, lift, shift_z)
	return pose


static func _perfil_clase(clase_id: String) -> Dictionary:
	# Devuelve posturas ergonómicas naturales de brazos/torso/piernas en reposo
	# manteniendo retratos de HUD (click_hud.gd) despejados y naturales.
	match clase_id:
		"warrior":
			return {
				"torso_pitch": 5.0,
				"torso_yaw": -9.0,
				"head_yaw": 9.0,
				"stance_w": 3.4,
				"leg_l_rx": -8.0, "knee_l": 16.0,
				"leg_r_rx": 8.0, "knee_r": 12.0,
				"arm_l": _rot_brazo(1.0, 62.0, 12.0, 14.0, -8.0),
				"forearm_l": _rot_codo(1.0, 74.0, 12.0),
				"hand_l": _rot_muneca(1.0, 6.0, 0.0, 0.0),
				"arm_r": _rot_brazo(-1.0, 66.0, 6.0, 14.0, 6.0),
				"forearm_r": _rot_codo(-1.0, 62.0, 8.0),
				"hand_r": _rot_muneca(-1.0, 4.0, -8.0, 0.0),
				"mass_mult": 0.90,
			}
		"archer":
			return {
				"torso_pitch": 4.0,
				"torso_yaw": -10.0,
				"head_yaw": 10.0,
				"stance_w": 2.8,
				"leg_l_rx": -9.0, "knee_l": 14.0,
				"leg_r_rx": 7.0, "knee_r": 10.0,
				"arm_l": _rot_brazo(1.0, 62.0, 8.0, 10.0, -4.0),
				"forearm_l": _rot_codo(1.0, 34.0, 8.0),
				"hand_l": _rot_muneca(1.0, 4.0, -10.0, 0.0),
				"arm_r": _rot_brazo(-1.0, 70.0, 4.0, 10.0, 4.0),
				"forearm_r": _rot_codo(-1.0, 44.0, -8.0),
				"hand_r": _rot_muneca(-1.0, 6.0, 0.0, 0.0),
				"mass_mult": 1.06,
			}
		"mage":
			return {
				"torso_pitch": 2.5,
				"torso_yaw": -4.0,
				"head_yaw": 4.0,
				"stance_w": 2.4,
				"leg_l_rx": -5.0, "knee_l": 10.0,
				"leg_r_rx": 5.0, "knee_r": 8.0,
				# Llama arcana izquierda ligeramente recogida al frente
				"arm_l": _rot_brazo(1.0, 68.0, 10.0, 12.0, 0.0),
				"forearm_l": _rot_codo(1.0, 66.0, 16.0),
				"hand_l": _rot_muneca(1.0, -8.0, 8.0, 10.0),
				# Báculo plasma derecho erguido al costado exterior despejando rostro HUD
				"arm_r": _rot_brazo(-1.0, 74.0, -4.0, -18.0, -6.0),
				"forearm_r": _rot_codo(-1.0, 18.0, -6.0),
				"hand_r": _rot_muneca(-1.0, -16.0, 10.0, 0.0),
				"mass_mult": 0.96,
			}
		_:
			return {
				"torso_pitch": 4.0,
				"torso_yaw": -6.0,
				"head_yaw": 6.0,
				"stance_w": 2.6,
				"leg_l_rx": -6.0, "knee_l": 12.0,
				"leg_r_rx": 6.0, "knee_r": 10.0,
				"arm_l": _rot_brazo(1.0, 72.0, 6.0, 10.0, 0.0),
				"forearm_l": _rot_codo(1.0, 42.0, 4.0),
				"hand_l": _rot_muneca(1.0, 4.0, 0.0, 0.0),
				"arm_r": _rot_brazo(-1.0, 68.0, 10.0, 12.0, 4.0),
				"forearm_r": _rot_codo(-1.0, 56.0, 6.0),
				"hand_r": _rot_muneca(-1.0, 6.0, -6.0, 0.0),
				"mass_mult": 1.0,
			}


static func _pose_idle_clase(reposos: Dictionary, clase_id: String, respira: float = 0.0, sway: float = 0.0, scan: float = 0.0) -> Dictionary:
	var pc := _perfil_clase(clase_id)
	var ll_rx: float = float(pc["leg_l_rx"]) - respira * 1.4
	var kl_rx: float = float(pc["knee_l"]) + respira * 2.8
	var lr_rx: float = float(pc["leg_r_rx"]) - respira * 1.0
	var kr_rx: float = float(pc["knee_r"]) + respira * 2.2
	var sw: float = float(pc["stance_w"])

	var ll := _pose_pierna(ll_rx, kl_rx, 0.0, 5.0, sw - sway * 1.2)
	var lr := _pose_pierna(lr_rx, kr_rx, 0.0, -5.0, -sw - sway * 1.2)
	var pelvis := _q_euler(0.0, float(pc["torso_yaw"]) * 0.25 + sway * 1.5, -sway * 1.4)
	var torso := _q_euler(float(pc["torso_pitch"]) + respira * 2.0, float(pc["torso_yaw"]) * 0.75 + sway * 1.2, sway * 1.0)
	var head := _q_euler(-float(pc["torso_pitch"]) * 0.5 - respira * 1.5, float(pc["head_yaw"]) + scan * 5.5, -sway * 0.8)

	var arm_l: Quaternion
	var fore_l: Quaternion
	var hand_l: Quaternion = pc["hand_l"]
	var arm_r: Quaternion
	var fore_r: Quaternion
	var hand_r: Quaternion = pc["hand_r"]

	match clase_id:
		"warrior":
			arm_l = _rot_brazo(1.0, 62.0 - respira * 2.2, 12.0 + respira * 2.5, 14.0 + respira * 1.5, -8.0)
			fore_l = _rot_codo(1.0, 74.0 + respira * 4.0, 12.0)
			arm_r = _rot_brazo(-1.0, 66.0 - respira * 2.0, 6.0 + respira * 3.0, 14.0 + respira * 1.5, 6.0)
			fore_r = _rot_codo(-1.0, 62.0 + respira * 3.5, 8.0)
		"archer":
			arm_l = _rot_brazo(1.0, 62.0 - respira * 2.5, 8.0 + respira * 2.0, 10.0, -4.0)
			fore_l = _rot_codo(1.0, 34.0 + respira * 3.0, 8.0)
			arm_r = _rot_brazo(-1.0, 70.0 - respira * 2.0, 4.0 + respira * 2.0, 10.0, 4.0)
			fore_r = _rot_codo(-1.0, 44.0 + respira * 3.5, -8.0)
		"mage":
			arm_l = _rot_brazo(1.0, 68.0 - respira * 3.0, 10.0 + respira * 3.5, 12.0 + respira * 2.0, 0.0)
			fore_l = _rot_codo(1.0, 66.0 + respira * 5.0, 16.0)
			arm_r = _rot_brazo(-1.0, 74.0 - respira * 1.5, -4.0 + respira * 1.5, -18.0, -6.0)
			fore_r = _rot_codo(-1.0, 18.0 + respira * 2.5, -6.0)
		_:
			arm_l = _rot_brazo(1.0, 72.0 - respira * 2.5, 6.0 + respira * 2.5, 10.0, 0.0)
			fore_l = _rot_codo(1.0, 42.0 + respira * 4.0, 4.0)
			arm_r = _rot_brazo(-1.0, 68.0 - respira * 2.5, 10.0 + respira * 3.0, 12.0, 4.0)
			fore_r = _rot_codo(-1.0, 56.0 + respira * 4.0, 6.0)

	return _armar_pose_pose(
		reposos, pelvis, ll, lr, torso, head,
		arm_l, fore_l, hand_l, arm_r, fore_r, hand_r,
		true, 0.0, sway * 0.005, 0.0
	)


static func _pose_guardia(reposos: Dictionary, clase_id: String, respira: float = 0.0) -> Dictionary:
	var ll := _pose_pierna(-16.0 - respira * 1.5, 28.0 + respira * 3.0, 0.0, 6.0, 3.8)
	var lr := _pose_pierna(12.0 - respira * 1.0, 20.0 + respira * 2.0, 0.0, -8.0, -3.8)
	var torso := _q_euler(10.0 + respira * 2.0, -12.0, 0.0)
	var head := _q_euler(-7.0 - respira * 1.5, 12.0, 0.0)
	var pelvis := _q_euler(0.0, -4.0, 0.0)

	var arm_l: Quaternion
	var fore_l: Quaternion
	var hand_l: Quaternion
	var arm_r: Quaternion
	var fore_r: Quaternion
	var hand_r: Quaternion

	if clase_id == "warrior":
		# Escudo alzado protegiendo pecho/rostro + martillo listo en guardia alta derecha
		arm_l = _rot_brazo(1.0, 50.0 - respira * 2.0, 30.0 + respira * 2.0, 38.0, -14.0)
		fore_l = _rot_codo(1.0, 78.0 + respira * 2.0, 18.0)
		hand_l = _rot_muneca(1.0, 8.0, 0.0, 0.0)
		arm_r = _rot_brazo(-1.0, 54.0 - respira * 2.0, 16.0 + respira * 2.0, 18.0, 10.0)
		fore_r = _rot_codo(-1.0, 72.0 + respira * 3.0, 12.0)
		hand_r = _rot_muneca(-1.0, 8.0, -10.0, 0.0)
	elif clase_id == "archer":
		arm_l = _rot_brazo(1.0, 52.0 - respira * 2.0, 18.0, 22.0, -4.0)
		fore_l = _rot_codo(1.0, 46.0 + respira * 3.0, 8.0)
		hand_l = _rot_muneca(1.0, 4.0, -8.0, 0.0)
		arm_r = _rot_brazo(-1.0, 56.0 - respira * 2.0, 14.0, 24.0, 4.0)
		fore_r = _rot_codo(-1.0, 68.0 + respira * 3.0, -10.0)
		hand_r = _rot_muneca(-1.0, 6.0, 0.0, 0.0)
	elif clase_id == "mage":
		arm_l = _rot_brazo(1.0, 54.0 - respira * 2.5, 22.0 + respira * 2.5, 26.0, 0.0)
		fore_l = _rot_codo(1.0, 76.0 + respira * 4.0, 20.0)
		hand_l = _rot_muneca(1.0, -10.0, 10.0, 12.0)
		arm_r = _rot_brazo(-1.0, 58.0 - respira * 2.0, 8.0, -4.0, -12.0)
		fore_r = _rot_codo(-1.0, 62.0 + respira * 3.0, -12.0)
		hand_r = _rot_muneca(-1.0, 8.0, -12.0, 0.0)
	else:
		arm_l = _rot_brazo(1.0, 52.0 - respira * 2.0, 22.0, 26.0, 0.0)
		fore_l = _rot_codo(1.0, 74.0 + respira * 3.0, 10.0)
		hand_l = _rot_muneca(1.0, 6.0, 0.0, 0.0)
		arm_r = _rot_brazo(-1.0, 54.0 - respira * 2.0, 20.0, 24.0, 6.0)
		fore_r = _rot_codo(-1.0, 78.0 + respira * 3.0, 10.0)
		hand_r = _rot_muneca(-1.0, 8.0, -8.0, 0.0)

	return _armar_pose_pose(reposos, pelvis, ll, lr, torso, head, arm_l, fore_l, hand_l, arm_r, fore_r, hand_r, true, 0.0)


# ==============================================================================
# SÍNTESIS DE MARCHA NATURAL (WALK / RUN / SPRINT / BLOCK-WALK)
# ==============================================================================
# Ciclo normalizado u ∈ [0, 1]:
#   u = 0.00 : Contacto talón izquierdo al frente, pierna derecha atrás en toe-off
#   u = 0.14 : Absorción izquierda (rodilla izquierda ~20°, planta se asienta), derecha empieza a recogerse
#   u = 0.25 : Paso medio (izquierda soporta peso recta/suave, derecha rodilla alta al pasar)
#   u = 0.38 : Impulso puntera izquierda / derecha alcanza extensión frontal
#   u = 0.50..1.00 : Simétrico exacto para lado derecho.

static func _evaluar_pierna_marcha(u_raw: float, modo: String) -> Dictionary:
	var u := fposmod(u_raw, 1.0)
	var ph := u * TAU
	var hip_amp := 24.0
	var lean_forward := 2.0
	var stance_knee := 16.0
	var swing_knee_peak := 56.0
	var heel_deg := -18.0
	var toe_deg := 26.0

	match modo:
		"walk":
			hip_amp = 25.0
			lean_forward = 2.0
			stance_knee = 15.0
			swing_knee_peak = 56.0
			heel_deg = -18.0
			toe_deg = 24.0
		"block_walk":
			hip_amp = 18.0
			lean_forward = -3.0
			stance_knee = 28.0
			swing_knee_peak = 52.0
			heel_deg = -10.0
			toe_deg = 16.0
		"run":
			hip_amp = 36.0
			lean_forward = -4.0
			stance_knee = 24.0
			swing_knee_peak = 86.0
			heel_deg = -14.0
			toe_deg = 36.0
		"sprint":
			hip_amp = 45.0
			lean_forward = -7.0
			stance_knee = 26.0
			swing_knee_peak = 104.0
			heel_deg = -10.0
			toe_deg = 44.0

	# Cadera: cos(ph) alcanza máximo adelante (-hip_amp) en u=0 y atrás (+hip_amp) en u=0.5,
	# ajustado con asimetría de fase para estancia ligeramente más larga que el vuelo.
	var c := cos(ph)
	var s := sin(ph)
	var hip_rx := lean_forward - hip_amp * c - 4.0 * sin(2.0 * ph) * 0.25

	# Rodilla (siempre >= 0):
	# - En u ∈ [0.0, 0.5] (fase de apoyo): pico suave de absorción en u≈0.14
	# - En u ∈ [0.5, 1.0] (fase de balanceo): flexión pronunciada centrada en u≈0.74 para librar el suelo!
	var dist_stance := absf(u - 0.14) / 0.14
	var absorption := pow(maxf(0.0, 1.0 - dist_stance), 1.6) * stance_knee
	var pre_bend := (4.0 if modo == "walk" else 10.0) + (8.0 if modo == "block_walk" else 0.0)
	var swing_w := pow(maxf(0.0, sin((u - 0.45) / 0.55 * PI)), 1.35) if u > 0.45 else 0.0
	# Amortiguar rápido al llegar a u = 0.96 para recibir talón
	var extension_tarde := smoothstep(0.84, 0.99, u) * 0.65
	var knee_rx := pre_bend + absorption + swing_knee_peak * swing_w * (1.0 - extension_tarde)
	knee_rx = clampf(knee_rx, 4.0, 118.0)

	# Tobillo / orientación pie respecto al mundo:
	# u≈0.00: heel strike (puntera arriba, heel_deg < 0)
	# u=0.10..0.34: pie plano en 0°
	# u=0.35..0.55: empuje de punta (toe_deg > 0)
	# u=0.60..0.92: dorsiflexión neutra durante balanceo para no rozar suelo
	var foot_world := 0.0
	if u < 0.09:
		foot_world = lerpf(heel_deg, 0.0, smoothstep(0.0, 0.09, u))
	elif u < 0.34:
		foot_world = 0.0
	elif u < 0.54:
		foot_world = lerpf(0.0, toe_deg, smoothstep(0.34, 0.54, u))
	elif u < 0.78:
		foot_world = lerpf(toe_deg, -4.0, smoothstep(0.54, 0.78, u))
	else:
		foot_world = lerpf(-4.0, heel_deg, smoothstep(0.78, 1.0, u))

	return {
		"hip_rx": hip_rx,
		"knee_rx": knee_rx,
		"foot_world": foot_world,
		"is_swing": 1.0 if (u > 0.52 and u < 0.95) else 0.0,
		"stride_cos": c,
		"stride_sin": s,
	}


static func _generar_ciclo_locomocion(
	reposos: Dictionary,
	clase_id: String,
	modo: String,
	duracion: float,
	muestras: int = 24
) -> Array:
	var poses: Array = []
	var pc := _perfil_clase(clase_id)
	var sw: float = float(pc["stance_w"])

	for i in range(muestras + 1):
		var u := float(i) / float(muestras)
		var ph := u * TAU
		var s := sin(ph)
		var c := cos(ph)

		# Lado izquierdo en fase u, lado derecho desfasado 0.5 ciclo
		var dl := _evaluar_pierna_marcha(u, modo)
		var dr := _evaluar_pierna_marcha(u + 0.5, modo)

		# Rotación pélvica y desplazamiento lateral de centro de masa sobre pierna de apoyo
		var hip_yaw_amp := 4.5 if modo == "walk" else (7.0 if modo == "run" else 9.0)
		if modo == "block_walk":
			hip_yaw_amp = 3.0
		var pelvis_yaw := -hip_yaw_amp * c
		var pelvis_roll := (-2.2 if modo == "walk" else -3.0) * c
		var torso_lean := 7.0
		var torso_yaw_amp := 10.0
		var lat_amp := 0.008
		var lift := 0.0

		match modo:
			"walk":
				torso_lean = 6.5
				torso_yaw_amp = 9.5
				lat_amp = 0.009
				lift = 0.0
			"block_walk":
				torso_lean = 12.0
				torso_yaw_amp = 5.0
				lat_amp = 0.006
				lift = 0.0
			"run":
				torso_lean = 14.5
				torso_yaw_amp = 15.0
				lat_amp = 0.007
				lift = 0.012 * pow(maxf(0.0, absf(s) - 0.55) / 0.45, 1.3)
			"sprint":
				torso_lean = 22.0
				torso_yaw_amp = 19.0
				lat_amp = 0.006
				lift = 0.022 * pow(maxf(0.0, absf(s) - 0.42) / 0.58, 1.2)

		var arm_swing_l := -c # Brazo izquierdo avanza cuando pierna izquierda va atrás!
		var arm_swing_r := c  # Brazo derecho avanza cuando pierna izquierda está al frente!
		var arm_phase_lag := sin(ph - 0.45)

		var leg_l := _pose_pierna(float(dl["hip_rx"]), float(dl["knee_rx"]), float(dl["foot_world"]), -pelvis_yaw + 3.0, sw - pelvis_roll)
		var leg_r := _pose_pierna(float(dr["hip_rx"]), float(dr["knee_rx"]), float(dr["foot_world"]), -pelvis_yaw - 3.0, -sw - pelvis_roll)

		# Torso contrarrota respecto a pelvis
		var torso_yaw := -pelvis_yaw + torso_yaw_amp * c
		var bounce_pitch := 1.8 * absf(s) if modo != "walk" else 1.0 * absf(s)
		var torso := _q_euler(torso_lean + bounce_pitch, torso_yaw, 1.8 * c)
		var head := _q_euler(-torso_lean * 0.72 - bounce_pitch * 0.6, -torso_yaw - pelvis_yaw * 0.4, -1.2 * c)
		var pelvis := _q_euler(0.0, pelvis_yaw, pelvis_roll)

		# Porte de brazos según arma de cada clase + fase natural del codo
		var arm_amp := 22.0 if modo == "walk" else (34.0 if modo == "run" else 44.0)
		var base_elbow := 36.0 if modo == "walk" else (78.0 if modo == "run" else 92.0)

		var arm_l: Quaternion
		var fore_l: Quaternion
		var hand_l: Quaternion
		var arm_r: Quaternion
		var fore_r: Quaternion
		var hand_r: Quaternion

		if modo == "block_walk":
			# Guardia de escudo firme al avanzar
			arm_l = _rot_brazo(1.0, 50.0, 28.0 + 4.0 * arm_swing_l, 38.0, -14.0)
			fore_l = _rot_codo(1.0, 78.0, 18.0)
			hand_l = _rot_muneca(1.0, 8.0, 0.0, 0.0)
			arm_r = _rot_brazo(-1.0, 58.0, 10.0 + 10.0 * arm_swing_r, 16.0, 8.0)
			fore_r = _rot_codo(-1.0, 70.0 + 8.0 * maxf(0.0, arm_swing_r), 10.0)
			hand_r = _rot_muneca(-1.0, 6.0, -8.0, 0.0)
		else:
			match clase_id:
				"warrior":
					# Escudo izquierdo protegido frente al costado izquierdo, martillo en diagonal limpia exterior
					var sh_bajar := 58.0 if modo == "walk" else 52.0
					arm_l = _rot_brazo(1.0, sh_bajar, 18.0 + 11.0 * arm_swing_l, 26.0, -10.0)
					fore_l = _rot_codo(1.0, 74.0 + 8.0 * maxf(0.0, arm_swing_l), 14.0)
					hand_l = _rot_muneca(1.0, 6.0, 0.0, 0.0)
					arm_r = _rot_brazo(-1.0, 64.0 - 4.0 * absf(s), 6.0 + arm_amp * 0.72 * arm_swing_r, 8.0, 14.0)
					fore_r = _rot_codo(-1.0, maxf(40.0, base_elbow - 12.0 + 16.0 * maxf(0.0, arm_swing_r) - 6.0 * arm_phase_lag), 12.0)
					hand_r = _rot_muneca(-1.0, -12.0, 10.0, 0.0)
				"archer":
					# Arco izquierdo equilibrado en diagonal estable mientras corre; brazo derecho ágil
					arm_l = _rot_brazo(1.0, 60.0 if modo == "walk" else 52.0, 10.0 + arm_amp * 0.45 * arm_swing_l, 16.0, -6.0)
					fore_l = _rot_codo(1.0, 38.0 + (22.0 if modo != "walk" else 6.0) + 10.0 * maxf(0.0, arm_swing_l), 10.0)
					hand_l = _rot_muneca(1.0, 4.0, -10.0, 0.0)
					arm_r = _rot_brazo(-1.0, 64.0 if modo == "walk" else 54.0, 8.0 + arm_amp * arm_swing_r, 14.0, 4.0)
					fore_r = _rot_codo(-1.0, maxf(30.0, base_elbow + 22.0 * maxf(0.0, arm_swing_r) + 8.0 * arm_phase_lag), 0.0)
					hand_r = _rot_muneca(-1.0, 6.0, 0.0, 0.0)
				"mage":
					# Mano izquierda con llama arcana se mantiene frente-arriba estable; báculo en mano derecha inclinándose suavemente atrás
					arm_l = _rot_brazo(1.0, 62.0 if modo == "walk" else 52.0, 14.0 + arm_amp * 0.48 * arm_swing_l, 20.0, 0.0)
					fore_l = _rot_codo(1.0, 68.0 + 12.0 * maxf(0.0, arm_swing_l), 16.0)
					hand_l = _rot_muneca(1.0, -8.0, 8.0, 10.0)
					arm_r = _rot_brazo(-1.0, 66.0 if modo == "walk" else 58.0, -2.0 + arm_amp * 0.42 * arm_swing_r, -8.0, -14.0)
					fore_r = _rot_codo(-1.0, 52.0 + (18.0 if modo != "walk" else 6.0) + 10.0 * maxf(0.0, arm_swing_r), -14.0)
					hand_r = _rot_muneca(-1.0, 8.0, -12.0, 0.0)
				_:
					arm_l = _rot_brazo(1.0, 66.0 if modo == "walk" else 56.0, 8.0 + arm_amp * arm_swing_l, 12.0, 0.0)
					fore_l = _rot_codo(1.0, maxf(24.0, base_elbow + 22.0 * maxf(0.0, arm_swing_l) + 8.0 * arm_phase_lag), 4.0)
					hand_l = _rot_muneca(1.0, 4.0, 0.0, 0.0)
					arm_r = _rot_brazo(-1.0, 64.0 if modo == "walk" else 54.0, 10.0 + arm_amp * 0.90 * arm_swing_r, 14.0, 6.0)
					fore_r = _rot_codo(-1.0, maxf(32.0, base_elbow + 20.0 * maxf(0.0, arm_swing_r) - 6.0 * arm_phase_lag), 8.0)
					hand_r = _rot_muneca(-1.0, 6.0, -6.0, 0.0)

		var pose := _armar_pose_pose(
			reposos, pelvis, leg_l, leg_r, torso, head,
			arm_l, fore_l, hand_l, arm_r, fore_r, hand_r,
			true, lift, lat_amp * c, 0.0
		)
		pose["t"] = duracion * u
		poses.append(pose)
	return poses


# ==============================================================================
# CONSTRUCTOR PRINCIPAL DE TODAS LAS 21 ANIMACIONES DEL HÉROE
# ==============================================================================

static func construir_animaciones_heroe(
	escena: Node,
	skel: Skeleton3D,
	reposos: Dictionary,
	clase_id: String
) -> void:
	var ap: AnimationPlayer = escena.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		ap = AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		escena.add_child(ap)
	ap.root_node = ap.get_path_to(escena)
	var skel_rel: String = String(escena.get_path_to(skel))

	var lib := AnimationLibrary.new()
	var pose_idle0 := _pose_idle_clase(reposos, clase_id, 0.0, 0.0, 0.0)
	var pose_guard0 := _pose_guardia(reposos, clase_id, 0.0)

	# --------------------------------------------------------------------------
	# 1. idle (2.2s loop — respiración asimétrica suave + micro balanceo orgánico)
	# --------------------------------------------------------------------------
	var idle_poses: Array = []
	var idle_n := 22
	for ii in range(idle_n + 1):
		var u := float(ii) / float(idle_n)
		var ph := u * TAU
		var resp := sin(ph)
		var sway := sin(ph * 0.5)
		var scan := sin(ph + 1.1) * 0.45 + sin(ph * 2.0) * 0.15
		var p_idle := _pose_idle_clase(reposos, clase_id, resp, sway, scan)
		p_idle["t"] = 2.2 * u
		idle_poses.append(p_idle)
	lib.add_animation(&"idle", _crear_clip_15huesos(skel_rel, "idle", 2.2, true, reposos, idle_poses))

	# --------------------------------------------------------------------------
	# 2. static (0.6s loop — pose neutra articulada apta para retratos HUD)
	# --------------------------------------------------------------------------
	var pc := _perfil_clase(clase_id)
	var st_pose := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-4.0, 8.0, 0.0, 3.0, 2.2),
		_pose_pierna(4.0, 8.0, 0.0, -3.0, -2.2),
		_q_euler(2.5, 0.0, 0.0),
		_q_euler(-1.0, 0.0, 0.0),
		pc["arm_l"], pc["forearm_l"], pc["hand_l"],
		pc["arm_r"], pc["forearm_r"], pc["hand_r"],
		true, 0.0
	)
	var st_a := st_pose.duplicate(true)
	st_a["t"] = 0.0
	var st_b := st_pose.duplicate(true)
	st_b["t"] = 0.6
	lib.add_animation(&"static", _crear_clip_15huesos(skel_rel, "static", 0.6, true, reposos, [st_a, st_b]))

	# --------------------------------------------------------------------------
	# 3. holding-both (1.4s loop — guardia de combate / bloqueo con escudo)
	# --------------------------------------------------------------------------
	var hb_poses: Array = []
	for hi in range(17):
		var u := float(hi) / 16.0
		var p_hb := _pose_guardia(reposos, clase_id, sin(u * TAU))
		p_hb["t"] = 1.4 * u
		hb_poses.append(p_hb)
	lib.add_animation(&"holding-both", _crear_clip_15huesos(skel_rel, "holding-both", 1.4, true, reposos, hb_poses))

	# --------------------------------------------------------------------------
	# 4. block-walk (0.76s loop — avance en guardia acorazada con escudo firme)
	# --------------------------------------------------------------------------
	lib.add_animation(&"block-walk", _crear_clip_15huesos(
		skel_rel, "block-walk", 0.76, true, reposos,
		_generar_ciclo_locomocion(reposos, clase_id, "block_walk", 0.76, 24)
	))

	# --------------------------------------------------------------------------
	# 5. holding-right-shoot (1.2s loop — apuntado tenso listo para disparar)
	# --------------------------------------------------------------------------
	var hrs_poses: Array = []
	for hi in range(17):
		var u := float(hi) / 16.0
		var r := sin(u * TAU)
		var p_hrs := _armar_pose_pose(
			reposos, _q_euler(0.0, -14.0, 0.0),
			_pose_pierna(-14.0 - r, 24.0 + r * 2.0, 0.0, 10.0, 3.2),
			_pose_pierna(12.0 - r, 18.0 + r * 2.0, 0.0, -10.0, -3.2),
			_q_euler(4.0 + r * 1.2, -32.0, 0.0),
			_q_euler(-2.0 - r, 44.0, 0.0),
			_rot_brazo(1.0, 14.0 - r * 1.5, 4.0, 26.0, -6.0),
			_rot_codo(1.0, 14.0, 6.0),
			_rot_muneca(1.0, 2.0, -8.0, 0.0),
			_rot_brazo(-1.0, 18.0 - r * 1.5, 10.0, 28.0, 6.0),
			_rot_codo(-1.0, 96.0 + r * 3.0, -12.0),
			_rot_muneca(-1.0, 4.0, 0.0, 0.0),
			true, 0.0
		)
		p_hrs["t"] = 1.2 * u
		hrs_poses.append(p_hrs)
	lib.add_animation(&"holding-right-shoot", _crear_clip_15huesos(skel_rel, "holding-right-shoot", 1.2, true, reposos, hrs_poses))

	# --------------------------------------------------------------------------
	# 6, 7, 8. walk / run / sprint (24 muestras densas por ciclo)
	# --------------------------------------------------------------------------
	lib.add_animation(&"walk", _crear_clip_15huesos(
		skel_rel, "walk", 0.80, true, reposos,
		_generar_ciclo_locomocion(reposos, clase_id, "walk", 0.80, 24)
	))
	lib.add_animation(&"run", _crear_clip_15huesos(
		skel_rel, "run", 0.62, true, reposos,
		_generar_ciclo_locomocion(reposos, clase_id, "run", 0.62, 24)
	))
	lib.add_animation(&"sprint", _crear_clip_15huesos(
		skel_rel, "sprint", 0.50, true, reposos,
		_generar_ciclo_locomocion(reposos, clase_id, "sprint", 0.50, 24)
	))

	# --------------------------------------------------------------------------
	# 9. attack-melee-right (0.48s — látigo secuencial: cadera -> pecho -> hombro -> codo -> muñeca)
	# --------------------------------------------------------------------------
	var es_pesado := (clase_id == "warrior")
	var atk_r_wind := _armar_pose_pose(
		reposos, _q_euler(0.0, -14.0, -2.0),
		_pose_pierna(-12.0, 26.0, 0.0, 8.0, 3.6),
		_pose_pierna(18.0, 28.0, 0.0, -8.0, -3.6),
		_q_euler(-10.0, -24.0, -6.0),
		_q_euler(6.0, 34.0, 4.0),
		_rot_brazo(1.0, 52.0, 24.0, 38.0, -12.0),
		_rot_codo(1.0, 78.0, 14.0),
		_rot_muneca(1.0, 6.0, 0.0, 0.0),
		# Carga alta y abierta sobre hombro derecho (-X, +Y), despejada de cabeza y escudo
		_rot_brazo(-1.0, -22.0 if es_pesado else -18.0, -14.0, -18.0, 36.0),
		_rot_codo(-1.0, 24.0, 14.0),
		_rot_muneca(-1.0, -56.0, -12.0, 18.0),
		true, 0.0, -0.012, -0.014
	)
	var atk_r_hit := _armar_pose_pose(
		reposos, _q_euler(0.0, 12.0, 2.0),
		_pose_pierna(-32.0, 46.0, 0.0, 6.0, 4.0),
		_pose_pierna(24.0, 16.0, 18.0, -6.0, -4.0),
		_q_euler(18.0, 22.0, 6.0),
		_q_euler(-12.0, -30.0, -4.0),
		_rot_brazo(1.0, 58.0, -16.0, 22.0, -12.0),
		_rot_codo(1.0, 88.0, 14.0),
		_rot_muneca(1.0, 8.0, 0.0, 0.0),
		# Proyección frontal potente extendiendo brazo y punta del arma hacia +Z
		_rot_brazo(-1.0, 34.0, 48.0, 30.0, -12.0),
		_rot_codo(-1.0, 14.0, -6.0),
		_rot_muneca(-1.0, -68.0, -10.0, 0.0),
		true, 0.0, 0.010, 0.025
	)
	var atk_r_follow := _armar_pose_pose(
		reposos, _q_euler(0.0, 14.0, 1.0),
		_pose_pierna(-22.0, 34.0, 0.0, 6.0, 3.4),
		_pose_pierna(18.0, 18.0, 10.0, -6.0, -3.4),
		_q_euler(14.0, 28.0, 4.0),
		_q_euler(-10.0, -30.0, -2.0),
		_rot_brazo(1.0, 56.0, 8.0, 28.0, -10.0),
		_rot_codo(1.0, 78.0, 12.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 46.0, 30.0, 52.0, -12.0),
		_rot_codo(-1.0, 24.0, -6.0),
		_rot_muneca(-1.0, -56.0, -8.0, 0.0),
		true, 0.0, 0.005, 0.015
	)
	var kfs_atk_r: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		atk_r_wind.merged({"t": 0.13, "ease": "ease_in_out"}, true),
		atk_r_hit.merged({"t": 0.24, "ease": "snap"}, true),
		atk_r_follow.merged({"t": 0.34, "ease": "ease_out"}, true),
		pose_idle0.merged({"t": 0.48, "ease": "ease_in_out"}, true),
	]
	lib.add_animation(&"attack-melee-right", _crear_clip_15huesos(
		skel_rel, "attack-melee-right", 0.48, false, reposos,
		_hornear_secuencia(0.48, 30, kfs_atk_r)
	))

	# --------------------------------------------------------------------------
	# 10. attack-melee-left (0.46s — Shield Bash en Guerrero / revés ágil en otros)
	# --------------------------------------------------------------------------
	var atk_l_wind := _armar_pose_pose(
		reposos, _q_euler(0.0, 14.0, 2.0),
		_pose_pierna(14.0, 24.0, 0.0, 6.0, 3.6),
		_pose_pierna(-16.0, 28.0, 0.0, -6.0, -3.6),
		_q_euler(-4.0, 30.0, 5.0),
		_q_euler(3.0, -32.0, -4.0),
		_rot_brazo(1.0, 46.0 if es_pesado else 36.0, -14.0, -12.0, -16.0),
		_rot_codo(1.0, 92.0 if es_pesado else 80.0, 16.0),
		_rot_muneca(1.0, -8.0, 0.0, 0.0),
		_rot_brazo(-1.0, 62.0, 16.0, 20.0, 6.0),
		_rot_codo(-1.0, 74.0, 10.0),
		pc["hand_r"],
		true, 0.0, 0.010, -0.012
	)
	var atk_l_hit := _armar_pose_pose(
		reposos, _q_euler(0.0, -10.0, -2.0),
		_pose_pierna(-26.0, 38.0, 0.0, 6.0, 4.0),
		_pose_pierna(22.0, 16.0, 16.0, -6.0, -4.0),
		_q_euler(18.0, -18.0, -5.0),
		_q_euler(-12.0, 26.0, 4.0),
		_rot_brazo(1.0, 30.0 if es_pesado else 26.0, 28.0, 56.0 if es_pesado else 70.0, 14.0 if es_pesado else -8.0),
		_rot_codo(1.0, 48.0 if es_pesado else 18.0, 16.0),
		_rot_muneca(1.0, -20.0 if not es_pesado else 10.0, 0.0, 0.0),
		_rot_brazo(-1.0, 64.0, -16.0, 8.0, 8.0),
		_rot_codo(-1.0, 70.0, 8.0),
		pc["hand_r"],
		true, 0.0, -0.008, 0.024
	)
	var kfs_atk_l: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		atk_l_wind.merged({"t": 0.12, "ease": "ease_in_out"}, true),
		atk_l_hit.merged({"t": 0.23, "ease": "snap"}, true),
		pose_idle0.merged({"t": 0.46, "ease": "ease_in_out"}, true),
	]
	lib.add_animation(&"attack-melee-left", _crear_clip_15huesos(
		skel_rel, "attack-melee-left", 0.46, false, reposos,
		_hornear_secuencia(0.46, 30, kfs_atk_l)
	))

	# --------------------------------------------------------------------------
	# 11. shoot-bow (0.50s — hombro izq recto al blanco, codo der doblado 118° atrás junto a mejilla)
	# --------------------------------------------------------------------------
	var bow_ready := _armar_pose_pose(
		reposos, _q_euler(0.0, -16.0, 0.0),
		_pose_pierna(-16.0, 24.0, 0.0, 12.0, 3.6),
		_pose_pierna(14.0, 18.0, 0.0, -12.0, -3.6),
		_q_euler(3.0, -40.0, 0.0),
		_q_euler(-2.0, 54.0, 0.0),
		_rot_brazo(1.0, 12.0, 2.0, 24.0, 0.0),
		_rot_codo(1.0, 16.0, 0.0),
		_rot_muneca(1.0, 0.0, 18.0, 0.0),
		_rot_brazo(-1.0, 14.0, 4.0, 22.0, 0.0),
		_rot_codo(-1.0, 88.0, -10.0),
		_rot_muneca(-1.0, 4.0, 0.0, 0.0),
		true, 0.0
	)
	var bow_full_draw := _armar_pose_pose(
		reposos, _q_euler(0.0, -18.0, 0.0),
		_pose_pierna(-18.0, 28.0, 0.0, 14.0, 4.0),
		_pose_pierna(16.0, 20.0, 0.0, -14.0, -4.0),
		_q_euler(2.0, -52.0, -2.0),
		_q_euler(-1.0, 70.0, 2.0),
		# Brazo izquierdo extendido recto al frente (+Z) compensando -24° del arco para flecha horizontal
		_rot_brazo(1.0, 6.0, 0.0, 18.0, 0.0),
		_rot_codo(1.0, 6.0, 0.0),
		_rot_muneca(1.0, 0.0, 22.0, 0.0),
		# Brazo derecho eleva codo atrás y lo flexiona 122° llevando la mano junto a la mejilla
		_rot_brazo(-1.0, 4.0, -4.0, 10.0, -10.0),
		_rot_codo(-1.0, 122.0, -16.0),
		_rot_muneca(-1.0, 6.0, 0.0, 0.0),
		true, 0.0
	)
	var bow_release := _armar_pose_pose(
		reposos, _q_euler(0.0, -16.0, 0.0),
		_pose_pierna(-16.0, 26.0, 0.0, 14.0, 3.8),
		_pose_pierna(15.0, 20.0, 0.0, -14.0, -3.8),
		_q_euler(0.0, -44.0, -1.0),
		_q_euler(0.0, 60.0, 1.0),
		_rot_brazo(1.0, 8.0, 2.0, 22.0, 0.0),
		_rot_codo(1.0, 10.0, 0.0),
		_rot_muneca(1.0, 0.0, 20.0, 0.0),
		# Mano derecha retrocede con crispado natural al soltar la cuerda
		_rot_brazo(-1.0, 12.0, -22.0, -12.0, -10.0),
		_rot_codo(-1.0, 104.0, -12.0),
		_rot_muneca(-1.0, -12.0, 0.0, 0.0),
		true, 0.0, 0.0, -0.008
	)
	var kfs_bow: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		bow_ready.merged({"t": 0.08, "ease": "ease_out"}, true),
		bow_full_draw.merged({"t": 0.20, "ease": "ease_in_out"}, true),
		bow_full_draw.merged({"t": 0.28, "ease": "linear"}, true),
		bow_release.merged({"t": 0.35, "ease": "snap"}, true),
		pose_idle0.merged({"t": 0.50, "ease": "ease_in_out"}, true),
	]
	lib.add_animation(&"shoot-bow", _crear_clip_15huesos(
		skel_rel, "shoot-bow", 0.50, false, reposos,
		_hornear_secuencia(0.50, 30, kfs_bow)
	))

	# --------------------------------------------------------------------------
	# 12. cast-magic (0.54s — concentración con rodillas flex -> proyección arcana)
	# --------------------------------------------------------------------------
	var cast_gather := _armar_pose_pose(
		reposos, _q_euler(0.0, 10.0, 0.0),
		_pose_pierna(-24.0, 44.0, 0.0, 6.0, 3.6),
		_pose_pierna(12.0, 28.0, 0.0, -6.0, -3.6),
		_q_euler(-8.0, 14.0, -2.0),
		_q_euler(-6.0, -14.0, 0.0),
		_rot_brazo(1.0, 40.0, 14.0, 36.0, -10.0),
		_rot_codo(1.0, 96.0, 24.0),
		_rot_muneca(1.0, -12.0, 12.0, 14.0),
		_rot_brazo(-1.0, 24.0, -6.0, -14.0, -12.0),
		_rot_codo(-1.0, 86.0, -20.0),
		_rot_muneca(-1.0, 4.0, -12.0, 0.0),
		true, 0.0
	)
	var cast_release := _armar_pose_pose(
		reposos, _q_euler(0.0, -12.0, 0.0),
		_pose_pierna(-16.0, 20.0, 0.0, 6.0, 3.4),
		_pose_pierna(20.0, 16.0, 18.0, -6.0, -3.4),
		_q_euler(16.0, -14.0, 2.0),
		_q_euler(-12.0, 14.0, 0.0),
		_rot_brazo(1.0, 16.0, 10.0, 74.0, 0.0),
		_rot_codo(1.0, 16.0, 10.0),
		_rot_muneca(1.0, -18.0, 0.0, 0.0),
		_rot_brazo(-1.0, 18.0, 14.0, 72.0, -12.0),
		_rot_codo(-1.0, 20.0, -12.0),
		_rot_muneca(-1.0, 24.0, -14.0, 0.0),
		true, 0.012, 0.0, 0.020
	)
	var kfs_cast: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		cast_gather.merged({"t": 0.16, "ease": "ease_in_out"}, true),
		cast_release.merged({"t": 0.30, "ease": "snap"}, true),
		cast_release.merged({"t": 0.38, "ease": "ease_out"}, true),
		pose_idle0.merged({"t": 0.54, "ease": "ease_in_out"}, true),
	]
	lib.add_animation(&"cast-magic", _crear_clip_15huesos(
		skel_rel, "cast-magic", 0.54, false, reposos,
		_hornear_secuencia(0.54, 30, kfs_cast)
	))

	# --------------------------------------------------------------------------
	# 13. whirlwind (0.52s — muestreo fino continuo sin atajos SLERP en 360°)
	# --------------------------------------------------------------------------
	var whirl_poses: Array = []
	var whirl_n := 24
	for wi in range(whirl_n + 1):
		var u := float(wi) / float(whirl_n)
		# Curva con breve carga inicial y aceleración de giro explosiva en la parte media
		var rot_frac := smoothstep(0.06, 0.90, u)
		var yaw_world := -360.0 * rot_frac
		var spin_amp := sin(clampf((u - 0.04) / 0.88, 0.0, 1.0) * PI)
		var knee_bend := lerpf(24.0, 36.0, spin_amp)
		var hip_l := lerpf(-16.0, -22.0, spin_amp)
		var hip_r := lerpf(12.0, 18.0, spin_amp)
		var w_arm_l := _rot_brazo(1.0, lerpf(62.0, 22.0, spin_amp), lerpf(12.0, 14.0, spin_amp), lerpf(16.0, 42.0, spin_amp), -10.0)
		var w_fore_l := _rot_codo(1.0, lerpf(74.0, 62.0, spin_amp), 14.0)
		var w_arm_r := _rot_brazo(-1.0, lerpf(66.0, 14.0, spin_amp), 2.0, lerpf(16.0, -4.0, spin_amp), 0.0)
		var w_fore_r := _rot_codo(-1.0, lerpf(62.0, 10.0, spin_amp), 0.0)
		var p_w := _armar_pose_pose(
			reposos, _q_euler(0.0, yaw_world, 6.0 * spin_amp),
			_pose_pierna(hip_l, knee_bend, 0.0, 6.0, 4.5),
			_pose_pierna(hip_r, knee_bend - 4.0, 0.0, -6.0, -4.5),
			_q_euler(14.0 * spin_amp + 4.0, -18.0 * spin_amp, -4.0 * spin_amp),
			_q_euler(-10.0 * spin_amp, 12.0 * spin_amp, 0.0),
			w_arm_l, w_fore_l, pc["hand_l"],
			w_arm_r, w_fore_r, _rot_muneca(-1.0, lerpf(4.0, -82.0, spin_amp), 0.0, 0.0),
			true, 0.008 * spin_amp
		)
		p_w["t"] = 0.52 * u
		whirl_poses.append(p_w)
	lib.add_animation(&"whirlwind", _crear_clip_15huesos(skel_rel, "whirlwind", 0.52, false, reposos, whirl_poses))

	# --------------------------------------------------------------------------
	# 14. dash (0.36s — embestida rasante con rodilla delantera doblada y atrás extendida)
	# --------------------------------------------------------------------------
	var dash_peak := _armar_pose_pose(
		reposos, _q_euler(0.0, -12.0 if clase_id == "warrior" else 0.0, 0.0),
		_pose_pierna(-42.0, 64.0, 0.0, 4.0, 3.0),
		_pose_pierna(36.0, 24.0, 26.0, -4.0, -3.0),
		_q_euler(28.0, -16.0 if clase_id == "warrior" else 4.0, 0.0),
		_q_euler(-22.0, 16.0 if clase_id == "warrior" else -4.0, 0.0),
		_rot_brazo(1.0, 50.0 if clase_id == "warrior" else 64.0, 28.0 if clase_id == "warrior" else -30.0, 40.0 if clase_id == "warrior" else 0.0, -14.0 if clase_id == "warrior" else 0.0),
		_rot_codo(1.0, 82.0 if clase_id == "warrior" else 46.0, 16.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 64.0, -34.0, 0.0, 6.0),
		_rot_codo(-1.0, 52.0, 0.0),
		pc["hand_r"],
		true, 0.010, 0.0, 0.025
	)
	var dash_brake := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-24.0, 44.0, 0.0, 5.0, 3.2),
		_pose_pierna(18.0, 28.0, 0.0, -5.0, -3.2),
		_q_euler(14.0, 0.0, 0.0),
		_q_euler(-10.0, 0.0, 0.0),
		pc["arm_l"], pc["forearm_l"], pc["hand_l"],
		pc["arm_r"], pc["forearm_r"], pc["hand_r"],
		true, 0.0
	)
	var kfs_dash: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		dash_peak.merged({"t": 0.09, "ease": "snap"}, true),
		dash_peak.merged({"t": 0.21, "ease": "linear"}, true),
		dash_brake.merged({"t": 0.29, "ease": "ease_out"}, true),
		pose_idle0.merged({"t": 0.36, "ease": "ease_in_out"}, true),
	]
	lib.add_animation(&"dash", _crear_clip_15huesos(
		skel_rel, "dash", 0.36, false, reposos,
		_hornear_secuencia(0.36, 30, kfs_dash)
	))

	# --------------------------------------------------------------------------
	# 15. hit (0.32s — retroceso articular rápido con absorción en rodillas)
	# --------------------------------------------------------------------------
	var hit_recoil := _armar_pose_pose(
		reposos, _q_euler(-4.0, 10.0, -3.0),
		_pose_pierna(-16.0, 34.0, 0.0, 5.0, 3.8),
		_pose_pierna(16.0, 30.0, 0.0, -5.0, -3.8),
		_q_euler(-22.0, 14.0, -6.0),
		_q_euler(-18.0, -14.0, 6.0),
		_rot_brazo(1.0, 46.0, -18.0, -10.0, 0.0),
		_rot_codo(1.0, 68.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 48.0, -18.0, -10.0, 0.0),
		_rot_codo(-1.0, 70.0, 0.0),
		pc["hand_r"],
		true, 0.0, 0.0, -0.020
	)
	var kfs_hit: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		hit_recoil.merged({"t": 0.08, "ease": "snap"}, true),
		pose_idle0.merged({"t": 0.32, "ease": "ease_out"}, true),
	]
	lib.add_animation(&"hit", _crear_clip_15huesos(
		skel_rel, "hit", 0.32, false, reposos,
		_hornear_secuencia(0.32, 30, kfs_hit)
	))

	# --------------------------------------------------------------------------
	# 16. crouch (1.2s loop — sentadilla táctica real con rodillas a 84° y botas planas)
	# --------------------------------------------------------------------------
	var crouch_poses: Array = []
	for ci in range(17):
		var u := float(ci) / 16.0
		var r := sin(u * TAU)
		var hip_c := -42.0 - r * 2.5
		var knee_c := 82.0 + r * 4.5
		var p_c := _armar_pose_pose(
			reposos, _q_euler(0.0, -6.0, 0.0),
			_pose_pierna(hip_c, knee_c, 0.0, 8.0, 4.5),
			_pose_pierna(hip_c + 4.0, knee_c - 6.0, 0.0, -8.0, -4.5),
			_q_euler(24.0 + r * 2.0, -6.0, 0.0),
			_q_euler(-18.0 - r * 1.5, 6.0, 0.0),
			_rot_brazo(1.0, 56.0 - r * 2.0, 22.0, 30.0, -8.0),
			_rot_codo(1.0, 84.0 + r * 3.0, 14.0),
			pc["hand_l"],
			_rot_brazo(-1.0, 58.0 - r * 2.0, 18.0, 26.0, 6.0),
			_rot_codo(-1.0, 82.0 + r * 3.0, 10.0),
			pc["hand_r"],
			true, 0.0
		)
		p_c["t"] = 1.2 * u
		crouch_poses.append(p_c)
	lib.add_animation(&"crouch", _crear_clip_15huesos(skel_rel, "crouch", 1.2, true, reposos, crouch_poses))

	# --------------------------------------------------------------------------
	# 17. jump (0.56s — anticipación en flexión -> salto extendido -> recogimiento -> aterrizaje)
	# --------------------------------------------------------------------------
	var jmp_prep := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-34.0, 68.0, 0.0, 5.0, 3.6),
		_pose_pierna(-30.0, 62.0, 0.0, -5.0, -3.6),
		_q_euler(20.0, 0.0, 0.0),
		_q_euler(-12.0, 0.0, 0.0),
		_rot_brazo(1.0, 64.0, -24.0, 4.0, 0.0),
		_rot_codo(1.0, 42.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 64.0, -24.0, 4.0, 0.0),
		_rot_codo(-1.0, 44.0, 0.0),
		pc["hand_r"],
		true, 0.0
	)
	var jmp_launch := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-8.0, 12.0, 38.0, 4.0, 3.0),
		_pose_pierna(12.0, 18.0, 42.0, -4.0, -3.0),
		_q_euler(-4.0, 0.0, 0.0),
		_q_euler(2.0, 0.0, 0.0),
		_rot_brazo(1.0, -18.0, 26.0, 16.0, 0.0),
		_rot_codo(1.0, 34.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, -14.0, 24.0, 16.0, 0.0),
		_rot_codo(-1.0, 38.0, 0.0),
		pc["hand_r"],
		false, 0.135
	)
	var jmp_tuck := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-42.0, 82.0, 20.0, 4.0, 4.5, 0.0, 0.0, false),
		_pose_pierna(-18.0, 52.0, 24.0, -4.0, -4.5, 0.0, 0.0, false),
		_q_euler(12.0, 0.0, 0.0),
		_q_euler(-8.0, 0.0, 0.0),
		_rot_brazo(1.0, 20.0, 24.0, 22.0, 0.0),
		_rot_codo(1.0, 74.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 22.0, 22.0, 22.0, 0.0),
		_rot_codo(-1.0, 72.0, 0.0),
		pc["hand_r"],
		false, 0.145
	)
	var jmp_land := _armar_pose_pose(
		reposos, Quaternion.IDENTITY,
		_pose_pierna(-28.0, 56.0, 0.0, 5.0, 3.8),
		_pose_pierna(-22.0, 46.0, 0.0, -5.0, -3.8),
		_q_euler(16.0, 0.0, 0.0),
		_q_euler(-10.0, 0.0, 0.0),
		_rot_brazo(1.0, 52.0, 16.0, 20.0, 0.0),
		_rot_codo(1.0, 68.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 52.0, 16.0, 20.0, 0.0),
		_rot_codo(-1.0, 68.0, 0.0),
		pc["hand_r"],
		true, 0.0
	)
	var kfs_jump: Array = [
		jmp_prep.merged({"t": 0.00}, true),
		jmp_launch.merged({"t": 0.14, "ease": "ease_out"}, true),
		jmp_tuck.merged({"t": 0.28, "ease": "ease_in_out"}, true),
		jmp_land.merged({"t": 0.44, "ease": "ease_in"}, true),
		pose_idle0.merged({"t": 0.56, "ease": "ease_out"}, true),
	]
	lib.add_animation(&"jump", _crear_clip_15huesos(
		skel_rel, "jump", 0.56, false, reposos,
		_hornear_secuencia(0.56, 30, kfs_jump)
	))

	# --------------------------------------------------------------------------
	# 18. fall (0.64s loop — equilibrio aéreo dinámico con rodillas dobladas)
	# --------------------------------------------------------------------------
	var fall_poses: Array = []
	for fi in range(17):
		var u := float(fi) / 16.0
		var w := sin(u * TAU)
		var p_f := _armar_pose_pose(
			reposos, Quaternion.IDENTITY,
			_pose_pierna(-34.0 + w * 6.0, 68.0 - w * 8.0, 18.0, 4.0, 5.0, 0.0, 0.0, false),
			_pose_pierna(-12.0 - w * 6.0, 44.0 + w * 8.0, 24.0, -4.0, -5.0, 0.0, 0.0, false),
			_q_euler(12.0 + w * 2.0, 0.0, w * 2.5),
			_q_euler(-8.0 - w * 2.0, 0.0, -w * 2.0),
			_rot_brazo(1.0, 12.0 + w * 10.0, 22.0, 14.0, 0.0),
			_rot_codo(1.0, 54.0 + w * 8.0, 0.0),
			pc["hand_l"],
			_rot_brazo(-1.0, 14.0 - w * 10.0, 20.0, 14.0, 0.0),
			_rot_codo(-1.0, 56.0 - w * 8.0, 0.0),
			pc["hand_r"],
			false, 0.030 + w * 0.008
		)
		p_f["t"] = 0.64 * u
		fall_poses.append(p_f)
	lib.add_animation(&"fall", _crear_clip_15huesos(skel_rel, "fall", 0.64, true, reposos, fall_poses))

	# --------------------------------------------------------------------------
	# 19. die (1.00s — tambaleo -> colapso de rodillas -> caída natural sin flotar)
	# --------------------------------------------------------------------------
	var die_stagger := _armar_pose_pose(
		reposos, _q_euler(-8.0, 8.0, -3.0),
		_pose_pierna(-14.0, 32.0, 0.0, 6.0, 4.0),
		_pose_pierna(10.0, 34.0, 0.0, -6.0, -4.0),
		_q_euler(-18.0, 12.0, -5.0),
		_q_euler(-16.0, -10.0, 4.0),
		_rot_brazo(1.0, 42.0, -14.0, -8.0, 0.0),
		_rot_codo(1.0, 52.0, 0.0),
		pc["hand_l"],
		_rot_brazo(-1.0, 46.0, -12.0, -6.0, 0.0),
		_rot_codo(-1.0, 56.0, 0.0),
		pc["hand_r"],
		true, 0.0
	)
	var die_kneel := _armar_pose_pose(
		reposos, _q_euler(-24.0, 4.0, 0.0),
		_pose_pierna(-32.0, 102.0, 28.0, 8.0, 6.0, 0.0, 0.0, false),
		_pose_pierna(-24.0, 96.0, 26.0, -8.0, -6.0, 0.0, 0.0, false),
		_q_euler(18.0, 6.0, 2.0),
		_q_euler(14.0, -6.0, 0.0),
		_rot_brazo(1.0, 58.0, 12.0, 10.0, 12.0),
		_rot_codo(1.0, 38.0, 0.0),
		_rot_muneca(1.0, 0.0, 0.0, 0.0),
		_rot_brazo(-1.0, 58.0, 8.0, 8.0, -14.0),
		_rot_codo(-1.0, 44.0, 0.0),
		_rot_muneca(-1.0, 0.0, 0.0, 0.0),
		false, -0.075, 0.0, -0.025
	)
	var die_down := _armar_pose_pose(
		reposos, _q_euler(-84.0, 6.0, 4.0),
		_pose_pierna(-12.0, 26.0, 18.0, 8.0, 10.0, 0.0, 0.0, false),
		_pose_pierna(-18.0, 34.0, 22.0, -8.0, -10.0, 0.0, 0.0, false),
		_q_euler(-4.0, 0.0, 0.0),
		_q_euler(14.0, 12.0, -4.0),
		_rot_brazo(1.0, 32.0, -12.0, -24.0, 34.0),
		_rot_codo(1.0, 28.0, 0.0),
		_rot_muneca(1.0, 0.0, 0.0, 0.0),
		_rot_brazo(-1.0, 36.0, -14.0, -20.0, -42.0),
		_rot_codo(-1.0, 34.0, 0.0),
		_rot_muneca(-1.0, 0.0, 0.0, 0.0),
		false, 0.074, 0.0, -0.095
	)
	var die_rest := _armar_pose_pose(
		reposos, _q_euler(-86.0, 6.0, 4.0),
		_pose_pierna(-8.0, 18.0, 16.0, 10.0, 11.0, 0.0, 0.0, false),
		_pose_pierna(-14.0, 24.0, 18.0, -10.0, -11.0, 0.0, 0.0, false),
		_q_euler(-2.0, 0.0, 0.0),
		_q_euler(10.0, 16.0, -6.0),
		_rot_brazo(1.0, 26.0, -14.0, -28.0, 38.0),
		_rot_codo(1.0, 20.0, 0.0),
		_rot_muneca(1.0, 0.0, 0.0, 0.0),
		_rot_brazo(-1.0, 30.0, -14.0, -24.0, -48.0),
		_rot_codo(-1.0, 24.0, 0.0),
		_rot_muneca(-1.0, 0.0, 0.0, 0.0),
		false, 0.070, 0.0, -0.105
	)
	var kfs_die: Array = [
		pose_idle0.merged({"t": 0.00}, true),
		die_stagger.merged({"t": 0.18, "ease": "ease_out"}, true),
		die_kneel.merged({"t": 0.44, "ease": "ease_in_out"}, true),
		die_down.merged({"t": 0.74, "ease": "ease_in"}, true),
		die_rest.merged({"t": 0.88, "ease": "ease_out"}, true),
		die_rest.merged({"t": 1.00, "ease": "linear"}, true),
	]
	lib.add_animation(&"die", _crear_clip_15huesos(
		skel_rel, "die", 1.00, false, reposos,
		_hornear_secuencia(1.00, 30, kfs_die)
	))

	# --------------------------------------------------------------------------
	# 20. telegraph (0.80s loop — postura cargada de poder con rodillas y codos en tensión)
	# --------------------------------------------------------------------------
	var tel_poses: Array = []
	for ti in range(17):
		var u := float(ti) / 16.0
		var pulse := sin(u * TAU)
		var p_t := _armar_pose_pose(
			reposos, _q_euler(0.0, -10.0, 0.0),
			_pose_pierna(-24.0 - pulse * 2.0, 44.0 + pulse * 4.0, 0.0, 8.0, 4.0),
			_pose_pierna(20.0 - pulse * 1.5, 34.0 + pulse * 3.0, 0.0, -8.0, -4.0),
			_q_euler(-10.0 - pulse * 3.0, -22.0 - pulse * 3.0, -3.0),
			_q_euler(6.0 + pulse * 2.0, 28.0 + pulse * 3.0, 2.0),
			_rot_brazo(1.0, 44.0, 26.0, 36.0, -10.0),
			_rot_codo(1.0, 84.0, 14.0),
			pc["hand_l"],
			_rot_brazo(-1.0, 16.0, -28.0 - pulse * 4.0, -24.0, 18.0),
			_rot_codo(-1.0, 94.0 + pulse * 4.0, 16.0),
			_rot_muneca(-1.0, -10.0, -12.0, 0.0),
			true, 0.0
		)
		p_t["t"] = 0.80 * u
		tel_poses.append(p_t)
	lib.add_animation(&"telegraph", _crear_clip_15huesos(skel_rel, "telegraph", 0.80, true, reposos, tel_poses))

	# --------------------------------------------------------------------------
	# 21. stunned (1.10s loop — balanceo inestable en forma de 8 con cabeza pesada)
	# --------------------------------------------------------------------------
	var stn_poses: Array = []
	for si in range(21):
		var u := float(si) / 20.0
		var ph := u * TAU
		var sx := sin(ph)
		var cx := cos(ph * 2.0)
		var p_s := _armar_pose_pose(
			reposos, _q_euler(0.0, sx * 4.0, sx * 3.5),
			_pose_pierna(-20.0 + cx * 3.0, 42.0 - cx * 4.0, 0.0, 5.0, 4.2 - sx * 1.5),
			_pose_pierna(16.0 - cx * 3.0, 36.0 + cx * 4.0, 0.0, -5.0, -4.2 - sx * 1.5),
			_q_euler(18.0 + cx * 3.0, sx * 10.0, sx * 6.0),
			_q_euler(18.0 - cx * 2.0, -sx * 12.0, -sx * 8.0),
			_rot_brazo(1.0, 74.0, 10.0 + cx * 4.0, 8.0, 0.0),
			_rot_codo(1.0, 26.0 + sx * 4.0, 0.0),
			pc["hand_l"],
			_rot_brazo(-1.0, 74.0, 10.0 - cx * 4.0, 8.0, 0.0),
			_rot_codo(-1.0, 28.0 - sx * 4.0, 0.0),
			pc["hand_r"],
			true, 0.0, sx * 0.014, 0.0
		)
		p_s["t"] = 1.10 * u
		stn_poses.append(p_s)
	lib.add_animation(&"stunned", _crear_clip_15huesos(skel_rel, "stunned", 1.10, true, reposos, stn_poses))

	for old_lib: StringName in ap.get_animation_library_list():
		ap.remove_animation_library(old_lib)
	ap.add_animation_library(&"", lib)
