extends MeshInstance

const OFF_MATERIAL := preload("res://raycast_node_example/off_material.tres")
const ON_MATERIAL := preload("res://raycast_node_example/on_material.tres")

onready var raycast : RayCast = $RayCast

func _physics_process(delta):
	if raycast.is_colliding():
		material_override = ON_MATERIAL
	else:
		material_override = OFF_MATERIAL
