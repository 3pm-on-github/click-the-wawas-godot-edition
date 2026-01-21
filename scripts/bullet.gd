extends Sprite2D

@export var speed := 600.0
@export var whatami := "bullet"

func _process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += direction * speed * delta

func _ready():
	$AudioStreamPlayer2D.play()
