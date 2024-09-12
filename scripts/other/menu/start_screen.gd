extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")

var measure = 0
var beat = 0

func _ready():
	text_to_sprites("the\nfunkin group inc\npresents")


func _on_beat_timer_timeout():
	for child in $start_text.get_children():
		if child.is_in_group("line_" + str(beat)):
			child.show()
	if beat == 2 and measure == 1:
		$newgrounds_logo.show()
	beat += 1
	if beat > 3:
		beat = 0
		measure += 1
		for child in $start_text.get_children():
			if child.is_in_group("letter"):
				child.call_deferred("queue_free")
				if beat == 0 and measure == 2:
					$newgrounds_logo.queue_free()
		match measure:
			1:
				text_to_sprites("in association\nwith\nnewgrounds")
			2:
				var intro_text = FileAccess.open("res://assets/resources/intro_text.txt", FileAccess.READ).get_as_text()
				text_to_sprites(intro_text.get_slice("\n", randi_range(0, intro_text.count("\n"))).replace("-", "\n\n"))
			3:
				text_to_sprites("friday\nnight\nfunkin")
			4:
				show_main()


func text_to_sprites(text : String):
	for child in $start_text.get_children():
		if child.is_in_group("letter"):
			child.call_deferred("queue_free")
	var lines = text.count("\n")
	var text_buffer = text
	text_buffer = text.get_slice("\n", 0)
	for line in lines + 1:
		for letter_x in text_buffer.length():
			if text_buffer[letter_x] == " ":
				continue
			GlobalFunctions.add_anim_sprite($start_text, {
				"sprite_frames" : LETTERS_SPRITE_FRAMES,
				"sprite_anim" : text_buffer[letter_x].to_lower(),
				"position" : Vector2(640 + (letter_x - (text_buffer.length() / 2.0)) * 45, 360 + (line - lines / 2.0) * 65),
				"delete_on_end" : false,
				"visible" : false,
				"add_to_group" : ["letter", "line_" + str(line)],
			})
		text_buffer = text.get_slice("\n", line + 1)


func show_main():
	$beat_timer.queue_free()
	$start_text.queue_free()
	$anim_player.play("show")
	get_parent().get_node("main/anim_player").play("show")


func _on_anim_player_animation_finished(_anim_name):
	get_parent().get_node("main/logo").show()
	GlobalVaribles.menu_layer = "main"
	queue_free()
