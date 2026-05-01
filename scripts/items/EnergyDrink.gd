
extends Area2D

@export var heal_amount: int = 1
@export var lifetime: float = 12.0

@onready var sprite: Sprite2D = $Sprite2D
var base_y: float
var time_passed: float = 0.0

func _ready() -> void:
    base_y = sprite.position.y
    body_entered.connect(_on_body_entered)
    await get_tree().create_timer(lifetime).timeout
    if is_inside_tree():
        queue_free()

func _process(delta: float) -> void:
    time_passed += delta
    sprite.position.y = base_y + sin(time_passed * 4.0) * 5.0
    sprite.rotation = sin(time_passed * 2.0) * 0.08

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player") and body.has_method("heal"):
        body.heal(heal_amount)
        queue_free()
