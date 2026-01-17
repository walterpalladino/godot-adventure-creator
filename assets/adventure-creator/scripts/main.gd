extends Control

# Configuration
const MIN_ROOMS = 5
const MAX_GENERATION_ATTEMPTS = 10

# Data file paths
const OBJECTIVES_DATA_PATH = "res://assets/adventure-creator/data/objectives.json"
const ROOMS_DATA_PATH = "res://assets/adventure-creator/data/rooms.json"
const ITEMS_DATA_PATH = "res://assets/adventure-creator/data/items.json"

# Managers
var game_manager : GameManager = null


# UI References
@onready var output_text = $VBoxContainer/ScrollContainer/OutputText
@onready var input_field = $VBoxContainer/HBoxContainer/InputField
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton



func _ready():
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_input_submitted)
	initialize()

func initialize():
	
	var objectives_manager = null
	var room_manager = null
	var items_manager = null

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
	
	game_manager = GameManager.new(room_manager, items_manager, objectives_manager, MIN_ROOMS)
	
	print_output("Generating adventure...\n")
	
	generate_adventure()

# ========== ADVENTURE GENERATION ==========

func generate_adventure():
	
	var adventure_tester : AdventureTester = AdventureTester.new(game_manager)

	var attempts = 0
	var success = false
	
	while attempts < MAX_GENERATION_ATTEMPTS and not success:
		attempts += 1
		print_output("Attempt %d/%d...\n" % [attempts, MAX_GENERATION_ATTEMPTS])

		game_manager.generate_adventure()
		
		# Test if adventure is completable
		if adventure_tester.test_adventure_completable():
			success = true
			game_manager.game_ready = true
			print_output("Adventure generated successfully!\n\n")
			start_game()
		else:
			print_output("Not completable, regenerating...\n")
	
	if not success:
		print_output("\n!!! FAILED TO GENERATE COMPLETABLE ADVENTURE !!!\n")
		print_output("Please restart to try again.\n")
		game_manager.game_ready = false


# ========== GAME START ==========

func start_game():
	print_output("=== ADVENTURE BEGINS ===\n")
	print_output("Your objective: %s\n\n" % get_objective_description())
	print_output("Commands: look, inventory, north/south/east/west, take [item], use [item], drop [item]\n\n")
	look_room()

func get_objective_description() -> String:
	var obj_type = game_manager.objective_type
	var obj_target = game_manager.objective_target
	
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
	if not game_manager.game_ready:
		return
	
	var command = input_field.text.strip_edges().to_lower()
	input_field.text = ""
	
	if command.is_empty():
		return
	
	print_output("\n> %s\n" % command)
	
	if game_manager.game_won:
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
		"drop":
			if parts.size() > 1:
				drop_item(parts[1])
			else:
				print_output("Drop what?\n")
		"use":
			if parts.size() > 1:
				use_item(parts[1])
			else:
				print_output("Use what?\n")
		"help":
			print_output("Commands: look, inventory, north/south/east/west, take [item], use [item], drop [item]\n")
		_:
			print_output("Unknown command. Type 'help' for commands.\n")

# ========== GAME ACTIONS ==========

func look_room():
	
	print_output("=== %s ===\n" % game_manager.current_room)
	print_output("%s\n" % game_manager.get_current_room_description())
	
	var room_items = game_manager.get_current_room_items()
	if room_items.size() > 0:
		print_output("\nYou see: %s\n" % ", ".join(room_items))
	
	var connections = game_manager.get_current_room_connections()
	if connections.size() > 0:
		print_output("\nExits: %s\n" % ", ".join(connections.keys()))
	
	if game_manager.is_current_objective_room():
		check_objective()

func show_inventory():
	if game_manager.get_inventory().size() == 0:
		print_output("Your inventory is empty.\n")
	else:
		print_output("Inventory: %s\n" % ", ".join(game_manager.get_inventory()))

func move_direction(direction: String):
	var connections = game_manager.get_current_room_connections()
	
	if direction not in connections:
		print_output("You can't go that way.\n")
		return
	
	var next_room = connections[direction]
	var required = game_manager.get_room_requirement(next_room)
	
	#if required and required not in game_manager.inventory:
	if !game_manager.can_access_room(next_room):
		print_output("The way is blocked. You need: %s\n" % required)
		return
	
	game_manager.current_room = next_room
	print_output("You move %s.\n\n" % direction)
	look_room()

func take_item(item_name: String):
	if not game_manager.current_room_has_item(item_name):
		print_output("There's no %s here.\n" % item_name)
		return

	game_manager.pick_item(item_name)	
	print_output("You take the %s.\n" % item_name)

func drop_item(item_name: String):
	
	if !game_manager.check_inventory_as_item(item_name):
		print_output("You don't have %s in your inventory.\n" % item_name)
		return
		
	game_manager.drop_item(item_name)
	print_output("You dropped the %s.\n" % item_name)

func use_item(item_name: String):
	if item_name not in game_manager.inventory:
		print_output("You don't have that item.\n")
		return
	
	print_output("You use the %s.\n" % item_name)
	
	if game_manager.is_current_objective_room():
		check_objective()

# ========== OBJECTIVE COMPLETION ==========

func check_objective():
	if not is_objective_complete():
		return
	
	game_manager.game_won = true
	print_output("\n*** CONGRATULATIONS! ***\n")
	print_output("%s\n" % get_victory_message())
	print_output("You won the adventure!\n")

func is_objective_complete() -> bool:
	var obj_type = game_manager.objective_type
	match obj_type:
		"find_item":
			var target_key = game_manager.objective_target.to_lower().replace(" ", "_")
			return target_key in game_manager.inventory
		"rescue", "activate", "escape":
			return true
		"destroy":
			var destructive_items = ["sword", "hammer", "pickaxe", "crowbar", "staff", "wand"]
			for item in destructive_items:
				if item in game_manager.inventory:
					return true
			return true
	return false

func get_victory_message() -> String:
	var obj_type = game_manager.objective_type
	var obj_target = game_manager.objective_target
	
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
	
	
