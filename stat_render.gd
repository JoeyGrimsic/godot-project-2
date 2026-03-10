extends Node2D

# use dict to keep insertion order
var logged_stats : Dictionary = {}

func _input(event: InputEvent) -> void:
	# Toggle the debug overlay when pressing F3
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		toggle_debug(not visible)

func toggle_debug(show: bool) -> void:
	# Use Godot's built-in properties to manage state
	visible = show
	set_process(show)

func _process(_delta: float) -> void:
	# add or update stats in one line
	log_stat("Mouse Pos", get_global_mouse_position())
	log_stat("FPS", Engine.get_frames_per_second())

func log_stat(stat_name: String, value: Variant) -> void:
	# save stat and request redraw
	logged_stats[stat_name] = value
	queue_redraw()

func _draw():
	if logged_stats.is_empty():
		return
		
	var y_pos = 18          # start y pos
	var line_spacing = 15   # gap between lines
	
	# render each stat
	for stat_name in logged_stats:
		var display_text = stat_name + ": " + str(logged_stats[stat_name])
		draw_string(ThemeDB.fallback_font, Vector2(0, y_pos), display_text)
		y_pos += line_spacing
