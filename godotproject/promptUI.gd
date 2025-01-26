extends Control

@onready var battlefield: Battlefield = get_node("/root/Battlefield")
@onready var agent_policies = get_node("/root/Battlefield/AgentPolicies")


func _ready():
	hide() # Hide initially until intro is finished

func _on_intro_intro_finished():
	show()

func _on_button_pressed():
	# Call LLM with the prompt
	if agent_policies and agent_policies.llm_instance:
		agent_policies.llm_instance.call_mistral_api(
			"hVnbwh7aEMLNuGSnnDRljvgUOZAbKXZj",
			"mistral-large-latest",
			$TextureRect/TextEdit.text
		)
	
	# Start level 1 and spawn enemies for the current level
	if battlefield:
		battlefield.start_level(battlefield.current_level + 1)
		battlefield.spawn_pending_agents()
	
	$TextureRect/TextEdit.text = ""
	hide()
