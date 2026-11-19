extends CanvasLayer

signal clase_seleccionada(nombre_clase: String)

const SELLO_GRACIA_INICIAL_MS: int = 850
const SELLO_REBOTE_SPAM_MS: int = 350
const SELLO_MAX_TOTAL_MS: int = 1900

var _apertura_msec: int = 0
var _bloqueado_hasta_msec: int = 0

@onready var btn_guerrero: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardGuerrero/BtnElegirGuerrero
@onready var btn_cazador: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardCazador/BtnElegirCazador
@onready var btn_mago: Button = $Control/Panel/Margin/VBox/HBoxCartas/CardMago/BtnElegirMago

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20 # Por encima de cualquier interfaz normal
	_apertura_msec = Time.get_ticks_msec()
	_bloqueado_hasta_msec = _apertura_msec + SELLO_GRACIA_INICIAL_MS
	
	btn_guerrero.pressed.connect(func(): _on_seleccionar("Murmillo"))
	btn_cazador.pressed.connect(func(): _on_seleccionar("Sagittario"))
	btn_mago.pressed.connect(func(): _on_seleccionar("Arúspice"))

func _on_seleccionar(clase: String):
	var ahora := Time.get_ticks_msec()
	if ahora < _bloqueado_hasta_msec:
		if ahora >= _apertura_msec + 140:
			_bloqueado_hasta_msec = mini(_apertura_msec + SELLO_MAX_TOTAL_MS, maxi(_bloqueado_hasta_msec, ahora + SELLO_REBOTE_SPAM_MS))
		return
	emit_signal("clase_seleccionada", clase)
