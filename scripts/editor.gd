extends Node2D
func _process(_delta: float) -> void:
	pass

var focus = ""
var elements = []

func int_to_11bit(value: int) -> String:
	return String.num_uint64(value & 0x7FF, 2).pad_zeros(11)

func save_to_file(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(content)
	file.close()

func load_from_file(path):
	var content = FileAccess.get_file_as_bytes(path)
	return content

func load_and_returnb64(path):
	var content = FileAccess.get_file_as_bytes(path)
	return Marshalls.raw_to_base64(content)

func returnsha256(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	var hash: PackedByteArray = ctx.finish()
	return hash.hex_encode()

func _write_u32(dst: PackedByteArray, v: int) -> void:
	dst.append((v >> 24) & 0xFF)
	dst.append((v >> 16) & 0xFF)
	dst.append((v >> 8) & 0xFF)
	dst.append(v & 0xFF)

func _read_u32(src: PackedByteArray, i: int) -> int:
	return (src[i] << 24) | (src[i + 1] << 16) | (src[i + 2] << 8) | src[i + 3]


# storage method:
# u8    counter
# bytes popup_text
# u8    0x00
# u32   music_b64_length (big-endian)
# bytes music_b64 (UTF-8)
# repeat:
#     u8   packed id/x/y high bits
#     u8   x low
#     u8   y low
#     u8   flags

func save():
	var out := PackedByteArray()

	out.append((digit1 * 10) + digit2)

	for c in popuptext:
		out.append(ord(c))
	out.append(0x00)

	var music_b64: String = load_and_returnb64(musicpath)
	var music_bytes := music_b64.to_utf8_buffer()

	_write_u32(out, music_bytes.size())
	out.append_array(music_bytes)

	for element in elements:
		var id = element.elementid
		var x := int(element.position.x)
		var y := int(element.position.y)
		var flags := 0

		assert(id >= 0 and id < 4)
		assert(x >= 0 and x < 2048)
		assert(y >= 0 and y < 2048)
		assert(flags >= 0 and flags < 256)

		out.append(
			(id & 0b11) |
			(((x >> 8) & 0b111) << 2) |
			(((y >> 8) & 0b111) << 5)
		)
		out.append(x & 0xFF)
		out.append(y & 0xFF)
		out.append(flags)

	save_to_file(out, "user://customstages/"+returnsha256(out)+".ctw")

func loadcontent() -> Dictionary:
	var src: PackedByteArray = load_from_file("user://customstages/savedata.dat") # will be changed soon

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

	var elementz := []
	while i + 3 < src.size():
		var b0 := src[i]
		var b1 := src[i + 1]
		var b2 := src[i + 2]
		var b3 := src[i + 3]

		elementz.append({
			"id": b0 & 0b11,
			"x": (((b0 >> 2) & 0b111) << 8) | b1,
			"y": (((b0 >> 5) & 0b111) << 8) | b2,
			"flags": b3
		})

		i += 4

	result["elements"] = elementz
	return result

var loadedcontent = loadcontent()
var wawacount = 0
var mrfreshcount = 0
func _ready() -> void:
	DirAccess.make_dir_absolute("user://customstages")
	$countereditpopup.visible = false
	$editpopuppopup.visible = false
	$blackbg.visible = true
	if len(str(loadedcontent.counter)) == 1:
		digit1 = 0
		digit2 = int(str(loadedcontent.counter)[0])
	else:
		digit1 = int(str(loadedcontent.counter)[0])
		digit2 = int(str(loadedcontent.counter)[1])
	popuptext = loadedcontent.popup_text
	$counter/Label.text = "0" + str((digit1 * 10)+digit2) if len(str((digit1 * 10)+digit2))==1 else str((digit1 * 10)+digit2)
	$countereditpopup/digit2.text = str(digit2)
	$countereditpopup/digit1.text = str(digit1)
	for element in loadedcontent.elements:
		if element.id == 0:
			var copy = $wawa.duplicate()
			copy.position.x = element.x
			copy.position.y = element.y
			copy.visible = true
			wawacount += 1
			copy.remove_me.connect(_on_wawa_remove_me)
			copy.modulate.a = 0
			elements.append(copy)
			$wawa.get_parent().add_child(copy)
		elif element.id == 1:
			var copy = $mrfresh.duplicate()
			copy.position.x = element.x
			copy.position.y = element.y
			copy.visible = true
			mrfreshcount += 1
			copy.remove_me.connect(_on_mrfresh_remove_me)
			copy.modulate.a = 0
			elements.append(copy)
			$mrfresh.get_parent().add_child(copy)
		else:
			assert(false, "Error: Invalid Element ID "+str(element.id)+"\nYour Saved Stage Data is corrupted.")
	$WawaSelector/counter.text = str(wawacount)
	$MrFreshSelector/counter.text = str(mrfreshcount)
	DiscordRPC.state = "editing a stage ("+popuptext+")"
	DiscordRPC.refresh()
	for i in range(50):
		for element in elements:
			element.modulate.a += 0.02
		$blackbg.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	$blackbg.visible = false
	
func _on_wawa_selector_focus_entered() -> void:
	focus = "Wawa"

func _on_mr_fresh_selector_pressed() -> void:
	focus = "Mr Fresh"

func _on_counterhitbox_pressed() -> void:
	$countereditpopup.visible = true
	for element in elements:
		element.visible = false
	focus = ""

var digit1 = 3
func _on_digit1_addbtn_pressed() -> void:
	focus = ""
	digit1 += 1
	if digit1 == 10:
		digit1 = 0
		if digit2 == 0:
			digit2 = 1
			$countereditpopup/digit2.text = str(digit2)
	$countereditpopup/digit1.text = str(digit1)
func _on_digit1_subbtn_pressed() -> void:
	focus = ""
	digit1 -= 1
	if digit1 == -1:
		digit1 = 9
	if digit2 == 0 and digit1 == 0:
		digit2 = 1
		$countereditpopup/digit2.text = str(digit2)
	$countereditpopup/digit1.text = str(digit1)

var digit2 = 0
func _on_digit2_addbtn_pressed() -> void:
	focus = ""
	digit2 += 1
	if digit1 != 0:
		if digit2 == 10:
			digit2 = 0
	else:
		if digit2 == 10:
			digit2 = 1
	$countereditpopup/digit2.text = str(digit2)
func _on_digit2_subbtn_pressed() -> void:
	focus = ""
	digit2 -= 1
	if digit1 != 0:
		if digit2 == -1:
			digit2 = 9
	else:
		if digit2 == 0:
			digit2 = 9
	$countereditpopup/digit2.text = str(digit2)

func _on_donebtn_pressed() -> void:
	focus = ""
	$counter/Label.text = "0" + str((digit1 * 10)+digit2) if len(str((digit1 * 10)+digit2))==1 else str((digit1 * 10)+digit2)
	$countereditpopup.visible = false
	for element in elements:
		element.visible = true

func _on_bg_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if focus == "Wawa":
			$AudioStreamPlayer2D2.play()
			var copy = $wawa.duplicate()
			copy.position = Vector2(event.position.x-35.75, event.position.y-48)
			if copy.position.x < 0:
				copy.position.x = 0
			if copy.position.y < 0:
				copy.position.y = 0
			copy.visible = true
			wawacount += 1
			copy.remove_me.connect(_on_wawa_remove_me)
			$AudioStreamPlayer2D3.stream = load("res://audio/ow.wav")
			$AudioStreamPlayer2D3.play()
			elements.append(copy)
			$wawa.get_parent().add_child(copy)
			$WawaSelector/counter.text = str(wawacount)
		elif focus == "Mr Fresh":
			$AudioStreamPlayer2D2.play()
			var copy = $mrfresh.duplicate()
			copy.position = Vector2(event.position.x-35.75, event.position.y-48)
			if copy.position.x < 0:
				copy.position.x = 0
			if copy.position.y < 0:
				copy.position.y = 0
			copy.visible = true
			mrfreshcount += 1
			copy.remove_me.connect(_on_mrfresh_remove_me)
			$AudioStreamPlayer2D3.stream = load("res://audio/tp.mp3")
			$AudioStreamPlayer2D3.play()
			elements.append(copy)
			$mrfresh.get_parent().add_child(copy)
			$MrFreshSelector/counter.text = str(mrfreshcount)

func _on_tryitbtn_pressed() -> void:
	save()
	focus = ""
	$blackbg.visible = true
	$AudioStreamPlayer2D3.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D3.play()
	for i in range(50):
		for element in elements:
			element.modulate.a -= 0.02
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.02
		await get_tree().create_timer(0.02).timeout
	$AudioStreamPlayer2D.stop()
	for element in elements:
		element.visible = false
	get_tree().change_scene_to_file("res://scenes/customstage.tscn")

var popuptext = "test"
func _on_edit_popup_pressed() -> void:
	$settingspopup.visible = false
	$editpopuppopup/LineEdit.text = popuptext
	$editpopuppopup.visible = true
	for element in elements:
		element.visible = false
	focus = ""

func _on_editpopup_donebtn_pressed() -> void:
	focus = ""
	popuptext = $editpopuppopup/LineEdit.text
	if popuptext == "":
		popuptext = "Default"
	$editpopuppopup.visible = false
	for element in elements:
		element.visible = true
	DiscordRPC.state = "editing a stage ("+popuptext+")"
	DiscordRPC.refresh()

func _on_back_to_menu_pressed() -> void:
	save()
	focus = ""
	$blackbg.visible = true
	$AudioStreamPlayer2D3.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D3.play()
	for i in range(50):
		for element in elements:
			element.modulate.a -= 0.02
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.02
		await get_tree().create_timer(0.02).timeout
	$AudioStreamPlayer2D.stop()
	for element in elements:
		element.visible = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_delete_stage_pressed() -> void:
	$settingspopup.visible = false
	$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
	$AudioStreamPlayer2D3.play()
	for element in elements:
		element.queue_free()
	elements = []
	musicpath = "res://audio/customstagemusic.mp3"
	popuptext = "Default"
	digit1 = 3
	digit2 = 0
	$counter/Label.text = "0" + str((digit1 * 10)+digit2) if len(str((digit1 * 10)+digit2))==1 else str((digit1 * 10)+digit2)
	$countereditpopup/digit2.text = str(digit2)
	$countereditpopup/digit1.text = str(digit1)
	save()
	wawacount = 0
	mrfreshcount = 0
	$WawaSelector/counter.text = str(wawacount)
	$MrFreshSelector/counter.text = str(wawacount)
	DiscordRPC.state = "editing a stage ("+popuptext+")"
	DiscordRPC.refresh()

func _on_wawa_remove_me(wawa):
	$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
	$AudioStreamPlayer2D2.play()
	$AudioStreamPlayer2D3.play()
	wawacount -= 1
	$WawaSelector/counter.text = str(wawacount)
	elements.erase(wawa)
	wawa.queue_free()
	
func _on_mrfresh_remove_me(mrfresh):
	$AudioStreamPlayer2D3.stream = load("res://audio/meowrgh.mp3")
	$AudioStreamPlayer2D2.play()
	$AudioStreamPlayer2D3.play()
	mrfreshcount -= 1
	$MrFreshSelector/counter.text = str(mrfreshcount)
	elements.erase(mrfresh)
	mrfresh.queue_free()

func _on_settings_pressed() -> void:
	$settingspopup.visible = true
	for element in elements:
		element.visible = false
	focus = ""

func _on_settings_donebtn_pressed() -> void:
	$settingspopup.visible = false
	for element in elements:
		element.visible = true
	focus = ""

var musicpath = "res://audio/customstagemusic.mp3"
func _on_edit_music_pressed() -> void:
	$settingspopup.visible = false
	$editmusicpopup/LineEdit.text = musicpath
	$editmusicpopup.visible = true
	prevmusictime = null
	for element in elements:
		element.visible = false
	focus = ""
	
func _on_editmusic_donebtn_pressed() -> void:
	if not $editmusicpopup/LineEdit.text.ends_with(".mp3"):
		return
	musicpath = $editmusicpopup/LineEdit.text
	if musicpath == "":
		musicpath = "res://audio/customstagemusic.mp3"
	$editmusicpopup.visible = false
	for element in elements:
		element.visible = true
	if prevmusictime != null:
		$AudioStreamPlayer2D.stop()
		$AudioStreamPlayer2D.stream = load("res://audio/editorost.mp3")
		$AudioStreamPlayer2D.play(prevmusictime)
	focus = ""

var prevmusictime = null
func _on_editmusic_playbtn_pressed() -> void:
	if not $editmusicpopup/LineEdit.text.ends_with(".mp3"):
		return
	prevmusictime = $AudioStreamPlayer2D.get_playback_position()
	$AudioStreamPlayer2D.stop()
	if $editmusicpopup/LineEdit.text.begins_with("res://"):
		$AudioStreamPlayer2D.stream = load($editmusicpopup/LineEdit.text)
	else:
		$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_file($editmusicpopup/LineEdit.text)
	$AudioStreamPlayer2D.play()
