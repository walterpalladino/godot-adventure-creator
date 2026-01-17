extends RefCounted
class_name GameManager

# Managers
var _objectives_manager : ObjectivesManager = null
var _room_manager : RoomManager = null
var _items_manager : ItemsManager = null
var _inventory_manager : InventoryManager = null


# Game state
var _current_room : String = ""
#var _inventory : Array = []
var _game_won : bool = false
var _game_ready : bool = false

var _min_rooms : int = 5

# Current objective
var _current_objective_type = ""
var _current_objective_target = ""


func _init(p__room_manager : RoomManager, p__items_manager : ItemsManager, p__objectives_manager : ObjectivesManager, p__min_rooms : int = 5) -> void:
	_room_manager = p__room_manager
	_items_manager = p__items_manager
	_objectives_manager = p__objectives_manager
	_min_rooms = p__min_rooms

	_inventory_manager = InventoryManager.new()

var current_room : String :
	get:
		return _current_room
	set(new_value):
		_current_room = new_value

var objective_type : String:
	get:
		return _current_objective_type

var objective_target : String:
	get:
		return _current_objective_target

var game_ready : bool :
	get:
		return _game_ready
	set(new_value):
		_game_ready = new_value

var game_won : bool :
	get:
		return _game_won

#var inventory : Array :
#	get:
#		return _inventory


func select_random_objective():
	var obj_keys = _objectives_manager.objective_templates.keys()
	_current_objective_type = obj_keys[randi() % obj_keys.size()]
	_current_objective_target = _objectives_manager.objective_templates[_current_objective_type][randi() % _objectives_manager.objective_templates[_current_objective_type].size()]

	


func generate_adventure() :
		
	# Clear previous attempt
	_room_manager.clear_rooms()
	_inventory_manager.clear()
	_game_won = false
	_game_ready = false
	
	# Select random objective
	select_random_objective()
	
	# Generate rooms and items
	create_rooms()
	
	_game_ready = true
	

func create_rooms():
	var room_count = _min_rooms + randi() % 3
	
	# Generate rooms using room manager
	_room_manager.generate_rooms(room_count)
	_current_room = _room_manager.get_starting_room()
	_room_manager.create_room_connections()
	
	# Place items and requirements
	distribute_items()
	
	# Place objective in final room
	_room_manager.set_objective_room()


func distribute_items():
	var item_keys = _items_manager.get_all_items()
	item_keys.shuffle()
	var room_keys = _room_manager.get_room_list()
	
	# Place items in rooms (not in starting or objective room)
	var placeable_rooms = room_keys.slice(1, room_keys.size() - 1)
	var num_items = min(5 + randi() % 3, placeable_rooms.size())
	
	for i in range(num_items):
		if i < item_keys.size() and i < placeable_rooms.size():
			_room_manager.add_item_to_room(placeable_rooms[i], item_keys[i])
	
	# For find_item objectives, place the target item in a room
	if objective_type == "find_item":
		place_objective_item(room_keys)
	
	# Add locked doors
	add_locked_doors(room_keys)
	
	
func place_objective_item(room_keys: Array):
	var target_item = objective_target.to_lower().replace(" ", "_")
	var target_room_idx = 1 + randi() % (room_keys.size() - 1)
	if not _room_manager.room_has_item(room_keys[target_room_idx], target_item):
		_room_manager.add_item_to_room(room_keys[target_room_idx], target_item)


func add_locked_doors(room_keys: Array):
	if room_keys.size() <= 2:
		return
	
	var num_locks = 1 + randi() % 2
#	var key_items = ["rusty_key", "golden_key", "silver_key", "master_key", 
#					 "skeleton_key", "passcode", "id_card", "keycard", "crowbar"]
	var key_items = _items_manager.get_items_used_for(["unlock_door", "pry_open", "break"])
	#print(key_items)
	
	for lock_idx in range(num_locks):
		if lock_idx >= room_keys.size() - 1:
			break
			
		var lock_room_idx = min(2 + lock_idx * 2, room_keys.size() - 2)
		var selected_key = key_items[randi() % key_items.size()]
		
		# Ensure key exists in the world
		if not _room_manager.is_item_in_any_room(selected_key) and lock_room_idx > 0:
			var key_room_idx = randi() % lock_room_idx
			_room_manager.add_item_to_room(room_keys[key_room_idx], selected_key)
		
		_room_manager.set_room_requirement(room_keys[lock_room_idx + 1], selected_key)


func is_objective_room(room_name : String) -> bool:
	return _room_manager.is_objective_room(room_name)	


func is_current_objective_room() -> bool:
	return _room_manager.is_objective_room(_current_room)	


func remove_item_from_current_room(item: String) :
	_room_manager.remove_item_from_room(_current_room, item)
	

func add_item_from_current_room(item: String) :
	_room_manager.add_item_to_room(_current_room, item)


func current_room_has_item(item: String) -> bool:
	return _room_manager.room_has_item(_current_room, item)
		
func get_room_requirement(room_name: String):
	return _room_manager.get_room_requirement(room_name)
		

func get_room_connections(room_name : String) -> Dictionary:
	return _room_manager.get_room_connections(room_name)


func get_current_room_connections() -> Dictionary:
	return _room_manager.get_room_connections(_current_room)


func get_room_items(room_name : String) -> Array:
	return _room_manager.get_room_items(room_name)

func get_current_room_items() -> Array:
	return _room_manager.get_room_items(_current_room)


func get_current_room_description() -> String:
	return _room_manager.get_room_description(current_room)

func pick_item(item_name : String):
	remove_item_from_current_room(item_name)
	#_inventory.append(item_name)
	_inventory_manager.add_item(item_name)

func drop_item(item_name : String):
	add_item_from_current_room(item_name)
	_inventory_manager.remove_item(item_name)


func get_inventory() -> Array:
	return _inventory_manager.get_items()

func check_inventory_as_item(item_name : String) -> bool:
	return _inventory_manager.has_item(item_name)


func can_access_room(room_name : String) -> bool:

	var required_item = get_room_requirement(room_name)
	if required_item and !_inventory_manager.has_item(required_item):
		return false
	else:
		return true
