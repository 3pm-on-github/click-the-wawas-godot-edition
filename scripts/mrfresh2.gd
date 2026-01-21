extends TextureButton
func _ready() -> void:
	pass
func _process(delta: float) -> void:
	pass

signal mrfresh_clicked()

var clicks = 0
var alreadypressed = false
func _on_pressed() -> void:
	if clicks < 3:
		clicks += 1
		$AudioStreamPlayer2D.play()
		self.position = Vector2(randi_range(0, 1920), randi_range(0, 1080))
	elif not alreadypressed:
		alreadypressed = true
		emit_signal("mrfresh_clicked")
		$AudioStreamPlayer2D.stream = load("res://audio/meowrgh.mp3")
		$AudioStreamPlayer2D.play()
		self.visible = false
