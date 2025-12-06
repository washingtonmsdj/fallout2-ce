class_name Location extends Resource

@export var id: String
@export var name: String
@export var position: Vector2
@export var map_scene: PackedScene
@export var danger_level: int = 0  # 0-10
@export var is_city: bool = false
@export var faction: String = ""
@export var description: String = ""

func _to_string() -> String:
	return "Location(%s)" % name
