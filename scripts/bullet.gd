extends CharacterBody2D

var is_player_bullet: bool = true
var _is_star: bool = false


func _ready() -> void:
	add_to_group("bullets")


func init(direction: Vector2, from_player: bool) -> void:
	is_player_bullet = from_player
	_is_star = from_player and (GameManager.player_has_star or UpgradeManager.has_star_shot())
	velocity = direction.normalized() * Constants.BULLET_SPEED
	if from_player:
		collision_layer = Constants.LAYER_BULLET_PLAYER
		collision_mask = (Constants.LAYER_WALLS
				| Constants.LAYER_ENEMY
				| Constants.LAYER_EAGLE
				| Constants.LAYER_BULLET_ENEMY)
	else:
		collision_layer = Constants.LAYER_BULLET_ENEMY
		collision_mask = (Constants.LAYER_WALLS
				| Constants.LAYER_PLAYER
				| Constants.LAYER_EAGLE
				| Constants.LAYER_BULLET_PLAYER)


func _physics_process(delta: float) -> void:
	if _out_of_bounds():
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		_on_hit(collision.get_collider())


func _on_hit(collider: Object) -> void:
	if collider == null or not is_instance_valid(collider):
		queue_free()
		return

	# Map tile (StaticBody2D with tile_type meta)
	if collider.has_meta("tile_type"):
		var tile_type: int = collider.get_meta("tile_type")
		var gp: Vector2i = collider.get_meta("grid_pos")
		var mm = get_tree().get_first_node_in_group("map_manager")
		if tile_type == Constants.TileType.BRICK:
			if mm:
				mm.destroy_tile(gp)
		elif tile_type == Constants.TileType.STEEL and _is_star:
			if mm:
				mm.destroy_tile(gp, true)
		queue_free()
		return

	# Opposing bullet — mutual cancel
	if collider.is_in_group("bullets"):
		if is_instance_valid(collider):
			collider.queue_free()
		queue_free()
		return

	# Eagle
	if collider.is_in_group("eagle"):
		collider.destroy()
		queue_free()
		return

	# Tank (player or enemy) — call take_damage if available
	if collider.has_method("take_damage"):
		collider.take_damage()

	queue_free()


func _out_of_bounds() -> bool:
	var m := float(Constants.TILE_SIZE)
	return (position.x < -m or position.x > Constants.PLAY_AREA_W + m
			or position.y < -m or position.y > Constants.PLAY_AREA_H + m)


func _draw() -> void:
	draw_rect(Rect2(-2.0, -2.0, 4.0, 4.0), Constants.COLOR_BULLET)
