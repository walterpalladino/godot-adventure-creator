extends RefCounted
class_name AdventureTester

var game_manager : GameManager = null

func _init(p_game_manager : GameManager) -> void:
	game_manager = p_game_manager
	
func test_adventure_completable() -> bool:
	var sim_state = {
		"inventory": [],
		"current": game_manager.current_room,
		"visited": {},
		"items_collected": []
	}
	
	var max_steps = 100
	for steps in range(max_steps):
		sim_state.visited[sim_state.current] = true
		
		# Collect items
		collect_items_in_simulation(sim_state)
		
		# Check objective completion
		if game_manager.is_objective_room(sim_state.current):
			return can_complete_objective(sim_state.inventory)
		
		# Try to move
		if not try_move_simulation(sim_state):
			return false
	
	return false

func collect_items_in_simulation(sim_state: Dictionary):
	var room_items = game_manager.get_room_items(sim_state.current)
	for item in room_items:
		if item not in sim_state.items_collected:
			sim_state.inventory.append(item)
			sim_state.items_collected.append(item)

func can_complete_objective(sim_inventory: Array) -> bool:
	var obj_type = game_manager.objective_type
	match obj_type:
		"find_item":
			var target_item = game_manager.objective_target.to_lower().replace(" ", "_")
			return target_item in sim_inventory
		"rescue", "activate", "escape":
			return true
		"destroy":
			var weapons = ["sword", "hammer", "pickaxe", "crowbar", "staff", "wand"]
			for weapon in weapons:
				if weapon in sim_inventory:
					return true
			return true
	return false

func try_move_simulation(sim_state: Dictionary) -> bool:
	var connections = game_manager.get_room_connections(sim_state.current)
	
	# Try unvisited rooms first
	for direction in connections:
		var next_room = connections[direction]
		var required = game_manager.get_room_requirement(next_room)
		
		if required and required not in sim_state.inventory:
			continue
		
		if next_room not in sim_state.visited:
			sim_state.current = next_room
			return true
	
	# Try any accessible room
	for direction in connections:
		var next_room = connections[direction]
		var required = game_manager.get_room_requirement(next_room)
		
		if not required or required in sim_state.inventory:
			sim_state.current = next_room
			return true
	
	return false
