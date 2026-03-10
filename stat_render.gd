extends Node2D

var handle_mouse_pos
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	handle_mouse_pos = _add_stat(mouse_pos)
	pass

var mouse_pos : Vector2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	stat_list[handle_mouse_pos][0] = get_global_mouse_position()
	queue_redraw()
	pass

func _draw():
	if stat_list:
		for stat in stat_list:
			draw_string(ThemeDB.fallback_font, Vector2(0,stat[1]), str(stat[0]))

var stat_count : int
var stat_list = []
func _add_stat(stat) -> int:
	stat_count += 1
	var height_offset = 5
	var stat_height = stat_count * height_offset + 13
	stat_list.append([stat, stat_height])
	return stat_count - 1
	
func _compute_spring_force(k: float, x: float) -> float:
	return k*x*-1.0
