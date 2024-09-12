extends Node

const ANIM_SPRITE = preload("res://scenes/gameplay/animated_sprite.scn")
const AUDIO_EFFECT = preload("res://scenes/other/audio_effect.scn")

func _ready():
	if SaveManager.game_data.max_fps == -1:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
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


func add_audio_effect(variant, volume = 0, audio_process_mode = PROCESS_MODE_INHERIT):
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


func add_anim_sprite(node, data):
	var sprite_inst = ANIM_SPRITE.instantiate()
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


func load_story(scenario):
	GlobalVaribles.story_info.is_story = true
	GlobalVaribles.story_info.scenario = scenario


func unload_story():
	GlobalVaribles.story_info = {
		"is_story" : false,
		"scenario" : [],
	}


func add_level_infos(data):
	for varible in data:
		if varible == "max_combo":
			if data[varible] > GlobalVaribles.level_infos[varible]:
				GlobalVaribles.level_infos[varible] = data[varible]
		else:
			GlobalVaribles.level_infos[varible] += data[varible]


func clear_level_infos():
	GlobalVaribles.level_infos = {
		"score" : 0, "sick" : 0, "good" : 0, "bad" : 0, "shit" : 0, "missed" : 0, "max_combo" : 0, "total_notes" : 0, "rate" : 0
	}


func reset():
	if !GlobalVaribles.story_info.is_story:
		clear_level_infos()
	clear_sounds()
	SceneChanger.change_to("")
