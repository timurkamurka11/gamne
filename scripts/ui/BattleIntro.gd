extends Control

@export var next_scene_path: String = "res://scenes/world/World.tscn"

@onready var intro_sprite: AnimatedSprite2D = $IntroSprite
@onready var flash_rect: ColorRect = $FlashRect

var _changing_scene: bool = false

func _ready() -> void:
	_build_frames()
	_fit_sprite_to_screen()
	flash_rect.modulate.a = 0.0
	intro_sprite.play("intro")
	# Small flash when the portraits collide.
	await get_tree().create_timer(1.15).timeout
	var tween := create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.55, 0.06)
	tween.tween_property(flash_rect, "modulate:a", 0.0, 0.22)
	await intro_sprite.animation_finished
	_go_to_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_sprite_to_screen()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
		_go_to_game()

func _go_to_game() -> void:
	if _changing_scene:
		return
	_changing_scene = true
	get_tree().change_scene_to_file(next_scene_path)

func _fit_sprite_to_screen() -> void:
	var viewport_size := get_viewport_rect().size
	intro_sprite.position = viewport_size / 2.0
	var scale_value: float = max(viewport_size.x / 512.0, viewport_size.y / 512.0)
	intro_sprite.scale = Vector2(scale_value, scale_value)

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("intro")
	frames.set_animation_speed("intro", 8.0)
	frames.set_animation_loop("intro", false)
	for i in range(16):
		var path := "res://assets/sprites/ui/battle_intro_stage1/frame_%02d.png" % i
		frames.add_frame("intro", load(path))
	intro_sprite.sprite_frames = frames
