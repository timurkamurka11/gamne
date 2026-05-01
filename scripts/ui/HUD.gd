
extends CanvasLayer

@onready var hearts_box: HBoxContainer = $HeartsBox
var heart_full := preload("res://assets/sprites/ui/heart_full.png")
var heart_empty := preload("res://assets/sprites/ui/heart_empty.png")

func set_hp(current_hp: int, max_hp: int) -> void:
	for child in hearts_box.get_children():
		child.queue_free()

	for i in range(max_hp):
		var heart := TextureRect.new()
		heart.texture = heart_full if i < current_hp else heart_empty
		heart.custom_minimum_size = Vector2(32, 32)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_box.add_child(heart)
