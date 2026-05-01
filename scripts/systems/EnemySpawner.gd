extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.2
@export var max_enemies_alive: int = 8

@onready var spawn_points: Node2D = $SpawnPoints
@onready var entry_targets: Node2D = $EntryTargets

var is_spawning: bool = true

func _ready() -> void:
	randomize()
	_spawn_loop()

func _spawn_loop() -> void:
	while is_spawning:
		if get_tree().get_nodes_in_group("enemy").size() < max_enemies_alive:
			_spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var spawns: Array[Node] = spawn_points.get_children()
	var targets: Array[Node] = entry_targets.get_children()

	if spawns.is_empty() or targets.is_empty():
		return

	var max_count: int = mini(spawns.size(), targets.size())
	var index: int = randi_range(0, max_count - 1)

	var spawn_marker: Marker2D = spawns[index] as Marker2D
	var target_marker: Marker2D = targets[index] as Marker2D

	if spawn_marker == null or target_marker == null:
		return

	var enemy: Node = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.setup_spawn(spawn_marker.global_position, target_marker.global_position)
