extends Node2D
func _process(_delta: float) -> void:
	pass

var focus = ""
var elements = []
var next_beat_time = 0
var beat_index = 0
var beat_tween : Tween = null
var beat1 = preload("res://audio/beat1.mp3")
var beat2 = preload("res://audio/beat2.mp3")
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

func copy_res_to_user(res_path: String, user_path: String) -> bool:
	if not FileAccess.file_exists(res_path):
		push_error("Source missing: " + res_path)
		return false
	var data := FileAccess.get_file_as_bytes(res_path)
	if data.is_empty():
		push_error("Source empty or not packed: " + res_path)
		return false
	DirAccess.make_dir_recursive_absolute(user_path.get_base_dir())
	var f := FileAccess.open(user_path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open destination: " + user_path)
		return false
	f.store_buffer(data)
	f.close()
	return true

func load_and_returnb64(path: String):
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
	
func returnsha256str(data: String) -> String:
	var bytes: PackedByteArray = data.to_utf8_buffer()
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

var finalpath = ""
var stageid = ""
func save():
	var out := {}
	out['version'] = 1
	out['counter'] = digit1*10+digit2
	out['popup_text'] = popuptext
	out['author'] = authorname
	out['lights_bpm'] = 0 if not lightsenabled else lightsbpm
	out['lights_startpos'] = lightsstarttime*1000
	out['lights_rgb'] = [lightsrgb.r8, lightsrgb.g8, lightsrgb.b8, lightsrgb.a8]
	out['music_encodeddata'] = load_and_returnb64(musicpath)
	out['music_path_sha256'] = returnsha256str(musicpath)
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
	stageid = returnsha256(out)
	save_to_file(JSON.stringify(out), finalpath)

func savemusicpath(musicpath: String):
	var out = loadedmusicpaths
	out[returnsha256str(musicpath)] = musicpath
	save_to_file(JSON.stringify(out), "user://savedmusicpaths.json")
	loadedmusicpaths = out

func loadcontent():
	var src: PackedByteArray = load_from_file(Global.customstagetotry)
	if src.get_string_from_utf8() == "": return
	return JSON.parse_string(src.get_string_from_utf8())

func loadmusicpaths():
	var src: PackedByteArray = load_from_file("user://savedmusicpaths.json")
	if src.get_string_from_utf8() == "": return
	return JSON.parse_string(src.get_string_from_utf8())

var loadedcontent = {
	"version": 1,
	"counter": 30,
	"popup_text": "Default",
	"lights_bpm": 120.0,
	"lights_startpos": 0.0,
	"lights_rgb": [144, 255, 255, 255],
	"music_path_sha256": "dd9db6c2ec014e37defe49a42f80a7f1e556f283d166cfb0835dda6e6fd63f41",
	"elements": []
}
var loadedmusicpaths = {}
var wawacount = 0
var mrfreshcount = 0
func _ready() -> void:
	copy_res_to_user("res://audio/customstagemusic.mp3", "user://customstagemusic.mp3")
	dontrunthebpmpreview = true
	if loadcontent():
		loadedcontent = loadcontent()
	if loadmusicpaths():
		loadedmusicpaths = loadmusicpaths()
		if loadedcontent.music_path_sha256 in loadedmusicpaths:
			musicpath = loadedmusicpaths[loadedcontent.music_path_sha256]
		else:
			print("Error: Music Path not found in Music Path List. :(")
	lightsbpm = loadedcontent.lights_bpm
	lightsstarttime = loadedcontent.lights_startpos/1000
	lightsrgb = Color.from_rgba8(loadedcontent.lights_rgb[0], loadedcontent.lights_rgb[1], loadedcontent.lights_rgb[2], loadedcontent.lights_rgb[3])
	$editlightspopup/BPM.value = lightsbpm
	$editlightspopup/StartTime.value = lightsstarttime
	$editlightspopup/ColorPickerButton.color = lightsrgb
	$countereditpopup.visible = false
	$editpopuppopup.visible = false
	$editauthorpopup.visible = false
	$blackbg.visible = true
	$selectorbg/uploading.visible = false
	dontrunthebpmpreview = false
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
			$AudioStreamPlayer2D2.stream = load("res://audio/clickfast.ogg")
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
			$AudioStreamPlayer2D2.stream = load("res://audio/clickfast.ogg")
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
	if len(elements) == 0:
		$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
		$AudioStreamPlayer2D3.play()
		return
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

var authorname = "Wawa Clicker"
func _on_edit_author_pressed() -> void:
	$settingspopup.visible = false
	$editauthorpopup/LineEdit.text = authorname
	$editauthorpopup.visible = true
	for element in elements:
		element.visible = false
	focus = ""

func _on_editauthor_donebtn_pressed() -> void:
	focus = ""
	authorname = $editauthorpopup/LineEdit.text
	if authorname == "":
		authorname = "Wawa Clicker"
	$editauthorpopup.visible = false
	for element in elements:
		element.visible = true
	
func _on_back_to_menu_pressed() -> void:
	if len(elements) != 0:
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
	musicpath = "user://customstagemusic.mp3"
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

var musicpath = "user://customstagemusic.mp3"
func _on_edit_music_pressed() -> void:
	$settingspopup.visible = false
	$editmusicpopup/changebtn.text = musicpath.get_file()
	$editmusicpopup.visible = true
	prevmusictime = null
	for element in elements:
		element.visible = false
	focus = ""

func _on_editmusic_changebtn_pressed() -> void:
	$editmusicpopup/FileDialog.visible = true

func _on_editmusic_file_dialog_file_selected(path: String) -> void:
	musicpath = path
	$editmusicpopup/changebtn.text = musicpath.get_file()

func _on_editmusic_donebtn_pressed() -> void:
	if not musicpath.ends_with(".mp3"):
		return
	if musicpath == "":
		musicpath = "user://customstagemusic.mp3"
	$editmusicpopup.visible = false
	for element in elements:
		element.visible = true
	if prevmusictime != null:
		$AudioStreamPlayer2D.stop()
		$AudioStreamPlayer2D.stream = load("res://audio/editorost.mp3")
		$AudioStreamPlayer2D.play(prevmusictime)
	focus = ""
	if not returnsha256str(musicpath) in loadedmusicpaths:
		savemusicpath(musicpath)

var prevmusictime = null
func _on_editmusic_playbtn_pressed() -> void:
	prevmusictime = $AudioStreamPlayer2D.get_playback_position()
	$AudioStreamPlayer2D.stop()
	if musicpath.begins_with("res://"):
		$AudioStreamPlayer2D.stream = load(musicpath)
	else:
		$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_file(musicpath)
	$AudioStreamPlayer2D.play()

func _on_edit_lights_pressed() -> void:
	$settingspopup.visible = false
	$editlightspopup.visible = true
	for element in elements:
		element.visible = false
	focus = ""

var lightsbpm = 120.0
var lightsstarttime = 0.0
var lightsrgb = Color.from_rgba8(144, 255, 255, 255)
var lightsenabled = false
func _on_editlights_donebtn_pressed() -> void:
	$editlightspopup.visible = false
	$editlightspopup/bpmfinder.visible = false
	alreadystartedbpmpreview = false
	lightsbpm = $editlightspopup/BPM.value
	lightsstarttime = $editlightspopup/StartTime.value
	lightsrgb = $editlightspopup/ColorPickerButton.color
	if prevmusictime != null:
		$AudioStreamPlayer2D.stop()
		$AudioStreamPlayer2D.stream = load("res://audio/editorost.mp3")
		$AudioStreamPlayer2D.play(prevmusictime)
	for element in elements:
		element.visible = true
	focus = ""

func _on_editlights_enabled_pressed() -> void:
	lightsenabled = not lightsenabled

var alreadystartedbpmpreview = false
var dontrunthebpmpreview = false
func _on_bpm_value_changed(value: float) -> void:
	$editlightspopup/bpmfinder.visible = true
	lightsbpm = value
	if (not alreadystartedbpmpreview) and (not dontrunthebpmpreview):
		start_bpm_preview()
	else:
		next_beat_time = Time.get_ticks_usec()
		beat_index = 0

func start_bpm_preview():
	alreadystartedbpmpreview = true
	prevmusictime = $AudioStreamPlayer2D.get_playback_position()
	$AudioStreamPlayer2D.stop()
	if musicpath.begins_with("res://"):
		$AudioStreamPlayer2D.stream = load(musicpath)
	else:
		$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_file(musicpath)
	$AudioStreamPlayer2D.play(lightsstarttime)
	next_beat_time = Time.get_ticks_usec()
	beat_index = 0
	run_beat_loop()

func run_beat_loop():
	while alreadystartedbpmpreview:
		var now = Time.get_ticks_usec()
		var beat_interval = 60.0 / lightsbpm * 1_000_000.0
		if now >= next_beat_time:
			play_beat()
			next_beat_time += beat_interval
		await get_tree().process_frame

func play_beat():
	beat_index += 1
	if beat_index % 4 == 0:
		$AudioStreamPlayer2D2.stream = beat1
	else:
		$AudioStreamPlayer2D2.stream = beat2
	$AudioStreamPlayer2D2.play()
	$editlightspopup/bpmfinder.modulate = $editlightspopup/ColorPickerButton.color
	if beat_tween:
		beat_tween.kill()
	var beat_interval = 60.0 / lightsbpm
	beat_tween = get_tree().create_tween()

	beat_tween.tween_property(
		$editlightspopup/bpmfinder,
		"modulate",
		Color.from_rgba8(255, 255, 255, 255),
		beat_interval
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

var tap_times = []
const MAX_TAPS = 6
func _on_bpmfinder_pressed() -> void:
	var now = Time.get_ticks_usec()
	tap_times.append(now)
	if tap_times.size() > MAX_TAPS:
		tap_times.pop_front()
	if tap_times.size() < 2:
		return
	var total_interval = 0.0
	for i in range(1, tap_times.size()):
		total_interval += (tap_times[i] - tap_times[i - 1])
	var avg_interval_sec = (total_interval / (tap_times.size() - 1)) / 1_000_000.0
	var bpm = snapped(60.0 / avg_interval_sec, 0.1)
	$editlightspopup/bpmfinder.text = str(bpm) + "bpm"
	lightsbpm = bpm
	$editlightspopup/BPM.value = lightsbpm

func _on_upload_pressed() -> void:
	if len(elements) == 0:
		$AudioStreamPlayer2D3.stream = load("res://audio/editordelete.mp3")
		$AudioStreamPlayer2D3.play()
		return
	save()
	$AudioStreamPlayer2D2.stream = load("res://audio/uploading.mp3")
	$AudioStreamPlayer2D2.play()
	$selectorbg/uploading.text = "uploading..."
	$selectorbg/uploading.modulate.a = 0.0
	$selectorbg/uploading.visible = true
	for i in range(13):
		$selectorbg/uploading.modulate.a += 0.08
		await get_tree().create_timer(0.01).timeout
	var url = "http://ctw.threepm.xyz/api/v1/uploadstage/" + stageid + ".ctw"
	var httpreq = HTTPRequest.new()
	add_child(httpreq)
	var bytes = load_from_file("user://customstages/" + stageid + ".ctw")
	var body = bytes.get_string_from_utf8()
	var headers = PackedStringArray([
	    "Content-Type: text/plain; charset=utf-8"
	])
	var err = httpreq.request(url, headers, HTTPClient.Method.METHOD_POST, body)
	if err != OK:
		print("Request failed to start: ", err)
		return
	var result = await httpreq.request_completed
	var response_code = result[1]
	var response_bytes : PackedByteArray = result[3]
	var response_text = response_bytes.get_string_from_utf8()
	if response_code != 200:
		print("HTTP Error: ", response_code)
		print("Server Response: ", response_text)
		$selectorbg/uploading.text = "failed.."
		$AudioStreamPlayer2D2.stream = load("res://audio/uploadfailed.mp3")
	else:
		print("Upload successful! Server Response: ", response_text)
		$selectorbg/uploading.text = "uploaded!"
		$AudioStreamPlayer2D2.stream = load("res://audio/uploaded.mp3")
	$AudioStreamPlayer2D2.play()
	await get_tree().create_timer(1).timeout
	for i in range(13):
		$selectorbg/uploading.modulate.a -= 0.08
		await get_tree().create_timer(0.01).timeout
	$selectorbg/uploading.modulate.a = 0.0
	$selectorbg/uploading.visible = false
