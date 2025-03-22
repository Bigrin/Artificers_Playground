extends TileMapLayer

const main_atlas_id = 0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var global_clicked = event.position
			var pos_clicked = local_to_map(to_local(global_clicked))
			print(pos_clicked)
			var current_atlas_coords = get_cell_atlas_coords(pos_clicked)
			var current_tile_alt = get_cell_alternative_tile(pos_clicked)
			var number_of_alts_for_clicked = tile_set.get_source(main_atlas_id)\
					.get_alternative_tiles_count(current_atlas_coords)
			set_cell(pos_clicked,main_atlas_id,current_atlas_coords,\
					(current_tile_alt+1)%number_of_alts_for_clicked)
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
