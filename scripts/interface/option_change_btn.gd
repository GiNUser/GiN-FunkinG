extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_REMOTE_CLICK = preload("res://assets/sounds/menu/options/remote_click.ogg")

var cur_var = 0
@export var vars = []
@export var vars_decriptions = []

@export var setting = ""
@export var text = ""

func _ready():
	cur_var = vars.find(SaveManager.game_data[setting])
	update_text()


func update_text():
	for child in get_children():
		child.queue_free()
	
	var text_to_add = text + vars_decriptions[cur_var]
	var letter_pos = 0
	for letter in text_to_add:
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


func use():
	cur_var += 1
	if cur_var + 1 > vars.size():
		cur_var = 0
	SaveManager.game_data[setting] = vars[cur_var]
	SaveManager.save_data()
	update_text()
	
	match setting:
		"max_fps":
			if SaveManager.game_data[setting] == -1:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				Engine.max_fps = SaveManager.game_data[setting]
	GlobalFunctions.add_audio_effect(SOUND_REMOTE_CLICK, 15)
