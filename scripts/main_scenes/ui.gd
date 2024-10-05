extends CanvasLayer

const PARTICLE = preload("res://scenes/gameplay/particle.scn")
const RESULTS_SCREEN = preload("res://scenes/other/ui/results_screen.scn")
const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const NUMS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/nums.res")
const PAUSE = preload("res://scenes/other/ui/pause.scn")

@onready var level = get_tree().root.get_node("level")
var tween_bop : Tween

func _ready():
	get_parent().score_updated.connect(update_score)
	get_parent().health_updated.connect(update_health)
	get_parent().combo_updated.connect(update_combo)
	get_parent().bop_anim_played.connect(play_bop_anim)
	get_parent().json_loaded.connect(json_loaded)
	if !SaveManager.game_data.centered_arrows:
		$rating_container.position = Vector2(595, 81)


func json_loaded():
	for i in ["opponent", "player"]:
		var character_data = GlobalVaribles.CHARACTERS_DATA[level.chart.data.characters[i]]
		if character_data.has("icon"):
			get_node("main/health_bar_texture/icons/" + i).animation = character_data.icon
		else:
			get_node("main/health_bar_texture/icons/" + i).animation = level.chart.data.characters[i]
		get_node("main/health_bar_texture/" + i + "_color").color = character_data.health_color
		if character_data.has("is_pixel"):
			get_node("main/health_bar_texture/icons/" + i).scale *= 5.5
			get_node("main/health_bar_texture/icons/" + i).set_texture_filter(1)
	update_health(get_parent().health)
	
	var style = get_parent().chart.data.style
	$main/intro_anim/sprite.sprite_frames = GlobalVaribles.preloaded_styles[style].start
	var style_scale = Vector2(1, 1)
	var texture_filter = Node2D.TEXTURE_FILTER_LINEAR
	match style:
		"pixel":
			style_scale *= 6
			texture_filter = Node2D.TEXTURE_FILTER_NEAREST
	$main/intro_anim/sprite.scale = style_scale
	$main/intro_anim/sprite.texture_filter = texture_filter
	$main/intro_anim/anim_player.speed_scale = get_parent().bps
	
	$rating_container/anim_sprite.texture_filter = texture_filter
	$rating_container/anim_sprite.sprite_frames = GlobalVaribles.preloaded_styles[style].rate
	
	if style_scale != Vector2(1, 1):
		var anim_r = $rating_container/anim_player.get_animation("RESET").duplicate()
		var anim = $rating_container/anim_player.get_animation("default").duplicate()
		for key_idx in anim.track_get_key_count(0):
			anim.track_set_key_value(0, key_idx, anim.track_get_key_value(0, key_idx) * style_scale)
		
		var lib = AnimationLibrary.new()
		lib.add_animation("RESET", anim_r)
		lib.add_animation("default", anim)
		$rating_container/anim_player.remove_animation_library("")
		$rating_container/anim_player.add_animation_library("", lib)


func _input(_event):
	if Input.is_action_just_pressed("restart"):
		if !GlobalVaribles.story_info:
			GlobalFunctions.clear_level_infos()
		SceneChanger.change_to()
	elif Input.is_action_just_pressed("pause") and !has_node("results_screen"):
		show_pause()


func spawn_anim_particle(anim, special_anim = "", unique_pos = Vector2.ZERO):
	var particle_inst = PARTICLE.instantiate()
	particle_inst.sprite_anim = anim
	particle_inst.special_anim = special_anim
	particle_inst.global_position = unique_pos
	particle_inst.scale = Vector2(2, 2)
	get_parent().call_deferred("add_child", particle_inst)


func update_combo(combo, breaked):
	if combo > 9:
		spawn_combo_text(str(combo))
	elif breaked:
		spawn_combo_text("0")


func spawn_combo_text(text):
	for node in $rating_container.get_children():
		if node.is_in_group("combo"):
			node.queue_free()
	var num_pos = 0
	var style = get_parent().chart.data.style
	var inst_scale = 1.5
	var texture_filter = Node2D.TEXTURE_FILTER_LINEAR
	match style:
		"pixel":
			inst_scale = 6
			texture_filter = Node2D.TEXTURE_FILTER_NEAREST
	for num in str(text):
		GlobalFunctions.add_particle($rating_container, {
			"sprite_frames" : GlobalVaribles.preloaded_styles[style].nums,
			"sprite_anim" : int(num),
			"animation" : "combo_num",
			"rotation" : randf_range(-0.05, 0.05),
			"scale" : Vector2(inst_scale, inst_scale),
			"position" : Vector2((num_pos - str(text).length() / 2.0) * 50, 100),
			"add_to_group" : ["combo"],
			"texture_filter" : texture_filter
		})
		num_pos += 1


func update_score(score):
	if round(score) <= -1:
		return
	for node in $main/score.get_children():
		if node.is_in_group("score"):
			node.queue_free()
	var inst_scale = 0.7
	var texture_filter = Node2D.TEXTURE_FILTER_LINEAR
	var style = get_parent().chart.data.style
	match style:
		"pixel":
			inst_scale = 2.4
			texture_filter = Node2D.TEXTURE_FILTER_NEAREST
	var num_pos = 0
	for num in str(round(score)):
		var sprite_anim = int(num)
		GlobalFunctions.add_particle($main/score, {
			"sprite_frames" : GlobalVaribles.preloaded_styles[style].nums,
			"sprite_anim" : sprite_anim,
			"scale" : Vector2(inst_scale, inst_scale),
			"delete_on_end" : false,
			"position" : Vector2(103 + (20 * num_pos), 0),
			"add_to_group" : ["score"],
			"texture_filter" : texture_filter,
		})
		num_pos += 1


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


func update_health(health):
	if health > get_parent().max_health * 0.8:
		$main/health_bar_texture/icons/opponent.frame = 2
		$main/health_bar_texture/icons/player.frame = 0
	elif health < get_parent().max_health * 0.2:
		$main/health_bar_texture/icons/opponent.frame = 0
		$main/health_bar_texture/icons/player.frame = 2
	else:
		$main/health_bar_texture/icons/opponent.frame = 1
		$main/health_bar_texture/icons/player.frame = 1


func music_finished():
	if GlobalVaribles.story_info:
		if !GlobalVaribles.story_info.scenario.is_empty():
			return
	call_deferred("add_child", RESULTS_SCREEN.instantiate())


func play_bop_anim():
	$main.scale = get_parent().bop_power
	$main/health_bar_texture/icons.scale = $main.scale
	if tween_bop:
		tween_bop.kill()
	tween_bop = create_tween()
	tween_bop.tween_property($main, "scale", Vector2(1, 1), get_parent().stb).set_ease(Tween.EASE_OUT)
	tween_bop.parallel().tween_property($main/health_bar_texture/icons, "scale", Vector2(1, 1), get_parent().stb).set_ease(Tween.EASE_OUT)


func _process(delta):
	$main/health_bar_texture/opponent_color.size.x -= ($main/health_bar_texture/opponent_color.size.x - (1 - (get_parent().health / get_parent().max_health)) * 589) * delta * 6
	$main/health_bar_texture/icons.position.x = $main/health_bar_texture/opponent_color.size.x + 6.0


func show_pause():
	if !has_node("pause") and !has_node("results_screen"):
		call_deferred("add_child", PAUSE.instantiate())
		get_tree().paused = true


func show_rate(rate):
	$rating_container/anim_sprite.frame = rate
	$rating_container/anim_sprite.rotation = randf_range(-0.05, 0.05)
	$rating_container/anim_player.stop()
	$rating_container/anim_player.play("default")


func emit_start(beat):
	$main/intro_anim/sprite.frame = beat
	$main/intro_anim/anim_player.stop()
	$main/intro_anim/anim_player.play("default")


func _on_anim_player_animation_finished(_anim_name):
	$main/intro_anim.queue_free()
