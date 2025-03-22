extends Node2D

@onready var core :AnimatedSprite2D = $Player_Core
@onready var movement_cooldown : Timer =$movement_timer

var core_cords: Vector2 	#Tile location of core
const main_atlas_id = 0	 	#Main 
var can_move = true
var momentum_dir: Vector2

# Naming Atlas Tiles for readability
var terrain_atlas = $Terrain.tile_set.get_source(main_atlas_id)
var plain_atl = terrain_atlas.get_tile_id(0)
var goal_atl = terrain_atlas.get_tile_id(1)
var brick_atl = terrain_atlas.get_tile_id(2)
var ice_atl = terrain_atlas.get_tile_id(3)
var snek_atl =  terrain_atlas.get_tile_id(4)

# Lists
var blocking_tiles = [brick_atl,snek_atl]
var damaging_tiles = [snek_atl]
var slippery_tiles = [ice_atl]

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	print('Start')
	core.play()
	print('Start')
	var tween = create_tween()
	core_cords = $Terrain.local_to_map(Vector2(core.position))
	tween.tween_property(core,"position",$Terrain.map_to_local(core_cords),0.3)
	print('Start')
	pass # Replace with function body.

func _unhandled_key_input(_event: InputEvent) -> void:
	var move_dir = Vector2(0,0)
	if Input.is_action_just_pressed("NP_N"):
		move_dir = Vector2(0,-1)
	elif	Input.is_action_just_pressed("NP_S"):
		move_dir = Vector2(0,1)
	elif	Input.is_action_just_pressed("NP_SE"):
		move_dir = Vector2(1,0)
	elif	Input.is_action_just_pressed("NP_SW"):
		move_dir = Vector2(-1,1)
	elif	Input.is_action_just_pressed("NP_NE"):
		move_dir = Vector2(1,-1)
	elif	Input.is_action_just_pressed("NP_NW"):
		move_dir = Vector2(-1,0)
	if can_move:_try_move_core(move_dir)
	pass

func _try_move_core(move_dir:Vector2) ->bool:
	# Check if Movement requested
	if move_dir!=Vector2(0,0) :
		# If path clear of obstacles move core in specified direction
		if _check_if_clear(core_cords + move_dir): 
			core_cords += move_dir # Execute position change
			momentum_dir = move_dir # Store momentum for Ice 'physics'
			var tween = create_tween()
			can_move = false
			tween.tween_property(core,"position",$Terrain.map_to_local(core_cords),0.3)
			$movement_timer.start()
			return true
		else:
			_check_for_contact_damage(core_cords + move_dir)  
	return false
	
# Handle Ice and other movement physics by delaying next steps
func _on_movement_timer_timeout():
	# If Core is on a slippery surface
	if slippery_tiles.has($Terrain.get_cell_atlas_coords(core_cords)):
		# But cannot slide any further, unlock move input
		if !_try_move_core(momentum_dir):can_move = true
	else:	
		can_move = true
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _check_if_clear(target_hex:Vector2) -> bool:
	var current_atlas_coords = $Terrain.get_cell_atlas_coords(target_hex)
	if blocking_tiles.has(current_atlas_coords):
		return false
	return true
	
func _check_for_contact_damage(target_hex:Vector2):
	if damaging_tiles.has($Terrain.get_cell_atlas_coords(target_hex)):
		$Core_Integrety.value -= 1
		print("Damage Taken")
