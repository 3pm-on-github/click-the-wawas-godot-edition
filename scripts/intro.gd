extends Node2D

func loadconfig():
	var src: PackedByteArray = FileAccess.get_file_as_bytes("user://config.json")
	if src.get_string_from_utf8() == "": return
	return JSON.parse_string(src.get_string_from_utf8())

func _ready() -> void:
	var loadedconfig = loadconfig()
	if "skipintro"in loadedconfig:if loadedconfig.skipintro:get_tree().change_scene_to_file("res://scenes/menu.tscn")
	await get_tree().create_timer(0.1).timeout
	$VideoStreamPlayer.play()
	await get_tree().create_timer(7.62).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(_delta: float) -> void:
	pass
