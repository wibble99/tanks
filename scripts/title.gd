extends Node2D

var _blink: bool = true
var _blink_timer: float = 0.0


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= 0.5:
		_blink_timer = 0.0
		_blink = !_blink
		queue_redraw()

	if Input.is_action_just_pressed("fire") or Input.is_action_just_pressed("move_up"):
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(0.0, 0.0, 512.0, 416.0), Color(0.02, 0.02, 0.05))

	# Decorative tank silhouettes flanking the title
	_draw_tank(Vector2(90.0, 190.0),  Color(0.90, 0.80, 0.10), 0.0,  14.0)
	_draw_tank(Vector2(422.0, 190.0), Color(0.85, 0.12, 0.12), PI,   14.0)

	# Title
	_ctext(font, "TANK  1990",            256.0, 128.0, 34, Color(1.0, 0.60, 0.00))
	_ctext(font, "B A T T L E   A R E N A", 256.0, 174.0, 10, Color(0.68, 0.68, 0.68))

	# Blinking prompt
	if _blink:
		_ctext(font, "PRESS SPACE TO START", 256.0, 256.0, 10, Color.WHITE)

	# Controls hint
	_ctext(font, "WASD / ARROWS : MOVE", 256.0, 314.0, 8, Color(0.48, 0.48, 0.48))
	_ctext(font, "SPACE / Z : FIRE",     256.0, 328.0, 8, Color(0.48, 0.48, 0.48))

	_ctext(font, "2025", 256.0, 390.0, 8, Color(0.30, 0.30, 0.30))


func _ctext(font: Font, text: String, cx: float, y: float, sz: int, col: Color) -> void:
	var w   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var asc := font.get_ascent(sz)
	draw_string(font, Vector2(cx - w * 0.5, y + asc), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw_tank(center: Vector2, col: Color, angle: float, half: float) -> void:
	draw_set_transform(center, angle)
	var dark := Color(col.r * 0.45, col.g * 0.45, col.b * 0.45)
	var bw   := half * 0.28
	var bl   := half * 1.55
	# body
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), col)
	# barrel
	draw_rect(Rect2(-bw, -(half + bl), bw * 2.0, bl), col)
	# treads (3 notches each side)
	var th := half * 0.32
	var tw := half * 0.42
	for i in range(3):
		var ty := -half + half * 0.18 + float(i) * half * 0.58
		draw_rect(Rect2(-(half + tw), ty, tw, th), dark)
		draw_rect(Rect2(half,          ty, tw, th), dark)
	draw_set_transform(Vector2.ZERO, 0.0)
