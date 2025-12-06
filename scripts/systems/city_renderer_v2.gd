## Renderizador Visual da Cidade V2 - Estilo Citybound
## 2D/2.5D Isométrico com Volume e Profundidade
class_name CityRendererV2
extends Node2D

@export var city_simulation: CitySimulation
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

## Configurações visuais
@export var building_height_scale: float = 1.5
@export var shadow_offset: Vector2 = Vector2(8, 4)
@export var shadow_alpha: float = 0.3
@export var ambient_light: Color = Color(1.0, 0.95, 0.9)
@export var show_grid: bool = false

## Cores do terreno - estilo wasteland
const COLOR_GROUND_LIGHT = Color(0.76, 0.70, 0.58)
const COLOR_GROUND_DARK = Color(0.68, 0.62, 0.50)
const COLOR_ROAD_ASPHALT = Color(0.28, 0.26, 0.24)
const COLOR_ROAD_MARKING = Color(0.9, 0.85, 0.2)
const COLOR_SIDEWALK = Color(0.55, 0.52, 0.48)

## Paleta de edifícios - estilo pós-apocalíptico
const BUILDING_PALETTES = {
	"residential": {
		"wall": Color(0.72, 0.58, 0.45),
		"wall_dark": Color(0.58, 0.45, 0.35),
		"roof": Color(0.45, 0.35, 0.28),
		"window": Color(0.3, 0.35, 0.4),
		"door": Color(0.4, 0.32, 0.25)
	},
	"commercial": {
		"wall": Color(0.55, 0.58, 0.62),
		"wall_dark": Color(0.42, 0.45, 0.50),
		"roof": Color(0.35, 0.38, 0.42),
		"window": Color(0.5, 0.6, 0.7),
		"door": Color(0.3, 0.32, 0.35)
	},
	"industrial": {
		"wall": Color(0.5, 0.48, 0.45),
		"wall_dark": Color(0.38, 0.36, 0.34),
		"roof": Color(0.4, 0.35, 0.32),
		"window": Color(0.25, 0.28, 0.3),
		"door": Color(0.35, 0.32, 0.3)
	},
	"farm": {
		"wall": Color(0.6, 0.5, 0.35),
		"wall_dark": Color(0.48, 0.4, 0.28),
		"roof": Color(0.55, 0.35, 0.25),
		"window": Color(0.4, 0.45, 0.35),
		"door": Color(0.45, 0.35, 0.25)
	}
}

func _ready():
	print("🎨 CityRendererV2 _ready() called!")
	
	if not city_simulation:
		city_simulation = get_parent().find_child("CitySimulation", true, false)
	
	if city_simulation:
		city_simulation.city_updated.connect(_on_city_updated)
		visible = true
		z_index = 10
		queue_redraw()
		print("🎨 CityRendererV2 initialized - Citybound Style!")
		print("  - Grid size: %s" % city_simulation.grid_size)
		print("  - Roads: %d" % city_simulation.roads.size())
		print("  - Buildings: %d" % city_simulation.buildings.size())
	else:
		push_error("CityRendererV2: CitySimulation NOT FOUND!")

func _process(_delta):
	queue_redraw()

## Converte grid para isométrico
func grid_to_iso(grid_pos: Vector2) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * (tile_width / 2.0),
		(grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	)

func _draw():
	# DEBUG: Sempre desenhar algo para confirmar que _draw está funcionando
	draw_circle(Vector2.ZERO, 30, Color.RED)
	draw_string(ThemeDB.fallback_font, Vector2(-50, -50), "RENDERER V2 OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	
	if not city_simulation:
		draw_string(ThemeDB.fallback_font, Vector2(0, 0), "NO SIMULATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.RED)
		return
	
	# DEBUG: Mostrar contadores
	var debug_text = "Roads: %d | Buildings: %d | Citizens: %d" % [
		city_simulation.roads.size(),
		city_simulation.buildings.size(),
		city_simulation.citizens.size()
	]
	draw_string(ThemeDB.fallback_font, Vector2(-150, -30), debug_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	
	# 1. Desenhar terreno base
	_draw_terrain()
	
	# 2. Coletar e ordenar todas as entidades por profundidade
	var entities = _collect_entities()
	entities.sort_custom(func(a, b): return a.depth < b.depth)
	
	# 3. Desenhar entidades na ordem correta
	for entity in entities:
		match entity.type:
			"road":
				_draw_road_v2(entity.data)
			"building":
				_draw_building_v2(entity.data)
			"citizen":
				_draw_citizen_v2(entity.data)

## Desenha terreno base com variação
func _draw_terrain():
	var grid_size = city_simulation.grid_size
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var color = COLOR_GROUND_LIGHT if (x + y) % 2 == 0 else COLOR_GROUND_DARK
			# Adicionar variação sutil
			var noise_val = sin(x * 0.5) * cos(y * 0.5) * 0.05
			color = color.lightened(noise_val)
			_draw_iso_tile(Vector2(x, y), color)

## Desenha tile isométrico
func _draw_iso_tile(grid_pos: Vector2, color: Color):
	var center = grid_to_iso(grid_pos)
	var points = PackedVector2Array([
		center + Vector2(0, -tile_height / 2.0),
		center + Vector2(tile_width / 2.0, 0),
		center + Vector2(0, tile_height / 2.0),
		center + Vector2(-tile_width / 2.0, 0)
	])
	draw_colored_polygon(points, color)

## Coleta todas as entidades para ordenação
func _collect_entities() -> Array:
	var entities = []
	
	# Estradas
	for road_cell in city_simulation.roads:
		var pos = Vector2(road_cell)
		entities.append({"type": "road", "depth": pos.x + pos.y, "data": {"position": pos}})
	
	# Edifícios
	for building in city_simulation.buildings:
		var pos = Vector2(building["position"])
		entities.append({"type": "building", "depth": pos.x + pos.y + 3.0, "data": building})
	
	# Cidadãos
	for citizen in city_simulation.citizens:
		var pos = Vector2(citizen["position"])
		entities.append({"type": "citizen", "depth": pos.x + pos.y + 0.5, "data": citizen})
	
	return entities

## Desenha estrada com detalhes
func _draw_road_v2(data: Dictionary):
	var pos = data["position"]
	var center = grid_to_iso(pos + Vector2(0.5, 0.5))
	
	# Base da estrada (asfalto)
	_draw_iso_tile(pos, COLOR_ROAD_ASPHALT)
	
	# Calçadas nas bordas
	var sidewalk_width = 4.0
	_draw_road_sidewalk(pos)
	
	# Marcação central (linha amarela tracejada)
	if int(pos.x + pos.y) % 3 == 0:
		draw_circle(center, 2.5, COLOR_ROAD_MARKING)

## Desenha calçada
func _draw_road_sidewalk(grid_pos: Vector2):
	var center = grid_to_iso(grid_pos + Vector2(0.5, 0.5))
	# Pequenos detalhes nas bordas
	var offset = 3.0
	draw_circle(center + Vector2(-tile_width/4, -offset), 1.5, COLOR_SIDEWALK)
	draw_circle(center + Vector2(tile_width/4, offset), 1.5, COLOR_SIDEWALK)


## Desenha edifício com volume real - estilo Citybound
func _draw_building_v2(building: Dictionary):
	var pos = Vector2(building["position"])
	var type = building["type"]
	var palette = _get_building_palette(type)
	var floors = _get_building_floors(type)
	var floor_height = 18.0 * building_height_scale
	var total_height = floors * floor_height
	
	# Tamanho do edifício (2x2 tiles)
	var width = 2
	var depth = 2
	
	# 1. SOMBRA primeiro (embaixo de tudo)
	_draw_building_shadow(pos, width, depth, total_height)
	
	# 2. Calcular pontos base
	var p_back = grid_to_iso(pos)
	var p_right = grid_to_iso(pos + Vector2(width, 0))
	var p_front = grid_to_iso(pos + Vector2(width, depth))
	var p_left = grid_to_iso(pos + Vector2(0, depth))
	
	# 3. Pontos do topo
	var top_offset = Vector2(0, -total_height)
	var p_top_back = p_back + top_offset
	var p_top_right = p_right + top_offset
	var p_top_front = p_front + top_offset
	var p_top_left = p_left + top_offset
	
	# 4. FACE ESQUERDA (mais escura)
	var left_face = PackedVector2Array([p_top_back, p_top_left, p_left, p_back])
	draw_colored_polygon(left_face, palette.wall_dark)
	
	# 5. FACE DIREITA (mais clara)
	var right_face = PackedVector2Array([p_top_right, p_top_front, p_front, p_right])
	draw_colored_polygon(right_face, palette.wall)
	
	# 6. TOPO (telhado)
	var top_face = PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left])
	draw_colored_polygon(top_face, palette.roof)
	
	# 7. Contornos
	var outline = palette.wall_dark.darkened(0.3)
	draw_line(p_top_back, p_top_right, outline, 1.5)
	draw_line(p_top_right, p_top_front, outline, 1.5)
	draw_line(p_top_front, p_top_left, outline, 1.5)
	draw_line(p_top_left, p_top_back, outline, 1.5)
	draw_line(p_top_front, p_front, outline, 1.5)
	draw_line(p_top_right, p_right, outline, 1.5)
	draw_line(p_top_left, p_left, outline, 1.5)
	draw_line(p_front, p_right, outline, 1.0)
	draw_line(p_front, p_left, outline, 1.0)
	
	# 8. JANELAS (em cada andar)
	_draw_building_windows(pos, width, depth, floors, floor_height, palette)
	
	# 9. PORTA (na face frontal)
	_draw_building_door(pos, width, depth, palette)
	
	# 10. Detalhes específicos por tipo
	_draw_building_details(building, pos, total_height, palette)

## Desenha sombra do edifício
func _draw_building_shadow(pos: Vector2, width: int, depth: int, height: float):
	var shadow_length = height * 0.4
	var p_front = grid_to_iso(pos + Vector2(width, depth))
	var p_right = grid_to_iso(pos + Vector2(width, 0))
	var p_left = grid_to_iso(pos + Vector2(0, depth))
	
	var shadow_dir = shadow_offset.normalized() * shadow_length
	
	var shadow_points = PackedVector2Array([
		p_front,
		p_right,
		p_right + shadow_dir,
		p_front + shadow_dir,
		p_left + shadow_dir,
		p_left
	])
	
	draw_colored_polygon(shadow_points, Color(0, 0, 0, shadow_alpha))

## Desenha janelas do edifício
func _draw_building_windows(pos: Vector2, width: int, depth: int, floors: int, floor_height: float, palette: Dictionary):
	var window_size = Vector2(6, 8)
	var window_spacing = 14.0
	
	for floor in range(floors):
		var floor_y = -floor_height * (floor + 0.6)
		
		# Janelas na face direita
		for w in range(2):
			var wx = 0.3 + w * 0.4
			var window_pos = grid_to_iso(pos + Vector2(width * wx, depth)) + Vector2(0, floor_y)
			_draw_window(window_pos, window_size, palette.window)
		
		# Janelas na face esquerda
		for w in range(2):
			var wy = 0.3 + w * 0.4
			var window_pos = grid_to_iso(pos + Vector2(0, depth * wy)) + Vector2(0, floor_y)
			_draw_window(window_pos, window_size * 0.9, palette.window)

## Desenha uma janela
func _draw_window(center: Vector2, size: Vector2, color: Color):
	var rect = Rect2(center - size/2, size)
	draw_rect(rect, color)
	# Moldura
	draw_rect(rect, color.darkened(0.3), false, 1.0)
	# Reflexo
	var highlight = Rect2(center - size/2 + Vector2(1, 1), size * 0.3)
	draw_rect(highlight, Color(1, 1, 1, 0.2))

## Desenha porta do edifício
func _draw_building_door(pos: Vector2, width: int, depth: int, palette: Dictionary):
	var door_pos = grid_to_iso(pos + Vector2(width * 0.5, depth)) + Vector2(0, -8)
	var door_size = Vector2(10, 16)
	var rect = Rect2(door_pos - Vector2(door_size.x/2, door_size.y), door_size)
	draw_rect(rect, palette.door)
	draw_rect(rect, palette.door.darkened(0.3), false, 1.5)
	# Maçaneta
	draw_circle(door_pos + Vector2(3, -8), 1.5, Color(0.8, 0.7, 0.3))

## Desenha detalhes específicos do tipo de edifício
func _draw_building_details(building: Dictionary, pos: Vector2, height: float, palette: Dictionary):
	var type = building["type"]
	var top_center = grid_to_iso(pos + Vector2(1, 1)) + Vector2(0, -height)
	
	match type:
		CitySimulation.BuildingType.HOUSE:
			# Telhado triangular
			_draw_roof_triangle(top_center, 30, 20, palette.roof.darkened(0.1))
			# Chaminé
			_draw_chimney(top_center + Vector2(15, 5), palette.wall_dark)
		
		CitySimulation.BuildingType.SHOP:
			# Placa/Letreiro
			_draw_shop_sign(pos, palette)
		
		CitySimulation.BuildingType.FARM:
			# Plantas ao redor
			_draw_farm_crops(pos)
		
		CitySimulation.BuildingType.WATER_TOWER:
			# Tanque de água no topo
			_draw_water_tank(top_center)
		
		CitySimulation.BuildingType.WORKSHOP:
			# Chaminé com fumaça
			_draw_chimney(top_center + Vector2(10, 0), palette.wall_dark)
			_draw_smoke(top_center + Vector2(10, -15))

## Desenha telhado triangular
func _draw_roof_triangle(center: Vector2, width: float, height: float, color: Color):
	var points = PackedVector2Array([
		center + Vector2(0, -height),
		center + Vector2(-width/2, 0),
		center + Vector2(width/2, 0)
	])
	draw_colored_polygon(points, color)
	draw_polyline(points, color.darkened(0.2), 1.5)

## Desenha chaminé
func _draw_chimney(pos: Vector2, color: Color):
	var chimney = Rect2(pos - Vector2(4, 20), Vector2(8, 20))
	draw_rect(chimney, color)
	draw_rect(chimney, color.darkened(0.2), false, 1.0)

## Desenha fumaça
func _draw_smoke(pos: Vector2):
	var smoke_color = Color(0.7, 0.7, 0.7, 0.4)
	for i in range(3):
		var offset = Vector2(sin(Time.get_ticks_msec() * 0.001 + i) * 5, -i * 8)
		draw_circle(pos + offset, 4 - i, smoke_color)

## Desenha placa de loja
func _draw_shop_sign(pos: Vector2, palette: Dictionary):
	var sign_pos = grid_to_iso(pos + Vector2(1, 2)) + Vector2(0, -25)
	var sign_rect = Rect2(sign_pos - Vector2(15, 8), Vector2(30, 16))
	draw_rect(sign_rect, Color(0.8, 0.7, 0.5))
	draw_rect(sign_rect, Color(0.5, 0.4, 0.3), false, 2.0)
	draw_string(ThemeDB.fallback_font, sign_pos + Vector2(-8, 4), "SHOP", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.3, 0.2, 0.1))

## Desenha plantações da fazenda
func _draw_farm_crops(pos: Vector2):
	var crop_color = Color(0.3, 0.6, 0.2)
	for i in range(4):
		for j in range(4):
			var crop_pos = grid_to_iso(pos + Vector2(-0.5 + i * 0.3, 2.5 + j * 0.3))
			draw_circle(crop_pos, 3, crop_color.lightened(randf() * 0.2))

## Desenha tanque de água
func _draw_water_tank(pos: Vector2):
	# Base cilíndrica
	var tank_color = Color(0.4, 0.5, 0.6)
	draw_circle(pos + Vector2(0, -20), 18, tank_color)
	draw_circle(pos + Vector2(0, -20), 18, tank_color.darkened(0.2), false, 2.0)
	# Suportes
	for i in range(4):
		var angle = i * PI / 2
		var support_end = pos + Vector2(cos(angle) * 12, 0)
		draw_line(pos + Vector2(cos(angle) * 10, -20), support_end, Color(0.3, 0.3, 0.3), 3.0)

## Retorna paleta de cores para tipo de edifício
func _get_building_palette(type: int) -> Dictionary:
	match type:
		CitySimulation.BuildingType.HOUSE:
			return BUILDING_PALETTES.residential
		CitySimulation.BuildingType.SHOP, CitySimulation.BuildingType.BAR, CitySimulation.BuildingType.HOTEL:
			return BUILDING_PALETTES.commercial
		CitySimulation.BuildingType.WORKSHOP, CitySimulation.BuildingType.WAREHOUSE:
			return BUILDING_PALETTES.industrial
		CitySimulation.BuildingType.FARM:
			return BUILDING_PALETTES.farm
		_:
			return BUILDING_PALETTES.residential

## Retorna número de andares por tipo
func _get_building_floors(type: int) -> int:
	match type:
		CitySimulation.BuildingType.HOUSE: return 2
		CitySimulation.BuildingType.SHOP: return 1
		CitySimulation.BuildingType.WORKSHOP: return 2
		CitySimulation.BuildingType.FARM: return 1
		CitySimulation.BuildingType.WATER_TOWER: return 3
		CitySimulation.BuildingType.HOTEL: return 3
		CitySimulation.BuildingType.WAREHOUSE: return 1
		_: return 1


## Desenha cidadão com mais detalhes
func _draw_citizen_v2(citizen: Dictionary):
	var grid_pos = Vector2(citizen["position"]) + Vector2(0.5, 0.5)
	var iso_pos = grid_to_iso(grid_pos)
	var state = citizen.get("state", "idle")
	
	# Cores baseadas no estado
	var body_color = _get_citizen_body_color(state)
	var skin_color = Color(0.87, 0.72, 0.58)
	
	# 1. Sombra
	_draw_ellipse(iso_pos + Vector2(0, 3), Vector2(6, 3), Color(0, 0, 0, 0.25))
	
	# 2. Pernas
	draw_line(iso_pos + Vector2(-2, -2), iso_pos + Vector2(-3, 2), body_color.darkened(0.2), 2.5)
	draw_line(iso_pos + Vector2(2, -2), iso_pos + Vector2(3, 2), body_color.darkened(0.2), 2.5)
	
	# 3. Corpo (torso)
	_draw_ellipse(iso_pos + Vector2(0, -8), Vector2(5, 8), body_color)
	
	# 4. Braços
	draw_line(iso_pos + Vector2(-5, -10), iso_pos + Vector2(-7, -2), skin_color, 2.0)
	draw_line(iso_pos + Vector2(5, -10), iso_pos + Vector2(7, -2), skin_color, 2.0)
	
	# 5. Cabeça
	draw_circle(iso_pos + Vector2(0, -18), 6, skin_color)
	
	# 6. Cabelo
	var hair_color = Color(0.25, 0.18, 0.12)
	_draw_ellipse(iso_pos + Vector2(0, -22), Vector2(5, 4), hair_color)
	
	# 7. Olhos
	draw_circle(iso_pos + Vector2(-2, -18), 1.2, Color.WHITE)
	draw_circle(iso_pos + Vector2(2, -18), 1.2, Color.WHITE)
	draw_circle(iso_pos + Vector2(-2, -18), 0.6, Color.BLACK)
	draw_circle(iso_pos + Vector2(2, -18), 0.6, Color.BLACK)
	
	# 8. Indicador de estado (ícone pequeno acima)
	_draw_citizen_state_indicator(iso_pos + Vector2(0, -30), state)

## Cor do corpo baseada no estado
func _get_citizen_body_color(state: String) -> Color:
	match state:
		"seeking_food": return Color(0.8, 0.5, 0.2)  # Laranja - com fome
		"seeking_water": return Color(0.3, 0.5, 0.8)  # Azul - com sede
		"going_home": return Color(0.3, 0.7, 0.3)    # Verde - indo pra casa
		"working": return Color(0.7, 0.6, 0.3)       # Amarelo - trabalhando
		_: return Color(0.5, 0.5, 0.55)              # Cinza - idle

## Indicador de estado do cidadão
func _draw_citizen_state_indicator(pos: Vector2, state: String):
	var icon_color = _get_citizen_body_color(state)
	match state:
		"seeking_food":
			# Ícone de comida
			draw_circle(pos, 4, icon_color)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-3, 3), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)
		"seeking_water":
			# Gota de água
			draw_circle(pos, 4, icon_color)
		"working":
			# Engrenagem
			draw_circle(pos, 4, icon_color)
			draw_circle(pos, 2, Color.WHITE)

## Desenha elipse
func _draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	var segments = 16
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func _on_city_updated():
	queue_redraw()
