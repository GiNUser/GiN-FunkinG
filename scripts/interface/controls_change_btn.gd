extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_REMOTE_CLICK = preload("res://assets/sounds/menu/options/remote_click.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const POP_UP = preload("res://scenes/interface/pop_up_label.scn")

@export var action = ""
@export var text = ""

var active = false

func _ready():
	update_text()


func update_text():
	for child in get_children():
		child.queue_free()
	
	var key : InputEventKey = InputMap.action_get_events(action)[InputMap.action_get_events(action).size() - 1]
	var new_text = text + key.as_text_keycode()
	
	var letter_pos = 0
	for letter in new_text:
		if letter == " ":
			letter_pos += 1
			continue
		var inst_scale = Vector2(0.7, 0.7)
		if letter == str(float(letter)):
			inst_scale = Vector2(1, 1)
		GlobalFunctions.add_anim_sprite(self, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : inst_scale,
			"position" : Vector2(40, 60) + Vector2(30 * letter_pos, 0),
			"delete_on_end" : false,
			"sprite_anim" : letter.to_lower(),
		})
		letter_pos += 1


func _input(event):
	if active:
		if event is not InputEventKey:
			return
		
		if event.keycode == 4194305:
			call_deferred("off")
			GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL)
		elif event.keycode != 4194309:
			var actions = InputMap.action_get_events(action)
			InputMap.action_erase_event(action, actions[actions.size() - 1])
			InputMap.action_add_event(action, event)
			update_text()
			
			SaveManager.game_data.input_map[action] = event.keycode
			SaveManager.save_data()
			
			call_deferred("off")
			GlobalFunctions.add_audio_effect(SOUND_REMOTE_CLICK, 15)


func off():
	active = false
	GlobalVaribles.menu_layer = "options"
	change_pop_up()


func use():
	if active:
		return
	active = true
	GlobalVaribles.menu_layer = "controls_change"
	change_pop_up()
	GlobalFunctions.add_audio_effect(SOUND_REMOTE_CLICK, 15)


func change_pop_up():
	if !get_tree().root.has_node("pop_up_label"):
		get_tree().root.add_child(POP_UP.instantiate())
	else:
		get_tree().root.get_node("pop_up_label").queue_free()
