
extends Area2D

@export var speed: float = 430.0
@export var max_distance: float = 285.0
@export var damage: int = 1

var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2

func _ready() -> void:
    start_position = global_position
    body_entered.connect(_on_body_entered)

func setup(new_direction: Vector2) -> void:
    direction = new_direction.normalized()
    rotation = direction.angle()

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    if global_position.distance_to(start_position) >= max_distance:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("enemy") and body.has_method("take_damage"):
        body.take_damage(damage, global_position)
        queue_free()
    elif body.is_in_group("world"):
        queue_free()
