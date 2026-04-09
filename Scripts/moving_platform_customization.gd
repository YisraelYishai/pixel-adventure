extends Path2D

@export_enum("Platform1", "Platform2") var PlatformType: String = "Platform1"
@export var max_speed: float = 75.0

var chain_texture: Texture2D = preload("res://Assets/Pixel Adventure 1/Traps/Platforms/Chain.png")
var spacing: float = 16.0

@onready var chain_container: Node2D = $ChainContainer


func _ready():
	generate_chain()


func generate_chain():
	for child in chain_container.get_children():
		child.queue_free()

	var length = curve.get_baked_length()
	var distance = 0.0

	while distance < length:
		var pos = curve.sample_baked(distance)

		var chain = Sprite2D.new()
		chain.texture = chain_texture
		chain.position = pos

		chain_container.add_child(chain)

		distance += spacing
