extends TextureButton
func _process(delta: float) -> void:
	pass

signal wawa_clicked()
@export var bpm = 120.0

var alreadypressed = false
func _ready() -> void:
	self.pivot_offset = self.size * 0.5
	self.rotation = 0
	var toggle = false
	var originalpos = self.position
	while not alreadypressed:
		var tween = get_tree().create_tween()
		var tween2 = get_tree().create_tween()
		toggle = not toggle
		var duration = 60.0 / bpm
		if toggle:
			tween.tween_property(self, "position", originalpos + Vector2(0, -50), duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween2.tween_property(self, "rotation_degrees", -15, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(self, "position", originalpos + Vector2(0, -50), duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween2.tween_property(self, "rotation_degrees", 15, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(duration/2).timeout
		var tween_back = get_tree().create_tween()
		tween_back.tween_property(self, "position", originalpos + Vector2(0, 50), duration).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(duration/2).timeout
	
func _on_pressed() -> void:
	if not alreadypressed:
		alreadypressed = true
		emit_signal("wawa_clicked")
		$AudioStreamPlayer2D.play()
		var img := Image.new()
		img = load("res://images/evilWawa.png").get_image()
		self.texture_normal = ImageTexture.create_from_image(img)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(0.6, 0.1), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(1.0).timeout
		for i in range(6):
			self.visible = true
			await get_tree().create_timer(0.1).timeout
			self.visible = false
			await get_tree().create_timer(0.1).timeout
