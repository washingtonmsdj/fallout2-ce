class_name NPCSpawn
extends RefCounted

## Dados de spawn de um NPC no mapa

@export var npc_id: String = ""
@export var proto_id: int = 0
@export var position: Vector2i = Vector2i.ZERO
@export var elevation: int = 0
@export var direction: int = 0  # 0-5 para hexagonal

# Comportamento
var ai_type: String = "default"  # "default", "aggressive", "defensive", "coward"
var patrol_points: Array = []
var dialogue_id: String = ""

# Estado inicial
var initial_hp: int = 0
var initial_ap: int = 0
var equipment: Array = []  # IDs de itens


func _init() -> void:
	pass


## Inicializar NPC com valores
func setup(p_npc_id: String, p_proto_id: int, p_position: Vector2i) -> NPCSpawn:
	npc_id = p_npc_id
	proto_id = p_proto_id
	position = p_position
	return self


## Adicionar ponto de patrulha
func add_patrol_point(point: Vector2i) -> void:
	patrol_points.append(point)


## Obter próximo ponto de patrulha
func get_next_patrol_point(current_index: int) -> Vector2i:
	if patrol_points.is_empty():
		return position
	
	var next_index = (current_index + 1) % patrol_points.size()
	return patrol_points[next_index]


## Adicionar item ao equipamento
func add_equipment(item_id: int) -> void:
	equipment.append(item_id)


## Remover item do equipamento
func remove_equipment(item_id: int) -> void:
	equipment.erase(item_id)


## Obter direção em radianos
func get_direction_radians() -> float:
	# Hexagonal: 0=N, 1=NE, 2=SE, 3=S, 4=SW, 5=NW
	return (direction * PI / 3.0)


## Validar dados do NPC
func validate() -> Array:
	var errors: Array = []
	
	if npc_id.is_empty():
		errors.append("NPC ID cannot be empty")
	
	if proto_id < 0:
		errors.append("NPC proto_id cannot be negative")
	
	if direction < 0 or direction > 5:
		errors.append("NPC direction must be 0-5")
	
	if ai_type.is_empty():
		errors.append("NPC ai_type cannot be empty")
	
	return errors
