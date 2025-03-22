extends Node2D

@onready var core :AnimatedSprite2D = $Player_Core
@onready var movement_cooldown : Timer =$movement_timer
@onready var Terrain: TileMapLayer = $Terrain
signal process_hazzards
signal damage_taken(int)

var core_cords: Vector2i 	#Tile location of core
const main_atlas_id = 0	 	#Main 
var can_move = true
var score = 0
var momentum_dir: Vector2i


# Naming Atlas Tiles for readability
# var terrain_atlas = $Terrain.tile_set.get_source(main_atlas_id)

var plain_atl
var goal_atl 
var brick_atl 
var ice_atl
var spikes_atl
var snek_atl
var innactive_goal_atl
	
var blocking_tiles = []
var damaging_tiles = []
var slippery_tiles = []
var damaging_hazards = []
# Lists


# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	#TerrainTiles.grid_ref = self.Terrain
	#HazardTiles.grid_ref = self.Hazards
	plain_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(0)
	goal_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(1)
	innactive_goal_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(3)
	brick_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(4)
	ice_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(5)
	spikes_atl = $Terrain.tile_set.get_source(main_atlas_id).get_tile_id(2)
	snek_atl = $Hazards.tile_set.get_source(main_atlas_id).get_tile_id(1)
	
	
	blocking_tiles = [brick_atl,spikes_atl]
	damaging_tiles = [spikes_atl]
	slippery_tiles = [ice_atl]
	damaging_hazards = [snek_atl]
	
	core.play()
	var tween = create_tween()
	core_cords = $Terrain.local_to_map(Vector2i(core.position))
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
	if can_move:
		_try_move_core(move_dir)
	pass

func _try_move_core(move_dir:Vector2i) ->bool:
	# Check if Movement requested
	if move_dir!=Vector2i(0,0) :
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
			if _check_for_contact_damage(core_cords + move_dir):
				$movement_timer.start()
			return false 
	return false
	
# Handle Ice and other movement physics by delaying next steps
func _on_movement_timer_timeout():
	# If Core is on a slippery surface
	if slippery_tiles.has($Terrain.get_cell_atlas_coords(core_cords)):
		# But cannot slide any further, unlock move input
		if _try_move_core(momentum_dir): return
	await(_trigger_tiles())
	process_hazzards.emit()
	$movement_timer.stop()
	pass
	
func _on_hazards_reactivate_movement() -> void:
	can_move = true

func _trigger_tiles()->void:
	var Terrain_id = $Terrain.get_cell_atlas_coords(core_cords)
	print("test")
	match Terrain_id:
		goal_atl:
			score += 1
			$Terrain.set_cell(core_cords,main_atlas_id,innactive_goal_atl)
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _check_if_clear(target_hex:Vector2i) -> bool:
	var Terrain_id = $Terrain.get_cell_atlas_coords(target_hex)
	var Hazards_id = $Hazards.get_cell_atlas_coords(target_hex)
	if blocking_tiles.has(Terrain_id):
		return false
	if (Hazards_id != Vector2i(-1,-1)):
		return false
	return true
	
func _check_for_contact_damage(target_hex:Vector2i) -> bool:
	var Hazards_id = $Hazards.get_cell_atlas_coords(target_hex)
	var Terrain_id = $Terrain.get_cell_atlas_coords(target_hex)
	if damaging_tiles.has(Terrain_id) or damaging_hazards.has(Hazards_id):
		damage_taken.emit(1)
		print("Damage Taken")
		return true
	else: return false
