## BuildingRenderer - Renderizador especializado para edifícios
## Desenha edifícios como cubos isométricos 3D com shading e variantes visuais
class_name BuildingRenderer
extends Node

# Referências
var grid_system
var building_system
var building_templates

# Configurações de renderização
var tile_width: float = 64.0
var tile_height: float = 32.0

# Enum para condições visuais
enum VisualVariant {
	PRISTINE,    # Novo, bem mantido
	GOOD,        # Bom estado
	DAMAGED,     # Danificado
	RUINED,      # Arruinado
	MAKESHIFT    # Improvisado/remendado
}

func _init() -> void:
	pass

func set_systems(grid, building, templates) -> void:
	"""Define as referências aos sistemas"""
	grid_system = grid
	building_system = building
	building_templates = templates

func set_tile_size(width: float, height: float) -> void:
	"""Define o tamanho dos tiles"""
	tile_width = width
	tile_height = height

## Converte coordenadas do grid para isométrico
func grid_to_iso(grid_pos: Vector2) -> Vector2:
	var iso_x = (grid_pos.x - grid_pos.y) * (tile_width / 2.0)
	var iso_y = (grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	return Vector2(iso_x, iso_y)

## Determina a variante visual baseada na condição do edifício
func get_visual_variant(building) -> int:
	if building.condition >= 90.0:
		return VisualVariant.PRISTINE
	elif building.condition >= 70.0:
		return VisualVariant.GOOD
	elif building.condition >= 40.0:
		return VisualVariant.DAMAGED
	elif building.condition >= 10.0:
		return VisualVariant.RUINED
	else:
		return VisualVariant.MAKESHIFT

## Obtém a cor base do edifício baseada no tipo
func get_building_base_color(building_type: int) -> Color:
	match building_type:
		# Residencial - tons de marrom/bege
		BuildingSystem.BuildingType.SMALL_HOUSE:
			return Color(0.75, 0.55, 0.35)
		BuildingSystem.BuildingType.MEDIUM_HOUSE:
			return Color(0.70, 0.50, 0.30)
		BuildingSystem.BuildingType.LARGE_HOUSE:
			return Color(0.65, 0.45, 0.25)
		BuildingSystem.BuildingType.APARTMENT:
			return Color(0.60, 0.50, 0.40)
		
		# Comercial - tons de azul
		BuildingSystem.BuildingType.SHOP:
			return Color(0.35, 0.55, 0.75)
		BuildingSystem.BuildingType.MARKET:
			return Color(0.30, 0.50, 0.70)
		BuildingSystem.BuildingType.RESTAURANT:
			return Color(0.40, 0.60, 0.80)
		BuildingSystem.BuildingType.BANK:
			return Color(0.25, 0.45, 0.65)
		
		# Industrial - tons de cinza
		BuildingSystem.BuildingType.FACTORY:
			return Color(0.55, 0.55, 0.55)
		BuildingSystem.BuildingType.WORKSHOP:
			return Color(0.50, 0.50, 0.50)
		BuildingSystem.BuildingType.WAREHOUSE:
			return Color(0.45, 0.45, 0.45)
		BuildingSystem.BuildingType.POWER_PLANT:
			return Color(0.85, 0.85, 0.25)
		
		# Agrícola - tons de verde
		BuildingSystem.BuildingType.FARM:
			return Color(0.35, 0.70, 0.25)
		BuildingSystem.BuildingType.GREENHOUSE:
			return Color(0.40, 0.75, 0.30)
		BuildingSystem.BuildingType.GRAIN_MILL:
			return Color(0.50, 0.60, 0.30)
		
		# Militar - tons de verde escuro/cinza
		BuildingSystem.BuildingType.GUARD_POST:
			return Color(0.40, 0.50, 0.40)
		BuildingSystem.BuildingType.BARRACKS:
			return Color(0.35, 0.45, 0.35)
		BuildingSystem.BuildingType.WATCHTOWER:
			return Color(0.45, 0.55, 0.45)
		BuildingSystem.BuildingType.ARMORY:
			return Color(0.30, 0.40, 0.30)
		
		# Utilidade - cores específicas
		BuildingSystem.BuildingType.WATER_PUMP:
			return Color(0.25, 0.45, 0.85)
		BuildingSystem.BuildingType.MEDICAL_CLINIC:
			return Color(0.85, 0.25, 0.25)
		BuildingSystem.BuildingType.SCHOOL:
			return Color(0.70, 0.60, 0.40)
		BuildingSystem.BuildingType.LIBRARY:
			return Color(0.60, 0.50, 0.70)
		
		# Especial
		BuildingSystem.BuildingType.VAULT:
			return Color(0.20, 0.30, 0.50)
		BuildingSystem.BuildingType.SETTLEMENT_CENTER:
			return Color(0.65, 0.45, 0.25)
		
		_:
			return Color(0.7, 0.7, 0.7)

## Aplica modificadores de cor baseado na variante visual
func apply_variant_modifier(base_color: Color, variant: int) -> Color:
	match variant:
		VisualVariant.PRISTINE:
			return base_color.lightened(0.1)
		VisualVariant.GOOD:
			return base_color
		VisualVariant.DAMAGED:
			return base_color.darkened(0.15).lerp(Color(0.5, 0.4, 0.3), 0.2)
		VisualVariant.RUINED:
			return base_color.darkened(0.3).lerp(Color(0.4, 0.3, 0.2), 0.4)
		VisualVariant.MAKESHIFT:
			return base_color.darkened(0.1).lerp(Color(0.6, 0.5, 0.3), 0.3)
		_:
			return base_color

## Obtém a altura do edifício baseada no tipo e nível
func get_building_height(building_type: int, level: int) -> float:
	var base_height = 20.0
	
	match building_type:
		BuildingSystem.BuildingType.SMALL_HOUSE:
			base_height = 20.0
		BuildingSystem.BuildingType.MEDIUM_HOUSE:
			base_height = 25.0
		BuildingSystem.BuildingType.LARGE_HOUSE:
			base_height = 30.0
		BuildingSystem.BuildingType.APARTMENT:
			base_height = 40.0
		BuildingSystem.BuildingType.SHOP:
			base_height = 25.0
		BuildingSystem.BuildingType.MARKET:
			base_height = 30.0
		BuildingSystem.BuildingType.RESTAURANT:
			base_height = 28.0
		BuildingSystem.BuildingType.BANK:
			base_height = 35.0
		BuildingSystem.BuildingType.FACTORY:
			base_height = 45.0
		BuildingSystem.BuildingType.WORKSHOP:
			base_height = 30.0
		BuildingSystem.BuildingType.WAREHOUSE:
			base_height = 25.0
		BuildingSystem.BuildingType.POWER_PLANT:
			base_height = 50.0
		BuildingSystem.BuildingType.FARM:
			base_height = 15.0
		BuildingSystem.BuildingType.GREENHOUSE:
			base_height = 20.0
		BuildingSystem.BuildingType.GRAIN_MILL:
			base_height = 35.0
		BuildingSystem.BuildingType.GUARD_POST:
			base_height = 25.0
		BuildingSystem.BuildingType.BARRACKS:
			base_height = 30.0
		BuildingSystem.BuildingType.WATCHTOWER:
			base_height = 60.0
		BuildingSystem.BuildingType.ARMORY:
			base_height = 28.0
		BuildingSystem.BuildingType.WATER_PUMP:
			base_height = 40.0
		BuildingSystem.BuildingType.MEDICAL_CLINIC:
			base_height = 30.0
		BuildingSystem.BuildingType.SCHOOL:
			base_height = 35.0
		BuildingSystem.BuildingType.LIBRARY:
			base_height = 32.0
		BuildingSystem.BuildingType.VAULT:
			base_height = 55.0
		BuildingSystem.BuildingType.SETTLEMENT_CENTER:
			base_height = 45.0
	
	# Adicionar altura por nível
	return base_height + (level - 1) * 5.0

## Desenha um cubo isométrico 3D com shading
func draw_iso_cube(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int, 
					height: float, color: Color, variant: int) -> void:
	var base = grid_to_iso(grid_pos)
	
	# Aplicar modificador de variante
	var modified_color = apply_variant_modifier(color, variant)
	
	# Calcular offset do topo
	var top_offset = Vector2(0, -height)
	
	# Pontos do topo
	var p_top_back = grid_to_iso(grid_pos) + top_offset
	var p_top_right = grid_to_iso(grid_pos + Vector2(width, 0)) + top_offset
	var p_top_front = grid_to_iso(grid_pos + Vector2(width, depth)) + top_offset
	var p_top_left = grid_to_iso(grid_pos + Vector2(0, depth)) + top_offset
	
	# Pontos da base
	var p_base_back = grid_to_iso(grid_pos)
	var p_base_right = grid_to_iso(grid_pos + Vector2(width, 0))
	var p_base_front = grid_to_iso(grid_pos + Vector2(width, depth))
	var p_base_left = grid_to_iso(grid_pos + Vector2(0, depth))
	
	# Face direita (mais clara - luz vindo da direita)
	var right_face = PackedVector2Array([p_top_right, p_top_front, p_base_front, p_base_right])
	var right_color = modified_color.lightened(0.15)
	canvas.draw_colored_polygon(right_face, right_color)
	
	# Face esquerda (mais escura - sombra)
	var left_face = PackedVector2Array([p_top_back, p_top_left, p_base_left, p_base_back])
	var left_color = modified_color.darkened(0.25)
	canvas.draw_colored_polygon(left_face, left_color)
	
	# Face superior (cor base)
	var top_face = PackedVector2Array([p_top_back, p_top_right, p_top_front, p_top_left])
	canvas.draw_colored_polygon(top_face, modified_color)
	
	# Adicionar detalhes de variante
	_draw_variant_details(canvas, grid_pos, width, depth, height, variant, modified_color)
	
	# Contornos (mais escuros para definição)
	var outline_color = modified_color.darkened(0.5)
	var outline_width = 1.5 if variant == VisualVariant.PRISTINE else 1.0
	
	# Contornos do topo
	canvas.draw_line(p_top_back, p_top_right, outline_color, outline_width)
	canvas.draw_line(p_top_right, p_top_front, outline_color, outline_width)
	canvas.draw_line(p_top_front, p_top_left, outline_color, outline_width)
	canvas.draw_line(p_top_left, p_top_back, outline_color, outline_width)
	
	# Contornos verticais
	canvas.draw_line(p_top_front, p_base_front, outline_color, outline_width)
	canvas.draw_line(p_top_right, p_base_right, outline_color, outline_width)
	canvas.draw_line(p_top_left, p_base_left, outline_color, outline_width)

## Desenha detalhes específicos da variante visual
func _draw_variant_details(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int,
							height: float, variant: int, color: Color) -> void:
	match variant:
		VisualVariant.PRISTINE:
			# Janelas brilhantes
			_draw_windows(canvas, grid_pos, width, depth, height, Color(0.9, 0.9, 0.5, 0.8))
		
		VisualVariant.GOOD:
			# Janelas normais
			_draw_windows(canvas, grid_pos, width, depth, height, Color(0.7, 0.7, 0.4, 0.6))
		
		VisualVariant.DAMAGED:
			# Janelas quebradas e rachaduras
			_draw_windows(canvas, grid_pos, width, depth, height, Color(0.3, 0.3, 0.3, 0.4))
			_draw_cracks(canvas, grid_pos, width, depth, height, color.darkened(0.4))
		
		VisualVariant.RUINED:
			# Buracos e destruição
			_draw_holes(canvas, grid_pos, width, depth, height, Color(0.1, 0.1, 0.1, 0.7))
			_draw_debris(canvas, grid_pos, width, depth, color.darkened(0.5))
		
		VisualVariant.MAKESHIFT:
			# Remendos e placas de metal
			_draw_patches(canvas, grid_pos, width, depth, height, Color(0.5, 0.5, 0.5, 0.6))

## Desenha janelas no edifício
func _draw_windows(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int,
					height: float, window_color: Color) -> void:
	# Janelas na face direita
	var right_base = grid_to_iso(grid_pos + Vector2(width, 0))
	var right_offset = Vector2(0, -height * 0.7)
	canvas.draw_rect(Rect2(right_base + right_offset + Vector2(-4, 0), Vector2(6, 8)), window_color, true)
	
	# Janelas na face esquerda
	var left_base = grid_to_iso(grid_pos + Vector2(0, depth))
	var left_offset = Vector2(0, -height * 0.7)
	canvas.draw_rect(Rect2(left_base + left_offset + Vector2(-2, 0), Vector2(6, 8)), window_color, true)

## Desenha rachaduras no edifício
func _draw_cracks(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int,
					height: float, crack_color: Color) -> void:
	var base = grid_to_iso(grid_pos + Vector2(width * 0.5, depth * 0.5))
	var top_offset = Vector2(0, -height * 0.5)
	
	# Rachadura diagonal
	canvas.draw_line(base + top_offset + Vector2(-8, -5), 
					base + top_offset + Vector2(8, 10), crack_color, 1.5)
	canvas.draw_line(base + top_offset + Vector2(-5, 0), 
					base + top_offset + Vector2(5, 8), crack_color, 1.0)

## Desenha buracos no edifício arruinado
func _draw_holes(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int,
				height: float, hole_color: Color) -> void:
	var base = grid_to_iso(grid_pos + Vector2(width * 0.6, depth * 0.4))
	var offset = Vector2(0, -height * 0.6)
	
	# Buraco irregular
	var hole_points = PackedVector2Array([
		base + offset + Vector2(-6, -4),
		base + offset + Vector2(4, -2),
		base + offset + Vector2(6, 6),
		base + offset + Vector2(-4, 8)
	])
	canvas.draw_colored_polygon(hole_points, hole_color)

## Desenha detritos ao redor do edifício
func _draw_debris(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int, debris_color: Color) -> void:
	# Pequenos detritos ao redor da base
	for i in range(3):
		var offset = Vector2(randf_range(-width * 0.3, width * 0.3), 
							randf_range(-depth * 0.3, depth * 0.3))
		var debris_pos = grid_to_iso(grid_pos + Vector2(width * 0.5, depth * 0.5) + offset)
		canvas.draw_circle(debris_pos, randf_range(2, 4), debris_color)

## Desenha remendos no edifício improvisado
func _draw_patches(canvas: CanvasItem, grid_pos: Vector2, width: int, depth: int,
					height: float, patch_color: Color) -> void:
	# Remendos de metal na face direita
	var right_base = grid_to_iso(grid_pos + Vector2(width, depth * 0.5))
	var right_offset = Vector2(0, -height * 0.4)
	canvas.draw_rect(Rect2(right_base + right_offset + Vector2(-8, 0), Vector2(12, 10)), 
					patch_color, true)
	canvas.draw_rect(Rect2(right_base + right_offset + Vector2(-8, 0), Vector2(12, 10)), 
					patch_color.darkened(0.3), false, 1.0)
	
	# Remendos na face esquerda
	var left_base = grid_to_iso(grid_pos + Vector2(width * 0.5, depth))
	var left_offset = Vector2(0, -height * 0.6)
	canvas.draw_rect(Rect2(left_base + left_offset + Vector2(-6, 0), Vector2(10, 8)), 
					patch_color, true)
	canvas.draw_rect(Rect2(left_base + left_offset + Vector2(-6, 0), Vector2(10, 8)), 
					patch_color.darkened(0.3), false, 1.0)

## Desenha um edifício completo
func draw_building(canvas: CanvasItem, building) -> void:
	if building == null:
		return
	
	var pos = Vector2(building.position)
	var size = building.size
	var building_type = building.building_type
	var level = building.level
	
	# Obter cor base e variante
	var base_color = get_building_base_color(building_type)
	var variant = get_visual_variant(building)
	var height = get_building_height(building_type, level)
	
	# Desenhar cubo isométrico
	draw_iso_cube(canvas, pos, size.x, size.y, height, base_color, variant)
	
	# Desenhar detalhes específicos do tipo de edifício
	_draw_building_type_details(canvas, building, pos, size, height, variant)
	
	# Desenhar indicador de construção se necessário
	if building.is_under_construction:
		_draw_construction_indicator(canvas, pos, size, height, building.construction_progress)

## Desenha detalhes específicos do tipo de edifício
func _draw_building_type_details(canvas: CanvasItem, building, pos: Vector2, size: Vector2i,
								height: float, variant: int) -> void:
	var center = grid_to_iso(pos + Vector2(size.x * 0.5, size.y * 0.5)) + Vector2(0, -height - 8)
	
	# Apenas desenhar detalhes se não estiver arruinado
	if variant == VisualVariant.RUINED:
		return
	
	match building.building_type:
		BuildingSystem.BuildingType.SMALL_HOUSE, BuildingSystem.BuildingType.MEDIUM_HOUSE, BuildingSystem.BuildingType.LARGE_HOUSE:
			# Telhado triangular
			var roof_height = 15.0
			var roof = PackedVector2Array([
				center + Vector2(0, -roof_height),
				center + Vector2(-size.x * 8, roof_height * 0.4),
				center + Vector2(size.x * 8, roof_height * 0.4)
			])
			var roof_color = Color(0.6, 0.3, 0.2) if variant == VisualVariant.PRISTINE else Color(0.5, 0.25, 0.15)
			canvas.draw_colored_polygon(roof, roof_color)
			canvas.draw_polyline(roof, roof_color.darkened(0.4), 1.5)
		
		BuildingSystem.BuildingType.WATER_PUMP:
			# Tanque de água
			canvas.draw_circle(center + Vector2(0, -8), 10, Color(0.3, 0.5, 0.8))
			canvas.draw_circle(center + Vector2(0, -8), 10, Color.BLACK, false, 1.5)
			canvas.draw_circle(center + Vector2(0, -8), 6, Color(0.4, 0.6, 0.9))
		
		BuildingSystem.BuildingType.FARM, BuildingSystem.BuildingType.GREENHOUSE:
			# Plantas
			for i in range(3):
				var plant_pos = center + Vector2(-12 + i * 12, 5)
				canvas.draw_circle(plant_pos, 4, Color(0.2, 0.6, 0.1))
				canvas.draw_circle(plant_pos + Vector2(0, -2), 3, Color(0.3, 0.7, 0.2))
		
		BuildingSystem.BuildingType.MEDICAL_CLINIC:
			# Cruz vermelha
			var cross_color = Color.WHITE if variant == VisualVariant.PRISTINE else Color(0.9, 0.9, 0.9)
			canvas.draw_rect(Rect2(center - Vector2(2, 10), Vector2(4, 20)), cross_color, true)
			canvas.draw_rect(Rect2(center - Vector2(10, 2), Vector2(20, 4)), cross_color, true)
			canvas.draw_rect(Rect2(center - Vector2(2, 10), Vector2(4, 20)), Color.RED, false, 1.5)
			canvas.draw_rect(Rect2(center - Vector2(10, 2), Vector2(20, 4)), Color.RED, false, 1.5)
		
		BuildingSystem.BuildingType.SHOP, BuildingSystem.BuildingType.MARKET:
			# Símbolo de dinheiro
			var font = ThemeDB.fallback_font
			var font_size = 16 if variant == VisualVariant.PRISTINE else 14
			var text_color = Color.YELLOW if variant == VisualVariant.PRISTINE else Color(0.8, 0.8, 0.3)
			canvas.draw_string(font, center + Vector2(-6, 5), "$", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
		
		BuildingSystem.BuildingType.POWER_PLANT:
			# Chaminé com fumaça
			var chimney_base = center + Vector2(8, -10)
			canvas.draw_rect(Rect2(chimney_base, Vector2(6, 15)), Color(0.3, 0.3, 0.3), true)
			# Fumaça (apenas se operacional)
			if building.is_operational:
				for i in range(3):
					var smoke_pos = chimney_base + Vector2(3, -5 - i * 6)
					var smoke_size = 4.0 + i * 2.0
					canvas.draw_circle(smoke_pos, smoke_size, Color(0.6, 0.6, 0.6, 0.4 - i * 0.1))
		
		BuildingSystem.BuildingType.WATCHTOWER:
			# Plataforma de observação no topo
			var platform_y = center.y - 10
			canvas.draw_rect(Rect2(center + Vector2(-12, platform_y), Vector2(24, 3)), Color(0.4, 0.3, 0.2), true)
			canvas.draw_line(center + Vector2(-12, platform_y), center + Vector2(-12, platform_y + 8), Color(0.3, 0.2, 0.1), 2.0)
			canvas.draw_line(center + Vector2(12, platform_y), center + Vector2(12, platform_y + 8), Color(0.3, 0.2, 0.1), 2.0)

## Desenha indicador de construção
func _draw_construction_indicator(canvas: CanvasItem, pos: Vector2, size: Vector2i,
								height: float, progress: float) -> void:
	var center = grid_to_iso(pos + Vector2(size.x * 0.5, size.y * 0.5))
	var bar_width = size.x * 16.0
	var bar_height = 6.0
	var bar_pos = center + Vector2(-bar_width * 0.5, -height - 20)
	
	# Fundo da barra
	canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2, 0.8), true)
	
	# Progresso
	var progress_width = bar_width * (progress / 100.0)
	canvas.draw_rect(Rect2(bar_pos, Vector2(progress_width, bar_height)), Color(0.3, 0.8, 0.3, 0.9), true)
	
	# Contorno
	canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.WHITE, false, 1.0)
	
	# Texto de porcentagem
	var font = ThemeDB.fallback_font
	var text = "%d%%" % int(progress)
	canvas.draw_string(font, bar_pos + Vector2(bar_width * 0.5 - 10, -2), text, 
						HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

## Desenha todos os edifícios (para uso em batch)
func draw_all_buildings(canvas: CanvasItem) -> void:
	if building_system == null:
		return
	
	var buildings = building_system.get_all_buildings()
	
	# Ordenar por profundidade (y + x) para renderização correta
	buildings.sort_custom(func(a, b):
		var pos_a = a.position
		var pos_b = b.position
		return (pos_a.x + pos_a.y) < (pos_b.x + pos_b.y)
	)
	
	# Desenhar cada edifício
	for building in buildings:
		draw_building(canvas, building)
