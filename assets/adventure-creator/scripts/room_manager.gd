extends RefCounted
class_name RoomManager

# Room data loaded from JSON
var room_definitions = {}

# Active rooms in current adventure
var rooms = {}
var starting_room = ""
var objective_room = ""

func _init(p_rooms: Dictionary):
	room_definitions = p_rooms

func clear_rooms():
	rooms.clear()
	starting_room = ""
	objective_room = ""

func generate_rooms(count: int):
	var available_rooms = room_definitions.keys()
	available_rooms.shuffle()
	
	# Create specified number of rooms
	for i in range(min(count, available_rooms.size())):
		var room_name = available_rooms[i]
		rooms[room_name] = {
			"description": room_definitions[room_name],
			"connections": {},
			"items": [],
			"required_item": null,
			"has_objective": false
		}
	
	# Set starting room
	if rooms.size() > 0:
		starting_room = rooms.keys()[0]

func create_room_connections():
	var room_keys = rooms.keys()
	
	# Connect rooms in a main path
	for i in range(room_keys.size() - 1):
		var from_room = room_keys[i]
		var to_room = room_keys[i + 1]
		
		# Add bidirectional connection
		rooms[from_room]["connections"]["north"] = to_room
		rooms[to_room]["connections"]["south"] = from_room
	
	# Add some extra connections for complexity
	if room_keys.size() > 3:
		var extra_connections = min(2, room_keys.size() / 3)
		for i in range(extra_connections):
			var from_idx = 1 + i * 2
			var to_idx = min(from_idx + 2, room_keys.size() - 1)
			
			if from_idx < room_keys.size() and to_idx < room_keys.size():
				rooms[room_keys[from_idx]]["connections"]["east"] = room_keys[to_idx]
				rooms[room_keys[to_idx]]["connections"]["west"] = room_keys[from_idx]

func set_objective_room():
	var room_keys = rooms.keys()
	if room_keys.size() > 0:
		objective_room = room_keys[-1]
		rooms[objective_room]["has_objective"] = true

func get_starting_room() -> String:
	return starting_room

func get_room_list() -> Array:
	return rooms.keys()

func get_room_description(room_name: String) -> String:
	if room_name in rooms:
		return rooms[room_name]["description"]
	return "Unknown room"

func get_room_connections(room_name: String) -> Dictionary:
	if room_name in rooms:
		return rooms[room_name]["connections"]
	return {}

func get_room_items(room_name: String) -> Array:
	if room_name in rooms:
		return rooms[room_name]["items"]
	return []

func get_room_requirement(room_name: String):
	if room_name in rooms:
		return rooms[room_name].get("required_item", null)
	return null

func is_objective_room(room_name: String) -> bool:
	if room_name in rooms:
		return rooms[room_name]["has_objective"]
	return false

func add_item_to_room(room_name: String, item: String):
	if room_name in rooms:
		if item not in rooms[room_name]["items"]:
			rooms[room_name]["items"].append(item)

func remove_item_from_room(room_name: String, item: String):
	if room_name in rooms:
		rooms[room_name]["items"].erase(item)

func room_has_item(room_name: String, item: String) -> bool:
	if room_name in rooms:
		return item in rooms[room_name]["items"]
	return false

func is_item_in_any_room(item: String) -> bool:
	for room in rooms.values():
		if item in room["items"]:
			return true
	return false

func set_room_requirement(room_name: String, required_item: String):
	if room_name in rooms:
		rooms[room_name]["required_item"] = required_item
