extends Camera2D

var zoom_on_none = 0.7
var zoom_on_target = 0.95

var bop_zoom = 0.0
var bop_power = 1.0
var smooth_zoom = 0.0

var real_zoom
var real_pos = Vector2.ZERO

var target = "none"
var events = []

var tween_pos : Tween
var tween_zoom : Tween
var tween_bop : Tween

func _enter_tree():
	get_parent().json_loaded.connect(loaded)
	get_parent().bop_anim_played.connect(play_bop_anim)


func loaded():
	real_zoom = zoom_on_none
	smooth_zoom = real_zoom
	zoom = Vector2(real_zoom, real_zoom)


func set_target(new_target, special_offset = 0):
	target = new_target
	
	if target == "none":
		real_zoom = zoom_on_none
		real_pos = Vector2.ZERO
	else:
		real_zoom = zoom_on_target
		if special_offset:
			real_pos = get_parent().get_node("stage/" + target).target_pos * special_offset
		else:
			real_pos = (get_parent().get_node("stage/" + target).target_pos) / (1.7 / zoom_on_target)
	
	if tween_pos:
		tween_pos.kill()
	tween_pos = create_tween()
	tween_pos.tween_property(self, "position", real_pos, get_parent().bps / 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	
	if tween_zoom:
		tween_zoom.kill()
	tween_zoom = create_tween()
	tween_zoom.tween_property(self, "smooth_zoom", real_zoom, get_parent().bps / 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


func _process(_delta):
	zoom = Vector2(smooth_zoom + bop_zoom, smooth_zoom + bop_zoom)


func play_bop_anim():
	bop_zoom = smooth_zoom * 0.0125 * bop_power
	
	if tween_bop:
		tween_bop.kill()
	tween_bop = create_tween()
	tween_bop.tween_property(self, "bop_zoom", 0, get_parent().stb).set_ease(Tween.EASE_OUT)


func set_bop_power(mod):
	bop_power = mod
