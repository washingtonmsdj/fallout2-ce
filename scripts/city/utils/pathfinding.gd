## Pathfinding utility with A* algorithm
## Handles both road-based and off-road pathfinding
class_name Pathfinding
extends Node

class PathResult:
	var path: Array = []  # Array of Vector2i
	var cost: float = 0.0
	var estimated_time: float = 0.0
	var is_valid: bool = false
	var mode: int = 0  # 0 = off-road, 1 = road-only
	
	func _init(p_path: Array = [], p_cost: float = 0.0, p_time: float = 0.0, 
			   p_valid: bool = false, p_mode: int = 0) -> void:
		path = p_path
		cost = p_cost
		estimated_time = p_time
		is_valid = p_valid
		mode = p_mode
	
	func _to_string() -> String:
		return "PathResult(valid=%s, length=%d, cost=%.2f, time=%.2f)" % [
			is_valid, path.size(), cost, estimated_time
		]

enum PathMode {
	OFF_ROAD = 0,
	ROAD_ONLY = 1
}

var grid_system: GridSystem
var road_system: RoadSystem
var config: CityConfig

# Landmark system for optimization
class Landmark:
	var position: Vector2i
	var connections: Dictionary = {}  # Vector2i -> float (distance)
	
	func _init(p_pos: Vector2i) -> void:
		position = p_pos
	
	func add_connection(target_pos: Vector2i, distance: float) -> void:
		connections[target_pos] = distance
	
	func get_distance_to(target_pos: Vector2i) -> float:
		return connections.get(target_pos, -1.0)

var landmarks: Array = []
var landmark_cache: Dictionary = {}  # (start, goal) -> PathResult
var cache_enabled: bool = true

# A* node for pathfinding
class AStarNode:
	var position: Vector2i
	var g_cost: float = 0.0  # Cost from start
	var h_cost: float = 0.0  # Heuristic to goal
	var parent: AStarNode = null
	
	func _init(p_pos: Vector2i, p_g: float = 0.0, p_h: float = 0.0) -> void:
		position = p_pos
		g_cost = p_g
		h_cost = p_h
	
	func f_cost() -> float:
		return g_cost + h_cost
	
	func _to_string() -> String:
		return "AStarNode(%s, f=%.2f)" % [position, f_cost()]

func _init(p_grid: GridSystem = null, p_road: RoadSystem = null, p_config: CityConfig = null) -> void:
	grid_system = p_grid
	road_system = p_road
	config = p_config if p_config else CityConfig.new()

func set_systems(grid: GridSystem, road: RoadSystem) -> void:
	"""Set the grid and road systems"""
	grid_system = grid
	road_system = road

func precompute_landmarks(num_landmarks: int = 10) -> void:
	"""Precompute landmarks at key intersections"""
	if grid_system == null or road_system == null:
		return
	
	landmarks.clear()
	landmark_cache.clear()
	
	# Find road intersections
	var intersections: Array = []
	var road_tiles = {}
	
	# Collect all road tiles and count connections
	for road in road_system.get_all_roads():
		for tile in road.tiles:
			if not road_tiles.has(tile):
				road_tiles[tile] = 0
			road_tiles[tile] += 1
	
	# Find intersections (tiles with multiple road connections)
	for tile_pos in road_tiles.keys():
		if road_tiles[tile_pos] > 1:
			intersections.append(tile_pos)
	
	# Select landmarks from intersections
	var selected_count = 0
	var step = max(1, intersections.size() / num_landmarks)
	
	for i in range(0, intersections.size(), step):
		if selected_count >= num_landmarks:
			break
		
		var landmark = Landmark.new(intersections[i])
		landmarks.append(landmark)
		selected_count += 1
	
	# Precompute distances between landmarks
	for i in range(landmarks.size()):
		for j in range(i + 1, landmarks.size()):
			var path = _find_offroad_path(landmarks[i].position, landmarks[j].position)
			if path.is_valid:
				landmarks[i].add_connection(landmarks[j].position, path.cost)
				landmarks[j].add_connection(landmarks[i].position, path.cost)

func find_path_cached(start: Vector2i, goal: Vector2i, mode: int = PathMode.OFF_ROAD) -> PathResult:
	"""Find path with caching enabled"""
	if not cache_enabled:
		return find_path(start, goal, mode)
	
	var cache_key = "%s_%s_%d" % [start, goal, mode]
	
	if landmark_cache.has(cache_key):
		return landmark_cache[cache_key]
	
	var result = find_path(start, goal, mode)
	landmark_cache[cache_key] = result
	
	return result

func clear_cache() -> void:
	"""Clear the pathfinding cache"""
	landmark_cache.clear()

func set_cache_enabled(enabled: bool) -> void:
	"""Enable or disable caching"""
	cache_enabled = enabled

func find_path(start: Vector2i, goal: Vector2i, mode: int = PathMode.OFF_ROAD) -> PathResult:
	"""Find a path from start to goal using A* algorithm"""
	if grid_system == null:
		return PathResult([], 0.0, 0.0, false, mode)
	
	if not grid_system._is_valid_position(start) or not grid_system._is_valid_position(goal):
		return PathResult([], 0.0, 0.0, false, mode)
	
	if mode == PathMode.ROAD_ONLY and road_system != null:
		return _find_road_path(start, goal)
	else:
		return _find_offroad_path(start, goal)

func _find_offroad_path(start: Vector2i, goal: Vector2i) -> PathResult:
	"""Find path allowing off-road movement"""
	var open_set: Array = []
	var closed_set: Dictionary = {}
	var node_map: Dictionary = {}
	
	var start_node = AStarNode.new(start, 0.0, _heuristic(start, goal))
	open_set.append(start_node)
	node_map[start] = start_node
	
	while open_set.size() > 0:
		# Find node with lowest f_cost
		var current_idx = 0
		for i in range(1, open_set.size()):
			if open_set[i].f_cost() < open_set[current_idx].f_cost():
				current_idx = i
		
		var current = open_set[current_idx]
		
		if current.position == goal:
			return _reconstruct_path(current, PathMode.OFF_ROAD)
		
		open_set.remove_at(current_idx)
		closed_set[current.position] = true
		
		# Check all neighbors
		var neighbors = _get_neighbors(current.position, PathMode.OFF_ROAD)
		for neighbor_pos in neighbors:
			if closed_set.has(neighbor_pos):
				continue
			
			var tentative_g = current.g_cost + _movement_cost(current.position, neighbor_pos, PathMode.OFF_ROAD)
			
			if not node_map.has(neighbor_pos):
				var h = _heuristic(neighbor_pos, goal)
				var neighbor_node = AStarNode.new(neighbor_pos, tentative_g, h)
				neighbor_node.parent = current
				node_map[neighbor_pos] = neighbor_node
				open_set.append(neighbor_node)
			else:
				var neighbor_node = node_map[neighbor_pos]
				if tentative_g < neighbor_node.g_cost:
					neighbor_node.g_cost = tentative_g
					neighbor_node.h_cost = _heuristic(neighbor_pos, goal)
					neighbor_node.parent = current
	
	# No path found
	return PathResult([], 0.0, 0.0, false, PathMode.OFF_ROAD)

func _find_road_path(start: Vector2i, goal: Vector2i) -> PathResult:
	"""Find path using only roads"""
	if road_system == null:
		return PathResult([], 0.0, 0.0, false, PathMode.ROAD_ONLY)
	
	# Find nearest road tiles to start and goal
	var start_road_tile = _find_nearest_road_tile(start)
	var goal_road_tile = _find_nearest_road_tile(goal)
	
	if start_road_tile == null or goal_road_tile == null:
		return PathResult([], 0.0, 0.0, false, PathMode.ROAD_ONLY)
	
	# Find path on roads
	var road_path = _find_offroad_path(start_road_tile, goal_road_tile)
	
	if not road_path.is_valid:
		return PathResult([], 0.0, 0.0, false, PathMode.ROAD_ONLY)
	
	# Add paths from start to nearest road and from road to goal
	var full_path: Array = []
	
	# Add path from start to road
	var start_to_road = _find_offroad_path(start, start_road_tile)
	if start_to_road.is_valid:
		full_path.append_array(start_to_road.path)
	
	# Add road path (skip first point to avoid duplication)
	for i in range(1, road_path.path.size()):
		full_path.append(road_path.path[i])
	
	# Add path from road to goal
	var road_to_goal = _find_offroad_path(goal_road_tile, goal)
	if road_to_goal.is_valid:
		for i in range(1, road_to_goal.path.size()):
			full_path.append(road_to_goal.path[i])
	
	var total_cost = start_to_road.cost + road_path.cost + road_to_goal.cost
	var total_time = start_to_road.estimated_time + road_path.estimated_time + road_to_goal.estimated_time
	
	return PathResult(full_path, total_cost, total_time, true, PathMode.ROAD_ONLY)

func _find_nearest_road_tile(position: Vector2i) -> Vector2i:
	"""Find the nearest road tile to a position"""
	if road_system == null:
		return null
	
	var search_radius = 10
	var nearest_tile = null
	var nearest_distance = search_radius
	
	for x in range(position.x - search_radius, position.x + search_radius):
		for y in range(position.y - search_radius, position.y + search_radius):
			var tile_pos = Vector2i(x, y)
			if grid_system._is_valid_position(tile_pos) and road_system.is_road_tile(tile_pos):
				var distance = position.distance_to(tile_pos)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_tile = tile_pos
	
	return nearest_tile

func _get_neighbors(position: Vector2i, mode: int) -> Array:
	"""Get valid neighbor positions"""
	var neighbors: Array = []
	
	# 8 directions (including diagonals)
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	
	for direction in directions:
		var neighbor = position + direction
		
		if not grid_system._is_valid_position(neighbor):
			continue
		
		if mode == PathMode.ROAD_ONLY:
			if road_system != null and road_system.is_road_tile(neighbor):
				neighbors.append(neighbor)
		else:
			# Off-road: check if walkable
			if grid_system.is_walkable(neighbor):
				neighbors.append(neighbor)
	
	return neighbors

func _movement_cost(from: Vector2i, to: Vector2i, mode: int) -> float:
	"""Calculate movement cost between two tiles"""
	var distance = from.distance_to(to)
	
	# Diagonal movement costs more
	if from.x != to.x and from.y != to.y:
		distance = distance * 1.414  # sqrt(2)
	
	# Road movement is cheaper
	if mode == PathMode.ROAD_ONLY:
		distance *= 0.5
	
	return distance

func _heuristic(from: Vector2i, to: Vector2i) -> float:
	"""Heuristic function for A* (Chebyshev distance)"""
	var dx = abs(from.x - to.x)
	var dy = abs(from.y - to.y)
	return float(max(dx, dy))

func _reconstruct_path(end_node: AStarNode, mode: int) -> PathResult:
	"""Reconstruct path from end node to start"""
	var path: Array = []
	var current = end_node
	var total_cost = 0.0
	
	while current != null:
		path.insert(0, current.position)
		if current.parent != null:
			total_cost += _movement_cost(current.parent.position, current.position, mode)
		current = current.parent
	
	# Estimate time based on path length and movement speed
	var estimated_time = total_cost / 5.0  # Assume 5 tiles per second
	
	return PathResult(path, total_cost, estimated_time, true, mode)

func smooth_path(path: Array) -> Array:
	"""Smooth a path by removing unnecessary waypoints"""
	if path.size() <= 2:
		return path
	
	var smoothed: Array = [path[0]]
	var current_idx = 0
	
	while current_idx < path.size() - 1:
		var next_idx = path.size() - 1
		
		# Find the farthest point we can reach in a straight line
		while next_idx > current_idx + 1:
			var line_clear = true
			var from = path[current_idx]
			var to = path[next_idx]
			
			# Check if line of sight is clear
			var line_tiles = grid_system.raycast(from, to)
			for tile in line_tiles:
				if not grid_system.is_walkable(tile):
					line_clear = false
					break
			
			if line_clear:
				break
			next_idx -= 1
		
		smoothed.append(path[next_idx])
		current_idx = next_idx
	
	return smoothed
