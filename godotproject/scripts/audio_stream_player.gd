extends AudioStreamPlayer


var audio_url = "https://api.elevenlabs.io/v1/text-to-speech/V33LkP9pVLdcjeB2y5Na/stream?output_format=mp3_44100_128"

@onready var http_request_node = $test_HTTPRequest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#self.play()
	var headers = [
		"xi-api-key: lolilol",
		"Content-Type: application/json"
	]
	
	var data = {
		"text": "Je parle depuis godot ! hype hype",
		"model_id": "eleven_multilingual_v2"
	}
	
	http_request_node.request(audio_url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	print('coucou')
	$TextEdit.text
	pass # Replace with function body.

func play_audio_from_stream(audio_data: PackedByteArray):
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = audio_data
	self.stream = audio_stream
	self.play()

func _on_test_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		play_audio_from_stream(body)
	else:
		print("Failed to fetch audio stream. Response code: ", response_code)
