class_name LLMController
extends Node

@export var api_key: String
@export var model: String
@export var system_prompt: String
@export var user_prompt: String

var last_ast_actions = []
var _llm_orders = null
var _llm_orders_commment = null
#extends Node3D

class Parser:
	var tokens = []
	var current_token = null
	var binary_operators = ["<", ">", "<=", ">=", "=<", "=>", "=", "==", "!=", "=/="]

	func _init(token_list):
		tokens = token_list
		next_token()

	func next_token():
		if tokens.size() > 0:
			current_token = tokens.pop_front()
		else:
			current_token = null

	func parse():
		return expression()

	func expression():
		var node = term()
		while current_token == "or":
			next_token()
			node = ["or", node, term()]
		return node

	func term():
		var node = factor()
		while current_token == "and":
			next_token()
			node = ["and", node, factor()]
		return node

	func factor():
		if current_token == "not":
			next_token()
			var node = ["not", factor()]
			return node
		else:
			var node = primary()
			if current_token in binary_operators:
				var op = current_token
				next_token()
				node = [op, node, primary()]
			return node

	func primary():
		var regex = RegEx.new()
		regex.compile("^[a-zA-Z_][a-zA-Z0-9_]*$")
		
		if current_token == "(":
			next_token()
			var node = expression()
			if current_token == ")":
				next_token()
			else:
				push_error("Expected closing parenthesis")
			return node
		elif regex.search(current_token) != null:
			var identifier = current_token
			next_token()
			if current_token == "(":
				next_token()
				var args = argument_list()
				if current_token == ")":
					next_token()
					var node = ["FUNC", identifier, args]
					return node
				else:
					push_error("Expected closing parenthesis for function call")
			else:
				var node = ["VAR", identifier]
				return node
		else:
			var node = value()
			return node

	func argument_list():
		var args = []
		if current_token != ")":
			args.append(expression())
			while current_token == ",":
				next_token()
				args.append(expression())
		return args

	func value():
		var regex = RegEx.new()
		regex.compile("^\\d+(.\\d+)?$")
		if regex.search(current_token) != null:
			var node = ["NUMBER", float(current_token)]
			next_token()
			return node
		elif current_token in ["True", "False"]:
			var node = ["BOOLEAN", current_token == "True"]
			next_token()
			return node
		else:
			var node = ["VAR", current_token]
			next_token()
			return node

func add_space_around_special_chars(input_string: String) -> String:
	var result = ""
	for i in range(input_string.length()):
		var current_char = input_string[i]
		if current_char in ['<', '>', '=', '!', '(', ')', '/']:
			# Check the character before the special character
			if i > 0:
				var prev_char = input_string[i - 1]
				if (prev_char >= '0' and prev_char <= '9') or (prev_char >= 'a' and prev_char <= 'z') or (prev_char >= 'A' and prev_char <= 'Z'):
					result += " "
			result += current_char
			# Check the character after the special character
			if i < input_string.length() - 1:
				var next_char = input_string[i + 1]
				if (next_char >= '0' and next_char <= '9') or (next_char >= 'a' and next_char <= 'z') or (next_char >= 'A' and next_char <= 'Z'):
					result += " "
		else:
			result += current_char
	return result


func parse_msg(msg):
	var regex = RegEx.new()
	var ast_actions = []
	regex.compile(r"^\s*if\s?(.*):\s*return\s*\[(.*)\]\s*$")
	for line in msg.split("\n"):
		line = line.strip_edges()
		if not line:
			continue
		var result = regex.search(line)
		var condition = result.get_string(1).to_lower()
		var actions = result.get_string(2).split(",")
		var operators = ["<", ">", "<=", ">=", "=<", "=>", "=", "==", "!=", "=/=", "\\(", "\\)"]

		condition = add_space_around_special_chars(condition)

		var condition_words = Array(condition.split(" "))
		var parser = Parser.new(condition_words)
		var ast = parser.parse()
		ast_actions.append([ast, actions])
		
	return ast_actions


# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass
	#var msg = """if (health < 0.3) and (is_targeted and distance_to_nearest_obstacle_forward <= 5): return [hide_behind_nearest_obstacle_forward]
#if health < 0.3 and is_targeted and distance_to_nearest_obstacle <= 5: return [hide_behind_nearest_obstacle]
#if is_targeted and distance_to_nearest_obstacle_forward <= 5: return [hide_behind_nearest_obstacle_forward]
#if is_targeted and distance_to_nearest_obstacle <= 5: return [hide_behind_nearest_obstacle]
#if distance_to_nearest_obstacle_forward <= 5: return [circumvent_obstacle]
#if not is_targeted: return [move_towards_goal]"""
	
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#call_mistral_api(api_key, model, Prompts.system_prompt, Prompts.user_prompt)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _do_nothing(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
):
	if result == OK and response_code == 200:
		# Convert the body to a String and then parse it as JSON
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		var response = parsed
		print(response)
		# Extract the content from the JSON
		var content = response["choices"][0]["message"]["content"]
		_llm_orders = content
		print("comment: " + content)
	else:
		return "error"
		
func _api_call_comment(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
):
	if result == OK and response_code == 200:
		# Convert the body to a String and then parse it as JSON
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		var response = parsed
		print("call_comment_output", response)
		# Extract the content from the JSON
		var content = response["choices"][0]["message"]["content"]
		_llm_orders_commment = content
		print("playing", _llm_orders_commment)
		Tts.play(_llm_orders_commment)
		
	else:
		return "error"

# Example function to call the Mistral API
func call_mistral_api(api_key: String, model: String, input_text: String) -> void:
	####### GET ORDER ##########
	# 1. Create an HTTPRequest node and connect its signal.
	print("Starting Mistral API call")
	var request_order := HTTPRequest.new()
	add_child(request_order)
	request_order.connect("request_completed", _do_nothing)

	# 2. Prepare the endpoint, headers, and JSON data.
	var url := "https://api.mistral.ai/v1/chat/completions"
	# Use PackedStringArray in Godot 4
	var headers := PackedStringArray([
		"Authorization: Bearer " + api_key,
		"Content-Type: application/json"
	])

	var data_order := {
		"model": model,
		"temperature": 1,
		"top_p": 1,
		"max_tokens": 1000,
		"messages": [
			{
				"role": "system",
				"content": Prompts.get_order_system_prompt()
			},
			{
				"role": "user",
				"content": Prompts.get_order_user_prompt(input_text)
			}
		]
	}

	# Convert the Dictionary to a JSON string
	var json_body_order := JSON.stringify(data_order)

	# 3. Make the asynchronous request
	#    request(url, headers, use_ssl, method, request_data)
	var err_ord := request_order.request(url, headers, HTTPClient.METHOD_POST, json_body_order)
	await request_order.request_completed
	if err_ord != OK:
		push_error("Failed to make request: %s" % err_ord)
		
	print("Order:", _llm_orders)
	
	####### GET POLICY ############
	
	# 1. Create an HTTPRequest node and connect its signal.
	print("Starting 2nd Mistral API call")
	var request_policy := HTTPRequest.new()
	add_child(request_policy)
	request_policy.connect("request_completed", _on_mistral_api_response)

	var data_policy := {
		"model": model,
		"temperature": 1,
		"top_p": 1,
		"max_tokens": 1000,
		"messages": [
			{
				"role": "system",
				"content": Prompts.get_policy_system_prompt()
			},
			{
				"role": "user",
				"content": Prompts.get_policy_user_prompt(_llm_orders)
			}
		]
	}
	
	print("llm_orders befor call " + _llm_orders)

	# Convert the Dictionary to a JSON string
	var json_body_policy := JSON.stringify(data_policy)
	
	# 3. Make the asynchronous request
	#    request(url, headers, use_ssl, method, request_data)
	var err := request_policy.request(url, headers, HTTPClient.METHOD_POST, json_body_policy)
	await get_tree().create_timer(1).timeout
	await request_policy.request_completed
	#await request_policy.request_completed
	if err != OK:
		push_error("Failed to make request: %s" % err)
	print("Policy:", err)
	
	### COMMENT ON POLICY
	print("Starting 3rd Mistral API call")
	var request_comment := HTTPRequest.new()
	add_child(request_comment)
	request_comment.connect("request_completed", _api_call_comment)
	print('llm_orders befor comment', _llm_orders)
	var data_comment := {
		"model": model,
		"temperature": 1,
		"top_p": 1,
		"max_tokens": 1000,
		"messages": [
			{
				"role": "system",
				"content": Prompts.get_comment_system_prompt()
			},
			{
				"role": "user",
				"content": Prompts.get_comment_user_prompt(_llm_orders)
			}
		]
	}
	
	# Convert the Dictionary to a JSON string
	var json_body_comment := JSON.stringify(data_comment)

	# 3. Make the asynchronous request
	#    request(url, headers, use_ssl, method, request_data)
	var err_comment := request_comment.request(url, headers, HTTPClient.METHOD_POST, json_body_comment)
	await request_comment.request_completed
	
	if err_comment != OK:
		push_error("Failed to make request: %s" % err)
	
	print("Policy:", err_comment)
	

# This function gets called automatically when the HTTP request completes.
func _on_mistral_api_response(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
):
	print('gotten result')
	print(result, response_code)
	if result == OK and response_code == 200:
		# Convert the body to a String and then parse it as JSON
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		var response = parsed
		# Extract the content from the JSON
		var content = response["choices"][0]["message"]["content"]
		# Split the content to extract the part between <grammar> and </grammar>
		var split_content = content.split("```\n")
		print(split_content)
		if len(split_content) > 1: # Ensure there's a <grammar> tag
			var grammar_section = split_content[1].split("\n```")
			
			var grammar_game_plan_1 = grammar_section[0]
			#grammar_game_plan_1 = grammar_game_plan_1.replace("/n", "")
			print("Extracted grammar content:", grammar_game_plan_1)
			var ast_actions = parse_msg(grammar_game_plan_1)
			#print(ast_actions)
			# Update last_ast_actions
			get_parent().set_ast_actions(ast_actions)
			# Set policy to LLM mode (9)
			get_parent().set_policy(9)
		else:
			print("No opening <grammar> tag found.")

	else:
		push_warning("Request failed. Error code: %s, HTTP status: %s" % [result, response_code])
		
