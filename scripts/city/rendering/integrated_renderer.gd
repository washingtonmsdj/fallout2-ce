## Renderizador Integrado para o City Map System
## Funciona com GridSystem, BuildingSystem, CitizenSystem, RoadSystem
class_name IntegratedRenderer
extends Node2D

## Referências aos sistemas (serão injetadas)
var grid_system
var road_system
var building_system
var citizen_system
var zone_system

## Configurações
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0
@export var building_height_scale: float = 2.0

## Cores
const COLOR_GROUND_LIGHT = Color(0.76, 0.70, 0.58)
const COLOR_GROUND_DARK = Color(0.68, 0.62, 0.50)
const COLOR_ROAD = Color(0.28, 0.26, 0.24)
const COLOR_ROAD_MARKING = Color(0.9, 0.85, 0.2)

const ZONE_COLORS = {
	0: Color(0.2, 0.7, 0.2, 0.3),  # RESIDENTIAL - verde
	1: Color(0.2, 0.2, 0.8, 0.3),  # COMMERCIAL - azul
	2: Color(0.8, 0.8, 0.2, 0.3),  # INDUSTRIAL - amarelo
	3: Color(0.6, 0.4, 0.2, 0.3),  # AGRICULTURAL - marrom
}

const BUILDING_COLORS = {
	0: Color(0.72, 0.58, 0.45),   # SMALL_HOUSE
	1: Color(0.68, 0.55, 0.42),   # MEDIUM_HOUSE
	2: Color(0.65, 0.52, 0.40),   # LARGE_HOUSE
	3: Color(0.60, 0.50, 0.38),   # APARTMENT
	4: Color(0.55, 0.58, 0.65),   # SHOP
	5: Color(0.50, 0.55, 0.60),   # MARKET
	6: Color(0.45, 0.50, 0.55),   # WAREHOUSE
	7: Color(0.50, 0.48, 0.45),   # FACTORY
	8: Color(0.55, 0.45, 0.40),   # WORKSHOP
	9: Color(0.85, 0.25, 0.25),   # HOSPITAL
	10: Color(0.25, 0.45, 0.85),  # WATER_TOWER
	11: Color(0.85, 0.85, 0.25),  # POWER_PLANT
	12: Color(0.35, 0.65, 0.25),  # FARM
}

var _initialized: bool = false

func _ready():
	visible = true
	z_index = 10
	print("🎨 IntegratedRenderer ready!")

func set_systems(p_grid, p_road, p_building, p_citizen, p_zone):
	grid_system = p_grid
	road_system = p_road
	building_system = p_building
	citizen_system = p_citizen
	zone_system = p_zone
	_initialized = true
	print("🎨 IntegratedRenderer systems connected!")
	print("  - Grid: %s" % (grid_system != null))
	print("  - Roads: %s" % (road_system != null))
	print("  - Buildings: %s" % (building_system != null))
	print("  - Citizens: %s" % (citizen_system != null))
	print("  - Zones: %s" % (zone_system != null))
	queue_redraw()

func _process(_delta):
	queue_redraw()

func grid_to_iso(grid_pos: Vector2) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * (tile_width / 2.0),
		(grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	)

func _draw():
	if not _initialized:
		return
	
	# Desenhar terreno
	_draw_terrain()
	
	# Desenhar zonas
	_draw_zones()
	
	# Coletar e ordenar entidades
	var entities = _collect_entities()
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# Desenhar entidades
	for entity in entities:
		match entity.type:
			"road":
				_draw_road(entity.data)
			"building":
				_draw_building(entity.data)
			"citizen":
				_draw_citizen(entity.data)

func _draw_terrain():
	if not grid_system:
		return
	
	var width = grid_system._grid_width if grid_system.has_method("get") else 100
	var height = grid_system._grid_height if grid_system.has_method("get") else 100
	
	# Desenhar apenas área visível (otimização)
	var visible_range = 60  # tiles visíveis
	var center_x = width / 2
	var center_y = height / 2
	
	for y in range(max(0, center_y - visible_range), min(height, center_y + visible_range)):
		for x in range(max(0, center_x - visible_range), min(width, center_x + visible_range)):
			var color = COLOR_GROUND_LIGHT if (x + y) % 2 == 0 else COLOR_GROUND_DARK
			_draw_iso_tile(Vector2(x, y), color)

func _draw_zones():
	if not zone_system:
		return
	
	var zones = zone_system.get_all_zones() if zone_system.has_method("get_all_zones") else []
	for zone in zones:
		var zone_type: int
		var tiles: Array
		
		if zone is Dictionary:
			zone_type = zone.get("zone_type", 0)
			tiles = zone.get("tiles", [])
		else:
			zone_type = zone.zone_type if zone.zone_type else 0
			tiles = zone.tiles if zone.tiles else []
		
		var color = ZONE_COLORS.get(zone_type, Color(0.5, 0.5, 0.5, 0.3))
		for tile in tiles:
			_draw_iso_tile(Vector2(tile), color)

func _collect_entities() -> Array:
	var entities = []
	
	# Estradas
	if road_system:
		var roads = road_system.get_all_roads() if road_system.has_method("get_all_roads") else []
		for road in roads:
			var tiles: Array
			if road is Dictionary:
				tiles = road.get("tiles", [])
			else:
				tiles = road.tiles if road.tiles else []
			for tile in tiles:
				entities.append({
					"type": "road",
					"depth": tile.x + tile.y,
					"data": {"position": Vector2(tile)}
				})
	
	# Edifícios
	if building_system:
		var buildings = building_system.get_all_buildings() if building_system.has_method("get_all_buildings") else []
		for building in buildings:
			var pos: Vector2i
			if building is Dictionary:
				pos = building.get("position", Vector2i.ZERO)
			else:
				pos = building.position
			entities.append({
				"type": "building",
				"depth": pos.x + pos.y + 5,
				"data": building
			})
	
	# Cidadãos
	if citizen_system:
		var citizens = citizen_system.get_all_citizens() if citizen_system.has_method("get_all_citizens") else []
		for citizen in citizens:
			var pos: Vector2i
			if citizen is Dictionary:
				pos = citizen.get("position", Vector2i.ZERO)
			else:
				pos = citizen.position
			entities.append({
				"type": "citizen",
				"depth": pos.x + pos.y + 0.5,
				"data": citizen
			})
	
	return entities

func _draw_iso_tile(grid_pos: Vector2, color: Color):
	var center = grid_to_iso(grid_pos)
	var points = PackedVector2Array([
		center + Vector2(0, -tile_height / 2.0),
		center + Vector2(tile_width / 2.0, 0),
		center + Vector2(0, tile_height / 2.0),
		center + Vector2(-tile_width / 2.0, 0)
	])
	draw_colored_polygon(points, color)

func _draw_road(data: Dictionary):
	var pos = data.get("position", Vector2.ZERO)
	_draw_iso_tile(pos, COLOR_ROAD)
	# Marcação central
	var center = grid_to_iso(pos + Vector2(0.5, 0.5))
	if int(pos.x + pos.y) % 3 == 0:
		draw_circle(center, 2, COLOR_ROAD_MARKING)

func _draw_building(data):
	# Suporta tanto Dictionary quanto objetos
	var pos: Vector2
	var size: Vector2
	var building_type: int
	
	if data is Dictionary:
		pos = Vector2(data.get("position", Vector2i.ZERO))
		size = Vector2(data.get("size", Vector2i(3, 3)))
		building_type = data.get("building_type", 0)
	else:
		pos = Vector2(data.position) if data.position else Vector2.ZERO
		size = Vector2(data.size) if data.size else Vector2(3, 3)
		building_type = data.building_type if data.building_type else 0
	
	var color = BUILDING_COLORS.get(building_type, Color(0.6, 0.5, 0.4))
	
	var floors = _get_building_floors(building_type)
	var floor_height = 15.0 * building_height_scale
	var total_height = floors * floor_height
	
	# Sombra
	_draw_building_shadow(pos, int(size.x), int(size.y), total_height)
	
	# Faces do edifício
	var p_back = grid_to_iso(pos)
	var p_right = grid_to_iso(pos + Vector2(size.x, 0))
	var p_front = grid_to_iso(pos + Vector2(size.x, size.y))
	var p_left = grid_to_iso(pos + Vector2(0, size.y))
	
	var top_offset = Vector2(0, -total_height)
	var p_top_back = p_back + top_offset
	var p_top_right = p_right + top_offset
	var p_top_front = p_front + top_offset
	var p_top_left = p_left + top_offset
	
	# Face esquerda (escura)
	draw_colored_polygon(PackedVector2Array([p_top_back, p_top_left, p_left, p_back]), color.darkened(0.2))
	# Face direita (clara)
	draw_colored_polygon(PackedVector2Array([p_top_right, p_top_front, p_front, p_right]), color.lightened(0.1))
	# Topo
	draw_colored_polygon(PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left]), color)
	
	# Contornos
	var outline = color.darkened(0.4)
	draw_line(p_top_back, p_top_right, outline, 1.5)
	draw_line(p_top_right, p_top_front, outline, 1.5)
	draw_line(p_top_front, p_top_left, outline, 1.5)
	draw_line(p_top_left, p_top_back, outline, 1.5)
	draw_line(p_top_front, p_front, outline, 1.5)
	draw_line(p_top_right, p_right, outline, 1.5)
	draw_line(p_top_left, p_left, outline, 1.5)
	
	# Janelas
	_draw_windows(pos, size, floors, floor_height, color)

func _draw_building_shadow(pos: Vector2, width: int, depth: int, height: float):
	var shadow_offset = Vector2(height * 0.3, height * 0.15)
	var p_front = grid_to_iso(pos + Vector2(width, depth))
	var p_right = grid_to_iso(pos + Vector2(width, 0))
	var p_left = grid_to_iso(pos + Vector2(0, depth))
	
	var shadow = PackedVector2Array([
		p_front, p_right, p_right + shadow_offset,
		p_front + shadow_offset, p_left + shadow_offset, p_left
	])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.25))

func _draw_windows(pos: Vector2, size: Vector2, floors: int, floor_height: float, color: Color):
	var window_color = Color(0.2, 0.25, 0.35)  # Janela escura
	var window_light = Color(0.9, 0.85, 0.6, 0.3)  # Luz amarelada
	
	for floor_idx in range(floors):
		var y_offset = -floor_height * (floor_idx + 0.5)
		
		# Janelas na face frontal (direita)
		var num_windows = max(1, int(size.x) - 1)
		for w in range(num_windows):
			var wx = 0.3 + (w * 0.7 / max(1, num_windows - 1)) if num_windows > 1 else 0.5
			var window_pos = grid_to_iso(pos + Vector2(size.x * wx, size.y)) + Vector2(0, y_offset)
			
			# Janela
			var win_rect = Rect2(window_pos - Vector2(4, 5), Vector2(8, 10))
			draw_rect(win_rect, window_color)
			
			# Moldura
			draw_rect(win_rect, color.darkened(0.4), false, 1.0)
			
			# Luz (algumas janelas acesas)
			if (floor_idx + w) % 3 == 0:
				draw_rect(Rect2(win_rect.position + Vector2(1, 1), win_rect.size - Vector2(2, 2)), window_light)
		
		# Janelas na face lateral (esquerda)
		for w in range(max(1, int(size.y) - 1)):
			var wy = 0.3 + (w * 0.7 / max(1, int(size.y) - 2)) if size.y > 2 else 0.5
			var window_pos = grid_to_iso(pos + Vector2(0, size.y * wy)) + Vector2(0, y_offset)
			
			var win_rect = Rect2(window_pos - Vector2(3, 4), Vector2(6, 8))
			draw_rect(win_rect, window_color.darkened(0.1))
			draw_rect(win_rect, color.darkened(0.5), false, 1.0)

func _get_building_floors(type: int) -> int:
	match type:
		0: return 2         # SMALL_HOUSE
		1: return 2         # MEDIUM_HOUSE
		2, 3: return 3      # Large house, apartment
		4, 5: return 2      # Shops
		6, 7, 8: return 3   # Industrial
		9: return 3         # Hospital
		10: return 4        # Water tower
		11: return 3        # Power plant
		12: return 1        # Farm
		_: return 2

func _draw_citizen(data):
	var pos: Vector2
	if data is Dictionary:
		pos = Vector2(data.get("position", Vector2i.ZERO))
	else:
		pos = Vector2(data.position) if data.position else Vector2.ZERO
	var iso_pos = grid_to_iso(pos + Vector2(0.5, 0.5))
	
	# Sombra
	_draw_ellipse(iso_pos + Vector2(0, 3), Vector2(6, 3), Color(0, 0, 0, 0.3))
	
	# Pernas
	draw_line(iso_pos + Vector2(-3, -2), iso_pos + Vector2(-4, 3), Color(0.25, 0.25, 0.3), 2.5)
	draw_line(iso_pos + Vector2(3, -2), iso_pos + Vector2(4, 3), Color(0.25, 0.25, 0.3), 2.5)
	
	# Corpo (vault suit azul)
	_draw_ellipse(iso_pos + Vector2(0, -8), Vector2(6, 10), Color(0.2, 0.35, 0.65))
	
	# Braços
	draw_line(iso_pos + Vector2(-6, -12), iso_pos + Vector2(-8, -4), Color(0.85, 0.7, 0.55), 2.0)
	draw_line(iso_pos + Vector2(6, -12), iso_pos + Vector2(8, -4), Color(0.85, 0.7, 0.55), 2.0)
	
	# Cabeça
	draw_circle(iso_pos + Vector2(0, -20), 6, Color(0.9, 0.75, 0.6))
	
	# Cabelo
	_draw_ellipse(iso_pos + Vector2(0, -25), Vector2(5, 3), Color(0.3, 0.22, 0.15))
	
	# Olhos
	draw_circle(iso_pos + Vector2(-2, -20), 1.2, Color.WHITE)
	draw_circle(iso_pos + Vector2(2, -20), 1.2, Color.WHITE)
	draw_circle(iso_pos + Vector2(-2, -20), 0.6, Color.BLACK)
	draw_circle(iso_pos + Vector2(2, -20), 0.6, Color.BLACK)

func _draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)


