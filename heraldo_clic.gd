extends "res://enemigo_base.gd"
class_name HeraldoClic

## Heraldo del Clic — Élite de Fiebre / Overdrive x5
## Reemplaza el castigo injusto de invocar la Parca Roja a los 70 clics por un mini-jefe de alta
## recompensa que canaliza energía rúnica, recibe daño amplificado por clics y suelta botín legendario.

var _boton_movil: Node3D = null
var _anillo_halo: MeshInstance3D = null

func _ready() -> void:
	rapidez = 3.6
	vida_maxima = 260.0
	dano_contacto = 18.0
	xp_otorgada = 80
	oro_otorgado = 45
	resistencia_knockback = 0.45
	add_to_group("heraldos_clic")
	add_to_group("jefes")
	_construir_geometria_procedural()
	super._ready()
	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null and _boton_movil.has_signal("click_presionado"):
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _construir_geometria_procedural():
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.65
		cap.height = 2.4
		col.shape = cap
		col.position = Vector3(0, 1.2, 0)
		add_child(col)

	var cuerpo = MeshInstance3D.new()
	cuerpo.name = "MeshInstance3D"
	var prism = PrismMesh.new()
	prism.size = Vector3(1.3, 2.2, 1.3)
	cuerpo.mesh = prism
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.25, 0.85)
	cuerpo.material_override = mat
	cuerpo.position = Vector3(0, 1.2, 0)
	add_child(cuerpo)

	_anillo_halo = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.15
	_anillo_halo.mesh = torus
	var mat_h = StandardMaterial3D.new()
	mat_h.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_h.albedo_color = Color(0.2, 0.95, 1.0)
	_anillo_halo.material_override = mat_h
	_anillo_halo.position = Vector3(0, 1.5, 0)
	add_child(_anillo_halo)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if _anillo_halo != null:
		_anillo_halo.rotate_y(delta * 3.2)
		_anillo_halo.rotate_x(delta * 1.6)
	return super._calcular_velocidad_ia(delta)

func _on_boton_click(_total: int):
	if muerto or not is_instance_valid(self):
		return
	recibir_dano(38.0, true)

func morir() -> void:
	if _muerto:
		return
	var arbol = get_tree()
	var pos_muerte = global_position
	super.morir()
	if arbol != null:
		var pool = arbol.get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(pos_muerte + Vector3(0, 2.6, 0), "⚡ ¡HERALDO DEL CLIC ABATIDO! +45🪙 +80 XP +5⚡", Color(1.0, 0.35, 0.95), 1.4)
	if jugador != null and is_instance_valid(jugador):
		for i in range(5):
			if jugador.has_method("registrar_click_jugador"):
				jugador.registrar_click_jugador(true)
