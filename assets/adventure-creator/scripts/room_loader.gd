extends Object
class_name RoomLoader

static func load_data(path: String) -> Dictionary:
	return FileUtils.load_json_file(path)
