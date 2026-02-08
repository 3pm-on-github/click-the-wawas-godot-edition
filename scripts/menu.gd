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

var bpm = 140
var stopthewawabeat = false
var insolomenu = false
var owsound = false
var pause = false
var pausecount = 0
func wawabeat():
	while true:
		if stopthewawabeat:
			break
		if pause:
			pausecount += 1
			await get_tree().create_timer(60.0/bpm).timeout
			if pausecount == round(1/(60.0/bpm)):
				pausecount = 0
				pause = false
			continue
		var tween1 = get_tree().create_tween()
		if insolomenu:
			tween1.tween_property($mainmenu/Wawa, "scale", Vector2(2.0, 2.0), 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween1.tween_property($mainmenu/Wawa, "scale", Vector2(1.5, 1.5), (60.0/bpm)-0.1)
		else:
			tween1.tween_property($mainmenu/Wawa, "scale", Vector2(6.0, 6.0), 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween1.tween_property($mainmenu/Wawa, "scale", Vector2(5.0, 5.0), (60.0/bpm)-0.1)
		if owsound:
			$AudioStreamPlayer2D2.stream = load("res://audio/ow.wav")
			$AudioStreamPlayer2D2.play()
		await get_tree().create_timer(60.0/bpm).timeout

func titlemove():
	var titletween = get_tree().create_tween()
	titletween.tween_property($mainmenu/title, "position:y", $mainmenu/title.position.y + 20, 1.5)\
		.set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.5).timeout
	while true:
		if movement:
			titletween = get_tree().create_tween()
			titletween.tween_property($mainmenu/title, "position:y", $mainmenu/title.position.y - 40, 3.0).set_trans(Tween.TRANS_SINE)
			await get_tree().create_timer(3.0).timeout
			titletween = get_tree().create_tween()
			titletween.tween_property($mainmenu/title, "position:y", $mainmenu/title.position.y + 40, 3.0).set_trans(Tween.TRANS_SINE)
			await get_tree().create_timer(3.0).timeout

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
	$mainmenu/Wawa.position = Vector2(2542, 525)
	$mainmenu/title.position = Vector2(-940.0, 64.0)
	$mainmenu/playbtn.position = Vector2(-403, 443)
	$mainmenu/solobtn.visible = false
	$mainmenu/multibtn.visible = false
	$mainmenu/multibtn.position = Vector2(431.0, 443.0)
	$mainmenu/editorbtn.position = Vector2(-403, 582)
	$onlinestagesmenu/InfoPanel.modulate.a = 0.0
	$onlinestagesmenu/InfoPanel.visible = false
	$mainmenu/configbtn.position = Vector2(-403, 724)
	$mainmenu/exitbtn.position = Vector2(-403, 867)
	$onlinestagesmenu/title.position = Vector2(1097.0, 11.0)
	$onlinestagesmenu/goback.position = Vector2(1445.0, 979.0)
	$wawahitbox.visible = true
	$solomenu.visible = false
	$onlinestagesmenu/ScrollContainer.position = Vector2(0, 0)
	$solomenu.modulate.a = 0.0
	$onlinestagesmenu.visible = false
	$onlinestagesmenu.modulate.a = 0.0
	$configmenu.visible = false
	$configmenu.modulate.a = 0.0
	loadedconfig = loadconfig()
	$configmenu/onlineapiurl/LineEdit.text = loadedconfig.api_url
	$configmenu/onlineusername/LineEdit.text = loadedconfig.username
	$configmenu/onlinepassword/LineEdit.text = loadedconfig.password
	titlemove()
	
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
		await get_tree().create_timer(0.005).timeout
	$AudioStreamPlayer2D.play(0.117)
	wawabeat()
	var tween = get_tree().create_tween()
	var wawatween = get_tree().create_tween()
	$mainmenu/Wawa.rotation_degrees = -45
	tween.tween_property($mainmenu/Wawa, "position", Vector2(1413, 525), 1.0).set_trans(Tween.TRANS_SINE)
	wawatween.tween_property($mainmenu/Wawa, "rotation_degrees", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
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

func _process(_delta: float) -> void:
	$onlinestagesmenu/title/wawabanner/Label.position.x -= 1.0
	if $onlinestagesmenu/title/wawabanner/Label.position.x == -89.0:
		$onlinestagesmenu/title/wawabanner/Label.position.x = 0.0

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
	$mainmenu/solobtn.visible = false
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
	#for i in range(40):
	#	$mainmenu.modulate.a -= 0.025
	#	await get_tree().create_timer(0.005).timeout
	
	# main menu animation
	var tween = get_tree().create_tween()
	var tween1 = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	var tween3 = get_tree().create_tween()
	var tween4 = get_tree().create_tween()
	var wawatween = get_tree().create_tween()
	var wawatween2 = get_tree().create_tween()
	insolomenu = true
	pause = true
	wawatween.tween_property($mainmenu/Wawa, "position", Vector2(1777, 888), 1.0).set_trans(Tween.TRANS_SINE)
	wawatween2.tween_property($mainmenu/Wawa, "scale", Vector2(2.0, 2.0), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($mainmenu/title, "position", Vector2(-940.0, 64.0), 1.0).set_trans(Tween.TRANS_SINE)
	tween1.tween_property($mainmenu/playbtn, "position", Vector2(-403, 443), 0.5).set_trans(Tween.TRANS_SINE)
	tween2.tween_property($mainmenu/editorbtn, "position", Vector2(-403, 582), 0.5).set_trans(Tween.TRANS_SINE)
	tween3.tween_property($mainmenu/configbtn, "position", Vector2(-403, 724), 0.5).set_trans(Tween.TRANS_SINE)
	tween4.tween_property($mainmenu/exitbtn, "position", Vector2(-403, 867), 0.5).set_trans(Tween.TRANS_SINE)
	
	#$mainmenu.visible = false
	#await get_tree().create_timer(0.25).timeout
	$solomenu.visible = true
	for i in range(40):
		$mainmenu/solobtn.modulate.a -= 0.025
		$mainmenu/multibtn.modulate.a -= 0.025
		$solomenu.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout
	$mainmenu/solobtn.visible = false
	$mainmenu/multibtn.visible = false
	$wawahitbox.position = Vector2(1605.0, 676.0)
	$wawahitbox.size = Vector2(312, 403)
	$wawahitbox.visible = true

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
		copy.get_node("Rating").text = str(stageinfo.ranking)+"★"
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
	stopthewawabeat=true
	var filepath = await get_onlinestage(onlineelementfilepaths[element])
	var loadedcontent = loadcontent(filepath)
	var stageinfo = await get_onlinestage_info(filepath.trim_prefix("user://customstages/"))
	$AudioStreamPlayer2D.stop()
	$AudioStreamPlayer2D.stream = AudioStreamMP3.load_from_buffer(Marshalls.base64_to_raw(loadedcontent.music_encodeddata))
	$AudioStreamPlayer2D.play(loadedcontent.lights_startpos/1000)
	$onlinestagesmenu/InfoPanel/Title.text = loadedcontent.popup_text
	$onlinestagesmenu/InfoPanel/Author.text = "by "+stageinfo.author
	$onlinestagesmenu/InfoPanel/Rating.text = str(stageinfo.ranking)+"★"
	bpm = loadedcontent.lights_bpm
	stopthewawabeat=false
	wawabeat()
	
	# loading animation
	$AudioStreamPlayer2D2.stream = load("res://audio/editortry.ogg")
	$AudioStreamPlayer2D2.play()
	$onlinestagesmenu/InfoPanel.visible = true
	var tween1 = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	var tween3 = get_tree().create_tween()
	var tween4 = get_tree().create_tween()
	var tween5 = get_tree().create_tween()
	tween1.tween_property($onlinestagesmenu/ScrollContainer, "position", Vector2(-820, 0), 1.0).set_trans(Tween.TRANS_SINE)
	tween2.tween_property($onlinestagesmenu/title, "position", Vector2(1920, 11), 1.0).set_trans(Tween.TRANS_SINE)
	tween3.tween_property($onlinestagesmenu/goback, "position", Vector2(1445, 1080), 1.0).set_trans(Tween.TRANS_SINE)
	tween4.tween_property($mainmenu/Wawa, "position", Vector2(1018, 388), 1.0).set_trans(Tween.TRANS_SINE)
	tween5.tween_property($onlinestagesmenu/InfoPanel, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	$wawahitbox.visible = false
	await get_tree().create_timer(5.0).timeout
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
		$mainmenu/Wawa.modulate.a -= 0.025
		await get_tree().create_timer(0.005).timeout
	$onlinestagesmenu.visible = false
	await get_tree().create_timer(0.25).timeout
	$solomenu.visible = true
	for i in range(40):
		$solomenu.modulate.a += 0.025
		$mainmenu/Wawa.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout

func _on_goback_solomenu_pressed() -> void:
	$AudioStreamPlayer2D2.stream = load("res://audio/click.wav")
	$AudioStreamPlayer2D2.play()
	$wawahitbox.visible = false
	dothewawabossfight = true
	
	# main menu animation
	
	var tween = get_tree().create_tween()
	var tween1 = get_tree().create_tween()
	var tween2 = get_tree().create_tween()
	var tween3 = get_tree().create_tween()
	var tween4 = get_tree().create_tween()
	var wawatween = get_tree().create_tween()
	var wawatween2 = get_tree().create_tween()
	insolomenu = false
	pause = true
	wawatween.tween_property($mainmenu/Wawa, "position", Vector2(1413, 525), 1.0).set_trans(Tween.TRANS_SINE)
	wawatween2.tween_property($mainmenu/Wawa, "scale", Vector2(5.0, 5.0), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property($mainmenu/title, "position", Vector2(64.0, 64.0), 1.0).set_trans(Tween.TRANS_SINE)
	tween1.tween_property($mainmenu/playbtn, "position", Vector2(47.0, 443), 0.5).set_trans(Tween.TRANS_SINE)
	tween2.tween_property($mainmenu/editorbtn, "position", Vector2(47.0, 582), 0.5).set_trans(Tween.TRANS_SINE)
	tween3.tween_property($mainmenu/configbtn, "position", Vector2(47.0, 724), 0.5).set_trans(Tween.TRANS_SINE)
	tween4.tween_property($mainmenu/exitbtn, "position", Vector2(47.0, 867), 0.5).set_trans(Tween.TRANS_SINE)
	
	$mainmenu/solobtn.visible = true
	$mainmenu/multibtn.visible = true
	for i in range(40):
		$solomenu.modulate.a -= 0.025
		$mainmenu/solobtn.modulate.a += 0.025
		$mainmenu/multibtn.modulate.a += 0.025
		await get_tree().create_timer(0.005).timeout
	$solomenu.visible = false
	$wawahitbox.position = Vector2(998.0, 43.0)
	$wawahitbox.size = Vector2(898, 974)
	$wawahitbox.visible = true
	
	#$mainmenu.visible = true
	#for i in range(40):
	#	$mainmenu.modulate.a += 0.025
	#	await get_tree().create_timer(0.005).timeout

func saveconfig(api_url, username, password):
	var out := {}
	out['version'] = 1
	out['api_url'] = api_url
	out['username'] = username
	if password != loadedconfig.password:
		out['password'] = password.sha256_text()
	else:
		out['password'] = loadedconfig.password
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
		$configmenu/onlinepassword/LineEdit.text
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
	$mainmenu/solobtn.visible = true

func _on_wawahitbox_mouse_entered() -> void:
	owsound = true

func _on_wawahitbox_mouse_exited() -> void:
	owsound = false
