extends "res://santuario_base.gd"
class_name FuenteDeseos

## FuenteDeseos - Santuario de apuesta multi-uso (hasta 5 deseos).
## Cada deseo incrementa el costo en Denarios un +50% (ceili).
## La Suerte efectiva reduce el peso del resultado vacío ("Nada").

const MAX_USOS: int = 5
const ESCENA_DROP = preload("res://drop_item.tscn")

const STATS_DESEO := [
	{"id": "dano", "titulo": "⚔️ Filo Mortal"},
	{"id": "cadencia", "titulo": "⚡ Furia Veloz"},
	{"id": "vida", "titulo": "🛡️ Vitalidad"},
	{"id": "velocidad", "titulo": "👟 Agilidad"},
	{"id": "critico", "titulo": "🎯 Precisión Letal"},
	{"id": "iman", "titulo": "🧲 Imán Rúnico"},
	{"id": "fortuna", "titulo": "🍀 Fortuna del Coliseo"},
]

var _usos_actuales: int = 0
var _orbe_agua: MeshInstance3D = null

func _configurar_santuario() -> void:
	nombre_santuario = "Fuente de los Deseos"
	costo_denarios = 3
	radio_interaccion = 5.5
	un_solo_uso = false
	activacion_por_clic = true
	color_luz = Color(0.22, 0.84, 1.0)
	altura_etiqueta = 3.2

func _construir_visual() -> void:
	# Tazón exterior de mármol blanco
	var pileta := MeshInstance3D.new()
	var m_pileta := CylinderMesh.new()
	m_pileta.top_radius = 1.25
	m_pileta.bottom_radius = 0.95
	m_pileta.height = 0.55
	m_pileta.radial_segments = 16
	m_pileta.material = _crear_material(Color(0.85, 0.88, 0.92), Color(0.1, 0.35, 0.55), 0.2, 0.15, 0.5)
	pileta.mesh = m_pileta
	pileta.position = Vector3(0.0, 0.275, 0.0)
	visual_root.add_child(pileta)

	# Espejo de agua brillante
	var agua := MeshInstance3D.new()
	var m_agua := CylinderMesh.new()
	m_agua.top_radius = 1.08
	m_agua.bottom_radius = 1.08
	m_agua.height = 0.08
	m_agua.radial_segments = 16
	m_agua.material = _crear_material(Color(0.18, 0.78, 0.98), Color(0.22, 0.88, 1.0), 1.4, 0.3, 0.1)
	agua.mesh = m_agua
	agua.position = Vector3(0.0, 0.55, 0.0)
	visual_root.add_child(agua)

	# Pedestal central de la fuente
	var surtidor := MeshInstance3D.new()
	var m_surtidor := CylinderMesh.new()
	m_surtidor.top_radius = 0.22
	m_surtidor.bottom_radius = 0.36
	m_surtidor.height = 1.05
	m_surtidor.radial_segments = 12
	m_surtidor.material = _crear_material(Color(0.88, 0.86, 0.80), Color(0.15, 0.55, 0.85), 0.35, 0.25, 0.35)
	surtidor.mesh = m_surtidor
	surtidor.position = Vector3(0.0, 1.02, 0.0)
	visual_root.add_child(surtidor)

	# Gota / orbe celeste flotante sobre el surtidor
	_orbe_agua = MeshInstance3D.new()
	var m_orbe := SphereMesh.new()
	m_orbe.radius = 0.32
	m_orbe.height = 0.64
	m_orbe.material = _crear_material(Color(0.35, 0.92, 1.0), Color(0.25, 0.88, 1.0), 1.9, 0.4, 0.1)
	_orbe_agua.mesh = m_orbe
	_orbe_agua.position = Vector3(0.0, 1.92, 0.0)
	visual_root.add_child(_orbe_agua)

	_actualizar_etiqueta("Usos 0/%d" % MAX_USOS)

func _process(delta: float) -> void:
	if _consumido or _orbe_agua == null:
		return
	_orbe_agua.rotate_y(delta * 1.8)
	_orbe_agua.position.y = 1.92 + sin(Time.get_ticks_msec() * 0.0045) * 0.11

func _activar(pj: Node3D) -> bool:
	if _usos_actuales >= MAX_USOS:
		return false
	if not _cobrar(pj):
		return false

	# La suerte efectiva reduce el peso de "Nada" y lo redistribuye hacia los premios
	var l_raw: float = FortunaManager.obtener_suerte_efectiva()
	var w_nada: float = 35.0
	if l_raw >= 0.0:
		w_nada = 35.0 / (1.0 + l_raw)
	else:
		w_nada = 35.0 * (1.0 + clampf(-l_raw, 0.0, 0.55))

	var bono_desplazado: float = 35.0 - w_nada
	var w_oro: float = maxf(5.0, 30.0 + bono_desplazado * 0.46)
	var w_stat: float = maxf(5.0, 25.0 + bono_desplazado * 0.38)
	var w_dup: float = maxf(3.0, 10.0 + bono_desplazado * 0.16)
	var total: float = w_nada + w_oro + w_stat + w_dup

	var r_deseo: float = FortunaManager.rng.randf_range(0.0, total)
	if r_deseo < w_nada:
		_spawn_texto_3d("💧 El agua guarda silencio...", Color(0.62, 0.78, 0.94))
		AudioManager.play("click", 0.72)
	elif r_deseo < w_nada + w_oro:
		_otorgar_lluvia_oro(pj)
	elif r_deseo < w_nada + w_oro + w_stat:
		var rareza: int = FortunaManager.tirar_rareza(Rareza.RARO)
		var mult: float = FortunaManager.obtener_multiplicador_rareza(rareza)
		var idx: int = FortunaManager.rng.randi_range(0, STATS_DESEO.size() - 1)
		var stat: Dictionary = STATS_DESEO[idx]
		if pj.has_method("aplicar_mejora"):
			pj.aplicar_mejora(String(stat["id"]), mult)
		AudioManager.play("legendario" if rareza == Rareza.LEGENDARIO else "puzzle_completo", 1.1)
		_spawn_texto_3d("✨ %s [%s]" % [String(stat["titulo"]), Rareza.obtener_nombre(rareza)], Rareza.obtener_color(rareza))
	else:
		if "duplicar_proxima_carta" in pj:
			pj.duplicar_proxima_carta = true
		AudioManager.play("legendario", 1.08)
		_spawn_texto_3d("🃏 ¡PRÓXIMA CARTA x2!", Color(0.86, 0.42, 1.0))

	_usos_actuales += 1
	costo_denarios = ceili(float(costo_denarios) * 1.5)

	if _usos_actuales >= MAX_USOS:
		_consumir()
	else:
		_actualizar_etiqueta("Usos %d/%d" % [_usos_actuales, MAX_USOS])

	return false

func _otorgar_lluvia_oro(pj: Node3D) -> void:
	if pj != null and pj.has_method("recoger_drop"):
		pj.recoger_drop(0, 40)
	if get_parent() != null:
		for i in range(8):
			var item := ESCENA_DROP.instantiate()
			var ang: float = (TAU / 8.0) * float(i) + FortunaManager.rng.randf_range(-0.2, 0.2)
			var dist: float = FortunaManager.rng.randf_range(1.3, 2.4)
			get_parent().add_child(item)
			item.global_position = global_position + Vector3(cos(ang) * dist, 0.5, sin(ang) * dist)
			if item.has_method("iniciar"):
				item.iniciar(0, 10)
	AudioManager.play("jackpot", 1.12)
	_spawn_texto_3d("🪙 ¡LLUVIA DE ORO!", Color(1.0, 0.88, 0.25))
