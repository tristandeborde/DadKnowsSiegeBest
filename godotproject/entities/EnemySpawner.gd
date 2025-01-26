extends Node3D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 10

func spawn_enemy():
	var spawn_points = $SpawnPoints.get_children()
	if spawn_points.is_empty():
		push_error("No spawn points found!")
		return
		
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_point.global_position
	get_parent().add_child(enemy)
