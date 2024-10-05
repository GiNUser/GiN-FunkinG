extends Node2D

const DESATURATION_SHADER = preload("res://assets/shaders/desat.gdshader")

var dir

func _ready():
	var level = get_tree().root.get_node("level")
	$sprite.animation = level.chart.data.style + "_" + dir
	match level.chart.data.style:
		"pixel":
			$sprite.scale = Vector2(6, 6)
			$sprite.texture_filter = TEXTURE_FILTER_NEAREST


func miss():
	$sprite.z_index = -3
	$sprite.material = ShaderMaterial.new()
	$sprite.material.shader = DESATURATION_SHADER
