extends Path3D

@export var camera_speed = 0.2
@export var tween_speed: float = 0.2

@onready var path_follow_3d: PathFollow3D = $PathFollow3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if path_follow_3d.progress_ratio + camera_speed < 1:
				create_tween().tween_property(path_follow_3d, "progress_ratio", path_follow_3d.progress_ratio + camera_speed, tween_speed)
			else:
				path_follow_3d.progress_ratio = 1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if path_follow_3d.progress_ratio - camera_speed > 0:
				create_tween().tween_property(path_follow_3d, "progress_ratio", path_follow_3d.progress_ratio - camera_speed, tween_speed)
				
			else:
				path_follow_3d.progress_ratio = 0
