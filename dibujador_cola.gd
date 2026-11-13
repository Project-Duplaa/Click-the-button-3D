@tool
extends Control

var punto_origen1: Vector2 = Vector2.ZERO
var punto_origen2: Vector2 = Vector2.ZERO
var punto_destino: Vector2 = Vector2.ZERO
var color_fondo: Color = Color(0.08, 0.09, 0.13, 0.96)
var color_borde: Color = Color(0.85, 0.72, 0.38, 1.0)
var activo: bool = false

func actualizar_cola(p1: Vector2, p2: Vector2, dest: Vector2, visible_cola: bool):
	punto_origen1 = p1
	punto_origen2 = p2
	punto_destino = dest
	activo = visible_cola
	queue_redraw()

func ocultar():
	activo = false
	queue_redraw()

func _draw():
	if not activo:
		return
	var triangulo = PackedVector2Array([punto_origen1, punto_origen2, punto_destino])
	draw_polygon(triangulo, PackedColorArray([color_fondo]))
	draw_line(punto_origen1, punto_destino, color_borde, 1.8, true)
	draw_line(punto_origen2, punto_destino, color_borde, 1.8, true)
