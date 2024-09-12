extends Control

const LETTERS = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const NUMS = preload("res://assets/resources/sprite_frames/anim_sprite/nums.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")

const DATA = {
	"total_notes" : [Vector2(391, 171), Color.WHITE],
	"max_combo" : [Vector2(391, 221), Color.WHITE],
	"sick" : [Vector2(247, 296), "89e59e"],
	"good" : [Vector2(228, 352), "89c9e5"],
	"bad" : [Vector2(207, 404), "e6cf8a"],
	"shit" : [Vector2(237, 458), "e68c8a"],
	"missed" : [Vector2(277, 515), "c68ae6"],
}

func _ready():
	GlobalFunctions.clear_sounds()
	$result_offset_timer.start()
	$gf_idle_timer.start()
	$difficulty.play(GlobalVaribles.difficulty)
	get_tree().paused = true
	
	if GlobalVaribles.level_infos.rate <= 59:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/loss-intro.ogg", "AudioStreamOggVorbis")
	elif GlobalVaribles.level_infos.rate >= 90 and GlobalVaribles.level_infos.rate < 100:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/excellent-intro.ogg", "AudioStreamOggVorbis")
	$music.play()


func _input(_event):
	if Input.is_action_just_pressed("restart"):
		GlobalFunctions.reset()
	elif Input.is_action_just_pressed("accept"):
		$music.stop()
		GlobalFunctions.unload_story()
		GlobalFunctions.clear_level_infos()
		GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM)
		
		if GlobalVaribles.story_info.is_story:
			SceneChanger.change_to("scenes/main_scenes/menu")
			return
		var texture_rect = TextureRect.new()
		await RenderingServer.frame_post_draw
		texture_rect.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
		texture_rect.name = "last_frame"
		texture_rect.size = DisplayServer.screen_get_size()
		get_tree().root.add_child(texture_rect)
		get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")


func _on_result_offset_timer_timeout():
	$bf_idle.play("def")
	for item in DATA:
		var num_pos = 0
		for num in str(GlobalVaribles.level_infos[item]):
			GlobalFunctions.add_anim_sprite(self, {
				"sprite_frames" : NUMS,
				"sprite_anim" : int(num),
				"delete_on_end" : false,
				"animation" : "show_num",
				"position" : DATA[item][0] + Vector2(42 * num_pos, 0),
				"modulate" : DATA[item][1],
			})
			num_pos += 1


func _on_gf_idle_timer_timeout():
	$gf.play("idle")
	$gf_idle_timer.queue_free()


func _on_anim_player_animation_finished(_anim_name):
	var cur_num = 0
	for num in str(round(GlobalVaribles.level_infos.score)).reverse():
		if num == "-":
			continue
		get_node("score_nums/num_" + str(9 - cur_num)).play(num)
		cur_num += 1
	if GlobalVaribles.level_infos.score > SaveManager.game_data.levels_data[GlobalVaribles.level_dict_name][GlobalVaribles.difficulty][0]:
		$show_highscore.play("def")
	
	if $music.stream:
		return
	if GlobalVaribles.level_infos.rate <= 89:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/good.ogg", "AudioStreamOggVorbis")
	elif GlobalVaribles.level_infos.rate >= 100:
		$music.stream = GlobalFunctions.load_thread("res://assets/music/results/perfect.ogg", "AudioStreamOggVorbis")
	$music.play()


func _on_music_finished():
	$music.stream = GlobalFunctions.load_thread($music.stream.resource_path.replace("-intro", ""), "AudioStreamOggVorbis")
	$music.play()
