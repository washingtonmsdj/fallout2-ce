extends Node2D

## Script base para mapas convertidos do Fallout 2
## Carrega dados do JSON e renderiza o mapa com tiles reais

@export var map_name: String = ""
@export var map_file: String = ""
@export var entering_x: int = 50
@export var entering_y: int = 50
@export var entering_elevation: int = 0

@onready var world: Node2D = $World
@onready var ground: Node2D = $World/Ground
@onready var objects_node: Node2D = $World/Objects
@onready var player: CharacterBody2D = $Player

var iso_renderer: Node = null
var map_data: Dictionary = {}
var tile_mapping: Dictionary = {}
var tile_cache: Dictionary = {}
var is_ready: bool = false

const TILE_WIDTH = 80
const TILE_HEIGHT = 36

func _ready():
	print("BaseMap: Carregando ", map_name)
	
	iso_renderer = get_node_or_null("/root/IsometricRenderer")
	
	await get_tree().process_frame
	
	# Carregar mapeamento de tiles
	_load_tile_mapping()
	
	# Carregar dados do mapa
	_load_map_data()
	
	# Renderizar mapa
	_render_map()
	
	# Configurar player
	_setup_player()
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_map = self
		gm.current_map_name = map_name
		gm.change_state(gm.GameState.EXPLORATION)
	
	is_ready = true
	print("BaseMap: ", map_name, " carregado!")

func _load_tile_mapping():
	"""Carrega mapeamento de floor_id para nomes de tiles."""
	var mapping_path = "res://assets/data/tile_mapping.json"
	
	if ResourceLoader.exists(mapping_path):
		var file = FileAccess.open(mapping_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_text) == OK:
				tile_mapping = json.data
				print("BaseMap: Mapeamento carregado - ", tile_mapping.size(), " tiles")
	else:
		print("BaseMap: Mapeamento não encontrado, usando fallback")


func _load_map_data():
	"""Carrega dados do JSON do mapa."""
	# Extrair nome base do arquivo
	var base_name = map_file.replace(".map", "").replace(".MAP", "").to_lower()
	# Remover qualquer caminho
	if "/" in base_name:
		base_name = base_name.get_file()
	if "\\" in base_name:
		base_name = base_name.split("\\")[-1]
	
	var json_path = "res://assets/data/maps/" + base_name + ".json"
	
	print("BaseMap: map_file = ", map_file)
	print("BaseMap: base_name = ", base_name)
	print("BaseMap: Tentando carregar: ", json_path)
	
	# Tentar abrir o arquivo diretamente (JSON não precisa de ResourceLoader)
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		print("BaseMap: JSON lido, tamanho = ", json_text.length())
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			map_data = json.data
			var tiles_count = map_data.get("tiles", []).size()
			print("BaseMap: Dados carregados - tiles: ", tiles_count, " stats: ", map_data.get("stats", {}))
		else:
			print("BaseMap: Erro ao parsear JSON: ", json.get_error_message())
		file.close()
	else:
		var err = FileAccess.get_open_error()
		print("BaseMap: Erro ao abrir arquivo: ", err)
		print("BaseMap: Arquivo não encontrado, map_data ficará vazio")

func _get_tile_texture(floor_id: int) -> Texture2D:
	"""Obtém textura do tile pelo floor_id."""
	# Extrair índice real do tile (12 bits inferiores, igual ao original)
	var tile_index = floor_id & 0xFFF
	
	# Verificar cache
	if tile_cache.has(tile_index):
		return tile_cache[tile_index]
	
	var texture: Texture2D = null
	
	# Tentar obter nome do mapeamento
	var tile_name = tile_mapping.get(str(tile_index), "")
	
	if tile_name != "":
		var tile_path = "res://assets/sprites/tiles/" + tile_name + ".png"
		if ResourceLoader.exists(tile_path):
			texture = load(tile_path)
	
	# Não usar fallback - se não encontrar, retorna null
	
	# Cachear resultado
	if texture:
		tile_cache[tile_index] = texture
	
	return texture

func _render_map():
	"""Renderiza tiles e objetos do mapa."""
	print("BaseMap: _render_map chamado, map_data.is_empty() = ", map_data.is_empty())
	
	if map_data.is_empty():
		print("BaseMap: Sem dados, criando mapa fallback")
		_create_fallback_map()
		return
	
	var tiles = map_data.get("tiles", [])
	print("BaseMap: Renderizando ", tiles.size(), " tiles")
	print("BaseMap: tile_mapping.size() = ", tile_mapping.size())
	
	var rendered = 0
	var skipped = 0
	
	# Renderizar tiles de todos os níveis (0, 1, 2)
	# No Fallout 2, nível 0 pode ser vazio e nível 1 ter os tiles reais
	for tile in tiles:
		var elevation: int = int(tile.get("elevation", 0))
		
		# Por enquanto só renderizar níveis 0 e 1
		if elevation > 1:
			skipped += 1
			continue
		
		var x: int = int(tile.get("x", 0))
		var y: int = int(tile.get("y", 0))
		var floor_id: int = int(tile.get("floor_id", 1))
		
		# Extrair índice real do tile (12 bits inferiores)
		var tile_index: int = floor_id & 0xFFF
		
		# Pular tiles vazios ou inválidos
		# - índice 0 ou 1 = vazio/grid
		# - índice >= 4095 (0xFFF) = inválido
		# - índice > tile_mapping.size() = não existe
		if tile_index <= 1 or tile_index >= 4095:
			skipped += 1
			continue
		
		# Verificar se o tile existe no mapeamento
		if not tile_mapping.has(str(tile_index)):
			skipped += 1
			continue
		
		var screen_pos = _tile_to_screen(x, y)
		
		# Ajustar posição Y para elevação
		if elevation > 0:
			screen_pos.y -= elevation * 96  # ELEVATION_OFFSET do original
		
		var sprite = Sprite2D.new()
		sprite.name = "Tile_%d_%d_E%d" % [x, y, elevation]
		sprite.position = screen_pos
		sprite.centered = true
		
		var texture = _get_tile_texture(floor_id)
		if texture:
			sprite.texture = texture
			# Z-index considera elevação
			sprite.z_index = -10000 + (x + y) * 10 + elevation * 1000
			ground.add_child(sprite)
			rendered += 1
		else:
			skipped += 1
	
	print("BaseMap: Floor tiles renderizados: ", rendered, " | Pulados: ", skipped)
	
	# Renderizar roof tiles (paredes/tetos)
	var roof_rendered = 0
	for tile in tiles:
		var elevation: int = int(tile.get("elevation", 0))
		if elevation > 1:
			continue
		
		var x: int = int(tile.get("x", 0))
		var y: int = int(tile.get("y", 0))
		var roof_id: int = int(tile.get("roof_id", 0))
		
		# Extrair índice real do roof tile
		var roof_index: int = roof_id & 0xFFF
		
		# Pular roofs vazios
		if roof_index <= 1 or roof_index >= 4095:
			continue
		
		# Verificar se existe no mapeamento
		if not tile_mapping.has(str(roof_index)):
			continue
		
		var screen_pos = _tile_to_screen(x, y)
		# Roofs são renderizados mais acima
		screen_pos.y -= 96
		
		var sprite = Sprite2D.new()
		sprite.name = "Roof_%d_%d" % [x, y]
		sprite.position = screen_pos
		sprite.centered = true
		
		var texture = _get_tile_texture(roof_id)
		if texture:
			sprite.texture = texture
			# Roofs ficam acima dos tiles de chão
			sprite.z_index = -5000 + (x + y) * 10
			ground.add_child(sprite)
			roof_rendered += 1
	
	print("BaseMap: Roof tiles renderizados: ", roof_rendered)
	
	# Renderizar objetos
	_render_objects()

func _tile_to_screen(x: int, y: int) -> Vector2:
	"""Converte coordenadas de tile para tela."""
	if iso_renderer:
		return iso_renderer.tile_to_screen(Vector2i(x, y), 0)
	else:
		# Fórmula isométrica do Fallout 2
		var screen_x = (x - y) * (TILE_WIDTH / 2)
		var screen_y = (x + y) * (TILE_HEIGHT / 2)
		return Vector2(screen_x, screen_y)


func _render_objects():
	"""Renderiza objetos do mapa (scenery, items, etc)."""
	var objects = map_data.get("objects", [])
	if objects.is_empty():
		return
	
	print("BaseMap: Renderizando ", objects.size(), " objetos")
	
	for obj in objects:
		var x: int = int(obj.get("x", 0))
		var y: int = int(obj.get("y", 0))
		var elevation: int = int(obj.get("elevation", 0))
		var obj_type: String = str(obj.get("object_type", "misc"))
		
		# Por enquanto só nível 0
		if elevation != 0:
			continue
		
		var screen_pos = _tile_to_screen(x, y)
		
		# Criar placeholder para objeto
		var placeholder = ColorRect.new()
		placeholder.name = "Obj_%d_%d_%s" % [x, y, obj_type]
		placeholder.size = Vector2(16, 16)
		placeholder.position = screen_pos - Vector2(8, 8)
		
		# Cores por tipo
		match obj_type:
			"critter":
				placeholder.color = Color(1, 0, 0, 0.5)  # Vermelho
			"item":
				placeholder.color = Color(1, 1, 0, 0.5)  # Amarelo
			"scenery":
				placeholder.color = Color(0, 1, 0, 0.3)  # Verde
			"wall":
				placeholder.color = Color(0.5, 0.5, 0.5, 0.5)  # Cinza
			_:
				placeholder.color = Color(0, 0, 1, 0.3)  # Azul
		
		placeholder.z_index = (x + y) * 10
		objects_node.add_child(placeholder)

func _create_fallback_map():
	"""Cria mapa básico se não houver dados."""
	print("BaseMap: Criando mapa fallback com tiles coloridos")
	
	# Carregar algumas texturas de fallback
	var fallback_textures: Array[Texture2D] = []
	var fallback_paths = [
		"res://assets/sprites/tiles/arfl001.png",
		"res://assets/sprites/tiles/arfl002.png",
		"res://assets/sprites/tiles/arfl003.png",
		"res://assets/sprites/tiles/aft1000.png",
		"res://assets/sprites/tiles/aft1001.png",
	]
	
	for path in fallback_paths:
		var tex = load(path) as Texture2D
		if tex:
			fallback_textures.append(tex)
			print("BaseMap: Textura carregada: ", path)
	
	print("BaseMap: Texturas fallback carregadas: ", fallback_textures.size())
	
	# Criar grid de tiles ao redor do player
	var center_x = entering_x
	var center_y = entering_y
	var radius = 20
	
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x = center_x + dx
			var y = center_y + dy
			var screen_pos = _tile_to_screen(x, y)
			
			if fallback_textures.size() > 0:
				var sprite = Sprite2D.new()
				sprite.name = "Tile_%d_%d" % [x, y]
				sprite.position = screen_pos
				sprite.centered = true
				sprite.texture = fallback_textures[(abs(dx) + abs(dy)) % fallback_textures.size()]
				sprite.z_index = -10000 + (x + y) * 10
				ground.add_child(sprite)
			else:
				# Fallback com ColorRect se não houver texturas
				var rect = ColorRect.new()
				rect.name = "Tile_%d_%d" % [x, y]
				rect.size = Vector2(TILE_WIDTH, TILE_HEIGHT)
				rect.color = Color(0.4, 0.35, 0.3) if (x + y) % 2 == 0 else Color(0.35, 0.3, 0.25)
				rect.position = screen_pos - Vector2(TILE_WIDTH / 2, TILE_HEIGHT / 2)
				rect.z_index = -10000 + (x + y) * 10
				ground.add_child(rect)
	
	print("BaseMap: Fallback map criado com ", (radius * 2 + 1) * (radius * 2 + 1), " tiles")

func _setup_player():
	"""Configura player na posição de entrada."""
	if not player:
		print("BaseMap: Player não encontrado!")
		return
	
	player.add_to_group("player")
	
	# Usar posição de entrada do mapa
	var start_x = entering_x
	var start_y = entering_y
	
	# Se temos dados do mapa, usar posição de entrada
	if map_data.has("entering"):
		var entering = map_data.get("entering", {})
		var tile_num = int(entering.get("tile", 0))
		# No Fallout 2, o mapa é 100x100, então:
		start_x = tile_num % 100
		start_y = (tile_num / 100) % 100  # Garantir que fique dentro do mapa
		print("BaseMap: tile_num=", tile_num, " -> x=", start_x, " y=", start_y)
	
	var start_pos = _tile_to_screen(start_x, start_y)
	player.position = start_pos
	player.z_index = 1000
	
	print("BaseMap: Player posicionado em tile (", start_x, ", ", start_y, ") -> screen ", start_pos)
	
	# Configurar câmera
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0

func _input(event):
	if not is_ready:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos = get_global_mouse_position()
			if player and player.has_method("move_to"):
				player.move_to(world_pos)
