extends Area2D
class_name TriggerZone
## Zona de gatilho que executa scripts quando o jogador entra

@export var trigger_id: String = ""
@export var script_id: String = ""
@export var elevation_change: int = 0  # Para transições entre andares
@export var destination_map: String = ""  # Para transições entre mapas
@export var destination_position: Vector2 = Vector2.ZERO

var has_triggered: bool = false
var is_one_time: bool = true

signal triggered(player: Critter)
signal player_entered
signal player_exited

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

## Chamado quando algo entra na zona
func _on_area_entered(area: Area2D) -> void:
	if area is Critter:
		var critter = area as Critter
		if critter.is_player:
			_trigger(critter)
			player_entered.emit()

## Chamado quando algo sai da zona
func _on_area_exited(area: Area2D) -> void:
	if area is Critter:
		var critter = area as Critter
		if critter.is_player:
			player_exited.emit()

## Ativa o gatilho
func _trigger(player: Critter) -> void:
	if is_one_time and has_triggered:
		return
	
	has_triggered = true
	
	# Executar script customizado
	if not script_id.is_empty():
		_execute_script(player)
	
	# Transição de elevação
	if elevation_change != 0:
		_handle_elevation_change(player)
	
	# Transição de mapa
	if not destination_map.is_empty():
		_handle_map_transition(player)
	
	triggered.emit(player)

## Executa um script customizado
func _execute_script(player: Critter) -> void:
	# Implementação de scripts customizados
	pass

## Trata mudança de elevação
func _handle_elevation_change(player: Critter) -> void:
	# Implementação de mudança de elevação
	pass

## Trata transição de mapa
func _handle_map_transition(player: Critter) -> void:
	# Implementação de transição de mapa
	pass

## Reseta o gatilho
func reset() -> void:
	has_triggered = false

## Retorna informações sobre o gatilho
func get_trigger_info() -> Dictionary:
	return {
		"id": trigger_id,
		"script_id": script_id,
		"elevation_change": elevation_change,
		"destination_map": destination_map,
		"destination_position": destination_position,
		"has_triggered": has_triggered,
		"is_one_time": is_one_time
	}
