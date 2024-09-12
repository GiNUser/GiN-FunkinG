extends Control

const ANIM_SPRITE = preload("res://scenes/gameplay/animated_sprite.scn")
const CAPSULE = preload("res://scenes/interface/capsule.scn")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")
const DIGITAL_NUMS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/digital_nums.res")
const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const CLEAR_NUMS = preload("res://assets/resources/sprite_frames/anim_sprite/freeplay_clear.res")

const LEVELS = ["tutorial", "bopeebo", "fresh", "dadbattle", "spookeez", "south", "monster",
	"pico", "philly-nice", "blammed", "satin-panties", "high", "milf", "cocoa",
	"eggnog", "winter-horrorland", "senpai", "roses", "thorns", "ugh", "guns",
	"stress"]#, "darnell", "lit-up", "2hot"]

const LEVELS_ERECT = ["bopeebo", "fresh", "dadbattle", "spookeez", "south", "pico", "philly-nice",
"blammed", "satin-panties", "high", "eggnog", "senpai", "roses", "thorns"]

var cur_level_type = "def"
var levels_array = []
var tween : Tween
var animate_score = false

func _ready():
	if GlobalVaribles.freeplay_capsules_infos.is_empty():
		GlobalVaribles.freeplay_capsules_infos = {"random" : [["easy", "normal", "hard", "erect", "nightmare"], ["", {"default" : 0, "erect" : 0}, {}]]}
		for level in LEVELS:
			GlobalVaribles.freeplay_capsules_infos.merge({level : [[]]})
			var json = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/songs/" + level + "/data.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())
			for dif_type in json.data.difficulties:
				for dif in json.data.difficulties[dif_type].difs:
					GlobalVaribles.freeplay_capsules_infos[level][0].append(dif)
			var bpm = {}
			for dif_type in json.data.difficulties:
				bpm.merge({dif_type : json.data.difficulties[dif_type].bpm})
			var rates = {}
			for dif_type in json.data.difficulties:
				for dif in json.data.difficulties[dif_type].difs:
					if json.data.difficulties[dif_type].difs.has(dif):
						rates.merge({dif : json.data.difficulties[dif_type].difs[dif][1]})
			GlobalVaribles.freeplay_capsules_infos[level].append([
				json.data.characters.opponent,
				bpm,
				rates,
			])
	
	spawn_sprite_text("freeplay", Vector2(20, 27.5), $top_bar)
	spawn_sprite_text("original ost", Vector2(1285, 27.5), $top_bar, true)
	
	$anim_player.play("show")
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		cur_level_type = "erect"
	set_new_levels()
	spawn_capsules()
	$difficulty.play(GlobalVaribles.difficulty)
	get_parent().get_node("main_music").volume_db = -80
	update_main_music()
	if get_tree().root.has_node("last_frame"):
		await $anim_player.animation_finished
		get_tree().root.get_node("last_frame").queue_free()


func _input(_event):
	if GlobalVaribles.menu_layer != "freeplay":
		return
	if Input.is_action_just_pressed("accept"):
		if get_cur_music() == "random":
			GlobalVaribles.cur_freeplay_level = randi_range(1, $capsules.get_child_count())
			update_freeplay_btn()
		GlobalVaribles.level_dict_name = get_cur_music()
		$bf_anim.play("start_level")
		get_parent().get_node("main_music").stop()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("esc"):
		$anim_player.play("hide")
		get_parent().update_menu_btns()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL, 0, PROCESS_MODE_ALWAYS)
		get_parent().get_node("main_music").stream = GlobalFunctions.load_thread("res://assets/music/menu/main.ogg", "AudioStream")
		get_parent().get_node("main_music").play()
		$freeplay_music_time.stop()
		$music_load_time.stop()
		get_parent().get_node("beat_anim").stop()
		get_parent().get_node("beat_anim").play()
		get_parent().get_node("main").show()
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
				var cur_level = LEVELS[GlobalVaribles.cur_freeplay_level - 1]
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
					var cur_level = LEVELS_ERECT[GlobalVaribles.cur_freeplay_level - 1]
					GlobalVaribles.cur_freeplay_level = LEVELS.find(cur_level) + 1
		
		if cur_dif != cur_level_type:
			cur_level_type = cur_dif
			
			$capsules.name = "to_del"
			$to_del.queue_free()
			var node = Control.new()
			node.position = Vector2(429, 256)
			node.name = "capsules"
			add_child(node)
			
			spawn_capsules()
			update_main_music()
		
		for capsule in $capsules.get_children():
			capsule.update_dif()
		spawn_score()
		
		$difficulty.play(GlobalVaribles.difficulty)
		$dif_anim.play("change")
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
		$selector_l.scale = Vector2(0.7, 0.7)
		await get_tree().create_timer(0.1).timeout
		$selector_l.scale = Vector2(1, 1)
	elif Input.is_action_just_pressed("right"):
		var to_dif = ["easy", "normal", "hard", "erect", "nightmare"].find(GlobalVaribles.difficulty) + 1
		var cur_dif = "def"
		GlobalVaribles.difficulty = ["easy", "normal", "hard", "erect", "nightmare", "easy"][to_dif]
		set_new_levels()
		match to_dif:
			3:
				var cur_level = LEVELS[GlobalVaribles.cur_freeplay_level - 1]
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
					var cur_level = LEVELS_ERECT[GlobalVaribles.cur_freeplay_level - 1]
					GlobalVaribles.cur_freeplay_level = LEVELS.find(cur_level) + 1
		
		if cur_dif != cur_level_type:
			cur_level_type = cur_dif
			
			$capsules.name = "to_del"
			$to_del.queue_free()
			var node = Control.new()
			node.position = Vector2(429, 256)
			node.name = "capsules"
			add_child(node)
			
			spawn_capsules()
			update_main_music()
		
		for capsule in $capsules.get_children():
			capsule.call_deferred("update_dif")
		spawn_score()
		
		$difficulty.play(GlobalVaribles.difficulty)
		$dif_anim.play("change")
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
		$selector_r.scale = Vector2(0.7, 0.7)
		await get_tree().create_timer(0.1).timeout
		$selector_r.scale = Vector2(1, 1)
	elif Input.is_action_just_pressed("freeplay_favourite"):
		$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).change_fav()


func update_freeplay_btn():
	$capsules.get_node(str(GlobalVaribles.cur_freeplay_level)).active()
	var cont = 0
	for capsule in $capsules.get_children():
		capsule.vec = Vector2(abs(GlobalVaribles.cur_freeplay_level - cont) * -35, (GlobalVaribles.cur_freeplay_level - cont) * -116)
		if (GlobalVaribles.cur_freeplay_level - cont) > 1:
			capsule.vec.y -= 116
			capsule.vec.x = -35
		elif (GlobalVaribles.cur_freeplay_level - cont) < -3:
			capsule.vec.y += 116
			capsule.vec.x = -70
		elif (GlobalVaribles.cur_freeplay_level - cont) < 0:
			capsule.vec.x += 35
		cont += 1
	update_main_music()


func spawn_score():
	animate_score = true
	if get_cur_music() == "random":
		if tween:
			tween.kill()
		tween = create_tween()
		tween.parallel().tween_property(self, "smooth_score", 0, 0.5)
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
	tween.parallel().tween_property(self, "smooth_score", SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][0], 0.5)
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
		GlobalFunctions.add_anim_sprite(node,
		{
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
	SceneChanger.change_to("scenes/main_scenes/level")


func spawn_capsules():
	var vec = Vector2(0, -116 * GlobalVaribles.cur_freeplay_level)
	if GlobalVaribles.cur_freeplay_level != 0:
		vec.x = -35
		if GlobalVaribles.cur_freeplay_level > 1:
			vec.y -= 116
	spawn_capsule("random", 0, vec)
	
	var dict_num = 1
	for level in levels_array:
		if level == "random":
			continue
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


func spawn_capsule(_music_name, _name, _vec):
	var capsule_inst = CAPSULE.instantiate()
	capsule_inst.music_name = _music_name
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		capsule_inst.dif_type = "erect"
	capsule_inst.name = str(_name)
	capsule_inst.vec = _vec
	
	if GlobalVaribles.cur_freeplay_level == _name:
		capsule_inst.start_anim = "active"
	$capsules.call_deferred("add_child", capsule_inst)


func get_cur_music():
	return levels_array[GlobalVaribles.cur_freeplay_level]


var smooth_score = 0
var smooth_rate = 0
func _process(delta):
	for capsule in $capsules.get_children():
		capsule.position += (capsule.vec - capsule.position) * delta * 14
	
	if animate_score:
		spawn_score_data()


func spawn_score_data():
	var score = str(smooth_score)
	for i in 7 - score.length():
		score = "0" + score
	for letter in 7:
		if get_node("score/num" + str((score.length() - letter) - 1)).animation != score[letter]:
			get_node("score/num" + str((score.length() - letter) - 1)).play(score[letter])
	
	var sep
	for child in $cleared_box.get_children():
		child.queue_free()
	var rate = str(smooth_rate)
	for letter in rate.length():
		sep = (letter - rate.length() + 1) * 26 + 11
		if rate[letter] == "1":
			sep += 9
		GlobalFunctions.add_anim_sprite($cleared_box, {
			"sprite_frames" : CLEAR_NUMS,
			"sprite_anim" : rate[letter],
			"delete_on_end" : false,
			"position" : Vector2(sep, 9),
		})
	
	if get_cur_music() == "random":
		if smooth_score == 0 and smooth_rate == 0:
			animate_score = false
	elif smooth_score == SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][0] and smooth_rate == SaveManager.game_data.levels_data[get_cur_music()][GlobalVaribles.difficulty][1]:
		animate_score = false


func update_main_music():
	get_parent().get_node("main_music").stop()
	$freeplay_music_time.stop()
	$music_load_time.start(0.0)


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
		levels_array.append_array(LEVELS_ERECT)
	else:
		levels_array.append_array(LEVELS)
