extends Node2D

var movement = true
func _ready() -> void:
	$bg.modulate.a = 0.0
	$blackbg.visible = false
	$blackbg.modulate.a = 0.0
	$mainmenu.visible = true
	$mainmenu/Wawa.position = Vector2(2542, 525)
	$mainmenu/title.position = Vector2(-940.0, 64.0)
	$mainmenu/playbtn.position = Vector2(-403, 443)
	$mainmenu/solobtn.visible = false
	$mainmenu/multibtn.visible = false
	$mainmenu/multibtn.position = Vector2(431.0, 443.0)
	$mainmenu/editorbtn.position = Vector2(-403, 582)
	$mainmenu/configbtn.position = Vector2(-403, 724)
	$mainmenu/exitbtn.position = Vector2(-403, 867)
	$solomenu.visible = false
	$solomenu.modulate.a = 0.0
	
	DiscordRPC.state = "in the menu"
	DiscordRPC.refresh()
	
	for i in range(25):
		$bg.modulate.a += 0.04
		await get_tree().create_timer(0.005).timeout
	$AudioStreamPlayer2D.play()
	var tween = get_tree().create_tween()
	$mainmenu/Wawa.rotation_degrees = 0
	tween.tween_property($mainmenu/Wawa, "position", Vector2(1413, 525), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($mainmenu/title, "position", Vector2(64, 64), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($mainmenu/playbtn, "position", Vector2(47, 443), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.25).timeout
	var tween2 = get_tree().create_tween()
	tween2.tween_property($mainmenu/editorbtn, "position", Vector2(47, 582), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.25).timeout
	var tween3 = get_tree().create_tween()
	tween3.tween_property($mainmenu/configbtn, "position", Vector2(47, 724), 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.25).timeout
	var tween4 = get_tree().create_tween()
	tween4.tween_property($mainmenu/exitbtn, "position", Vector2(47, 867), 0.5).set_trans(Tween.TRANS_SINE)
	$mainmenu/solobtn.visible = true
	while true:
		if movement:
			for i in range(40):
				$mainmenu/title.position.y += 0.5
				await get_tree().create_timer(0.0375).timeout
			for i in range(80):
				$mainmenu/title.position.y -= 0.5
				await get_tree().create_timer(0.0375).timeout
			for i in range(40):
				$mainmenu/title.position.y += 0.5
				await get_tree().create_timer(0.0375).timeout

func _process(_delta: float) -> void:
	$mainmenu/Wawa.rotation_degrees += 1
	$solomenu/title/wawabanner/Label.position.x -= 1.0
	if $solomenu/title/wawabanner/Label.position.x == -89.0:
		$solomenu/title/wawabanner/Label.position.x = 0.0

var playtoggled = false
func _on_playbtn_pressed() -> void:
	playtoggled = not playtoggled
	if playtoggled:
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		var tween = get_tree().create_tween()
		tween.tween_property($mainmenu/solobtn, "position", Vector2(431.0, 443.0), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.25).timeout
		$mainmenu/multibtn.visible = true
		var tween2 = get_tree().create_tween()
		tween2.tween_property($mainmenu/multibtn, "position", Vector2(431.0, 582.0), 0.25).set_trans(Tween.TRANS_SINE)
	else:
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		var tween = get_tree().create_tween()
		tween.tween_property($mainmenu/multibtn, "position", Vector2(431.0, 443.0), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(0.25).timeout
		$mainmenu/multibtn.visible = false
		var tween2 = get_tree().create_tween()
		tween2.tween_property($mainmenu/solobtn, "position", Vector2(47, 443), 0.25).set_trans(Tween.TRANS_SINE)

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
	$mainmenu/Wawa.texture = load("res://images/evilWawa.png")
	var tween = get_tree().create_tween()
	tween.tween_property($mainmenu/Wawa, "scale", Vector2(5, 0.7), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property($mainmenu/Wawa, "scale", Vector2(5, 5), 0.1).set_trans(Tween.TRANS_SINE)
	await tween.finished
	$mainmenu/Wawa.texture = load("res://images/Wawa.png")
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
	$AudioStreamPlayer2D2.stream = load("res://audio/editordelete.mp3")
	$AudioStreamPlayer2D2.play()

func _on_solobtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$wawahitbox.visible = false
	for i in range(40):
		$mainmenu.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$mainmenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$solomenu.visible = true
	for i in range(40):
		$solomenu.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

func _on_solobtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()

func _on_multibtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()

func _on_classicstagesbtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	get_tree().change_scene_to_file("res://scenes/stages/stage1.tscn")
