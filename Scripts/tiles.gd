extends TileMapLayer

@onready var shadow_layer: TileMapLayer = $Shadows
var shadow_source_id = 3
var shadow_atlas_coords = Vector2i.ZERO
var shadow_pixel_offset = Vector2(-3, 3)

func _ready() -> void:
	shadow_layer.position = shadow_pixel_offset
	changed.connect(update_shadows.call_deferred)
	update_shadows()

func update_shadows() -> void:
	shadow_layer.clear()
	for cell in get_used_cells():
		var data := get_cell_tile_data(cell)
		if data != null and data.get_custom_data("casts_shadow"):
			shadow_layer.set_cell(cell, shadow_source_id, shadow_atlas_coords)
