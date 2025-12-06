## Renderizador Visual da Cidade - Visão Isométrica
## Desenha a cidade no estilo isométrico como Fallout 2
class_name CityRenderer
extends Node2D

@export var city_simulation: CitySimulation
@export var tile_width: float = 64.0  ## Largura do tile isométrico
@export var tile_height: float = 32.0  ## Altura do tile isométrico
@export var show_grid: bool = true
@export var show_zones: bool = true

## Cores
const COLOR_ROAD = Color(0.25, 0.22, 0.2)
const COLOR_RESIDENTIAL = Color(0.2, 0.7, 0.2, 0.4)
const COLOR_COMMERCIAL = Color(0.2, 0.2, 0.7, 0.4)
const COLOR_INDUSTRIAL = Color(0.7, 0.7, 0.2, 0.4)
const COLOR_AGRICULTURAL = Color(0.5, 0.35, 0.15, 0.4)
const COLOR_GRID = Color(0.4, 0.4, 0.4, 0.15)
const COLOR_GROUND = Color(0.6, 0.5, 0.35)

## Cores de edifícios
const BUILDING_COLORS = {
	CitySimulation.BuildingType.HOUSE: Color(0.75, 0.55, 0.35),
	CitySimulation.BuildingType.SHOP: Color(0.35, 0.55, 0.75),
	CitySimulation.BuildingType.WORKSHOP: Color(0.55, 0.55, 0.55),
	CitySimulation.BuildingType.FARM: Color(0.35, 0.7, 0.25),
	CitySimulation.BuildingType.WATER_TOWER: Color(0.25, 0.45, 0.85),
	CitySimulation.BuildingType.POWER_PLANT: Color(0.85, 0.85, 0.25),
	CitySimulation.BuildingType.CLINIC: Color(0.85, 0.25, 0.25),
	CitySimulation.BuildingType.BAR: Color(0.55, 0.25, 0.55),
	CitySimulation.BuildingType.HOTEL: Color(0.65, 0.45, 0.25),
	CitySimulation.BuildingType.WAREHOUSE: Color(0.45, 0.45, 0.45)
}

func _ready():
	print("🎨 CityRenderer _ready() called")
	
	# Se não foi atribuído no editor, procura na cena
	if not city_simulation:
		print("  - Looking for CitySimulation...")
		city_simulation = get_parent().find_child("CitySimulation", true, false)
		if not city_simulation:
			# Tentar buscar de outra forma
			var parent = get_parent()
			if parent:
				for child in parent.get_children():
					if child is CitySimulation:
						city_simulation = child
						break
	
	if city_simulation:
		city_simulation.building_constructed.connect(_on_building_constructed)
		city_simulation.citizen_spawned.connect(_on_citizen_spawned)
		city_simulation.city_updated.connect(_on_city_updated)
		
		# Garantir visibilidade
		visible = true
		z_index = 10
		
		# Forçar primeiro desenho
		queue_redraw()
		
		print("🎨 CityRenderer initialized!")
		print("  - Visible: %s" % visible)
		print("  - Z-Index: %s" % z_index)
		print("  - Position: %s" % position)
		print("  - Grid Size: %s" % city_simulation.grid_size)
		
		# Calcular centro da cidade em coordenadas isométricas
		var center_grid = Vector2(city_simulation.grid_size.x / 2.0, city_simulation.grid_size.y / 2.0)
		var center_iso = grid_to_iso(center_grid)
		print("  - City Center (grid): %s" % center_grid)
		print("  - City Center (iso): %s" % center_iso)
	else:
		push_error("CityRenderer: CitySimulation not found!")
		print("❌ CityRenderer: CitySimulation NOT FOUND!")

## Converte coordenadas do grid para isométrico
func grid_to_iso(grid_pos: Vector2) -> Vector2:
	var iso_x = (grid_pos.x - grid_pos.y) * (tile_width / 2.0)
	var iso_y = (grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	return Vector2(iso_x, iso_y)

## Converte coordenadas isométricas para grid
func iso_to_grid(iso_pos: Vector2) -> Vector2:
	var grid_x = (iso_pos.x / (tile_width / 2.0) + iso_pos.y / (tile_height / 2.0)) / 2.0
	var grid_y = (iso_pos.y / (tile_height / 2.0) - iso_pos.x / (tile_width / 2.0)) / 2.0
	return Vector2(grid_x, grid_y)

## Desenha um tile isométrico (losango)
func _draw_iso_tile(grid_pos: Vector2, color: Color, filled: bool = true, line_width: float = 1.0):
	var center = grid_to_iso(grid_pos)
	var points = PackedVector2Array([
		center + Vector2(0, -tile_height / 2.0),           # Topo
		center + Vector2(tile_width / 2.0, 0),             # Direita
		center + Vector2(0, tile_height / 2.0),            # Baixo
		center + Vector2(-tile_width / 2.0, 0)             # Esquerda
	])
	
	if filled:
		draw_colored_polygon(points, color)
	else:
		for i in range(4):
			draw_line(points[i], points[(i + 1) % 4], color, line_width)

## Desenha um cubo isométrico (edifício)
func _draw_iso_cube(grid_pos: Vector2, width: int, depth: int, height: float, color: Color):
	var base = grid_to_iso(grid_pos)
	
	# Calcular cantos do topo
	var top_offset = Vector2(0, -height)
	
	# Face superior (topo do cubo)
	var top_points = PackedVector2Array()
	for i in range(width + 1):
		for j in range(depth + 1):
			pass
	
	# Pontos do topo
	var p_top_back = grid_to_iso(grid_pos) + top_offset
	var p_top_right = grid_to_iso(grid_pos + Vector2(width, 0)) + top_offset
	var p_top_front = grid_to_iso(grid_pos + Vector2(width, depth)) + top_offset
	var p_top_left = grid_to_iso(grid_pos + Vector2(0, depth)) + top_offset
	
	# Pontos da base
	var p_base_front = grid_to_iso(grid_pos + Vector2(width, depth))
	var p_base_right = grid_to_iso(grid_pos + Vector2(width, 0))
	var p_base_left = grid_to_iso(grid_pos + Vector2(0, depth))
	
	# Face direita (mais clara)
	var right_face = PackedVector2Array([p_top_right, p_top_front, p_base_front, p_base_right])
	draw_colored_polygon(right_face, color.lightened(0.1))
	
	# Face esquerda (mais escura)
	var left_face = PackedVector2Array([p_top_back, p_top_left, p_base_left, grid_to_iso(grid_pos)])
	draw_colored_polygon(left_face, color.darkened(0.2))
	
	# Face superior
	var top_face = PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left])
	draw_colored_polygon(top_face, color)
	
	# Contornos
	var outline_color = color.darkened(0.4)
	draw_line(p_top_back, p_top_right, outline_color, 1.0)
	draw_line(p_top_right, p_top_front, outline_color, 1.0)
	draw_line(p_top_front, p_top_left, outline_color, 1.0)
	draw_line(p_top_left, p_top_back, outline_color, 1.0)
	draw_line(p_top_front, p_base_front, outline_color, 1.0)
	draw_line(p_top_right, p_base_right, outline_color, 1.0)
	draw_line(p_top_left, p_base_left, outline_color, 1.0)

func _draw():
	# DEBUG: Sempre desenhar um marcador grande para confirmar que _draw está sendo chamado
	draw_rect(Rect2(-50, -50, 100, 100), Color.RED, false, 3.0)
	draw_circle(Vector2.ZERO, 20, Color.GREEN)
	draw_string(ThemeDB.fallback_font, Vector2(-100, -80), "RENDERER OK", 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	
	if not city_simulation:
		# Debug: Desenhar mensagem de erro
		draw_string(ThemeDB.fallback_font, Vector2(0, 0), "NO SIMULATION", 
					HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.RED)
		return
	
	# Debug: Mostrar contadores
	var debug_text = "Roads: %d | Buildings: %d | Citizens: %d" % [
		city_simulation.roads.size(),
		city_simulation.buildings.size(),
		city_simulation.citizens.size()
	]
	draw_string(ThemeDB.fallback_font, Vector2(-200, -60), debug_text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	
	# Desenhar chão base
	_draw_ground()
	
	# Desenhar grid
	if show_grid:
		_draw_grid()
	
	# Desenhar zonas
	if show_zones:
		_draw_zones()
	
	# Desenhar todas as entidades com depth sorting correto
	_draw_entities_with_depth_sorting()

func _draw_ground():
	var grid_size = city_simulation.grid_size
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			_draw_iso_tile(Vector2(x, y), COLOR_GROUND.darkened(0.1 if (x + y) % 2 == 0 else 0))

func _draw_grid():
	var grid_size = city_simulation.grid_size
	
	for x in range(grid_size.x + 1):
		var start = grid_to_iso(Vector2(x, 0))
		var end = grid_to_iso(Vector2(x, grid_size.y))
		draw_line(start, end, COLOR_GRID, 1.0)
	
	for y in range(grid_size.y + 1):
		var start = grid_to_iso(Vector2(0, y))
		var end = grid_to_iso(Vector2(grid_size.x, y))
		draw_line(start, end, COLOR_GRID, 1.0)

func _draw_zones():
	for zone in city_simulation.zones:
		var color = _get_zone_color(zone["type"])
		var zone_start: Vector2i = zone["start"]
		var zone_size: Vector2i = zone["size"]
		
		# Desenhar cada tile da zona
		for x in range(zone_size.x):
			for y in range(zone_size.y):
				_draw_iso_tile(Vector2(zone_start.x + x, zone_start.y + y), color)

func _get_zone_color(type: CitySimulation.ZoneType) -> Color:
	match type:
		CitySimulation.ZoneType.RESIDENTIAL:
			return COLOR_RESIDENTIAL
		CitySimulation.ZoneType.COMMERCIAL:
			return COLOR_COMMERCIAL
		CitySimulation.ZoneType.INDUSTRIAL:
			return COLOR_INDUSTRIAL
		CitySimulation.ZoneType.AGRICULTURAL:
			return COLOR_AGRICULTURAL
		_:
			return Color.WHITE

## Estrutura para entidades renderizáveis com profundidade
class RenderEntity:
	var type: String  # "road", "building", "citizen"
	var depth: float  # Profundidade para ordenação (y + x)
	var data: Dictionary  # Dados da entidade
	
	func _init(p_type: String, p_depth: float, p_data: Dictionary):
		type = p_type
		depth = p_depth
		data = p_data

## Desenha todas as entidades com depth sorting correto
func _draw_entities_with_depth_sorting():
	var entities: Array[RenderEntity] = []
	
	# Adicionar estradas
	for road_cell in city_simulation.roads:
		var pos = Vector2(road_cell)
		var depth = pos.x + pos.y
		entities.append(RenderEntity.new("road", depth, {"position": pos}))
	
	# Adicionar edifícios
	for building in city_simulation.buildings:
		var pos = Vector2(building["position"])
		# Edifícios usam a posição frontal para depth (y + x + tamanho)
		var depth = pos.x + pos.y + 2.0  # +2 para considerar o tamanho do edifício
		entities.append(RenderEntity.new("building", depth, building))
	
	# Adicionar cidadãos
	for citizen in city_simulation.citizens:
		var pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
		var depth = pos.x + pos.y
		entities.append(RenderEntity.new("citizen", depth, citizen))
	
	# Ordenar todas as entidades por profundidade
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# Desenhar entidades na ordem correta
	for entity in entities:
		match entity.type:
			"road":
				_draw_road_entity(entity.data)
			"building":
				_draw_building_entity(entity.data)
			"citizen":
				_draw_citizen_entity(entity.data)

## Desenha uma entidade de estrada
func _draw_road_entity(data: Dictionary):
	var pos = data["position"]
	_draw_iso_tile(pos, COLOR_ROAD)
	
	# Linha amarela central
	var center = grid_to_iso(pos + Vector2(0.5, 0.5))
	draw_circle(center, 2, Color.YELLOW)

func _draw_roads():
	for road_cell in city_simulation.roads:
		_draw_iso_tile(Vector2(road_cell), COLOR_ROAD)
		
		# Linha amarela central
		var center = grid_to_iso(Vector2(road_cell) + Vector2(0.5, 0.5))
		draw_circle(center, 2, Color.YELLOW)

## Desenha uma entidade de edifício
func _draw_building_entity(building: Dictionary):
	var pos = Vector2(building["position"])
	var color = BUILDING_COLORS.get(building["type"], Color.WHITE)
	var height = _get_building_height(building["type"])
	
	# Desenhar cubo isométrico
	_draw_iso_cube(pos, 2, 2, height, color)
	
	# Desenhar ícone/detalhe no topo
	_draw_building_detail(building, pos, height)

## Desenha uma entidade de cidadão
func _draw_citizen_entity(citizen: Dictionary):
	var grid_pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
	var iso_pos = grid_to_iso(grid_pos)
	
	var color = _get_citizen_color(citizen)
	
	# Sombra
	draw_ellipse(iso_pos + Vector2(0, 2), Vector2(4, 2), Color(0, 0, 0, 0.3))
	
	# Corpo (elipse vertical)
	draw_ellipse(iso_pos + Vector2(0, -4), Vector2(3, 6), color)
	
	# Cabeça
	draw_circle(iso_pos + Vector2(0, -12), 4, Color(0.9, 0.75, 0.6))

func _draw_buildings():
	# Ordenar edifícios por profundidade (y + x) para desenhar corretamente
	var sorted_buildings = city_simulation.buildings.duplicate()
	sorted_buildings.sort_custom(func(a, b): 
		var pos_a = a["position"]
		var pos_b = b["position"]
		return (pos_a.x + pos_a.y) < (pos_b.x + pos_b.y)
	)
	
	for building in sorted_buildings:
		var pos = Vector2(building["position"])
		var color = BUILDING_COLORS.get(building["type"], Color.WHITE)
		var height = _get_building_height(building["type"])
		
		# Desenhar cubo isométrico
		_draw_iso_cube(pos, 2, 2, height, color)
		
		# Desenhar ícone/detalhe no topo
		_draw_building_detail(building, pos, height)

func _get_building_height(type: CitySimulation.BuildingType) -> float:
	match type:
		CitySimulation.BuildingType.HOUSE: return 25.0
		CitySimulation.BuildingType.SHOP: return 30.0
		CitySimulation.BuildingType.WORKSHOP: return 35.0
		CitySimulation.BuildingType.FARM: return 15.0
		CitySimulation.BuildingType.WATER_TOWER: return 50.0
		CitySimulation.BuildingType.POWER_PLANT: return 45.0
		CitySimulation.BuildingType.CLINIC: return 30.0
		CitySimulation.BuildingType.BAR: return 25.0
		CitySimulation.BuildingType.HOTEL: return 40.0
		CitySimulation.BuildingType.WAREHOUSE: return 20.0
		_: return 20.0

func _draw_building_detail(building: Dictionary, pos: Vector2, height: float):
	var center = grid_to_iso(pos + Vector2(1, 1)) + Vector2(0, -height - 5)
	
	match building["type"]:
		CitySimulation.BuildingType.HOUSE:
			# Telhado triangular
			var roof = PackedVector2Array([
				center + Vector2(0, -12),
				center + Vector2(-15, 5),
				center + Vector2(15, 5)
			])
			draw_colored_polygon(roof, Color(0.6, 0.3, 0.2))
		CitySimulation.BuildingType.WATER_TOWER:
			# Tanque circular
			draw_circle(center + Vector2(0, -10), 12, Color(0.3, 0.5, 0.8))
			draw_circle(center + Vector2(0, -10), 12, Color.BLACK, false, 1.0)
		CitySimulation.BuildingType.FARM:
			# Plantas
			for i in range(3):
				draw_circle(center + Vector2(-8 + i * 8, 0), 4, Color(0.2, 0.6, 0.1))
		CitySimulation.BuildingType.CLINIC:
			# Cruz vermelha
			draw_rect(Rect2(center - Vector2(2, 8), Vector2(4, 16)), Color.WHITE, true)
			draw_rect(Rect2(center - Vector2(8, 2), Vector2(16, 4)), Color.WHITE, true)
		CitySimulation.BuildingType.SHOP:
			# Placa
			draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)

func _draw_citizens():
	for citizen in city_simulation.citizens:
		var grid_pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
		var iso_pos = grid_to_iso(grid_pos)
		
		var color = _get_citizen_color(citizen)
		
		# Sombra
		draw_ellipse(iso_pos + Vector2(0, 2), Vector2(4, 2), Color(0, 0, 0, 0.3))
		
		# Corpo (elipse vertical)
		draw_ellipse(iso_pos + Vector2(0, -4), Vector2(3, 6), color)
		
		# Cabeça
		draw_circle(iso_pos + Vector2(0, -12), 4, Color(0.9, 0.75, 0.6))

## Desenha uma elipse
func draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func _get_citizen_color(citizen: Dictionary) -> Color:
	match citizen["state"]:
		"seeking_food":
			return Color(0.9, 0.5, 0.2)
		"seeking_water":
			return Color(0.3, 0.5, 0.9)
		"going_home":
			return Color(0.3, 0.8, 0.3)
		"working":
			return Color(0.9, 0.8, 0.3)
		_:
			return Color(0.7, 0.7, 0.7)

func _on_building_constructed(_building: Variant, _position: Vector2):
	queue_redraw()

func _on_citizen_spawned(_citizen: Variant):
	queue_redraw()

func _on_city_updated():
	queue_redraw()

func _process(_delta):
	# Redesenhar a cada frame para animações suaves
	queue_redraw()
	
	# Debug: mostrar se está renderizando
	if city_simulation:
		if Engine.get_frames_drawn() % 60 == 0:  # A cada segundo
			print("🎨 Rendering: Roads=%d, Buildings=%d, Citizens=%d" % [
				city_simulation.roads.size(),
				city_simulation.buildings.size(),
				city_simulation.citizens.size()
			])
