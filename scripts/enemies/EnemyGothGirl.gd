extends CharacterBody2D

enum State { ENTERING, CHASE, ATTACK, DEAD }

@export var speed: float = 95.0
@export var attack_range: float = 165.0
@export var attack_cooldown: float = 1.8
@export var max_health: int = 1
@export var knockback_distance: float = 96.0
@export var dark_projectile_scene: PackedScene
@export var drop_scene: PackedScene
@export_range(0.0, 1.0) var drop_chance: float = 0.35

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound

var state: State = State.ENTERING
var health: int = 1
var player: Node2D
var entry_target: Vector2
var can_attack: bool = true
var last_hit_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    add_to_group("enemy")
    health = max_health
    player = get_tree().get_first_node_in_group("player")
    _build_sprite_frames()
    sprite.play("walk_down")

func setup_spawn(spawn_position: Vector2, target_position: Vector2) -> void:
    global_position = spawn_position
    entry_target = target_position
    state = State.ENTERING

func _physics_process(_delta: float) -> void:
    match state:
        State.ENTERING:
            _move_to_entry_target()
        State.CHASE:
            _chase_player()
        State.ATTACK:
            pass
        State.DEAD:
            pass

func _move_to_entry_target() -> void:
    var direction := global_position.direction_to(entry_target)
    velocity = direction * speed
    move_and_slide()
    _play_walk_animation(direction)
    if global_position.distance_to(entry_target) < 8.0:
        state = State.CHASE

func _chase_player() -> void:
    if player == null or not is_instance_valid(player):
        return
    var distance := global_position.distance_to(player.global_position)
    if distance <= attack_range and can_attack:
        _attack_player()
        return
    var direction := global_position.direction_to(player.global_position)
    velocity = direction * speed
    move_and_slide()
    _play_walk_animation(direction)

func _attack_player() -> void:
    if player == null or not is_instance_valid(player):
        return
    state = State.ATTACK
    velocity = Vector2.ZERO
    var direction := global_position.direction_to(player.global_position)
    _play_attack_animation(direction)
    can_attack = false

    # Задержка перед тёмной атакой, чтобы враг не стрелял мгновенно.
    await get_tree().create_timer(0.28).timeout
    if state == State.DEAD:
        return

    _spawn_dark_projectile(direction)
    await get_tree().create_timer(0.45).timeout
    if state != State.DEAD:
        state = State.CHASE
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true

func _spawn_dark_projectile(direction: Vector2) -> void:
    if dark_projectile_scene == null:
        return
    var projectile = dark_projectile_scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position + direction.normalized() * 32.0
    projectile.setup(direction)

func take_damage(amount: int, source_position: Vector2 = Vector2.INF) -> void:
    if state == State.DEAD:
        return

    if source_position != Vector2.INF:
        last_hit_direction = source_position.direction_to(global_position).normalized()
        if last_hit_direction == Vector2.ZERO:
            last_hit_direction = Vector2.DOWN

    health -= amount
    if health <= 0:
        _die()

func _die() -> void:
    state = State.DEAD
    remove_from_group("enemy")
    velocity = Vector2.ZERO

    if collision_shape:
        collision_shape.set_deferred("disabled", true)

    if damage_sound:
        damage_sound.play()

    _try_drop_item()
    sprite.flip_h = last_hit_direction.x < 0
    sprite.play("death")

    var target_position := global_position + last_hit_direction * knockback_distance
    var tween := create_tween()
    tween.tween_property(self, "global_position", target_position, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    await sprite.animation_finished
    queue_free()

func _try_drop_item() -> void:
    if drop_scene == null:
        return
    if randf() <= drop_chance:
        var item = drop_scene.instantiate()
        get_tree().current_scene.add_child(item)
        item.global_position = global_position

func _play_walk_animation(direction: Vector2) -> void:
    sprite.flip_h = false
    if abs(direction.x) > abs(direction.y):
        sprite.play("walk_right" if direction.x > 0 else "walk_left")
    else:
        sprite.play("walk_down" if direction.y > 0 else "walk_up")

func _play_attack_animation(direction: Vector2) -> void:
    sprite.flip_h = direction.x < 0
    if abs(direction.x) > abs(direction.y):
        sprite.play("attack_dark_right" if direction.x > 0 else "attack_dark_left")
    else:
        sprite.play("attack_dark_down" if direction.y > 0 else "attack_dark_up")

func _build_sprite_frames() -> void:
    var frames := SpriteFrames.new()

    _add_sheet_animation(frames, "walk_down", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_down.png", 4, 360, 622, 8.0, true)
    _add_sheet_animation(frames, "walk_up", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_up.png", 4, 310, 600, 8.0, true)
    _add_sheet_animation(frames, "walk_left", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_left.png", 4, 384, 584, 8.0, true)
    _add_sheet_animation(frames, "walk_right", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_right.png", 4, 378, 572, 8.0, true)

    _add_idle_from_sheet(frames, "idle_down", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_down.png", 360, 622)
    _add_idle_from_sheet(frames, "idle_up", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_up.png", 310, 600)
    _add_idle_from_sheet(frames, "idle_left", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_left.png", 384, 584)
    _add_idle_from_sheet(frames, "idle_right", "res://assets/sprites/enemies/goth_girl/sheets/goth_walk_right.png", 378, 572)

    _add_sheet_animation(frames, "attack_dark_down", "res://assets/sprites/enemies/goth_girl/sheets/goth_attack.png", 6, 410, 434, 8.5, false)
    _add_sheet_animation(frames, "attack_dark_up", "res://assets/sprites/enemies/goth_girl/sheets/goth_attack.png", 6, 410, 434, 8.5, false)
    _add_sheet_animation(frames, "attack_dark_left", "res://assets/sprites/enemies/goth_girl/sheets/goth_attack.png", 6, 410, 434, 8.5, false)
    _add_sheet_animation(frames, "attack_dark_right", "res://assets/sprites/enemies/goth_girl/sheets/goth_attack.png", 6, 410, 434, 8.5, false)

    _add_sheet_animation(frames, "death", "res://assets/sprites/enemies/goth_girl/sheets/goth_death.png", 3, 724, 724, 6.0, false)

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
