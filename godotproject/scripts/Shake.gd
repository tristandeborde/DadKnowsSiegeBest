extends Node

@export var randomStrength: float = 4.0
@export var shakeFade: float = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
var original_transform: Transform3D

func _ready():
	# Save the original transform of the parent node
	if get_parent():
		original_transform = get_parent().transform
	else:
		push_error("Camera3D has no parent node. Cannot apply shake to parent.")

func shake():
	shake_strength = randomStrength / 30

func _process(delta):
	if shake_strength > 0.0:
		shake_strength = lerp(shake_strength, 0.0, shakeFade * delta)

		# Apply random offset for the parent's position
		if get_parent():
			var offset = random_offset()
			var parent = get_parent()
			parent.transform = original_transform.translated(offset)

func random_offset() -> Vector3:
	# Only apply shake to the x and y axes, z-axis remains unaffected
	return Vector3(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength),
		0.0
	)
