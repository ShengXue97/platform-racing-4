extends Tile
class_name SafetyNet


func init():
	matter_type = Tile.GAS
	area.push_back(safety_net)


func safety_net(player: Node2D, tilemap: TileMap, coords: Vector2i):
	player.position.x = player.last_safe_position.x
	player.position.y = player.last_safe_position.y

	if (player.last_safe_layer != null and (player.last_safe_layer.get_node("Players") != player.get_parent())):
		player.get_parent().remove_child(player)
		player.last_safe_layer.get_node("Players").add_child(player)
		player.set_depth(round(player.last_safe_layer.follow_viewport_scale * 10))
		player.force_remove_body_shape(coords)
		
