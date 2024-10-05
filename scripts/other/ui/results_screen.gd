extends CanvasLayer

const RESULTS_PERCENT_SMALL = preload("res://assets/resources/sprite_frames/results-screen/results_percent_small.res")
const RESULTS_PERCENT = preload("res://assets/resources/sprite_frames/results-screen/results_percent.res")
const LETTERS = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const RESULT_ANIM = preload("res://scenes/other/ui/results_screen/bf_result_anim.scn")
const NUMS = preload("res://assets/resources/sprite_frames/anim_sprite/nums.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")
const TARDLING = preload("res://assets/resources/sprite_frames/results-screen/tardling.res")

const DATA = {
	"total_notes" : [Vector2(391, 171), Color.WHITE],
	"max_combo" : [Vector2(391, 221), Color.WHITE],
	"sick" : [Vector2(247, 296), "89e59e"],
	"good" : [Vector2(228, 352), "89c9e5"],
	"bad" : [Vector2(207, 404), "e6cf8a"],
	"shit" : [Vector2(237, 458), "e68c8a"],
	"missed" : [Vector2(277, 515), "c68ae6"],
}

var tween : Tween
var cur_percent = 0
var percent_smooth = 0
var top_text_pos = -1
var right_text_pos = -1

var max_pos = 0
var label_pos = 0
@onready var start_label_pos = $back_text/label.position.x

var rate = 0

func _ready():
	GlobalFunctions.clear_sounds()
	get_tree().paused = true
	
	var infos = GlobalVaribles.level_infos
	rate += infos.sick
	rate += infos.good
	rate += infos.bad / 2.0
	rate += infos.shit / 4.0
	rate = floor((rate / float(infos.total_notes)) * 100.0)
	if infos.sick == infos.total_notes:
		rate = 101
	
	var t1
	if rate <= 59:
		t1 = "LOSS "
	elif rate <= 79:
		t1 = "GOOD "
	elif rate <= 89:
		t1 = "GREAT "
	elif rate <= 99:
		t1 = "EXCELLENT "
	elif rate >= 100:
		t1 = "PERFECT "
	
	$back_text/label.text = t1
	$back_text/label.reset_size()
	max_pos = $back_text/label.size.x
	var t = ""
	for o in 4:
		for i in 10:
			t += t1
		t += "\n\n\n"
	$back_text/label.text = t
	$back_text/label2.text = t
	
	for i in 4: for letter in t1:
		$right_text.text += letter + "\n"
	
	update_rate_percent("0")
	
	tween = create_tween()
	var to_rate = clamp(clamp(rate, 0, 100) - 1, 0, 100)
	tween.tween_property(self, "percent_smooth", to_rate, 3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(result_stop)
	
	if rate <= 59:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/loss-intro.ogg", "AudioStreamOggVorbis")
	elif rate <= 89:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/good.ogg", "AudioStreamOggVorbis")
	elif rate >= 90 and rate < 100:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/excellent-intro.ogg", "AudioStreamOggVorbis")
	$music.play()


func _input(_event):
	if Input.is_action_just_pressed("restart"):
		if GlobalVaribles.story_info:
			GlobalVaribles.story_info.scenario = GlobalVaribles.story_info.full_scenario.duplicate()
		GlobalFunctions.clear_level_infos()
		GlobalFunctions.clear_sounds()
		SceneChanger.change_to()
	elif Input.is_action_just_pressed("accept"):
		$music.stop()
		GlobalVaribles.story_info = {}
		GlobalFunctions.clear_level_infos()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM)
		
		if GlobalVaribles.story_info:
			SceneChanger.change_to("scenes/main_scenes/menu")
			return
		var texture_rect = TextureRect.new()
		await RenderingServer.frame_post_draw
		texture_rect.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
		texture_rect.name = "last_frame"
		texture_rect.size = DisplayServer.screen_get_size()
		get_tree().root.add_child(texture_rect)
		get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")


func _process(delta):
	if tween.is_running():
		if cur_percent != percent_smooth:
			cur_percent = percent_smooth
			update_rate_percent(str(percent_smooth))
			GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, -5, PROCESS_MODE_ALWAYS)
	
	label_pos += delta * 10
	if label_pos >= max_pos:
		label_pos = 0
	$back_text/label.position.x = start_label_pos + label_pos
	$back_text/label2.position.x = start_label_pos - label_pos
	
	if top_text_pos != -1:
		top_text_pos += delta * 90
		if top_text_pos > $top_text.size.x + 550:
			top_text_pos = 0
		$top_text.position = Vector2(1283, 83) - Vector2(top_text_pos * 1283, top_text_pos * -83) / 1000
	if right_text_pos != -1:
		right_text_pos += delta * 50
		if right_text_pos > $right_text.size.y / 4:
			right_text_pos = 0
		$right_text.position.y = -right_text_pos


func _on_anim_player_animation_finished(_anim_name):
	var cur_num = 0
	for num in str(round(GlobalVaribles.level_infos.score)).reverse():
		if num == "-":
			continue
		get_node("score_nums/num_" + str(9 - cur_num)).play(num)
		cur_num += 1
	if GlobalVaribles.level_infos.score > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0]:
		$show_highscore.play("def")


func _on_music_finished():
	$music.stream = GlobalFunctions.load_thread($music.stream.resource_path.replace("-intro", ""), "AudioStreamOggVorbis")
	$music.play()


func result_stop():
	tween.kill()
	update_rate_percent(str(clamp(rate, 0, 100)))
	GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
	$back_text.show()
	$right_text.show()
	$flash_anim.play("hide")
	for item in DATA:
		var num_pos = 0
		for num in str(GlobalVaribles.level_infos[item]):
			GlobalFunctions.add_particle(self, {
				"sprite_frames" : NUMS,
				"sprite_anim" : int(num),
				"delete_on_end" : false,
				"animation" : "show_num",
				"position" : DATA[item][0] + Vector2(42 * num_pos, 0),
				"modulate" : DATA[item][1],
				"z_index" : 11,
			})
			num_pos += 1


func flash_end(_anim_name):
	$flash_anim.queue_free()
	$percent.queue_free()
	$flash_rect.queue_free()
	add_child(RESULT_ANIM.instantiate())
	
	$top_text/difficulty.texture = GlobalFunctions.load_thread("res://assets/images/results-screen/" + GlobalVaribles.difficulty + ".png", "Texture2D")
	$top_text/difficulty.reset_size()
	$top_text.size.x = $top_text/difficulty.size.x
	
	for num in str(clamp(rate, 0, 100)):
		GlobalFunctions.add_particle($top_text, {
			"sprite_frames" : RESULTS_PERCENT_SMALL,
			"sprite_anim" : int(num),
			"delete_on_end" : false,
			"position" : Vector2($top_text.size.x + 20, 34),
			})
		$top_text.size.x += 28
	$top_text/percent.position = Vector2($top_text.size.x + 5, 14)
	$top_text.size.x += 40
	
	var text
	if GlobalVaribles.story_info:
		text = GlobalVaribles.story_info.name
	else:
		text = GlobalVaribles.level_name
	for letter in text:
		$top_text.size.x += 35
		if [" ", ".", "-"].has(letter):
			continue
		GlobalFunctions.add_particle($top_text, {
			"sprite_frames" : TARDLING,
			"sprite_anim" : str(letter),
			"delete_on_end" : false,
			"position" : Vector2($top_text.size.x, 43),
			})
	top_text_pos = 0
	right_text_pos = 0
	
	if rate >= 100:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/perfect.ogg", "AudioStreamOggVorbis")
		$music.play()


func update_rate_percent(percent):
	for child in $percent.get_children():
		if child.name != "text" and child.name != "label":
			child.queue_free()
	
	var num_pos = 1
	for num in percent:
		GlobalFunctions.add_particle($percent, {
			"sprite_frames" : RESULTS_PERCENT,
			"sprite_anim" : int(num),
			"delete_on_end" : false,
			"position" : Vector2((percent.length() - num_pos) * -75 - 4, 41),
			})
		num_pos += 1
