extends Node2D
class_name EditorMenu

signal control_event
signal level_event

@onready var mega_row: Node2D = $MegaRow
@onready var background_row: Node2D = $BackgroundRow


func _ready():
	background_row.visible = false
	add_row(background_row)
	add_row(mega_row)
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()


func add_row(row: Node) -> void:
	var window_size = get_viewport().get_visible_rect().size
	row.max_width = window_size.x
	if row.has_signal("control_event"):
		row.control_event.connect(_on_control_event)
	if row.has_signal("level_event"):
		row.level_event.connect(_on_level_event)
	_position_rows()


func remove_row(row) -> void:
	remove_child(row)
	_on_size_changed()


func get_height() -> float:
	var height = 0
	for row in get_children():
		height += row.get_dimensions().y
	return height


func _position_rows() -> void:
	var y = 0
	for row in get_children():
		row.position.y = y
		y += row.get_dimensions().y
	_on_size_changed()


func _on_size_changed():
	var window_size = get_viewport().get_visible_rect().size
	position = Vector2(0, window_size.y - get_height())


func _on_control_event(event: Dictionary) -> void:
	print("EditorMenu::_on_control_event ", event)
	control_event.emit(event)
	background_row.visible = event.get("tool") == "bg"


func _on_level_event(event: Dictionary) -> void:
	print("EditorMenu::_on_level_event ", event)
	level_event.emit(event)
