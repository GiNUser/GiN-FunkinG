extends Node2D

const DESATURATION_SHADER = preload("res://assets/shaders/desat.gdshader")
@onready var level = get_tree().root.get_node("level")

var dir = "up"
var l = 0
var t_pressed = 0

func _ready():
	$collision.shape = RectangleShape2D.new()
	$collision.shape.size.y = (l * level.note_speed) - 30
	$collision.position.y = ($collision.shape.size.y / 2) + 30
	
	$tale.play(level.chart.data.style + "_" + dir)
	$end.play(level.chart.data.style + "_" + dir)
	
	match level.chart.data.style:
		"pixel":
			$tale.offset.y = 3
			$end.offset.y = 3
			
			$tale.scale = Vector2(5, ((l * level.note_speed) / 30) * 5)
			$end.scale = Vector2(5, 5)
			$end.position.y = l * level.note_speed
			
			$tale.texture_filter = TEXTURE_FILTER_NEAREST
			$end.texture_filter = TEXTURE_FILTER_NEAREST
		"funkin":
			$tale.scale.y = ((l * level.note_speed) / 30) * 0.6
			$end.position.y = l * level.note_speed


func progress():
	t_pressed = (level.t - position.y / level.note_speed)
	match level.chart.data.style:
		"pixel":
			$tale.scale.y = (((l - t_pressed) * level.note_speed) / 30) * 5
			$tale.position.y = t_pressed * level.note_speed
		"funkin":
			$tale.scale.y = (((l - t_pressed) * level.note_speed) / 30) * 0.6
			$tale.position.y = t_pressed * level.note_speed


func inactive():
	$collision.queue_free()
	$tale.material = ShaderMaterial.new()
	$end.material = ShaderMaterial.new()
	$tale.material.shader = DESATURATION_SHADER
	$end.material.shader = DESATURATION_SHADER
	z_index = -2
