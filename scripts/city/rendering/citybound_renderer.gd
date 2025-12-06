## CityboundRenderer - Renderizador estilo Citybound para Godot
## Renderiza cidade com visual procedural similar ao Citybound
class_name CityboundRenderer
extends Node2D

## Referências aos sistemas
var grid_system
var road_system
var building_system
var citizen_system
var zone_system

## Configurações de renderização isométrica
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0
@export var pixels_per_meter: float = 4.0  # Escala de metros para pixels

## Cache de edifícios procedurais
var _building_cache: Dictionary = {}  # building_id -> ProceduralBuilding

## Cores do terreno (estilo Citybound)
const GRASS_COLOR = Color(0.79, 0.88, 0.67)
const ASPHALT_COLOR = Color(0.6, 0.6, 0.6)
const ROAD_MARKER_COLOR = Color(1.0, 1.0, 1.0)

## Cores de zonas (misturadas com grama como no Citybound)
const ZONE_COLORS = {
	0: Color(0.91, 0.84, 0.55),  # Residential - amarelo suave
	1: Color(0.85, 0.55, 0.35),  # Commercial - laranja
	2: Color(0.65, 0.50, 0.58),  # Industrial - roxo acinzentado
	3: Color(0.62, 0.62, 0.52),  # Agricultural - verde oliva
}

var _initialized: bool = false
var _visible_bounds: Rect2 = Rect2()

func _ready() -> void:
	visible = true
	z_index = 0
	print("🎨 CityboundRenderer initialized!")

func set_systems(p_grid, p_road, p_building, p_citizen, p_zone) -> void:
	grid_system = p_grid
	road_system = p_road
	building_system = p_building
	citizen_system = p_citizen
	zone_system = p_zone
	_initialized = true
	_rebuild_building_cache()
	queue_redraw()

func _rebuild_building_cache() -> void:
	"""Reconstrói o cache de edifícios procedurais"""
	_building_cache.clear()
	if not building_system:
		return
	
	var buildings = building_system.get_all_buildings()
	for building in buildings:
		var building_id = building.id if building is Object else building.get("id", 0)
		_cache_building(building)

func _cache_building(building) -> void:
	"""Cria e cacheia um edifício procedural"""
	var building_id: int
	var pos: Vector2i
	var building_type: int
	var condition: float
	
	if building is Dictionary:
		building_id = building.get("id", randi())
		pos = building.get("position", Vector2i.ZERO)
		building_type = building.get("building_type", 0)
		condition = building.get("condition", 100.0)
	else:
		building_id = building.id
		pos = building.position
		building_type = building.building_type
		condition = building.condition if "condition" in building else 100.0
	
	var proc_building = ProceduralBuilding.new(building_id)
	var style = _map_building_type_to_style(building_type)
	proc_building.generate(style, Vector2(pos), condition)
	_building_cache[building_id] = proc_building

func _map_building_type_to_style(building_type: int) -> int:
	"""Mapeia tipo de edifício do BuildingSystem para estilo procedural"""
	match building_type:
		0, 1, 2:  # SMALL_HOUSE, MEDIUM_HOUSE, LARGE_HOUSE
			return ProceduralBuilding.Style.FAMILY_HOUSE
		3:  # APARTMENT
			return ProceduralBuilding.Style.APARTMENT
		4, 5:  # SHOP, MARKET
			return ProceduralBuilding.Style.GROCERY_SHOP
		6:  # WAREHOUSE
			return ProceduralBuilding.Style.WAREHOUSE
		7, 8:  # FACTORY, WORKSHOP
			return ProceduralBuilding.Style.FACTORY
		9:  # HOSPITAL
			return ProceduralBuilding.Style.APARTMENT
		10:  # WATER_TOWER
			return ProceduralBuilding.Style.WATER_TOWER
		11:  # POWER_PLANT
			return ProceduralBuilding.Style.POWER_PLANT
		12:  # FARM
			return ProceduralBuilding.Style.FARM_FIELD
		_:
			return ProceduralBuilding.Style.SHACK

func _process(_delta: float) -> void:
	queue_redraw()

## Converte coordenadas do grid para isométrico
func grid_to_iso(grid_pos: Vector2) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * (tile_width / 2.0),
		(grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	)

## Converte metros para pixels isométricos
func meters_to_iso_height(meters: float) -> float:
	return meters * pixels_per_meter

func _draw() -> void:
	if not _initialized:
		return
	
	# 1. Desenhar terreno base (grama)
	_draw_terrain()
	
	# 2. Desenhar zonas
	_draw_zones()
	
	# 3. Coletar e ordenar todas as entidades por profundidade
	var render_items = _collect_render_items()
	render_items.sort_custom(func(a, b): return a.depth < b.depth)
	
	# 4. Desenhar entidades ordenadas
	for item in render_items:
		match item.type:
			"road":
				_draw_road_segment(item.data)
			"building":
				_draw_building_3d(item.data)
			"citizen":
				_draw_citizen(item.data)

func _draw_terrain() -> void:
	"""Desenha o terreno base com padrão de grama"""
	if not grid_system:
		return
	
	var width = grid_system._grid_width if "_grid_width" in grid_system else 100
	var height = grid_system._grid_height if "_grid_height" in grid_system else 100
	
	# Desenhar área visível
	var visible_range = 50
	var center_x = width / 2
	var center_y = height / 2
	
	for y in range(max(0, center_y - visible_range), min(height, center_y + visible_range)):
		for x in range(max(0, center_x - visible_range), min(width, center_x + visible_range)):
			# Variação sutil na cor da grama
			var noise_val = sin(x * 0.5) * cos(y * 0.5) * 0.05
			var grass = GRASS_COLOR.lightened(noise_val)
			_draw_iso_tile(Vector2(x, y), grass)

func _draw_zones() -> void:
	"""Desenha zonas com cores misturadas com grama (estilo Citybound)"""
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
			zone_type = zone.zone_type
			tiles = zone.tiles
		
		# Misturar cor da zona com grama (90% grama, 10% zona) como no Citybound
		var zone_color = ZONE_COLORS.get(zone_type, Color(0.5, 0.5, 0.5))
		var mixed_color = GRASS_COLOR.lerp(zone_color, 0.1)
		
		for tile in tiles:
			var tile_vec = Vector2(tile) if tile is Vector2i else tile
			_draw_iso_tile(tile_vec, mixed_color)

func _collect_render_items() -> Array:
	"""Coleta todos os itens para renderização com profundidade"""
	var items = []
	
	# Estradas
	if road_system:
		var roads = road_system.get_all_roads() if road_system.has_method("get_all_roads") else []
		for road in roads:
			var tiles: Array
			if road is Dictionary:
				tiles = road.get("tiles", [])
			else:
				tiles = road.tiles
			for tile in tiles:
				var tile_vec = Vector2(tile) if tile is Vector2i else tile
				items.append({
					"type": "road",
					"depth": tile_vec.x + tile_vec.y,
					"data": {"position": tile_vec}
				})
	
	# Edifícios
	if building_system:
		var buildings = building_system.get_all_buildings()
		for building in buildings:
			var pos: Vector2
			var building_id: int
			if building is Dictionary:
				pos = Vector2(building.get("position", Vector2i.ZERO))
				building_id = building.get("id", 0)
			else:
				pos = Vector2(building.position)
				building_id = building.id
			
			# Profundidade baseada na posição + offset para ficar acima das estradas
			items.append({
				"type": "building",
				"depth": pos.x + pos.y + 10,
				"data": {"building": building, "proc": _building_cache.get(building_id)}
			})
	
	# Cidadãos
	if citizen_system:
		var citizens = citizen_system.get_all_citizens() if citizen_system.has_method("get_all_citizens") else []
		for citizen in citizens:
			var pos: Vector2
			if citizen is Dictionary:
				pos = Vector2(citizen.get("position", Vector2i.ZERO))
			else:
				pos = Vector2(citizen.position)
			items.append({
				"type": "citizen",
				"depth": pos.x + pos.y + 5,
				"data": citizen
			})
	
	return items

func _draw_iso_tile(grid_pos: Vector2, color: Color) -> void:
	"""Desenha um tile isométrico"""
	var center = grid_to_iso(grid_pos)
	var points = PackedVector2Array([
		center + Vector2(0, -tile_height / 2.0),
		center + Vector2(tile_width / 2.0, 0),
		center + Vector2(0, tile_height / 2.0),
		center + Vector2(-tile_width / 2.0, 0)
	])
	draw_colored_polygon(points, color)

func _draw_road_segment(data: Dictionary) -> void:
	"""Desenha um segmento de estrada estilo Citybound"""
	var pos = data.get("position", Vector2.ZERO)
	
	# Asfalto
	_draw_iso_tile(pos, ASPHALT_COLOR)
	
	# Marcações de estrada (linhas brancas)
	var center = grid_to_iso(pos + Vector2(0.5, 0.5))
	
	# Linha central tracejada
	if int(pos.x + pos.y) % 2 == 0:
		var line_start = center + Vector2(-8, -4)
		var line_end = center + Vector2(8, 4)
		draw_line(line_start, line_end, ROAD_MARKER_COLOR, 1.5)

func _draw_building_3d(data: Dictionary) -> void:
	"""Desenha um edifício 3D procedural"""
	var building = data.get("building")
	var proc: ProceduralBuilding = data.get("proc")
	
	if not building:
		return
	
	var pos: Vector2
	var size: Vector2
	
	if building is Dictionary:
		pos = Vector2(building.get("position", Vector2i.ZERO))
		size = Vector2(building.get("size", Vector2i(3, 3)))
	else:
		pos = Vector2(building.position)
		size = Vector2(building.size)
	
	# Se temos dados procedurais, usar
	if proc:
		_draw_procedural_building(pos, proc)
	else:
		# Fallback para renderização simples
		_draw_simple_building(pos, size, Color(0.7, 0.6, 0.5), 40.0)

func _draw_procedural_building(grid_pos: Vector2, proc: ProceduralBuilding) -> void:
	"""Desenha um edifício com dados procedurais"""
	var width = proc.footprint_width / tile_width * 2.0
	var depth = proc.footprint_depth / tile_height * 2.0
	var height = meters_to_iso_height(proc.total_height)
	
	var wall_color = proc.get_material_color(proc.wall_material)
	var roof_color = proc.get_material_color(proc.roof_material)
	
	# Calcular pontos do edifício
	var p_back = grid_to_iso(grid_pos)
	var p_right = grid_to_iso(grid_pos + Vector2(width, 0))
	var p_front = grid_to_iso(grid_pos + Vector2(width, depth))
	var p_left = grid_to_iso(grid_pos + Vector2(0, depth))
	
	var top_offset = Vector2(0, -height)
	var p_top_back = p_back + top_offset
	var p_top_right = p_right + top_offset
	var p_top_front = p_front + top_offset
	var p_top_left = p_left + top_offset
	
	# Sombra
	_draw_building_shadow(grid_pos, width, depth, height)
	
	# Face esquerda (sombra)
	var left_face = PackedVector2Array([p_top_back, p_top_left, p_left, p_back])
	draw_colored_polygon(left_face, wall_color.darkened(0.25))
	
	# Face direita (luz)
	var right_face = PackedVector2Array([p_top_right, p_top_front, p_front, p_right])
	draw_colored_polygon(right_face, wall_color.lightened(0.15))
	
	# Telhado
	if proc.roof_type == 1:  # Gable roof
		_draw_gable_roof(p_top_back, p_top_right, p_top_front, p_top_left, roof_color, height * 0.3)
	else:  # Flat roof
		var top_face = PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left])
		draw_colored_polygon(top_face, roof_color)
	
	# Contornos
	var outline = wall_color.darkened(0.5)
	draw_line(p_top_back, p_top_right, outline, 1.5)
	draw_line(p_top_right, p_top_front, outline, 1.5)
	draw_line(p_top_front, p_top_left, outline, 1.5)
	draw_line(p_top_left, p_top_back, outline, 1.5)
	draw_line(p_top_front, p_front, outline, 1.5)
	draw_line(p_top_right, p_right, outline, 1.5)
	draw_line(p_top_left, p_left, outline, 1.5)
	
	# Props (janelas, portas)
	_draw_building_props(grid_pos, proc)

func _draw_gable_roof(p_back: Vector2, p_right: Vector2, p_front: Vector2, p_left: Vector2, 
					color: Color, roof_height: float) -> void:
	"""Desenha um telhado de duas águas"""
	var mid_back = (p_back + p_right) / 2.0
	var mid_front = (p_left + p_front) / 2.0
	var peak_offset = Vector2(0, -roof_height)
	
	var peak_back = mid_back + peak_offset
	var peak_front = mid_front + peak_offset
	
	# Lado esquerdo do telhado
	var left_roof = PackedVector2Array([p_back, peak_back, peak_front, p_left])
	draw_colored_polygon(left_roof, color.darkened(0.1))
	
	# Lado direito do telhado
	var right_roof = PackedVector2Array([peak_back, p_right, p_front, peak_front])
	draw_colored_polygon(right_roof, color.lightened(0.1))
	
	# Frontões (gables)
	var front_gable = PackedVector2Array([p_left, peak_front, p_front])
	draw_colored_polygon(front_gable, color.darkened(0.2))
	
	# Contorno do telhado
	draw_line(p_back, peak_back, color.darkened(0.4), 1.5)
	draw_line(peak_back, p_right, color.darkened(0.4), 1.5)
	draw_line(p_left, peak_front, color.darkened(0.4), 1.5)
	draw_line(peak_front, p_front, color.darkened(0.4), 1.5)
	draw_line(peak_back, peak_front, color.darkened(0.4), 1.5)

func _draw_building_shadow(grid_pos: Vector2, width: float, depth: float, height: float) -> void:
	"""Desenha sombra do edifício"""
	var shadow_offset = Vector2(height * 0.3, height * 0.15)
	var p_front = grid_to_iso(grid_pos + Vector2(width, depth))
	var p_right = grid_to_iso(grid_pos + Vector2(width, 0))
	var p_left = grid_to_iso(grid_pos + Vector2(0, depth))
	
	var shadow = PackedVector2Array([
		p_front, p_right, p_right + shadow_offset,
		p_front + shadow_offset, p_left + shadow_offset, p_left
	])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.2))

func _draw_building_props(grid_pos: Vector2, proc: ProceduralBuilding) -> void:
	"""Desenha props do edifício (janelas, portas, etc)"""
	var base_iso = grid_to_iso(grid_pos)
	
	for prop in proc.props:
		var prop_type = prop.get("type", 0)
		var prop_pos = prop.get("position", Vector3.ZERO)
		var prop_color = prop.get("color", Color.WHITE)
		
		# Converter posição 3D para 2D isométrico
		var iso_offset = Vector2(
			prop_pos.x * pixels_per_meter * 0.5,
			-prop_pos.y * pixels_per_meter + prop_pos.z * pixels_per_meter * 0.25
		)
		var draw_pos = base_iso + iso_offset
		
		match prop_type:
			ProceduralBuilding.Prop.SMALL_WINDOW:
				_draw_window(draw_pos, prop_color, Vector2(6, 8))
			ProceduralBuilding.Prop.SHOP_WINDOW_GLASS:
				_draw_window(draw_pos, prop_color, Vector2(12, 10))
			ProceduralBuilding.Prop.SHOP_WINDOW_BANNER:
				_draw_banner(draw_pos, prop_color)
			ProceduralBuilding.Prop.NARROW_DOOR:
				_draw_door(draw_pos, prop_color, Vector2(6, 12))
			ProceduralBuilding.Prop.WIDE_DOOR:
				_draw_door(draw_pos, prop_color, Vector2(12, 12))
			ProceduralBuilding.Prop.CHIMNEY:
				_draw_chimney(draw_pos, prop_color)
			ProceduralBuilding.Prop.SIGN:
				_draw_sign(draw_pos, prop_color)

func _draw_window(pos: Vector2, color: Color, size: Vector2) -> void:
	"""Desenha uma janela"""
	var rect = Rect2(pos - size / 2.0, size)
	draw_rect(rect, Color(0.15, 0.2, 0.25))  # Vidro escuro
	draw_rect(rect, color.darkened(0.3), false, 1.0)  # Moldura
	# Reflexo
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(size.x * 0.3, size.y * 0.5)), 
			Color(1, 1, 1, 0.2))

func _draw_door(pos: Vector2, color: Color, size: Vector2) -> void:
	"""Desenha uma porta"""
	var rect = Rect2(pos - Vector2(size.x / 2.0, size.y), size)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.4), false, 1.5)
	# Maçaneta
	draw_circle(pos + Vector2(size.x * 0.3, -size.y * 0.5), 1.5, color.lightened(0.3))

func _draw_banner(pos: Vector2, color: Color) -> void:
	"""Desenha um banner de loja"""
	var rect = Rect2(pos - Vector2(8, 3), Vector2(16, 6))
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.3), false, 1.0)

func _draw_chimney(pos: Vector2, color: Color) -> void:
	"""Desenha uma chaminé"""
	var rect = Rect2(pos - Vector2(3, 15), Vector2(6, 15))
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.3), false, 1.0)
	# Fumaça
	for i in range(3):
		var smoke_pos = pos + Vector2(0, -18 - i * 5)
		var smoke_size = 3.0 + i * 1.5
		draw_circle(smoke_pos, smoke_size, Color(0.6, 0.6, 0.6, 0.3 - i * 0.08))

func _draw_sign(pos: Vector2, color: Color) -> void:
	"""Desenha uma placa"""
	var rect = Rect2(pos - Vector2(10, 5), Vector2(20, 10))
	draw_rect(rect, color)
	draw_rect(rect, Color.BLACK, false, 1.5)

func _draw_simple_building(grid_pos: Vector2, size: Vector2, color: Color, height: float) -> void:
	"""Fallback para renderização simples de edifício"""
	var p_back = grid_to_iso(grid_pos)
	var p_right = grid_to_iso(grid_pos + Vector2(size.x, 0))
	var p_front = grid_to_iso(grid_pos + Vector2(size.x, size.y))
	var p_left = grid_to_iso(grid_pos + Vector2(0, size.y))
	
	var top_offset = Vector2(0, -height)
	var p_top_back = p_back + top_offset
	var p_top_right = p_right + top_offset
	var p_top_front = p_front + top_offset
	var p_top_left = p_left + top_offset
	
	# Faces
	draw_colored_polygon(PackedVector2Array([p_top_back, p_top_left, p_left, p_back]), color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([p_top_right, p_top_front, p_front, p_right]), color.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left]), color)

func _draw_citizen(data) -> void:
	"""Desenha um cidadão"""
	var pos: Vector2
	if data is Dictionary:
		pos = Vector2(data.get("position", Vector2i.ZERO))
	else:
		pos = Vector2(data.position)
	
	var iso_pos = grid_to_iso(pos + Vector2(0.5, 0.5))
	
	# Sombra
	draw_circle(iso_pos + Vector2(0, 2), 4, Color(0, 0, 0, 0.25))
	
	# Corpo (simplificado mas estilizado)
	var body_color = Color(0.2, 0.35, 0.65)  # Vault suit azul
	var skin_color = Color(0.9, 0.75, 0.6)
	
	# Pernas
	draw_line(iso_pos + Vector2(-2, -3), iso_pos + Vector2(-3, 2), Color(0.25, 0.25, 0.3), 2.0)
	draw_line(iso_pos + Vector2(2, -3), iso_pos + Vector2(3, 2), Color(0.25, 0.25, 0.3), 2.0)
	
	# Corpo
	draw_circle(iso_pos + Vector2(0, -8), 5, body_color)
	
	# Cabeça
	draw_circle(iso_pos + Vector2(0, -16), 4, skin_color)
	
	# Olhos
	draw_circle(iso_pos + Vector2(-1.5, -16), 0.8, Color.WHITE)
	draw_circle(iso_pos + Vector2(1.5, -16), 0.8, Color.WHITE)
	draw_circle(iso_pos + Vector2(-1.5, -16), 0.4, Color.BLACK)
	draw_circle(iso_pos + Vector2(1.5, -16), 0.4, Color.BLACK)

## Adiciona um novo edifício ao cache
func add_building(building) -> void:
	_cache_building(building)
	queue_redraw()

## Remove um edifício do cache
func remove_building(building_id: int) -> void:
	_building_cache.erase(building_id)
	queue_redraw()

## Força reconstrução do cache
func rebuild_cache() -> void:
	_rebuild_building_cache()
	queue_redraw()
