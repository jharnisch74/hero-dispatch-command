# DataLoader.gd
# Loads hero and mission data from JSON files (Godot 4.5 compatible)

extends Node

class_name DataLoader

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: File not found: %s" % path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: Failed to open file: %s" % path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.parse(json_string)
	if json.error != OK:
		push_error("DataLoader: Failed to parse JSON in %s. Error: %s" % [path, json.error_string])
		return {}

	return json.result

func load_heroes(path: String) -> Array:
	var data = load_json(path)
	if not data.has("heroes"):
		push_error("DataLoader: No 'heroes' key in %s" % path)
		return []
	return data.heroes

func load_missions(path: String) -> Array:
	var data = load_json(path)
	if not data.has("missions"):
		push_error("DataLoader: No 'missions' key in %s" % path)
		return []
	return data.missions
