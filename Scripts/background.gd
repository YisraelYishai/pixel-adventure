extends ParallaxBackground

@export_enum("Blue", "Brown", "Gray", "Green", "Pink", "Purple", "Yellow", "Random") var background_image : String = "Green"
@onready var background_img: TextureRect = $ParallaxLayer/BackgroundImg
@onready var parallax_layer: ParallaxLayer = $ParallaxLayer
var scroll_speed: float = 25.0

func _ready() -> void:
	var picks: Array[String] = ["Blue", "Brown", "Gray", "Green", "Pink", "Purple", "Yellow"]
	if background_image == "Random":
		background_image = picks.pick_random()
	background_img.texture = load("res://Assets/Pixel Adventure 1/Background/" + background_image + ".png")

func _process(delta: float) -> void:
	parallax_layer.motion_offset.y += scroll_speed * delta
