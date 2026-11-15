extends StaticBody3D

var _manager: Node = null
var vida_maxima: float = 600.0
var vida: float = 600.0
var _destruido: bool = false

func configurar_monolito(mgr: Node, hp_max: float = 600.0) -> void:
	_manager = mgr
	vida_maxima = hp_max
	vida = hp_max

func _ready() -> void:
	add_to_group("rompibles")

func recibir_dano(cantidad: float, _fuente = "normal", _es_critico: bool = false) -> void:
	if _destruido:
		return
	vida -= cantidad
	var lbl = get_node_or_null("Label3D") as Label3D
	if lbl != null:
		lbl.text = "🗿 MONOLITO DEL CAMPEÓN CAÍDO\n[%d / %d HP]" % [maxi(0, int(ceil(vida))), int(vida_maxima)]
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.08, 0.04)
	tw.tween_property(self, "scale", Vector3.ONE, 0.07)
	if vida <= 0.0:
		_destruido = true
		if _manager != null and is_instance_valid(_manager) and _manager.has_method("_on_monolito_destruido_externo"):
			_manager._on_monolito_destruido_externo(global_position)
		queue_free()
