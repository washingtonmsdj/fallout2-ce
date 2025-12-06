## RoadSystem - Sistema de estradas e conectividade
## Gerencia segmentos de estrada, curvas e conexões
class_name RoadSystem
extends Node

# Enums para tipos de estrada
enum RoadType {
	DIRT_PATH = 0,
	PAVED_ROAD = 1,
	HIGHWAY = 2,
	ALLEY = 3,
	BRIDGE = 4
}

# Classe para dados de um segmento de estrada
class RoadSegment:
	var id: int
	var road_type: int = RoadType.DIRT_PATH
	var tiles: Array = []  # Vector2i positions
	var connections: Array = []  # IDs de segmentos conectados
	var bezier_points: Array = []  # Pontos de controle Bezier para curvas
	var is_curved: bool = false
	
	func _init(p_id: int, p_type: int = RoadType.DIRT_PATH) -> void:
		id = p_id
		road_type = p_type
	
	func _to_string() -> String:
		return "RoadSegment(id=%d, type=%d, tiles=%d, curved=%s)" % [
			id, road_type, tiles.size(), is_curved
		]

# Armazenamento de estradas
var _road_segments: Dictionary = {}  # int (id) -> RoadSegment
var _tile_to_road: Dictionary = {}  # Vector2i -> int (road id)
var _next_road_id: int = 0
var grid_system
var config

func _ready() -> void:
	pass

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()

func set_grid_system(grid) -> void:
	"""Define a referência ao GridSystem"""
	grid_system = grid

func create_road(from: Vector2i, to: Vector2i, road_type: int = RoadType.PAVED_ROAD) -> int:
	"""Cria uma estrada reta entre dois pontos"""
	if grid_system == null:
		return -1
	
	var segment = RoadSegment.new(_next_road_id, road_type)
	_next_road_id += 1
	
	# Usar raycast do grid para obter tiles
	var tiles = grid_system.raycast(from, to)
	segment.tiles = tiles
	
	# Registrar tiles
	for tile_pos in tiles:
		_tile_to_road[tile_pos] = segment.id
	
	_road_segments[segment.id] = segment
	return segment.id

func create_curved_road(from: Vector2i, to: Vector2i, control_points: Array = [], 
						road_type: int = RoadType.PAVED_ROAD) -> int:
	"""Cria uma estrada curva com pontos de controle Bezier"""
	if grid_system == null:
		return -1
	
	var segment = RoadSegment.new(_next_road_id, road_type)
	_next_road_id += 1
	segment.is_curved = true
	
	# Armazenar pontos de controle
	segment.bezier_points.append(from)
	segment.bezier_points.append_array(control_points)
	segment.bezier_points.append(to)
	
	# Gerar tiles ao longo da curva Bezier
	var tiles = _generate_bezier_tiles(segment.bezier_points)
	segment.tiles = tiles
	
	# Registrar tiles
	for tile_pos in tiles:
		_tile_to_road[tile_pos] = segment.id
	
	_road_segments[segment.id] = segment
	return segment.id

func connect_roads(road_id_1: int, road_id_2: int) -> bool:
	"""Conecta dois segmentos de estrada"""
	if not _road_segments.has(road_id_1) or not _road_segments.has(road_id_2):
		return false
	
	var seg1 = _road_segments[road_id_1]
	var seg2 = _road_segments[road_id_2]
	
	# Verificar se há tiles adjacentes
	var connected = false
	for tile1 in seg1.tiles:
		for tile2 in seg2.tiles:
			if tile1.distance_to(tile2) <= 1.5:  # Adjacente ou diagonal
				connected = true
				break
		if connected:
			break
	
	if connected:
		if not seg1.connections.has(road_id_2):
			seg1.connections.append(road_id_2)
		if not seg2.connections.has(road_id_1):
			seg2.connections.append(road_id_1)
		return true
	
	return false

func auto_connect_adjacent_roads() -> void:
	"""Conecta automaticamente segmentos de estrada adjacentes"""
	var road_ids = _road_segments.keys()
	
	for i in range(road_ids.size()):
		for j in range(i + 1, road_ids.size()):
			connect_roads(road_ids[i], road_ids[j])

func get_road_segment(road_id: int) -> RoadSegment:
	"""Obtém um segmento de estrada"""
	return _road_segments.get(road_id)

func get_road_at_tile(position: Vector2i) -> int:
	"""Obtém o ID da estrada em um tile específico"""
	return _tile_to_road.get(position, -1)

func is_road_tile(position: Vector2i) -> bool:
	"""Verifica se um tile é parte de uma estrada"""
	return _tile_to_road.has(position)

func get_all_roads() -> Array:
	"""Retorna todos os segmentos de estrada"""
	return _road_segments.values()

func get_road_count() -> int:
	"""Retorna o número de segmentos de estrada"""
	return _road_segments.size()

func destroy_road(road_id: int) -> bool:
	"""Remove um segmento de estrada"""
	if not _road_segments.has(road_id):
		return false
	
	var segment = _road_segments[road_id]
	
	# Remover tiles
	for tile_pos in segment.tiles:
		_tile_to_road.erase(tile_pos)
	
	# Remover conexões
	for connected_id in segment.connections:
		if _road_segments.has(connected_id):
			var connected = _road_segments[connected_id]
			connected.connections.erase(road_id)
	
	_road_segments.erase(road_id)
	return true

func _generate_bezier_tiles(control_points: Array) -> Array:
	"""Gera tiles ao longo de uma curva Bezier"""
	var tiles: Array = []
	var steps = 50  # Número de passos ao longo da curva
	
	for i in range(steps + 1):
		var t = float(i) / steps
		var point = _evaluate_bezier(control_points, t)
		var tile_pos = Vector2i(int(point.x), int(point.y))
		
		if grid_system == null or grid_system._is_valid_position(tile_pos):
			if not tiles.has(tile_pos):
				tiles.append(tile_pos)
	
	return tiles

func _evaluate_bezier(control_points: Array, t: float) -> Vector2:
	"""Avalia um ponto em uma curva Bezier"""
	if control_points.size() == 2:
		# Linear
		return control_points[0].lerp(control_points[1], t)
	
	# Bezier cúbica (4 pontos)
	if control_points.size() == 4:
		var p0 = control_points[0]
		var p1 = control_points[1]
		var p2 = control_points[2]
		var p3 = control_points[3]
		
		var mt = 1.0 - t
		var mt2 = mt * mt
		var mt3 = mt2 * mt
		var t2 = t * t
		var t3 = t2 * t
		
		return mt3 * p0 + 3 * mt2 * t * p1 + 3 * mt * t2 * p2 + t3 * p3
	
	# Fallback para linear
	return control_points[0].lerp(control_points[-1], t)

func create_organic_network(center: Vector2i, num_roads: int = 5, 
							max_length: int = 50, road_type: int = RoadType.PAVED_ROAD) -> Array:
	"""Cria uma rede de estradas orgânica com curvas e diagonais"""
	var created_roads: Array = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(num_roads):
		# Gerar direção aleatória
		var angle = rng.randf() * TAU
		var direction = Vector2(cos(angle), sin(angle))
		
		# Gerar comprimento aleatório
		var length = rng.randi_range(int(max_length * 0.5), max_length)
		var offset = (direction * length).round()
		var end_point = Vector2i(center.x + int(offset.x), center.y + int(offset.y))
		
		# Gerar pontos de controle para curva
		var control_points: Array = []
		var num_controls = rng.randi_range(1, 3)
		
		for j in range(num_controls):
			var t = float(j + 1) / (num_controls + 1)
			var base_point = Vector2(center).lerp(Vector2(end_point), t)
			# Adicionar desvio perpendicular
			var perpendicular = Vector2(-direction.y, direction.x)
			var deviation = rng.randf_range(-length * 0.2, length * 0.2)
			var control_offset = (perpendicular * deviation).round()
			var control_point = Vector2i(int(base_point.x + control_offset.x), int(base_point.y + control_offset.y))
			control_points.append(control_point)
		
		# Criar estrada curva
		var road_id = create_curved_road(center, end_point, control_points, road_type)
		if road_id >= 0:
			created_roads.append(road_id)
	
	# Conectar estradas adjacentes
	auto_connect_adjacent_roads()
	
	return created_roads

func create_grid_roads(top_left: Vector2i, width: int, height: int, 
					   spacing: int = 10, road_type: int = RoadType.PAVED_ROAD) -> Array:
	"""Cria uma rede de estradas em padrão de grade com variações"""
	var created_roads: Array = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Criar estradas horizontais com variações
	for y in range(0, height, spacing):
		var current_y = top_left.y + y
		var start_x = top_left.x
		var end_x = top_left.x + width
		
		# Adicionar pequenas variações na altura
		var variation = rng.randi_range(-2, 2)
		current_y += variation
		
		var road_id = create_road(Vector2i(start_x, current_y), Vector2i(end_x, current_y), road_type)
		if road_id >= 0:
			created_roads.append(road_id)
	
	# Criar estradas verticais com variações
	for x in range(0, width, spacing):
		var current_x = top_left.x + x
		var start_y = top_left.y
		var end_y = top_left.y + height
		
		# Adicionar pequenas variações na largura
		var variation = rng.randi_range(-2, 2)
		current_x += variation
		
		var road_id = create_road(Vector2i(current_x, start_y), Vector2i(current_x, end_y), road_type)
		if road_id >= 0:
			created_roads.append(road_id)
	
	# Conectar estradas adjacentes
	auto_connect_adjacent_roads()
	
	return created_roads

func create_radial_roads(center: Vector2i, num_roads: int = 8, 
						 radius: int = 50, road_type: int = RoadType.PAVED_ROAD) -> Array:
	"""Cria estradas em padrão radial a partir de um centro"""
	var created_roads: Array = []
	
	for i in range(num_roads):
		var angle = (TAU / num_roads) * i
		var direction = Vector2(cos(angle), sin(angle))
		var offset = (direction * radius).round()
		var end_point = Vector2i(center.x + int(offset.x), center.y + int(offset.y))
		
		var road_id = create_road(center, end_point, road_type)
		if road_id >= 0:
			created_roads.append(road_id)
	
	# Conectar estradas adjacentes
	auto_connect_adjacent_roads()
	
	return created_roads
