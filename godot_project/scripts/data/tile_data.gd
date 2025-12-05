class_name TileData
extends RefCounted

## Dados de um tile individual do mapa

@export var tile_id: int = 0
@export var elevation: int = 0

# Flags de tile
var walkable: bool = true
var transparent: bool = true
var damaged: bool = false
var locked: bool = false


func _init() -> void:
	pass


## Verificar se tile é caminhável
func is_walkable() -> bool:
	return walkable and not locked


## Verificar se tile é transparente
func is_transparent() -> bool:
	return transparent


## Marcar tile como danificado
func set_damaged(state: bool) -> void:
	damaged = state


## Marcar tile como trancado
func set_locked(state: bool) -> void:
	locked = state


## Obter flags do tile
func get_flags() -> int:
	var flags: int = 0
	
	if walkable:
		flags |= 1  # Bit 0: walkable
	if transparent:
		flags |= 2  # Bit 1: transparent
	if damaged:
		flags |= 4  # Bit 2: damaged
	if locked:
		flags |= 8  # Bit 3: locked
	
	return flags


## Definir flags do tile
func set_flags(flags: int) -> void:
	walkable = (flags & 1) != 0
	transparent = (flags & 2) != 0
	damaged = (flags & 4) != 0
	locked = (flags & 8) != 0
