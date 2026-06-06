class_name LevelData
extends Resource

@export var level_number: int = 1
@export var enemy_count: int = 20
@export var enemy_sequence: PackedInt32Array = []
@export var map_rows: PackedStringArray = []
@export var player_spawn_cols: PackedInt32Array = PackedInt32Array([0, 24])
@export var enemy_spawn_cols: PackedInt32Array = PackedInt32Array([0, 12, 24])
@export var eagle_col: int = 12
@export var eagle_row: int = 24
@export var powerup_chance: float = 0.2
