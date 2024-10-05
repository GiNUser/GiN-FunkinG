extends Node2D

const DESATURATION_SHADER = preload("res://assets/shaders/desat.gdshader")
@onready var level = get_tree().root.get_node("level")

var dir = "up"
var l = 0
var t_pressed = 0

func _ready():
	$tale.play(level.chart.data.style + "_" + dir)
	$end.play(level.chart.data.style + "_" + dir)
	
	match level.chart.data.style:
		"funkin":
			$tale.scale.y = ((l * level.note_speed) / 30) * 0.6
		"pixel":
			$tale.offset.y = 3
			$end.offset.y = 3
			
			$tale.scale = Vector2(5, ((l * level.note_speed) / 30) * 5)
			$end.scale = Vector2(5, 5)
			
			$tale.texture_filter = TEXTURE_FILTER_NEAREST
			$end.texture_filter = TEXTURE_FILTER_NEAREST
	$end.position.y = l * level.note_speed


func progress():
	t_pressed = level.t - position.y / level.note_speed
	$tale.scale.y = (((l - t_pressed) * level.note_speed) / 30) 
	match level.chart.data.style:
		"funkin": $tale.scale.y *= 0.6
		"pixel": $tale.scale.y *= 5
	$tale.position.y = t_pressed * level.note_speed


func miss():
	var desat_material = ShaderMaterial.new()
	desat_material.shader = DESATURATION_SHADER
	$tale.material = desat_material
	$end.material = desat_material
	z_index = -2
