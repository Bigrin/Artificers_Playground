extends AudioStreamPlayer


func _core_damage_sound() -> void:
	pitch_scale = 2+randf()
	play()
	pass

func _core_destroyed_sound() -> void:
	pitch_scale = randf_range(0.75,1.1)
	play()
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_core_integrety_core_damaged_s() -> void:
	pass # Replace with function body.
