extends TextureButton

signal wawa_clicked()

var alreadypressed = false
func _process(delta: float) -> void:
	self.rotation_degrees += 1

func _ready() -> void:
	self.pivot_offset = self.size * 0.5
	
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
