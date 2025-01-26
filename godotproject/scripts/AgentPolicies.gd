extends Node

@onready var llm_instance: LLMController = $LLMController

var current_policy: int = 0
var last_ast_actions = []

signal new_agent_policy

func _ready():
	pass
	#_initialize_llm()

func _physics_process(_delta):
	if current_policy > 0:
		execute_current_policy()

func _initialize_llm():
	llm_instance.call_mistral_api(
		"hVnbwh7aEMLNuGSnnDRljvgUOZAbKXZj",
		"mistral-large-latest",
		""
	)

# Remove _ready and _process since we'll handle updates differently
func get_ast_actions():
	return last_ast_actions
	
func set_ast_actions(ast_actions):
	print("Set ast_actions")
	print(ast_actions)
	last_ast_actions = ast_actions

# Remove static from these functions
func can_execute_action(enemy: Enemy) -> bool:
	var can_execute = not enemy.is_busy()
	return can_execute

func execute_policy_1(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		enemy.move_towards_turret()

func execute_policy_2(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		enemy.hide_behind_nearest_obstacle()

func execute_policy_3(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		enemy.hide_behind_nearest_obstacle_forward()

func execute_policy_4(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		enemy.circumvent_obstacle()

func execute_policy_5(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		if enemy.targeted:
			enemy.hide_behind_nearest_obstacle()
		else:
			enemy.move_towards_turret()


func execute_policy_6(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		if enemy.current_weapon == Enemy.WeaponType.SANDALS:
			enemy.move_towards_turret()
		else:
			var sandals = enemy.find_nearest_weapon(Enemy.WeaponType.SANDALS)
			if sandals:
				enemy.move_towards_goal(sandals.global_position, false)

# Policy 7: Get shield and become tank
func execute_policy_7(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		if enemy.current_weapon == Enemy.WeaponType.SHIELD:
			enemy.move_towards_turret()
		else:
			var shield = enemy.find_nearest_weapon(Enemy.WeaponType.SHIELD)
			if shield:
				enemy.move_towards_goal(shield.global_position, false)

# Policy 8: Get staff and become healer
func execute_policy_8(enemy: Enemy) -> void:
	if can_execute_action(enemy):
		if enemy.current_weapon == Enemy.WeaponType.STAFF:
			# Find wounded ally to heal
			var allies = get_tree().get_nodes_in_group("enemies")
			if enemy.time_to_wounded_allies() < 1:
				enemy.heal_nearby_enemies()
			elif enemy.time_to_wounded_allies() < 3:
				enemy.move_to_wounded_allies()
			else:
				enemy.move_towards_turret()
			
			var wounded_nearby = false
			
			for ally in allies:
				if ally != enemy and ally.health < ally.base_health and ally.global_position.distance_to(enemy.global_position) < 10:
					wounded_nearby = true
					enemy.move_towards_goal(ally.global_position, false)
					break
			
			if not wounded_nearby:
				enemy.move_towards_turret()
		else:
			var staff = enemy.find_nearest_weapon(Enemy.WeaponType.STAFF)
			if staff:
				enemy.move_towards_goal(staff.global_position, false)

func eval_ast(enemy: Enemy, ast):
	var op = ast[0]
	
	if op == "or":
		return eval_ast(enemy, ast[1]) or eval_ast(enemy, ast[2])
	if op == "and":
		return eval_ast(enemy, ast[1]) and eval_ast(enemy, ast[2])
	if op == "not":
		return not eval_ast(enemy, ast[1])
	if op == "<":
		return eval_ast(enemy, ast[1]) < eval_ast(enemy, ast[2])
	if op == ">":
		return eval_ast(enemy, ast[1]) > eval_ast(enemy, ast[2])
	if op == "<=":
		return eval_ast(enemy, ast[1]) <= eval_ast(enemy, ast[2])
	if op == ">=":
		return eval_ast(enemy, ast[1]) >= eval_ast(enemy, ast[2])
	if op == "=<":
		return eval_ast(enemy, ast[1]) <= eval_ast(enemy, ast[2])
	if op == "=>":
		return eval_ast(enemy, ast[1]) >= eval_ast(enemy, ast[2])
	if op == "=":
		return eval_ast(enemy, ast[1]) == eval_ast(enemy, ast[2])
	if op == "==":
		return eval_ast(enemy, ast[1]) == eval_ast(enemy, ast[2])
	if op == "!=":
		return eval_ast(enemy, ast[1]) != eval_ast(enemy, ast[2])
	if op == "=/=":
		return eval_ast(enemy, ast[1]) != eval_ast(enemy, ast[2])
	if op in ['NUMBER', 'BOOLEAN']:
		return ast[1]
	if op == "FUNC":
		if ast[1] == "time_to_closest_pickup":
			var weapon = ast[2]
			if weapon == "STAFF":
				enemy.time_to_closest_pickup(Enemy.WeaponType.STAFF)
			elif weapon == "SANDALS":
				enemy.time_to_closest_pickup(Enemy.WeaponType.SANDALS)
			elif weapon == "SHIELD":
				enemy.time_to_closest_pickup(Enemy.WeaponType.SHIELD)
				
	if op == 'VAR':
		var var_name = ast[1]
		if var_name == "true":
			return true
		if var_name == "health":
			return enemy.health
		if var_name == "is_targeted":
			return enemy.targeted
		if var_name == "advancement":
			return enemy.advancement
		if var_name == "distance_to_nearest_obstacle":
			return enemy.distance_to_nearest_obstacle()
		if var_name == "distance_to_nearest_obstacle_forward":
			return enemy.distance_to_nearest_obstacle_forward()
		print("Var name doesn't exist: " + str(var_name))
		return false


func execute_policy_llm(enemy: Enemy, ast_actions) -> void:
	CameraHandler.camera_battle.current = true
	CameraHandler.camera_intro.current = false
	
	for ast_action in ast_actions:
		var ast = ast_action[0]
		var action = ast_action[1][0] # TODO don't always take the first action. But needs a bigger rework!!
		
		if eval_ast(enemy, ast):
			if action == "hide_behind_nearest_obstacle":
				enemy.hide_behind_nearest_obstacle()
			elif action == "hide_behind_nearest_obstacle_forward":
				enemy.hide_behind_nearest_obstacle_forward()
			elif action == "move_towards_goal":
				enemy.move_towards_turret()
			elif action == "move_to_wounded_allies":
				enemy.move_to_wounded_allies()
			elif action.begins_with("move_to_closest_pickup"):
				var weapon = action.substr(24, action.length() - 26)
				if weapon == "STAFF":
					enemy.move_to_closest_pickup(Enemy.WeaponType.STAFF)
				elif weapon == "SANDALS":
					enemy.move_to_closest_pickup(Enemy.WeaponType.SANDALS)
				elif weapon == "SHIELD":
					enemy.move_to_closest_pickup(Enemy.WeaponType.SHIELD)
				else:
					print("Action doesn't exist: ", action)
			else:
				print("Action doesn't exist: ", action)

func execute_current_policy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		match current_policy:
			1: execute_policy_1(enemy)
			2: execute_policy_2(enemy)
			3: execute_policy_3(enemy)
			4: execute_policy_4(enemy)
			5: execute_policy_5(enemy)
			6: execute_policy_6(enemy)
			7: execute_policy_7(enemy)
			8: execute_policy_8(enemy)
			9: execute_policy_llm(enemy, get_ast_actions())

func set_policy(policy_number: int):
	if current_policy == policy_number:
		current_policy = 0 # Turn off current policy
		print("Policy disabled")
	else:
		current_policy = policy_number
		print("Activated policy ", policy_number)
		# Spawn agents when policy is selected
		var battlefield = get_parent()
		if battlefield.has_method("spawn_pending_agents"):
			battlefield.spawn_pending_agents()
