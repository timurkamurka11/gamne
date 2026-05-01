extends CharacterBody2D

@export var speed: float = 165.0
@export var max_hp: int = 5
@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 0.75

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bat_hit_sound: AudioStreamPlayer2D = $BatHitSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

var current_hp: int = 5
var last_direction: Vector2 = Vector2.DOWN
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var hud: CanvasLayer

func _ready() -> void:
    add_to_group("player")
    current_hp = max_hp
    _build_sprite_frames()
    sprite.play("idle_down")
    hud = get_tree().get_first_node_in_group("hud")
    _update_hud()

func _physics_process(_delta: float) -> void:
    if is_dead:
        return
    _handle_movement()
    _handle_attack()

func _handle_movement() -> void:
    if is_attacking:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()

    if direction != Vector2.ZERO:
        last_direction = direction.normalized()
        _play_walk_animation(last_direction)
    else:
        _play_idle_animation()

func _handle_attack() -> void:
    if Input.is_action_just_pressed("attack") and can_attack:
        _attack()

func _attack() -> void:
    can_attack = false
    is_attacking = true

    _play_attack_animation(last_direction)

    # Маленькая задержка перед активным кадром удара — атака ощущается плавнее.
    await get_tree().create_timer(0.18).timeout
    if is_dead:
        return

    if bat_hit_sound:
        bat_hit_sound.play()
    _spawn_energy_projectile()

    await get_tree().create_timer(0.36).timeout
    is_attacking = false
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true

func _spawn_energy_projectile() -> void:
    if projectile_scene == null:
        return
    var projectile = projectile_scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position + last_direction.normalized() * 34.0
    projectile.setup(last_direction)

func take_damage(amount: int) -> void:
    if current_hp <= 0 or is_dead:
        return

    current_hp = max(current_hp - amount, 0)
    _update_hud()

    if hurt_sound:
        hurt_sound.play()

    if current_hp <= 0:
        _die()

func heal(amount: int) -> void:
    if is_dead:
        return
    current_hp = min(current_hp + amount, max_hp)
    _update_hud()

func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    if collision_shape:
        collision_shape.set_deferred("disabled", true)
    sprite.play("death")
    await sprite.animation_finished
    get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _update_hud() -> void:
    if hud and hud.has_method("set_hp"):
        hud.set_hp(current_hp, max_hp)

func _play_walk_animation(direction: Vector2) -> void:
    sprite.flip_h = false
    if abs(direction.x) > abs(direction.y):
        sprite.play("walk_right" if direction.x > 0 else "walk_left")
    else:
        sprite.play("walk_down" if direction.y > 0 else "walk_up")

func _play_idle_animation() -> void:
    sprite.flip_h = false
    if abs(last_direction.x) > abs(last_direction.y):
        sprite.play("idle_right" if last_direction.x > 0 else "idle_left")
    else:
        sprite.play("idle_down" if last_direction.y > 0 else "idle_up")

func _play_attack_animation(direction: Vector2) -> void:
    sprite.flip_h = direction.x < 0
    if abs(direction.x) > abs(direction.y):
        sprite.play("attack_bat_right" if direction.x > 0 else "attack_bat_left")
    else:
        sprite.play("attack_bat_down" if direction.y > 0 else "attack_bat_up")

func _build_sprite_frames() -> void:
    var frames := SpriteFrames.new()

    _add_sheet_animation(frames, "walk_down", "res://assets/sprites/player/sheets/player_walk_down.png", 4, 344, 596, 8.0, true)
    _add_sheet_animation(frames, "walk_up", "res://assets/sprites/player/sheets/player_walk_up.png", 4, 336, 580, 8.0, true)
    _add_sheet_animation(frames, "walk_left", "res://assets/sprites/player/sheets/player_walk_left.png", 4, 424, 596, 8.0, true)
    _add_sheet_animation(frames, "walk_right", "res://assets/sprites/player/sheets/player_walk_right.png", 4, 332, 534, 8.0, true)

    _add_idle_from_sheet(frames, "idle_down", "res://assets/sprites/player/sheets/player_walk_down.png", 344, 596)
    _add_idle_from_sheet(frames, "idle_up", "res://assets/sprites/player/sheets/player_walk_up.png", 336, 580)
    _add_idle_from_sheet(frames, "idle_left", "res://assets/sprites/player/sheets/player_walk_left.png", 424, 596)
    _add_idle_from_sheet(frames, "idle_right", "res://assets/sprites/player/sheets/player_walk_right.png", 332, 534)

    _add_sheet_animation(frames, "attack_bat_down", "res://assets/sprites/player/sheets/player_attack_bat.png", 6, 448, 404, 10.0, false)
    _add_sheet_animation(frames, "attack_bat_up", "res://assets/sprites/player/sheets/player_attack_bat.png", 6, 448, 404, 10.0, false)
    _add_sheet_animation(frames, "attack_bat_left", "res://assets/sprites/player/sheets/player_attack_bat.png", 6, 448, 404, 10.0, false)
    _add_sheet_animation(frames, "attack_bat_right", "res://assets/sprites/player/sheets/player_attack_bat.png", 6, 448, 404, 10.0, false)

    _add_sheet_animation(frames, "death", "res://assets/sprites/player/sheets/player_death.png", 3, 724, 724, 6.0, false)

    sprite.sprite_frames = frames

func _add_sheet_animation(frames: SpriteFrames, anim_name: StringName, path: String, frame_count: int, frame_width: int, frame_height: int, fps: float, loop: bool) -> void:
    var sheet: Texture2D = load(path)
    frames.add_animation(anim_name)
    frames.set_animation_loop(anim_name, loop)
    frames.set_animation_speed(anim_name, fps)

    for i in range(frame_count):
        var atlas := AtlasTexture.new()
        atlas.atlas = sheet
        atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
        frames.add_frame(anim_name, atlas)

func _add_idle_from_sheet(frames: SpriteFrames, anim_name: StringName, path: String, frame_width: int, frame_height: int) -> void:
    var sheet: Texture2D = load(path)
    frames.add_animation(anim_name)
    frames.set_animation_loop(anim_name, true)
    frames.set_animation_speed(anim_name, 1.0)

    var atlas := AtlasTexture.new()
    atlas.atlas = sheet
    atlas.region = Rect2(0, 0, frame_width, frame_height)
    frames.add_frame(anim_name, atlas)
