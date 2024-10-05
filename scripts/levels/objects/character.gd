extends Node2D

const GF_LIST = ["gf", "gf-car", "gf-pixel", "gf-christmas", "gf-tankmen"]
var skipable_anims
var beats = [1, 3]

@onready var level = get_tree().root.get_node("level")

@export var character = ""
@export var left = 0
@export var down = 1
@export var up = 2
@export var right = 3

@export var idle_anim = "idle"
@export var left_anim = "left"
@export var down_anim = "down"
@export var up_anim = "up"
@export var right_anim = "right"

@export var sing = true

var cur_dir = ""
var events = []
var ignore_beats = false
var target_pos = Vector2.ZERO

func _ready():
	change_character(character)
	update_skipable_anims()
	if sing:
		connect_arrows()
	level._on_beat.connect(on_beat)
	update_beat()


func update_beat():
	if level.bpm <= 120 and !GF_LIST.has(character):
		beats = [1, 2, 3, 4]


func play(anim):
	if anim == $anim_player.current_animation:
		$anim_player.stop()
	$anim_player.play(anim)


func on_beat(beat):
	if ignore_beats:
		return
	if !cur_dir:
		if skipable_anims.has($anim_player.current_animation) or $anim_player.current_animation.find("_loop") != -1:
			if beats.has(beat) and $anim_player.has_animation(idle_anim):
				$anim_player.stop()
				$anim_player.play(idle_anim)


func play_note_anim(dir):
	play(self[dir + "_anim"])
	cur_dir = dir


func play_note_miss_anim(dir):
	play(self[dir + "_anim"] + "_miss")
	cur_dir = ""


func note_release(dir):
	if cur_dir == dir:
		cur_dir = ""


func _on_anim_player_animation_finished(anim_name):
	if $anim_player.has_animation(anim_name + "_loop"):
		play(anim_name + "_loop")


func change_animations(array):
	var anim = 0
	for i in ["idle", "left", "down", "up", "right"]:
		self[i + "_anim"] = array[anim + 1]
		anim += 1
	update_skipable_anims()


func update_skipable_anims():
	skipable_anims = ["", idle_anim, left_anim, down_anim, up_anim, right_anim]


func connect_arrows():
	for child in level.get_node("note_lines").get_children():
		for varible in ["left", "down", "up", "right"]:
			if child.id == self[varible]:
				child.note_press.connect(play_note_anim)
				child.note_miss.connect(play_note_miss_anim)
				child.note_release.connect(note_release)


func disconnect_arrows():
	for i in get_incoming_connections():
		if ["note_press", "note_miss", "note_release"].has(i.signal.get_name()):
			i.signal.get_object().disconnect(i.signal.get_name(), i.callable)
	cur_dir = ""


func change_character(new_character):
	character = new_character
	if $anim_player.has_animation_library(""):
		$anim_player.remove_animation_library("")
	if !GlobalVaribles.preloaded_characters.has(character):
		GlobalVaribles.preloaded_characters.merge({character : []})
		GlobalVaribles.preloaded_characters[character].append(GlobalFunctions.load_thread("res://assets/animations/" + new_character + "/sprite_frames.res", "SpriteFrames"))
		var anim_library = AnimationLibrary.new()
		for file in DirAccess.open("res://assets/animations/" + new_character + "/").get_files():
			if file.get_extension() == "anim":
				anim_library.add_animation(file.trim_suffix(".anim"), GlobalFunctions.load_thread("res://assets/animations/" + character + "/" + file, "Animation"))
		GlobalVaribles.preloaded_characters[character].append(anim_library)
	$anim_sprite.set_sprite_frames(GlobalVaribles.preloaded_characters[character][0])
	$anim_player.add_animation_library("", GlobalVaribles.preloaded_characters[character][1])
	
	scale = Vector2(1, 1)
	$anim_sprite.texture_filter = TEXTURE_FILTER_LINEAR
	if ["senpai", "senpai-angry", "bf-pixel", "gf-pixel", "spirit"].has(character):
		scale = Vector2(7.2, 7.2)
		$anim_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	elif character == "pico-speaker":
		$anim_player.play("shoot_" + str(randi_range(1, 4)) + "_loop")
		return
	
	if $anim_player.has_animation("idle_loop"):
		$anim_player.play("idle_loop")
	else:
		$anim_sprite.position = $anim_player.get_animation(idle_anim).track_get_key_value(0, $anim_player.get_animation(idle_anim).track_get_key_count(0) - 1)
		$anim_sprite.frame = $anim_player.get_animation(idle_anim).track_get_key_value(1, $anim_player.get_animation(idle_anim).track_get_key_count(1) - 1)
		$anim_sprite.rotation_degrees = $anim_player.get_animation(idle_anim).track_get_key_value(2, $anim_player.get_animation(idle_anim).track_get_key_count(2) - 1)
	
	var tex = $anim_sprite.sprite_frames.get_frame_texture("default", $anim_player.get_animation(idle_anim).track_get_key_value(1, $anim_player.get_animation(idle_anim).track_get_key_count(1) - 1))
	if $anim_player.get_animation(idle_anim).track_get_key_value(2, $anim_player.get_animation(idle_anim).track_get_key_count(2) - 1) != 0:
		target_pos = position + Vector2(0, -tex.get_size().x * 0.6) * scale.x
	else:
		target_pos = position + Vector2(0, -tex.get_size().y * 0.6) * scale.x
	
	if GF_LIST.has(character):
		$anim_player.speed_scale = (level.bps * $anim_player.get_animation(idle_anim).length) / 2
		play(idle_anim)
	
	match character:
		"pico":
			$anim_sprite.flip_v = true
		"tankman":
			$anim_sprite.flip_h = true
