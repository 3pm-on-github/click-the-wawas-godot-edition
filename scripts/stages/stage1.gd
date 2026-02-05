# 1.00 ★
extends Node2D

func _ready() -> void:
	$popup.visible = true
	$counter.visible = false
	$youlost.visible = false
	$blackbg.visible = true
	$wawa.visible = false
	$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D2.play()
	for i in range(50):
		$blackbg.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	$blackbg.visible = false

func _process(_delta: float) -> void:
	pass

var wawaskilled = 0
func _on_wawa_clicked() -> void:
	wawaskilled+=1
	if wawaskilled == 35:
		print("star ranking:", 1.15-(30.0-float(counter))/100.0)
		await get_tree().create_timer(2).timeout
		Global.music_playbacktime = $AudioStreamPlayer2D.get_playback_position()
		get_tree().change_scene_to_file("res://scenes/stages/stage3.tscn")

var counter = 31
var wawas = []
func _on_ok_pressed() -> void:
	DiscordRPC.state = "stage 1 (click the wawas!!!)"
	DiscordRPC.refresh()
	$popup.visible = false
	$counter.visible = true
	for i in range(35):
		var copy = $wawa.duplicate()
		copy.wawa_clicked.connect(_on_wawa_clicked)
		copy.visible = true
		wawas.append(copy)
		$wawa.get_parent().add_child(copy)
	for i in range(31):
		$AudioStreamPlayer2D2.stream = load("res://audio/tick.wav")
		$AudioStreamPlayer2D2.play()
		counter-=1
		$counter/Label.text = "0" + str(counter) if len(str(counter))==1 else str(counter)
		await get_tree().create_timer(1.0).timeout
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
