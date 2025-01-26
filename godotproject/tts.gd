class_name TTS

extends Node

@onready var audio_player: AudioStreamPlayer = $TTSStreamPlayer
@onready var http_request: HTTPRequest = $TTSHTTPRequest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func play(text: String, voice_id = null):
	print("TTS Started")
	if voice_id == null:
		voice_id = "hehehe"
	
	var tts_url = "https://api.elevenlabs.io/v1/text-to-speech/" + voice_id + "/stream?output_format=mp3_44100_128"
	
	var headers = [
		"xi-api-key: lololol",
		"Content-Type: application/json"
	]
	
	var data = {
		"text": text,
		"model_id": "eleven_multilingual_v2"
	}
	
	http_request.request(tts_url, headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	
func play_audio_from_stream(audio_data: PackedByteArray):
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = audio_data
	audio_player.stream = audio_stream
	audio_player.play()


func _on_ttshttp_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		play_audio_from_stream(body)
	else:
		print("Failed to fetch audio stream. Response code: ", response_code)
