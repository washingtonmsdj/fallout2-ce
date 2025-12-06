## TrafficSystem - Sistema de tráfego de veículos
## Gerencia carros nas estradas
class_name TrafficSystem
extends Node

## Dados de um veículo
class Vehicle:
	var id: int
	var position: Vector2
	var target_position: Vector2
	var speed: float
	var color: Color
	var type: int  # 0=car, 1=truck, 2=bike
	
	func _init(p_id: int, p_pos: Vector2):
		id = p_id
		position = p_pos
		target_position = p_pos
		speed = randf_range(20.0, 40.0)
		# Cores variadas como no Citybound
		var colors = [
			Color(0.12, 0.18, 0.18),  # Preto
			Color(0.98, 0.98, 0.98),  # Branco
			Color(0.39, 0.48, 0.48),  # Cinza escuro
			Color(0.63, 0.70, 0.70),  # Cinza claro
			Color(0.23, 0.45, 0.72),  # Azul escuro
			Color(0.47, 0.69, 0.90),  # Azul claro
			Color(0.60, 0.80, 0.84),  # Turquesa
			Color(0.40, 0.64, 0.48),  # Verde escuro
			Color(0.72, 0.67, 0.54),  # Bege
			Color(0.57, 0.48, 0.36),  # Marrom
			Color(0.78, 0.51, 0.40),  # Vermelho tijolo
			Color(0.87, 0.59, 0.54),  # Vermelho tomate
			Color(0.78, 0.54, 0.63),  # Roxo vinho
			Color(0.57, 0.39, 0.51),  # Roxo berinjela
			Color(0.34, 0.31, 0.60),  # Azul-roxo
			Color(0.31, 0.39, 0.60),  # Azul-cinza
			Color(0.67, 0.62, 0.62),  # Cinza-vermelho
			Color(0.91, 0.91, 0.98),  # Branco-azulado
			Color(0.38, 0.50, 0.37),  # Verde floresta
			Color(0.86, 0.71, 0.42),  # Laranja suave
			Color(0.57, 0.20, 0.25),  # Vermelho escuro
		]
		color = colors[randi() % colors.size()]
		type = randi() % 3

## Veículos ativos
var _vehicles: Dictionary = {}  # id -> Vehicle
var _next_vehicle_id: int = 0
var _road_system
var _rng: RandomNumberGenerator

## Sinais
signal vehicle_spawned(vehicle_id: int)
signal vehicle_despawned(vehicle_id: int)

func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func set_road_system(road) -> void:
	_road_system = road

## Spawna um veículo
func spawn_vehicle(pos: Vector2) -> int:
	var vehicle_id = _next_vehicle_id
	_next_vehicle_id += 1
	
	var vehicle = Vehicle.new(vehicle_id, pos)
	_vehicles[vehicle_id] = vehicle
	
	vehicle_spawned.emit(vehicle_id)
	return vehicle_id

## Remove um veículo
func despawn_vehicle(vehicle_id: int) -> bool:
	if not _vehicles.has(vehicle_id):
		return false
	
	_vehicles.erase(vehicle_id)
	vehicle_despawned.emit(vehicle_id)
	return true

## Spawna veículos aleatórios nas estradas
func spawn_random_vehicles(count: int) -> void:
	if not _road_system:
		return
	
	var roads = _road_system.get_all_roads() if _road_system.has_method("get_all_roads") else []
	if roads.is_empty():
		return
	
	for i in range(count):
		var road = roads[_rng.randi() % roads.size()]
		var tiles: Array
		if road is Dictionary:
			tiles = road.get("tiles", [])
		else:
			tiles = road.tiles if "tiles" in road else []
		
		if not tiles.is_empty():
			var tile = tiles[_rng.randi() % tiles.size()]
			var pos = Vector2(tile) if tile is Vector2i else tile
			spawn_vehicle(pos)

## Atualiza movimento dos veículos
func update_traffic(delta: float) -> void:
	for vehicle in _vehicles.values():
		# Movimento simples - mover em direção ao alvo
		var direction = (vehicle.target_position - vehicle.position).normalized()
		vehicle.position += direction * vehicle.speed * delta
		
		# Se chegou perto do alvo, escolher novo alvo
		if vehicle.position.distance_to(vehicle.target_position) < 5.0:
			_assign_new_target(vehicle)

func _assign_new_target(vehicle: Vehicle) -> void:
	if not _road_system:
		return
	
	var roads = _road_system.get_all_roads() if _road_system.has_method("get_all_roads") else []
	if roads.is_empty():
		return
	
	var road = roads[_rng.randi() % roads.size()]
	var tiles: Array
	if road is Dictionary:
		tiles = road.get("tiles", [])
	else:
		tiles = road.tiles if "tiles" in road else []
	
	if not tiles.is_empty():
		var tile = tiles[_rng.randi() % tiles.size()]
		vehicle.target_position = Vector2(tile) if tile is Vector2i else tile

## Retorna todos os veículos
func get_all_vehicles() -> Array:
	return _vehicles.values()

## Retorna um veículo específico
func get_vehicle(vehicle_id: int):
	return _vehicles.get(vehicle_id)

## Limpa todos os veículos
func clear_all() -> void:
	_vehicles.clear()
	_next_vehicle_id = 0

## Estatísticas
func get_vehicle_count() -> int:
	return _vehicles.size()
