extends Node2D

func _ready() -> void:
	await get_tree().create_timer(7.62).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(_delta: float) -> void:
	pass
