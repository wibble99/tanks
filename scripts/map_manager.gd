class_name MapManager
extends Node2D

const LevelData := preload("res://levels/level_data.gd")

signal tile_destroyed(grid_pos: Vector2i)

var _tile_data: Dictionary = {}
var _tile_bodies: Dictionary = {}
var _tree_positions: Array[Vector2i] = []
var _ice_areas: Dictionary = {}
var _fortress_tiles: Dictionary = {}
var _fortress_expiry: float = 0.0

var eagle_grid_pos: Vector2i = Vector2i(12, 24)
var player_spawn_cols: Array[int] = [0, 24]
var enemy_spawn_cols: Array[int] = [0, 12, 24]

@onready var _tree_layer: Node2D = $TreeLayer

		  
func _ready() -> void:
	add_to_group("map_manager")
	var level_data: LevelData = load("res://levels/level_01.tres")
	if level_data:
		load_level(level_data)


func _process(_delta: float) -> void:
	if _fortress_tiles.is_empty():
		return
	var remaining := _fortress_expiry - Time.get_ticks_msec() * 0.001
	if remaining <= 0.0:
		_revert_fortress()
	elif remaining < 3.0:
		queue_redraw()  # drive the flashing animation


func load_level(level_data: LevelData) -> void:
	eagle_grid_pos = Vector2i(level_data.eagle_col, level_data.eagle_row)
	player_spawn_cols.clear()
	for c in level_data.player_spawn_cols:
		player_spawn_cols.append(c)
	enemy_spawn_cols.clear()
	for c in level_data.enemy_spawn_cols:
		enemy_spawn_cols.append(c)
	load_map(level_data.map_rows)


func load_map(rows: PackedStringArray) -> void:
	_clear_tiles()
	for row in range(rows.size()):
		var line: String = rows[row]
		for col in range(line.length()):
			var ch: String = line[col]
			var gp := Vector2i(col, row)
			match ch:
				"B":
					_tile_data[gp] = Constants.TileType.BRICK
					_create_solid_body(gp, Constants.TileType.BRICK)
				"S":
					_tile_data[gp] = Constants.TileType.STEEL
					_create_solid_body(gp, Constants.TileType.STEEL)
				"W":
					_tile_data[gp] = Constants.TileType.WATER
					_create_solid_body(gp, Constants.TileType.WATER)
				"T":
					_tile_data[gp] = Constants.TileType.TREES
					_tree_positions.append(gp)
				"I":
					_tile_data[gp] = Constants.TileType.ICE
					_create_ice_area(gp)
	if _tree_layer:
		_tree_layer.set_tree_positions(_tree_positions)
	queue_redraw()


func _clear_tiles() -> void:
	for body in _tile_bodies.values():
		body.queue_free()
	for area in _ice_areas.values():
		area.queue_free()
	_tile_data.clear()
	_tile_bodies.clear()
	_tree_positions.clear()
	_ice_areas.clear()
	_fortress_tiles.clear()
	_fortress_expiry = 0.0


func _create_solid_body(gp: Vector2i, tile_type: int) -> void:
	var body := StaticBody2D.new()
	body.position = grid_to_world_center(gp)
	var layer := Constants.LAYER_WATER if tile_type == Constants.TileType.WATER else Constants.LAYER_WALLS
	body.collision_layer = layer
	body.collision_mask = 0
	body.set_meta("tile_type", tile_type)
	body.set_meta("grid_pos", gp)
	body.set_meta("bullet_passable", tile_type == Constants.TileType.WATER)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	shape.shape = rect_shape
	body.add_child(shape)
	add_child(body)
	_tile_bodies[gp] = body


func _create_ice_area(gp: Vector2i) -> void:
	var area := Area2D.new()
	area.position = grid_to_world_center(gp)
	area.set_meta("tile_type", Constants.TileType.ICE)
	area.set_meta("grid_pos", gp)
	area.collision_layer = 0
	area.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	shape.shape = rect_shape
	area.add_child(shape)
	add_child(area)
	_ice_areas[gp] = area


func destroy_tile(gp: Vector2i, force: bool = false) -> bool:
	if not _tile_data.has(gp):
		return false
	var t: int = _tile_data[gp]
	if t == Constants.TileType.STEEL and not force:
		return false
	if t != Constants.TileType.BRICK and t != Constants.TileType.STEEL:
		return false
	_tile_data.erase(gp)
	if _tile_bodies.has(gp):
		_tile_bodies[gp].queue_free()
		_tile_bodies.erase(gp)
	queue_redraw()
	tile_destroyed.emit(gp)
	return true


func get_tile_at(gp: Vector2i) -> int:
	return _tile_data.get(gp, Constants.TileType.EMPTY)


func is_tile_bullet_passable(gp: Vector2i) -> bool:
	var t: int = get_tile_at(gp)
	return t == Constants.TileType.WATER or t == Constants.TileType.TREES or t == Constants.TileType.EMPTY


func grid_to_world(gp: Vector2i) -> Vector2:
	return Vector2(gp.x * Constants.TILE_SIZE, gp.y * Constants.TILE_SIZE)


func grid_to_world_center(gp: Vector2i) -> Vector2:
	return Vector2(
		gp.x * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5,
		gp.y * Constants.TILE_SIZE + Constants.TILE_SIZE * 0.5
	)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / Constants.TILE_SIZE),
		int(world_pos.y / Constants.TILE_SIZE)
	)


func get_tree_positions() -> Array[Vector2i]:
	return _tree_positions


func get_player_spawns() -> Array[Vector2]:
	var spawns: Array[Vector2] = []
	for col in player_spawn_cols:
		spawns.append(grid_to_world_center(Vector2i(col, eagle_grid_pos.y)))
	return spawns


func get_enemy_spawns() -> Array[Vector2]:
	var spawns: Array[Vector2] = []
	for col in enemy_spawn_cols:
		spawns.append(grid_to_world_center(Vector2i(col, 0)))
	return spawns


func fortify_eagle(duration: float) -> void:
	_fortress_expiry = Time.get_ticks_msec() * 0.001 + duration
	# Scan the standard protection zone around the eagle and upgrade BRICK → STEEL
	for dy in range(-1, 2):
		for dx in range(-2, 5):
			var gp := eagle_grid_pos + Vector2i(dx, dy)
			if _tile_data.get(gp, Constants.TileType.EMPTY) == Constants.TileType.BRICK:
				_tile_data[gp] = Constants.TileType.STEEL
				if _tile_bodies.has(gp):
					_tile_bodies[gp].set_meta("tile_type", Constants.TileType.STEEL)
				_fortress_tiles[gp] = true
	queue_redraw()


func _revert_fortress() -> void:
	for gp in _fortress_tiles.keys():
		# Only revert tiles that are still steel (star bullets may have destroyed some)
		if _tile_data.get(gp, Constants.TileType.EMPTY) == Constants.TileType.STEEL:
			_tile_data[gp] = Constants.TileType.BRICK
			if _tile_bodies.has(gp):
				_tile_bodies[gp].set_meta("tile_type", Constants.TileType.BRICK)
	_fortress_tiles.clear()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, Constants.PLAY_AREA_W, Constants.PLAY_AREA_H), Constants.COLOR_GROUND)
	for gp: Vector2i in _tile_data:
		var tile_type: int = _tile_data[gp]
		if tile_type == Constants.TileType.TREES:
			continue
		_draw_tile(gp, tile_type)


func _draw_tile(gp: Vector2i, tile_type: int) -> void:
	var wp := grid_to_world(gp)
	var ts := float(Constants.TILE_SIZE)
	var rect := Rect2(wp, Vector2(ts, ts))

	# Fortress expiry warning: flash between steel and brick appearance
	var draw_type := tile_type
	if tile_type == Constants.TileType.STEEL and _fortress_tiles.has(gp):
		var remaining := _fortress_expiry - Time.get_ticks_msec() * 0.001
		if remaining < 3.0 and remaining > 0.0:
			if fmod(Time.get_ticks_msec() * 0.001, 0.4) < 0.2:
				draw_type = Constants.TileType.BRICK

	match draw_type:
		Constants.TileType.BRICK:
			draw_rect(rect, Constants.COLOR_BRICK)
			var dark := Color(0, 0, 0, 0.45)
			draw_rect(Rect2(wp, Vector2(ts, 1)), dark)
			draw_rect(Rect2(wp, Vector2(1, ts)), dark)
			draw_rect(Rect2(wp + Vector2(0, ts * 0.5), Vector2(ts, 1)), dark)
			draw_rect(Rect2(wp + Vector2(ts * 0.5, 0), Vector2(1, ts)), dark)
		Constants.TileType.STEEL:
			draw_rect(rect, Constants.COLOR_STEEL)
			draw_rect(Rect2(wp + Vector2(2, 2), Vector2(ts - 4, ts - 4)), Color(0.72, 0.74, 0.80))
			draw_rect(Rect2(wp, Vector2(ts, 1)), Color(0.85, 0.87, 0.92))
			draw_rect(Rect2(wp, Vector2(1, ts)), Color(0.85, 0.87, 0.92))
		Constants.TileType.WATER:
			draw_rect(rect, Constants.COLOR_WATER)
			draw_rect(Rect2(wp + Vector2(0, ts * 0.4), Vector2(ts, 2)), Color(0.05, 0.20, 0.70, 0.6))
			draw_rect(Rect2(wp + Vector2(0, ts * 0.75), Vector2(ts, 2)), Color(0.05, 0.20, 0.70, 0.6))
		Constants.TileType.ICE:
			draw_rect(rect, Constants.COLOR_ICE)
			draw_rect(Rect2(wp + Vector2(3, 3), Vector2(ts - 6, ts - 6)), Color(0.85, 0.95, 1.0, 0.5))
