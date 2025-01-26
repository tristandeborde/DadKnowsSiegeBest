extends Node3D

const OFF_MATERIAL := preload("res://Assets/Materials/Black.tres")
const ON_MATERIAL := preload("res://Assets/Materials/Red.tres")

@export var mouse_sensitivity: float = 0.1
@export var force_magnitude: float = 30

@onready var raycast: RayCast3D = $RayCast3D
@onready var model = $TurretModel
@onready var animation = $AnimationPlayer
# @onready var camera = $Camera3D
@onready var cannonSoundPlayer = $CannonStreamPlayer3D


var smoke_particle_scene = preload("res://Assets/Particles/CanonSmoke.tscn")
var impact_particle_scene = preload("res://Assets/Particles/ImpactParticle.tscn")


var target: Enemy

var mouse_captured = false
# Aimbot vars
var aimbot = true
var min_time_between_shots = 2
var time_between_shots = min_time_between_shots
var rotation_speed = 0.2
var intelligent_aimbot = true # TODO: stick to current target if it's not hidden


func _cmp_enemy_distance(e1: Enemy, e2: Enemy):
	var d_e1 = (e1.position - position).length_squared()
	var d_e2 = (e2.position - position).length_squared()
	return (d_e1 - d_e2) < 0

func wrap_angle(angle):
	# Ensures the angle is between -PI and PI
	while angle > PI:
		angle -= TAU
	while angle < -PI:
		angle += TAU
	return angle

func perform_raycast(start_point: Vector3, end_point: Vector3) -> Dictionary:
	# Access the physics space state
	var space_state = get_world_3d().direct_space_state

	# Create a PhysicsRayQueryParameters3D object
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = start_point
	ray_query.to = end_point
	ray_query.exclude = [] # Optionally exclude objects, e.g., [source]
	ray_query.collision_mask = 0xFFFFFFFF # Default to all layers

	# Perform the raycast
	return space_state.intersect_ray(ray_query)
	
func _rotate_towards_enemy(enemy: Enemy, delta):
	var turret_position = global_position
	var enemy_position = enemy.global_position

	# Calculate the direction vector
	var direction = (enemy_position - turret_position).normalized()

	# Get the current forward direction of the turret
	var forward = -global_transform.basis.z.normalized()

	# Calculate the angle between the forward vector and the enemy direction
	var angle_to_target = acos(forward.dot(direction))

	# Calculate the rotation axis using the cross product
	var rotation_axis = forward.cross(direction).normalized()

	# Limit the rotation to the maximum allowed rotation speed
	var clamped_angle = min(angle_to_target, rotation_speed * delta)

	# Apply the rotation if needed
	if angle_to_target > 0.01: # Prevent jittering
		var rotation_quat = Quaternion(rotation_axis, clamped_angle)
		global_transform.basis = Basis(rotation_quat) * global_transform.basis
	
func _physics_process(delta):
	# Aimbot aiming logic
	if aimbot:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if len(enemies) > 0:
			enemies.sort_custom(_cmp_enemy_distance)
			# Try to find enemy that's alive and not hidden
			var found_target = false
			if intelligent_aimbot:
				for enemy in enemies:
					if not enemy.is_dead() and perform_raycast(position, enemy.position).get("collider", null) is Enemy:
						_rotate_towards_enemy(enemy, delta)
						# look_at(enemy.position) -> if we want instant lockon
						found_target = true
						break
						
			if not found_target:
				# Find closest enemy that's alive
				for enemy in enemies:
					if not enemy.is_dead():
						_rotate_towards_enemy(enemy, delta)
						found_target = true
						break
			if not found_target:
				_rotate_towards_enemy(enemies[0], delta)
				found_target = true
					
			
	if target and not is_instance_valid(target):
		target = null
	
	# Set enemy into 'targeted' state
	if raycast.is_colliding() and raycast.get_collider() is Enemy:
		var new_target = raycast.get_collider()
		if target:
			target.turret_untargeted()
		
		target = new_target
		target.turret_targeted()
		
		model.material_override = ON_MATERIAL
	else:
		if target:
			target.turret_untargeted()
		target = null
		
		model.material_override = OFF_MATERIAL
		
		
	# Aimbot shooting logic
	time_between_shots += delta
	if aimbot and target:
		if time_between_shots >= min_time_between_shots:
			shoot()
			time_between_shots = 0
	
	
func _ready():
	# Start with mouse free for debugging
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _input(event):
	#if Input.is_key_pressed(KEY_A):
	#	aimbot = not aimbot

	#if Input.is_key_pressed(KEY_E):
	#	intelligent_aimbot = not intelligent_aimbot
	
	# Check for mouse motion to rotate the camera
	if event is InputEventMouseMotion and not aimbot:
		rotate_camera(event.relative)

	# Check for left-click to perform a raycast
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and not aimbot:
		shoot()
		
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
	
	# Right click to capture mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
	
	# Only rotate camera if mouse is captured
	# if mouse_captured: # TODO: is this ok ?
	# 	if event is InputEventMouseMotion and not aimbot:
	# 		rotate_camera(event.relative)

func rotate_camera(mouse_delta: Vector2):
	# Clamp horizontal rotation (Y-axis)
	var new_y_rotation = rotation_degrees.y + (-mouse_delta.x * mouse_sensitivity)
	rotation_degrees.y = clamp(new_y_rotation, -89, 89)
	
	# Clamp vertical rotation (X-axis)
	var vertical_rotation = deg_to_rad(-mouse_delta.y * mouse_sensitivity)
	var new_x_rotation = rotation_degrees.x + rad_to_deg(vertical_rotation)
	rotation_degrees.x = clamp(new_x_rotation, -89, 10)

func shoot():
	cannonSoundPlayer.play()
	
	var collision_point = raycast.get_collision_point()
	
	if animation.is_playing():
		animation.stop()
		
	var smoke_particle_instance = smoke_particle_scene.instantiate()
	smoke_particle_instance.position = $TurretModel/smoke.position
	add_child(smoke_particle_instance)
	smoke_particle_instance.emitting = true
	
	var impact_particle_instance = impact_particle_scene.instantiate()
	get_tree().root.add_child(impact_particle_instance)
	impact_particle_instance.global_position = collision_point
	impact_particle_instance.emitting = true
	
	# $Camera3D/Shaker.shake()
	animation.play("GunShooting")

	if target:
		var force_direction = (target.global_transform.origin - global_transform.origin).normalized()
		target.on_shot(force_direction)
		
		# # Apply knockback to CharacterBody3D
		# if target is CharacterBody3D:
		# 	target.velocity = force_direction * force_magnitude
		# 	target.move_and_slide()

			
	await smoke_particle_instance.finished
	await impact_particle_instance.finished
	
	impact_particle_instance.queue_free()
	smoke_particle_instance.queue_free()
