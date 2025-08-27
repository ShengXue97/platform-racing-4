extends ItemDispenser
class_name ItemDispenserInfinite


func dispense_item(player: Node2D, tile_map_layer: TileMapLayer, coords: Vector2i):
	player.set_item()
