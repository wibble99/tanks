extends Node2D

var _wait_for_input: bool = false
var _blink: bool = false
var _blink_timer: float = 0.0
var _is_high_score: bool = false


func _ready() -> void:
	_is_high_score = GameManager.score > 0 and GameManager.score == GameManager.high_score
	await get_tree().create_timer(2.0).timeout
	_wait_for_input = true


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= 0.5:
		_blink_timer = 0.0
		if _wait_for_input:
			_blink = !_blink
			queue_redraw()

	if _wait_for_input and Input.is_action_just_pressed("fire"):
		get_tree().change_scene_to_file("res://scenes/title.tscn")


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(0.0, 0.0, 512.0, 416.0), Color(0.02, 0.02, 0.05))

	_ctext(font, "GAME  OVER", 256.0, 128.0, 30, Color(1.0, 0.18, 0.18))

	_ctext(font, "SCORE",              256.0, 206.0,  9, Color(0.78, 0.78, 0.78))
	_ctext(font, "%05d" % GameManager.score, 256.0, 220.0, 16, Color(1.0, 0.60, 0.00))

	if _is_high_score:
		_ctext(font, "NEW HIGH SCORE!", 256.0, 254.0, 11, Color(1.0, 1.0, 0.20))

	_ctext(font, "STAGE  %02d" % GameManager.current_level,
			256.0, 282.0, 9, Color(0.60, 0.60, 0.60))

	if _blink:
		_ctext(font, "PRESS SPACE TO CONTINUE", 256.0, 334.0, 10, Color.WHITE)


func _ctext(font: Font, text: String, cx: float, y: float, sz: int, col: Color) -> void:
	var w   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var asc := font.get_ascent(sz)
	draw_string(font, Vector2(cx - w * 0.5, y + asc), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
