extends Node2D

func _ready() -> void:
	DiscordRPC.app_id = 1456256387326677054
	DiscordRPC.details = "a game where you click wawas"
	DiscordRPC.state = "idle"
	DiscordRPC.large_image = "wawa"
	DiscordRPC.large_image_text = "wawa"
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
	await get_tree().create_timer(7.62).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(_delta: float) -> void:
	pass
