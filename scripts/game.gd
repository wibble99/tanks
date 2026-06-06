extends Node2D

const PlayerTankScene     := preload("res://scenes/objects/player_tank.tscn")
const EnemyTankScene      := preload("res://scenes/objects/enemy_tank.tscn")
const BulletScene         := preload("res://scenes/objects/bullet.tscn")
const EagleScene          := preload("res://scenes/objects/eagle.tscn")
const PowerupScene        := preload("res://scenes/objects/powerup.tscn")
const UpgradeOverlayScene := preload("res://scenes/objects/upgrade_overlay.tscn")

const MAX_ACTIVE_ENEMIES: int = 4
const ENEMY_SPAWN_DELAY: float = 2.0
const BONUS_ENEMY_CHANCE: float = 0.30

var _enemy_queue: Array = []
var _spawn_points: Array = []
var _spawn_index: int = 0
var _spawn_timer: float = 1.0

var _game_over_pending: bool = false
var _respawn_seq: int = 0
var _upgrade_overlay: Control = null


func _ready() -> void:
	GameManager.start_game()
	GameManager.level_complete_triggered.connect(_on_level_complete)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.bomb_triggered.connect(_on_bomb)
	_setup_upgrade_overlay()
	_spawn_eagle()
	_spawn_player()
	_init_enemies()


func _process(delta: float) -> void:
	_tick_enemy_spawner(delta)


# ── Eagle ─────────────────────────────────────────────────────────────────────

func _spawn_eagle() -> void:
	var mm = $MapManager
	var eagle = EagleScene.instantiate()
	eagle.position = mm.grid_to_world_center(mm.eagle_grid_pos)
	add_child(eagle)


# ── Player ────────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	if _game_over_pending:
		return
	var mm = $MapManager
	var spawns = mm.get_player_spawns()
	if spawns.is_empty():
		return
	var player = PlayerTankScene.instantiate()
	player.position = spawns[0]
	player.fired.connect(_on_player_fired)
	player.died.connect(_on_player_died)
	$Entities.add_child(player)


func _on_player_died() -> void:
	var seq := _respawn_seq
	if GameManager.lives > 0 and not _game_over_pending:
		await get_tree().create_timer(2.0).timeout
		if _respawn_seq == seq and not _game_over_pending:
			_spawn_player()


# ── Enemies ───────────────────────────────────────────────────────────────────

func _init_enemies() -> void:
	_spawn_points = $MapManager.get_enemy_spawns()
	var ld = load("res://levels/level_01.tres")
	if ld != null:
		for t in ld.enemy_sequence:
			_enemy_queue.append(int(t))
	else:
		for _i in 20:
			_enemy_queue.append(Constants.EnemyTier.BASIC)
	GameManager.set_enemy_count(_enemy_queue.size())


func _tick_enemy_spawner(delta: float) -> void:
	if _game_over_pending or _enemy_queue.is_empty():
		return
	var active: int = get_tree().get_nodes_in_group("enemies").size()
	if active >= MAX_ACTIVE_ENEMIES:
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = ENEMY_SPAWN_DELAY
	_spawn_next_enemy()


func _spawn_next_enemy() -> void:
	if _enemy_queue.is_empty() or _spawn_points.is_empty():
		return
	var tier: int = _enemy_queue.pop_front()
	var pos: Vector2 = _spawn_points[_spawn_index % _spawn_points.size()]
	_spawn_index += 1

	var enemy = EnemyTankScene.instantiate()
	enemy.init(tier)
	enemy.position = pos
	enemy.fired.connect(_on_enemy_fired)
	if randf() < BONUS_ENEMY_CHANCE:
		enemy.is_bonus = true
		enemy.dropped_powerup.connect(_on_powerup_dropped)
	$Entities.add_child(enemy)


# ── Bullets ───────────────────────────────────────────────────────────────────

func _on_player_fired(world_pos: Vector2, direction: Vector2) -> void:
	SoundManager.play_shoot()
	_spawn_bullet(world_pos, direction, true)


func _on_enemy_fired(world_pos: Vector2, direction: Vector2) -> void:
	SoundManager.play_shoot()
	_spawn_bullet(world_pos, direction, false)


func _spawn_bullet(world_pos: Vector2, direction: Vector2, from_player: bool) -> void:
	var bullet = BulletScene.instantiate()
	bullet.position = world_pos
	bullet.init(direction, from_player)
	$Entities.add_child(bullet)


# ── Powerups ──────────────────────────────────────────────────────────────────

func _on_powerup_dropped(world_pos: Vector2) -> void:
	_spawn_powerup(world_pos)


func _spawn_powerup(world_pos: Vector2) -> void:
	var types := [
		Constants.PowerupType.SHIELD,
		Constants.PowerupType.STAR,
		Constants.PowerupType.FREEZE,
		Constants.PowerupType.LIFE,
		Constants.PowerupType.BOMB,
		Constants.PowerupType.SPEED,
		Constants.PowerupType.SHOVEL,
	]
	var pu = PowerupScene.instantiate()
	pu.init(types[randi() % types.size()])
	pu.position = world_pos
	$Entities.add_child(pu)


func _on_bomb() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.die_to_bomb()


# ── Level progression ─────────────────────────────────────────────────────────

func _setup_upgrade_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_upgrade_overlay = UpgradeOverlayScene.instantiate()
	_upgrade_overlay.continue_pressed.connect(_on_upgrade_continue)
	layer.add_child(_upgrade_overlay)


func _on_upgrade_continue() -> void:
	get_tree().paused = false
	_start_next_level()


func _on_level_complete() -> void:
	if _game_over_pending:
		return
	_game_over_pending = true
	set_process(false)
	SoundManager.play_victory()
	await get_tree().create_timer(1.0).timeout
	var pts := GameManager.current_level * 150
	UpgradeManager.earn(pts)
	get_tree().paused = true
	_upgrade_overlay.show_screen(pts)


func _start_next_level() -> void:
	_respawn_seq += 1  # cancel any pending player respawn coroutines

	GameManager.next_level()
	var path := "res://levels/level_%02d.tres" % GameManager.current_level
	var ld = load(path)
	if ld == null:
		# Past the last level — cycle back to 1 (keeps score/lives)
		ld = load("res://levels/level_01.tres")
	if ld == null:
		return

	# Remove all in-play entities
	for child in $Entities.get_children():
		child.queue_free()
	for child in get_children():
		if child.is_in_group("eagle"):
			child.queue_free()

	# Allow queue_frees to flush before creating the new map
	await get_tree().process_frame

	$MapManager.load_level(ld)

	# Rebuild spawner state
	_enemy_queue.clear()
	_spawn_index = 0
	_spawn_timer = 1.5
	for t in ld.enemy_sequence:
		_enemy_queue.append(int(t))
	_spawn_points = $MapManager.get_enemy_spawns()
	GameManager.set_enemy_count(_enemy_queue.size())

	# Resume play
	_game_over_pending = false
	set_process(true)
	_spawn_eagle()
	_spawn_player()


# ── Game over ─────────────────────────────────────────────────────────────────

func _on_game_over() -> void:
	if _game_over_pending:
		return
	_game_over_pending = true
	set_process(false)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
