extends ParallaxBackground

@export_enum("Blue", "Brown", "Gray", "Green", "Pink", "Purple", "Yellow") var background_image : String = "Green"
@onready var background_img: TextureRect = $ParallaxLayer/BackgroundImg
@onready var parallax_layer: ParallaxLayer = $ParallaxLayer
var scroll_speed: float = 20.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_img.texture = load("res://Assets/Pixel Adventure 1/Background/" + background_image + ".png")

func _process(delta: float) -> void:
	parallax_layer.motion_offset.y += scroll_speed * delta
