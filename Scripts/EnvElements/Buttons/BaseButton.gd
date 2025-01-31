class_name Base_Button
extends Interactable

signal pressed
signal released
signal switched(on)

export(NodePath) var toggle_path

var pressed := false

func _ready() -> void:
	continuous = false
	
	if interact_txt == "":
		interact_txt = "Press"

func press():
	emit_signal("pressed")
	set_pressed(true)
	
func release():
	emit_signal("released")
	set_pressed(false)
	
func set_pressed(value):
	pressed = value
	
	if pressed:
		_on_pressed()
	else:
		_on_released()
	
	emit_signal("switched", pressed)
	_on_switched()
	
func _on_pressed() -> void:
	pass
	
func _on_released() -> void:
	pass
	
func _on_switched() -> void:
	pass

func can_interact():
	return not oneshot or not pressed
