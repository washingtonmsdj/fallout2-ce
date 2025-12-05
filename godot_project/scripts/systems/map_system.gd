extends Node

## Sistema de Mapas do Fallout 2
## Baseado no codigo original (src/map.cc)
## Gerencia carregamento, transicoes e dados de mapas

signal map_loading(map_name: String)
signal map_loaded(map_name: String)
signal map_unloaded(map_name: String)
signal elevation_changed(new_elevation: int)
signal map_exit_detected(exit_id: String, target_map: String)
signal elevation_transition_started(from_elevation: int, to_elevation: int)
signal elevation_transition_completed(new_elevation: int)

# Constantes do original
const MAX_ELEVATION = 3
const TILE_WIDTH = 80
const TILE_HEIGHT = 36
const ELEVATION_TRANSITION_DURATION = 0.3  # segundos

# Estado atual
var current_map_name: String = ""
var current_map_data: MapData = null
var current_elevation: int = 0
var loaded_maps: Dictionary = {}

# Dados de transicao
var pending_transition: Dictionary = {}
var is_transitioning: bool = false
var is_elevation_transitioning: bool = false
var elevation_transition_progress: float = 0.0
var elevation_transition_target: int = 0

# Referências a sistemas
var game_manager: Node = null
var isometric_renderer: Node = null

func _ready():
	game_manager = get_node_or_null("/root/GameManager")
	isometric_renderer = get_node_or_null("/root/IsometricRenderer")
	
	# Conectar sinais de elevação
	elevation_changed.connect(_on_elevation_changed)

# === CARREGAMENTO DE MAPAS ===

func load_map(map_name: String, entrance_id: int = 0) -> bool:
	"""Carrega um mapa com todos os tiles, objetos e NPCs"""
	print("MapSystem: Iniciando carregamento do mapa: ", map_name)
	map_loading.emit(map_name)
	
	# Descarregar mapa anterior
	if current_map_name != "":
		print("MapSystem: Descarregando mapa anterior: ", current_map_name)
		unload_map(current_map_name)
	
	# Verificar se mapa ja esta carregado em cache
	if loaded_maps.has(map_name):
		print("MapSystem: Mapa encontrado em cache: ", map_name)
		current_map_data = loaded_maps[map_name]
		current_map_name = map_name
		_apply_entrance(entrance_id)
		map_loaded.emit(map_name)
		return true
	
	# Tentar carregar dados do mapa
	print("MapSystem: Carregando dados do mapa...")
	var map_data = _load_map_data(map_name)
	if map_data == null:
		push_error("MapSystem: Falha ao carregar dados do mapa: " + map_name)
		return false
	
	print("MapSystem: Dados do mapa carregados: %dx%d, %d elevações" % [map_data.width, map_data.height, map_data.elevation_count])
	
	# Validar dados do mapa
	print("MapSystem: Validando dados do mapa...")
	var errors = map_data.validate()
	if not errors.is_empty():
		push_error("MapSystem: Erros ao validar mapa " + map_name + ": " + str(errors))
		return false
	
	print("MapSystem: Validação concluída com sucesso")
	
	# Carregar tiles de todas as elevações
	print("MapSystem: Carregando tiles...")
	if not _load_map_tiles(map_data):
		push_error("MapSystem: Falha ao carregar tiles do mapa: " + map_name)
		return false
	
	# Instanciar objetos do mapa
	print("MapSystem: Instanciando objetos (%d objetos)..." % map_data.objects.size())
	if not _instantiate_map_objects(map_data):
		push_error("MapSystem: Falha ao instanciar objetos do mapa: " + map_name)
		return false
	
	# Instanciar NPCs do mapa
	print("MapSystem: Instanciando NPCs (%d NPCs)..." % map_data.npcs.size())
	if not _instantiate_map_npcs(map_data):
		push_error("MapSystem: Falha ao instanciar NPCs do mapa: " + map_name)
		return false
	
	# Configurar conexões entre mapas
	print("MapSystem: Configurando conexões de mapa (%d saídas)..." % map_data.exits.size())
	_configure_map_connections(map_data)
	
	# Armazenar dados
	loaded_maps[map_name] = map_data
	current_map_data = map_data
	current_map_name = map_name
	
	# Aplicar entrada
	print("MapSystem: Aplicando entrada %d..." % entrance_id)
	_apply_entrance(entrance_id)
	
	print("MapSystem: Mapa carregado com sucesso: ", map_name)
	map_loaded.emit(map_name)
	return true

func unload_map(map_name: String = ""):
	"""Descarrega um mapa"""
	if map_name.is_empty():
		map_name = current_map_name
	
	# Limpar representação visual do mapa
	_clear_map_visuals()
	
	if loaded_maps.has(map_name):
		loaded_maps.erase(map_name)
		map_unloaded.emit(map_name)
	
	if map_name == current_map_name:
		current_map_name = ""
		current_map_data = null
		current_elevation = 0

func _clear_map_visuals():
	"""Limpa todos os elementos visuais do mapa"""
	var game_scene = get_tree().current_scene
	if game_scene == null:
		return
	
	var map_container = game_scene.get_node_or_null("MapContainer")
	if map_container:
		# Remover todos os filhos do container
		for child in map_container.get_children():
			child.queue_free()
		
		print("MapSystem: Elementos visuais do mapa limpos")

func _load_map_data(map_name: String) -> MapData:
	"""Carrega dados de um mapa"""
	# Tentar carregar de arquivo .tres (Godot Resource)
	var tres_path = "res://assets/data/maps/" + map_name + ".tres"
	if ResourceLoader.exists(tres_path):
		var map_data = load(tres_path) as MapData
		if map_data != null:
			return map_data
	
	# Tentar carregar de arquivo JSON
	var json_path = "res://assets/data/maps/" + map_name + ".json"
	if ResourceLoader.exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				return _create_map_from_json(map_name, json.data)
	
	# Retornar dados padrao para teste
	return _create_default_map_data(map_name)

func _create_default_map_data(map_name: String) -> MapData:
	"""Cria dados padrao para um mapa"""
	var map_data = MapData.new(map_name, map_name, 200, 200)
	
	# Criar saída padrão
	var exit = MapExit.new("exit_0", "arroyo", Vector2i(100, 100))
	exit.set_exit_zone(Rect2i(Vector2i(0, 0), Vector2i(200, 200)))
	map_data.exits.append(exit)
	
	return map_data


func _create_map_from_json(map_name: String, json_data: Dictionary) -> MapData:
	"""Cria MapData a partir de dados JSON"""
	var map_data = MapData.new(
		map_name,
		json_data.get("name", map_name),
		json_data.get("width", 200),
		json_data.get("height", 200)
	)
	
	# Carregar tiles
	var tiles_data = json_data.get("tiles", [])
	for tile_info in tiles_data:
		var pos = Vector2i(tile_info.get("x", 0), tile_info.get("y", 0))
		var elevation = tile_info.get("elevation", 0)
		var tile_id = tile_info.get("tile_id", 0)
		
		if map_data.is_valid_position(pos, elevation):
			map_data.set_tile(pos, elevation, tile_id)
	
	# Carregar objetos
	var objects_data = json_data.get("objects", [])
	for obj_info in objects_data:
		var obj = MapObject.new(
			obj_info.get("id", ""),
			obj_info.get("type", "scenery"),
			Vector2i(obj_info.get("x", 0), obj_info.get("y", 0)),
			obj_info.get("proto_id", 0)
		)
		obj.elevation = obj_info.get("elevation", 0)
		map_data.objects.append(obj)
	
	# Carregar NPCs
	var npcs_data = json_data.get("npcs", [])
	for npc_info in npcs_data:
		var npc = NPCSpawn.new(
			npc_info.get("npc_id", ""),
			npc_info.get("proto_id", 0),
			Vector2i(npc_info.get("x", 0), npc_info.get("y", 0))
		)
		npc.elevation = npc_info.get("elevation", 0)
		npc.ai_type = npc_info.get("ai_type", "default")
		map_data.npcs.append(npc)
	
	# Carregar itens
	var items_data = json_data.get("items", [])
	for item_info in items_data:
		var item = ItemSpawn.new(
			item_info.get("item_id", ""),
			item_info.get("proto_id", 0),
			Vector2i(item_info.get("x", 0), item_info.get("y", 0)),
			item_info.get("quantity", 1)
		)
		item.elevation = item_info.get("elevation", 0)
		map_data.items.append(item)
	
	# Carregar saídas
	var exits_data = json_data.get("exits", [])
	for exit_info in exits_data:
		var exit = MapExit.new(
			exit_info.get("exit_id", ""),
			exit_info.get("target_map", ""),
			Vector2i(exit_info.get("target_x", 0), exit_info.get("target_y", 0))
		)
		exit.target_elevation = exit_info.get("target_elevation", 0)
		exit.set_exit_zone(Rect2i(
			Vector2i(exit_info.get("zone_x", 0), exit_info.get("zone_y", 0)),
			Vector2i(exit_info.get("zone_width", 10), exit_info.get("zone_height", 10))
		))
		map_data.exits.append(exit)
	
	return map_data

func _load_map_tiles(map_data: MapData) -> bool:
	"""Carrega tiles de todas as elevações do mapa"""
	if map_data == null:
		return false
	
	# Validar que tiles foram carregados
	if map_data.floor_tiles.is_empty():
		push_warning("MapSystem: Nenhum tile carregado para mapa: " + map_data.name)
		# Criar tiles padrão se não existirem
		_create_default_tiles(map_data)
	
	# Verificar integridade dos tiles
	for elevation in range(map_data.elevation_count):
		if elevation >= map_data.floor_tiles.size():
			push_error("MapSystem: Elevação %d não tem dados de tiles" % elevation)
			return false
		
		var floor_layer = map_data.floor_tiles[elevation]
		if floor_layer.size() != map_data.height:
			push_error("MapSystem: Altura de tiles incorreta na elevação %d" % elevation)
			return false
		
		for row in floor_layer:
			if row.size() != map_data.width:
				push_error("MapSystem: Largura de tiles incorreta na elevação %d" % elevation)
				return false
	
	# Criar representação visual dos tiles
	_create_tile_visuals(map_data)
	
	print("MapSystem: Tiles carregados com sucesso - %d elevações, %dx%d tiles" % [map_data.elevation_count, map_data.width, map_data.height])
	return true

func _create_default_tiles(map_data: MapData):
	"""Cria tiles padrão para um mapa vazio"""
	map_data.floor_tiles.clear()
	map_data.roof_tiles.clear()
	
	for elevation in range(map_data.elevation_count):
		var floor_layer: Array[Array] = []
		var roof_layer: Array[Array] = []
		
		for y in range(map_data.height):
			var floor_row: Array[int] = []
			var roof_row: Array[int] = []
			
			for x in range(map_data.width):
				floor_row.append(1)  # Tile padrão
				roof_row.append(0)
			
			floor_layer.append(floor_row)
			roof_layer.append(roof_row)
		
		map_data.floor_tiles.append(floor_layer)
		map_data.roof_tiles.append(roof_layer)

func _create_tile_visuals(map_data: MapData):
	"""Cria representação visual dos tiles usando TileMap"""
	# Obter ou criar nó de mapa na cena
	var game_scene = get_tree().current_scene
	if game_scene == null:
		push_warning("MapSystem: Nenhuma cena ativa para criar tiles")
		return
	
	# Procurar por nó de mapa existente
	var map_container = game_scene.get_node_or_null("MapContainer")
	if map_container == null:
		# Criar container se não existir
		map_container = Node2D.new()
		map_container.name = "MapContainer"
		game_scene.add_child(map_container)
	
	# Limpar tiles anteriores
	for child in map_container.get_children():
		child.queue_free()
	
	# Criar TileMap para cada elevação
	for elevation in range(map_data.elevation_count):
		var tilemap = TileMap.new()
		tilemap.name = "TileMap_Elevation_%d" % elevation
		tilemap.z_index = elevation * 100  # Separar elevações visualmente
		map_container.add_child(tilemap)
		
		# Configurar tiles (simplificado - em produção usaria tileset real)
		# Por enquanto apenas marca que os tiles foram carregados
		tilemap.visible = (elevation == current_elevation)
	
	print("MapSystem: Representação visual de tiles criada para %d elevações" % map_data.elevation_count)

func _instantiate_map_objects(map_data: MapData) -> bool:
	"""Instancia objetos do mapa"""
	if map_data == null:
		return false
	
	var objects_count = 0
	var game_scene = get_tree().current_scene
	if game_scene == null:
		push_warning("MapSystem: Nenhuma cena ativa para instanciar objetos")
		return false
	
	# Obter ou criar container de objetos
	var objects_container = game_scene.get_node_or_null("MapContainer/ObjectsContainer")
	if objects_container == null:
		var map_container = game_scene.get_node_or_null("MapContainer")
		if map_container == null:
			map_container = Node2D.new()
			map_container.name = "MapContainer"
			game_scene.add_child(map_container)
		
		objects_container = Node2D.new()
		objects_container.name = "ObjectsContainer"
		map_container.add_child(objects_container)
	
	# Limpar objetos anteriores
	for child in objects_container.get_children():
		child.queue_free()
	
	for obj in map_data.objects:
		# Validar posição
		if not map_data.is_valid_position(obj.position, obj.elevation):
			push_warning("MapSystem: Objeto fora dos limites do mapa: " + obj.id)
			continue
		
		# Criar nó para o objeto
		var obj_node = _create_object_node(obj)
		if obj_node:
			objects_container.add_child(obj_node)
			objects_count += 1
	
	print("MapSystem: %d objetos instanciados" % objects_count)
	return true

func _create_object_node(obj: MapObject) -> Node2D:
	"""Cria nó visual para um objeto do mapa"""
	# Tentar carregar cena do objeto
	var scene_path = "res://godot_project/scenes/objects/%s.tscn" % obj.object_type
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			var instance = scene.instantiate()
			instance.position = tile_to_world(obj.position)
			instance.z_index = obj.elevation * 100 + obj.position.y
			return instance
	
	# Fallback: criar sprite simples
	var sprite = Sprite2D.new()
	sprite.name = obj.id
	sprite.position = tile_to_world(obj.position)
	sprite.z_index = obj.elevation * 100 + obj.position.y
	sprite.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Cinza para objetos sem sprite
	
	# Tentar carregar textura do objeto
	var texture_path = "res://godot_project/assets/sprites/objects/%s.png" % obj.proto_id
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	
	return sprite

func _instantiate_map_npcs(map_data: MapData) -> bool:
	"""Instancia NPCs do mapa"""
	if map_data == null:
		return false
	
	var npcs_count = 0
	var game_scene = get_tree().current_scene
	if game_scene == null:
		push_warning("MapSystem: Nenhuma cena ativa para instanciar NPCs")
		return false
	
	# Obter ou criar container de NPCs
	var npcs_container = game_scene.get_node_or_null("MapContainer/NPCsContainer")
	if npcs_container == null:
		var map_container = game_scene.get_node_or_null("MapContainer")
		if map_container == null:
			map_container = Node2D.new()
			map_container.name = "MapContainer"
			game_scene.add_child(map_container)
		
		npcs_container = Node2D.new()
		npcs_container.name = "NPCsContainer"
		map_container.add_child(npcs_container)
	
	# Limpar NPCs anteriores
	for child in npcs_container.get_children():
		child.queue_free()
	
	for npc_spawn in map_data.npcs:
		# Validar posição
		if not map_data.is_valid_position(npc_spawn.position, npc_spawn.elevation):
			push_warning("MapSystem: NPC fora dos limites do mapa: " + npc_spawn.npc_id)
			continue
		
		# Criar nó para o NPC
		var npc_node = _create_npc_node(npc_spawn)
		if npc_node:
			npcs_container.add_child(npc_node)
			npcs_count += 1
	
	print("MapSystem: %d NPCs instanciados" % npcs_count)
	return true

func _create_npc_node(npc_spawn: NPCSpawn) -> Node2D:
	"""Cria nó visual para um NPC"""
	# Tentar carregar cena do NPC
	var scene_path = "res://godot_project/scenes/characters/npc.tscn"
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		if scene:
			var instance = scene.instantiate()
			instance.position = tile_to_world(npc_spawn.position)
			instance.z_index = npc_spawn.elevation * 100 + npc_spawn.position.y
			
			# Configurar dados do NPC se o script tiver métodos apropriados
			if instance.has_method("set_npc_id"):
				instance.set_npc_id(npc_spawn.npc_id)
			if instance.has_method("set_proto_id"):
				instance.set_proto_id(npc_spawn.proto_id)
			if instance.has_method("set_ai_type"):
				instance.set_ai_type(npc_spawn.ai_type)
			
			return instance
	
	# Fallback: criar sprite simples
	var sprite = Sprite2D.new()
	sprite.name = npc_spawn.npc_id
	sprite.position = tile_to_world(npc_spawn.position)
	sprite.z_index = npc_spawn.elevation * 100 + npc_spawn.position.y
	sprite.modulate = Color(1.0, 0.5, 0.5, 1.0)  # Vermelho claro para NPCs sem sprite
	
	# Tentar carregar textura do NPC
	var texture_path = "res://godot_project/assets/sprites/characters/npc_%s.png" % npc_spawn.proto_id
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	
	return sprite

func _configure_map_connections(map_data: MapData):
	"""Configura conexões entre mapas"""
	if map_data == null:
		return
	
	for exit in map_data.exits:
		# Validar que mapa de destino existe
		var target_path = "res://assets/data/maps/" + exit.target_map + ".tres"
		if not ResourceLoader.exists(target_path):
			push_warning("MapSystem: Mapa de destino não encontrado: " + exit.target_map)
			continue
		
		print("MapSystem: Conexão configurada: %s -> %s" % [map_data.name, exit.target_map])

func _apply_entrance(entrance_id: int):
	"""Aplica posicao de entrada"""
	if current_map_data == null:
		return
	
	# Usar primeira saída como entrada padrão
	if current_map_data.exits.size() > 0:
		var exit = current_map_data.exits[0]
		if game_manager and game_manager.has_method("get_player"):
			var player = game_manager.get_player()
			if player:
				var world_pos = tile_to_world(exit.target_position)
				player.global_position = world_pos
		
		set_elevation(exit.target_elevation)
		return
	
	# Posição padrão
	if game_manager and game_manager.has_method("get_player"):
		var player = game_manager.get_player()
		if player:
			player.global_position = Vector2(400, 300)
	
	set_elevation(0)

# === ELEVACAO ===

func set_elevation(elevation: int, use_transition: bool = false):
	"""Define elevacao atual com transição opcional"""
	if elevation < 0 or elevation >= MAX_ELEVATION:
		return
	
	if elevation == current_elevation:
		return
	
	if use_transition and not is_elevation_transitioning:
		_start_elevation_transition(elevation)
	else:
		current_elevation = elevation
		elevation_changed.emit(elevation)

func get_elevation() -> int:
	"""Retorna elevacao atual"""
	return current_elevation

func _start_elevation_transition(target_elevation: int):
	"""Inicia transição suave entre elevações"""
	is_elevation_transitioning = true
	elevation_transition_target = target_elevation
	elevation_transition_progress = 0.0
	elevation_transition_started.emit(current_elevation, target_elevation)

func _update_elevation_transition(delta: float):
	"""Atualiza progresso da transição de elevação"""
	if not is_elevation_transitioning:
		return
	
	elevation_transition_progress += delta / ELEVATION_TRANSITION_DURATION
	
	if elevation_transition_progress >= 1.0:
		elevation_transition_progress = 1.0
		is_elevation_transitioning = false
		current_elevation = elevation_transition_target
		elevation_changed.emit(current_elevation)
		elevation_transition_completed.emit(current_elevation)
	
	# Notificar renderer sobre progresso
	if isometric_renderer:
		isometric_renderer.set_elevation_transition(elevation_transition_progress)

func _on_elevation_changed(new_elevation: int):
	"""Callback quando elevação muda"""
	# Atualizar visibilidade de objetos baseado em elevação
	_update_elevation_visibility(new_elevation)

func _update_elevation_visibility(elevation: int):
	"""Atualiza visibilidade de objetos para elevação específica"""
	if current_map_data == null:
		return
	
	# Ocultar objetos de outras elevações
	for obj in current_map_data.objects:
		if obj.elevation != elevation:
			# Marcar como oculto (será tratado pelo renderer)
			pass

func _process(delta: float):
	"""Atualizar transições de elevação"""
	if is_elevation_transitioning:
		_update_elevation_transition(delta)

# === TRANSICOES ===

func transition_to(map_name: String, entrance_id: int = 0):
	"""Inicia transicao para outro mapa"""
	if is_transitioning:
		push_warning("MapSystem: Transição já em progresso")
		return
	
	is_transitioning = true
	pending_transition = {
		"map": map_name,
		"entrance": entrance_id
	}
	
	# Notificar GameManager para carregar novo mapa
	if game_manager:
		game_manager.load_map(map_name, entrance_id)
	else:
		# Fallback: carregar diretamente
		load_map(map_name, entrance_id)
	
	is_transitioning = false

func check_exit(position: Vector2) -> MapExit:
	"""Verifica se posição está em uma saída de mapa"""
	if current_map_data == null:
		return null
	
	var tile_pos = world_to_tile(position)
	return check_exit_at_tile(tile_pos)

func check_exit_at_tile(tile_pos: Vector2i) -> MapExit:
	"""Verifica se tile está em uma saída de mapa"""
	if current_map_data == null:
		return null
	
	for exit in current_map_data.exits:
		if exit.is_in_exit_zone(tile_pos):
			map_exit_detected.emit(exit.exit_id, exit.target_map)
			return exit
	
	return null

# === TILES ===

func get_tile_at(pos: Vector2i, elevation: int = -1) -> TileData:
	"""Retorna tile em uma posicao"""
	if current_map_data == null:
		return null
	
	if elevation < 0:
		elevation = current_elevation
	
	return current_map_data.get_tile(pos, elevation)

func is_tile_walkable(pos: Vector2i, elevation: int = -1) -> bool:
	"""Verifica se tile e caminhavel"""
	var tile = get_tile_at(pos, elevation)
	if tile == null:
		return false
	
	return tile.is_walkable()

func is_tile_blocked(pos: Vector2i, elevation: int = -1) -> bool:
	"""Verifica se tile esta bloqueado"""
	var tile = get_tile_at(pos, elevation)
	if tile == null:
		return true
	
	return not tile.is_walkable()

# === OBJETOS ===

func get_objects_at(pos: Vector2i, elevation: int = -1) -> Array:
	"""Retorna objetos em uma posicao"""
	if current_map_data == null:
		return []
	
	if elevation < 0:
		elevation = current_elevation
	
	var result: Array = []
	
	for obj in current_map_data.objects:
		if obj.position == pos and obj.elevation == elevation:
			result.append(obj)
	
	return result

func add_object(obj: MapObject):
	"""Adiciona objeto ao mapa"""
	if current_map_data == null:
		return
	
	current_map_data.objects.append(obj)

func remove_object(obj_id: String):
	"""Remove objeto do mapa"""
	if current_map_data == null:
		return
	
	for i in range(current_map_data.objects.size()):
		if current_map_data.objects[i].id == obj_id:
			current_map_data.objects.remove_at(i)
			return

# === SCRIPTS ===

func get_map_scripts() -> Array:
	"""Retorna scripts do mapa"""
	if current_map_data == null:
		return []
	
	return current_map_data.map_scripts

func trigger_script(script_id: String, event: String = ""):
	"""Dispara um script do mapa"""
	if current_map_data == null:
		return
	
	if script_id in current_map_data.map_scripts:
		_execute_script(script_id, event)

func _execute_script(script_id: String, _event: String):
	"""Executa um script"""
	# TODO: Implementar interpretador de scripts
	print("MapSystem: Executando script: ", script_id)

# === UTILIDADES ===

func get_map_info() -> Dictionary:
	"""Retorna informacoes do mapa atual"""
	if current_map_data == null:
		return {}
	
	return {
		"name": current_map_name,
		"width": current_map_data.width,
		"height": current_map_data.height,
		"elevation": current_elevation,
		"max_elevation": current_map_data.elevation_count,
		"objects_count": current_map_data.objects.size(),
		"npcs_count": current_map_data.npcs.size(),
		"items_count": current_map_data.items.size()
	}

func world_to_tile(world_pos: Vector2) -> Vector2i:
	"""Converte posicao do mundo para tile"""
	return Vector2i(
		int(world_pos.x / TILE_WIDTH),
		int(world_pos.y / TILE_HEIGHT)
	)

func tile_to_world(tile_pos: Vector2i) -> Vector2:
	"""Converte tile para posicao do mundo"""
	return Vector2(
		tile_pos.x * TILE_WIDTH + TILE_WIDTH / 2,
		tile_pos.y * TILE_HEIGHT + TILE_HEIGHT / 2
	)



func get_current_map() -> MapData:
	"""Retorna dados do mapa atual"""
	return current_map_data

func get_npcs_at(pos: Vector2i, elevation: int = -1) -> Array:
	"""Retorna NPCs em uma posição"""
	if current_map_data == null:
		return []
	
	if elevation < 0:
		elevation = current_elevation
	
	return current_map_data.get_npcs_at(pos)

func get_items_at(pos: Vector2i, elevation: int = -1) -> Array:
	"""Retorna itens em uma posição"""
	if current_map_data == null:
		return []
	
	if elevation < 0:
		elevation = current_elevation
	
	var result: Array = []
	
	for item in current_map_data.items:
		if item.position == pos and item.elevation == elevation:
			result.append(item)
	
	return result
