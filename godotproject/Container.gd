extends CenterContainer

func _ready():
	# Ensure the container size matches the display on start
	size = get_viewport_rect().size
	# Enable notifications for resizing
	set_process(true)

func _notification(what):
	size = get_viewport_rect().size
