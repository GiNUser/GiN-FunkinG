extends CanvasLayer

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")

func _ready():
	spawn_text("press any key to rebind", Vector2(640, 150))
	spawn_text("press escape to cancel", Vector2(640, 570))


func spawn_text(text, pos):
	var letter_pos = 0
	for letter in text:
		if letter == " ":
			letter_pos += 1
			continue
		var inst_scale = Vector2(0.7, 0.7)
		if letter == str(float(letter)):
			inst_scale = Vector2(1, 1)
		GlobalFunctions.add_anim_sprite(self, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : inst_scale,
			"position" : pos + Vector2(30 * (letter_pos - text.length() / 2), 0),
			"delete_on_end" : false,
			"sprite_anim" : letter.to_lower(),
		})
		letter_pos += 1
