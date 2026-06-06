extends Node2D

var _t: float = 0.0
const DURATION: float = 0.55


func _ready() -> void:
	z_index = 3


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p := _t / DURATION
	# Expand 0→0.65, then fade 0.65→1.0
	var expand := minf(p / 0.65, 1.0)
	var alpha := 1.0 if p <= 0.65 else 1.0 - (p - 0.65) / 0.35

	var r_outer := expand * 20.0
	var r_mid   := expand * 13.0
	var r_inner := expand *  7.0

	draw_circle(Vector2.ZERO, r_outer, Color(1.0, 0.35, 0.0, alpha * 0.55))
	draw_circle(Vector2.ZERO, r_mid,   Color(1.0, 0.62, 0.0, alpha * 0.80))
	draw_circle(Vector2.ZERO, r_inner, Color(1.0, 0.92, 0.45, alpha))
