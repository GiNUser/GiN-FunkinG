extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")

@onready var level = get_tree().root.get_node("level")
var cur_btn = 0

func _ready():
	get_tree().paused = true
	if level.chart.data.has("pause_music"):
		$track.stream = GlobalFunctions.load_thread("res://assets/" + level.chart.data.pause_music, "AudioStream")
	spawn_sprite_text(level.chart.data.song_name, Vector2(0, 40), $current_music_name, true, 0.7)
	spawn_sprite_text(GlobalVaribles.difficulty, Vector2(-8, 80), $current_music_name, true, 0.35, 16)
	
	spawn_btns(["resume", "menu"])
	update_cur_pause_btn()
	
	var t = create_tween()
	t.tween_property($track, "volume_db", 0, 1.5)
	
	$container.position.y = -$container.get_child(cur_btn).position.y + 280


func _input(_event):
	if Input.is_action_just_pressed("restart"):
		if !GlobalVaribles.story_info:
			GlobalFunctions.clear_level_infos()
		SceneChanger.change_to()
	elif Input.is_action_just_pressed("accept"):
		match cur_btn:
			0:
				unpause()
			1:
				$track.stop()
				GlobalFunctions.clear_sounds()
				GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM)
				if GlobalVaribles.story_info:
					SceneChanger.change_to("scenes/main_scenes/menu")
					return
				
				GlobalFunctions.create_last_frame(ImageTexture.create_from_image(get_viewport().get_texture().get_image()))
				get_tree().change_scene_to_file("res://scenes/main_scenes/menu.scn")
	elif Input.is_action_just_pressed("cancel"):
		unpause()
	elif Input.is_action_just_pressed("up"):
		cur_btn -= 1
		if cur_btn < 0:
			cur_btn = $container.get_child_count() - 1
		update_cur_pause_btn()
	elif Input.is_action_just_pressed("down"):
		cur_btn += 1
		if cur_btn > $container.get_child_count() - 1:
			cur_btn = 0
		update_cur_pause_btn()


func update_cur_pause_btn():
	for child_id in $container.get_child_count():
		$container.get_child(child_id).modulate = "99999999"
	$container.get_child(cur_btn).modulate = Color.WHITE
	GlobalFunctions.add_audio_effect("res://assets/sounds/menu/scroll.ogg", -10, PROCESS_MODE_ALWAYS)


func unpause():
	get_tree().paused = false
	get_tree().root.get_node("level").unpaused()
	queue_free()


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
		GlobalFunctions.add_particle(node, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"delete_on_end" : false,
			"scale" : Vector2(inst_scale, inst_scale),
			"position" : inst_pos,
			"sprite_anim" : letter.to_lower()
		})
		letter_pos += 1


func spawn_btns(array):
	for i in array:
		var btn = Control.new()
		btn.custom_minimum_size = Vector2(600, 100)
		btn.name = i
		spawn_sprite_text(i, Vector2(0, 50), btn, false, 0.7)
		$container.add_child(btn)


func _process(delta):
	$container.position.y -= ($container.position.y - (-$container.get_child(cur_btn).position.y + 280)) * clamp(delta * 15, 0, 0.99)
