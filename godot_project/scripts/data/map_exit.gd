class_name MapExit
extends RefCounted

## Dados de uma saída de mapa (conexão com outro mapa)

@export var exit_id: String = ""
@export var target_map: String = ""
@export var target_position: Vector2i = Vector2i.ZERO
@export var target_elevation: int = 0

# Zona de saída
@export var exit_zone: Rect2i = Rect2i()

# Tipo de transição
var transition_type: String = "fade"  # "fade", "slide", "instant"
var transition_duration: float = 0.5


func _init() -> void:
	pass


## Inicializar saída com valores
func setup(p_exit_id: String, p_target_map: String, p_target_pos: Vector2i) -> MapExit:
	exit_id = p_exit_id
	target_map = p_target_map
	target_position = p_target_pos
	return self


## Verificar se posição está na zona de saída
func is_in_exit_zone(pos: Vector2i) -> bool:
	return exit_zone.has_point(pos)


## Definir zona de saída
func set_exit_zone(zone: Rect2i) -> void:
	exit_zone = zone


## Obter duração da transição
func get_transition_duration() -> float:
	return transition_duration


## Validar dados da saída
func validate() -> Array:
	var errors: Array = []
	
	if exit_id.is_empty():
		errors.append("Exit ID cannot be empty")
	
	if target_map.is_empty():
		errors.append("Target map cannot be empty")
	
	if exit_zone.size.x <= 0 or exit_zone.size.y <= 0:
		errors.append("Exit zone must have positive size")
	
	if transition_type.is_empty():
		errors.append("Transition type cannot be empty")
	
	if transition_duration <= 0.0:
		errors.append("Transition duration must be positive")
	
	return errors
