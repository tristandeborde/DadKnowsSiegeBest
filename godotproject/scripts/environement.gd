extends Node3D

@onready var camera_intro = get_tree().get_root().get_node("Intro/Path3D/PathFollow3D/CameraIntro")
@onready var camera_battle = get_tree().get_root().get_node("BattlePath/PathFollow3D/CameraTop")

@onready var spawnpoints = $EnemySpawner/SpawnPoints

var z_spawn = -38.304
var z_chateau = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if "CameraTop" not in String(camera.get_path()):
		return 
		
	var min_z_enemies = 99999
	for node in get_children():
		if node is Enemy:
			if node.position.z < min_z_enemies:
				min_z_enemies = node.position.z
	
	var percent = (min_z_enemies - z_spawn) / (z_chateau - z_spawn)
	
	if min_z_enemies== 99999:
		percent = 0
	
	if percent < 0:
		percent = 0
	camera.get_parent().progress_ratio = percent
	
	
	
	
