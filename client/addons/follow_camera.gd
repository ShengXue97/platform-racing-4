extends Node2D
## Makes the parent node follow the active camera in the viewport.
## Updates position and scale based on camera position and zoom with smooth lerping.

var parent: Node2D
var lerp_speed: float = 10.0


func _ready():
	parent = get_parent()


func _process(delta):
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		var target_position: Vector2 = camera.get_screen_center_position()
		var target_scale: Vector2 = Vector2.ONE / camera.zoom
		
		parent.position = parent.position.lerp(target_position, lerp_speed * delta)
		parent.scale = parent.scale.lerp(target_scale, lerp_speed * delta)
		
