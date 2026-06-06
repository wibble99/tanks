extends Control

signal continue_pressed

const NAMES  := ["FIREPOWER", "SPEED", "RANK", "ABILITY"]
const COLORS := [
	Color(1.0, 0.50, 0.10),  # orange
	Color(1.0, 0.85, 0.10),  # yellow
	Color(0.30, 0.85, 1.00), # cyan
	Color(0.40, 1.00, 0.40), # green
]

var _cursor: int = 0
var _points_earned: int = 0
var _blink: bool = true
var _blink_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(512.0, 416.0)
	hide()


func show_screen(pts: int) -> void:
	_points_earned = pts
	_cursor = 0
	_blink = true
	_blink_timer = 0.0
	show()
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_blink_timer += delta
	if _blink_timer >= 0.35:
		_blink_timer = 0.0
		_blink = !_blink
		queue_redraw()
	if Input.is_action_just_pressed("move_up"):
		_cursor = (_cursor - 1 + 5) % 5
		_blink = true
		_blink_timer = 0.0
		queue_redraw()
	elif Input.is_action_just_pressed("move_down"):
		_cursor = (_cursor + 1) % 5
		_blink = true
		_blink_timer = 0.0
		queue_redraw()
	elif Input.is_action_just_pressed("fire"):
		if _cursor == 4:
			hide()
			continue_pressed.emit()
		elif UpgradeManager.buy(_cursor):
			queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(0.0, 0.0, 512.0, 416.0), Color(0.02, 0.04, 0.10, 0.94))

	_ctext(font, "STAGE CLEAR!", 256.0, 16.0, 22, Color(1.0, 0.55, 0.0))
	_ctext(font, "+%d UPGRADE POINTS" % _points_earned, 256.0, 48.0, 10, Color.WHITE)
	_ctext(font, "TOTAL  %d PTS" % UpgradeManager.points, 256.0, 64.0, 9, Color(1.0, 1.0, 0.3))

	draw_rect(Rect2(24.0, 82.0, 464.0, 1.0), Color(0.28, 0.28, 0.28))

	var row_h := 68.0
	var y0 := 88.0
	for i in range(4):
		_draw_row(font, i, y0 + float(i) * row_h)

	var div_y := y0 + 4.0 * row_h
	draw_rect(Rect2(24.0, div_y, 464.0, 1.0), Color(0.28, 0.28, 0.28))

	var cy := div_y + 16.0
	var is_cont := _cursor == 4
	if is_cont:
		draw_rect(Rect2(140.0, cy - 4.0, 232.0, 26.0), Color(0.10, 0.14, 0.28))
	var cont_col := (Color.WHITE if _blink else Color(0.32, 0.32, 0.32)) if is_cont else Color(0.52, 0.52, 0.52)
	_ctext(font, "PRESS FIRE TO CONTINUE", 256.0, cy, 10, cont_col)


func _draw_row(font: Font, type: int, y: float) -> void:
	var is_sel := _cursor == type
	var col: Color = COLORS[type]
	var lv: int = UpgradeManager.levels[type]
	var maxed := lv >= UpgradeManager.MAX_LEVEL

	if is_sel:
		draw_rect(Rect2(20.0, y, 472.0, 60.0), Color(0.10, 0.12, 0.26))

	if is_sel and _blink:
		_ltext(font, ">", 24.0, y + 18.0, 13, col)

	var name_col := col if is_sel else Color(col.r * 0.7, col.g * 0.7, col.b * 0.7)
	_ltext(font, NAMES[type], 42.0, y + 12.0, 12, name_col)

	_ltext(font, _next_desc(type, lv), 42.0, y + 30.0, 8, Color(0.58, 0.58, 0.58))

	for d in range(UpgradeManager.MAX_LEVEL):
		var cx := 316.0 + float(d) * 14.0
		var cy := y + 24.0
		if d < lv:
			draw_circle(Vector2(cx, cy), 4.5, col)
		else:
			draw_arc(Vector2(cx, cy), 4.0, 0.0, TAU, 12,
					Color(col.r * 0.4, col.g * 0.4, col.b * 0.4), 1.5)

	if maxed:
		_ltext(font, "MAXED", 388.0, y + 18.0, 9, Color(0.42, 0.42, 0.42))
	else:
		var cost := UpgradeManager.cost_for(type)
		var can := UpgradeManager.can_buy(type)
		_ltext(font, "%d PTS" % cost, 388.0, y + 12.0, 9,
				Color(1.0, 0.85, 0.0) if can else Color(0.42, 0.42, 0.42))
		if is_sel:
			var hint := "FIRE TO BUY" if can else "NEED MORE PTS"
			var hcol := Color(0.42, 1.0, 0.42) if can else Color(1.0, 0.38, 0.38)
			_ltext(font, hint, 388.0, y + 28.0, 7, hcol)


func _next_desc(type: int, current_lv: int) -> String:
	if current_lv >= UpgradeManager.MAX_LEVEL:
		return "Maximum level reached"
	match type:
		0:  # FIREPOWER
			var pct := (current_lv + 1) * 15
			var extra := " + STAR SHOT" if current_lv + 1 >= 3 else ""
			return "-%d%% fire cooldown%s" % [pct, extra]
		1:  # SPEED
			return "+%d%% move speed" % ((current_lv + 1) * 20)
		2:  # RANK
			return "Start with %d hit points" % (current_lv + 2)
		3:  # ABILITY
			var pnames := ["SHIELD", "STAR SHOT", "FREEZE", "BOMB"]
			return "Start stage: %s" % pnames[current_lv]
	return ""


func _ctext(font: Font, text: String, cx: float, y: float, sz: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(font, Vector2(cx - w * 0.5, y + font.get_ascent(sz)),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _ltext(font: Font, text: String, x: float, y: float, sz: int, col: Color) -> void:
	draw_string(font, Vector2(x, y + font.get_ascent(sz)),
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
