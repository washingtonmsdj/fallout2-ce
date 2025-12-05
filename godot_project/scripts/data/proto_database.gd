class_name ProtoDatabase
extends Resource

## Database de protótipos do Fallout 2
## Mapeia PIDs para tipos de objetos, sprites e propriedades

# Tipos de objetos (baseado no byte alto do PID)
enum ObjectType {
	ITEM = 0,
	CRITTER = 1,
	SCENERY = 2,
	WALL = 3,
	TILE = 4,
	MISC = 5
}

# Subtipos de items
enum ItemType {
	ARMOR = 0,
	CONTAINER = 1,
	DRUG = 2,
	WEAPON = 3,
	AMMO = 4,
	MISC_ITEM = 5,
	KEY = 6
}

# Subtipos de scenery
enum SceneryType {
	DOOR = 0,
	STAIRS = 1,
	ELEVATOR = 2,
	LADDER_BOTTOM = 3,
	LADDER_TOP = 4,
	GENERIC = 5
}

# Cache de protótipos
static var proto_cache: Dictionary = {}
static var fid_to_sprite_cache: Dictionary = {}

## Extrair tipo de objeto do PID
static func get_object_type(pid: int) -> ObjectType:
	return (pid >> 24) & 0xFF as ObjectType

## Extrair subtipo do PID
static func get_subtype(pid: int) -> int:
	return (pid >> 16) & 0xFF

## Extrair ID do proto do PID
static func get_proto_id(pid: int) -> int:
	return pid & 0xFFFF

## Obter informações do protótipo
static func get_proto_info(pid: int) -> Dictionary:
	if proto_cache.has(pid):
		return proto_cache[pid]
	
	var info = {
		"pid": pid,
		"type": get_object_type(pid),
		"subtype": get_subtype(pid),
		"proto_id": get_proto_id(pid),
		"name": "",
		"sprite_path": "",
		"walkable": true,
		"blocks_light": false,
		"interactive": false
	}
	
	# Determinar propriedades baseado no tipo
	match info.type:
		ObjectType.CRITTER:
			info.name = "Critter_%d" % info.proto_id
			info.sprite_path = "res://assets/sprites/characters/critter_%d.png" % info.proto_id
			info.walkable = false
			info.interactive = true
		
		ObjectType.ITEM:
			info.name = "Item_%d" % info.proto_id
			info.sprite_path = "res://assets/sprites/items/item_%d.png" % info.proto_id
			info.walkable = true
			info.interactive = true
		
		ObjectType.SCENERY:
			info.name = "Scenery_%d" % info.proto_id
			info.sprite_path = "res://assets/sprites/scenery/scenery_%d.png" % info.proto_id
			info.walkable = (info.subtype == SceneryType.GENERIC)
			info.blocks_light = true
			info.interactive = (info.subtype in [SceneryType.DOOR, SceneryType.STAIRS, SceneryType.ELEVATOR])
		
		ObjectType.WALL:
			info.name = "Wall_%d" % info.proto_id
			info.sprite_path = "res://assets/sprites/walls/wall_%d.png" % info.proto_id
			info.walkable = false
			info.blocks_light = true
		
		ObjectType.MISC:
			info.name = "Misc_%d" % info.proto_id
			info.sprite_path = "res://assets/sprites/misc/misc_%d.png" % info.proto_id
			info.walkable = true
	
	proto_cache[pid] = info
	return info

## Obter sprite path do FRM ID
static func get_sprite_from_fid(fid: int) -> String:
	if fid_to_sprite_cache.has(fid):
		return fid_to_sprite_cache[fid]
	
	# Extrair tipo e ID do FID
	var fid_type = (fid >> 24) & 0xF
	var fid_id = fid & 0xFFFF
	
	var sprite_path = ""
	
	match fid_type:
		0:  # Items
			sprite_path = "res://assets/sprites/items/item_%04d.png" % fid_id
		1:  # Critters
			sprite_path = "res://assets/sprites/characters/critter_%04d.png" % fid_id
		2:  # Scenery
			sprite_path = "res://assets/sprites/scenery/scenery_%04d.png" % fid_id
		3:  # Walls
			sprite_path = "res://assets/sprites/walls/wall_%04d.png" % fid_id
		4:  # Tiles
			sprite_path = "res://assets/sprites/tiles/tile_%04d.png" % fid_id
		5:  # Misc
			sprite_path = "res://assets/sprites/misc/misc_%04d.png" % fid_id
	
	fid_to_sprite_cache[fid] = sprite_path
	return sprite_path

## Verificar se PID é válido
static func is_valid_pid(pid: int) -> bool:
	if pid == 0 or pid == 0xFFFFFFFF:
		return false
	
	var obj_type = get_object_type(pid)
	return obj_type >= ObjectType.ITEM and obj_type <= ObjectType.MISC

## Obter nome legível do tipo
static func get_type_name(obj_type: ObjectType) -> String:
	match obj_type:
		ObjectType.ITEM: return "Item"
		ObjectType.CRITTER: return "Critter"
		ObjectType.SCENERY: return "Scenery"
		ObjectType.WALL: return "Wall"
		ObjectType.TILE: return "Tile"
		ObjectType.MISC: return "Misc"
		_: return "Unknown"
