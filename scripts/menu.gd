extends Node2D

var movement = true
func _ready() -> void:
	$bg.modulate.a = 0.0
	$blackbg.visible = false
	$blackbg.modulate.a = 0.0
	$Wawa.position = Vector2(2542, 525)
	$title.position = Vector2(-940.0, 64.0)
	$playbtn.position = Vector2(-403, 443)
	$solobtn.visible = false
	$multibtn.visible = false
	$multibtn.position = Vector2(431.0, 443.0)
	$editorbtn.position = Vector2(-403, 582)
	$configbtn.position = Vector2(-403, 724)
	$exitbtn.position = Vector2(-403, 867)
	
	DiscordRPC.state = "in the menu"
	DiscordRPC.refresh()
	
	for i in range(25):
		$bg.modulate.a += 0.04
		await get_tree().create_timer(0.005).timeout
	$AudioStreamPlayer2D.play()
	var tween = get_tree().create_tween()
	$Wawa.rotation_degrees = 0
	tween.tween_property($Wawa, "position", Vector2(1413, 525), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($title, "position", Vector2(64, 64), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($playbtn, "position", Vector2(47, 443), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.25).timeout
	var tween2 = get_tree().create_tween()
	tween2.tween_property($editorbtn, "position", Vector2(47, 582), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.25).timeout
	var tween3 = get_tree().create_tween()
	tween3.tween_property($configbtn, "position", Vector2(47, 724), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.25).timeout
	var tween4 = get_tree().create_tween()
	tween4.tween_property($exitbtn, "position", Vector2(47, 867), 0.5).set_trans(Tween.TRANS_SINE)
	$solobtn.visible = true
	while true:
		if movement:
			for i in range(40):
				$title.position.y += 0.5
				await get_tree().create_timer(0.0375).timeout
			for i in range(80):
				$title.position.y -= 0.5
				await get_tree().create_timer(0.0375).timeout
			for i in range(40):
				$title.position.y += 0.5
				await get_tree().create_timer(0.0375).timeout

func _process(_delta: float) -> void:
	$Wawa.rotation_degrees += 1

var playtoggled = false
func _on_playbtn_pressed() -> void:
	playtoggled = not playtoggled
	if playtoggled:
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		var tween = get_tree().create_tween()
		tween.tween_property($solobtn, "position", Vector2(431.0, 443.0), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.25).timeout
		$multibtn.visible = true
		var tween2 = get_tree().create_tween()
		tween2.tween_property($multibtn, "position", Vector2(431.0, 582.0), 0.25).set_trans(Tween.TRANS_SINE)
	else:
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		var tween = get_tree().create_tween()
		tween.tween_property($multibtn, "position", Vector2(431.0, 443.0), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.25).timeout
		$multibtn.visible = false
		var tween2 = get_tree().create_tween()
		tween2.tween_property($solobtn, "position", Vector2(47, 443), 0.25).set_trans(Tween.TRANS_SINE)

func _on_playbtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()

func _on_exitbtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()

func _on_exitbtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	get_tree().quit()

var clicks = 0
func _on_wawahitbox_pressed() -> void:
	clicks += 1
	$AudioStreamPlayer2D2.stream = load("res://audio/ow.wav")
	$AudioStreamPlayer2D2.play()
	$Wawa.texture = load("res://images/evilWawa.png")
	var tween = get_tree().create_tween()
	tween.tween_property($Wawa, "scale", Vector2(5, 0.7), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Wawa, "scale", Vector2(5, 5), 0.1).set_trans(Tween.TRANS_SINE)
	await tween.finished
	$Wawa.texture = load("res://images/Wawa.png")
	$AudioStreamPlayer2D.pitch_scale -= 0.01
	$blackbg.visible = true
	$blackbg.modulate.a += 0.01
	if clicks == 100:
		print("bros cooked lmaoo")
		$wawahitbox.visible = false
		$AudioStreamPlayer2D.stop()
		await get_tree().create_timer(1.0).timeout
		movement = false
		get_tree().change_scene_to_file("res://scenes/wawabossfight.tscn")

func _on_editorbtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()

func _on_editorbtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	get_tree().change_scene_to_file("res://scenes/editor.tscn")

func _on_hitbox_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	get_tree().change_scene_to_file("res://scenes/gallery.tscn")


func _on_multibtn_pressed() -> void:
	pass # the api isnt real yet so i cant make it rn

func _on_solobtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	get_tree().change_scene_to_file("res://scenes/stages/stage1.tscn")
