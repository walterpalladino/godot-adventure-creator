extends RefCounted
class_name ObjectivesManager

# Objective templates data
var objective_templates = {}

# Current objective
var current_type = ""
var current_target = ""

func _init(p_objectives: Dictionary):
	objective_templates = p_objectives

func select_random_objective():
	var obj_keys = objective_templates.keys()
	current_type = obj_keys[randi() % obj_keys.size()]
	current_target = objective_templates[current_type][randi() % objective_templates[current_type].size()]

func get_objective_type() -> String:
	return current_type

func get_objective_target() -> String:
	return current_target
	
	
