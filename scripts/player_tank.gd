class_name PlayerTank
extends CharacterBody2D

const ExplosionScene := preload("res://scenes/objects/explosion.tscn")

signal fired(world_pos: Vector2, direction: Vector2)
signal died()

const SNAP_THRESHOLD: float = 4.0
const SPAWN_FLASH_INTERVAL: float = 0.1

var _direction: int = Constants.Direction.UP
var _facing_angle: float = 0.0
var _fire_cooldown: float = 0.0

var _spawning: bool = true
var _spawn_timer: float = Constants.SPAWN_FLASH_TIME
var _flash_visible: bool = true

var _shield_active: bool = false
var _shield_timer: float = 0.0
var _speed_boost_timer: float = 0.0
var _hits_remaining: int = 1
var _hit_invincible_timer: float = 0.0


func _ready() -> void:
	collision_layer = Constants.LAYER_PLAYER
	collision_mask = Constants.LAYER_WALLS | Constants.LAYER_ENEMY | Constants.LAYER_WATER
	_hits_remaining = UpgradeManager.rank_hits()
	var sp := UpgradeManager.starting_powerup()
	if sp >= 0:
		apply_powerup(sp)


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)

	if _spawning:
		_spawn_timer -= delta
		_flash_visible = fmod(_spawn_timer, SPAWN_FLASH_INTERVAL * 2) > SPAWN_FLASH_INTERVAL
		if _spawn_timer <= 0.0:
			_spawning = false
			_flash_visible = true
		queue_redraw()
		return

	if _shield_active:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_active = false
		queue_redraw()

	if _speed_boost_timer > 0.0:
		_speed_boost_timer -= delta

	if _hit_invincible_timer > 0.0:
		_hit_invincible_timer -= delta
		queue_redraw()

	var input_dir := _get_input_direction()
	var spd := Constants.PLAYER_SPEED * UpgradeManager.speed_mult()
	if _speed_boost_timer > 0.0:
		spd *= 1.5

	if input_dir != Vector2.ZERO:
		if input_dir != velocity.normalized():
			_try_snap_to_grid(input_dir)
		velocity = input_dir * spd
		_set_direction(input_dir)
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_clamp_to_play_area()

	if Input.is_action_just_pressed("fire") and _fire_cooldown <= 0.0:
		_fire()


func _get_input_direction() -> Vector2:
	if Input.is_action_pressed("move_up"):
		return Vector2.UP
	elif Input.is_action_pressed("move_down"):
		return Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		return Vector2.LEFT
	elif Input.is_action_pressed("move_right"):
		return Vector2.RIGHT
	return Vector2.ZERO


func _try_snap_to_grid(new_dir: Vector2) -> void:
	var ts := float(Constants.TILE_SIZE)
	if new_dir.x != 0.0:
		var snapped_y: float = round(position.y / ts) * ts
		if absf(position.y - snapped_y) <= SNAP_THRESHOLD:
			position.y = snapped_y
	else:
		var snapped_x: float = round(position.x / ts) * ts
		if absf(position.x - snapped_x) <= SNAP_THRESHOLD:
			position.x = snapped_x


func _set_direction(dir: Vector2) -> void:
	var prev := _direction
	if dir == Vector2.UP:
		_direction = Constants.Direction.UP
		_facing_angle = 0.0
	elif dir == Vector2.RIGHT:
		_direction = Constants.Direction.RIGHT
		_facing_angle = PI * 0.5
	elif dir == Vector2.DOWN:
		_direction = Constants.Direction.DOWN
		_facing_angle = PI
	elif dir == Vector2.LEFT:
		_direction = Constants.Direction.LEFT
		_facing_angle = -PI * 0.5
	if _direction != prev:
		queue_redraw()


func _clamp_to_play_area() -> void:
	var half := float(Constants.TILE_SIZE) * 0.5
	position.x = clampf(position.x, half, float(Constants.PLAY_AREA_W) - half)
	position.y = clampf(position.y, half, float(Constants.PLAY_AREA_H) - half)


func _fire() -> void:
	_fire_cooldown = Constants.PLAYER_FIRE_COOLDOWN * UpgradeManager.fire_cooldown_mult()
	fired.emit(get_barrel_tip(), Constants.DIR_VECTORS[_direction])


func get_barrel_tip() -> Vector2:
	# World-space position at end of barrel, used for bullet spawn in Step 4
	var local_tip := Vector2(0.0, -12.0).rotated(_facing_angle)
	return position + local_tip


func take_damage() -> void:
	if _shield_active or _hit_invincible_timer > 0.0:
		return
	_hits_remaining -= 1
	if _hits_remaining > 0:
		_hit_invincible_timer = 0.8
		queue_redraw()
		return
	GameManager.player_has_star = false
	_speed_boost_timer = 0.0
	var exp := ExplosionScene.instantiate()
	exp.position = position
	get_parent().add_child(exp)
	ScreenFlash.flash()
	SoundManager.play_explosion()
	GameManager.lose_life()
	died.emit()
	queue_free()


func apply_powerup(ptype: int) -> void:
	match ptype:
		Constants.PowerupType.SHIELD:
			activate_shield(5.0)
		Constants.PowerupType.STAR:
			GameManager.set_player_star(true)
		Constants.PowerupType.FREEZE:
			GameManager.freeze_enemies(10.0)
		Constants.PowerupType.LIFE:
			GameManager.gain_life()
		Constants.PowerupType.BOMB:
			GameManager.bomb_all_enemies()
		Constants.PowerupType.SPEED:
			_speed_boost_timer = 6.0
		Constants.PowerupType.SHOVEL:
			var mm = get_tree().get_first_node_in_group("map_manager")
			if mm:
				mm.fortify_eagle(15.0)


func activate_shield(duration: float) -> void:
	_shield_active = true
	_shield_timer = duration
	queue_redraw()


func _draw() -> void:
	if not _flash_visible:
		return

	draw_set_transform(Vector2.ZERO, _facing_angle)

	var c := Constants.COLOR_PLAYER
	var dark := Color(c.r * 0.55, c.g * 0.55, c.b * 0.55)

	# Tank body
	draw_rect(Rect2(-6.0, -6.0, 12.0, 12.0), c)
	# Barrel
	draw_rect(Rect2(-2.0, -11.0, 4.0, 8.0), c)

	# Tread detail — left side
	draw_rect(Rect2(-7.0, -5.0, 3.0, 2.0), dark)
	draw_rect(Rect2(-7.0, -1.0, 3.0, 2.0), dark)
	draw_rect(Rect2(-7.0,  3.0, 3.0, 2.0), dark)
	# Tread detail — right side
	draw_rect(Rect2( 4.0, -5.0, 3.0, 2.0), dark)
	draw_rect(Rect2( 4.0, -1.0, 3.0, 2.0), dark)
	draw_rect(Rect2( 4.0,  3.0, 3.0, 2.0), dark)

	draw_set_transform(Vector2.ZERO, 0.0)

	# Shield aura — drawn without rotation
	if _shield_active:
		var pulse := 0.5 + 0.5 * sin(_shield_timer * 10.0)
		draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color(0.3, 0.8, 1.0, 0.4 + 0.4 * pulse), 2.0)

	# HP pips (rank upgrade — one dot per hit point)
	var max_hits := UpgradeManager.rank_hits()
	if max_hits > 1:
		for i in range(max_hits):
			var pip_x := float(i) * 4.0 - float(max_hits - 1) * 2.0
			var pip_col := Color(0.40, 1.00, 0.40) if i < _hits_remaining else Color(0.22, 0.22, 0.22)
			draw_circle(Vector2(pip_x, -15.0), 2.0, pip_col)
