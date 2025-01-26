extends Control

@onready var label = $CenterContainer/Label

func announce_level(level: int, num_turrets: int):
	# Reset any existing animations
	label.visible_ratio = 0
	label.modulate.a = 1
	label.text = "LEVEL %d\nFacing %d %s" % [
		level,
		num_turrets,
		"turret" if num_turrets == 1 else "turrets"
	]
	
	# Create text reveal animation (1.5x slower)
	var reveal_tween = create_tween()
	reveal_tween.tween_property(label, "visible_ratio", 1.0, 1.5)
	reveal_tween.tween_interval(1.5)
	
	# Fade out animation (1.5x slower)
	var fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, 1.5).set_delay(3.0)
