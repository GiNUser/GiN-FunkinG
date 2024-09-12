extends Area2D

const DESATURATION_SHADER = preload("res://assets/shaders/desat.gdshader")
@onready var level = get_tree().root.get_node("level")

var is_missed = false
var dir
var t

func _ready():
	$sprite.animation = level.chart.data.style + "_" + dir
	match level.chart.data.style:
		"pixel":
			$sprite.scale = Vector2(6, 6)
			$sprite.texture_filter = TEXTURE_FILTER_NEAREST


func miss():
	if !is_missed:
		skipped()
		get_parent().get_parent().note_miss()


func skipped():
	$sprite.z_index = -3
	$sprite.material = ShaderMaterial.new()
	$sprite.material.shader = DESATURATION_SHADER
	is_missed = true
