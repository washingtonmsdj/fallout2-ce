class_name MapObject
extends RefCounted

## Dados de um objeto no mapa (cenários, móveis, etc)

@export var id: String = ""
@export var type: String = ""  # "scenery", "wall", "door", etc
@export var position: Vector2i = Vector2i.ZERO
@export var elevation: int = 0
@export var rotation: float = 0.0
@export var proto_id: int = 0

# Propriedades do objeto
var sprite_id: int = 0
var frame_id: int = 0
var light_radius: int = 0
var light_intensity: float = 0.0

# Flags
var is_walkable: bool = false
var is_transparent: bool = true
var is_locked: bool = false
var is_open: bool = false


func _init() -> void:
	pass


## Inicializar objeto com valores
func setup(p_id: String, p_type: String, p_position: Vector2i, p_proto_id: int) -> MapObject:
	id = p_id
	type = p_type
	position = p_position
	proto_id = p_proto_id
	return self


## Obter sprite do objeto
func get_sprite() -> int:
	return sprite_id


## Obter frame de animação
func get_frame() -> int:
	return frame_id


## Obter forma de colisão
func get_collision_shape() -> String:
	match type:
		"door":
			return "rect"
		"wall":
			return "rect"
		"scenery":
			return "circle"
		_:
			return "circle"


## Verificar se objeto é interativo
func is_interactive() -> bool:
	return type in ["door", "container", "switch"]


## Verificar se objeto bloqueia movimento
func blocks_movement() -> bool:
	return not is_walkable


## Verificar se objeto bloqueia visão
func blocks_vision() -> bool:
	return not is_transparent


## Abrir/fechar objeto (para portas, etc)
func toggle_state() -> void:
	if type == "door":
		is_open = not is_open


## Trancar/destrancar objeto
func set_locked(state: bool) -> void:
	is_locked = state


## Validar dados do objeto
func validate() -> Array:
	var errors: Array = []
	
	if id.is_empty():
		errors.append("Object ID cannot be empty")
	
	if type.is_empty():
		errors.append("Object type cannot be empty")
	
	if proto_id < 0:
		errors.append("Object proto_id cannot be negative")
	
	return errors
