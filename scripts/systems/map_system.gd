extends Node
class_name MapSystem
## Sistema de gerenciamento de mapas

signal map_loaded(map_name: String)
signal tile_clicked(position: Vector2i)
signal object_interacted(object: MapObject)
signal critter_entered_map(critter: Critter)
signal critter_left_map(critter: Critter)

var current_map: MapData = null
var tilemap: TileMap = null
var objects: Dictionary = {}  # {String: MapObject}
var triggers: Array[TriggerZone] = []

func _ready() -> void:
	pass

## Carrega um mapa
func load_map(map_data: MapData) -> void:
	current_map = map_data
	
	if current_map == null:
		push_error("MapSystem.load_map: map_data is null")
		return
	
	# Inicializar o mapa se necessário
	if current_map.tiles.size() == 0:
		current_map.initialize()
	
	# Copiar objetos e gatilhos
	objects = current_map.objects.duplicate()
	triggers = current_map.triggers.duplicate()
	
	map_loaded.emit(current_map.map_name)

## Retorna o tile em uma posição
func get_tile_at(position: Vector2i) -> TileData:
	if current_map == null:
		return null
	
	return current_map.get_tile(position)

## Verifica se um tile é passável
func is_walkable(position: Vector2i) -> bool:
	if current_map == null:
		return false
	
	return current_map.is_walkable(position)

## Retorna objetos em uma posição
func get_objects_at(position: Vector2i) -> Array[MapObject]:
	var objects_at: Array[MapObject] = []
	
	if current_map == null:
		return objects_at
	
	var tile = current_map.get_tile(position)
	if tile == null or tile.object_id.is_empty():
		return objects_at
	
	if tile.object_id in current_map.objects:
		objects_at.append(current_map.objects[tile.object_id])
	
	return objects_at

## Retorna critters em uma posição
func get_critters_at(position: Vector2i) -> Array[Critter]:
	var critters_at: Array[Critter] = []
	
	if current_map == null:
		return critters_at
	
	var tile = current_map.get_tile(position)
	if tile == null or tile.critter_id.is_empty():
		return critters_at
	
	if tile.critter_id in current_map.critters:
		critters_at.append(current_map.critters[tile.critter_id])
	
	return critters_at

## Adiciona um objeto ao mapa
func add_object(obj_id: String, obj: MapObject, position: Vector2i) -> void:
	if current_map == null:
		return
	
	current_map.add_object(obj_id, obj, position)
	objects[obj_id] = obj

## Remove um objeto do mapa
func remove_object(obj_id: String) -> void:
	if current_map == null:
		return
	
	current_map.remove_object(obj_id)
	if obj_id in objects:
		objects.erase(obj_id)

## Adiciona um critter ao mapa
func add_critter(critter_id: String, critter: Critter, position: Vector2i) -> void:
	if current_map == null:
		return
	
	current_map.add_critter(critter_id, critter, position)
	critter_entered_map.emit(critter)

## Remove um critter do mapa
func remove_critter(critter_id: String) -> void:
	if current_map == null:
		return
	
	if critter_id in current_map.critters:
		var critter = current_map.critters[critter_id]
		current_map.remove_critter(critter_id)
		critter_left_map.emit(critter)

## Move um critter para uma nova posição
func move_critter(critter_id: String, new_position: Vector2i) -> bool:
	if current_map == null:
		return false
	
	if not current_map.is_valid_position(new_position):
		return false
	
	if not current_map.is_walkable(new_position):
		return false
	
	# Remover critter da posição antiga
	var tile = current_map.get_tile(new_position)
	if tile and tile.critter_id == critter_id:
		# Já está nessa posição
		return true
	
	# Encontrar posição antiga
	for pos in current_map.tiles:
		var t = current_map.tiles[pos]
		if t.critter_id == critter_id:
			t.critter_id = ""
			break
	
	# Adicionar critter na nova posição
	tile = current_map.get_tile(new_position)
	if tile:
		tile.critter_id = critter_id
	
	return true

## Retorna tiles passáveis
func get_walkable_tiles() -> Array[Vector2i]:
	if current_map == null:
		return []
	
	return current_map.get_walkable_tiles()

## Retorna vizinhos de um tile
func get_neighbors(position: Vector2i) -> Array[Vector2i]:
	if current_map == null:
		return []
	
	return current_map.get_neighbors(position)

## Retorna vizinhos passáveis
func get_walkable_neighbors(position: Vector2i) -> Array[Vector2i]:
	if current_map == null:
		return []
	
	return current_map.get_walkable_neighbors(position)

## Retorna tiles em um raio
func get_tiles_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	if current_map == null:
		return []
	
	return current_map.get_tiles_in_radius(center, radius)

## Retorna informações sobre o mapa atual
func get_current_map_info() -> Dictionary:
	if current_map == null:
		return {}
	
	return current_map.get_map_info()

## Interage com um objeto
func interact_with_object(obj_id: String, player: Critter) -> void:
	if obj_id not in objects:
		return
	
	var obj = objects[obj_id]
	obj.interact(player)
	object_interacted.emit(obj)

## Retorna a distância entre dois tiles
func get_distance(from: Vector2i, to: Vector2i) -> float:
	if current_map == null:
		return 0.0
	
	return current_map.get_distance(from, to)

## Verifica se uma posição é válida
func is_valid_position(position: Vector2i) -> bool:
	if current_map == null:
		return false
	
	return current_map.is_valid_position(position)
