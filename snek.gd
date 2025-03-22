extends Node
@export var Snek_scene: PackedScene
@onready var mode = 'S'
@onready var wait_timer = $Timer
signal deal_damage(damage)
signal finished_turns

var Hazzard_tileset = 0
var Snek_atl = Vector2i(0,1)
var Damage = 1
var sprite_preset #Snek sprite
# Mode of snek							Animation name
# S = sleeping							-> 
# A = alert
# I = idle
# U = stuned
# D = dead
# P_N = Preparing to strike North
# P_NE = Preparing to strike NorthEast
# P_NW = Preparing to strike NorthWest
# P_S = Preparing to strike South
# P_SE = Preparing to strike SouthEast
# P_SW = Preparing to strike SouthWest
const modes = ['S','A','I','U','D','P_N','P_NE','P_NW','P_S','P_SE','P_SW']
const Animations = ["Sleep","Alerted","Idle","Stunned","Dead",\
"Attack_N","Attack_NE","Attack_NW","Attack_S","Attack_SE","Attack_SW"]
# list of *pointers* to active, child sneks
var Sneks: Array = []
# pointer to the snek currently being manipulated
var Active_snek = null
var Ter_grid 
var Haz_grid
var current_tile
var relitive_core_coordinates:Vector2i
var core_coordinates:Vector2i
var own_coordinates:Vector2i
#Both following series are aligned to start at north and proceed clock-wise
const Strike_Dirs = ["P_N","P_NE","P_SE","P_S","P_SW","P_NW"]
const Adj_vectors = [Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0)\
		,Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Ter_grid = get_node("../../Terrain")
	Haz_grid = get_node("..")
	
	pass # Replace with function body.

func _Initialise(Snek_locations:Array)-> void:
	# Load the sprite preset
	sprite_preset = preload("res://snek.tscn")
	# iterate thrugh desired Snek locations
	for i in Snek_locations.size():
		var location: Vector2i = Snek_locations[i]
		Active_snek = sprite_preset.instantiate()
		add_child(Active_snek)
		Sneks.push_back(Active_snek)
		Active_snek.position = \
		Ter_grid.map_to_local(location)
		# save own_coordinates to metatdata
		Active_snek.set_meta("own_coordinates",location)
		Active_snek.set_meta("mode",'S')
	pass
	
func _Snek_turns() -> void:
	core_coordinates = $"../..".core_cords
	#print("Snek Count:",Sneks.size())
	for i in Sneks.size():
		#print("managing snek no.",i)
		Active_snek = Sneks[i]
		own_coordinates = Active_snek.get_meta("own_coordinates")
		mode = Active_snek.get_meta("mode")
		await(_take_turn(core_coordinates,own_coordinates))
		Active_snek.set_meta("mode",mode)
		
	finished_turns.emit()
	pass
	
# Returns hex tile distance of co-ordinates 
func _Hx_distance(coordinates:Vector2i) -> int:
	return int(max(max(abs(coordinates.x),abs(coordinates.y)),abs(coordinates.y + coordinates.x )))
pass

func _take_turn(core_coordinates:Vector2i,own_coordinates) ->void:
	relitive_core_coordinates = core_coordinates - own_coordinates
	#print(" core relitive position is: ",relitive_core_coordinates)
	var outcome = await(_perform_lunges(mode))
	if !outcome:
		#print("Not attempting strike")
		#print("Mode was: ",mode)
		mode = _decide_next_behaviour(relitive_core_coordinates)
		#print("New mode is: ",mode)
	_update_animation()

func _update_animation() -> void:
	Active_snek.animation = Animations[modes.find(mode)]
	Active_snek.play
	pass
	

# Handles core-dependant decisionmaking and non-lunge movement
func _decide_next_behaviour\
(relitive_target_coordinates:Vector2i) -> StringName:
	var core_dist :int = _Hx_distance(relitive_target_coordinates)
	var from_pos: Vector2i = Active_snek.get_meta("own_coordinates")
	#print("Core distance is: ",core_dist)
	# Numerical representation of sub-mode behavioural options
	var options = []
	# Intermediate coordinate for deriving movement.
	var lunge
	match mode:
		"S":
			# Sleeping: If core is adjacent -> Awoken
			if core_dist == 1: return "A"
			else: return "S"
		"A":
			# Awoken: If adj to core reachable prepare in direction -> P_X
			#			Else go Idle
			if core_dist <= 2:
				#print("From Alert: pounce attempt")
				
				#check all 6 directions
				for i in 6:
					# Check if lunge is immediately blocked by wall
					lunge = Adj_vectors[i];
					if _check_if_clear(from_pos+lunge,false,false,false):
						#Check if lunge direction brings adjacent to target core
						if relitive_target_coordinates in [lunge,2*lunge,\
								lunge+Adj_vectors[(i+1)%6],\
								lunge+Adj_vectors[(i-1)%6]]:
							options.append(i)
				if options == []:
					#print("No valid strikes found")
					return "I"
				else: mode = Strike_Dirs[options.pick_random()]
				#print("Strike options were: ",options)
				#print("striking in direction: ",mode)
				return mode
			else:
				#print("no pounce")
				#print("distance =",core_dist)
				return "I"
		"I":
			# Idle: If adj to core reachable prepare in direction -> P_X
			#			Else wander and stay idle
			if core_dist <= 2:
				#print("From Idle: pounce attempt")
				#check all 6 directions
				for i in 6:
					# Check if lunge is immediately blocked by wall
					lunge = Adj_vectors[i];
					if _check_if_clear(from_pos+lunge,false,false,true):
						#Check if lunge direction brings adjacent to target core
						if relitive_target_coordinates in [lunge,2*lunge,\
								lunge+Adj_vectors[(i+1)%6],\
								lunge+Adj_vectors[(i-1)%6]]:
							options.append(i)
				if options == []:
					#print("No valid strikes found")
					_random_wander()
					return "I"
				else: mode = Strike_Dirs[options.pick_random()]
				#print("Strike options were: ",options)
				#print("striking in direction: ",mode)
				return mode
			else:
				#print("Idle")
				#print("distance =",core_dist)
				_random_wander()
				return "I"
		"U":
			return "A" 
		"D":
			return "D"
	print("error, received mode was",mode)
	return "ERROR"
	
func _random_wander() -> void:
	var wander_options = []
	var from_pos = Active_snek.get_meta("own_coordinates")
	for i in 6:
		# Check if wanderis immediately blocked by wall
			var wander_dir = Adj_vectors[i];
			if _check_if_clear(from_pos+wander_dir,false,false,false):
				wander_options.append(i)
	if wander_options == []:
		return
	else:
		_move_by(Adj_vectors[wander_options.pick_random()])
	pass

func _check_if_clear(target_hex:Vector2i,\
					bumping:bool,\
					count_core:bool,\
					count_haz:bool) -> bool:
	# Checks if the target hex is clear of any obstacle that prevents movement
	# -Bumping- distinguishes between decisionmaking and physical calls 
	# for atributing damage
	var Terrain_id = $"../../Terrain".get_cell_atlas_coords(target_hex)
	var Hazards_id = $"..".get_cell_atlas_coords(target_hex)
	# Note how Null terrain tiles behave as walls as every set contains Null
	if $"../..".blocking_tiles.has(Terrain_id):
		return false
	if (Hazards_id != Vector2i(-1,-1) and count_haz):
		return false
		# Insert blocking hazzard logic here
	if (core_coordinates == target_hex):
		if bumping == true:
			do_damage()
		return !count_core
		# blocked by core
	return true

func _check_if_damaging(target_hex:Vector2i)->bool:
	var Terrain_id = $"../../Terrain".get_cell_atlas_coords(target_hex)
	var Hazards_id = $"..".get_cell_atlas_coords(target_hex)
	return $"../..".damaging_tiles.has(Terrain_id) or\
	 $"../..".damaging_hazards.has(Hazards_id)
	
	

func _move_by(relitive_movement:Vector2i) -> bool:
	#print("move attempt")
	if !(relitive_movement in Adj_vectors):
		print("warning, unusual requested movement")
	own_coordinates = Active_snek.get_meta("own_coordinates")
	if relitive_movement != Vector2i(0,0) :
	# If path clear of obstacles move core in specified direction
		if _check_if_clear(own_coordinates + relitive_movement,true,true,true): 
			Haz_grid.set_cell(own_coordinates,-1)
			own_coordinates += relitive_movement # Execute position change
			Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
			var dist = 1
			Active_snek.set_meta("own_coordinates",own_coordinates)
			# If on ice consider sliding further,
			while\
			 (_get_current_tile(own_coordinates) in $"../..".slippery_tiles) \
			and \
			 (_check_if_clear(own_coordinates + relitive_movement,true,true,true)):
				dist += 1
				Haz_grid.set_cell(own_coordinates,-1)
				own_coordinates += relitive_movement # Execute position change
				Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
				#print("sliding")
				Active_snek.set_meta("own_coordinates",own_coordinates)
			await(_action_move(dist,0.3))
			return true
		else: #if direct movement is blocked
			return false
	return true
func _strike_move_by(relitive_movement:Vector2i) -> bool:
	#print("move attempt")
	# Check if Movement requested executes fully
	# must be able to handle an empty set call to handle entombed snakes.
	#also handles slippery behaviour and wall contact
	# returns false if movement 'unsucsessful'
		# blocked by hazzard or tile
	# returns true 
	own_coordinates = Active_snek.get_meta("own_coordinates")
	if relitive_movement != Vector2i(0,0) :
	# If path clear of obstacles move core in specified direction
		if _check_if_clear(own_coordinates + relitive_movement,true,true,true): 
			Haz_grid.set_cell(own_coordinates,-1)
			own_coordinates += relitive_movement # Execute position change
			Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
			var dist = 1
			Active_snek.set_meta("own_coordinates",own_coordinates)
			# If on ice consider sliding further,
			while (_get_current_tile(own_coordinates) in $"../..".slippery_tiles):
				if !_check_if_clear(own_coordinates + relitive_movement,true,true,true):
					# return false if Haz or wall, True if Core
					Active_snek.set_meta("own_coordinates",own_coordinates)
					await(_action_move(dist,0.15))
					#print("blocked movement")
					return core_coordinates == (own_coordinates + relitive_movement)
					break # if off ice return to normal process
				dist += 1
				Haz_grid.set_cell(own_coordinates,-1)
				own_coordinates += relitive_movement # Execute position change
				Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
				#print("sliding")
			# strike
			if !_check_if_clear(own_coordinates + relitive_movement,true,true,true):
				# return false if Haz or wall, True if Core
				Active_snek.set_meta("own_coordinates",own_coordinates)
				await(_action_move(dist,0.15))
				#print("blocked strike movement")
				return core_coordinates == (own_coordinates + relitive_movement)
			else:
				# uninterupted strike
				dist += 1
				Haz_grid.set_cell(own_coordinates,-1)
				own_coordinates += relitive_movement # Execute position change
				Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
				# check for sliding:
				while (_get_current_tile(own_coordinates) in $"../..".slippery_tiles):
					if !_check_if_clear(own_coordinates + relitive_movement,true,true,true):
						Active_snek.set_meta("own_coordinates",own_coordinates)
						await(_action_move(dist,0.15))
						# core impact otherwise failure
						return core_coordinates == (own_coordinates + relitive_movement)
					dist += 1
					Haz_grid.set_cell(own_coordinates,-1)
					own_coordinates += relitive_movement # Execute position change
					Haz_grid.set_cell(own_coordinates,Hazzard_tileset,Snek_atl)
				# landed from strike on non-slippery
				Active_snek.set_meta("own_coordinates",own_coordinates)
				await(_action_move(dist,0.15))
				return true
		else: #if direct movement is blocked
			return core_coordinates == (own_coordinates + relitive_movement)
	return true

# Execute all lunge attacks including mode changes and movement
# also handles slippery behaviour
# False if not lunging
func _perform_lunges(input_mode:StringName) -> bool:
	if input_mode in Strike_Dirs:
		#print("performing lunge",mode)
		var strike_dir = Adj_vectors[Strike_Dirs.find(input_mode)]
		#print("Striking with: ",strike_dir)
		
		## handle animation for striking here##
		
		# move using strike logic, sucsess-> allert, Failure -> stun
		#print("start wait")
		var outcome = await (_strike_move_by(strike_dir))
		#print("end wait")
		if outcome:
			#print("strike sucsessfull")
			mode = 'A'
		else:
			#print("strike unsucessfull")
			mode = 'U'
		return true
	else:
		return false

func _action_move(dist:=1,speed:=0.3)->bool:
	var tween = create_tween()
	tween.tween_property (Active_snek,"position",
	$"../../Terrain".map_to_local(own_coordinates)
	,speed*dist)
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = speed*(dist)
	timer.start()
	await timer.timeout
	# await get_tree().create_timer(speed*dist-0.07).timeout
	timer.queue_free()
	return true

func _on_death()->void:
	queue_free()
	pass
	
func _on_stun()->void:
	mode = 'U'
	Active_snek.animation = "Stunned"
	Active_snek.play
	pass
	
func do_damage()->void:
	#print("damage delt")
	deal_damage.emit(1)
	pass

func pass_turn()->void:
	
	pass
	
func _get_current_tile(own_coordinates) -> Vector2i:
	return $"../../Terrain".get_cell_atlas_coords(own_coordinates)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	pass
