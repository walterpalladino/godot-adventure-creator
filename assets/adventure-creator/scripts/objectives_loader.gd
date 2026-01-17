extends Object
class_name ObjectivesLoader

static func load_data(path: String) -> Dictionary:
	return FileUtils.load_json_file(path)
