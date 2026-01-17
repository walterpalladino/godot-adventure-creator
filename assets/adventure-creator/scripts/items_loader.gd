extends Object
class_name ItemsLoader

static func load_data(path: String) -> Dictionary:
	return FileUtils.load_json_file(path)
