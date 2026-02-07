extends TextureButton
func _ready() -> void:
	pass
func _process(_delta: float) -> void:
	pass
	
@export var elementid := 1
@export var flags := 1
signal remove_me(mrfresh)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("remove_me", self)
