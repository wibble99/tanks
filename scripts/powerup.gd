extends Area2D

const FLASH_INTERVAL: float = 0.18
const LIFETIME: float = 12.0

var powerup_type: int = Constants.PowerupType.SHIELD
var _flash_timer: float = 0.0
var _show: bool = true
var _lifetime: float = LIFETIME


func init(ptype: int) -> void:
	powerup_type = ptype


func _ready() -> void:
	add_to_group("powerups")
	collision_layer = Constants.LAYER_POWERUP
	collision_mask = Constants.LAYER_PLAYER
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	_flash_timer += delta
	var now_show := fmod(_flash_timer, FLASH_INTERVAL * 2.0) > FLASH_INTERVAL
	if now_show != _show:
		_show = now_show
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_powerup"):
		SoundManager.play_pickup()
		body.apply_powerup(powerup_type)
		queue_free()


func _draw() -> void:
	if not _show:
		return
	var col := _type_color()
	draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), col, false, 2.0)
	draw_rect(Rect2(-7.0, -7.0, 14.0, 14.0), Color(col.r, col.g, col.b, 0.25))
	_draw_icon(col)


func _type_color() -> Color:
	match powerup_type:
		Constants.PowerupType.SHIELD: return Color(0.30, 0.85, 1.00)
		Constants.PowerupType.STAR:   return Color(1.00, 1.00, 0.20)
		Constants.PowerupType.FREEZE: return Color(0.55, 0.80, 1.00)
		Constants.PowerupType.LIFE:   return Color(0.20, 1.00, 0.40)
		Constants.PowerupType.BOMB:   return Color(1.00, 0.30, 0.30)
		Constants.PowerupType.SPEED:  return Color(1.00, 0.65, 0.00)
		Constants.PowerupType.SHOVEL: return Color(0.75, 0.58, 0.28)
		_: return Color.WHITE


func _draw_icon(col: Color) -> void:
	match powerup_type:
		Constants.PowerupType.STAR:
			for i in range(5):
				var a := -PI * 0.5 + float(i) * TAU / 5.0
				draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 5.5, col, 1.5)
		Constants.PowerupType.SHIELD:
			draw_arc(Vector2.ZERO, 4.5, 0.0, TAU, 16, col, 2.0)
		Constants.PowerupType.LIFE:
			draw_rect(Rect2(-1.0, -4.5, 2.0, 9.0), col)
			draw_rect(Rect2(-4.5, -1.0, 9.0, 2.0), col)
		Constants.PowerupType.FREEZE:
			# Clock face
			draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 20, col, 1.5)
			# Hour hand (12 o'clock)
			draw_line(Vector2.ZERO, Vector2(0.0, -3.5), col, 1.5)
			# Minute hand (3 o'clock)
			draw_line(Vector2.ZERO, Vector2(3.5, 0.0), col, 1.5)
		Constants.PowerupType.BOMB:
			draw_circle(Vector2(0.0, 1.0), 4.0, col)
			draw_line(Vector2(1.5, -3.0), Vector2(3.0, -5.5), col, 1.5)
		Constants.PowerupType.SPEED:
			draw_line(Vector2(-4.5, 0.0), Vector2(4.5, 0.0), col, 2.0)
			draw_line(Vector2(1.5, -3.0), Vector2(4.5, 0.0), col, 2.0)
			draw_line(Vector2(1.5,  3.0), Vector2(4.5, 0.0), col, 2.0)
		Constants.PowerupType.SHOVEL:
			# Fortress / castle silhouette
			draw_rect(Rect2(-5.0, -0.5, 10.0, 5.0), col)   # base wall
			draw_rect(Rect2(-5.0, -4.5,  2.0, 4.0), col)   # left merlon
			draw_rect(Rect2(-1.0, -4.5,  2.0, 4.0), col)   # centre merlon
			draw_rect(Rect2( 3.0, -4.5,  2.0, 4.0), col)   # right merlon
