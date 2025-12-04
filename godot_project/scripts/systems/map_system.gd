extends Node

## Sistema de Mapas do Fallout 2
## Baseado no codigo original (src/map.cc)
## Gerencia carregamento, transicoes e dados de mapas

signal map_loading(map_name: String)
signal map_loaded(map_name: String)
signal map_unloaded(map_name: String)
signal elevation_changed(new_elevation: int)

# Constantes do original
const MAX_ELEVATION = 3
const TILE_WIDTH = 80
const TILE_HEIGHT = 36

# Estado atual
var current_map_name: String = ""
var current_map_data: Dictionary = {}
var current_elevation: int = 0
var loaded_maps: Dictionary = {}

# Dados de transicao
var pending_transition: Dictionary = {}

func _ready():
	pass

# === CARREGAMENTO DE MAPAS ===

func load_map(map_name: String, entrance_id: int = 0) -> bool:
	"""Carrega um mapa"""
	print("MapSystem: Carregando mapa: ", map_name)
	map_loading.emit(map_name)
	
	# Verificar se mapa ja esta carregado
	if loaded_maps.has(map_name):
		current_map_data = loaded_maps[map_name]
		current_map_name = map_name
		_apply_entrance(entrance_id)
		map_loaded.emit(map_name)
		return true
	
	# Tentar carregar dados do mapa
	var map_data = _load_map_data(map_name)
	if map_data.is_empty():
		push_error("MapSystem: Falha ao carregar mapa: " + map_name)
		return false
	
	# Armazenar dados
	loaded_maps[map_name] = map_data
	current_map_data = map_data
	current_map_name = map_name
	
	# Aplicar entrada
	_apply_entrance(entrance_id)
	
	map_loaded.emit(map_name)
	return true

func unload_map(map_name: String = ""):
	"""Descarrega um mapa"""
	if map_name.is_empty():
		map_name = current_map_name
	
	if loaded_maps.has(map_name):
		loaded_maps.erase(map_name)
		map_unloaded.emit(map_name)
	
	if map_name == current_map_name:
		current_map_name = ""
		current_map_data = {}

func _load_map_data(map_name: String) -> Dictionary:
	"""Carrega dados de um mapa"""
	# Tentar carregar de arquivo JSON
	var json_path = "res://assets/data/maps/" + map_name + ".json"
	if ResourceLoader.exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				return json.data
	
	# Retornar dados padrao para teste
	return _create_default_map_data(map_name)

func _create_default_map_data(map_name: String) -> Dictionary:
	"""Cria dados padrao para um mapa"""
	return {
		"name": map_name,
		"width": 100,
		"height": 100,
		"elevations": 1,
		"entrances": [
			{"id": 0, "x": 50, "y": 50, "elevation": 0}
		],
		"exits": [],
		"tiles": [],
		"objects": [],
		"scripts": []
	}

func _apply_entrance(entrance_id: int):
	"""Aplica posicao de entrada"""
	var entrances = current_map_data.get("entrances", [])
	
	for entrance in entrances:
		if entrance.get("id", 0) == entrance_id:
			# Mover player para entrada
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.player:
				var pos = Vector2(
					entrance.get("x", 50) * TILE_WIDTH,
					entrance.get("y", 50) * TILE_HEIGHT
				)
				gm.player.global_position = pos
			
			# Definir elevacao
			set_elevation(entrance.get("elevation", 0))
			return
	
	# Entrada padrao
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.player:
		gm.player.global_position = Vector2(400, 300)

# === ELEVACAO ===

func set_elevation(elevation: int):
	"""Define elevacao atual"""
	if elevation < 0 or elevation >= MAX_ELEVATION:
		return
	
	if elevation != current_elevation:
		current_elevation = elevation
		elevation_changed.emit(elevation)

func get_elevation() -> int:
	"""Retorna elevacao atual"""
	return current_elevation

# === TRANSICOES ===

func transition_to(map_name: String, entrance_id: int = 0):
	"""Inicia transicao para outro mapa"""
	pending_transition = {
		"map": map_name,
		"entrance": entrance_id
	}
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.load_map(map_name, entrance_id)

func check_exit(position: Vector2) -> Dictionary:
	"""Verifica se posicao e uma saida"""
	var exits = current_map_data.get("exits", [])
	
	for exit in exits:
		var exit_pos = Vector2(
			exit.get("x", 0) * TILE_WIDTH,
			exit.get("y", 0) * TILE_HEIGHT
		)
		var exit_size = Vector2(
			exit.get("width", 1) * TILE_WIDTH,
			exit.get("height", 1) * TILE_HEIGHT
		)
		
		var rect = Rect2(exit_pos, exit_size)
		if rect.has_point(position):
			return exit
	
	return {}

# === TILES ===

func get_tile_at(x: int, y: int, elevation: int = -1) -> Dictionary:
	"""Retorna tile em uma posicao"""
	if elevation < 0:
		elevation = current_elevation
	
	var tiles = current_map_data.get("tiles", [])
	
	for tile in tiles:
		if tile.get("x") == x and tile.get("y") == y and tile.get("elevation", 0) == elevation:
			return tile
	
	return {}

func is_tile_walkable(x: int, y: int, elevation: int = -1) -> bool:
	"""Verifica se tile e caminhavel"""
	var tile = get_tile_at(x, y, elevation)
	return tile.get("walkable", true)

func is_tile_blocked(x: int, y: int, elevation: int = -1) -> bool:
	"""Verifica se tile esta bloqueado"""
	var tile = get_tile_at(x, y, elevation)
	return tile.get("blocked", false)

# === OBJETOS ===

func get_objects_at(x: int, y: int, elevation: int = -1) -> Array:
	"""Retorna objetos em uma posicao"""
	if elevation < 0:
		elevation = current_elevation
	
	var objects = current_map_data.get("objects", [])
	var result = []
	
	for obj in objects:
		if obj.get("x") == x and obj.get("y") == y and obj.get("elevation", 0) == elevation:
			result.append(obj)
	
	return result

func add_object(obj_data: Dictionary):
	"""Adiciona objeto ao mapa"""
	if not current_map_data.has("objects"):
		current_map_data["objects"] = []
	
	current_map_data["objects"].append(obj_data)

func remove_object(obj_id: String):
	"""Remove objeto do mapa"""
	var objects = current_map_data.get("objects", [])
	
	for i in range(objects.size()):
		if objects[i].get("id") == obj_id:
			objects.remove_at(i)
			return

# === SCRIPTS ===

func get_map_scripts() -> Array:
	"""Retorna scripts do mapa"""
	return current_map_data.get("scripts", [])

func trigger_script(script_id: String, event: String = ""):
	"""Dispara um script do mapa"""
	var scripts = get_map_scripts()
	
	for script in scripts:
		if script.get("id") == script_id:
			_execute_script(script, event)
			return

func _execute_script(_script: Dictionary, _event: String):
	"""Executa um script"""
	# TODO: Implementar interpretador de scripts
	pass

# === UTILIDADES ===

func get_map_info() -> Dictionary:
	"""Retorna informacoes do mapa atual"""
	return {
		"name": current_map_name,
		"width": current_map_data.get("width", 0),
		"height": current_map_data.get("height", 0),
		"elevation": current_elevation,
		"max_elevation": current_map_data.get("elevations", 1)
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
