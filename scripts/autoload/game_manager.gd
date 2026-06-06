extends Node

signal lives_changed(lives: int)
signal score_changed(score: int)
signal level_changed(level: int)
signal enemies_changed(count: int)
signal game_over_triggered()
signal level_complete_triggered()
signal bomb_triggered()

const STARTING_LIVES: int = 3

var lives: int = STARTING_LIVES
var score: int = 0
var current_level: int = 1
var enemies_remaining: int = 0
var high_score: int = 0
var player_has_star: bool = false
var enemies_frozen_until: float = 0.0

func _ready() -> void:
	_configure_input()


func _configure_input() -> void:
	_bind_key_action("move_up",    [KEY_W, KEY_UP])
	_bind_key_action("move_down",  [KEY_S, KEY_DOWN])
	_bind_key_action("move_left",  [KEY_A, KEY_LEFT])
	_bind_key_action("move_right", [KEY_D, KEY_RIGHT])
	_bind_key_action("fire",       [KEY_SPACE, KEY_Z])


func _bind_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)


func start_game() -> void:
	lives = STARTING_LIVES
	score = 0
	current_level = 1
	enemies_remaining = 0
	player_has_star = false
	enemies_frozen_until = 0.0

func add_score(points: int) -> void:
	score += points
	if score > high_score:
		high_score = score
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over_triggered.emit()

func set_enemy_count(count: int) -> void:
	enemies_remaining = count
	enemies_changed.emit(enemies_remaining)

func on_enemy_destroyed() -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	enemies_changed.emit(enemies_remaining)
	if enemies_remaining == 0:
		level_complete_triggered.emit()

func next_level() -> void:
	current_level += 1
	level_changed.emit(current_level)


func gain_life() -> void:
	lives += 1
	lives_changed.emit(lives)

func set_player_star(active: bool) -> void:
	player_has_star = active

func freeze_enemies(duration: float) -> void:
	enemies_frozen_until = Time.get_ticks_msec() * 0.001 + duration

func bomb_all_enemies() -> void:
	bomb_triggered.emit()

func eagle_destroyed() -> void:
	game_over_triggered.emit()
