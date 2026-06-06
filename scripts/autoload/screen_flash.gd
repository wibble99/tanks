extends Node

var _rect: ColorRect
var _layer: CanvasLayer
var _timer: float = 0.0

const DURATION: float = 0.18


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 25
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_rect.position = Vector2.ZERO
	_rect.size = Vector2(512.0, 416.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_rect)


func flash() -> void:
	_timer = DURATION


func _process(delta: float) -> void:
	if _timer > 0.0:
		_timer = maxf(0.0, _timer - delta)
		_rect.color = Color(1.0, 1.0, 1.0, (_timer / DURATION) * 0.55)
	elif _rect.color.a > 0.0:
		_rect.color = Color(1.0, 1.0, 1.0, 0.0)
