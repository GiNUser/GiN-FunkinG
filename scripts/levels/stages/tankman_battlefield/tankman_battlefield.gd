extends Node2D

const SOLDIER = preload("res://scenes/levels/objects/tankman_battlefield/soldier.scn")

var to_spawn = null
var to_pico = {}

func _ready():
	$idle_anim.speed_scale = get_tree().root.get_node("level").bps
	$tank_anim_delay.start(randf_range(25, 35))
	
	if get_parent().chart.has("attributes"):
		if get_parent().chart.attributes.has("pico-arrows"):
			to_spawn = get_parent().chart.attributes["pico-arrows"]


func _process(_delta):
	if to_spawn:
		for line in to_spawn:
			for note in to_spawn[line]:
				if note.t < get_parent().t - 1200:
					if !to_pico.has(line):
						to_pico.merge({line : []})
					to_pico[line].append(note)
					to_spawn[line].erase(note)
					if 0 == randi_range(0, 2):
						spawn_soldier(int(line) == 8)
		for line in to_pico:
			for note in to_pico[line]:
				if note.t < get_parent().t:
					if int(line) == 8:
						$girlfriend/anim_player.play("shoot_" + str(randi_range(1, 2)))
					else:
						$girlfriend/anim_player.play("shoot_" + str(randi_range(3, 4)))
					to_pico[line].erase(note)


func spawn_soldier(dir):
	var soldier_inst = SOLDIER.instantiate()
	if dir:
		soldier_inst.dir = "left"
	call_deferred("add_child", soldier_inst)


func _on_tank_anim_animation_finished(_anim_name):
	$paralax3/tank_anchor/tank.stop()


func _on_tank_anim_delay_timeout():
	$tank_anim.play("def")
	$paralax3/tank_anchor/tank.play("def")
	$tank_anim_delay.start(randf_range(25, 35))
