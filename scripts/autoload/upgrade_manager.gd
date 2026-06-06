extends Node

enum Type { FIREPOWER = 0, SPEED = 1, RANK = 2, ABILITY = 3 }

const MAX_LEVEL: int = 4
const COSTS: Array = [100, 200, 400, 800]

var points: int = 0
var levels: Array = [0, 0, 0, 0]


func _ready() -> void:
	GameManager.game_over_triggered.connect(_on_game_over)


func _on_game_over() -> void:
	reset()


func reset() -> void:
	points = 0
	for i in range(4):
		levels[i] = 0


func earn(amount: int) -> void:
	points += amount


func cost_for(type: int) -> int:
	var lv: int = levels[type]
	return COSTS[lv] if lv < MAX_LEVEL else 0


func can_buy(type: int) -> bool:
	return levels[type] < MAX_LEVEL and points >= cost_for(type)


func buy(type: int) -> bool:
	if not can_buy(type):
		return false
	points -= cost_for(type)
	levels[type] += 1
	return true


# ── Stat accessors used by game entities ──────────────────────────────────────

func fire_cooldown_mult() -> float:
	return 1.0 - levels[Type.FIREPOWER] * 0.15

func speed_mult() -> float:
	return 1.0 + levels[Type.SPEED] * 0.20

func rank_hits() -> int:
	return 1 + levels[Type.RANK]

func has_star_shot() -> bool:
	return levels[Type.FIREPOWER] >= 3

func starting_powerup() -> int:
	match levels[Type.ABILITY]:
		1: return Constants.PowerupType.SHIELD
		2: return Constants.PowerupType.STAR
		3: return Constants.PowerupType.FREEZE
		4: return Constants.PowerupType.BOMB
		_: return -1
