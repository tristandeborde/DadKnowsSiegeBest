extends Node3D

@export var weapon_type: Enemy.WeaponType

const ROTATION_SPEED = 2 * PI / 3.0 # One full rotation (2π) every 3 seconds

func _ready():
	add_to_group("weapon_pickups")
	
	# Hide all weapon models first
	$Sandals.visible = false
	$Shield.visible = false
	$Staff.visible = false
	
	# Show only the correct weapon model
	match weapon_type:
		Enemy.WeaponType.SANDALS:
			$Sandals.visible = true
			$Label3D.text = "Speed"
		Enemy.WeaponType.SHIELD:
			$Shield.visible = true
			$Label3D.text = "Shield"
		Enemy.WeaponType.STAFF:
			$Staff.visible = true
			$Label3D.text = "Healing"

func _process(delta):
	# Rotate around Y axis
	rotate_y(ROTATION_SPEED * delta)
