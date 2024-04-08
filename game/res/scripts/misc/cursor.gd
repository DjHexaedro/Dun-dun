# Used by the light that follows the mouse
extends Node2D


var old_position
var follow_mouse

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	follow_mouse = not Utils.device_is_phone()
	visible = not Utils.device_is_phone()
	set_process(true)

func _process(_delta):
	if follow_mouse:
		old_position = position
		global_position = get_global_mouse_position()
		visible = Input.get_mouse_mode() != Input.MOUSE_MODE_HIDDEN
