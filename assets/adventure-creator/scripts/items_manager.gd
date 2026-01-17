extends RefCounted
class_name ItemsManager

# Item uses data
var item_uses = {}

func _init(p_items: Dictionary):
	item_uses = p_items

func get_item_uses(item_name: String) -> Array:
	return item_uses.get(item_name, [])

func get_all_items() -> Array:
	return item_uses.keys()

func has_item(item_name: String) -> bool:
	return item_name in item_uses

func can_item_be_used_for(item_name: String, use: String) -> bool:
	if not has_item(item_name):
		return false
	return use in item_uses[item_name]
	
