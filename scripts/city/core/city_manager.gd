## CityManager - Coordenador central de todos os sistemas da cidade
## Gerencia ciclo de vida, inicialização e atualização de sistemas
class_name CityManager
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal systems_initialized()
signal systems_ready()
signal city_loaded(city_name: String)
signal city_saved(city_name: String)
signal tick_completed(delta: float)

# =============================================================================
# CONFIGURATION
# =============================================================================
@export var grid_size: Vector2i = CityConfig.GRID_SIZE_DEFAULT
@export var auto_initialize: bool = true
@export var enable_debug: bool = false

# =============================================================================
# SYSTEM REFERENCES
# =============================================================================
var event_bus: CityEventBus
var grid_system: Node  # GridSystem
var road_system: Node  # RoadSystem
var zone_system: Node  # ZoneSystem
var building_system: Node  # BuildingSystem
var citizen_system: Node  # CitizenSystem
var economy_system: Node  # EconomySystem
var faction_system: Node  # FactionSystem
var weather_system: Node  # WeatherSystem
var defense_system: Node  # DefenseSystem
var power_system: Node  # PowerSystem
var water_system: Node  # WaterSystem
var vehicle_system: Node  # VehicleSystem
var crafting_system: Node  # CraftingSystem
var quest_system: Node  # QuestSystem
var event_system: Node  # EventSystem

# =============================================================================
# STATE
# =============================================================================
var is_initialized: bool = false
var is_paused: bool = false
var city_name: String = "New Settlement"
var game_time: float = 0.0  # Tempo total de jogo em segundos
var current_hour: int = 8  # Hora atual (0-23)
var current_day: int = 1

# Sistema de ticks para atualização escalonada
var tick_accumulator: float = 0.0
const TICK_RATE: float = 0.1  # 10 ticks por segundo

# Ordem de atualização dos sistemas
var update_order: Array[String] = [
	"weather_system",
	"power_system",
	"water_system",
	"economy_system",
	"citizen_system",
	"building_system",
	"defense_system",
	"vehicle_system",
	"quest_system",
	"event_system"
]

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready():
	_setup_event_bus()
	
	if auto_initialize:
		call_deferred("initialize_systems")

func _process(delta: float):
	if not is_initialized or is_paused:
		return
	
	_update_game_time(delta)
	_process_tick(delta)

## Configura o EventBus
func _setup_event_bus():
	event_bus = CityEventBus.new()
	event_bus.name = "EventBus"
	add_child(event_bus)
	
	# Conectar eventos de debug
	if enable_debug:
		event_bus.debug_message.connect(_on_debug_message)
		event_bus.performance_warning.connect(_on_performance_warning)

## Inicializa todos os sistemas na ordem correta
func initialize_systems():
	if is_initialized:
		push_warning("CityManager: Systems already initialized")
		return
	
	_log("Initializing city systems...")
	
	# Criar sistemas na ordem de dependência
	_create_grid_system()
	_create_road_system()
	_create_zone_system()
	_create_building_system()
	_create_citizen_system()
	_create_economy_system()
	_create_faction_system()
	_create_weather_system()
	_create_defense_system()
	_create_power_system()
	_create_water_system()
	_create_vehicle_system()
	_create_crafting_system()
	_create_quest_system()
	_create_event_system()
	
	# Inicializar sistemas
	_initialize_all_systems()
	
	is_initialized = true
	systems_initialized.emit()
	_log("All systems initialized successfully")

## Cria sistema de grid
func _create_grid_system():
	# Placeholder - será implementado na Task 3
	var system = Node.new()
	system.name = "GridSystem"
	system.set_meta("grid_size", grid_size)
	add_child(system)
	grid_system = system
	_log("GridSystem created (placeholder)")

## Cria sistema de estradas
func _create_road_system():
	var system = Node.new()
	system.name = "RoadSystem"
	add_child(system)
	road_system = system
	_log("RoadSystem created (placeholder)")

## Cria sistema de zonas
func _create_zone_system():
	var system = Node.new()
	system.name = "ZoneSystem"
	add_child(system)
	zone_system = system
	_log("ZoneSystem created (placeholder)")

## Cria sistema de edifícios
func _create_building_system():
	var system = Node.new()
	system.name = "BuildingSystem"
	add_child(system)
	building_system = system
	_log("BuildingSystem created (placeholder)")

## Cria sistema de cidadãos
func _create_citizen_system():
	var system = Node.new()
	system.name = "CitizenSystem"
	add_child(system)
	citizen_system = system
	_log("CitizenSystem created (placeholder)")

## Cria sistema econômico
func _create_economy_system():
	var system = Node.new()
	system.name = "EconomySystem"
	add_child(system)
	economy_system = system
	_log("EconomySystem created (placeholder)")

## Cria sistema de facções
func _create_faction_system():
	var system = Node.new()
	system.name = "FactionSystem"
	add_child(system)
	faction_system = system
	_log("FactionSystem created (placeholder)")

## Cria sistema de clima
func _create_weather_system():
	var system = Node.new()
	system.name = "WeatherSystem"
	add_child(system)
	weather_system = system
	_log("WeatherSystem created (placeholder)")

## Cria sistema de defesa
func _create_defense_system():
	var system = Node.new()
	system.name = "DefenseSystem"
	add_child(system)
	defense_system = system
	_log("DefenseSystem created (placeholder)")

## Cria sistema de energia
func _create_power_system():
	var system = Node.new()
	system.name = "PowerSystem"
	add_child(system)
	power_system = system
	_log("PowerSystem created (placeholder)")

## Cria sistema de água
func _create_water_system():
	var system = Node.new()
	system.name = "WaterSystem"
	add_child(system)
	water_system = system
	_log("WaterSystem created (placeholder)")

## Cria sistema de veículos
func _create_vehicle_system():
	var system = Node.new()
	system.name = "VehicleSystem"
	add_child(system)
	vehicle_system = system
	_log("VehicleSystem created (placeholder)")

## Cria sistema de crafting
func _create_crafting_system():
	var system = Node.new()
	system.name = "CraftingSystem"
	add_child(system)
	crafting_system = system
	_log("CraftingSystem created (placeholder)")

## Cria sistema de quests
func _create_quest_system():
	var system = Node.new()
	system.name = "QuestSystem"
	add_child(system)
	quest_system = system
	_log("QuestSystem created (placeholder)")

## Cria sistema de eventos
func _create_event_system():
	var system = Node.new()
	system.name = "EventSystem"
	add_child(system)
	event_system = system
	_log("EventSystem created (placeholder)")

## Inicializa todos os sistemas
func _initialize_all_systems():
	# Cada sistema será inicializado quando implementado
	# Por enquanto, apenas emite sinal de pronto
	systems_ready.emit()

# =============================================================================
# UPDATE LOOP
# =============================================================================

## Atualiza tempo de jogo
func _update_game_time(delta: float):
	game_time += delta
	
	# Calcular hora atual
	var total_hours = game_time / CityConfig.HOUR_LENGTH_SECONDS
	var new_hour = int(total_hours) % 24
	
	if new_hour != current_hour:
		var old_hour = current_hour
		current_hour = new_hour
		event_bus.time_of_day_changed.emit(old_hour, new_hour)
		
		# Novo dia
		if new_hour == 0:
			var old_day = current_day
			current_day += 1
			event_bus.day_changed.emit(old_day, current_day)

## Processa tick de atualização
func _process_tick(delta: float):
	tick_accumulator += delta
	
	if tick_accumulator >= TICK_RATE:
		tick_accumulator -= TICK_RATE
		_update_systems(TICK_RATE)
		tick_completed.emit(TICK_RATE)

## Atualiza sistemas na ordem definida
func _update_systems(delta: float):
	for system_name in update_order:
		var system = get(system_name)
		if system and system.has_method("update_tick"):
			system.update_tick(delta)

# =============================================================================
# PUBLIC API
# =============================================================================

## Pausa/despausa a simulação
func set_paused(paused: bool):
	is_paused = paused

## Retorna se está pausado
func is_simulation_paused() -> bool:
	return is_paused

## Obtém sistema por nome
func get_system(system_name: String) -> Node:
	match system_name:
		"grid": return grid_system
		"road": return road_system
		"zone": return zone_system
		"building": return building_system
		"citizen": return citizen_system
		"economy": return economy_system
		"faction": return faction_system
		"weather": return weather_system
		"defense": return defense_system
		"power": return power_system
		"water": return water_system
		"vehicle": return vehicle_system
		"crafting": return crafting_system
		"quest": return quest_system
		"event": return event_system
		_: return null

## Habilita/desabilita sistema
func set_system_enabled(system_name: String, enabled: bool):
	var system = get_system(system_name)
	if system:
		system.set_process(enabled)
		system.set_physics_process(enabled)
		_log("System '%s' %s" % [system_name, "enabled" if enabled else "disabled"])

## Retorna estatísticas da cidade
func get_city_stats() -> Dictionary:
	return {
		"name": city_name,
		"game_time": game_time,
		"current_hour": current_hour,
		"current_day": current_day,
		"is_paused": is_paused,
		"is_initialized": is_initialized
	}

## Retorna hora formatada
func get_formatted_time() -> String:
	return "%02d:00" % current_hour

## Retorna se é dia
func is_daytime() -> bool:
	return current_hour >= 6 and current_hour < 20

## Salva estado da cidade
func save_city(slot: int = 0) -> bool:
	event_bus.save_started.emit(slot)
	
	# TODO: Implementar serialização completa
	var save_data = {
		"version": 1,
		"city_name": city_name,
		"game_time": game_time,
		"current_day": current_day,
		"grid_size": {"x": grid_size.x, "y": grid_size.y}
	}
	
	var success = true  # Placeholder
	event_bus.save_completed.emit(slot, success)
	
	if success:
		city_saved.emit(city_name)
	
	return success

## Carrega estado da cidade
func load_city(slot: int = 0) -> bool:
	event_bus.load_started.emit(slot)
	
	# TODO: Implementar deserialização completa
	var success = true  # Placeholder
	event_bus.load_completed.emit(slot, success)
	
	if success:
		city_loaded.emit(city_name)
	
	return success

## Reinicia a cidade
func reset_city():
	_log("Resetting city...")
	
	# Limpar sistemas
	is_initialized = false
	game_time = 0.0
	current_hour = 8
	current_day = 1
	
	# Remover sistemas existentes
	for child in get_children():
		if child != event_bus:
			child.queue_free()
	
	# Reinicializar
	call_deferred("initialize_systems")

# =============================================================================
# DEBUG
# =============================================================================

func _log(message: String):
	if enable_debug:
		print("[CityManager] %s" % message)
		if event_bus:
			event_bus.emit_debug("CityManager", message, 0)

func _on_debug_message(system: String, message: String, level: int):
	var level_str = ["INFO", "WARN", "ERROR"][mini(level, 2)]
	print("[%s][%s] %s" % [level_str, system, message])

func _on_performance_warning(system: String, metric: String, value: float):
	push_warning("[PERF][%s] %s: %.2f" % [system, metric, value])
