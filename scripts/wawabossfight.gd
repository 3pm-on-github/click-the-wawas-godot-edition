extends Node2D
func _ready() -> void:
	DiscordRPC.details = "bro's cooked"
	DiscordRPC.state = "wawa bossfight"
	DiscordRPC.refresh()
	$words/why.visible = false
	$words/do.visible = false
	$words/you.visible = false
	$words/have.visible = false
	$words/to.visible = false
	$words/click.visible = false
	$words/me.visible = false
	$so.visible = false
	$much.visible = false
	$AudioStreamPlayer2D2.play()
	await get_tree().create_timer(0.079).timeout
	$words/why.visible = true
	await get_tree().create_timer(0.494).timeout
	$words/do.visible = true
	await get_tree().create_timer(0.405).timeout
	$words/you.visible = true
	await get_tree().create_timer(0.451).timeout
	$words/have.visible = true
	await get_tree().create_timer(0.386).timeout
	$words/to.visible = true
	await get_tree().create_timer(0.452).timeout
	$words/click.visible = true
	await get_tree().create_timer(0.449).timeout
	$words/me.visible = true
	
	await get_tree().create_timer(0.381).timeout
	$words/why.visible = false
	$words/do.visible = false
	$words/you.visible = false
	$words/have.visible = false
	$words/to.visible = false
	$words/click.visible = false
	$words/me.visible = false
	$so.visible = true
	await get_tree().create_timer(0.729).timeout
	$so.visible = false
	$much.visible = true
	await get_tree().create_timer(1).timeout
	for i in range(50):
		$much.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	$nvmilldoitlater.visible = true
	for i in range(50):
		$nvmilldoitlater.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
