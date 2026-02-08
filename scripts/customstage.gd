extends Node2D

func load_from_file(path):
	var content = FileAccess.get_file_as_bytes(path)
	return content
	
func loadcontent() -> Dictionary:
	var src: PackedByteArray = load_from_file(Global.customstagetotry)
	return JSON.parse_string(src.get_string_from_utf8())

func createelements():
	for element in loadedcontent.elements:
		if element.id == 0:
			var copy = $wawa.duplicate()
			copy.position.x = element.x
			copy.position.y = element.y
			copy.visible = true
			if element.flags == 1: # moving wawas
				copy.set_script(load("res://scripts/wawa5.gd"))
			elif element.flags == 2: # bouncing wawas
				copy.set_script(load("res://scripts/wawa6.gd"))
				if loadedcontent.lights_bpm != 0.0:
					copy.bpm = loadedcontent.lights_bpm
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
	DiscordRPC.state = "custom stage ("+loadedcontent.popup_text+")"
	DiscordRPC.refresh()
	createelements()
	for element in elements:
		element.visible = false
	$AudioStreamPlayer2D2.play()
	if loadedcontent.lights_bpm != 0:
		var lightstexture = GradientTexture1D.new()
		var lightsgradient = Gradient.new()
		lightsgradient.set_color(0.421, Color.from_rgba8(loadedcontent.lights_rgb[0], loadedcontent.lights_rgb[1], loadedcontent.lights_rgb[2], loadedcontent.lights_rgb[3]))
		lightsgradient.set_color(1, Color.from_rgba8(255, 255, 255, 0))
		lightstexture.set_gradient(lightsgradient)
		$lights/lightl1.texture = lightstexture
		$lights/lightl2.texture = lightstexture
		$lights/lightr1.texture = lightstexture
		$lights/lightr2.texture = lightstexture
		bpm = loadedcontent.lights_bpm
		startpos = loadedcontent.lights_startpos
		lights()
	for i in range(50):
		$blackbg.modulate.a -= 0.02
		await get_tree().create_timer(0.02).timeout
	$blackbg.visible = false

func lights():
	var toggle = false
	while playing:
		toggle = not toggle
		var beat_duration = 60.0 / bpm
		if toggle:
			$lights/lightl1.visible = true
			$lights/lightr1.visible = true
			$lights/lightl2.visible = false
			$lights/lightr2.visible = false
			$lights/lightl1.modulate.a = 1.0
			$lights/lightr1.modulate.a = 1.0
			var tween1 = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			tween1.tween_property($lights/lightl1, "modulate:a", 0.0, beat_duration)
			tween2.tween_property($lights/lightr1, "modulate:a", 0.0, beat_duration)
		else:
			$lights/lightl1.visible = false
			$lights/lightr1.visible = false
			$lights/lightl2.visible = true
			$lights/lightr2.visible = true
			$lights/lightl2.modulate.a = 1.0
			$lights/lightr2.modulate.a = 1.0
			var tween1 = get_tree().create_tween()
			var tween2 = get_tree().create_tween()
			tween1.tween_property($lights/lightl2, "modulate:a", 0.0, beat_duration)
			tween2.tween_property($lights/lightr2, "modulate:a", 0.0, beat_duration)
		await get_tree().create_timer(beat_duration).timeout

var elementskilled = 0
func _on_element_clicked() -> void:
	elementskilled+=1
	if elementskilled == len(elements):
		var calculatedtimetook = float(30-((loadedcontent.counter-counter) / loadedcontent.counter) * 30)
		#var starrating = snapped(1.0+(0.15-(calculatedtimetook / 100)), 0.01)
		var rating = 1.0
		if "rating" in loadedcontent:
			print("Boom")
			rating = loadedcontent.rating
		var starrating = snapped((rating+0.15)-calculatedtimetook/100, 0.01)
		print("user's star rating: ", starrating)
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/winscreen.tscn")

var elements = []
var playing = true
var counter = 30
func _on_ok_pressed() -> void:
	for element in elements:
		element.visible = true
	counter = int(loadedcontent.counter)+1
	$popup.visible = false
	$counter.visible = true
	$lights.visible = true
	for i in range(counter):
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
