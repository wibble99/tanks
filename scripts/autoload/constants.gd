extends Node

# Grid dimensions
const TILE_SIZE: int = 16
const GRID_COLS: int = 26
const GRID_ROWS: int = 26
const PLAY_AREA_W: int = TILE_SIZE * GRID_COLS  # 416
const PLAY_AREA_H: int = TILE_SIZE * GRID_ROWS  # 416

# Physics layer bitmasks (match project.godot layer_names)
const LAYER_WALLS: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_BULLET_PLAYER: int = 8
const LAYER_BULLET_ENEMY: int = 16
const LAYER_EAGLE: int = 32
const LAYER_POWERUP: int = 64
const LAYER_WATER: int = 128

# Movement speeds (pixels/sec)
const PLAYER_SPEED: float = 80.0
const ENEMY_SPEED_BASE: float = 50.0
const BULLET_SPEED: float = 200.0

# Bullet fire cooldown (seconds)
const PLAYER_FIRE_COOLDOWN: float = 0.4
const ENEMY_FIRE_COOLDOWN: float = 1.5

# Spawn flash duration before enemy appears
const SPAWN_FLASH_TIME: float = 1.0

# Tile types
enum TileType {
	EMPTY  = 0,
	BRICK  = 1,
	STEEL  = 2,
	WATER  = 3,
	TREES  = 4,
	ICE    = 5,
}

# Powerup types
enum PowerupType {
	SHIELD = 0,
	SPEED  = 1,
	FREEZE = 2,
	STAR   = 3,
	SHOVEL = 4,
	LIFE   = 5,
	BOMB   = 6,
}

# Tank facing directions (also used as rotation index)
enum Direction {
	UP    = 0,
	RIGHT = 1,
	DOWN  = 2,
	LEFT  = 3,
}

# Direction vectors
const DIR_VECTORS: Array[Vector2] = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
]

# Enemy tank tiers
enum EnemyTier {
	BASIC    = 0,
	FAST     = 1,
	POWER    = 2,
	ARMORED  = 3,
}

# Scores per enemy tier
const ENEMY_SCORES: Array[int] = [100, 200, 300, 400]

# Placeholder colours (used until real sprites exist)
const COLOR_GROUND:        Color = Color(0.08, 0.08, 0.12)
const COLOR_BRICK:         Color = Color(0.78, 0.28, 0.08)
const COLOR_STEEL:         Color = Color(0.55, 0.58, 0.65)
const COLOR_WATER:         Color = Color(0.15, 0.35, 0.85)
const COLOR_TREES:         Color = Color(0.10, 0.55, 0.10)
const COLOR_ICE:           Color = Color(0.70, 0.90, 1.00)
const COLOR_PLAYER:        Color = Color(0.90, 0.80, 0.10)
const COLOR_ENEMY:         Color = Color(0.85, 0.12, 0.12)
const COLOR_EAGLE:         Color = Color(1.00, 0.60, 0.00)
const COLOR_BULLET:        Color = Color(1.00, 1.00, 0.80)
const COLOR_EXPLOSION:     Color = Color(1.00, 0.45, 0.00)
