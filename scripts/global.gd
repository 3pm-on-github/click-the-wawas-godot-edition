extends Node

var music_playbacktime = 0
var customstagetotry = ""

func _ready() -> void:
	DiscordRPC.app_id = 1456256387326677054
	DiscordRPC.details = "a game where you click wawas"
	DiscordRPC.state = "idle"
	DiscordRPC.large_image = "wawa"
	DiscordRPC.large_image_text = "wawa"
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
