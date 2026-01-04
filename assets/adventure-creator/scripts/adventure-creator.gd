extends Control

# Configuration
const MIN_ROOMS = 5
const MAX_GENERATION_ATTEMPTS = 10

# Objective types and their possible goals
var objective_templates = {
	"find_item": ["Ancient Amulet", "Golden Key", "Sacred Scroll", "Crystal Orb", "Magic Ring"],
	"rescue": ["Princess Elena", "Professor Smith", "Lost Child", "Captured Knight", "Village Elder"],
	"activate": ["Ancient Portal", "Mystical Fountain", "Sacred Altar", "Power Generator", "Time Machine"]
}

# Item uses dictionary
var item_uses = {
	"rusty_key": ["unlock_door", "pry_open"],
	"torch": ["light_area", "burn"],
	"rope": ["climb", "tie"],
	"crowbar": ["pry_open", "break"],
	"passcode": ["unlock_door"],
	"map": ["reveal_path"],
	"potion": ["heal", "unlock_magic"],
	"gem": ["activate", "power_source"],
	"lever": ["activate"],
	"note": ["reveal_clue"]
}

# Game state
var rooms = {}
var current_room = ""
var inventory = []
var objective_type = ""
var objective_target = ""
var game_won = false
var game_ready = false

# UI References
@onready var output_text = $VBoxContainer/ScrollContainer/OutputText
@onready var input_field = $VBoxContainer/HBoxContainer/InputField
@onready var send_button = $VBoxContainer/HBoxContainer/SendButton

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_input_submitted)
	
	print_output("=== TEXT ADVENTURE GENERATOR ===\n")
	print_output("Generating adventure...\n")
	
	generate_adventure()

func generate_adventure():
	var attempts = 0
	var success = false
	
	while attempts < MAX_GENERATION_ATTEMPTS and not success:
		attempts += 1
		print_output("Attempt %d/%d...\n" % [attempts, MAX_GENERATION_ATTEMPTS])
		
		# Clear previous attempt
		rooms.clear()
		inventory.clear()
		game_won = false
		
		# Select random objective
		var obj_keys = objective_templates.keys()
		objective_type = obj_keys[randi() % obj_keys.size()]
		objective_target = objective_templates[objective_type][randi() % objective_templates[objective_type].size()]
		
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
	var room_names = ["Entrance Hall", "Library", "Kitchen", "Bedroom", "Cellar", 
					  "Garden", "Attic", "Study", "Gallery", "Vault"]
	
	room_names.shuffle()
	
	# Create rooms
	for i in range(room_count):
		var room_name = room_names[i]
		rooms[room_name] = {
			"description": generate_room_description(room_name),
			"connections": {},
			"items": [],
			"required_item": null,
			"has_objective": false
		}
	
	# Set starting room
	current_room = room_names[0]
	
	# Connect rooms in a path
	var room_keys = rooms.keys()
	for i in range(room_keys.size() - 1):
		var from_room = room_keys[i]
		var to_room = room_keys[i + 1]
		
		# Add bidirectional connection
		rooms[from_room]["connections"]["north"] = to_room
		rooms[to_room]["connections"]["south"] = from_room
	
	# Add some extra connections
	if room_keys.size() > 3:
		rooms[room_keys[1]]["connections"]["east"] = room_keys[3]
		rooms[room_keys[3]]["connections"]["west"] = room_keys[1]
	
	# Place items and requirements
	distribute_items(room_keys)
	
	# Place objective in final room
	rooms[room_keys[-1]]["has_objective"] = true

func generate_room_description(room_name: String) -> String:
	var descriptions = {
		"Entrance Hall": "A grand entrance with marble floors and dusty paintings.",
		"Library": "Shelves filled with ancient books tower around you.",
		"Kitchen": "An old kitchen with rusty pots and a cold fireplace.",
		"Bedroom": "A musty bedroom with a canopy bed and broken mirror.",
		"Cellar": "A damp cellar with wine racks and cobwebs.",
		"Garden": "An overgrown garden with wilted flowers and a fountain.",
		"Attic": "A cramped attic filled with old trunks and forgotten memories.",
		"Study": "A scholar's study with a large desk and scattered papers.",
		"Gallery": "A long gallery with faded portraits watching you.",
		"Vault": "A secure vault with thick metal walls."
	}
	return descriptions.get(room_name, "A mysterious room.")

func distribute_items(room_keys: Array):
	var item_keys = item_uses.keys()
	item_keys.shuffle()
	
	# Place items in rooms (not in starting or objective room)
	var placeable_rooms = room_keys.slice(1, room_keys.size() - 1)
	
	for i in range(min(3, placeable_rooms.size())):
		if i < item_keys.size():
			rooms[placeable_rooms[i]]["items"].append(item_keys[i])
	
	# Add locked doors (require items)
	if room_keys.size() > 2:
		# Lock the path to objective room
		var lock_room_idx = room_keys.size() - 2
		rooms[room_keys[lock_room_idx + 1]]["required_item"] = item_keys[0] if item_keys.size() > 0 else "rusty_key"

func test_adventure_completable() -> bool:
	# Simulate playing through the adventure
	var sim_inventory = []
	var sim_current = current_room
	var visited = {}
	var items_collected = []
	
	# Try to reach objective room
	var max_steps = 100
	var steps = 0
	
	while steps < max_steps:
		steps += 1
		visited[sim_current] = true
		
		# Collect items in current room
		for item in rooms[sim_current]["items"]:
			if item not in items_collected:
				sim_inventory.append(item)
				items_collected.append(item)
		
		# Check if we reached objective
		if rooms[sim_current]["has_objective"]:
			return true
		
		# Try to move to unvisited connected rooms
		var moved = false
		for direction in rooms[sim_current]["connections"]:
			var next_room = rooms[sim_current]["connections"][direction]
			
			# Check if we can enter
			var required = rooms[next_room].get("required_item", null)
			if required and required not in sim_inventory:
				continue
			
			if next_room not in visited:
				sim_current = next_room
				moved = true
				break
		
		# If stuck, try any room we can access
		if not moved:
			var can_access = false
			for direction in rooms[sim_current]["connections"]:
				var next_room = rooms[sim_current]["connections"][direction]
				var required = rooms[next_room].get("required_item", null)
				if not required or required in sim_inventory:
					sim_current = next_room
					can_access = true
					break
			
			if not can_access:
				return false
	
	return false

func start_game():
	var obj_desc = ""
	match objective_type:
		"find_item":
			obj_desc = "find the %s" % objective_target
		"rescue":
			obj_desc = "rescue %s" % objective_target
		"activate":
			obj_desc = "activate the %s" % objective_target
	
	print_output("=== ADVENTURE BEGINS ===\n")
	print_output("Your objective: %s\n\n" % obj_desc)
	print_output("Commands: look, inventory, north/south/east/west, take [item], use [item]\n\n")
	
	look_room()

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

func look_room():
	var room = rooms[current_room]
	print_output("=== %s ===\n" % current_room)
	print_output("%s\n" % room["description"])
	
	if room["items"].size() > 0:
		print_output("\nYou see: %s\n" % ", ".join(room["items"]))
	
	if room["connections"].size() > 0:
		print_output("\nExits: %s\n" % ", ".join(room["connections"].keys()))
	
	if room["has_objective"]:
		check_objective()

func show_inventory():
	if inventory.size() == 0:
		print_output("Your inventory is empty.\n")
	else:
		print_output("Inventory: %s\n" % ", ".join(inventory))

func move_direction(direction: String):
	var room = rooms[current_room]
	
	if direction not in room["connections"]:
		print_output("You can't go that way.\n")
		return
	
	var next_room = room["connections"][direction]
	var required = rooms[next_room].get("required_item", null)
	
	if required and required not in inventory:
		print_output("The way is blocked. You need: %s\n" % required)
		return
	
	current_room = next_room
	print_output("You move %s.\n\n" % direction)
	look_room()

func take_item(item_name: String):
	var room = rooms[current_room]
	
	if item_name not in room["items"]:
		print_output("There's no %s here.\n" % item_name)
		return
	
	room["items"].erase(item_name)
	inventory.append(item_name)
	print_output("You take the %s.\n" % item_name)

func use_item(item_name: String):
	if item_name not in inventory:
		print_output("You don't have that item.\n")
		return
	
	print_output("You use the %s.\n" % item_name)
	
	# Check if using item helps with objective
	if rooms[current_room]["has_objective"]:
		check_objective()

func check_objective():
	var success = false
	
	match objective_type:
		"find_item":
			if objective_target.to_lower().replace(" ", "_") in inventory:
				success = true
		"rescue", "activate":
			# Simplified: just being in the room wins
			success = true
	
	if success:
		game_won = true
		print_output("\n*** CONGRATULATIONS! ***\n")
		print_output("You completed your objective: %s\n" % objective_target)
		print_output("You won the adventure!\n")

func print_output(text: String):
	output_text.text += text
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = $VBoxContainer/ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
