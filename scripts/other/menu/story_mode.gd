extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")

var cur_btn = 0

var weeks = ["Tutorial", "Week 1", "Week 2", "Week 3", "Week 4", "Week 5", "Week 6", "Week 7"]
var scenarios = [
	[["level", "tutorial"]],
	[["level", "bopeebo"], ["level", "fresh"], ["level", "dadbattle"]],
	[["level", "spookeez"], ["level", "south"], ["level", "monster"]],
	[["level", "pico"], ["level", "philly-nice"], ["level", "blammed"]],
	[["level", "satin-panties"], ["level", "high"], ["level", "milf"]],
	[["level", "cocoa"], ["level", "eggnog"], ["level", "winter-horrorland"]],
	[["level", "senpai"], ["level", "roses"], ["level", "thorns"]],
	[["level", "ugh"], ["level", "guns"], ["level", "stress"]],
]

var erect_storys = [1, 3, 6]

func _ready():
	SaveManager.save_data()
	for btn in weeks:
		var btn_inst = Control.new()
		btn_inst.custom_minimum_size = Vector2(200, 50)
		spawn_sprite_text(btn, Vector2(25, 25), btn_inst)
		$container.add_child(btn_inst)
	$difficulty.play(GlobalVaribles.difficulty)
	update_btns()


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
		GlobalFunctions.add_particle(node, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : Vector2(0.7, 0.7),
			"position" : set_pos,
			"sprite_anim" : letter.to_lower(),
			"delete_on_end" : false,
			})
		letter_pos += 1


func _input(_event):
	if Input.is_action_just_pressed("accept"):
		GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
		GlobalFunctions.clear_level_infos()
		GlobalVaribles.story_info = {}
		GlobalFunctions.load_story(scenarios[cur_btn], weeks[cur_btn])
		SceneChanger.change_to("scenes/main_scenes/" + GlobalVaribles.story_info.scenario[0][0])
	elif Input.is_action_just_pressed("cancel"):
		GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL, 0, PROCESS_MODE_ALWAYS)
		await get_tree().create_timer(0.05).timeout
		GlobalVaribles.menu_layer = "main"
		queue_free()
	elif Input.is_action_just_pressed("up"):
		cur_btn -= 1
		if cur_btn < 0:
			cur_btn = $container.get_child_count() - 1
		update_btns()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("down"):
		cur_btn += 1
		if cur_btn > $container.get_child_count() - 1:
			cur_btn = 0
		update_btns()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("left"):
		match GlobalVaribles.difficulty:
			"easy": GlobalVaribles.difficulty = "nightmare"
			"normal": GlobalVaribles.difficulty = "easy"
			"hard": GlobalVaribles.difficulty = "normal"
			"erect": GlobalVaribles.difficulty = "hard"
			"nightmare": GlobalVaribles.difficulty = "erect"
		
		if !erect_storys.has(cur_btn) and GlobalVaribles.difficulty == "nightmare":
			GlobalVaribles.difficulty = "hard"
		
		$difficulty.play(GlobalVaribles.difficulty)
		update_score()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("right"):
		match GlobalVaribles.difficulty:
			"easy": GlobalVaribles.difficulty = "normal"
			"normal": GlobalVaribles.difficulty = "hard"
			"hard": GlobalVaribles.difficulty = "erect"
			"erect": GlobalVaribles.difficulty = "nightmare"
			"nightmare": GlobalVaribles.difficulty = "easy"
		
		if !erect_storys.has(cur_btn) and GlobalVaribles.difficulty == "erect":
			GlobalVaribles.difficulty = "easy"
		
		$difficulty.play(GlobalVaribles.difficulty)
		update_score()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)


func update_btns():
	for child in $container.get_children():
		child.modulate = "99999999"
	$container.get_child(cur_btn).modulate = Color.WHITE
	
	if !erect_storys.has(cur_btn) and (GlobalVaribles.difficulty == "erect" or GlobalVaribles.difficulty == "nightmare"):
		GlobalVaribles.difficulty = "hard"
	$difficulty.play(GlobalVaribles.difficulty)
	update_score()


func update_score():
	if !SaveManager.game_data.storys_data.has(weeks[cur_btn]):
		SaveManager.game_data.storys_data.merge({weeks[cur_btn] : {}})
	if !SaveManager.game_data.storys_data[weeks[cur_btn]].has(GlobalVaribles.difficulty):
		SaveManager.game_data.storys_data[weeks[cur_btn]].merge({GlobalVaribles.difficulty : [0, 0]})
	SaveManager.save_data()
	$label.text = "Score: " + str(SaveManager.game_data.storys_data[weeks[cur_btn]][GlobalVaribles.difficulty][0]) + "\nRate: " + str(SaveManager.game_data.storys_data[weeks[cur_btn]][GlobalVaribles.difficulty][1]) + "%"


func _process(delta):
	$container.position.y -= ($container.position.y - (-$container.get_child(cur_btn).position.y) - 280) * clamp(delta * 15, 0, 0.99)
