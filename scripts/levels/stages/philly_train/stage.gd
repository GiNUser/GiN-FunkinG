extends Node2D

const SOUND_TRAIN_PASS = preload("res://assets/sounds/gameplay/stages/philly_train/train_passes.ogg")
var loop = 0

func _ready():
	get_tree().root.get_node("level")._on_measure.connect(_on_measure)
	$train_pass_time.start(randi_range(15, 35))
	$win_anim.speed_scale = get_tree().root.get_node("level").bps * 0.3


func _on_measure(_measure):
	$win_anim.stop()
	$win_anim.play(["yellow", "red", "blue", "green", "purple"].pick_random())


func _on_train_pass_time_timeout():
	$train_anim.play("train_passes_start")
	GlobalFunctions.add_audio_effect(SOUND_TRAIN_PASS)
	
	await $train_anim.animation_finished
	get_node("girlfriend").ignore_beats = true
	get_node("girlfriend/anim_player").play_backwards("hair_landing")


func _on_train_anim_animation_finished(anim_name):
	match anim_name:
		"train_passes_start":
			loop = 9
			$train_anim.play("train_passes_loop")
		"train_passes_loop":
			loop -= 1
			if loop == 0:
				get_node("girlfriend/anim_player").play("hair_landing")
				$train_anim.play("train_passes_end")
			else:
				get_node("girlfriend").play("hair_blowing_left")
				$train_anim.play("train_passes_loop")
		"train_passes_end":
			get_node("girlfriend").ignore_beats = false
			$train_pass_time.start(randi_range(15, 35))
