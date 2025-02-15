extends Node2D

const CLEANUP_INTERVAL = 60  # 600 seconds (1 minutes)
var last_cleanup_time = 0
var tile_update_timestamps = {}
var layers: Layers

@onready var layer_panel: Node2D = get_node("../UI/LayerPanel")
@onready var bg: Node2D = get_node("../BG")
@onready var editor_events: Node2D = get_node("../EditorEvents")
@onready var edit_cursors: Node2D = get_node("../EditorCursorLayer/EditorCursors")


func _ready():
	editor_events.connect("level_event", _on_level_event)


func init(_layers: Layers) -> void:
	layers = _layers


func _process(delta: float) -> void:
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_cleanup_time >= CLEANUP_INTERVAL:
		_cleanup_old_timestamps()
		last_cleanup_time = current_time


func _cleanup_old_timestamps() -> void:
	var current_time = Time.get_unix_time_from_system()
	for key in tile_update_timestamps.keys():
		if current_time - tile_update_timestamps[key] > CLEANUP_INTERVAL:
			tile_update_timestamps.erase(key)


func _on_level_event(event: Dictionary) -> void:
	print("Penciler::_on_level_event: ", event.type)
	if event.type == EditorEvents.SET_TILE:
		var coords = Vector2i(event.coords.x, event.coords.y)
		var coords_key = str(coords.x) + "_" + str(coords.y)
		
		if event.has("timestamp"):
			var new_timestamp = event.timestamp
			
			if not tile_update_timestamps.has(coords_key) or tile_update_timestamps[coords_key] < new_timestamp:
				_set_tile(event, coords, coords_key, new_timestamp)
		else:
			_set_tile(event, coords, coords_key)

	if event.type == EditorEvents.ADD_LINE:
		var lines: Node2D = layers.get_node(event.layer_name + "/Lines")
		var line = Line2D.new()
		lines.add_child(line)
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.position = Vector2(event.position.x, event.position.y)
		
		var converted_points = []
		for point_dict in event.points:
			converted_points.append(Vector2(point_dict.x, point_dict.y))
		line.points = converted_points

	if event.type == EditorEvents.ADD_LAYER:
		print("addlayer: " + event.name)
		layers.add_layer(event.name)

	if event.type == EditorEvents.DELETE_LAYER:
		print("remlayer: " + event.name)
		layers.remove_layer(event.name)

	if event.type == EditorEvents.ADD_USERTEXT:
		var usertextboxes: Node2D = layers.get_node(event.layer_name + "/UserTextboxes")
		var usertextbox_scene: PackedScene = preload("res://pages/editor/menu/UserTextbox.tscn")
		var usertextbox = usertextbox_scene.instantiate()
		usertextbox.set_usertext_properties(event.usertext, event.font, event.font_size)
		usertextboxes.add_child(usertextbox)
		usertextbox.position = Vector2(event.position.x, event.position.y)

	if event.type == EditorEvents.ROTATE_LAYER:
		var layer = layers.get_node(event.layer_name)
		layer.get_node("TileMap").rotation_degrees = event.rotation

	if event.type == EditorEvents.LAYER_DEPTH:
		var layer = layers.get_node(event.layer_name)
		layer.set_depth(event.depth)

	if event.type == EditorEvents.SET_BACKGROUND:
		bg.set_bg(event.bg)


func _set_tile(event: Dictionary, coords: Vector2i, coords_key: String, new_timestamp: int = -1) -> void:
	var tilemap: TileMap = layers.get_node(event.layer_name + "/TileMap")
	tilemap.set_cell(0, coords, 0, Helpers.to_atlas_coords(event.block_id))
	
	if new_timestamp != -1:
		tile_update_timestamps[coords_key] = new_timestamp
