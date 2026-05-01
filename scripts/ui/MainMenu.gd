
extends Control

func _ready() -> void:
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_settings_button_pressed() -> void:
	$InfoLabel.text = "Settings пока заглушка. Потом добавим громкость музыки и SFX."
