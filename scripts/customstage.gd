extends Node2D

func load_from_file():
	var content = FileAccess.get_file_as_bytes(Global.customstagetotry)
	return content

func _read_u32(src: PackedByteArray, i: int) -> int:
	return (src[i] << 24) | (src[i + 1] << 16) | (src[i + 2] << 8) | src[i + 3]

func loadcontent() -> Dictionary:
	var src: PackedByteArray = load_from_file()

	var result := {
		"counter": 30,
		"popup_text": "Default",
		"music_encodeddata": "",
		"elements": []
	}

	if src.is_empty():
		return result

	var i := 0

	result["counter"] = src[i]
	i += 1

	var popup := ""
	while i < src.size() and src[i] != 0x00:
		popup += char(src[i])
		i += 1
	result["popup_text"] = popup

	if i >= src.size():
		return result
	i += 1

	if i + 4 > src.size():
		return result

	var music_len := _read_u32(src, i)
	i += 4

	if i + music_len > src.size():
		return result

	result["music_encodeddata"] = \
		src.slice(i, i + music_len).get_string_from_utf8()
	i += music_len

	var elements := []
	while i + 3 < src.size():
		var b0 := src[i]
		var b1 := src[i + 1]
		var b2 := src[i + 2]
		var b3 := src[i + 3]

		elements.append({
			"id": b0 & 0b11,
			"x": (((b0 >> 2) & 0b111) << 8) | b1,
			"y": (((b0 >> 5) & 0b111) << 8) | b2,
			"flags": b3
		})

		i += 4

	result["elements"] = elements
	return result

var bpm = 130.0
var startpos = 0.055
var loadedcontent = loadcontent()
func _ready() -> void:
	$popup.visible = true
	$counter.visible = false
	$youlost.visible = false
	$blackbg.visible = true
	$lights.visible = false
	$popup/Label.text = loadedcontent.popup_text
	$wawa.visible = false
	$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_buffer(Marshalls.base64_to_raw(loadedcontent.music_encodeddata))
	$AudioStreamPlayer2D.play(startpos)
	$AudioStreamPlayer2D2.play()
	lights()
	for i in range(50):
		$blackbg.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	$blackbg.visible = false
	
func lights():
	var toggle = false
	while true:
		toggle = not toggle
		if not playing:
			break
		if toggle:
			$lights/lightl1.visible = true
			$lights/lightr1.visible = true
			$lights/lightl2.visible = false
			$lights/lightr2.visible = false
			$lights/lightl1.modulate.a = 1.0
			$lights/lightr1.modulate.a = 1.0
			var tween1 = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			tween1.tween_property($lights/lightl1, "modulate", Color.from_rgba8(255, 255, 255, 0), 1/(bpm/60))
			tween2.tween_property($lights/lightr1, "modulate", Color.from_rgba8(255, 255, 255, 0), 1/(bpm/60))
		else:
			$lights/lightl1.visible = false
			$lights/lightr1.visible = false
			$lights/lightl2.visible = true
			$lights/lightr2.visible = true
			$lights/lightl2.modulate.a = 1.0
			$lights/lightr2.modulate.a = 1.0
			var tween1 = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			tween1.tween_property($lights/lightl2, "modulate", Color.from_rgba8(255, 255, 255, 0), 1/(bpm/60))
			tween2.tween_property($lights/lightr2, "modulate", Color.from_rgba8(255, 255, 255, 0), 1/(bpm/60))
		await get_tree().create_timer(1/(bpm/60)).timeout

var elementskilled = 0
func _on_element_clicked() -> void:
	elementskilled+=1
	if elementskilled == len(elements):
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/winscreen.tscn")

var elements = []
var playing = true
func _on_ok_pressed() -> void:
	DiscordRPC.state = "custom stage ("+loadedcontent.popup_text+")"
	DiscordRPC.refresh()
	$popup.visible = false
	$counter.visible = true
	$lights.visible = true
	for element in loadedcontent.elements:
		if element.id == 0:
			var copy = $wawa.duplicate()
			copy.position.x = element.x
			copy.position.y = element.y
			copy.visible = true
			copy.wawa_clicked.connect(_on_element_clicked)
			elements.append(copy)
			$wawa.get_parent().add_child(copy)
		elif element.id == 1:
			var copy = $mrfresh.duplicate()
			copy.position.x = element.x
			copy.position.y = element.y
			copy.visible = true
			copy.mrfresh_clicked.connect(_on_element_clicked)
			elements.append(copy)
			$mrfresh.get_parent().add_child(copy)
	var counter = loadedcontent.counter+1
	for i in range(loadedcontent.counter+1):
		$AudioStreamPlayer2D2.stream = load("res://audio/tick.wav")
		$AudioStreamPlayer2D2.play()
		counter-=1
		$counter/Label.text = "0" + str(counter) if len(str(counter))==1 else str(counter)
		await get_tree().create_timer(1.0).timeout
	if elementskilled != len(elements):
		playing = false
		$AudioStreamPlayer2D.stop()
		for element in elements:
			element.visible = false
		$blackbg.visible = true
		$blackbg.modulate.a = 1.0
		$youlost.visible = true
		await get_tree().create_timer(2.5).timeout
		for i in range(50):
			$youlost.modulate.a -= 0.02
			await get_tree().create_timer(0.02).timeout
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/editor.tscn")
