extends Node2D

@export var fire_rate := 0.05
@export var bullet_speed := 600.0

var fire_timer := 0.0

func _ready() -> void:
	$Wawa.visible = false
	$counter.visible = false
	$shooter.visible = false
	$Bullet.visible = false
	$popup.visible = true
	$AudioStreamPlayer2D.play(Global.music_playbacktime)
	$AudioStreamPlayer2D2.play()
	
func _process(delta: float) -> void:
	$shooter.look_at(get_global_mouse_position())
	fire_timer -= delta
	if Input.is_action_pressed("ui_select") and fire_timer <= 0.0:
		var bullet = $Bullet.duplicate()
		bullet.global_position = $shooter.global_position
		bullet.rotation = $shooter.rotation
		bullet.visible = true
		add_child(bullet)
		fire_timer = fire_rate

var wawaskilled = 0
func _on_wawa_shot() -> void:
	wawaskilled+=1
	if wawaskilled == 35:
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/winscreen.tscn")

var wawas = []
func _on_ok_pressed() -> void:
	DiscordRPC.state = "stage 3 (shoot the wawa)"
	DiscordRPC.refresh()
	$popup.visible = false
	$shooter.visible = true
	$counter.visible = true
	for i in range(35):
		var copy = $Wawa.duplicate()
		copy.wawa_shot.connect(_on_wawa_shot)
		copy.visible = true
		wawas.append(copy)
		$Wawa.get_parent().add_child(copy)
	var counter = 31
	for i in range(31):
		$AudioStreamPlayer2D2.stream = load("res://audio/tick.wav")
		$AudioStreamPlayer2D2.play()
		counter-=1
		$counter/Label.text = "0" + str(counter) if len(str(counter))==1 else str(counter)
		await get_tree().create_timer(1.0).timeout
	if wawaskilled != 35:
		$AudioStreamPlayer2D.stop()
		for wawa in wawas:
			wawa.visible = false
		$blackbg.visible = true
		$blackbg.modulate.a = 1.0
		$youlost.visible = true
		await get_tree().create_timer(2.5).timeout
		for i in range(50):
			$youlost.modulate.a -= 0.02
			await get_tree().create_timer(0.02).timeout
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
