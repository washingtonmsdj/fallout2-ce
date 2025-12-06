extends Node2D
class_name MapObject
## Objeto interativo no mapa (porta, container, etc)

enum ObjectType {
	DOOR,
	CONTAINER,
	SCENERY,
	CRITTER
}

@export var object_type: ObjectType = ObjectType.SCENERY
@export var object_id: String = ""
@export var is_locked: bool = false
@export var lock_difficulty: int = 0
@export var script_id: String = ""

var is_open: bool = false
var is_interactable: bool = true

signal interacted(player: Critter)
signal state_changed(new_state: String)

## Interage com o objeto
func interact(player: Critter) -> void:
	if not is_interactable:
		return
	
	match object_type:
		ObjectType.DOOR:
			_interact_door(player)
		ObjectType.CONTAINER:
			_interact_container(player)
		ObjectType.SCENERY:
			_interact_scenery(player)
	
	interacted.emit(player)

## Interage com uma porta
func _interact_door(player: Critter) -> void:
	if is_locked:
		# Verificar se o jogador tem a chave ou pode abrir
		if not _can_unlock(player):
			return
	
	is_open = not is_open
	state_changed.emit("open" if is_open else "closed")

## Interage com um container
func _interact_container(player: Critter) -> void:
	if is_locked:
		if not _can_unlock(player):
			return
	
	is_open = not is_open
	state_changed.emit("open" if is_open else "closed")

## Interage com cenário
func _interact_scenery(player: Critter) -> void:
	# Executar script customizado se houver
	if not script_id.is_empty():
		_execute_script(player)

## Verifica se pode desbloquear
func _can_unlock(player: Critter) -> bool:
	# Verificar se tem chave
	for item in player.inventory:
		if item is Item and item.item_name.contains("Key"):
			return true
	
	# Verificar skill de lockpick
	if player.skills:
		var lockpick_skill = player.skills.get_skill_value(SkillData.Skill.LOCKPICK)
		if lockpick_skill > lock_difficulty:
			return true
	
	return false

## Executa um script customizado
func _execute_script(player: Critter) -> void:
	# Implementação de scripts customizados
	pass

## Desbloqueia o objeto
func unlock() -> void:
	is_locked = false
	state_changed.emit("unlocked")

## Bloqueia o objeto
func lock() -> void:
	is_locked = true
	state_changed.emit("locked")

## Retorna informações sobre o objeto
func get_object_info() -> Dictionary:
	return {
		"id": object_id,
		"type": ObjectType.keys()[object_type],
		"is_locked": is_locked,
		"is_open": is_open,
		"is_interactable": is_interactable,
		"lock_difficulty": lock_difficulty
	}
