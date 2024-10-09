extends Control

const DIGITAL_NUMS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/freeplay/digital_nums.res")
const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const CLEAR_NUMS = preload("res://assets/resources/sprite_frames/freeplay/clear_nums.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")
const PARTICLE = preload("res://scenes/gameplay/particle.scn")
const CAPSULE = preload("res://scenes/interface/capsule.scn")
const STARS = preload("res://assets/resources/sprite_frames/freeplay/stars.res")

var cur_level_type = "def"
var levels_array = []
var tween : Tween
var animate_score = false

func _ready():
	spawn_sprite_text("freeplay", Vector2(20, 27.5), $top_bar)
	spawn_sprite_text("original ost", Vector2(1285, 27.5), $top_bar, true)
	
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		cur_level_type = "erect"
	set_new_levels()
	spawn_capsules()
	$difficulty.play(GlobalVaribles.difficulty)
	get_parent().get_node("main_music").volume_db = -80
	update_main_music()
	
	await RenderingServer.frame_post_draw
	
	$anim_player.play("show")
	if get_tree().root.has_node("last_frame"):
		await $anim_player.animation_finished
		get_tree().root.get_node("last_frame").queue_free()


func _input(_event):
	if GlobalVaribles.menu_layer != "freeplay":
		return
	if Input.is_action_just_pressed("accept"):
		if get_cur_music() == "random":
			GlobalVaribles.cur_freeplay_level = randi_range(1, $capsules.get_child_count() - 1)
			$capsules.get_child(0).inactive()
			update_freeplay_btn()
		GlobalVaribles.level_dict_name = get_cur_music()
		$bf_anim.play("start_level")
		$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).use()
		get_parent().get_node("main_music").stop()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("cancel"):
		$anim_player.play("hide")
		get_parent().update_menu_btns()
		$freeplay_music_time.stop()
		$music_load_time.stop()
		get_parent().get_node("beat_anim").stop()
		get_parent().get_node("beat_anim").play()
		get_parent().get_node("main_music_anim").stop()
		get_parent().get_node("main_music").volume_db = 0
		get_parent().get_node("main_music").stream = GlobalFunctions.load_thread("res://assets/music/menu/main.ogg", "AudioStream")
		get_parent().get_node("main_music").play()
		get_parent().get_node("main").show()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("up"):
		$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).inactive()
		GlobalVaribles.cur_freeplay_level -= 1
		if GlobalVaribles.cur_freeplay_level < 0:
			GlobalVaribles.cur_freeplay_level = $capsules.get_child_count() - 1
		update_freeplay_btn()
		spawn_score()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("down"):
		$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).inactive()
		GlobalVaribles.cur_freeplay_level += 1
		if GlobalVaribles.cur_freeplay_level > $capsules.get_child_count() - 1:
			GlobalVaribles.cur_freeplay_level = 0
		update_freeplay_btn()
		spawn_score()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("left"):
		var to_dif = ["easy", "normal", "hard", "erect", "nightmare"].find(GlobalVaribles.difficulty) - 1
		var cur_dif = "def"
		GlobalVaribles.difficulty = ["nightmare", "easy", "normal", "hard", "erect", "nightmare"][to_dif + 1]
		set_new_levels()
		match to_dif:
			-1:
				var cur_level = GlobalVaribles.LEVELS[GlobalVaribles.cur_freeplay_level - 1]
				if GlobalVaribles.cur_freeplay_level == 0:
					cur_level = "random"
				if GlobalVaribles.freeplay_capsules_infos[cur_level][0].has("erect"):
					GlobalVaribles.cur_freeplay_level = levels_array.find(cur_level)
					cur_dif = "erect"
				else:
					GlobalVaribles.difficulty = "hard"
					set_new_levels()
			3:
				cur_dif = "erect"
			2:
				if GlobalVaribles.cur_freeplay_level != 0:
					var cur_level = GlobalVaribles.LEVELS_ERECT[GlobalVaribles.cur_freeplay_level - 1]
					GlobalVaribles.cur_freeplay_level = GlobalVaribles.LEVELS.find(cur_level) + 1
		
		if cur_dif != cur_level_type:
			cur_level_type = cur_dif
			
			$capsules.name = "to_del"
			$to_del.queue_free()
			var node = Control.new()
			node.position = Vector2(429, 256)
			node.name = "capsules"
			add_child(node)
			
			spawn_capsules()
			if get_cur_music() != "random":
				update_main_music()
		
		for capsule in $capsules.get_children():
			capsule.update_dif()
		spawn_score()
		spawn_stars()
		
		$difficulty.play(GlobalVaribles.difficulty)
		$dif_anim.play("change")
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
		$selector_l.scale = Vector2(0.6, 0.6)
		await get_tree().create_timer(0.1).timeout
		$selector_l.scale = Vector2(1, 1)
	elif Input.is_action_just_pressed("right"):
		var to_dif = ["easy", "normal", "hard", "erect", "nightmare"].find(GlobalVaribles.difficulty) + 1
		var cur_dif = "def"
		GlobalVaribles.difficulty = ["easy", "normal", "hard", "erect", "nightmare", "easy"][to_dif]
		set_new_levels()
		match to_dif:
			3:
				var cur_level = GlobalVaribles.LEVELS[GlobalVaribles.cur_freeplay_level - 1]
				if GlobalVaribles.cur_freeplay_level == 0:
					cur_level = "random"
				if GlobalVaribles.freeplay_capsules_infos[cur_level][0].has("erect"):
					GlobalVaribles.cur_freeplay_level = levels_array.find(cur_level)
					cur_dif = "erect"
				else:
					GlobalVaribles.difficulty = "easy"
					set_new_levels()
			4:
				cur_dif = "erect"
			5:
				if GlobalVaribles.cur_freeplay_level != 0:
					var cur_level = GlobalVaribles.LEVELS_ERECT[GlobalVaribles.cur_freeplay_level - 1]
					GlobalVaribles.cur_freeplay_level = GlobalVaribles.LEVELS.find(cur_level) + 1
		
		if cur_dif != cur_level_type:
			cur_level_type = cur_dif
			
			$capsules.name = "to_del"
			$to_del.queue_free()
			var node = Control.new()
			node.position = Vector2(429, 256)
			node.name = "capsules"
			add_child(node)
			
			spawn_capsules()
			if get_cur_music() != "random":
				update_main_music()
		
		for capsule in $capsules.get_children():
			capsule.call_deferred("update_dif")
		spawn_score()
		spawn_stars()
		
		$difficulty.play(GlobalVaribles.difficulty)
		$dif_anim.play("change")
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
		$selector_r.scale = Vector2(0.6, 0.6)
		await get_tree().create_timer(0.1).timeout
		$selector_r.scale = Vector2(1, 1)
	elif Input.is_action_just_pressed("freeplay_favourite"):
		$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).change_fav()


func spawn_score():
	animate_score = true
	if get_cur_music() == "random":
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, "smooth_score", 0, 0.5)
		tween.parallel().tween_property(self, "smooth_rate", 0, 0.5)
		return
	if !SaveManager.game_data.levels_data.has(get_cur_music()):
		var level_dat = {}
		for dif in GlobalVaribles.freeplay_capsules_infos[get_cur_music()][0]:
			level_dat.merge({dif : [0, 0]})
		var old_score = {get_cur_music() : level_dat}
		var new_scores = SaveManager.game_data.levels_data.duplicate()
		new_scores.merge(old_score)
		SaveManager.game_data.levels_data = new_scores.duplicate()
	if !SaveManager.game_data.levels_data[get_cur_music()].has(GlobalVaribles.difficulty):
		SaveManager.game_data.levels_data[get_cur_music()].merge({str(GlobalVaribles.difficulty) : [0, 0]})
	if !SaveManager.game_data.levels_data[get_cur_music()].has("FAV"):
		SaveManager.game_data.levels_data[get_cur_music()].merge({"FAV" : false})
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "smooth_score", SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][0], 0.5)
	tween.parallel().tween_property(self, "smooth_rate", clamp(SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][1], 0, 100), 0.5)


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


func freeplay_end(anim_name):
	if anim_name == "show":
		$bf_anim.play("idle")
	else:
		$bf_anim.stop()
		GlobalVaribles.menu_layer = "main"
		queue_free()


func bf_animation_finished(anim_name): if anim_name == "start_level":
	get_parent().get_node("main_music").stop()
	GlobalFunctions.clear_level_infos()
	GlobalVaribles.story_info = {}
	SceneChanger.change_to("scenes/main_scenes/level")


func spawn_capsules():
	var vec = Vector2(0, -116 * GlobalVaribles.cur_freeplay_level)
	var dict_num = 0
	for level in levels_array:
		vec = Vector2(abs((GlobalVaribles.cur_freeplay_level - dict_num)) * -35, (GlobalVaribles.cur_freeplay_level - dict_num) * -116)
		if (GlobalVaribles.cur_freeplay_level - dict_num) > 1:
			vec.y -= 116
			vec.x = -35
		elif (GlobalVaribles.cur_freeplay_level - dict_num) < -3:
			vec.y += 116
			vec.x = 70
		elif (GlobalVaribles.cur_freeplay_level - dict_num) < 0:
			vec.x += 35
		spawn_capsule(level, dict_num, vec)
		dict_num += 1
	spawn_score()
	update_freeplay_btn()


func update_freeplay_btn():
	$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).active()
	var inst = 0
	for capsule in $capsules.get_children():
		capsule.vec = Vector2(abs(GlobalVaribles.cur_freeplay_level - inst) * -35, (GlobalVaribles.cur_freeplay_level - inst) * -116)
		if (GlobalVaribles.cur_freeplay_level - inst) > 1:
			capsule.vec.y -= 116
			capsule.vec.x = -35
		elif (GlobalVaribles.cur_freeplay_level - inst) < -3:
			capsule.vec.y += 116
			capsule.vec.x = -70
		elif (GlobalVaribles.cur_freeplay_level - inst) < 0:
			capsule.vec.x += 35
		inst += 1
	update_main_music()
	spawn_stars()


func spawn_stars():
	for child in $album.get_children():
		child.queue_free()
	
	if get_cur_music() == "random":
		return
	for i in 10:
		if i < int(GlobalVaribles.freeplay_capsules_infos[get_cur_music()][1][2][GlobalVaribles.difficulty]):
			if i + 10 < int(GlobalVaribles.freeplay_capsules_infos[get_cur_music()][1][2][GlobalVaribles.difficulty]):
				GlobalFunctions.add_particle($album, {
					"sprite_frames" : STARS,
					"position" : Vector2(i * 29 - 131, -131),
					"sprite_anim" : 2,
					"scale" : Vector2(0.7, 0.7),
				})
			else:
				GlobalFunctions.add_particle($album, {
					"sprite_frames" : STARS,
					"position" : Vector2(i * 29 - 131, -131),
					"sprite_anim" : 1,
					"scale" : Vector2(0.7, 0.7),
				})
		else:
			GlobalFunctions.add_particle($album, {
				"sprite_frames" : STARS,
				"position" : Vector2(i * 29 - 131, -131),
				"sprite_anim" : 0,
			})


func spawn_capsule(music_name, inst_name, vec):
	var capsule_inst = CAPSULE.instantiate()
	capsule_inst.music_name = music_name
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		capsule_inst.dif_type = "erect"
	capsule_inst.name = str(inst_name)
	capsule_inst.vec = vec
	
	if GlobalVaribles.cur_freeplay_level == inst_name:
		capsule_inst.start_anim = "active"
	$capsules.add_child(capsule_inst)


func get_cur_music():
	return levels_array[GlobalVaribles.cur_freeplay_level]


var smooth_score = 0
var smooth_rate = 0
func _process(delta):
	var mod = clamp(delta * 14, 0, 0.99)
	for capsule in $capsules.get_children():
		capsule.position += (capsule.vec - capsule.position) * mod
	
	if animate_score:
		spawn_score_data()


func spawn_score_data():
	var score = str(smooth_score)
	for i in 7 - score.length():
		score = "0" + score
	for letter in 7:
		if get_node("score/num" + str((score.length() - letter) - 1)).animation != score[letter]:
			get_node("score/num" + str((score.length() - letter) - 1)).play(score[letter])
	
	for child in $cleared_box.get_children():
		child.queue_free()
	var sep
	var rate = str(smooth_rate)
	for letter in rate.length():
		sep = (letter - rate.length() + 1) * 26 + 11
		if rate[letter] == "1":
			sep += 9
		GlobalFunctions.add_particle($cleared_box, {
			"sprite_frames" : CLEAR_NUMS,
			"sprite_anim" : rate[letter],
			"delete_on_end" : false,
			"position" : Vector2(sep, 9),
		})
	
	if get_cur_music() == "random":
		if smooth_score == 0 and smooth_rate == 0:
			animate_score = false
	elif smooth_score == SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][0] and smooth_rate == clamp(SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][1], 0, 100):
		animate_score = false


func update_main_music():
	get_parent().get_node("main_music").stop()
	$freeplay_music_time.stop()
	$music_load_time.start()


func play_freeplay_track():
	if get_cur_music() == "random":
		get_parent().get_node("main_music").stream = GlobalFunctions.load_thread("res://assets/music/menu/freeplay_random.ogg", "AudioStream")
	elif cur_level_type != "def":
		get_parent().get_node("main_music").stream = GlobalFunctions.load_thread("res://assets/songs/" + get_cur_music() + "/main-" + cur_level_type + ".ogg", "AudioStream")
	else:
		get_parent().get_node("main_music").stream = GlobalFunctions.load_thread("res://assets/songs/" + get_cur_music() + "/main.ogg", "AudioStream")
	$freeplay_music_time.wait_time = get_parent().get_node("main_music").stream.get_length() * 0.2
	$freeplay_music_time.start()
	get_parent().get_node("main_music_anim").play("up_volume")
	get_parent().get_node("main_music").play()


func freeplay_music_end():
	get_parent().get_node("main_music").stop()
	GlobalFunctions.add_audio_effect("res://assets/sounds/menu/options/channel_switch.ogg")
	await get_tree().create_timer(0.3).timeout
	get_parent().get_node("main_music").play()
	$freeplay_music_time.start()


func set_new_levels():
	levels_array = ["random"]
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		levels_array.append_array(GlobalVaribles.LEVELS_ERECT)
	else:
		levels_array.append_array(GlobalVaribles.LEVELS)
