extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_REMOTE_CLICK = preload("res://assets/sounds/menu/options/remote_click.ogg")

@export var setting = ""
@export var text = ""

func _ready():
	if SaveManager.game_data[setting]:
		$check_box.frame = 6
	var letter_pos = 0
	for letter in text:
		if letter == " ":
			letter_pos += 1
			continue
		GlobalFunctions.add_anim_sprite(self, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : Vector2(0.7, 0.7),
			"position" : Vector2(120, 60) + Vector2(30 * letter_pos, 0),
			"delete_on_end" : false,
			"sprite_anim" : letter.to_lower(),
		})
		letter_pos += 1


func use():
	SaveManager.game_data[setting] = !SaveManager.game_data[setting]
	SaveManager.save_data()
	if SaveManager.game_data[setting]:
		$check_box.play("turn_on")
	else:
		$check_box.play("turn_off")
	GlobalFunctions.add_audio_effect(SOUND_REMOTE_CLICK, 15)
