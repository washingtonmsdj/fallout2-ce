class_name ItemSpawn
extends RefCounted

## Dados de spawn de um item no mapa

@export var item_id: String = ""
@export var proto_id: int = 0
@export var position: Vector2i = Vector2i.ZERO
@export var elevation: int = 0
@export var quantity: int = 1

# Propriedades do item
var condition: float = 1.0  # 0.0 a 1.0 (1.0 = perfeito)
var is_hidden: bool = false
var is_trapped: bool = false


func _init() -> void:
	pass


## Inicializar item com valores
func setup(p_item_id: String, p_proto_id: int, p_position: Vector2i, p_quantity: int) -> ItemSpawn:
	item_id = p_item_id
	proto_id = p_proto_id
	position = p_position
	quantity = p_quantity
	return self


## Definir condição do item
func set_condition(value: float) -> void:
	condition = clamp(value, 0.0, 1.0)


## Obter condição do item
func get_condition() -> float:
	return condition


## Marcar item como escondido
func set_hidden(state: bool) -> void:
	is_hidden = state


## Marcar item como armadilhado
func set_trapped(state: bool) -> void:
	is_trapped = state


## Validar dados do item
func validate() -> Array:
	var errors: Array = []
	
	if item_id.is_empty():
		errors.append("Item ID cannot be empty")
	
	if proto_id < 0:
		errors.append("Item proto_id cannot be negative")
	
	if quantity <= 0:
		errors.append("Item quantity must be positive")
	
	if condition < 0.0 or condition > 1.0:
		errors.append("Item condition must be between 0.0 and 1.0")
	
	return errors
