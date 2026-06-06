extends StaticBody2D

const ExplosionScene := preload("res://scenes/objects/explosion.tscn")

var _destroyed: bool = false


func _ready() -> void:
	add_to_group("eagle")
	collision_layer = Constants.LAYER_EAGLE
	collision_mask = 0


func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
	queue_redraw()
	var exp := ExplosionScene.instantiate()
	exp.position = position
	get_parent().add_child(exp)
	ScreenFlash.flash()
	SoundManager.play_explosion()
	GameManager.eagle_destroyed()


func _draw() -> void:
	if _destroyed:
		var rb := Color(0.20, 0.12, 0.04)
		draw_rect(Rect2(-8.0, -8.0, 16.0, 16.0), rb)
		draw_rect(Rect2(-5.0, -3.0, 4.0, 3.0), Color(0.30, 0.20, 0.08))
		draw_rect(Rect2( 2.0, -5.0, 3.0, 4.0), Color(0.30, 0.20, 0.08))
		draw_rect(Rect2(-2.0,  2.0, 5.0, 3.0), Color(0.30, 0.20, 0.08))
		return

	var c  := Constants.COLOR_EAGLE
	var dk := Color(c.r * 0.32, c.g * 0.32, c.b * 0.32)

	# Cross body
	draw_rect(Rect2(-2.5, -8.0,  5.0, 16.0), c)
	draw_rect(Rect2(-8.0, -2.5, 16.0,  5.0), c)
	# Wing corner nubs
	draw_rect(Rect2(-7.0, -7.0, 4.0, 4.0), c)
	draw_rect(Rect2( 3.0, -7.0, 4.0, 4.0), c)
	draw_rect(Rect2(-7.0,  3.0, 4.0, 4.0), c)
	draw_rect(Rect2( 3.0,  3.0, 4.0, 4.0), c)
	# Dark centre hub
	draw_rect(Rect2(-2.5, -2.5, 5.0, 5.0), dk)
