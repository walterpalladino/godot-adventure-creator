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

func can_item_be_used_for(item_name: String, uses: Array) -> bool:
	if not has_item(item_name):
		return false
		
	return item_uses[item_name].any(func(use): return uses.has(use))	
	
	
func get_items_used_for(uses: Array) -> Array:

	var item_keys : Array = []

	for item in item_uses:
		if can_item_be_used_for(item, uses):
			item_keys.append(item)

	return item_keys
