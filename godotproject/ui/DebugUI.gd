extends Control

var turret: Node3D
var agent_policies: Node
var battlefield: Node3D

func _ready():
	# Get references
	turret = get_node("../Turret")
	agent_policies = get_node("../AgentPolicies")
	battlefield = get_node("..")
	
	if not turret:
		push_error("Could not find Turret node!")
	
	# Add policy buttons
	var policies = {
		1: "Move to Castle",
		2: "Hide Behind Obstacle",
		3: "Hide Forward",
		4: "Circumvent",
		5: "Move or Hide",
		6: "Get Sandals",
		7: "Get Shield",
		8: "Get Staff",
		9: "LLM Policy"
	}
	
	for number in policies:
		var button = Button.new()
		button.text = str(number) + ": " + policies[number]
		button.pressed.connect(_on_policy_pressed.bind(number))
		$PolicyPanel/VBoxContainer.add_child(button)
	
	# Add level buttons
	var level_container = VBoxContainer.new()
	$PolicyPanel.add_child(level_container)
	level_container.add_theme_constant_override("separation", 10)
	
	# Add a label for the level buttons
	var label = Label.new()
	label.text = "Debug Levels:"
	level_container.add_child(label)
	
	# Create level buttons with correct levels
	var levels = [1, 2, 3] # Remove level 4
	for level in levels:
		var button = Button.new()
		button.text = "Start Level " + str(level)
		button.add_theme_color_override("font_color", Color.RED)
		button.add_theme_color_override("font_pressed_color", Color.DARK_RED)
		
		# Create a new function for each button
		var callable = func():
			if battlefield:
				battlefield.start_level(level)
		
		button.pressed.connect(callable)
		level_container.add_child(button)

func _on_policy_pressed(policy_number: int):
	agent_policies.set_policy(policy_number)

func _on_call_llm_pressed():
	if agent_policies and agent_policies.llm_instance:
		agent_policies.llm_instance.call_mistral_api(
			"hVnbwh7aEMLNuGSnnDRljvgUOZAbKXZj",
			"mistral-large-latest",
			$LLMPanel/VBoxContainer/LineEdit.text
		)

func _on_spoof_llm_pressed():
	print("spoofeds")
	if agent_policies and agent_policies.llm_instance:
		var sample_response = {
	"choices": [
		{
			"index": 0,
			"message": {
				"role": "assistant",
				"tool_calls": null,
				"content": "```html\n<grammar>\nif True: return [move_towards_goal]\n</grammar>\n```"
			},
			"finish_reason": "stop"
		}
	],
	"usage": {
		"prompt_tokens": 767,
		"total_tokens": 979,
		"completion_tokens": 212
	}
}
		agent_policies.llm_instance._on_mistral_api_response(
			OK, # result
			200, # response_code
			PackedStringArray([]), # headers
			JSON.stringify(sample_response).to_utf8_buffer() # body
		)

func _on_level_pressed(level: int):
	if battlefield:
		battlefield.start_level(level)
