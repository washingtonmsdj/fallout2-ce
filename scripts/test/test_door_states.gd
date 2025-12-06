extends Node
## Teste de propriedade para transições de estado de porta
## **Feature: fallout2-complete-migration, Property 11: Door State Transitions**
## **Validates: Requirements 3.3**

class_name TestDoorStates

## Testa que porta começa fechada
func test_door_starts_closed() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	assert(not door.is_open,
		"Door should start closed")

## Testa que porta pode ser aberta
func test_door_can_be_opened() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	var player = _create_test_critter()
	door.interact(player)
	
	assert(door.is_open,
		"Door should be open after interaction")

## Testa que porta pode ser fechada
func test_door_can_be_closed() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	door.is_open = true
	
	var player = _create_test_critter()
	door.interact(player)
	
	assert(not door.is_open,
		"Door should be closed after interaction")

## Testa que porta bloqueada não pode ser aberta sem chave
func test_locked_door_cannot_be_opened_without_key() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = true
	door.lock_difficulty = 50
	
	var player = _create_test_critter()
	player.skills.skill_values[SkillData.Skill.LOCKPICK] = 10  # Skill baixa
	
	door.interact(player)
	
	assert(not door.is_open,
		"Locked door should not open without sufficient skill")

## Testa que porta pode ser desbloqueada com skill suficiente
func test_locked_door_can_be_opened_with_skill() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = true
	door.lock_difficulty = 30
	
	var player = _create_test_critter()
	player.skills.skill_values[SkillData.Skill.LOCKPICK] = 50  # Skill alta
	
	door.interact(player)
	
	assert(door.is_open,
		"Door should open with sufficient lockpick skill")

## Testa que porta pode ser desbloqueada com chave
func test_locked_door_can_be_opened_with_key() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = true
	door.lock_difficulty = 100  # Muito difícil
	
	var player = _create_test_critter()
	player.skills.skill_values[SkillData.Skill.LOCKPICK] = 10  # Skill baixa
	
	# Adicionar chave ao inventário
	var key = Item.new()
	key.item_name = "Key"
	player.inventory.append(key)
	
	door.interact(player)
	
	assert(door.is_open,
		"Door should open with key")

## Testa que porta pode ser bloqueada
func test_door_can_be_locked() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	door.lock()
	
	assert(door.is_locked,
		"Door should be locked after lock()")

## Testa que porta pode ser desbloqueada
func test_door_can_be_unlocked() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = true
	
	door.unlock()
	
	assert(not door.is_locked,
		"Door should be unlocked after unlock()")

## Testa transição de estado: fechada -> aberta -> fechada
func test_door_state_cycle() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	var player = _create_test_critter()
	
	# Começar fechada
	assert(not door.is_open, "Door should start closed")
	
	# Abrir
	door.interact(player)
	assert(door.is_open, "Door should be open")
	
	# Fechar
	door.interact(player)
	assert(not door.is_open, "Door should be closed")
	
	# Abrir novamente
	door.interact(player)
	assert(door.is_open, "Door should be open again")

## Testa que porta emite sinal ao mudar de estado
func test_door_emits_state_changed_signal() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	var signal_emitted = false
	var signal_state = ""
	
	door.state_changed.connect(func(state: String) -> void:
		signal_emitted = true
		signal_state = state
	)
	
	var player = _create_test_critter()
	door.interact(player)
	
	assert(signal_emitted, "state_changed signal should be emitted")
	assert(signal_state == "open", "Signal should indicate 'open' state")

## Testa que porta emite sinal ao ser interagida
func test_door_emits_interacted_signal() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	
	var signal_emitted = false
	
	door.interacted.connect(func(player: Critter) -> void:
		signal_emitted = true
	)
	
	var player = _create_test_critter()
	door.interact(player)
	
	assert(signal_emitted, "interacted signal should be emitted")

## Testa que porta não interativa não pode ser aberta
func test_non_interactable_door_cannot_be_opened() -> void:
	var door = MapObject.new()
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = false
	door.is_interactable = false
	
	var player = _create_test_critter()
	door.interact(player)
	
	assert(not door.is_open,
		"Non-interactable door should not open")

## Testa informações da porta
func test_door_info_returned() -> void:
	var door = MapObject.new()
	door.object_id = "door_1"
	door.object_type = MapObject.ObjectType.DOOR
	door.is_locked = true
	door.lock_difficulty = 50
	door.is_open = false
	
	var info = door.get_object_info()
	
	assert(info["id"] == "door_1", "Door ID should be correct")
	assert(info["type"] == "DOOR", "Door type should be DOOR")
	assert(info["is_locked"] == true, "Door should be locked")
	assert(info["is_open"] == false, "Door should be closed")
	assert(info["lock_difficulty"] == 50, "Lock difficulty should be correct")

## Cria um personagem de teste
func _create_test_critter() -> Critter:
	var critter = Critter.new()
	critter.critter_name = "Test Player"
	critter.is_player = true
	critter.faction = "player"
	
	critter.stats = StatData.new()
	critter.stats.strength = 5
	critter.stats.perception = 5
	critter.stats.endurance = 5
	critter.stats.charisma = 5
	critter.stats.intelligence = 5
	critter.stats.agility = 5
	critter.stats.luck = 5
	critter.stats.calculate_derived_stats()
	
	critter.skills = SkillData.new()
	
	return critter

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running Door State Property Tests ===")
	
	test_door_starts_closed()
	print("✓ test_door_starts_closed passed")
	
	test_door_can_be_opened()
	print("✓ test_door_can_be_opened passed")
	
	test_door_can_be_closed()
	print("✓ test_door_can_be_closed passed")
	
	test_locked_door_cannot_be_opened_without_key()
	print("✓ test_locked_door_cannot_be_opened_without_key passed")
	
	test_locked_door_can_be_opened_with_skill()
	print("✓ test_locked_door_can_be_opened_with_skill passed")
	
	test_locked_door_can_be_opened_with_key()
	print("✓ test_locked_door_can_be_opened_with_key passed")
	
	test_door_can_be_locked()
	print("✓ test_door_can_be_locked passed")
	
	test_door_can_be_unlocked()
	print("✓ test_door_can_be_unlocked passed")
	
	test_door_state_cycle()
	print("✓ test_door_state_cycle passed")
	
	test_door_emits_state_changed_signal()
	print("✓ test_door_emits_state_changed_signal passed")
	
	test_door_emits_interacted_signal()
	print("✓ test_door_emits_interacted_signal passed")
	
	test_non_interactable_door_cannot_be_opened()
	print("✓ test_non_interactable_door_cannot_be_opened passed")
	
	test_door_info_returned()
	print("✓ test_door_info_returned passed")
	
	print("=== All Door State tests passed! ===")
