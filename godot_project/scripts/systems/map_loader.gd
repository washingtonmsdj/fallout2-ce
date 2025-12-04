extends Node

## MapLoader - Carrega e instancia mapas do Fallout 2
## Baseado no código original (src/map.cc)
## Implementa parser JSON, validação e instanciação de tiles/objetos/NPCs

signal map_loaded(map_name: String)
signal map_load_failed(map_name: String, error: String)
signal tile_created(tile_data: Dictionary)
signal object_spawned(object_data: Dictionary)
signal npc_spawned(npc_data: Dictionary)

# Referências
var renderer: Node = null
var map_system: Node = null

func _ready():
	renderer = get_node_or_null("/root/IsometricRenderer")
	map_system = get_node_or_null("/root/MapSystem")
	
	if not renderer:
		push_error("MapLoader: IsometricRenderer não encontrado!")

# === PARSER DE MAPAS JSON ===

func load_map_from_json(path: String) -> Dictionary:
	"""
	Carrega e parseia um mapa JSON
	Valida dados antes de retornar
	"""
	print("MapLoader: Carregando mapa de: ", path)
	
	if not ResourceLoader.exists(path):
		var error = "Arquivo não encontrado: " + path
		push_error("MapLoader: " + error)
		map_load_failed.emit(path.get_file().get_basename(), error)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		var error = "Erro ao abrir arquivo: " + path
		push_error("MapLoader: " + error)
		map_load_failed.emit(path.get_file().get_basename(), error)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		var error = "Erro ao parsear JSON: " + str(parse_error)
		push_error("MapLoader: " + error)
		map_load_failed.emit(path.get_file().get_basename(), error)
		return {}
	
	var map_data = json.data
	
	# Validar estrutura do mapa
	if not _validate_map_data(map_data):
		var error = "Dados do mapa inválidos"
		push_error("MapLoader: " + error)
		map_load_failed.emit(path.get_file().get_basename(), error)
		return {}
	
	print("MapLoader: Mapa parseado com sucesso")
	return map_data

func _validate_map_data(data: Dictionary) -> bool:
	"""
	Valida estrutura de dados do mapa
	Retorna true se válido
	"""
	# Campos obrigatórios
	if not data.has("name"):
		push_error("MapLoader: Campo 'name' obrigatório ausente")
		return false
	
	if not data.has("width") or not data.has("height"):
		push_error("MapLoader: Campos 'width' e 'height' obrigatórios")
		return false
	
	# Validar tipos
	if not (data.width is int and data.height is int):
		push_error("MapLoader: 'width' e 'height' devem ser inteiros")
		return false
	
	if data.width <= 0 or data.height <= 0:
		push_error("MapLoader: 'width' e 'height' devem ser > 0")
		return false
	
	# Validar arrays opcionais
	if data.has("tiles") and not (data.tiles is Array):
		push_error("MapLoader: 'tiles' deve ser um Array")
		return false
	
	if data.has("objects") and not (data.objects is Array):
		push_error("MapLoader: 'objects' deve ser um Array")
		return false
	
	if data.has("npcs") and not (data.npcs is Array):
		push_error("MapLoader: 'npcs' deve ser um Array")
		return false
	
	# Validar tiles
	if data.has("tiles"):
		for tile in data.tiles:
			if not _validate_tile_data(tile):
				return false
	
	# Validar objetos
	if data.has("objects"):
		for obj in data.objects:
			if not _validate_object_data(obj):
				return false
	
	# Validar NPCs
	if data.has("npcs"):
		for npc in data.npcs:
			if not _validate_npc_data(npc):
				return false
	
	return true

func _validate_tile_data(tile: Dictionary) -> bool:
	"""Valida dados de um tile"""
	if not tile.has("x") or not tile.has("y"):
		push_error("MapLoader: Tile deve ter 'x' e 'y'")
		return false
	
	if not (tile.x is int and tile.y is int):
		push_error("MapLoader: Tile 'x' e 'y' devem ser inteiros")
		return false
	
	return true

func _validate_object_data(obj: Dictionary) -> bool:
	"""Valida dados de um objeto"""
	if not obj.has("x") or not obj.has("y"):
		push_error("MapLoader: Objeto deve ter 'x' e 'y'")
		return false
	
	if not obj.has("prototype_id"):
		push_error("MapLoader: Objeto deve ter 'prototype_id'")
		return false
	
	return true

func _validate_npc_data(npc: Dictionary) -> bool:
	"""Valida dados de um NPC"""
	if not npc.has("x") or not npc.has("y"):
		push_error("MapLoader: NPC deve ter 'x' e 'y'")
		return false
	
	if not npc.has("prototype_id"):
		push_error("MapLoader: NPC deve ter 'prototype_id'")
		return false
	
	return true

# === INSTANCIAÇÃO DE TILES ===

func instantiate_tiles(tiles_data: Array, parent: Node2D, elevation: int = 0) -> Array[Node2D]:
	"""
	Instancia tiles usando IsometricRenderer
	Cria TileMapLayer para cada elevação
	"""
	if not renderer:
		push_error("MapLoader: IsometricRenderer não disponível")
		return []
	
	var created_tiles: Array[Node2D] = []
	
	for tile_data in tiles_data:
		var tile_elevation = tile_data.get("elevation", 0)
		
		# Apenas instanciar tiles da elevação atual
		if tile_elevation != elevation:
			continue
		
		var tile_node = _create_tile_node(tile_data, elevation)
		if tile_node:
			parent.add_child(tile_node)
			created_tiles.append(tile_node)
			tile_created.emit(tile_data)
	
	print("MapLoader: ", created_tiles.size(), " tiles instanciados na elevação ", elevation)
	return created_tiles

func _create_tile_node(tile_data: Dictionary, elevation: int) -> Node2D:
	"""Cria um node de tile"""
	var tile_pos = Vector2i(tile_data.get("x", 0), tile_data.get("y", 0))
	
	# Converter para posição de tela usando IsometricRenderer
	var screen_pos = renderer.tile_to_screen(tile_pos, elevation)
	
	# Criar node
	var tile_node = Node2D.new()
	tile_node.name = "Tile_%d_%d" % [tile_pos.x, tile_pos.y]
	tile_node.position = screen_pos
	tile_node.set_meta("tile_pos", tile_pos)
	tile_node.set_meta("elevation", elevation)
	
	# Adicionar sprite se houver textura
	var texture_path = tile_data.get("texture", "")
	if texture_path != "":
		var sprite = Sprite2D.new()
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.name = "Sprite"
			tile_node.add_child(sprite)
	
	return tile_node

# === SPAWN DE OBJETOS E NPCs ===

func spawn_objects(objects_data: Array, parent: Node2D, elevation: int = 0) -> Array[Node2D]:
	"""
	Instancia objetos interagíveis
	Usa protótipos para criar instâncias
	"""
	if not renderer:
		push_error("MapLoader: IsometricRenderer não disponível")
		return []
	
	var spawned_objects: Array[Node2D] = []
	var prototype_system = get_node_or_null("/root/PrototypeSystem")
	
	for obj_data in objects_data:
		var obj_elevation = obj_data.get("elevation", 0)
		
		# Apenas spawnar objetos da elevação atual
		if obj_elevation != elevation:
			continue
		
		var obj_node = _create_object_node(obj_data, prototype_system, elevation)
		if obj_node:
			parent.add_child(obj_node)
			spawned_objects.append(obj_node)
			object_spawned.emit(obj_data)
	
	print("MapLoader: ", spawned_objects.size(), " objetos spawnados na elevação ", elevation)
	return spawned_objects

func spawn_npcs(npcs_data: Array, parent: Node2D, elevation: int = 0) -> Array[Node2D]:
	"""
	Spawna NPCs com protótipos
	Carrega stats e comportamento do protótipo
	"""
	if not renderer:
		push_error("MapLoader: IsometricRenderer não disponível")
		return []
	
	var spawned_npcs: Array[Node2D] = []
	var prototype_system = get_node_or_null("/root/PrototypeSystem")
	
	for npc_data in npcs_data:
		var npc_elevation = npc_data.get("elevation", 0)
		
		# Apenas spawnar NPCs da elevação atual
		if npc_elevation != elevation:
			continue
		
		var npc_node = _create_npc_node(npc_data, prototype_system, elevation)
		if npc_node:
			parent.add_child(npc_node)
			spawned_npcs.append(npc_node)
			npc_spawned.emit(npc_data)
	
	print("MapLoader: ", spawned_npcs.size(), " NPCs spawnados na elevação ", elevation)
	return spawned_npcs

func _create_object_node(obj_data: Dictionary, prototype_system: Node, elevation: int) -> Node2D:
	"""Cria um node de objeto interagível"""
	var obj_pos = Vector2i(obj_data.get("x", 0), obj_data.get("y", 0))
	var screen_pos = renderer.tile_to_screen(obj_pos, elevation)
	
	# Criar node base
	var obj_node = Node2D.new()
	obj_node.name = "Object_" + obj_data.get("id", "unknown")
	obj_node.position = screen_pos
	obj_node.set_meta("tile_pos", obj_pos)
	obj_node.set_meta("elevation", elevation)
	obj_node.set_meta("object_data", obj_data)
	
	# Carregar protótipo se disponível
	var prototype_id = obj_data.get("prototype_id", "")
	if prototype_system and prototype_id != "":
		var prototype = prototype_system.get_item_prototype(prototype_id)
		if not prototype.is_empty():
			obj_node.set_meta("prototype", prototype)
	
	# Adicionar sprite
	var texture_path = obj_data.get("texture", "")
	if texture_path == "" and prototype_system:
		# Tentar obter do protótipo
		var prototype = obj_node.get_meta("prototype", {})
		texture_path = prototype.get("sprite", "")
	
	if texture_path != "":
		var sprite = Sprite2D.new()
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.name = "Sprite"
			obj_node.add_child(sprite)
	
	return obj_node

func _create_npc_node(npc_data: Dictionary, prototype_system: Node, elevation: int) -> Node2D:
	"""Cria um node de NPC"""
	var npc_pos = Vector2i(npc_data.get("x", 0), npc_data.get("y", 0))
	var screen_pos = renderer.tile_to_screen(npc_pos, elevation)
	
	# Criar node base
	var npc_node = Node2D.new()
	npc_node.name = "NPC_" + npc_data.get("id", "unknown")
	npc_node.position = screen_pos
	npc_node.set_meta("tile_pos", npc_pos)
	npc_node.set_meta("elevation", elevation)
	npc_node.set_meta("npc_data", npc_data)
	
	# Carregar protótipo se disponível
	var prototype_id = npc_data.get("prototype_id", "")
	if prototype_system and prototype_id != "":
		var prototype = prototype_system.get_critter_prototype(prototype_id)
		if not prototype.is_empty():
			npc_node.set_meta("prototype", prototype)
			# Aplicar stats do protótipo
			_apply_npc_prototype(npc_node, prototype)
	
	# Adicionar sprite
	var texture_path = npc_data.get("texture", "")
	if texture_path == "" and prototype_system:
		var prototype = npc_node.get_meta("prototype", {})
		texture_path = prototype.get("sprite", "")
	
	if texture_path != "":
		var sprite = Sprite2D.new()
		var texture = load(texture_path)
		if texture:
			sprite.texture = texture
			sprite.name = "Sprite"
			npc_node.add_child(sprite)
	
	return npc_node

func _apply_npc_prototype(npc_node: Node2D, prototype: Dictionary):
	"""Aplica stats e comportamento do protótipo ao NPC"""
	# Armazenar stats do protótipo
	npc_node.set_meta("hp", prototype.get("hp", 50))
	npc_node.set_meta("max_hp", prototype.get("max_hp", 50))
	npc_node.set_meta("strength", prototype.get("strength", 5))
	npc_node.set_meta("perception", prototype.get("perception", 5))
	# ... outros stats conforme necessário

# === PERSISTÊNCIA DE ESTADO DO MAPA ===

func save_map_state(map_name: String, map_nodes: Dictionary = {}) -> Dictionary:
	"""
	Salva estado modificado do mapa
	Captura mudanças em objetos, NPCs, etc.
	"""
	var state = {
		"map_name": map_name,
		"timestamp": Time.get_unix_time_from_system(),
		"objects": [],
		"npcs": [],
		"tiles": []
	}
	
	# Salvar estado de objetos modificados
	if map_nodes.has("objects"):
		for obj_node in map_nodes.objects:
			if obj_node.has_meta("modified"):
				var obj_state = _serialize_object_state(obj_node)
				state.objects.append(obj_state)
	
	# Salvar estado de NPCs modificados
	if map_nodes.has("npcs"):
		for npc_node in map_nodes.npcs:
			if npc_node.has_meta("modified"):
				var npc_state = _serialize_npc_state(npc_node)
				state.npcs.append(npc_state)
	
	# Salvar estado de tiles modificados (se houver)
	if map_nodes.has("tiles"):
		for tile_node in map_nodes.tiles:
			if tile_node.has_meta("modified"):
				var tile_state = _serialize_tile_state(tile_node)
				state.tiles.append(tile_state)
	
	return state

func restore_map_state(map_data: Dictionary, saved_state: Dictionary) -> Dictionary:
	"""
	Restaura estado do mapa a partir de save
	Modifica map_data com estado salvo
	"""
	if saved_state.get("map_name", "") != map_data.get("name", ""):
		push_error("MapLoader: Nome do mapa não corresponde")
		return map_data
	
	# Restaurar objetos
	if saved_state.has("objects"):
		for obj_state in saved_state.objects:
			_restore_object_state(map_data, obj_state)
	
	# Restaurar NPCs
	if saved_state.has("npcs"):
		for npc_state in saved_state.npcs:
			_restore_npc_state(map_data, npc_state)
	
	# Restaurar tiles
	if saved_state.has("tiles"):
		for tile_state in saved_state.tiles:
			_restore_tile_state(map_data, tile_state)
	
	return map_data

func _serialize_object_state(obj_node: Node2D) -> Dictionary:
	"""Serializa estado de um objeto"""
	var obj_data = obj_node.get_meta("object_data", {})
	return {
		"id": obj_data.get("id", ""),
		"x": obj_data.get("x", 0),
		"y": obj_data.get("y", 0),
		"elevation": obj_data.get("elevation", 0),
		"modified": obj_node.get_meta("modified", false),
		"custom_data": obj_node.get_meta("custom_data", {})
	}

func _serialize_npc_state(npc_node: Node2D) -> Dictionary:
	"""Serializa estado de um NPC"""
	var npc_data = npc_node.get_meta("npc_data", {})
	return {
		"id": npc_data.get("id", ""),
		"x": npc_data.get("x", 0),
		"y": npc_data.get("y", 0),
		"elevation": npc_data.get("elevation", 0),
		"hp": npc_node.get_meta("hp", 50),
		"modified": npc_node.get_meta("modified", false),
		"custom_data": npc_node.get_meta("custom_data", {})
	}

func _serialize_tile_state(tile_node: Node2D) -> Dictionary:
	"""Serializa estado de um tile"""
	var tile_pos = tile_node.get_meta("tile_pos", Vector2i(0, 0))
	return {
		"x": tile_pos.x,
		"y": tile_pos.y,
		"elevation": tile_node.get_meta("elevation", 0),
		"modified": tile_node.get_meta("modified", false),
		"custom_data": tile_node.get_meta("custom_data", {})
	}

func _restore_object_state(map_data: Dictionary, obj_state: Dictionary):
	"""Restaura estado de um objeto no map_data"""
	if not map_data.has("objects"):
		map_data["objects"] = []
	
	for obj in map_data.objects:
		if obj.get("id") == obj_state.get("id"):
			# Aplicar modificações
			obj.merge(obj_state.get("custom_data", {}))
			break

func _restore_npc_state(map_data: Dictionary, npc_state: Dictionary):
	"""Restaura estado de um NPC no map_data"""
	if not map_data.has("npcs"):
		map_data["npcs"] = []
	
	for npc in map_data.npcs:
		if npc.get("id") == npc_state.get("id"):
			# Aplicar modificações
			npc["hp"] = npc_state.get("hp", 50)
			npc.merge(npc_state.get("custom_data", {}))
			break

func _restore_tile_state(map_data: Dictionary, tile_state: Dictionary):
	"""Restaura estado de um tile no map_data"""
	if not map_data.has("tiles"):
		map_data["tiles"] = []
	
	for tile in map_data.tiles:
		if tile.get("x") == tile_state.get("x") and tile.get("y") == tile_state.get("y"):
			# Aplicar modificações
			tile.merge(tile_state.get("custom_data", {}))
			break

# === TRANSIÇÕES DE MAPA ===

func detect_exit_area(position: Vector2, map_data: Dictionary) -> Dictionary:
	"""
	Detecta se posição está em uma área de saída
	Retorna dados da saída se encontrada
	"""
	if not renderer:
		return {}
	
	var exits = map_data.get("exits", [])
	
	for exit in exits:
		var exit_tile = Vector2i(exit.get("x", 0), exit.get("y", 0))
		var exit_screen_pos = renderer.tile_to_screen(exit_tile, exit.get("elevation", 0))
		
		# Verificar se posição está próxima da saída (dentro de um raio)
		var distance = position.distance_to(exit_screen_pos)
		var threshold = 50.0  # Pixels
		
		if distance <= threshold:
			return exit
	
	return {}

func transition_to_map(current_map_data: Dictionary, exit_data: Dictionary, new_map_path: String, parent: Node2D) -> Dictionary:
	"""
	Realiza transição para novo mapa
	Detecta área de saída, salva estado atual, carrega novo mapa na entrada correta
	"""
	# Salvar estado do mapa atual antes de descarregar
	var current_map_nodes = {
		"objects": _get_all_object_nodes(parent),
		"npcs": _get_all_npc_nodes(parent),
		"tiles": _get_all_tile_nodes(parent)
	}
	
	var saved_state = save_map_state(current_map_data.get("name", ""), current_map_nodes)
	
	# Carregar novo mapa
	var new_map_data = load_map_from_json(new_map_path)
	if new_map_data.is_empty():
		push_error("MapLoader: Falha ao carregar novo mapa: " + new_map_path)
		return {}
	
	# Determinar entrada correta no novo mapa
	var target_entrance_id = exit_data.get("target_entrance", 0)
	var entrance_data = _find_entrance(new_map_data, target_entrance_id)
	
	# Limpar mapa atual
	_clear_map_nodes(parent)
	
	# Carregar novo mapa na elevação correta
	var elevation = entrance_data.get("elevation", 0)
	var new_map_nodes = load_and_instantiate_map(new_map_path, parent, elevation)
	
	# Posicionar player na entrada
	var entrance_tile = Vector2i(entrance_data.get("x", 0), entrance_data.get("y", 0))
	var entrance_screen_pos = renderer.tile_to_screen(entrance_tile, elevation)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player:
		gm.player.global_position = entrance_screen_pos
	
	# Atualizar MapSystem
	if map_system:
		map_system.current_map_name = new_map_data.get("name", "")
		map_system.current_map_data = new_map_data
		map_system.set_elevation(elevation)
	
	print("MapLoader: Transição concluída para ", new_map_data.get("name", ""))
	return new_map_nodes

func _find_entrance(map_data: Dictionary, entrance_id: int) -> Dictionary:
	"""Encontra dados de entrada no mapa"""
	var entrances = map_data.get("entrances", [])
	
	for entrance in entrances:
		if entrance.get("id", 0) == entrance_id:
			return entrance
	
	# Retornar primeira entrada se não encontrar
	if entrances.size() > 0:
		return entrances[0]
	
	# Entrada padrão
	return {
		"id": 0,
		"x": map_data.get("width", 100) / 2,
		"y": map_data.get("height", 100) / 2,
		"elevation": 0
	}

func _get_all_object_nodes(parent: Node2D) -> Array:
	"""Obtém todos os nodes de objetos"""
	var objects = []
	for child in parent.get_children():
		if child.name.begins_with("Object_"):
			objects.append(child)
	return objects

func _get_all_npc_nodes(parent: Node2D) -> Array:
	"""Obtém todos os nodes de NPCs"""
	var npcs = []
	for child in parent.get_children():
		if child.name.begins_with("NPC_"):
			npcs.append(child)
	return npcs

func _get_all_tile_nodes(parent: Node2D) -> Array:
	"""Obtém todos os nodes de tiles"""
	var tiles = []
	for child in parent.get_children():
		if child.name.begins_with("Tile_"):
			tiles.append(child)
	return tiles

func _clear_map_nodes(parent: Node2D):
	"""Limpa todos os nodes do mapa"""
	for child in parent.get_children():
		if child.name.begins_with("Tile_") or child.name.begins_with("Object_") or child.name.begins_with("NPC_"):
			child.queue_free()

# === CARREGAMENTO COMPLETO ===

func load_and_instantiate_map(path: String, parent: Node2D, elevation: int = 0) -> Dictionary:
	"""
	Carrega mapa completo e instancia tudo
	Retorna dicionário com nodes criados
	"""
	var map_data = load_map_from_json(path)
	if map_data.is_empty():
		return {}
	
	var result = {
		"tiles": [],
		"objects": [],
		"npcs": []
	}
	
	# Instanciar tiles
	if map_data.has("tiles"):
		result.tiles = instantiate_tiles(map_data.tiles, parent, elevation)
	
	# Spawnar objetos
	if map_data.has("objects"):
		result.objects = spawn_objects(map_data.objects, parent, elevation)
	
	# Spawnar NPCs
	if map_data.has("npcs"):
		result.npcs = spawn_npcs(map_data.npcs, parent, elevation)
	
	map_loaded.emit(map_data.get("name", "unknown"))
	return result

