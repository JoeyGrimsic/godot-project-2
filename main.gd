extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func generate_seed() -> int:
	return randi()


func generate_chunk_seed(world_seed: int, chunk_x_coord: int) -> int:
	return world_seed + (chunk_x_coord * 341873128712)


func lcg(previous_seed: int) -> int:
	return 5 * previous_seed + 3


# what type represents the chunk mesh?
func regenerate_mesh(chunk_x_cord: int) -> Variant:
	var idk = 1
	return idk
