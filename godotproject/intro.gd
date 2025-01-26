extends Node3D

var intro_monolog = [
	"The war was supposed to end with me...",
	"But fate had other plans...",
	"I was a war general, once feared, now forgotten.",
	"Down in battle...",
	"My son took up my sword, my name, and my cause...",
	"and he’s TERRIBLE at it!",
	"Only he can still hear me",
	"I can’t stay put while he fumbles our legacy",
	"I'll whisper him strategies to guide his army.",
	"Up to him to interpret my advice...",
	"...and not mess it up!"
]

var current_monolog_index = 0

@onready var display_text_ui: TextDisplay = $IntroUI
@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D

# The total duration for the path animation in seconds
@export var ANIMATION_DURATION = 32.0
@export var disable:bool = false

var progress_ratio = 0.0

signal intro_finished

func _ready():
	if disable:
		return
	await get_tree().create_timer(1).timeout

	$IntroVoice.play()
	$Path3D/PathFollow3D/CameraIntro.make_current()
	$Path3D/PathFollow3D.progress_ratio = 0
	display_text_ui.set_text(intro_monolog[current_monolog_index])
	display_text_ui.type_text()

func _process(delta: float) -> void:
	if disable:
		return
		
	# Increment progress_ratio based on delta time and duration
	progress_ratio += delta / ANIMATION_DURATION
	progress_ratio = clamp(progress_ratio, 0.0, 1.0)
	
	# Update the position of the PathFollow3D based on progress_ratio
	path_follow.progress_ratio = progress_ratio

func _on_intro_ui_stopped_typing() -> void:
	# Wait for 1 second before moving to the next line
	await get_tree().create_timer(1).timeout

	current_monolog_index += 1
	if current_monolog_index < intro_monolog.size():
		display_text_ui.set_text(intro_monolog[current_monolog_index])
		display_text_ui.type_text()
	else:
		intro_finished.emit()
		display_text_ui.hide()
