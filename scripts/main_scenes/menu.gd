extends CanvasLayer

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const ANIM_SPRITE = preload("res://scenes/gameplay/animated_sprite.scn")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")

const START_SCREEN = preload("res://scenes/other/menu/start_screen.scn")
const FREEPLAY = preload("res://scenes/other/menu/freeplay.scn")
const OPTIONS = preload("res://scenes/other/menu/options.scn")

var cur_menu_btn = 0

func _ready():
	get_tree().paused = false
	match GlobalVaribles.menu_layer:
		"":
			call_deferred("add_child", START_SCREEN.instantiate())
			$main_music.play()
			$main.hide()
		"main":
			$main/anim_player.play("show")
			$main_music.play()
		"freeplay":
			$main.hide()
			call_deferred("add_child", FREEPLAY.instantiate())


func _input(_event):
	if Input.is_action_just_pressed("accept"): match GlobalVaribles.menu_layer:
		"":
			if has_node("start_screen") and !$start_screen/anim_player.is_playing():
				if has_node("start_screen/newgrounds_logo"):
					$start_screen/newgrounds_logo.queue_free()
				$start_screen.show_main()
				$main/anim_player.play("show")
		"main":
			match cur_menu_btn:
				0:
					GlobalFunctions.load_story([["level", "bopeebo"], ["level", "fresh"], ["level", "dadbattle"]])
					SceneChanger.change_to("scenes/main_scenes/" + GlobalVaribles.story_info.scenario[0][0])
				1:
					call_deferred("add_child", FREEPLAY.instantiate())
					GlobalVaribles.menu_layer = "freeplay"
				2:
					GlobalVaribles.menu_layer = "options"
					call_deferred("add_child", OPTIONS.instantiate())
			GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
	if GlobalVaribles.menu_layer != "main":
		return
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
		return
	elif Input.is_action_just_pressed("up"):
		cur_menu_btn -= 1
		if cur_menu_btn < 0:
			cur_menu_btn = 2
		update_menu_btns()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("down"):
		cur_menu_btn += 1
		if cur_menu_btn > 2:
			cur_menu_btn = 0
		update_menu_btns()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)


func update_menu_btns(): match cur_menu_btn:
	0:
		$main/story_mode.play("focused")
		$main/free_play.play("unfocused")
		$main/options.play("unfocused")
	1:
		$main/story_mode.play("unfocused")
		$main/free_play.play("focused")
		$main/options.play("unfocused")
	2:
		$main/story_mode.play("unfocused")
		$main/free_play.play("unfocused")
		$main/options.play("focused")
