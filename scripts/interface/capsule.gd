extends Node2D

const SMALL_NUMS = preload("res://assets/resources/sprite_frames/freeplay/capsule_small_nums.res")
const NUMS = preload("res://assets/resources/sprite_frames/freeplay/capsule_nums.res")
const FAV_SOUND = preload("res://assets/sounds/menu/freeplay/fav.ogg")
const UNFAV_SOUND = preload("res://assets/sounds/menu/freeplay/unfav.ogg")

@onready var label = $capsule/label

var dif_type = "default"
var vec = Vector2(0, 0)
var music_name = ""
var start_anim = "inactive"
var fav = false

func _ready():
	label.label_settings = label.label_settings.duplicate()
	$idle_anim.speed_scale = randf_range(0.95, 1.05)
	$idle_anim.play(start_anim)
	position = vec
	if music_name == "random":
		label.text = "Random"
		for node in ["icon", "bpm", "weektype", "dif"]:
			get_node("capsule/" + node).queue_free()
		return
	if SaveManager.game_data.levels_data.has(music_name):
		if SaveManager.game_data.levels_data[music_name].has("FAV"):
			fav = SaveManager.game_data.levels_data[music_name].FAV
			$capsule/heart.visible = fav
	label.text = GlobalVaribles.freeplay_capsules_infos[music_name][1][3]
	
	if $capsule/icon.sprite_frames.get_animation_names().has(GlobalVaribles.freeplay_capsules_infos[music_name][1][0]):
		$capsule/icon.animation = GlobalVaribles.freeplay_capsules_infos[music_name][1][0]
	else: match GlobalVaribles.freeplay_capsules_infos[music_name][1][0]:
		"mom-car": $capsule/icon.animation = "mommy"
		"monster-christmas": $capsule/icon.animation = "monster"
		"senpai-angry": $capsule/icon.animation = "senpai"
	
	match music_name.to_lower():
		"tutorial" : $capsule/weektype.queue_free()
		"bopeebo": set_week_type(0, 1)
		"fresh": set_week_type(0, 1)
		"dadbattle": set_week_type(0, 1)
		"spookeez": set_week_type(0, 2)
		"south": set_week_type(0, 2)
		"monster": set_week_type(0, 2)
		"pico": set_week_type(0, 3)
		"philly nice": set_week_type(0, 3)
		"blammed": set_week_type(0, 3)
		"satin panties": set_week_type(0, 4)
		"high": set_week_type(0, 4)
		"m.i.l.f.": set_week_type(0, 4)
		"cocoa": set_week_type(0, 5)
		"eggnog": set_week_type(0, 5)
		"winter horrorland": set_week_type(0, 5)
		"senpai": set_week_type(0, 6)
		"roses": set_week_type(0, 6)
		"thorns": set_week_type(0, 6)
		"ugh": set_week_type(0, 7)
		"guns": set_week_type(0, 7)
		"stress": set_week_type(0, 7)
		"darnell": set_week_type(1, 1)
		"lit up": set_week_type(1, 1)
		"2hot": set_week_type(1, 1)
	spawn_sprite_text(str(GlobalVaribles.freeplay_capsules_infos[music_name][1][1][dif_type]), Vector2(46, 88.75), SMALL_NUMS)
	update_dif()


func set_week_type(type, num):
	$capsule/weektype.frame = type
	if type == 0:
		spawn_sprite_text(str(num), Vector2(260, 88.75), SMALL_NUMS)
	else:
		spawn_sprite_text(str(num), Vector2(285, 88.75), SMALL_NUMS)


func active():
	$idle_anim.play("active")
	label.modulate = Color(0.957, 0.988, 0.992)


func inactive():
	$idle_anim.play("inactive")
	label.modulate = Color(0.596, 0.6, 0.608)


func update_dif():
	if music_name == "random":
		return
	for child in $capsule.get_children():
		if child.is_in_group("rate"):
			child.queue_free()
	var rate = str(GlobalVaribles.freeplay_capsules_infos[music_name][1][2][GlobalVaribles.difficulty])
	if int(rate) < 10:
		rate = "0" + rate
	spawn_sprite_text(rate, Vector2(388, 39), NUMS, 33, ["rate"])
	
	if SaveManager.game_data.levels_data.has(music_name):
		var complete_rate = SaveManager.game_data.levels_data[music_name][GlobalVaribles.difficulty][1]
		$capsule/rank_badge.show()
		$capsule/rank_badge.stop()
		if complete_rate == 0:
			$capsule/rank_badge.hide()
		elif complete_rate <= 59:
			$capsule/rank_badge.play("loss")
		elif complete_rate <= 79:
			$capsule/rank_badge.play("good")
		elif complete_rate <= 89:
			$capsule/rank_badge.play("great")
		elif complete_rate <= 99:
			$capsule/rank_badge.play("excellent")
		elif complete_rate == 100:
			$capsule/rank_badge.play("perfect")
		elif complete_rate == 101:
			$capsule/rank_badge.play("perfect+")
	if $capsule/rank_badge.visible:
		$capsule/heart.position.x = 298.5
	else:
		$capsule/heart.position.x = 352.5


func spawn_sprite_text(text, pos, sprite_frames, sep = 11.4, groups = []):
	var letter_pos = 0
	for letter in text:
		letter_pos += 1
		
		var extra_x_pos = 0
		if letter == "1":
			extra_x_pos = 4.5
		GlobalFunctions.add_particle($capsule, {
			"sprite_frames" : sprite_frames,
			"scale" : Vector2(1.1, 1.1),
			"position" : Vector2(sep * letter_pos + extra_x_pos, 0) + pos,
			"sprite_anim" : int(letter),
			"delete_on_end" : false,
			"add_to_group" : groups
		})


func change_fav():
	fav = !fav
	SaveManager.game_data.levels_data[music_name].FAV = fav
	SaveManager.save_data()
	if fav:
		$capsule/heart.show()
		$capsule/heart.play("show")
		$other_anim.play("fav_on")
		GlobalFunctions.add_audio_effect(FAV_SOUND)
	else:
		$capsule/heart.play("hide")
		$other_anim.play("fav_off")
		GlobalFunctions.add_audio_effect(UNFAV_SOUND)


func use():
	$capsule/icon.play($capsule/icon.animation)
	$label_anim.play("use")
