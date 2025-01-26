extends Node3D

@onready var viewport_container = $".."

func _ready():
	viewport_container.position = Vector2(-50, -5) # Center the bar

func _process(_delta):
	# Make HP bar always face camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Update position to follow parent in world space
		var parent_pos = get_parent().get_parent().global_position
		global_position = parent_pos + Vector3(0, 1.5, 0)
		
		# Make UI face camera
		look_at(camera.global_position, Vector3.UP)
		rotation.x = 0 # Keep vertical
		
		# Update UI container position in screen space
		var screen_pos = camera.unproject_position(global_position)
		viewport_container.position = screen_pos - viewport_container.size / 2
