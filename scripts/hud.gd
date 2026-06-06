extends Control

var _score_label: Label
var _hi_label: Label
var _level_label: Label
var _lives: int = 3
var _enemies: int = 0


func _ready() -> void:
	position = Vector2(416.0, 0.0)
	size = Vector2(96.0, 416.0)

	_header("1-UP",  Vector2(8.0,   6.0))
	_score_label = _value("00000", Vector2(8.0,  18.0), Color(1.0, 0.6, 0.1))

	_header("HI",    Vector2(8.0,  40.0))
	_hi_label    = _value("00000", Vector2(8.0,  52.0), Color(1.0, 0.6, 0.1))

	_header("STAGE", Vector2(8.0,  72.0))
	_level_label = _value("01",    Vector2(30.0, 82.0), Color.WHITE, 14)

	_header("P1",    Vector2(8.0, 210.0))

	GameManager.lives_changed.connect(_on_stat)
	GameManager.score_changed.connect(_on_stat)
	GameManager.level_changed.connect(_on_stat)
	GameManager.enemies_changed.connect(_on_stat)

	_sync()
	queue_redraw()


func _header(text: String, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)


func _value(text: String, pos: Vector2, col: Color, sz: int = 10) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", col)
	add_child(lbl)
	return lbl


func _on_stat(_v: int) -> void:
	_sync()
	queue_redraw()


func _sync() -> void:
	_score_label.text = "%05d" % GameManager.score
	_hi_label.text    = "%05d" % GameManager.high_score
	_level_label.text = "%02d" % GameManager.current_level
	_lives   = GameManager.lives
	_enemies = GameManager.enemies_remaining


func _draw() -> void:
	# Sidebar background
	draw_rect(Rect2(0.0, 0.0, 96.0, 416.0), Color(0.06, 0.06, 0.09))

	# Separator lines
	_sep(98.0)
	_sep(198.0)
	_sep(262.0)

	_draw_enemy_icons()
	_draw_lives_icons()


func _sep(y: float) -> void:
	draw_rect(Rect2(6.0, y, 84.0, 1.0), Color(0.35, 0.35, 0.38))


func _draw_enemy_icons() -> void:
	var count := mini(_enemies, 20)
	var y0 := 105.0
	var row_step := 10.0
	for i in range(count):
		var col := i % 2
		var row := i / 2
		var cx := 22.0 if col == 0 else 56.0
		var cy := y0 + row * row_step
		_mini_tank(Vector2(cx, cy), Constants.COLOR_ENEMY)


func _draw_lives_icons() -> void:
	for i in range(mini(_lives, 7)):
		_mini_tank(Vector2(8.0 + i * 12.0, 222.0), Constants.COLOR_PLAYER)


func _mini_tank(center: Vector2, color: Color) -> void:
	# 6×6 body
	draw_rect(Rect2(center.x - 3.0, center.y - 3.0, 6.0, 6.0), color)
	# 2×4 barrel pointing up
	draw_rect(Rect2(center.x - 1.0, center.y - 6.0, 2.0, 4.0), color)
