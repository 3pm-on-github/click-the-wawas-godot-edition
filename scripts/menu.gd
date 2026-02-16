extends Node2D

@onready var audioblur := AudioServer.get_bus_effect(
	AudioServer.get_bus_index("Master"), 2
) as AudioEffectLowPassFilter

func get_file_list(path: String) -> Array:
	var files := []
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				files.append(path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Cannot open folder: " + path)
	return files

func load_and_return_popuptext(path):
	var src: PackedByteArray = FileAccess.get_file_as_bytes(path)
	return JSON.parse_string(src.get_string_from_utf8()).popup_text

func loadconfig():
	var src: PackedByteArray = FileAccess.get_file_as_bytes("user://config.json")
	if src.get_string_from_utf8() == "": return
	return JSON.parse_string(src.get_string_from_utf8())

var bpm = 170
var stopthewawabeat = false
var owsound = false
func wawabeat():
	while true:
		if stopthewawabeat:
			break
		var tween1 = get_tree().create_tween()
		tween1.tween_property($mainmenu/Wawa, "scale", Vector2(6.0, 6.0), 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween1.tween_property($mainmenu/Wawa, "scale", Vector2(5.0, 5.0), (60.0/bpm)-0.1)
		if owsound:
			$AudioStreamPlayer2D2.stream = load("res://audio/ow.wav")
			$AudioStreamPlayer2D2.play()
		await get_tree().create_timer(60.0/bpm).timeout

var movement = true
var elementfilepaths = {}
var onlineelementfilepaths = {}
var loadedconfig = {}
func _ready() -> void:
	DirAccess.make_dir_absolute("user://customstages")
	$bg.modulate.a = 0.0
	$blackbg.visible = false
	$blackbg.modulate.a = 0.0
	$mainmenu.visible = true
	$mainmenu/Wawa.pivot_offset = $mainmenu/Wawa.size * 0.5
	$mainmenu/Wawa.modulate.a = 0.0
	$mainmenu/playbtn.position = Vector2(-403, 443)
	$mainmenu/solobtn.visible = false
	$mainmenu/multibtn.visible = false
	$mainmenu/multibtn.position = Vector2(431.0, 443.0)
	$mainmenu/editorbtn.position = Vector2(-403, 582)
	$mainmenu/Changelog.visible = false
	$mainmenu/Changelog.modulate.a = 0.0
	$configmenu/Credits.visible = false
	$configmenu/Credits.modulate.a = 0.0
	$mainmenu/configbtn.position = Vector2(-403, 724)
	$mainmenu/exitbtn.position = Vector2(-403, 867)
	$onlinestagesmenu/title.position = Vector2(1097.0, 11.0)
	$onlinestagesmenu/goback.position = Vector2(1396.0, 963.0)
	$mainmenu/title.modulate.a = 0.0
	$mainmenu/playbtn.modulate.a = 0.0
	$mainmenu/editorbtn.modulate.a = 0.0
	$mainmenu/configbtn.modulate.a = 0.0
	$mainmenu/exitbtn.modulate.a = 0.0
	$wawahitbox.visible = true
	$solomenu.visible = false
	$onlinestagesmenu/ScrollContainer.position = Vector2(0, 0)
	$solomenu.modulate.a = 0.0
	$onlinestagesmenu.visible = false
	$onlinestagesmenu.modulate.a = 0.0
	$configmenu.visible = false
	$configmenu.modulate.a = 0.0
	loadedconfig = loadconfig()
	if loadedconfig:
		$configmenu/onlineapiurl/LineEdit.text = loadedconfig.api_url
		$configmenu/onlineusername/LineEdit.text = loadedconfig.username
		$configmenu/onlinepassword/LineEdit.text = loadedconfig.password
	
	var lastpos = $solomenu/onlinecustomstagesbtn.position.y
	# get custom stages
	for file in get_file_list("user://customstages"):
		var copy: Button = $solomenu/customstagebtn.duplicate(1)
		copy.text = load_and_return_popuptext(file)
		copy.position.y = lastpos + 90
		copy.visible = true
		copy.set_script($solomenu/customstagebtn.get_script())
		copy.got_pressed.connect(_on_customstagebtn_pressed)
		copy.get_node("listenbtn").set_script($solomenu/customstagebtn.get_script())
		copy.get_node("listenbtn").got_pressed.connect(_on_customstagelistenbtn_pressed)
		if len(copy.text) > 12:
			copy.get_node("listenbtn").position.x = 112+7.5*(len(copy.text)-12)+5
		elementfilepaths[copy] = file
		elementfilepaths[copy.get_node("listenbtn")] = file
		lastpos = copy.position.y
		$solomenu/customstagebtn.get_parent().add_child(copy)
	
	DiscordRPC.state = "in the menu"
	DiscordRPC.refresh()
	
	for i in range(25):
		$bg.modulate.a += 0.04
		$mainmenu/playbtn.modulate.a += 0.04
		$mainmenu/editorbtn.modulate.a += 0.04
		$mainmenu/configbtn.modulate.a += 0.04
		$mainmenu/exitbtn.modulate.a += 0.04
		$mainmenu/Wawa.modulate.a += 0.04
		$mainmenu/title.modulate.a += 0.04
		await get_tree().create_timer(0.005).timeout
	$AudioStreamPlayer2D.stream = load("res://audio/menu-loop-"+str(randi_range(1, 2))+".wav")
	wawabeat()
	await get_tree().create_timer(0.02).timeout
	$AudioStreamPlayer2D.play()

func _process(_delta: float) -> void:
	$onlinestagesmenu/title/wawabanner/Label.position.x -= 1.0
	if $onlinestagesmenu/title/wawabanner/Label.position.x == -89.0:
		$onlinestagesmenu/title/wawabanner/Label.position.x = 0.0
	var mouse_pos = get_global_mouse_position()
	$mainmenu/playbtn.position = Vector2((mouse_pos.x/50)+47, (mouse_pos.y/50)+443)
	$mainmenu/solobtn.position = Vector2((mouse_pos.x/50)+431, (mouse_pos.y/50)+443)
	$mainmenu/multibtn.position = Vector2((mouse_pos.x/50)+431, (mouse_pos.y/50)+582)
	$mainmenu/editorbtn.position = Vector2((mouse_pos.x/50)+47, (mouse_pos.y/50)+582)
	$mainmenu/configbtn.position = Vector2((mouse_pos.x/50)+47, (mouse_pos.y/50)+724)
	$mainmenu/exitbtn.position = Vector2((mouse_pos.x/50)+47, (mouse_pos.y/50)+867)
	$mainmenu/Wawa.position = Vector2(1313-((1920-mouse_pos.x)/50), (mouse_pos.y/50)+425)
	$mainmenu/title.position = Vector2((mouse_pos.x/50)+64, (mouse_pos.y/50)+64)

var playtoggled = false
func _on_playbtn_pressed() -> void:
	playtoggled = not playtoggled
	if playtoggled:
		$mainmenu/solobtn.modulate.a = 0.0
		$mainmenu/multibtn.modulate.a = 0.0
		$mainmenu/solobtn.visible = true
		$mainmenu/multibtn.visible = true
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		for i in range(25):
			$mainmenu/solobtn.modulate.a += 0.04
			$mainmenu/multibtn.modulate.a += 0.04
			await get_tree().create_timer(0.005).timeout
	else:
		$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
		$AudioStreamPlayer2D2.play()
		for i in range(25):
			$mainmenu/solobtn.modulate.a -= 0.04
			$mainmenu/multibtn.modulate.a -= 0.04
			await get_tree().create_timer(0.005).timeout
		$mainmenu/solobtn.visible = false
		$mainmenu/multibtn.visible = false

func _on_playbtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()
	
func _on_editorbtn_mouse_entered() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/hovering.wav")
	$AudioStreamPlayer2D2.play()
	
func _on_configbtn_mouse_entered() -> void:
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
	
func _on_configbtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$wawahitbox.visible = false
	for i in range(40):
		$mainmenu.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$mainmenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$configmenu.visible = true
	for i in range(40):
		$configmenu.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

var clicks = 0
var dothewawabossfight = true
func _on_wawahitbox_pressed() -> void:
	if dothewawabossfight:
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
	dothewawabossfight = false
	
	$solomenu.visible = true
	for i in range(20):
		$mainmenu.modulate.a -= 0.05
		$solomenu.modulate.a += 0.05
		await get_tree().create_timer(0.005).timeout
	$mainmenu.visible = false
	$wawahitbox.position = Vector2(1605.0, 676.0)
	$wawahitbox.size = Vector2(312, 403)
	$wawahitbox.visible = false

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

func _on_customstagebtn_pressed(element) -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	$blackbg.visible = true
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 1
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	Global.customstagetotry = elementfilepaths[element]
	get_tree().change_scene_to_file("res://scenes/customstage.tscn")

func _on_customstagelistenbtn_pressed(element) -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	stopthewawabeat=true
	var filepath = elementfilepaths[element]
	$AudioStreamPlayer2D.stop()
	var loadedcontent = loadcontent(filepath)
	await get_tree().create_timer(60.0/bpm).timeout
	$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_buffer(Marshalls.base64_to_raw(loadedcontent.music_encodeddata))
	$AudioStreamPlayer2D.play(loadedcontent.lights_startpos/1000)
	DiscordRPC.state = "listening to "+loadedcontent.popup_text+" in the menu"
	DiscordRPC.refresh()
	bpm = loadedcontent.lights_bpm
	stopthewawabeat=false
	wawabeat()

func _on_onlinecustomstagesbtn_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	
	# get online custom stages
	var httpreq = HTTPRequest.new()
	add_child(httpreq)
	httpreq.request_completed.connect(_on_request_completed)
	var err = httpreq.request(
		loadedconfig.api_url+"/liststages",
		PackedStringArray(),
		HTTPClient.Method.METHOD_GET
	)
	if err != OK:
		print("Request failed to start: ", err)
		
	for i in range(40):
		$solomenu.modulate.a -= 0.025
		$mainmenu/Wawa.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$solomenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$onlinestagesmenu.visible = true
	for i in range(40):
		$onlinestagesmenu.modulate.a += 0.025
		$mainmenu/Wawa.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

func get_onlinestage_popuptext(stageid: String) -> String:
	var url = loadedconfig.api_url+"/stagepopuptext/" + stageid
	var httpreq = HTTPRequest.new()
	add_child(httpreq)
	var err = httpreq.request(url, PackedStringArray(), HTTPClient.Method.METHOD_GET)
	if err != OK:
		print("Request failed to start: ", err)
		return ""
	var result = await httpreq.request_completed
	var response_code = result[1]
	var body = result[3]
	if response_code != 200:
		print("HTTP Error (b): ", response_code)
		return ""
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("JSON Parse Error")
		return ""
	return json.get_data()
	
func get_onlinestage_info(stageid: String) -> Dictionary:
	var url = loadedconfig.api_url+"/stageinfo/" + stageid
	var httpreq = HTTPRequest.new()
	add_child(httpreq)
	var err = httpreq.request(url, PackedStringArray(), HTTPClient.Method.METHOD_GET)
	if err != OK:
		print("Request failed to start: ", err)
		return {}
	var result = await httpreq.request_completed
	var response_code = result[1]
	var body = result[3]
	if response_code != 200:
		print("HTTP Error (idontevenknowanymore): ", response_code)
		return {}
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("JSON Parse Error")
		return {}
	return json.get_data()

func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		print("HTTP Error (a): ", response_code)
		return
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		print("JSON Parse Error")
		return
	var response = json.get_data()
	var lastpos = $onlinestagesmenu/ScrollContainer/Control/onlinecustomstage.position.y - 255
	for file in response:
		var copy: ColorRect = $onlinestagesmenu/ScrollContainer/Control/onlinecustomstage.duplicate(1)
		var popup_text = await get_onlinestage_popuptext(file)
		var stageinfo = await get_onlinestage_info(file)
		copy.get_node("Title").text = popup_text
		copy.get_node("Author").text = "by "+stageinfo.author
		if "ranking" in stageinfo:
			copy.get_node("Rating").text = str(stageinfo.ranking)+"★"
		else:
			copy.get_node("Rating").text = "1.00★"
		copy.position.y = lastpos + 255
		copy.visible = true
		if len(popup_text)>20:copy.get_node("Title").label_settings.font_size=64-1.6*(len(popup_text)-20)
		copy.get_node("playbtn").set_script($onlinestagesmenu/ScrollContainer/Control/onlinecustomstage/playbtn.get_script())
		copy.get_node("playbtn").got_pressed.connect(onlinecustomstageplaybtn_pressed)
		copy.get_node("downloadbtn").set_script($onlinestagesmenu/ScrollContainer/Control/onlinecustomstage/downloadbtn.get_script())
		copy.get_node("downloadbtn").got_pressed.connect(onlinecustomstagedownloadbtn_pressed)
		onlineelementfilepaths[copy.get_node("playbtn")] = file
		onlineelementfilepaths[copy.get_node("downloadbtn")] = file
		lastpos = copy.position.y
		$onlinestagesmenu/ScrollContainer/Control/onlinecustomstage.get_parent().add_child(copy)

func save_to_file(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(content)
	file.close()

func get_onlinestage(stageid: String) -> String:
	var url = loadedconfig.api_url+"/stage/" + stageid
	var httpreq = HTTPRequest.new()
	add_child(httpreq)
	var err = httpreq.request(url, PackedStringArray(), HTTPClient.Method.METHOD_GET)
	if err != OK:
		print("Request failed to start: ", err)
	var result = await httpreq.request_completed
	var response_code = result[1]
	if response_code != 200:
		print("HTTP Error (c): ", response_code)
	var body = result[3]
	save_to_file(body, "user://customstages/" + stageid)
	return "user://customstages/" + stageid

func onlinecustomstageplaybtn_pressed(element) -> void:
	$onlinestagesmenu/title.text = "downloading"
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	await get_onlinestage(onlineelementfilepaths[element])
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 2, true)
	$blackbg.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(audioblur, "cutoff_hz", 400, 0.5)
	for i in range(80):
		$AudioStreamPlayer2D.volume_db -= 0.25
		$blackbg.modulate.a += 0.0125
		await get_tree().create_timer(0.0125).timeout
	Global.customstagetotry = "user://customstages/" + onlineelementfilepaths[element]
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 2, false)
	audioblur.cutoff_hz = 20500
	get_tree().change_scene_to_file("res://scenes/customstage.tscn")
	
func load_from_file(path):
	var content = FileAccess.get_file_as_bytes(path)
	return content
	
func loadcontent(path) -> Dictionary:
	var src: PackedByteArray = load_from_file(path)
	return JSON.parse_string(src.get_string_from_utf8())
	
func onlinecustomstagedownloadbtn_pressed(element) -> void:
	$onlinestagesmenu/title.text = "downloading"
	$AudioStreamPlayer2D2.stream = load("res://audio/clickfast.ogg")
	$AudioStreamPlayer2D2.play()
	stopthewawabeat=true
	var filepath = await get_onlinestage(onlineelementfilepaths[element])
	$onlinestagesmenu/title.text = "online stages"
	$AudioStreamPlayer2D.stop()
	var loadedcontent = loadcontent(filepath)
	$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_buffer(Marshalls.base64_to_raw(loadedcontent.music_encodeddata))
	$AudioStreamPlayer2D.play(loadedcontent.lights_startpos/1000)
	bpm = loadedcontent.lights_bpm
	stopthewawabeat=false
	wawabeat()

func _on_goback_onlinestagesmenu_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	for i in range(40):
		$onlinestagesmenu.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$onlinestagesmenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$solomenu.visible = true
	for i in range(40):
		$solomenu.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

func _on_goback_solomenu_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$wawahitbox.visible = false
	dothewawabossfight = true
	
	$mainmenu.visible = true
	for i in range(20):
		$solomenu.modulate.a -= 0.05
		$mainmenu.modulate.a += 0.05
		await get_tree().create_timer(0.005).timeout
	$solomenu.visible = false
	$wawahitbox.position = Vector2(998.0, 43.0)
	$wawahitbox.size = Vector2(898, 974)
	$wawahitbox.visible = true

func saveconfig(api_url, username, password, skipintro):
	var out := {}
	out['version'] = 1
	out['api_url'] = api_url
	out['username'] = username
	if password != loadedconfig.password:
		out['password'] = password.sha256_text()
	else:
		out['password'] = loadedconfig.password
	out['skipintro'] = skipintro
	var file = FileAccess.open("user://config.json", FileAccess.WRITE)
	var data: PackedByteArray = PackedByteArray()
	for character in JSON.stringify(out):
		data.append(ord(character))
	file.store_buffer(data)
	file.close()
	loadedconfig = loadconfig()
	
func _on_configmenu_goback_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	saveconfig(
		$configmenu/onlineapiurl/LineEdit.text,
		$configmenu/onlineusername/LineEdit.text,
		$configmenu/onlinepassword/LineEdit.text,
		skipintrotoggle
	)
	for i in range(40):
		$configmenu.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$configmenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$mainmenu.visible = true
	$wawahitbox.visible = true
	for i in range(40):
		$mainmenu.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

func _on_wawahitbox_mouse_entered() -> void:
	owsound = true

func _on_wawahitbox_mouse_exited() -> void:
	owsound = false

var skipintrotoggle = false
func _on_skipintro_check_button_pressed() -> void:
	skipintrotoggle = not skipintrotoggle

var changelogtoggle = false
func _on_changelogbtn_pressed() -> void:
	changelogtoggle = not changelogtoggle
	if changelogtoggle:
		$mainmenu/Changelog.visible = true
		for i in range(40):
			$mainmenu/Changelog.modulate.a += 0.025
			await get_tree().create_timer(0.005).timeout
	else:
		for i in range(40):
			$mainmenu/Changelog.modulate.a -= 0.025
			await get_tree().create_timer(0.005).timeout
		$mainmenu/Changelog.visible = false

func _on_audio_finished():
	$AudioStreamPlayer2D.play()

var creditstoggle = false
func _on_credits_button_pressed() -> void:
	creditstoggle = not creditstoggle
	if creditstoggle:
		$configmenu/Credits.visible = true
		for i in range(40):
			$configmenu/Credits.modulate.a += 0.025
			await get_tree().create_timer(0.005).timeout
	else:
		for i in range(40):
			$configmenu/Credits.modulate.a -= 0.025
			await get_tree().create_timer(0.005).timeout
		$configmenu/Credits.visible = false
