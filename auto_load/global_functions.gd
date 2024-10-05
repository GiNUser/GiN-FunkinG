extends Node

const PARTICLE = preload("res://scenes/gameplay/particle.scn")
const AUDIO_EFFECT = preload("res://scenes/other/audio_effect.scn")

func _ready():
	GlobalVaribles.freeplay_capsules_infos = {"random" : [["easy", "normal", "hard", "erect", "nightmare"], ["", {"default" : 0, "erect" : 0}, {}]]}
	for level in GlobalVaribles.LEVELS:
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
			json.data.song_name,
		])
	
	AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
	AudioServer.set_bus_mute(0, !SaveManager.game_data.volume)
	AudioServer.set_bus_mute(2, !SaveManager.game_data.voices)
	Engine.time_scale = SaveManager.game_data.time_scale
	AudioServer.playback_speed_scale = SaveManager.game_data.time_scale
	
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	if SaveManager.game_data.fullscreen_on_start:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if SaveManager.game_data.max_fps != -1:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = SaveManager.game_data.max_fps
	if !SaveManager.game_data.start_intro:
		GlobalVaribles.menu_layer = "main"
	for action in SaveManager.game_data.input_map:
		var event = InputEventKey.new()
		event.keycode = SaveManager.game_data.input_map[action]
		InputMap.action_add_event(action, event)


func load_thread(path, hint):
	ResourceLoader.load_threaded_request(path, hint, true)
	return ResourceLoader.load_threaded_get(path)


func add_audio_effect(variant, volume = 0, audio_process_mode = PROCESS_MODE_INHERIT): if SaveManager.game_data.sounds:
	var audio_inst = AUDIO_EFFECT.instantiate()
	if variant is AudioStreamOggVorbis:
		audio_inst.stream = variant
	else:
		audio_inst.stream = load_thread(variant, "AudioStreamOggVorbis")
	audio_inst.volume_db = volume
	audio_inst.process_mode = audio_process_mode
	audio_inst.add_to_group("sound")
	get_tree().root.call_deferred("add_child", audio_inst)


func clear_sounds():
	for node in get_tree().root.get_children():
		if node.is_in_group("sound"):
			node.queue_free()


func add_particle(node, data):
	var sprite_inst = PARTICLE.instantiate()
	for varible in data:
		match varible:
			"add_to_group":
				for group in data[varible]:
					sprite_inst.add_to_group(group)
				continue
			"sprite_frames":
				sprite_inst.get_node("anim_sprite").sprite_frames = data[varible]
				continue
			"animation_speed":
				sprite_inst.get_node("anim_player").speed_scale = data[varible]
				continue
		sprite_inst[varible] = data[varible]
	node.call_deferred("add_child", sprite_inst)


func load_story(scenario, story_name):
	GlobalVaribles.story_info = {
		"full_scenario" = scenario.duplicate(),
		"scenario" = scenario,
		"name" = story_name,
	}


func clear_level_infos():
	GlobalVaribles.level_infos = {
	"score" : 0,
	"sick" : 0,
	"good" : 0,
	"bad" : 0,
	"shit" : 0,
	"missed" : 0,
	"max_combo" : 0,
	"total_notes" : 0,
	}


func add_level_infos(data):
	for varible in data:
		if varible == "max_combo":
			if data[varible] > GlobalVaribles.level_infos[varible]:
				GlobalVaribles.level_infos[varible] = data[varible]
		else:
			GlobalVaribles.level_infos[varible] += data[varible]
