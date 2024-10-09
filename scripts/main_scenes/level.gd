extends Node2D

const CHARACTER = preload("res://scenes/levels/objects/character.scn")

signal json_loaded

signal health_updated(health)
signal score_updated(score)
signal combo_updated(combo, breaked)

signal _on_beat(beat)
signal _on_measure(measure)
signal bop_anim_played

var chart = {}
var note_speed = 0

var bpm = 0
var bps = 0
var stb = 0

var measure = 0
var beat = 0

var song_position = 0.0
var song_position_in_beats = 0
var last_beat = 0
var t = -4000

var sick = 0
var good = 0
var bad = 0
var shit = 0
var missed = 0
var combo = 0
var total_notes = 0

var max_combo = 0
var max_health = 100.0
var health
var state = 0

var start_pos = 4
var score = 0.0

var bop_on_beats = [1.0]
var bop_power = Vector2(1.025, 1.025)
var tween_bop : Tween

func _enter_tree():
	if get_tree().root.has_node("last_frame"):
		get_tree().root.get_node("last_frame").queue_free()
	if GlobalVaribles.story_info:
		GlobalVaribles.level_dict_name = GlobalVaribles.story_info.scenario[0][1]
	var dict_name = GlobalVaribles.level_dict_name
	var json = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/songs/" + dict_name + "/data.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())
	var type = "default"
	if ["erect", "nightmare"].has(GlobalVaribles.difficulty):
		type = "erect"
	chart = json
	chart.notes = json.notes[GlobalVaribles.difficulty]
	chart.events = json.events[type]
	chart.data.difficulties = chart.data.difficulties[type]
	note_speed = (chart.data.difficulties.difs[GlobalVaribles.difficulty][0] / 2.2) / AudioServer.playback_speed_scale
	bpm = chart.data.difficulties.bpm
	bps = bpm / 60.0
	stb = 1 / bps
	GlobalVaribles.level_name = chart.data.song_name
	preload_style()
	
	for stream in ["main", "opponent", "player"]:
		if type != "default":
			get_node(stream + "_stream").stream = GlobalFunctions.load_thread("res://assets/songs/" + dict_name + "/" + stream + "-" + type + ".ogg", "AudioStream")
		else:
			get_node(stream + "_stream").stream = GlobalFunctions.load_thread("res://assets/songs/" + dict_name + "/" + stream + ".ogg", "AudioStream")
	if SaveManager.game_data.adaptive_health:
		match GlobalVaribles.difficulty:
			"easy": max_health = 130.0
			"normal": max_health = 115.0
			"hard": max_health = 100.0
			"erect": max_health = 75.0
			"nightmare": max_health = 50.0
	health = max_health / 2.0
	if !GlobalVaribles.preloaded_stages.has([chart.data.stage]):
		GlobalVaribles.preloaded_stages.merge({chart.data.stage : GlobalFunctions.load_thread("res://scenes/levels/stages/" + chart.data.stage + ".scn", "PackedScene")})
	var stage_inst = GlobalVaribles.preloaded_stages[chart.data.stage].instantiate()
	#stage_inst.z_index = -8
	for character in chart.data.characters:
		var character_inst = CHARACTER.instantiate()
		character_inst.position = stage_inst.get_node(character + "_pos").position
		character_inst.name = character
		character_inst.character = chart.data.characters[character]
		if character == "girlfriend":
			character_inst.sing = false
		else:
			character_inst.z_index = 1
		if character == "opponent":
			character_inst.left = 4
			character_inst.down = 5
			character_inst.up = 6
			character_inst.right = 7
		
		character_inst.get_node("event_manager").add_events(chart.events)
		
		stage_inst.call_deferred("add_child", character_inst)
		stage_inst.get_node(character + "_pos").queue_free()
	call_deferred("add_child", stage_inst)
	
	$event_manager.add_events(chart.events)
	$camera/event_manager.add_events(chart.events)
	
	if SaveManager.game_data.centered_arrows:
		$notes_anim_player.play("start_centered")
	else:
		$notes_anim_player.play("start")


func _ready():
	json_loaded.emit()
	update_health()
	score_updated.emit(score)


func _process(_delta): if !state:
	if $main_stream.playing:
		song_position = ($main_stream.get_playback_position() + AudioServer.get_time_since_last_mix()) - AudioServer.get_output_latency()
		song_position_in_beats = int(song_position / stb)
		t = song_position * 1000
		check_beat()


func check_beat():
	if song_position_in_beats <= last_beat:
		return
	
	beat += 1
	if beat > 4:
		measure += 1
		if measure > 4:
			measure = 1
		_on_measure.emit(measure)
		beat = 1
	
	if bop_on_beats.has(float(beat)):
		play_bop()
	
	_on_beat.emit(beat)
	last_beat = song_position_in_beats


func _input(_event): if state == 1:
	if Input.is_action_just_pressed("accept"):
		$stage/player/anim_player.stop()
		$stage/player/anim_player.play("dead_confirm")
		if has_node("game-over-stream"):
			$"game-over-stream".queue_free()
		GlobalFunctions.clear_sounds()
		GlobalFunctions.add_audio_effect("res://assets/music/gameover/def-end.ogg", 0, PROCESS_MODE_ALWAYS)
		state = 2
		await get_tree().create_timer(1).timeout
		SceneChanger.change_to("", "fade")
	elif Input.is_action_just_pressed("cancel"):
		state = 2
		GlobalFunctions.create_last_frame(ImageTexture.create_from_image(get_viewport().get_texture().get_image()))
		get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")


func add_stat(variant, score_to_add = 0):
	if variant:
		self[variant] += 1
		score += score_to_add
		var combo_break = false
		match variant:
			"sick":
				update_health(2.5)
				combo += 1
			"good":
				update_health(1)
				combo += 1
			"bad":
				combo_break = combo >= 10
				combo = 0
			"shit":
				update_health(-2)
				combo_break = combo >= 10
				combo = 0
			"missed":
				score -= 20
				update_health(-4)
				combo_break = combo >= 10
				combo = 0
				$player_stream.stop()
		if variant != "missed" and !$player_stream.playing:
			$player_stream.play($main_stream.get_playback_position())
		if combo > max_combo:
			max_combo = combo
		combo_updated.emit(combo, combo_break)
	else:
		score -= 10
		update_health(-3)
	score_updated.emit(score)


func tale_hold(delta):
	score += (delta / note_speed) * 3
	update_health((delta / note_speed) / 7.5)
	score_updated.emit(score)
	if !$player_stream.playing:
		$player_stream.play($main_stream.get_playback_position())


func _on_music_stream_finished():
	GlobalFunctions.clear_sounds()
	var rate = 0.0
	rate += sick
	rate += good
	rate += bad / 2.0
	rate += shit / 4.0
	rate = floor((rate / float(total_notes)) * 100.0)
	if sick == total_notes:
		rate = 101
	GlobalFunctions.add_level_infos({"score" : score, "sick" : sick, "good" : good, "bad" : bad, "shit" : shit,
		"missed" : missed, "max_combo" : max_combo, "total_notes" : total_notes})
	if SaveManager.game_data.time_scale == 1.0:
		if !SaveManager.game_data.levels_data.has(GlobalVaribles.level_dict_name):
			var level_dat = {}
			for dif in GlobalVaribles.freeplay_capsules_infos[GlobalVaribles.level_dict_name][0]:
				level_dat.merge({dif : [0, 0]})
			var old_score = {GlobalVaribles.level_dict_name : level_dat}
			var new_scores = SaveManager.game_data.levels_data.duplicate()
			new_scores.merge(old_score)
			SaveManager.game_data.levels_data = new_scores.duplicate()
		if !SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name].has(GlobalVaribles.difficulty):
			SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name].merge({str(GlobalVaribles.difficulty) : [0, 0]})
		
		if round(score) > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0]:
			SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0] = round(score)
		if rate > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][1]:
			SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][1] = rate
	if GlobalVaribles.story_info:
		GlobalVaribles.story_info.scenario.remove_at(0)
		if !GlobalVaribles.story_info.scenario.size():
			if SaveManager.game_data.time_scale == 1.0:
				if round(GlobalVaribles.level_infos.score) > SaveManager.game_data.storys_data[GlobalVaribles.story_info.name][GlobalVaribles.difficulty][0]:
					SaveManager.game_data.storys_data[GlobalVaribles.story_info.name][GlobalVaribles.difficulty][0] = round(GlobalVaribles.level_infos.score)
				
				var story_rate = 0.0
				story_rate += GlobalVaribles.level_infos.sick
				story_rate += GlobalVaribles.level_infos.good
				story_rate += GlobalVaribles.level_infos.bad / 2.0
				story_rate += GlobalVaribles.level_infos.shit / 4.0
				story_rate = floor((story_rate / float(GlobalVaribles.level_infos.total_notes)) * 100.0)
				if story_rate > SaveManager.game_data.storys_data[GlobalVaribles.story_info.name][GlobalVaribles.difficulty][1]:
					SaveManager.game_data.storys_data[GlobalVaribles.story_info.name][GlobalVaribles.difficulty][1] = story_rate
		else:
			SceneChanger.change_to("scenes/main_scenes/" + GlobalVaribles.story_info.scenario[0][0])
	SaveManager.save_data()
	get_node("ui").music_finished()


func update_health(mod = 0.0):
	health += mod
	health = clamp(health, 0, max_health)
	health_updated.emit(health)
	if health <= 0:
		state = 1
		$stage.set_script(null)
		GlobalFunctions.clear_sounds()
		
		if has_node("event_manager"):
			$event_manager.queue_free()
		$ui.queue_free()
		$main_stream.queue_free()
		$player_stream.queue_free()
		$opponent_stream.queue_free()
		$stage/player.disconnect_arrows()
		$note_lines.queue_free()
		
		for child in $stage.get_children(): if child.name != "player":
			child.queue_free()
		
		if has_node("camera/event_manager"):
			$camera/event_manager.queue_free()
		$camera.set_target("player", 1)
		
		$stage/player.events = []
		$stage/player.ignore_beats = true
		$stage/player/anim_player.stop()
		$stage/player/anim_player.play("dead")
		
		GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/game-over/loss-def.ogg")
		await get_tree().create_timer(2.08).timeout
		if state == 2:
			return
		var music_player = AudioStreamPlayer.new()
		music_player.stream = GlobalFunctions.load_thread("res://assets/music/gameover/def.ogg", "AudioStream")
		music_player.name = "game-over-stream"
		music_player.autoplay = true
		call_deferred("add_child", music_player)


func get_opponent_note_damage():
	if health > max_health * 0.25:
		update_health(-1.5)


func get_opponent_tale_damage(delta):
	if health > max_health * 0.25:
		update_health(-(delta / note_speed) / 7.5)


func _on_anim_player_animation_finished(_anim_name):
	$notes_anim_player.queue_free()


func set_bop(bop_on, mod):
	bop_on_beats = bop_on
	var _var = mod * 0.025 + 1
	bop_power = Vector2(_var, _var)
	$camera.set_bop_power(mod)


func unpaused():
	var unpause_time = $main_stream.get_playback_position() - (AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency())
	if unpause_time > 0:
		$main_stream.play(unpause_time)
		$opponent_stream.play(unpause_time)
		$player_stream.play(unpause_time)
	for note_line in $note_lines.get_children():
		note_line.unpaused()


func play_bop(): if SaveManager.game_data.zoom_on_bop:
	$note_lines.scale = bop_power
	if tween_bop:
		tween_bop.kill()
	tween_bop = create_tween()
	tween_bop.tween_property($note_lines, "scale", Vector2(1, 1), stb).set_ease(Tween.EASE_OUT)
	bop_anim_played.emit()


func preload_style():
	var style = chart.data.style
	if !GlobalVaribles.preloaded_styles.has(style):
		GlobalVaribles.preloaded_styles.merge({style : {}})
		for data in ["strum_line", "splash", "tale_splash", "rate", "hold", "start", "nums"]:
			GlobalVaribles.preloaded_styles[style].merge({data : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + style + "/" + data + ".res", "SpriteFrames")})
