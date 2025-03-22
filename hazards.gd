extends TileMapLayer
signal reactivate_movement

# Called when the node enters the scene tree for the first time.
var Snek_spawn_locations: Array = [Vector2i(-3,-1),Vector2i(6,-3),Vector2i(4,0),\
	Vector2i(-7,2),Vector2i(5,-5),Vector2i(0,2),Vector2i(-4,2),Vector2i(-4,5),Vector2i(12,4),\
	Vector2i(6,-3),Vector2i(6,1),Vector2i(13,7),Vector2i(7,4),Vector2i(2,6),\
	Vector2i(-8,-5),Vector2i(14,-3),Vector2i(-6,-2)]
func _ready() -> void:
	#hide()
	$Snek_manager._Initialise(Snek_spawn_locations)
	pass # Replace with function body.

func _process_hazzards()->void:
	print("--------------------")
	$Snek_manager._Snek_turns()

func _on_finished_turns() -> void:
	reactivate_movement.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
