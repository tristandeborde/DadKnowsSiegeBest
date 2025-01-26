extends Node

class_name TextDisplay

@export var typing_speed: float = 0.001  # Delay between characters

signal stopped_typing

var _rich_text_label: RichTextLabel
var _full_text: String = ""
var _current_index: int = 0
var _typing: bool = false

func _ready():
	_rich_text_label = $VBoxContainer2/RichTextLabel
	_full_text = _rich_text_label.text
	_rich_text_label.text = ""
	
	#set_text("The war was supposed to end with me.")
	#type_text()

func type_text():
	if _typing or _current_index >= _full_text.length():
		return
	_typing = true
	_current_index = 0
	_rich_text_label.text = ""
	_start_typing()

func _start_typing():
	# Continue typing the text
	if _current_index < _full_text.length():
		_rich_text_label.text += _full_text[_current_index]
		_current_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_start_typing()
	else:
		stopped_typing.emit()
		_typing = false

func set_text(new_text: String):
	# Set a new text to display
	_full_text = new_text
	_current_index = 0
	_rich_text_label.text = ""
	type_text()
