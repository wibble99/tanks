class_name EnemyTank
extends CharacterBody2D

const ExplosionScene := preload("res://scenes/objects/explosion.tscn")

signal fired(world_pos: Vector2, direction: Vector2)
signal died()
signal dropped_powerup(world_pos: Vector2)

const FLASH_INTERVAL: float = 0.1

var tier: int = Constants.EnemyTier.BASIC
var is_bonus: bool = false
var _hits_remaining: int = 1
var _speed: float = Constants.ENEMY_SPEED_BASE
var _fire_interval: float = Constants.ENEMY_FIRE_COOLDOWN

var _direction: int = Constants.Direction.DOWN
var _facing_angle: float = PI

var _fire_cooldown: float = 0.0
var _direction_timer: float = 0.0

var _spawning: bool = true
var _spawn_timer: float = Constants.SPAWN_FLASH_TIME
var _flash_visible: bool = true


func init(enemy_tier: int) -> void:
	tier = enemy_tier
	match tier:
		Constants.EnemyTier.BASIC:
			_hits_remaining = 1
			_speed = Constants.ENEMY_SPEED_BASE
			_fire_interval = Constants.ENEMY_FIRE_COOLDOWN
		Constants.EnemyTier.FAST:
			_hits_remaining = 1
			_speed = Constants.ENEMY_SPEED_BASE * 2.0
			_fire_interval = Constants.ENEMY_FIRE_COOLDOWN
		Constants.EnemyTier.POWER:
			_hits_remaining = 1
			_speed = Constants.ENEMY_SPEED_BASE
			_fire_interval = Constants.ENEMY_FIRE_COOLDOWN * 0.5
		Constants.EnemyTier.ARMORED:
			_hits_remaining = 4
			_speed = Constants.ENEMY_SPEED_BASE
			_fire_interval = Constants.ENEMY_FIRE_COOLDOWN
	# Stagger initial fire so not all enemies fire simultaneously
	_fire_cooldown = randf() * _fire_interval


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = (Constants.LAYER_WALLS | Constants.LAYER_PLAYER
			| Constants.LAYER_ENEMY | Constants.LAYER_WATER)
	_direction = Constants.Direction.DOWN
	_facing_angle = PI
	_direction_timer = 0.5 + randf() * 1.5


func _physics_process(delta: float) -> void:
	# Spawn flash animation — ignore input during this phase
	if _spawning:
		_spawn_timer -= delta
		_flash_visible = fmod(_spawn_timer, FLASH_INTERVAL * 2.0) > FLASH_INTERVAL
		if _spawn_timer <= 0.0:
			_spawning = false
			_flash_visible = true
		queue_redraw()
		return

	# Freeze powerup: skip all movement and shooting while frozen
	if Time.get_ticks_msec() * 0.001 < GameManager.enemies_frozen_until:
		queue_redraw()
		return

	if is_bonus:
		queue_redraw()

	_fire_cooldown -= delta
	_direction_timer -= delta

	var prev_pos := position
	velocity = Constants.DIR_VECTORS[_direction] * _speed
	move_and_slide()
	_clamp_to_play_area()

	# Detect blockage: if the tank barely moved, something is in the way
	var moved := (position - prev_pos).length()
	var blocked := moved < _speed * delta * 0.1

	if blocked or _direction_timer <= 0.0:
		_pick_new_direction(blocked)

	if _fire_cooldown <= 0.0:
		_shoot()
		_fire_cooldown = _fire_interval + randf() * _fire_interval * 0.5


func _pick_new_direction(was_blocked: bool) -> void:
	_direction_timer = 1.5 + randf() * 2.5

	# Higher-tier enemies target the eagle more often
	var aim_chance := 0.15 if tier < Constants.EnemyTier.POWER else 0.40
	var mm = get_tree().get_first_node_in_group("map_manager")
	if mm != null and randf() < aim_chance:
		_aim_toward_point(mm.grid_to_world_center(mm.eagle_grid_pos))
		return

	if was_blocked:
		# Avoid retrying the same direction that just failed
		var candidates := [0, 1, 2, 3]
		candidates.erase(_direction)
		_direction = candidates[randi() % candidates.size()]
	else:
		_direction = randi() % 4

	_set_facing()


func _aim_toward_point(target: Vector2) -> void:
	var diff := target - position
	if absf(diff.x) > absf(diff.y):
		_direction = Constants.Direction.RIGHT if diff.x > 0.0 else Constants.Direction.LEFT
	else:
		_direction = Constants.Direction.DOWN if diff.y > 0.0 else Constants.Direction.UP
	_set_facing()


func _set_facing() -> void:
	match _direction:
		Constants.Direction.UP:    _facing_angle = 0.0
		Constants.Direction.RIGHT: _facing_angle = PI * 0.5
		Constants.Direction.DOWN:  _facing_angle = PI
		Constants.Direction.LEFT:  _facing_angle = -PI * 0.5
	queue_redraw()


func _shoot() -> void:
	fired.emit(_barrel_tip(), Constants.DIR_VECTORS[_direction])


func _barrel_tip() -> Vector2:
	return position + Vector2(0.0, -12.0).rotated(_facing_angle)


func _clamp_to_play_area() -> void:
	var half := float(Constants.TILE_SIZE) * 0.5
	position.x = clampf(position.x, half, float(Constants.PLAY_AREA_W) - half)
	position.y = clampf(position.y, half, float(Constants.PLAY_AREA_H) - half)


func take_damage() -> void:
	_hits_remaining -= 1
	if _hits_remaining <= 0:
		_die()
	else:
		queue_redraw()


func die_to_bomb() -> void:
	_die()


func _die() -> void:
	GameManager.add_score(Constants.ENEMY_SCORES[tier])
	GameManager.on_enemy_destroyed()
	if is_bonus:
		dropped_powerup.emit(position)
	var exp := ExplosionScene.instantiate()
	exp.position = position
	get_parent().add_child(exp)
	ScreenFlash.flash()
	died.emit()
	queue_free()


func _body_color() -> Color:
	if tier != Constants.EnemyTier.ARMORED:
		match tier:
			Constants.EnemyTier.FAST:  return Color(0.95, 0.55, 0.10)
			Constants.EnemyTier.POWER: return Color(0.70, 0.05, 0.05)
			_: return Constants.COLOR_ENEMY
	# Armored: colour shifts as health depletes
	match _hits_remaining:
		4: return Color(0.15, 0.70, 0.15)
		3: return Color(0.60, 0.62, 0.65)
		2: return Color(0.90, 0.80, 0.10)
		_: return Constants.COLOR_ENEMY


func _draw() -> void:
	if not _flash_visible:
		return

	var c := _body_color()
	var dark := Color(c.r * 0.5, c.g * 0.5, c.b * 0.5)

	draw_set_transform(Vector2.ZERO, _facing_angle)

	# Body
	draw_rect(Rect2(-6.0, -6.0, 12.0, 12.0), c)
	# Barrel
	draw_rect(Rect2(-2.0, -11.0, 4.0, 8.0), c)
	# Tread detail
	draw_rect(Rect2(-7.0, -5.0, 3.0, 2.0), dark)
	draw_rect(Rect2(-7.0, -1.0, 3.0, 2.0), dark)
	draw_rect(Rect2(-7.0,  3.0, 3.0, 2.0), dark)
	draw_rect(Rect2( 4.0, -5.0, 3.0, 2.0), dark)
	draw_rect(Rect2( 4.0, -1.0, 3.0, 2.0), dark)
	draw_rect(Rect2( 4.0,  3.0, 3.0, 2.0), dark)

	draw_set_transform(Vector2.ZERO, 0.0)

	# Armored: draw hit-count pips above tank
	if tier == Constants.EnemyTier.ARMORED and _hits_remaining > 1:
		for i in range(_hits_remaining - 1):
			draw_circle(Vector2(-4.0 + i * 4.0, -14.0), 2.0, Color(1, 1, 1, 0.8))

	# Bonus enemy: pulsing white outline signals a powerup drop
	if is_bonus:
		var pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
		draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), Color(1.0, 1.0, 1.0, pulse * 0.8), false, 2.0)

	# Frozen: pulsing cyan outline
	if Time.get_ticks_msec() * 0.001 < GameManager.enemies_frozen_until:
		var pulse := sin(Time.get_ticks_msec() * 0.010) * 0.3 + 0.6
		draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), Color(0.45, 0.85, 1.0, pulse * 0.75), false, 2.5)
