extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")

var cur_options_layer = "main"
var cur_options_main_btn = 0
var cur_options_preferences_btn = 0
var cur_options_gameplay_btn = 0
var cur_options_controls_btn = 0

func _ready():
	spawn_sprite_text("options", Vector2(20, 27.5), $top_bar)
	spawn_sprite_text("preferences", Vector2(35, 50), $main_container/preferences)
	spawn_sprite_text("gameplay", Vector2(35, 50), $main_container/gameplay)
	spawn_sprite_text("controls", Vector2(35, 50), $main_container/controls)
	update_options_btn()


func spawn_sprite_text(text = "", pos = Vector2.ZERO, node = self, from_right_to_left = false):
	var letter_pos = 0
	for letter in text:
		if letter == " ":
			letter_pos += 1
			continue
		var set_pos
		if from_right_to_left:
			set_pos = pos - Vector2(30 * (text.length() - letter_pos), 0)
		else:
			set_pos = pos + Vector2(30 * letter_pos, 0)
		GlobalFunctions.add_anim_sprite(node,
		{
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : Vector2(0.7, 0.7),
			"position" : set_pos,
			"sprite_anim" : letter.to_lower(),
			"delete_on_end" : false,
			})
		letter_pos += 1


func _input(_event): if GlobalVaribles.menu_layer == "options":
	if Input.is_action_just_pressed("accept"):
		if cur_options_layer == "main":
			match cur_options_main_btn:
				0: cur_options_layer = "preferences"
				1: cur_options_layer = "gameplay"
				2: cur_options_layer = "controls"
			$transition_anim_player.play("hide")
			GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
		else:
			get_node(cur_options_layer + "_container").get_child(self["cur_options_" + cur_options_layer + "_btn"]).use()
	elif Input.is_action_just_pressed("esc"):
		if cur_options_layer == "main":
			$anim_player.play("hide")
		else:
			cur_options_layer = "main"
		GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL, 0, PROCESS_MODE_ALWAYS)
		$transition_anim_player.play("hide")
	elif Input.is_action_just_pressed("up"):
		self["cur_options_" + cur_options_layer + "_btn"] -= 1
		if self["cur_options_" + cur_options_layer + "_btn"] < 0:
			self["cur_options_" + cur_options_layer + "_btn"] = get_node(cur_options_layer + "_container").get_child_count() - 1
		update_options_btn()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("down"):
		self["cur_options_" + cur_options_layer + "_btn"] += 1
		if self["cur_options_" + cur_options_layer + "_btn"] > get_node(cur_options_layer + "_container").get_child_count() - 1:
			self["cur_options_" + cur_options_layer + "_btn"] = 0
		update_options_btn()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)


func update_options_btn():
	for child in get_node(cur_options_layer + "_container").get_children():
		child.modulate = Color.GRAY
	get_node(cur_options_layer + "_container").get_child(self["cur_options_" + cur_options_layer + "_btn"]).modulate = Color.WHITE


func _on_anim_player_animation_finished(anim_name):
	if anim_name == "hide":
		GlobalVaribles.menu_layer = "main"
		queue_free()


func _on_transition_anim_player_animation_finished(anim_name):
	if anim_name == "hide":
		$main_container.visible = cur_options_layer == "main"
		if cur_options_layer != "main":
			get_node(cur_options_layer + "_container").visible = true
		else:
			get_node("preferences_container").hide()
			get_node("gameplay_container").hide()
			get_node("controls_container").hide()
		$transition_anim_player.play("show")
		update_options_btn()
