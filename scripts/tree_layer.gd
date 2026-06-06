extends Node2D

var _tree_positions: Array[Vector2i] = []


func set_tree_positions(positions: Array[Vector2i]) -> void:
	_tree_positions = positions
	queue_redraw()


func _draw() -> void:
	var ts := float(Constants.TILE_SIZE)
	var dark_leaf := Color(0.06, 0.42, 0.06)
	for gp: Vector2i in _tree_positions:
		var wp := Vector2(gp.x * ts, gp.y * ts)
		draw_rect(Rect2(wp, Vector2(ts, ts)), Constants.COLOR_TREES)
		draw_circle(wp + Vector2(ts * 0.25, ts * 0.25), ts * 0.18, dark_leaf)
		draw_circle(wp + Vector2(ts * 0.75, ts * 0.25), ts * 0.18, dark_leaf)
		draw_circle(wp + Vector2(ts * 0.25, ts * 0.75), ts * 0.18, dark_leaf)
		draw_circle(wp + Vector2(ts * 0.75, ts * 0.75), ts * 0.18, dark_leaf)
