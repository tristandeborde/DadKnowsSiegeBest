extends Node3D
class_name Battlefield

@export var base_castle_life = 1 # we need 1 enemy to win the game
var castle_life = base_castle_life

signal game_won

var current_level = 0
var agents_per_level = {
	1: 5,
	2: 15,
	3: 40
}
var pending_agents = 0

@onready var enemy_spawner = $Environement/EnemySpawner
@onready var level_ui = $LevelUI
@onready var turrets = [
	$Environement/Castle/Turret,
	$Environement/Castle/Turret2,
	$Environement/Castle/Turret3,
	$Environement/Castle/Turret4
]

@onready var camera_intro = $Intro/Path3D/PathFollow3D/CameraIntro
@onready var camera_battle = $BattlePath/PathFollow3D/CameraTop
	

func _ready() -> void:
	$Environement/Castle/AnimationPlayer.connect("animation_finished", _on_Castle_AnimationPlayer_animation_finished)
	
	# Initially hide all turrets except the first one
	for i in range(1, turrets.size()):
		turrets[i].visible = false
		turrets[i].process_mode = Node.PROCESS_MODE_DISABLED
	
	# Remove automatic level 1 start
	# start_level(1)

func start_level(level: int):
	# Clear any existing enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	
	current_level = level
	
	# Unlock appropriate number of turrets
	var num_turrets = mini(level, turrets.size())
	for i in range(turrets.size()):
		turrets[i].visible = i < num_turrets
		turrets[i].process_mode = Node.PROCESS_MODE_INHERIT if i < num_turrets else Node.PROCESS_MODE_DISABLED
	
	level_ui.announce_level(level, num_turrets)
	
	# Store the number of agents to spawn later
	pending_agents = agents_per_level[level]
	
func spawn_pending_agents():
	$Gong.play()
	
	if pending_agents > 0:
		for i in range(pending_agents):
			enemy_spawner.spawn_enemy()
		pending_agents = 0
	

func check_level_complete() -> bool:
	return get_tree().get_nodes_in_group("enemies").size() == 0

func _process(_delta):
	# Remove automatic level progression
	# if check_level_complete() and current_level < agents_per_level.size():
	# 	current_level += 1
	# 	start_level(current_level)
	pass

func _on_enemy_target_body_entered(body: Node3D) -> void:
	if body is Enemy:
		var enemy: Enemy = body
		enemy.hurt(100)
		castle_life -= 1
		print("ouch! life:", castle_life)
		
	if castle_life <= 0:
		game_won.emit()
		$Environement/Castle/AnimationPlayer.play("CastleBroken")

func _on_Castle_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "CastleBroken":
		CameraHandler.camera_battle.current = false
		CameraHandler.camera_intro.current = true
		$PromptUI.visible = true
		$Environement/Castle/AnimationPlayer.play("RESET")

func _on_intro_intro_finished() -> void:
	pass
	#$BattlePath/PathFollow3D/CameraTop.make_current()
