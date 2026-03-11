extends Node2D

# note:
# this is an autoload singleton, and for now classes will be prefixed with 'C'
class_name CDebugOverlay

var logged_stats : Dictionary = {}

func _ready() -> void:
	# Make sure it draws on top of everything else
	z_index = 4096 
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F3 and event.pressed and not event.echo:
		toggle_debug(not visible)

func toggle_debug(show: bool) -> void:
	visible = show
	set_process(show)

func _process(_delta: float) -> void:
	if not visible: 
		return
		
	# Add continuous stats here
	# note: we may want to move this, or expand on this
	log_stat("Mouse Pos", get_global_mouse_position())
	log_stat("FPS", Engine.get_frames_per_second())

# This is the function other files will call! DebugOverlay.log_stat(...)
func log_stat(stat_name: String, value: Variant) -> void:
	logged_stats[stat_name] = value
	queue_redraw()

func _draw():
	if logged_stats.is_empty() or not visible:
		return
		
	var y_pos = 18          
	var line_spacing = 15   
	for stat_name in logged_stats:
		var display_text = stat_name + ": " + str(logged_stats[stat_name])
		draw_string(ThemeDB.fallback_font, Vector2(0, y_pos), display_text)
		y_pos += line_spacing
