extends Control

# Configuration
const MIN_ROOMS = 5
const MAX_GENERATION_ATTEMPTS = 10

# Data file paths
const OBJECTIVES_DATA_PATH = "res://assets/adventure-creator/data/objectives.json"
const ROOMS_DATA_PATH = "res://assets/adventure-creator/data/rooms.json"
const ITEMS_DATA_PATH = "res://assets/adventure-creator/data/items.json"

# Managers
var objectives_manager = null
var room_manager = null
var items_manager = null

# Game state
var current_room = ""
var inventory = []
var game_won = false
var game_ready = false

# UI References
@onready var output_text = $VBoxContainer/ScrollContainer/OutputText
@onready var input_field = $VBoxContainer/HBoxContainer/InputField
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton



func _ready():
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_input_submitted)
	initialize()

func initialize():
	print_output("=== TEXT ADVENTURE GENERATOR ===\n")
	print_output("Loading game data...\n")
	
	# Load objectives data and initialize objectives manager
	var objectives_data = ObjectivesLoader.load_data(OBJECTIVES_DATA_PATH)
	if objectives_data.is_empty():
		print_output("ERROR: Failed to load objectives data!\n")
		return
	
	objectives_manager = ObjectivesManager.new(objectives_data)
	
	# Load items data and initialize items manager
	var items_data = ItemsLoader.load_data(ITEMS_DATA_PATH)
	if items_data.is_empty():
		print_output("ERROR: Failed to load items data!\n")
		return
	
	items_manager = ItemsManager.new(items_data)
	
	# Load room data and initialize room manager
	var room_data = RoomLoader.load_data(ROOMS_DATA_PATH)
	if room_data.is_empty():
		print_output("ERROR: Failed to load room data!\n")
		return
	
	room_manager = RoomManager.new(room_data)
	
	print_output("Generating adventure...\n")
	generate_adventure()

# ========== ADVENTURE GENERATION ==========

func generate_adventure():
	var attempts = 0
	var success = false
	
	while attempts < MAX_GENERATION_ATTEMPTS and not success:
		attempts += 1
		print_output("Attempt %d/%d...\n" % [attempts, MAX_GENERATION_ATTEMPTS])
		
		# Clear previous attempt
		room_manager.clear_rooms()
		inventory.clear()
		game_won = false
		
		# Select random objective
		objectives_manager.select_random_objective()
		
		# Generate rooms and items
		create_rooms()
		
		# Test if adventure is completable
		if test_adventure_completable():
			success = true
			game_ready = true
			print_output("Adventure generated successfully!\n\n")
			start_game()
		else:
			print_output("Not completable, regenerating...\n")
	
	if not success:
		print_output("\n!!! FAILED TO GENERATE COMPLETABLE ADVENTURE !!!\n")
		print_output("Please restart to try again.\n")
		game_ready = false

func create_rooms():
	var room_count = MIN_ROOMS + randi() % 3
	
	# Generate rooms using room manager
	room_manager.generate_rooms(room_count)
	current_room = room_manager.get_starting_room()
	room_manager.create_room_connections()
	
	# Place items and requirements
	distribute_items()
	
	# Place objective in final room
	room_manager.set_objective_room()

func distribute_items():
	var item_keys = items_manager.get_all_items()
	item_keys.shuffle()
	var room_keys = room_manager.get_room_list()
	
	# Place items in rooms (not in starting or objective room)
	var placeable_rooms = room_keys.slice(1, room_keys.size() - 1)
	var num_items = min(5 + randi() % 3, placeable_rooms.size())
	
	for i in range(num_items):
		if i < item_keys.size() and i < placeable_rooms.size():
			room_manager.add_item_to_room(placeable_rooms[i], item_keys[i])
	
	# For find_item objectives, place the target item in a room
	if objectives_manager.get_objective_type() == "find_item":
		place_objective_item(room_keys)
	
	# Add locked doors
	add_locked_doors(room_keys)

func place_objective_item(room_keys: Array):
	var target_item = objectives_manager.get_objective_target().to_lower().replace(" ", "_")
	var target_room_idx = 1 + randi() % (room_keys.size() - 1)
	if not room_manager.room_has_item(room_keys[target_room_idx], target_item):
		room_manager.add_item_to_room(room_keys[target_room_idx], target_item)

func add_locked_doors(room_keys: Array):
	if room_keys.size() <= 2:
		return
	
	var num_locks = 1 + randi() % 2
	var key_items = ["rusty_key", "golden_key", "silver_key", "master_key", 
					 "skeleton_key", "passcode", "id_card", "keycard", "crowbar"]
	
	for lock_idx in range(num_locks):
		if lock_idx >= room_keys.size() - 1:
			break
			
		var lock_room_idx = min(2 + lock_idx * 2, room_keys.size() - 2)
		var selected_key = key_items[randi() % key_items.size()]
		
		# Ensure key exists in the world
		if not room_manager.is_item_in_any_room(selected_key) and lock_room_idx > 0:
			var key_room_idx = randi() % lock_room_idx
			room_manager.add_item_to_room(room_keys[key_room_idx], selected_key)
		
		room_manager.set_room_requirement(room_keys[lock_room_idx + 1], selected_key)

# ========== ADVENTURE VALIDATION ==========

func test_adventure_completable() -> bool:
	var sim_state = {
		"inventory": [],
		"current": current_room,
		"visited": {},
		"items_collected": []
	}
	
	var max_steps = 100
	for steps in range(max_steps):
		sim_state.visited[sim_state.current] = true
		
		# Collect items
		collect_items_in_simulation(sim_state)
		
		# Check objective completion
		if room_manager.is_objective_room(sim_state.current):
			return can_complete_objective(sim_state.inventory)
		
		# Try to move
		if not try_move_simulation(sim_state):
			return false
	
	return false

func collect_items_in_simulation(sim_state: Dictionary):
	var room_items = room_manager.get_room_items(sim_state.current)
	for item in room_items:
		if item not in sim_state.items_collected:
			sim_state.inventory.append(item)
			sim_state.items_collected.append(item)

func can_complete_objective(sim_inventory: Array) -> bool:
	var obj_type = objectives_manager.get_objective_type()
	match obj_type:
		"find_item":
			var target_item = objectives_manager.get_objective_target().to_lower().replace(" ", "_")
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
	var connections = room_manager.get_room_connections(sim_state.current)
	
	# Try unvisited rooms first
	for direction in connections:
		var next_room = connections[direction]
		var required = room_manager.get_room_requirement(next_room)
		
		if required and required not in sim_state.inventory:
			continue
		
		if next_room not in sim_state.visited:
			sim_state.current = next_room
			return true
	
	# Try any accessible room
	for direction in connections:
		var next_room = connections[direction]
		var required = room_manager.get_room_requirement(next_room)
		
		if not required or required in sim_state.inventory:
			sim_state.current = next_room
			return true
	
	return false

# ========== GAME START ==========

func start_game():
	print_output("=== ADVENTURE BEGINS ===\n")
	print_output("Your objective: %s\n\n" % get_objective_description())
	print_output("Commands: look, inventory, north/south/east/west, take [item], use [item]\n\n")
	look_room()

func get_objective_description() -> String:
	var obj_type = objectives_manager.get_objective_type()
	var obj_target = objectives_manager.get_objective_target()
	
	match obj_type:
		"find_item":
			return "find the %s" % obj_target
		"rescue":
			return "rescue %s" % obj_target
		"activate":
			return "activate the %s" % obj_target
		"destroy":
			return "destroy the %s" % obj_target
		"escape":
			return "escape from the %s" % obj_target
	return "complete unknown objective"

# ========== INPUT HANDLING ==========

func _on_send_pressed():
	process_command()

func _on_input_submitted(_text: String):
	process_command()

func process_command():
	if not game_ready:
		return
	
	var command = input_field.text.strip_edges().to_lower()
	input_field.text = ""
	
	if command.is_empty():
		return
	
	print_output("\n> %s\n" % command)
	
	if game_won:
		print_output("You already won! Restart to play again.\n")
		return
	
	var parts = command.split(" ", false)
	var action = parts[0]
	
	match action:
		"look":
			look_room()
		"inventory", "inv", "i":
			show_inventory()
		"north", "south", "east", "west", "n", "s", "e", "w":
			var dir = action[0]
			var full_dir = {"n": "north", "s": "south", "e": "east", "w": "west"}.get(dir, action)
			move_direction(full_dir)
		"take", "get", "pick":
			if parts.size() > 1:
				take_item(parts[1])
			else:
				print_output("Take what?\n")
		"use":
			if parts.size() > 1:
				use_item(parts[1])
			else:
				print_output("Use what?\n")
		"help":
			print_output("Commands: look, inventory, north/south/east/west, take [item], use [item]\n")
		_:
			print_output("Unknown command. Type 'help' for commands.\n")

# ========== GAME ACTIONS ==========

func look_room():
	print_output("=== %s ===\n" % current_room)
	print_output("%s\n" % room_manager.get_room_description(current_room))
	
	var room_items = room_manager.get_room_items(current_room)
	if room_items.size() > 0:
		print_output("\nYou see: %s\n" % ", ".join(room_items))
	
	var connections = room_manager.get_room_connections(current_room)
	if connections.size() > 0:
		print_output("\nExits: %s\n" % ", ".join(connections.keys()))
	
	if room_manager.is_objective_room(current_room):
		check_objective()

func show_inventory():
	if inventory.size() == 0:
		print_output("Your inventory is empty.\n")
	else:
		print_output("Inventory: %s\n" % ", ".join(inventory))

func move_direction(direction: String):
	var connections = room_manager.get_room_connections(current_room)
	
	if direction not in connections:
		print_output("You can't go that way.\n")
		return
	
	var next_room = connections[direction]
	var required = room_manager.get_room_requirement(next_room)
	
	if required and required not in inventory:
		print_output("The way is blocked. You need: %s\n" % required)
		return
	
	current_room = next_room
	print_output("You move %s.\n\n" % direction)
	look_room()

func take_item(item_name: String):
	if not room_manager.room_has_item(current_room, item_name):
		print_output("There's no %s here.\n" % item_name)
		return
	
	room_manager.remove_item_from_room(current_room, item_name)
	inventory.append(item_name)
	print_output("You take the %s.\n" % item_name)

func use_item(item_name: String):
	if item_name not in inventory:
		print_output("You don't have that item.\n")
		return
	
	print_output("You use the %s.\n" % item_name)
	
	if room_manager.is_objective_room(current_room):
		check_objective()

# ========== OBJECTIVE COMPLETION ==========

func check_objective():
	if not is_objective_complete():
		return
	
	game_won = true
	print_output("\n*** CONGRATULATIONS! ***\n")
	print_output("%s\n" % get_victory_message())
	print_output("You won the adventure!\n")

func is_objective_complete() -> bool:
	var obj_type = objectives_manager.get_objective_type()
	match obj_type:
		"find_item":
			var target_key = objectives_manager.get_objective_target().to_lower().replace(" ", "_")
			return target_key in inventory
		"rescue", "activate", "escape":
			return true
		"destroy":
			var destructive_items = ["sword", "hammer", "pickaxe", "crowbar", "staff", "wand"]
			for item in destructive_items:
				if item in inventory:
					return true
			return true
	return false

func get_victory_message() -> String:
	var obj_type = objectives_manager.get_objective_type()
	var obj_target = objectives_manager.get_objective_target()
	
	match obj_type:
		"find_item":
			return "You found the %s!" % obj_target
		"rescue":
			return "You successfully rescued %s!" % obj_target
		"activate":
			return "You activated the %s!" % obj_target
		"destroy":
			return "You destroyed the %s!" % obj_target
		"escape":
			return "You escaped from the %s!" % obj_target
	return "You completed your objective!"

# ========== UI UTILITIES ==========

func print_output(text: String):
	output_text.text += text
	await get_tree().process_frame
	var scroll = $VBoxContainer/ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	
	
