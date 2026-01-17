extends Control

# Configuration
const MIN_ROOMS = 5
const MAX_GENERATION_ATTEMPTS = 10

# Objective types and their possible goals
var objective_templates = {
	"find_item": [
		"Ancient Amulet", "Golden Key", "Sacred Scroll", "Crystal Orb", "Magic Ring",
		"Diamond Crown", "Philosopher's Stone", "Holy Grail", "Enchanted Sword", "Dragon Egg",
		"Star Map", "Lost Treasure", "Royal Scepter", "Mystic Compass", "Ancient Manuscript",
		"Cursed Idol", "Silver Chalice", "Emerald Tablet", "Phoenix Feather", "Moon Crystal"
	],
	"rescue": [
		"Princess Elena", "Professor Smith", "Lost Child", "Captured Knight", "Village Elder",
		"Duke Wellington", "Lady Blackwood", "Captain Rivers", "Oracle Maya", "Prince Adrian",
		"Scholar Thomas", "Merchant Anna", "Wizard Merlin", "Healer Catherine", "Explorer Jack",
		"Queen Isabella", "Astronomer Leo", "Botanist Rosa", "Guard Captain Marcus", "Diplomat Chen"
	],
	"activate": [
		"Ancient Portal", "Mystical Fountain", "Sacred Altar", "Power Generator", "Time Machine",
		"Crystal Conduit", "Dimensional Gate", "Eternal Flame", "Star Observatory", "Magic Circle",
		"Weather Control", "Teleporter", "Memory Archive", "Healing Spring", "Prophecy Stone",
		"Guardian Statue", "Energy Core", "Cosmic Beacon", "Spirit Shrine", "Warp Device"
	],
	"destroy": [
		"Cursed Artifact", "Dark Crystal", "Evil Tome", "Shadow Gate", "Plague Source",
		"Demon Seal", "Corrupted Core", "Nightmare Engine", "Void Anchor", "Chaos Orb"
	],
	"escape": [
		"Haunted Mansion", "Underground Dungeon", "Cursed Castle", "Frozen Fortress", "Lost Temple",
		"Abandoned Asylum", "Desert Tomb", "Sunken Ship", "Sky Prison", "Volcano Lair"
	]
}

# Item uses dictionary
var item_uses = {
	"rusty_key": ["unlock_door", "pry_open"],
	"golden_key": ["unlock_door", "unlock_chest"],
	"silver_key": ["unlock_door", "unlock_gate"],
	"master_key": ["unlock_door", "unlock_vault"],
	"skeleton_key": ["unlock_door", "unlock_any"],
	"torch": ["light_area", "burn", "scare_bats"],
	"lantern": ["light_area", "signal"],
	"candle": ["light_area", "melt_wax"],
	"rope": ["climb", "tie", "swing"],
	"chain": ["tie", "lock", "climb"],
	"grappling_hook": ["climb", "reach_high"],
	"crowbar": ["pry_open", "break", "lever"],
	"hammer": ["break", "repair", "pound"],
	"pickaxe": ["break", "mine", "dig"],
	"shovel": ["dig", "break_ground"],
	"passcode": ["unlock_door", "access_computer"],
	"id_card": ["unlock_door", "identify"],
	"keycard": ["unlock_door", "access_restricted"],
	"map": ["reveal_path", "navigate"],
	"compass": ["navigate", "find_north"],
	"telescope": ["see_far", "observe"],
	"potion": ["heal", "unlock_magic", "enhance"],
	"elixir": ["heal", "cure", "energize"],
	"antidote": ["cure", "neutralize_poison"],
	"gem": ["activate", "power_source", "unlock_magic"],
	"ruby": ["activate", "power_fire"],
	"sapphire": ["activate", "power_water"],
	"emerald": ["activate", "power_nature"],
	"diamond": ["activate", "power_light", "cut"],
	"crystal": ["activate", "power_source", "focus"],
	"lever": ["activate", "switch", "move"],
	"button": ["activate", "trigger"],
	"switch": ["activate", "toggle"],
	"note": ["reveal_clue", "read"],
	"journal": ["reveal_clue", "read", "learn"],
	"book": ["reveal_clue", "read", "learn_spell"],
	"scroll": ["reveal_clue", "read", "cast"],
	"letter": ["reveal_clue", "read"],
	"coin": ["currency", "insert", "weight"],
	"gold_bar": ["currency", "weight", "bribe"],
	"mirror": ["reflect", "see_truth", "signal"],
	"glass_shard": ["cut", "reflect"],
	"matches": ["light", "burn"],
	"flint": ["light", "spark"],
	"lockpick": ["unlock_door", "unlock_chest"],
	"wire": ["unlock_door", "tie", "conduct"],
	"magnet": ["attract", "pull", "collect"],
	"glue": ["stick", "repair", "seal"],
	"oil": ["lubricate", "burn", "slip"],
	"water_flask": ["drink", "pour", "extinguish"],
	"food_ration": ["eat", "restore_energy"],
	"medicine": ["heal", "cure"],
	"bandage": ["heal", "wrap"],
	"shield": ["protect", "block", "deflect"],
	"sword": ["cut", "fight", "lever"],
	"dagger": ["cut", "throw", "pry"],
	"staff": ["focus_magic", "support", "fight"],
	"wand": ["cast_spell", "point", "channel"],
	"amulet": ["protect", "unlock_magic", "detect"],
	"ring": ["unlock_magic", "enchant", "protect"],
	"cloak": ["hide", "protect_cold", "disguise"],
	"boots": ["walk_silent", "climb", "run_fast"],
	"gloves": ["protect_hands", "grip", "climb"],
	"helmet": ["protect", "see_dark"],
	"goggles": ["see_underwater", "protect_eyes"],
	"bag": ["carry_more", "store"],
	"chest": ["store", "transport"],
	"hourglass": ["measure_time", "activate"],
	"bell": ["signal", "ward_evil", "call"],
	"horn": ["signal", "call", "blow"],
	"flute": ["play_music", "charm", "signal"],
	"prism": ["split_light", "reveal", "focus"],
	"lens": ["magnify", "focus_light", "see_detail"],
	"thermometer": ["measure_temp", "detect"],
	"barometer": ["measure_pressure", "predict"],
	"sextant": ["navigate", "measure_angle"],
	"chisel": ["carve", "break", "shape"],
	"saw": ["cut", "break", "shape"],
	"drill": ["bore", "break", "pierce"],
	"paint": ["mark", "color", "seal"],
	"chalk": ["mark", "draw", "write"],
	"ink": ["write", "mark", "stain"],
	"quill": ["write", "mark"]
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
	var room_names = [
		# Classic mansion/castle rooms
		"Entrance Hall", "Grand Library", "Kitchen", "Master Bedroom", "Wine Cellar",
		"Garden", "Dusty Attic", "Study", "Portrait Gallery", "Vault",
		# Additional atmospheric rooms
		"Ballroom", "Conservatory", "Dining Hall", "Servant Quarters", "Tower Room",
		"Chapel", "Armory", "Trophy Room", "Music Room", "Observatory",
		"Dungeon", "Secret Passage", "Throne Room", "Alchemy Lab", "Treasure Room",
		"Crypt", "Underground Cave", "Clock Tower", "Great Hall", "Royal Chambers",
		"Smithy", "Stables", "Courtyard", "Meditation Chamber", "War Room",
		"Archive", "Scriptorium", "Torture Chamber", "Training Grounds", "Barracks",
		"Lighthouse", "Boathouse", "Watchtower", "Bridge", "Gatehouse",
		"Temple", "Shrine", "Sanctuary", "Cathedral", "Monastery",
		"Laboratory", "Workshop", "Storage Room", "Pantry", "Laundry",
		"Bath House", "Spa", "Sauna", "Pool Room", "Gymnasium"
	]
	
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
		# Classic rooms
		"Entrance Hall": "A grand entrance with marble floors and dusty paintings on the walls.",
		"Grand Library": "Towering shelves filled with ancient tomes reach toward the vaulted ceiling.",
		"Kitchen": "An old kitchen with rusty pots hanging above a cold, ash-filled fireplace.",
		"Master Bedroom": "A luxurious bedroom with a canopy bed and an ornate broken mirror.",
		"Wine Cellar": "A damp cellar lined with wine racks, cobwebs covering dusty bottles.",
		"Garden": "An overgrown garden where wilted flowers surround a crumbling fountain.",
		"Dusty Attic": "A cramped attic filled with old trunks, forgotten furniture, and thick dust.",
		"Study": "A scholar's study featuring a large oak desk covered in scattered papers.",
		"Portrait Gallery": "A long gallery where faded portraits seem to watch your every move.",
		"Vault": "A secure vault with thick metal walls and a heavy reinforced door.",
		
		# Atmospheric rooms
		"Ballroom": "An elegant ballroom with a crystal chandelier and polished marble floor.",
		"Conservatory": "A glass-walled room filled with exotic dead plants and broken pots.",
		"Dining Hall": "A vast dining hall with a long table set for a feast that never came.",
		"Servant Quarters": "Small, cramped quarters with simple beds and personal belongings.",
		"Tower Room": "A circular room at the top of a tower with windows facing all directions.",
		"Chapel": "A small chapel with wooden pews and stained glass windows casting colored light.",
		"Armory": "Walls lined with ancient weapons and suits of armor standing at attention.",
		"Trophy Room": "Mounted heads and hunting trophies adorn every available surface.",
		"Music Room": "A room with a grand piano, harps, and various musical instruments.",
		"Observatory": "A domed room with a large telescope pointing toward the stars.",
		
		# Mysterious rooms
		"Dungeon": "A dark, dank dungeon with iron bars and chains hanging from the walls.",
		"Secret Passage": "A narrow hidden corridor with stone walls and a musty smell.",
		"Throne Room": "A majestic throne room with a golden throne on a raised platform.",
		"Alchemy Lab": "Strange equipment, bubbling flasks, and mystical symbols cover the benches.",
		"Treasure Room": "Glittering piles of gold coins and jewels fill this locked chamber.",
		"Crypt": "Ancient stone sarcophagi line the walls of this underground burial chamber.",
		"Underground Cave": "A natural cave with stalactites dripping water and bioluminescent moss.",
		"Clock Tower": "Giant gears and mechanisms surround you, ticking rhythmically.",
		"Great Hall": "An enormous hall with high ceilings and faded banners hanging from the walls.",
		"Royal Chambers": "Opulent chambers decorated with gold trim and purple velvet.",
		
		# Functional rooms
		"Smithy": "A workshop with an anvil, forge, and various metalworking tools.",
		"Stables": "Empty stalls that once housed horses, with hay scattered on the ground.",
		"Courtyard": "An open-air courtyard with a dried-up fountain and overgrown plants.",
		"Meditation Chamber": "A peaceful room with cushions, incense holders, and calming symbols.",
		"War Room": "A strategic planning room with maps, flags, and miniature battlefield models.",
		"Archive": "Endless shelves of documents, scrolls, and historical records fill this room.",
		"Scriptorium": "Desks with quills, ink, and half-finished manuscripts cover the workspace.",
		"Torture Chamber": "A grim room with sinister devices and dark stains on the floor.",
		"Training Grounds": "An indoor space with practice dummies, targets, and training equipment.",
		"Barracks": "Rows of simple beds where soldiers once slept between battles.",
		
		# Specialized rooms
		"Lighthouse": "A tall tower room with a massive lamp and windows overlooking the sea.",
		"Boathouse": "A water-level room with docks and boats bobbing in dark water.",
		"Watchtower": "A defensive position with arrow slits and a commanding view.",
		"Bridge": "A covered bridge connecting two sections of the structure.",
		"Gatehouse": "A fortified entrance with murder holes and a portcullis mechanism.",
		"Temple": "A sacred space with an altar, offerings, and religious iconography.",
		"Shrine": "A small devotional space dedicated to a forgotten deity.",
		"Sanctuary": "A protected holy space with pews and devotional candles.",
		"Cathedral": "A grand religious space with soaring architecture and colored glass.",
		"Monastery": "A quiet contemplative space with simple furnishings and scriptures.",
		
		# Scientific rooms
		"Laboratory": "Scientific equipment, beakers, and research notes fill this room.",
		"Workshop": "A craftsman's workspace with tools, materials, and half-finished projects.",
		"Storage Room": "Shelves and crates packed with various supplies and equipment.",
		"Pantry": "A food storage room with shelves of preserved goods and dried herbs.",
		"Laundry": "Large wash basins, drying racks, and piles of old linens.",
		"Bath House": "A luxurious bathing area with a large tub and expensive soaps.",
		"Spa": "A relaxation room with massage tables and aromatic oils.",
		"Sauna": "A wooden room with benches and a cold stone heating pit.",
		"Pool Room": "An indoor pool with murky water and decorative tiles.",
		"Gymnasium": "An exercise space with weights, equipment, and training apparatus."
	}
	return descriptions.get(room_name, "A mysterious room filled with shadows and secrets.")

func distribute_items(room_keys: Array):
	var item_keys = item_uses.keys()
	item_keys.shuffle()
	
	# Place items in rooms (not in starting or objective room)
	var placeable_rooms = room_keys.slice(1, room_keys.size() - 1)
	
	# Place more items based on room count
	var num_items = min(5 + randi() % 3, placeable_rooms.size())
	
	for i in range(num_items):
		if i < item_keys.size() and i < placeable_rooms.size():
			rooms[placeable_rooms[i]]["items"].append(item_keys[i])
	
	# For find_item objectives, place the target item in a room
	if objective_type == "find_item":
		var target_item = objective_target.to_lower().replace(" ", "_")
		# Place target in a random room (not starting room)
		var target_room_idx = 1 + randi() % (room_keys.size() - 1)
		if target_item not in rooms[room_keys[target_room_idx]]["items"]:
			rooms[room_keys[target_room_idx]]["items"].append(target_item)
	
	# Add locked doors (require items to pass)
	if room_keys.size() > 2:
		# Lock some paths with required items
		var num_locks = 1 + randi() % 2  # 1-2 locked passages
		
		for lock_idx in range(num_locks):
			if lock_idx < room_keys.size() - 1:
				var lock_room_idx = min(2 + lock_idx * 2, room_keys.size() - 2)
				# Pick a key-type item that exists
				var key_items = ["rusty_key", "golden_key", "silver_key", "master_key", 
								 "skeleton_key", "passcode", "id_card", "keycard", "crowbar"]
				var selected_key = key_items[randi() % key_items.size()]
				
				# Make sure the key exists in the world
				var key_placed = false
				for room in rooms.values():
					if selected_key in room["items"]:
						key_placed = true
						break
				
				# If key not placed yet, add it to an earlier room
				if not key_placed and lock_room_idx > 0:
					var key_room_idx = randi() % lock_room_idx
					rooms[room_keys[key_room_idx]]["items"].append(selected_key)
				
				# Set the requirement
				rooms[room_keys[lock_room_idx + 1]]["required_item"] = selected_key

func test_adventure_completable() -> bool:
	# Simulate playing through the adventure
	var sim_inventory = []
	var sim_current = current_room
	var visited = {}
	var items_collected = []
	
	# Try to reach objective room and complete objective
	var max_steps = 100
	var steps = 0
	var objective_room_found = false
	
	while steps < max_steps:
		steps += 1
		visited[sim_current] = true
		
		# Collect items in current room
		for item in rooms[sim_current]["items"]:
			if item not in items_collected:
				sim_inventory.append(item)
				items_collected.append(item)
		
		# Check if we reached objective room
		if rooms[sim_current]["has_objective"]:
			objective_room_found = true
			
			# Now check if objective can be completed
			match objective_type:
				"find_item":
					# Check if target item is in inventory
					var target_item = objective_target.to_lower().replace(" ", "_")
					if target_item in sim_inventory:
						return true
				"rescue", "activate", "escape":
					# Just reaching the room is enough
					return true
				"destroy":
					# Check if we have a weapon or just allow it
					var has_weapon = false
					var weapons = ["sword", "hammer", "pickaxe", "crowbar", "staff", "wand"]
					for weapon in weapons:
						if weapon in sim_inventory:
							has_weapon = true
							break
					# Allow success even without weapon (simplified)
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
		
		# If stuck, try any room we can access (including visited)
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
				# Completely stuck, adventure not completable
				return false
	
	# If we found objective room but couldn't complete it
	if objective_room_found:
		return false
	
	# Couldn't even reach objective room
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
		"destroy":
			obj_desc = "destroy the %s" % objective_target
		"escape":
			obj_desc = "escape from the %s" % objective_target
	
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
			# Check if player has the target item in inventory
			var target_key = objective_target.to_lower().replace(" ", "_")
			if target_key in inventory:
				success = true
		"rescue":
			# Being in the objective room means rescue is successful
			success = true
		"activate":
			# Check if player has necessary items to activate
			# For activation, just being in room is enough (simplified)
			success = true
		"destroy":
			# Check if player has a weapon or destructive item
			var destructive_items = ["sword", "hammer", "pickaxe", "crowbar", "staff", "wand"]
			for item in destructive_items:
				if item in inventory:
					success = true
					break
			# If no weapon found, still allow success if in objective room
			if not success:
				success = true
		"escape":
			# For escape objectives, reaching the objective room means finding the exit
			success = true
	
	if success:
		game_won = true
		print_output("\n*** CONGRATULATIONS! ***\n")
		match objective_type:
			"find_item":
				print_output("You found the %s!\n" % objective_target)
			"rescue":
				print_output("You successfully rescued %s!\n" % objective_target)
			"activate":
				print_output("You activated the %s!\n" % objective_target)
			"destroy":
				print_output("You destroyed the %s!\n" % objective_target)
			"escape":
				print_output("You escaped from the %s!\n" % objective_target)
		print_output("You won the adventure!\n")

func print_output(text: String):
	output_text.text += text
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = $VBoxContainer/ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	
	
