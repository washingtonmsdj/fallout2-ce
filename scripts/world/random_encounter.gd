class_name RandomEncounter extends Resource

@export var id: String
@export var name: String
@export var enemies: Array[String]  # Critter template IDs
@export var terrain_type: String = ""
@export var min_player_level: int = 1
@export var max_player_level: int = 50
@export var probability: float = 0.5  # 0.0-1.0

func _to_string() -> String:
	return "RandomEncounter(%s)" % name
