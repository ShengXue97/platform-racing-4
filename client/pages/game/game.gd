extends Node2D
class_name Game

static var pr2_level_id
static var game: Node2D

@onready var back_button = $UI/Container/BackButton
@onready var minimap: Minimap = $UI/Container/Minimap
@onready var level_manager: LevelManager = $LevelManager

var used_rects: Dictionary = {}
var current_player_layer: String = ""
var characters: Dictionary = {}

func set_used_rect(layer_name: String, rect: Rect2i) -> void:
	used_rects[layer_name] = rect


func get_used_rect(layer_name: String) -> Rect2i:
	return used_rects.get(layer_name, Rect2i())


func clear_used_rects() -> void:
	used_rects.clear()


func set_current_player_layer(layer_name: String) -> void:
	current_player_layer = layer_name


func get_current_player_layer() -> String:
	return current_player_layer


static func get_target_layer_node() -> Node:
	var target_layer_name: String = game.level_manager.layers.get_target_layer()
	return game.level_manager.layers.get_node(target_layer_name)
	

func _ready():
	NetworkEvents.on_client_start.connect(_handle_connected)
	NetworkEvents.on_server_start.connect(_handle_host)
	NetworkEvents.on_peer_join.connect(_handle_new_peer)
	NetworkEvents.on_peer_leave.connect(_handle_leave)
	NetworkEvents.on_client_stop.connect(_handle_stop)
	NetworkEvents.on_server_stop.connect(_handle_stop)
	
	back_button.connect("pressed", _on_back_pressed)
	
	var penciler: Node2D = get_node("Penciler")
	var editor_events: EditorEvents = get_node("EditorEvents")
	
	editor_events.connect_to([level_manager.level_decoder])
	penciler.init(level_manager.layers, $BG, editor_events, null)
	
	if !Game.pr2_level_id or Game.pr2_level_id == '0':
		_activate_game()
	else:
		print("Game: Loading level id: " + Game.pr2_level_id)
		var http_request = get_node("HTTPRequest")
		http_request.request_completed.connect(func(_result, _response_code, _headers, body):
			var json = JSON.new()
			json.parse(body.get_string_from_utf8())
			var response = json.get_data()
			if !response:
				return
			if response.get("error", ''):
				return
			
			level_manager.decode_level(response, false)
			_activate_game()
		)
		if Game.pr2_level_id:
			var error = http_request.request(ApiManager.get_base_url() + "/pr2/level/" + Game.pr2_level_id)
			if error != OK:
				push_error("An error occurred in the HTTP request.")
	
	Game.game = self


func _activate_game() -> void:
	var player_manager: PlayerManager = get_node("PlayerManager")
	
	level_manager.activate_node()
	#player_manager.spawn_player(level_manager.layers, level_manager.tiles)
	
	minimap.init(self)
	level_manager.calc_used_rect()


func finish():
	Main.set_scene(Main.TITLE)


func _exit_tree():
	level_manager.clear()
	clear_used_rects()
	Game.game = null


func _on_back_pressed():
	Main.set_scene(Main.TITLE)
	
func _handle_connected(id: int):
	# Spawn an character for us
	_spawn(id)

func _handle_host():
	# Spawn own character on host machine
	_spawn(1)

func _handle_new_peer(id: int):
	# Spawn an character for new player
	var character = _spawn(id)
	var camera: Camera2D = character.find_child("Camera")
	camera.enabled = false

func _handle_leave(id: int):
	if not characters.has(id):
		return
	
	var character = characters[id] as Node
	character.queue_free()
	characters.erase(id)

func _handle_stop():
	# Remove all characters on game end
	for character in characters.values():
		character.queue_free()
	characters.clear()

func _spawn(id: int) -> CharacterBody2D:
	var player_manager: PlayerManager = get_node("PlayerManager")
	var character =  player_manager.spawn_player(level_manager.layers, level_manager.tiles)
		
	characters[id] = character
	character.name += " #%d" % id
	
	# Character is always owned by server
	character.set_multiplayer_authority(1)

	# Character's input object is owned by player
	var input = character.find_child("Input")
	input.set_multiplayer_authority(id)
	return character
