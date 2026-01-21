extends Node2D

@onready var spectrum := AudioServer.get_bus_effect_instance(
	AudioServer.get_bus_index("Master"), 0
) as AudioEffectSpectrumAnalyzerInstance

func _ready() -> void:
	$blackbg.visible = true
	$blackbg.modulate.a = 1
	roll()
	for i in range(25):
		$blackbg.modulate.a -= 0.04
		await get_tree().create_timer(0.04).timeout
	$blackbg.visible = false

var dothescale = false
func roll() -> void:
	dothescale = false
	$AudioStreamPlayer2D.stop()
	var randomimages = ["big meal.png", "milly.jpg", "question mark.png", "the fog is coming.png", "wawa.png", "weird al yankovic the ultimate video collection.jpg", "mods get em.png", "from the screen to the ring to the pen to the king.png", "god's yoinkiest sploinkier.png", "DAMNNN!!!!!!!!!!!!!!!!!!.jpg", "despair.jpg", "1 4.jpg", "Ventinlator.png", "cornball.png", "tomatonator.png", "freezing cold cheeto eye of rah.png", "bros schmoovin.png"]
	var randomaudio = ["#jedagjedug.mp3", "cartoon, daniel levi - on & on (silly disco flip).mp3", "discopled.mp3", "doodle.mp3", "laufey - from the start (silly funk remix).mp3", "linga guli guli.mp3", "loveli lori - love for you (pluggnb + disco flip).mp3", "luckyy.mp3", "lunar, Pt. 2.mp3", "plumbum.mp3", "disentanglement dynamo.mp3"]
	var randommusic = randomaudio.pick_random()
	var random = randomimages.pick_random()
	DiscordRPC.state = "gallery ("+randommusic+")"
	DiscordRPC.refresh()
	$TextureRect.texture = load("res://images/randomimages/"+random)
	$Label2.text = random
	$Label3.text = randommusic
	$AudioStreamPlayer2D.stop()
	dothescale = true
	$AudioStreamPlayer2D.stream = load("res://audio/randomaudio/"+randommusic)
	$AudioStreamPlayer2D.play()

func _process(delta: float) -> void:
	if !dothescale:
		return
	var energy = spectrum.get_magnitude_for_frequency_range(20, 150).length()
	var scale_value = clamp(1.0 + energy * 4.0, 1.0, 1.6)
	$TextureRect.scale = Vector2.ONE * scale_value

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_button_pressed() -> void:
	roll()
