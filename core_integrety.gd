extends ProgressBar

signal deal_damage(int)

signal core_damaged_s
signal core_destroyed_s

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_deal_damage(damage: Variant) -> void:
	value = max(value - damage,0)
	print("damage received")
	if value == 0:
		core_destroyed_s.emit()
		print("Dead")
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.5
		timer.start()
		await timer.timeout
	# await get_tree().create_timer(speed*dist-0.07).timeout
		timer.queue_free()
		$"../../..".queue_free()
	else:
		core_damaged_s.emit()
	pass # Replace with function body.
