extends Node2D
func _process(_delta: float) -> void:
	pass

var focus = ""
var elements = []
@onready var audioblur := AudioServer.get_bus_effect(
	AudioServer.get_bus_index("Master"), 2
) as AudioEffectLowPassFilter

func int_to_11bit(value: int) -> String:
	return String.num_uint64(value & 0x7FF, 2).pad_zeros(11)

func save_to_file(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data: PackedByteArray = PackedByteArray()
	for character in content:
		data.append(ord(character))
	file.store_buffer(data)
	file.close()

func load_from_file(path):
	var content = FileAccess.get_file_as_bytes(path)
	return content

func load_and_returnb64(path):
	var content = FileAccess.get_file_as_bytes(path)
	return Marshalls.raw_to_base64(content)

func returnsha256(data: Dictionary) -> String:
	var json_string := JSON.stringify(data)
	var bytes: PackedByteArray = json_string.to_utf8_buffer()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	var hashed: PackedByteArray = ctx.finish()
	return hashed.hex_encode()

func _write_u32(dst: PackedByteArray, v: int) -> void:
	dst.append((v >> 24) & 0xFF)
	dst.append((v >> 16) & 0xFF)
	dst.append((v >> 8) & 0xFF)
	dst.append(v & 0xFF)

func _write_u24(dst: PackedByteArray, v: int) -> void:
	dst.append((v >> 16) & 0xFF)
	dst.append((v >> 8) & 0xFF)
	dst.append(v & 0xFF)
	
func _write_u16(dst: PackedByteArray, v: int) -> void:
	dst.append((v >> 8) & 0xFF)
	dst.append(v & 0xFF)

func _read_u32(src: PackedByteArray, i: int) -> int:
	return (src[i] << 24) | (src[i + 1] << 16) | (src[i + 2] << 8) | src[i + 3]
	
func _read_u24(src: PackedByteArray, i: int) -> int:
	return(src[i] << 16) | (src[i + 1] << 8) | src[i + 2]
	
func _read_u16(src: PackedByteArray, i: int) -> int:
	return (src[i] << 8) | src[i + 1]

# storage method:
# u8    counter
# bytes popup_text
# u8    0x00
# u16   lights_bpm (0 if disabled)
# u24   lights_startpos (starttime*1000)
# lights_rgb:
#     u8   lights_red
#     u8   lights_green
#     u8   lights_blue
#     u8   lights_alpha
# u32   music_b64_length (big-endian)
# bytes music_b64 (UTF-8)
# repeat:
#     u8   packed id/x/y high bits
#     u8   x low
#     u8   y low
#     u8   flags

var finalpath = ""
func save():
	var out := {}
	out['counter'] = digit1*10+digit2
	out['popup_text'] = popuptext
	out['lights_bpm'] = 0 if not lightsenabled else lightsbpm
	out['lights_startpos'] = lightsstarttime*1000
	out['lights_rgb'] = [lightsrgb.r8, lightsrgb.g8, lightsrgb.b8, lightsrgb.a8]
	out['music_encodeddata'] = load_and_returnb64(musicpath)
	out['elements'] = []
	for element in elements:
		var id = element.elementid
		var x := int(element.position.x)
		var y := int(element.position.y)
		var flags := 0
		assert(id >= 0)
		assert(x >= 0)
		assert(y >= 0)
		assert(flags >= 0)
		out["elements"].append({"id": id, "x": x, "y": y, "flags": flags})
	finalpath = "user://customstages/"+returnsha256(out)+".ctw"
	save_to_file(JSON.stringify(out), finalpath)

func loadcontent():
	var src: PackedByteArray = load_from_file(Global.customstagetotry)
	return JSON.parse_string(src.get_string_from_utf8())

var loadedcontent = {
	"counter": 30,
	"popup_text": "Default",
	"lights_bpm": 0,
	"lights_startpos": 0,
	"lights_rgb": [144, 255, 255, 255],
	"elements": []
}
var wawacount = 0
var mrfreshcount = 0
func _ready() -> void:
	if loadcontent():
		loadedcontent = loadcontent()
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
	$selectorbg/WawaSelector/counter.text = str(wawacount)
	$selectorbg/MrFreshSelector/counter.text = str(mrfreshcount)
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
			$selectorbg/WawaSelector/counter.text = str(wawacount)
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
			$selectorbg/MrFreshSelector/counter.text = str(mrfreshcount)

func _on_tryitbtn_pressed() -> void:
	save()
	Global.customstagetotry = finalpath
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
	$deletestagepopup.modulate.a = 0.0
	$deletestagepopup.visible = true
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 2, true)
	var tween = get_tree().create_tween()
	tween.tween_property(audioblur, "cutoff_hz", 400, 0.5).set_trans(Tween.TRANS_SINE)
	for i in range(25):
		$counter.modulate.a -= 0.04
		$selectorbg.modulate.a -= 0.04
		$settingspopup.modulate.a -= 0.04
		$deletestagepopup.modulate.a += 0.04
		await get_tree().create_timer(0.01).timeout
	$settingspopup.visible = false
	$settingspopup.modulate.a = 1.0

func _on_deletestage_yesbtn_pressed() -> void:
	$deletestagepopup.visible = false
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
	$selectorbg/WawaSelector/counter.text = str(wawacount)
	$selectorbg/MrFreshSelector/counter.text = str(wawacount)
	DiscordRPC.state = "editing a stage ("+popuptext+")"
	DiscordRPC.refresh()
	var tween = get_tree().create_tween()
	tween.tween_property(audioblur, "cutoff_hz", 20500, 0.5).set_trans(Tween.TRANS_SINE)
	$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
	$AudioStreamPlayer2D3.play()
	for i in range(25):
		$counter.modulate.a += 0.04
		$selectorbg.modulate.a += 0.04
		await get_tree().create_timer(0.02).timeout
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 2, false)
	
func _on_deletestage_nobtn_pressed() -> void:
	$deletestagepopup.visible = false
	for element in elements:
		element.modulate.a = 0.0
		element.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(audioblur, "cutoff_hz", 20500, 0.5).set_trans(Tween.TRANS_SINE)
	for i in range(25):
		for element in elements:
			element.modulate.a += 0.04
		$counter.modulate.a += 0.04
		$selectorbg.modulate.a += 0.04
		await get_tree().create_timer(0.02).timeout
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 2, false)

func _on_wawa_remove_me(wawa):
	$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
	$AudioStreamPlayer2D2.play()
	$AudioStreamPlayer2D3.play()
	wawacount -= 1
	$selectorbg/WawaSelector/counter.text = str(wawacount)
	elements.erase(wawa)
	wawa.queue_free()
	
func _on_mrfresh_remove_me(mrfresh):
	$AudioStreamPlayer2D3.stream = load("res://audio/meowrgh.mp3")
	$AudioStreamPlayer2D2.play()
	$AudioStreamPlayer2D3.play()
	mrfreshcount -= 1
	$selectorbg/MrFreshSelector/counter.text = str(mrfreshcount)
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
		$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_file($editmusicpopup/LineEdit.text)
	else:
		$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_file($editmusicpopup/LineEdit.text)
	$AudioStreamPlayer2D.play()

func _on_edit_lights_pressed() -> void:
	$settingspopup.visible = false
	$editlightspopup.visible = true
	$editlightspopup/BPM.value = lightsbpm
	$editlightspopup/StartTime.value = lightsstarttime
	$editlightspopup/ColorPickerButton.color = lightsrgb
	for element in elements:
		element.visible = false
	focus = ""

var lightsbpm = loadedcontent.lights_bpm
var lightsstarttime = loadedcontent.lights_startpos
var lightsrgb = Color.from_rgba8(loadedcontent.lights_rgb[0], loadedcontent.lights_rgb[1], loadedcontent.lights_rgb[2], loadedcontent.lights_rgb[3])
var lightsenabled = false
func _on_editlights_donebtn_pressed() -> void:
	$editlightspopup.visible = false
	lightsbpm = $editlightspopup/BPM.value
	lightsstarttime = $editlightspopup/StartTime.value
	lightsrgb = $editlightspopup/ColorPickerButton.color
	for element in elements:
		element.visible = true
	focus = ""

func _on_editlights_enabled_pressed() -> void:
	lightsenabled = not lightsenabled
