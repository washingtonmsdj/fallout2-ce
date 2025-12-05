extends Node2D

## Temple of Trials - Primeiro mapa do Fallout 2
## Placeholder temporário - será substituído pelo mapa real convertido

@onready var world: Node2D = $World
@onready var ground: Node2D = $World/Ground
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

var iso_renderer: Node = null
var is_ready: bool = false

# Constantes do mapa
const MAP_WIDTH = 30
const MAP_HEIGHT = 30
const TILE_WIDTH = 80
const TILE_HEIGHT = 36

func _ready():
	print("TempleOfTrials: Inicializando primeiro mapa...")
	
	# Obter renderer isométrico
	iso_renderer = get_node_or_null("/root/IsometricRenderer")
	if not iso_renderer:
		push_warning("TempleOfTrials: IsometricRenderer não encontrado!")
	
	# Aguardar um frame
	await get_tree().process_frame
	
	# Criar mapa com estrutura mais completa
	_create_temple_map()
	
	# Configurar player
	_setup_player()
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_map = self
		gm.current_map_name = "Temple of Trials"
		gm.change_state(gm.GameState.EXPLORATION)
	
	# Atualizar HUD com localização
	_update_hud_location()
	
	is_ready = true
	print("TempleOfTrials: Pronto! Use WASD ou click para mover.")

func _update_hud_location():
	"""Atualiza o nome da localização no HUD"""
	await get_tree().process_frame
	
	# Encontrar o HUD
	var hud_node = get_node_or_null("HUD/FalloutHUD")
	if hud_node and hud_node.has_method("set_location"):
		hud_node.set_location("Temple of Trials")
	else:
		# Tentar encontrar label diretamente
		var location_label = get_node_or_null("HUD/FalloutHUD/LocationLabel")
		if location_label:
			location_label.text = "TEMPLE OF TRIALS"

func _setup_player():
	"""Configura o player na posição inicial"""
	if not player:
		return
	
	player.add_to_group("player")
	
	# Posicionar player na entrada do templo (tile 15, 25)
	var start_tile = Vector2i(15, 25)
	if iso_renderer:
		player.position = world.position + iso_renderer.tile_to_screen(start_tile, 0)
	else:
		player.position = Vector2(512, 600)
	
	# Z-index alto para ficar acima dos tiles
	player.z_index = 1000
	
	print("TempleOfTrials: Player posicionado em ", player.position)
	
	# Configurar câmera
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.make_current()
		camera.limit_left = -1500
		camera.limit_top = -1500
		camera.limit_right = 2500
		camera.limit_bottom = 2500
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0

func _create_temple_map():
	"""Cria o mapa do Temple of Trials com estrutura básica"""
	if not iso_renderer:
		_create_fallback_map()
		return
	
	print("TempleOfTrials: Criando mapa do templo...")
	
	var tile_textures = _load_tile_textures()
	var wall_textures = _load_wall_textures()
	
	if tile_textures.is_empty():
		print("TempleOfTrials: Nenhuma textura encontrada, usando fallback")
		_create_fallback_map()
		return
	
	# Criar layout do templo (simplificado)
	# 0 = vazio, 1 = chão, 2 = parede
	var layout = _generate_temple_layout()
	
	# Criar tiles baseado no layout
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile_type = layout[y][x]
			if tile_type == 0:
				continue  # Vazio
			
			var tile_pos = Vector2i(x, y)
			var screen_pos = iso_renderer.tile_to_screen(tile_pos, 0)
			
			var sprite = Sprite2D.new()
			sprite.name = "Tile_%d_%d" % [x, y]
			sprite.position = screen_pos
			sprite.centered = true
			
			if tile_type == 1:  # Chão
				var tex_idx = (x + y) % tile_textures.size()
				sprite.texture = tile_textures[tex_idx]
			elif tile_type == 2 and wall_textures.size() > 0:  # Parede
				sprite.texture = wall_textures[0]
			else:
				sprite.texture = tile_textures[0]
			
			# Z-index para ordenação
			sprite.z_index = -10000 + (x + y) * 10
			
			ground.add_child(sprite)
	
	print("TempleOfTrials: Mapa criado com layout de templo")

func _generate_temple_layout() -> Array:
	"""Gera layout simplificado do Temple of Trials"""
	var layout = []
	
	for y in range(MAP_HEIGHT):
		var row = []
		for x in range(MAP_WIDTH):
			# Criar área retangular do templo
			var in_temple = (x >= 5 and x < 25 and y >= 5 and y < 28)
			
			if not in_temple:
				row.append(0)  # Vazio fora do templo
			elif x == 5 or x == 24:  # Paredes laterais
				row.append(2)
			elif y == 5:  # Parede norte
				row.append(2)
			elif y == 27 and (x < 13 or x > 17):  # Parede sul com entrada
				row.append(2)
			else:
				row.append(1)  # Chão
		layout.append(row)
	
	# Adicionar corredores internos
	for y in range(10, 23):
		if y % 4 == 0:
			for x in range(8, 22):
				if x == 8 or x == 21:
					layout[y][x] = 2  # Pilares
	
	return layout

func _create_fallback_map():
	"""Cria mapa simples como fallback"""
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var rect = ColorRect.new()
			rect.name = "Tile_%d_%d" % [x, y]
			
			if iso_renderer:
				var screen_pos = iso_renderer.tile_to_screen(Vector2i(x, y), 0)
				rect.position = screen_pos - Vector2(40, 18)
			else:
				rect.position = Vector2(x * 40, y * 20)
			
			rect.size = Vector2(80, 36)
			rect.color = Color(0.3, 0.25, 0.2) if (x + y) % 2 == 0 else Color(0.25, 0.2, 0.15)
			rect.z_index = -10000 + (x + y) * 10
			
			ground.add_child(rect)

func _load_tile_textures() -> Array[Texture2D]:
	"""Carrega texturas de tiles de chão"""
	var textures: Array[Texture2D] = []
	
	# Tiles de chão do templo/arroyo
	var tile_paths = [
		"res://assets/sprites/tiles/aft1000.png",  # Temple floor
		"res://assets/sprites/tiles/aft1001.png",
		"res://assets/sprites/tiles/aft1002.png",
		"res://assets/sprites/tiles/arfl001.png",  # Arroyo floor
		"res://assets/sprites/tiles/arfl002.png",
		"res://assets/sprites/tiles/arfl003.png",
	]
	
	for path in tile_paths:
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				textures.append(texture)
	
	# Se não encontrou nenhum, tentar qualquer tile
	if textures.is_empty():
		var dir = DirAccess.open("res://assets/sprites/tiles/")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			var count = 0
			while file_name != "" and count < 5:
				if file_name.ends_with(".png") and not file_name.ends_with(".import"):
					var tex = load("res://assets/sprites/tiles/" + file_name)
					if tex:
						textures.append(tex)
						count += 1
				file_name = dir.get_next()
	
	return textures

func _load_wall_textures() -> Array[Texture2D]:
	"""Carrega texturas de paredes"""
	var textures: Array[Texture2D] = []
	
	# Tiles de parede/roof
	var wall_paths = [
		"res://assets/sprites/tiles/arrf001.png",
		"res://assets/sprites/tiles/arrf002.png",
		"res://assets/sprites/tiles/adb001.png",
	]
	
	for path in wall_paths:
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				textures.append(texture)
	
	return textures

func _input(event):
	"""Processa input do mapa"""
	if not is_ready:
		return
	
	# Click para mover
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)

func _handle_left_click(screen_pos: Vector2):
	"""Processa click esquerdo"""
	var gm = get_node_or_null("/root/GameManager")
	if gm and not gm.is_playing():
		return
	
	# Converter para posição do mundo
	var world_pos = get_global_mouse_position()
	
	# Mover player
	if player and player.has_method("move_to"):
		player.move_to(world_pos)
