class_name Enemy
extends CharacterBody3D

@export var speed = 2.5
@export var obstacle_avoid_distance = 2.0
@export var recovery_time: float = 1.0
@export var health: float = 1.0
@export var advancement: float = 0.0

@export var is_king: bool = false

@onready var turret = get_node("/root/Battlefield/Environement/Castle/EnemyTarget")
@onready var crown: Node3D = $Crown # Reference to the crown node

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var target_marker: MeshInstance3D = $TargetMarker
@onready var hp_bar: ProgressBar = $HPBar/SubViewport/ProgressBar
@onready var target_debug: Label = $HPBar/SubViewport/TargetDebug

@onready var audio_player_sand: AudioStreamPlayer3D = $SandAudioStreamPlayer

@export var force_magnitude: float = 30
@export var hover_height: float = 0.5
@export var hover_speed: float = 2.0
var hover_time: float = 0.0
var initial_y: float = 0.0

var current_target: Vector3
var targeted = false
var is_recovering = false
var is_executing_action = false

### begin hunger

var max_hunger = 1
var hunger = max_hunger
var hunger_depletion_rate = 0.1
var hunger_increase_rate = 0.2
var hunger_hp_depletion_rate = 0.01

### end hunger

### start cloak
@export var is_cloaked: bool = false
var _cloak_cooldown: float = 15
var _time_wo_cloak: float = _cloak_cooldown
var _time_in_cloak: float = 0
var _max_time_in_cloak: float = 4

func enable_cloak() -> void:
	if _time_wo_cloak >= _cloak_cooldown:
		is_cloaked = true
		_time_wo_cloak = 0
		speed = base_speed * 5

func disable_cloak() -> void:
	if is_cloaked:
		is_cloaked = false
		_time_wo_cloak = 0
		speed = base_speed
### end cloak

@onready var model: CSGBox3D = $CSGBox3D # Reference to the visual model

# @export var squash_amount: float = 0.2
# @export var squash_speed: float = 5.0
#var squash_time: float = 0.0

@onready var soldier_body: CSGCylinder3D = $SoldierBody
@onready var soldier_head: CSGSphere3D = $SoldierBody/SoldierHead

enum WeaponType {NONE, SANDALS, SHIELD, STAFF}

@export var base_speed = 2.5
@export var base_health = 1.0

var current_weapon = WeaponType.NONE
@onready var weapons = $SoldierBody/Weapons

@export var sandals_boost_interval = 2.0 # Time between speed boosts (increased cooldown)
@export var sandals_boost_duration = 1.0 # How long the boost lasts (shorter duration)
@export var sandals_boost_multiplier = 3.0 # How much faster during boost (more intense)
var time_since_last_boost = 0.0
var is_boosted = false

@onready var speed_particles: GPUParticles3D = $GPUParticles3D

func turret_targeted() -> void:
	targeted = true
	target_debug.text = "TARGETED!"
	target_debug.modulate = Color(1, 0.2, 0.2)
	
func turret_untargeted() -> void:
	targeted = false
	target_debug.text = "Not Targeted"
	target_debug.modulate = Color(0.7, 0.7, 0.7)

func is_dead() -> bool:
	return health <= 0.00001
	
func castle_health() -> float:
	var battlefield = get_parent()
	var castle_health = battlefield.castle_life / battlefield.base_castle_life
	return castle_health

func hurt(hurt_amount) -> void:
	# Reduce damage if we have shield
	if current_weapon == WeaponType.SHIELD:
		hurt_amount *= 0.5
	
	health -= hurt_amount
	hp_bar.value = health
	
	if is_dead():
		# Death animation
		audio_player_sand.play()
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", Vector3(0, 360, 0), 0.5)
		tween.parallel().tween_property(self, "position:y", position.y + 2, 0.25)
		tween.tween_property(self, "position:y", position.y - 10, 0.25)
		await tween.finished
		# Remove HP bar before freeing the enemy
		$HPBar.queue_free()
		queue_free()
	#else:
		#is_recovering = true
		#await get_tree().create_timer(recovery_time).timeout
		#is_recovering = false

func on_shot(force_direction) -> void:
	if is_cloaked and RandomNumberGenerator.new().randf_range(0, 1.0) > 0.5:
		return

	hurt(0.2)
	
	# Apply knockback to CharacterBody3D
	self.velocity = force_direction * force_magnitude * 2
	self.move_and_slide()

func _ready():
	if is_king:
		# Disable movement and actions for the king
		crown.visible = true # Make the crown visible
		hp_bar.visible = false # Hide the HP bar for the king
	else:
		crown.visible = false # Hide the crown for non-kings
		hp_bar.visible = true # Show the HP bar for non-kings

	# Add self to enemies group
	add_to_group("enemies")
	
	# Initialize base values first
	speed = 2.5
	health = 1.0 # For some reason, we need to set this here
	
	# Make sure to wait for the first physics frame so the NavigationServer can sync
	await get_tree().physics_frame
	
	# Configure the agent
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	print("Enemy ready at: ", global_position)
	print("Turret at: ", turret.global_position if turret else "NULL")
	
	hp_bar.value = health
	hp_bar.max_value = 1.0
	target_debug.text = "Not Targeted"
	target_debug.modulate = Color(0.7, 0.7, 0.7)
	
	# Connect the velocity computed signal
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	initial_y = position.y

func _physics_process(delta):
	if is_king:
		return # Skip processing for the king

	# heal
	time_wo_heal += delta
	
	# begin hunger
	if velocity.length() == 0:
		hunger -= delta * hunger_depletion_rate
		if hunger <= 0:
			hurt(hunger_hp_depletion_rate * delta)
	
	# end hunger
	# begin cloak
	if is_cloaked:
		_time_in_cloak += delta
		if _time_in_cloak > _max_time_in_cloak:
			disable_cloak()
	# end cloak

	# Check for nearby weapon pickups
	var weapons = get_tree().get_nodes_in_group("weapon_pickups")
	for weapon in weapons:
		if global_position.distance_to(weapon.global_position) < 1.0: # 1 unit radius for pickup
			pickup_weapon(weapon.weapon_type)
			print("Picked up weapon: ", weapon.weapon_type)
			# Queue the weapon pickup for deletion
			weapon.queue_free()
	
	# Handle weapon behaviors
	if current_weapon == WeaponType.SANDALS:
		time_since_last_boost += delta
		if time_since_last_boost >= sandals_boost_interval and not is_boosted:
			# Start speed boost
			speed = base_speed * sandals_boost_multiplier
			is_boosted = true
			time_since_last_boost = 0.0
			
			# Emit particles
			speed_particles.emitting = true
			
			# Create timer to end boost
			await get_tree().create_timer(sandals_boost_duration).timeout
			if current_weapon == WeaponType.SANDALS: # Check if we still have sandals
				speed = base_speed
				is_boosted = false
				speed_particles.emitting = false
	elif current_weapon == WeaponType.STAFF:
		heal_nearby_enemies()
	
	if not nav_agent.is_navigation_finished():
		# Update target marker position
		if current_target:
			target_marker.visible = true
			target_marker.global_position = current_target
			target_marker.global_position.y = 0.3 # Lift slightly above ground
		else:
			target_marker.visible = false
		
		# Get next path position and calculate velocity
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		var new_velocity = (next_path_position - global_position).normalized() * speed
		
		# Use avoidance velocity instead of direct velocity
		nav_agent.set_velocity(new_velocity)
	else:
		nav_agent.set_velocity(Vector3.ZERO)
		is_executing_action = false
		
func _process(delta):
	pass
	# Animate the soldier
	# squash_time += delta * squash_speed
	# var squash = sin(squash_time) * squash_amount
	
	# Squash and stretch effect
	# soldier_body.scale.y = 1.0 + squash
	# soldier_body.scale.x = 1.0 - squash * 0.5
	# soldier_body.scale.z = 1.0 - squash * 0.5
	
	# Make the head bob up and down slightly
	# soldier_head.position.y = 0.7 + squash * 0.3
	
	# Rotate to face movement direction
	# if velocity.length() > 0.1:
	#	var look_dir = -velocity.normalized()
	#	look_dir.y = 0
	#	soldier_body.rotation.y = lerp_angle(soldier_body.rotation.y, atan2(look_dir.x, look_dir.z), delta * 10.0)

# Add this function to handle the actual movement
func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()

func move_towards_goal(target_pos: Vector3, is_special_action: bool = false) -> bool:
	if is_executing_action:
		return false
		
	if not target_pos:
		return false
	
	current_target = target_pos
	nav_agent.target_position = target_pos
	is_executing_action = is_special_action # Only set busy if it's a special action
	return true

func hide_behind_nearest_obstacle() -> bool:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		print("No obstacles found!")
		return false
		
	var nearest = find_nearest_object(obstacles)
	if nearest:
		var hide_pos = calculate_hide_position(nearest)
		print("Hiding at position: ", hide_pos)
		return move_towards_goal(hide_pos, true)
	return false

func hide_behind_nearest_obstacle_forward() -> bool:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		return false
		
	var forward_obstacles = []
	# Get distance from turret to self
	var distance_to_turret = global_position.distance_to(turret.global_position)
	
	for obstacle in obstacles:
		var obstacle_distance = obstacle.global_position.distance_to(turret.global_position)
		# Only consider obstacles closer to turret than self
		if obstacle_distance < distance_to_turret:
			forward_obstacles.append(obstacle)
	
	if forward_obstacles.is_empty():
		print("No obstacles found closer to turret than self")
		return false
		
	var nearest = find_nearest_object(forward_obstacles)
	if nearest:
		var hide_pos = calculate_hide_position(nearest)
		print("Hiding behind forward obstacle at: ", hide_pos)
		return move_towards_goal(hide_pos, true)
	return false

func circumvent_obstacle() -> bool:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		return false
		
	# Find obstacles between us and turret
	var blocking_obstacles = []
	var to_turret = turret.global_position - global_position
	var distance_to_turret = to_turret.length()
	to_turret = to_turret.normalized()
	
	for obstacle in obstacles:
		var to_obstacle = obstacle.global_position - global_position
		var obstacle_distance = to_obstacle.length()
		
		# Check if obstacle is between us and turret
		if obstacle_distance < distance_to_turret:
			var dot = to_obstacle.normalized().dot(to_turret)
			if dot > 0.7: # Obstacle is roughly in the direction of turret
				blocking_obstacles.append(obstacle)
	
	if blocking_obstacles.is_empty():
		print("No obstacles found between self and turret")
		return false
	
	# Find nearest blocking obstacle
	var target_obstacle = find_nearest_object(blocking_obstacles)
	if not target_obstacle:
		return false
		
	# Get the pre-placed circumvent point
	var circumvent_point = target_obstacle.get_node("CircumventPoint")
	if not circumvent_point:
		print("No circumvent point found for obstacle!")
		return false
		
	print("Moving to circumvent position: ", circumvent_point.global_position)
	return move_towards_goal(circumvent_point.global_position, true)

func find_nearest_object(objects: Array):
	var nearest = null
	var nearest_distance = INF
	
	for obj in objects:
		var distance = global_position.distance_to(obj.global_position)
		if distance < nearest_distance:
			nearest = obj
			nearest_distance = distance
	
	return nearest

func calculate_hide_position(obstacle: Node3D) -> Vector3:
	var obstacle_pos = obstacle.global_position
	var turret_pos = turret.global_position
	
	# Calculate direction from turret to obstacle
	var hide_direction = (obstacle_pos - turret_pos).normalized()
	
	# Position behind obstacle relative to turret
	var hide_position = obstacle_pos + hide_direction * obstacle_avoid_distance
	
	# Adjust height to match ground
	hide_position.y = global_position.y
	
	return hide_position

func distance_to_nearest_obstacle() -> float:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		return INF
		
	var nearest = find_nearest_object(obstacles)
	if nearest:
		return global_position.distance_to(nearest.global_position)
	return INF
	
func time_to_nearest_obstacle() -> float:
	var dist = distance_to_nearest_obstacle()
	return dist / speed

func distance_to_nearest_obstacle_forward() -> float:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		return INF
		
	var forward_obstacles = []
	var distance_to_turret = global_position.distance_to(turret.global_position)
	
	for obstacle in obstacles:
		var obstacle_distance = obstacle.global_position.distance_to(turret.global_position)
		if obstacle_distance < distance_to_turret:
			forward_obstacles.append(obstacle)
	
	if forward_obstacles.is_empty():
		return INF
		
	var nearest = find_nearest_object(forward_obstacles)
	if nearest:
		return global_position.distance_to(nearest.global_position)
	return INF
	
func time_to_nearest_obstacle_forward() -> float:
	var dist = distance_to_nearest_obstacle_forward()
	return dist / speed

func get_turret_position() -> Vector3:
	var pos = turret.global_position
	pos.y = global_position.y # Keep same height as enemy
	return pos

func is_busy() -> bool:
	# Only consider the enemy busy if they're executing a special action
	# Don't block on navigation since that's part of normal movement
	return is_executing_action

func move_towards_turret() -> bool:
	var target = get_turret_position()
	return move_towards_goal(target, false)

func pickup_weapon(type: WeaponType) -> void:
	# Reset stats to base
	speed = base_speed
	health = base_health
	
	# Hide all weapons first
	for weapon in weapons.get_children():
		weapon.visible = false
	
	# Hide healing radius by default
	$HealingRadius.visible = false
	
	current_weapon = type
	match type:
		WeaponType.SANDALS:
			weapons.get_node("Sandals").visible = true
			time_since_last_boost = sandals_boost_interval # Start ready for boost
			speed_particles.emitting = false # Make sure particles are off
		WeaponType.SHIELD:
			weapons.get_node("Shield").visible = true
			speed *= 0.6 # Much slower
			health *= 2.0 # Double health
		WeaponType.STAFF:
			weapons.get_node("Staff").visible = true
			$HealingRadius.visible = true # Show healing radius when staff is equipped
			# Start healing timer
			$HealTimer.start()

func has_staff() -> bool:
	return current_weapon == WeaponType.STAFF

func has_sandals() -> bool:
	return current_weapon == WeaponType.SANDALS

func has_shield() -> bool:
	return current_weapon == WeaponType.SHIELD

func is_wounded():
	return health < base_health

func distance_to_wounded_allies() -> float:
	# Find wounded ally to heal
	var allies = get_tree().get_nodes_in_group("enemies")
	var wounded_allies = []
	for ally in allies:
		if ally != self and ally.is_wounded():
			wounded_allies.append(ally)
	if wounded_allies.is_empty():
		return INF
	var ally = find_nearest_object(wounded_allies)
	if ally:
		return ally.global_position.distance_to(global_position)
	return INF
	

func time_to_wounded_allies() -> float:
	return distance_to_wounded_allies() / speed
	
func move_to_wounded_allies() -> bool:
	# Find wounded ally to heal
	var allies = get_tree().get_nodes_in_group("enemies")
	var wounded_allies = []
	for ally in allies:
		if ally != self and ally.is_wounded():
			wounded_allies.append(ally)
	if wounded_allies.is_empty():
		return false
	var ally = find_nearest_object(wounded_allies)
	if ally:
		return move_towards_goal(ally.global_position)
	return false
	
func time_to_next_heal() -> float:
	return clamp(time_wo_heal - heal_cooldown, 0, heal_cooldown)


var heal_radius = 5.0
var heal_amount = 0.25
var heal_cooldown = 10
var time_wo_heal = heal_cooldown
func heal_nearby_enemies() -> void:
	if current_weapon != WeaponType.STAFF:
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) <= heal_radius:
			enemy.heal(heal_amount)

func heal(amount: float) -> void:
	var target_health = min(health + amount, base_health * (2.0 if current_weapon == WeaponType.SHIELD else 1.0))
	# Create a tween for smooth healing animation
	var tween = create_tween()
	tween.tween_property(self, "health", target_health, 0.5) # 0.5 seconds duration
	tween.tween_property(hp_bar, "value", target_health, 0.5)

func find_nearest_weapon(type: Enemy.WeaponType) -> Node3D:
	var weapons = get_tree().get_nodes_in_group("weapon_pickups")
	var nearest = null
	var nearest_distance = INF
	
	for weapon in weapons:
		if weapon.weapon_type == type:
			var distance = global_position.distance_to(weapon.global_position)
			if distance < nearest_distance:
				nearest = weapon
				nearest_distance = distance

	return nearest

func time_to_closest_pickup(weapon_type: WeaponType) -> float:
	var nearest = find_nearest_weapon(weapon_type)
	if nearest:
		return nearest.global_position.distance_to(global_position) / speed
	return INF
	
func move_to_closest_pickup(weapon_type: WeaponType) -> bool:
	var nearest = find_nearest_weapon(weapon_type)
	if nearest:
		return move_towards_goal(nearest.global_position, false)
	return false
