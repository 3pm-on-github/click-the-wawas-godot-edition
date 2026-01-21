extends Sprite2D

signal wawa_shot()
@export var whatami := "wawa"
	
var alreadypressed = false
func _ready() -> void:
	self.position = Vector2(randi_range(0,1834), 272)
	while true:
		var randtime = randf_range(0.5, 1.0)
		if not alreadypressed:
			var tween = get_tree().create_tween()
			tween.tween_property(self, "position", Vector2(randi_range(0,1834), 272), randtime).set_trans(Tween.TRANS_SINE)
			await get_tree().create_timer(randtime).timeout

func _process(delta: float) -> void:
	pass

var alreadyshot = false
func _on_shot() -> void:
	if not alreadyshot:
		alreadyshot = true
		emit_signal("wawa_shot")
		$AudioStreamPlayer2D.play()
		var img := Image.new()
		img = load("res://images/evilWawa.png").get_image()
		self.texture = ImageTexture.create_from_image(img)
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", Vector2(0.6, 0.1), 0.25).set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(1.0).timeout
		for i in range(6):
			self.visible = true
			await get_tree().create_timer(0.1).timeout
			self.visible = false
			await get_tree().create_timer(0.1).timeout
		self.queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.whatami == "bullet":
		_on_shot()
