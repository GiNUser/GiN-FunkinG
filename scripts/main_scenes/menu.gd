extends CanvasLayer

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")

const START_SCREEN = preload("res://scenes/other/menu/start_screen.scn")
const STORY_MODE = preload("res://scenes/other/menu/story_mode.scn")
const FREEPLAY = preload("res://scenes/other/menu/freeplay.scn")
const OPTIONS = preload("res://scenes/other/menu/options.scn")

var cur_btn = 0

func _ready():
	get_tree().paused = false
	match GlobalVaribles.menu_layer:
		"":
			add_child(START_SCREEN.instantiate())
			$main_music.play()
		"main":
			$main_music.play()
		"story_mode":
			add_child(STORY_MODE.instantiate())
			$main_music.play()
		"freeplay":
			$main.hide()
			cur_btn = 1
			add_child(FREEPLAY.instantiate())


func _input(_event):
	if Input.is_action_just_pressed("accept"): match GlobalVaribles.menu_layer:
		"":
			if has_node("start_screen") and !$start_screen/anim_player.is_playing():
				if has_node("start_screen/newgrounds_logo"):
					$start_screen/newgrounds_logo.queue_free()
				$start_screen.show_main()
		"main":
			match cur_btn:
				0: GlobalVaribles.menu_layer = "story_mode"
				1: GlobalVaribles.menu_layer = "freeplay"
				2: GlobalVaribles.menu_layer = "options"
			call_deferred("add_child", self[GlobalVaribles.menu_layer.to_upper()].instantiate())
			GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
	if GlobalVaribles.menu_layer != "main":
		return
	if Input.is_action_just_pressed("cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("up"):
		cur_btn -= 1
		if cur_btn < 0:
			cur_btn = 2
		update_menu_btns()
	elif Input.is_action_just_pressed("down"):
		cur_btn += 1
		if cur_btn > 2:
			cur_btn = 0
		update_menu_btns()


func update_menu_btns():
	$main/story_mode.play(str(cur_btn == 0))
	$main/free_play.play(str(cur_btn == 1))
	$main/options.play(str(cur_btn == 2))
	GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
