extends Node

## Sistema de Renderizacao Isometrica do Fallout 2
## Baseado no codigo original (src/tile.cc)
## Implementa a grade hexagonal isometrica do jogo

# Constantes do original
const TILE_WIDTH = 80   # Largura do tile em pixels
const TILE_HEIGHT = 36  # Altura do tile em pixels
const HEX_WIDTH = 32    # Largura do hex
const HEX_HEIGHT = 16   # Altura do hex
const ELEVATION_OFFSET = 96  # Offset vertical por elevacao

# Tamanho padrao do mapa (igual ao original)
const DEFAULT_MAP_WIDTH = 200
const DEFAULT_MAP_HEIGHT = 200

# Offsets para as 6 direcoes hexagonais
# 0=NE, 1=E, 2=SE, 3=SW, 4=W, 5=NW
const HEX_OFFSETS = [
	Vector2i(1, -1),   # NE
	Vector2i(1, 0),    # E
	Vector2i(0, 1),    # SE
	Vector2i(-1, 1),   # SW
	Vector2i(-1, 0),   # W
	Vector2i(0, -1)    # NW
]

# Offsets de tela para cada direcao (igual ao original: _off_tile)
const SCREEN_OFFSETS = [
	Vector2(16, -12),  # NE
	Vector2(32, 0),    # E
	Vector2(16, 12),   # SE
	Vector2(-16, 12),  # SW
	Vector2(-32, 0),   # W
	Vector2(-16, -12)  # NW
]

var map_width: int = DEFAULT_MAP_WIDTH
var map_height: int = DEFAULT_MAP_HEIGHT
var hex_grid_size: int = 0

func _ready():
	hex_grid_size = map_width * map_height

# === CONVERSAO DE COORDENADAS ===

func tile_to_screen(tile_pos: Vector2i, elevation: int = 0, sprite_offset: Vector2 = Vector2.ZERO) -> Vector2:
	"""
	Converte coordenadas de tile para coordenadas de tela
	Baseado em tileToScreenXY do original
	Args:
		tile_pos: Posicao do tile (x, y)
		elevation: Nivel de elevacao (0, 1, 2)
		sprite_offset: Offset adicional do sprite em pixels
	"""
	# Formula isometrica do Fallout 2
	var screen_x = (tile_pos.x - tile_pos.y) * (TILE_WIDTH / 2)
	var screen_y = (tile_pos.x + tile_pos.y) * (TILE_HEIGHT / 2) - (elevation * ELEVATION_OFFSET)
	return Vector2(screen_x, screen_y) + sprite_offset

func screen_to_tile(screen_pos: Vector2, elevation: int = 0, sprite_offset: Vector2 = Vector2.ZERO) -> Vector2i:
	"""
	Converte coordenadas de tela para coordenadas de tile
	Baseado em tileFromScreenXY do original
	Args:
		screen_pos: Posicao na tela (x, y)
		elevation: Nivel de elevacao (0, 1, 2)
		sprite_offset: Offset adicional do sprite em pixels (para reverter)
	"""
	# Remover offset do sprite e ajustar pela elevacao
	var adjusted_pos = screen_pos - sprite_offset
	var adjusted_y = adjusted_pos.y + (elevation * ELEVATION_OFFSET)
	
	# Formula inversa
	var tile_x = int((adjusted_pos.x / (TILE_WIDTH / 2.0) + adjusted_y / (TILE_HEIGHT / 2.0)) / 2.0)
	var tile_y = int((adjusted_y / (TILE_HEIGHT / 2.0) - adjusted_pos.x / (TILE_WIDTH / 2.0)) / 2.0)
	return Vector2i(tile_x, tile_y)

func hex_to_screen(hex_x: int, hex_y: int) -> Vector2:
	"""
	Converte coordenadas hexagonais para coordenadas de tela
	"""
	var screen_x = hex_x * HEX_WIDTH + (hex_y % 2) * (HEX_WIDTH / 2)
	var screen_y = hex_y * HEX_HEIGHT * 0.75
	return Vector2(screen_x, screen_y)

func screen_to_hex(screen_x: float, screen_y: float) -> Vector2i:
	"""
	Converte coordenadas de tela para coordenadas hexagonais
	"""
	var hex_y = int(screen_y / (HEX_HEIGHT * 0.75))
	var hex_x = int((screen_x - (hex_y % 2) * (HEX_WIDTH / 2)) / HEX_WIDTH)
	return Vector2i(hex_x, hex_y)

func tile_index_to_coords(tile_index: int) -> Vector2i:
	"""
	Converte indice de tile para coordenadas x,y
	"""
	if tile_index < 0 or tile_index >= hex_grid_size:
		return Vector2i(-1, -1)
	var x = tile_index % map_width
	var y = tile_index / map_width
	return Vector2i(x, y)

func coords_to_tile_index(x: int, y: int) -> int:
	"""
	Converte coordenadas x,y para indice de tile
	"""
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return -1
	return y * map_width + x

# === DISTANCIA E DIRECAO ===

func tile_distance(tile1: Vector2i, tile2: Vector2i) -> int:
	"""
	Calcula distancia entre dois tiles (igual ao original: tileDistanceBetween)
	"""
	var dx = abs(tile2.x - tile1.x)
	var dy = abs(tile2.y - tile1.y)
	return max(dx, dy)

func get_direction_to(from: Vector2i, to: Vector2i) -> int:
	"""
	Retorna a direcao de um tile para outro (0-5)
	Baseado em tileGetRotationTo do original
	"""
	var dx = to.x - from.x
	var dy = to.y - from.y
	
	if dx == 0 and dy == 0:
		return 0
	
	var angle = atan2(dy, dx)
	var deg = rad_to_deg(angle)
	
	# Normalizar para 0-360
	if deg < 0:
		deg += 360
	
	# Mapear para 6 direcoes
	return int((deg + 30) / 60) % 6

func get_tile_in_direction(tile: Vector2i, direction: int, distance: int = 1) -> Vector2i:
	"""
	Retorna o tile na direcao especificada
	Baseado em tileGetTileInDirection do original
	"""
	if direction < 0 or direction > 5:
		return tile
	
	var offset = HEX_OFFSETS[direction]
	return tile + offset * distance

func is_tile_in_front(tile1: Vector2i, tile2: Vector2i) -> bool:
	"""
	Verifica se tile1 esta na frente de tile2 (para ordenacao)
	Baseado em tileIsInFrontOf do original
	"""
	return (tile1.x + tile1.y) > (tile2.x + tile2.y)

func is_tile_to_right(tile1: Vector2i, tile2: Vector2i) -> bool:
	"""
	Verifica se tile1 esta a direita de tile2
	Baseado em tileIsToRightOf do original
	"""
	return (tile1.x - tile1.y) > (tile2.x - tile2.y)

# === VALIDACAO ===

func is_valid_tile(tile: Vector2i) -> bool:
	"""Verifica se o tile e valido"""
	return tile.x >= 0 and tile.x < map_width and tile.y >= 0 and tile.y < map_height

func is_edge_tile(tile: Vector2i) -> bool:
	"""
	Verifica se o tile esta na borda do mapa
	Baseado em tileIsEdge do original
	"""
	return tile.x == 0 or tile.x == map_width - 1 or tile.y == 0 or tile.y == map_height - 1

# === UTILIDADES ===

func get_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	"""Retorna todos os tiles dentro de um raio"""
	var tiles: Array[Vector2i] = []
	
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var tile = Vector2i(x, y)
			if is_valid_tile(tile) and tile_distance(center, tile) <= radius:
				tiles.append(tile)
	
	return tiles

func get_line_of_tiles(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	"""Retorna linha de tiles entre dois pontos (Bresenham)"""
	var tiles: Array[Vector2i] = []
	
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx - dy
	
	var current = from
	while true:
		tiles.append(current)
		if current == to:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return tiles

# === SORTING (ORDENACAO DE SPRITES) ===

func get_sort_order(tile: Vector2i, elevation: int = 0) -> int:
	"""
	Retorna ordem de renderizacao para um tile
	Objetos com maior valor sao renderizados por cima
	Formula: y + elevation * offset para ordenacao correta
	"""
	# Usar a posicao Y na tela como base, considerando elevacao
	var screen_pos = tile_to_screen(tile, elevation)
	return int(screen_pos.y + elevation * ELEVATION_OFFSET)

func sort_sprites(sprites: Array[Node2D]) -> void:
	"""
	Ordena sprites por profundidade e atualiza z_index
	Integra com CanvasItem.z_index para renderizacao correta
	"""
	# Criar array de tuplas (sprite, sort_order)
	var sprite_data = []
	for sprite in sprites:
		var elevation = 0
		# Tentar obter elevacao do sprite se tiver a propriedade
		if sprite.has_meta("elevation"):
			elevation = sprite.get_meta("elevation")
		
		var tile_pos = screen_to_tile(sprite.global_position, elevation)
		var sort_order = get_sort_order(tile_pos, elevation)
		sprite_data.append({"sprite": sprite, "order": sort_order})
	
	# Ordenar por sort_order
	sprite_data.sort_custom(func(a, b): return a.order < b.order)
	
	# Atualizar z_index de cada sprite
	for i in range(sprite_data.size()):
		sprite_data[i].sprite.z_index = i

func sort_objects_for_rendering(objects: Array) -> Array:
	"""
	Ordena objetos para renderizacao correta (painter's algorithm)
	DEPRECATED: Use sort_sprites() para melhor integracao com z_index
	"""
	objects.sort_custom(func(a, b):
		var pos_a = screen_to_tile(a.global_position)
		var pos_b = screen_to_tile(b.global_position)
		return get_sort_order(pos_a) < get_sort_order(pos_b)
	)
	return objects

# === ELEVATION LAYERS ===

func create_elevation_layers(parent: Node, num_elevations: int = 3) -> Array[Node2D]:
	"""
	Cria camadas separadas para cada elevacao
	Retorna array de nodes, um para cada elevacao
	"""
	var layers: Array[Node2D] = []
	for i in range(num_elevations):
		var layer = Node2D.new()
		layer.name = "ElevationLayer_" + str(i)
		layer.set_meta("elevation", i)
		parent.add_child(layer)
		layers.append(layer)
	return layers

func set_elevation_visibility(layers: Array[Node2D], current_elevation: int) -> void:
	"""
	Controla visibilidade das camadas baseado na elevacao atual
	Mostra apenas a camada atual e as abaixo (com transparencia)
	"""
	for i in range(layers.size()):
		var layer = layers[i]
		if i == current_elevation:
			layer.visible = true
			layer.modulate = Color(1, 1, 1, 1)  # Totalmente visivel
		elif i < current_elevation:
			layer.visible = true
			layer.modulate = Color(1, 1, 1, 0.5)  # Semi-transparente
		else:
			layer.visible = false  # Esconder elevacoes acima
