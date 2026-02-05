extends TextureButton
func _process(_delta: float) -> void:
	pass

signal wawa_clicked()
	
var alreadypressed = false
func _ready() -> void:
	self.position = Vector2(randi_range(0,1834), randi_range(0,984))
	while true:
		var randtime = randf_range(1.0, 5.0)
		if not alreadypressed:
			var tween = get_tree().create_tween()
			tween.tween_property(self, "position", Vector2(randi_range(0,1834), randi_range(0,984)), randtime).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(randtime).timeout

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
