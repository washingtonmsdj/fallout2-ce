class_name WorldmapSystem extends Node

signal travel_started(from: Location, to: Location)
signal travel_completed(location: Location)
signal encounter_triggered(encounter: RandomEncounter)
signal location_discovered(location: Location)

var player_position: Vector2 = Vector2.ZERO
var discovered_locations: Array[Location] = []
var current_vehicle: Vehicle = null
var all_locations: Dictionary = {}  # {location_id: Location}
var all_encounters: Array[RandomEncounter] = []

const BASE_SPEED: float = 10.0  # tiles per hour
const ENCOUNTER_CHECK_INTERVAL: float = 1.0  # hours

func _ready() -> void:
	pass

func register_location(location: Location) -> void:
	if location and location.id:
		all_locations[location.id] = location

func register_encounter(encounter: RandomEncounter) -> void:
	if encounter:
		all_encounters.append(encounter)

func start_travel(destination: Location) -> void:
	if not destination:
		return
	
	var from = get_location_at_position(player_position)
	travel_started.emit(from, destination)

func calculate_travel_time(from: Vector2, to: Vector2) -> float:
	var distance = from.distance_to(to)
	var speed = BASE_SPEED
	
	# Apply vehicle modifier if available
	if current_vehicle:
		speed *= current_vehicle.speed_multiplier
	
	# Travel time in hours
	return distance / speed

func check_random_encounter(player_level: int, danger_level: int) -> RandomEncounter:
	# Encounter probability based on danger level
	var base_probability = float(danger_level) / 10.0
	
	# Clamp between 0 and 1
	base_probability = clamp(base_probability, 0.0, 1.0)
	
	if randf() > base_probability:
		return null
	
	# Find valid encounters for player level
	var valid_encounters: Array[RandomEncounter] = []
	for encounter in all_encounters:
		if player_level >= encounter.min_player_level and player_level <= encounter.max_player_level:
			valid_encounters.append(encounter)
	
	if valid_encounters.is_empty():
		return null
	
	# Select random encounter
	var selected = valid_encounters[randi() % valid_encounters.size()]
	encounter_triggered.emit(selected)
	return selected

func discover_location(location: Location) -> void:
	if not location or location in discovered_locations:
		return
	
	discovered_locations.append(location)
	location_discovered.emit(location)

func get_discovered_locations() -> Array[Location]:
	return discovered_locations.duplicate()

func get_location_at_position(pos: Vector2) -> Location:
	for location in all_locations.values():
		if location.position.distance_to(pos) < 1.0:
			return location
	return null

func set_player_position(pos: Vector2) -> void:
	player_position = pos

func get_player_position() -> Vector2:
	return player_position

func set_current_vehicle(vehicle: Vehicle) -> void:
	current_vehicle = vehicle

func get_current_vehicle() -> Vehicle:
	return current_vehicle
