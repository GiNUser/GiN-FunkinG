extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")

@onready var level = get_tree().root.get_node("level")
var cur_btn = 0

func _ready():
	get_tree().paused = true
	if level.chart.data.has("pause_music"):
		$track.stream = GlobalFunctions.load_thread("res://assets/" + level.chart.data.pause_music, "AudioStream")
	spawn_sprite_text("resume", Vector2(0, 50), $container/pause, false, 0.7)
	spawn_sprite_text("main menu", Vector2(0, 50), $container/main_menu, false, 0.7)
	spawn_sprite_text(level.chart.data.song_name, Vector2(0, 40), $current_music_name, true, 0.7)
	spawn_sprite_text(GlobalVaribles.difficulty, Vector2(-8, 80), $current_music_name, true, 0.35, 16)
	update_cur_pause_btn()


func _input(_event):
	if Input.is_action_just_pressed("restart"):
		GlobalFunctions.reset()
	elif Input.is_action_just_pressed("accept"):
		match cur_btn:
			0:
				get_tree().paused = false
				get_tree().root.get_node("level").unpaused()
				call_deferred("queue_free")
			1:
				$track.stop()
				GlobalFunctions.clear_sounds()
				GlobalFunctions.unload_story()
				GlobalFunctions.clear_level_infos()
				GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM)
				if GlobalVaribles.story_info.is_story:
					SceneChanger.change_to("scenes/main_scenes/menu")
					return
				await RenderingServer.frame_post_draw
				var texture_rect = TextureRect.new()
				texture_rect.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
				texture_rect.name = "last_frame"
				texture_rect.size = DisplayServer.screen_get_size()
				get_tree().root.add_child(texture_rect)
				get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")
	elif Input.is_action_just_pressed("up"):
		cur_btn += 1
		if cur_btn > 1:
			cur_btn = 0
		update_cur_pause_btn()
	elif Input.is_action_just_pressed("down"):
		cur_btn -= 1
		if cur_btn < 0:
			cur_btn = 1
		update_cur_pause_btn()


func update_cur_pause_btn():
	for child_id in $container.get_child_count():
		$container.get_child(child_id).modulate = Color.GRAY
	$container.get_child(cur_btn).modulate = Color.WHITE
	GlobalFunctions.add_audio_effect("res://assets/sounds/menu/scroll.ogg", -10, PROCESS_MODE_ALWAYS)


func spawn_sprite_text(text = "", pos = Vector2.ZERO, node = self, from_right_to_left = false, inst_scale = 1.0, space = 28.0):
	var letter_pos = 0
	for letter in text:
		if [" ", "2"].has(letter):
			letter_pos += 1
			continue
		var inst_pos
		if from_right_to_left:
			inst_pos = pos - Vector2(space * (text.length() - letter_pos), 0)
		else:
			inst_pos = pos + Vector2(space * letter_pos, 0)
		if letter == ".":
			inst_pos.y += 12
		GlobalFunctions.add_anim_sprite(node, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"delete_on_end" : false,
			"scale" : Vector2(inst_scale, inst_scale),
			"position" : inst_pos,
			"sprite_anim" : letter.to_lower()
		})
		letter_pos += 1
