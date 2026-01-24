extends Button

signal got_pressed(element)

func _ready() -> void:
	connect("pressed", Callable(self, "_emit_got_pressed"))

func _emit_got_pressed() -> void:
	emit_signal("got_pressed", self)
