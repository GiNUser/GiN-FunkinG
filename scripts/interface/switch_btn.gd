extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_REMOTE_CLICK = preload("res://assets/sounds/menu/options/remote_click.ogg")

@export var setting = ""
@export var text = ""
@export var description = ""

func _ready():
	if SaveManager.game_data[setting]:
		$check_box.frame = 6
	var letter_pos = 0
	for letter in text:
		if letter == " ":
			letter_pos += 1
			continue
		GlobalFunctions.add_particle(self, {
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
	$check_box.play(str(SaveManager.game_data[setting]))
	GlobalFunctions.add_audio_effect(SOUND_REMOTE_CLICK, 15)
	
	match setting:
		"voices":
			AudioServer.set_bus_mute(2, !SaveManager.game_data[setting])
