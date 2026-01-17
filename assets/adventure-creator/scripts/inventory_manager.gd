extends RefCounted
class_name InventoryManager

var _inventory : Array = []
var _max_items : int = 0

func _init(p_max_items: int = 0):
	_max_items = p_max_items

func max_items() -> int:
	return _max_items

func add_item(p_item_name: String) -> bool:
	# Check if max items reached (0 means unlimited)
	if _max_items > 0 and _inventory.size() >= _max_items:
		return false
	
	_inventory.append(p_item_name)
	return true

func has_item(p_item_name: String) -> bool:
	return p_item_name in _inventory

func remove_item(p_item_name: String) -> bool:
	if not has_item(p_item_name):
		return false
	
	_inventory.erase(p_item_name)
	return true

func get_items() -> Array:
	return _inventory.duplicate()

func clear():
	_inventory.clear()

func get_count() -> int:
	return _inventory.size()

func is_full() -> bool:
	if _max_items == 0:
		return false
	return _inventory.size() >= _max_items

func get_items_as_string() -> String:
	if _inventory.is_empty():
		return ""
	return ", ".join(_inventory)
	
