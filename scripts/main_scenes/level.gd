extends Node2D

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const ANIM_SPRITE = preload("res://scenes/gameplay/animated_sprite.scn")
const CHARACTER = preload("res://scenes/levels/objects/character.scn")

signal json_loaded

signal health_updated(health)
signal score_updated(score)
signal combo_updated(combo, breaked)

signal _on_beat(beat)
signal _on_measure(measure)
signal bop_anim_played

var chart = {}

var chart_path
var note_speed = 0

var bpm = 0
var bps = 0
var stb = 0

var measures = 4
var beats = 4
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

var max_health = 100.0
var health
var state = 0

var combo = 0
var max_combo = 0

var total_notes = 0
var start_pos = 4
var score = 0.0

var start = true

var bop_on_beats = [1.0]

var bop_power = Vector2(1.025, 1.025)
var tween_bop : Tween

func _enter_tree():
	if get_tree().root.has_node("last_frame"):
		get_tree().root.get_node("last_frame").queue_free()
	if GlobalVaribles.story_info.is_story:
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
	t = stb * -5000
	for stream in ["main", "opponent", "player"]:
		if type != "default":
			get_node(stream + "_stream").stream = GlobalFunctions.load_thread("res://assets/songs/" + dict_name + "/" + stream + "-" + type + ".ogg", "AudioStream")
		else:
			get_node(stream + "_stream").stream = GlobalFunctions.load_thread("res://assets/songs/" + dict_name + "/" + stream + ".ogg", "AudioStream")
	if SaveManager.game_data.adaptive_health:
		match GlobalVaribles.difficulty:
			"easy": max_health = 130.0
			"normal": max_health = 100.0
			"hard": max_health = 80.0
			"erect": max_health = 65.0
			"nightmare": max_health = 55.0
	health = max_health / 2.0
	if !GlobalVaribles.preloaded_stages.has([chart.data.stage]):
		GlobalVaribles.preloaded_stages.merge({chart.data.stage : GlobalFunctions.load_thread("res://scenes/levels/stages/" + chart.data.stage + ".scn", "PackedScene")})
	var stage_inst = GlobalVaribles.preloaded_stages[chart.data.stage].instantiate()
	stage_inst.z_index = -8
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
	score_updated.emit(score)
	update_health()
	json_loaded.emit()
	$start_delay.wait_time = stb
	$start_delay.start()


func _process(delta):
	if has_node("main_stream"):
		if $main_stream.playing:
			song_position = ($main_stream.get_playback_position() + AudioServer.get_time_since_last_mix()) - AudioServer.get_output_latency()
			song_position_in_beats = int(song_position / stb)
			t = song_position * 1000
			_check_beat()
		elif start:
			t += delta * 1000
			song_position = (t + stb * 5000) / 1000
			song_position_in_beats = int(song_position / stb)


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
	elif Input.is_action_just_pressed("esc"):
		state = 2
		if GlobalVaribles.story_info.is_story:
			SceneChanger.change_to("scenes/main_scenes/menu", "fade")
			return
		await RenderingServer.frame_post_draw
		var texture_rect = TextureRect.new()
		texture_rect.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
		texture_rect.name = "last_frame"
		texture_rect.size = DisplayServer.screen_get_size()
		get_tree().root.call_deferred("add_child", texture_rect)
		get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")


func _check_beat():
	if song_position_in_beats > last_beat:
		beat += 1
		if beat > beats:
			measure += 1
			if measure > measures:
				measure = 1
			_on_measure.emit(measure)
			beat = 1
		
		if bop_on_beats.has(float(beat)):
			play_bop()
		
		_on_beat.emit(beat)
		last_beat = song_position_in_beats


func _on_start_delay_timeout():
	if start_pos != 0:
		GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/intro/" + chart.data.style + "/" + str(start_pos - 1) + ".ogg", -10)
		if start_pos != 4:
			$ui.emit_start(start_pos - 1)
		_on_beat.emit(beat)
		beat += 1
	else:
		$start_delay.queue_free()
		start = false
		last_beat = 0
		_on_beat.emit(4)
		
		if bop_on_beats.has(4.0):
			play_bop()
		
		for stream in ["main", "opponent", "player"]:
			get_node(stream + "_stream").play()
	start_pos -= 1


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
				if combo >= 10:
					combo_break = true
				combo = 0
			"shit":
				update_health(-2)
				if combo >= 10:
					combo_break = true
				combo = 0
			"missed":
				score -= 20
				update_health(-4)
				if combo >= 10:
					combo_break = true
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
	var rate = 0.0
	rate += sick
	rate += good
	rate += bad / 2.0
	rate += shit / 4.0
	rate = floor((rate / float(total_notes)) * 100.0)
	if sick == total_notes:
		rate = 101
	if rate > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][1]:
		SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][1] = rate
		SaveManager.save_data()
	if round(score) > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0]:
		SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0] = round(score)
		SaveManager.save_data()
	GlobalFunctions.add_level_infos({"score" : score, "sick" : sick, "good" : good, "bad" : bad, "shit" : shit,
		"missed" : missed, "max_combo" : max_combo, "total_notes" : total_notes, "rate" : rate})
	if GlobalVaribles.story_info.is_story:
		GlobalVaribles.story_info.scenario.remove_at(0)
		if GlobalVaribles.story_info.scenario.size() != 0:
			SceneChanger.change_to("scenes/main_scenes/" + GlobalVaribles.story_info.scenario[0][0])
	get_node("ui").music_finished()


func spawn_sprite_text(text = "", pos = Vector2.ZERO, node = self, from_right_to_left = false):
	var letter_pos = 0
	for letter in text:
		var letter_inst = ANIM_SPRITE.instantiate()
		letter_inst.sprite_frames = LETTERS_SPRITE_FRAMES
		if letter == " ":
			letter_pos += 1
			continue
		else:
			letter_inst.special_frame = letter.to_lower().to_ascii_buffer()[0] - 97
		letter_inst.delete_on_end = false
		if from_right_to_left:
			letter_inst.position = pos - Vector2(28 * (text.length() - letter_pos), 0)
		else:
			letter_inst.position = pos + Vector2(28 * letter_pos, 0)
		letter_inst.scale = Vector2(0.7, 0.7)
		node.call_deferred("add_child", letter_inst)
		letter_pos += 1


func update_health(mod = 0.0):
	health += mod
	health = clamp(health, 0, max_health)
	health_updated.emit(health)
	if health <= 0:
		GlobalFunctions.clear_sounds()
		$stage.set_script(null)
		if has_node("event_manager"):
			$event_manager.queue_free()
		$ui.queue_free()
		
		$main_stream.queue_free()
		$player_stream.queue_free()
		$opponent_stream.queue_free()
		
		$note_lines.queue_free()
		for child in $stage.get_children():
			if child.name != "player":
				child.queue_free()
			else:
				child.events = []
				child.ignore_beats = true
		$camera.set_target("player", 1)
		if has_node("camera/event_manager"):
			$camera/event_manager.queue_free()
		GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/game-over/loss-def.ogg")
		state = 1
		await get_tree().create_timer(0.01).timeout
		$stage/player/anim_player.stop()
		$stage/player/anim_player.play("dead")
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


func set_bop_power(mod):
	var _var = mod * 0.025 + 1
	bop_power = Vector2(_var, _var)
	$camera.set_bop_power(mod)


func unpaused():
	if $main_stream.get_playback_position() - (AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()) > 0:
		$main_stream.play($main_stream.get_playback_position() - (AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()))
		$opponent_stream.play($main_stream.get_playback_position())
		$player_stream.play($main_stream.get_playback_position())
	for note_line in $note_lines.get_children():
		note_line.unpaused()


func play_bop(): if SaveManager.game_data.zoom_on_bop:
	$note_lines.scale = bop_power
	if tween_bop:
		tween_bop.kill()
	tween_bop = create_tween()
	tween_bop.tween_property($note_lines, "scale", Vector2(1, 1), stb).set_ease(Tween.EASE_OUT)
	bop_anim_played.emit()
