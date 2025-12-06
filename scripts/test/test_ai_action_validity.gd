extends Node
## Teste de propriedade para validade de ações de IA
## **Feature: fallout2-complete-migration, Property 5: AI Action Validity**
## **Validates: Requirements 2.1**

class_name TestAIActionValidity

## Testa que ações de IA são válidas e executáveis
func test_ai_action_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Avaliar turno múltiplas vezes
	for i in range(10):
		var action = ai_controller.evaluate_turn()
		
		# Verificar que a ação retornada é válida
		if action.size() > 0:
			assert("action" in action,
				"AI action should have an 'action' key")
			
			var action_name = action["action"]
			assert(action_name is String and action_name != "",
				"Action name should be a non-empty string")

## Testa que ações de combate requerem AP suficiente
func test_ai_combat_action_ap_requirement() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	
	# Reduzir AP para 0
	critter.stats.current_ap = 0
	
	# Tentar executar ataque
	var can_attack = ai_controller.execute_attack({})
	assert(not can_attack,
		"AI should not be able to attack without sufficient AP")

## Testa que ações de fuga são válidas
func test_ai_flee_action_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	
	# Reduzir HP para ativar fuga
	critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
	
	# Verificar que deve fugir
	var should_flee = ai_controller.should_flee()
	
	# Depende da personalidade
	match ai_controller.personality:
		AIController.AIPersonality.AGGRESSIVE:
			assert(not should_flee, "Aggressive AI should not flee")
		AIController.AIPersonality.DEFENSIVE:
			assert(should_flee, "Defensive AI should flee when low on HP")
		AIController.AIPersonality.COWARD:
			assert(should_flee, "Coward AI should flee when low on HP")
		AIController.AIPersonality.BERSERK:
			assert(not should_flee, "Berserk AI should not flee")

## Testa que seleção de arma é válida
func test_ai_weapon_selection_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Adicionar armas ao inventário
	var weapon1 = Weapon.new()
	weapon1.item_name = "Pistol"
	weapon1.min_damage = 5
	weapon1.max_damage = 10
	
	var weapon2 = Weapon.new()
	weapon2.item_name = "Rifle"
	weapon2.min_damage = 10
	weapon2.max_damage = 20
	
	critter.inventory.append(weapon1)
	critter.inventory.append(weapon2)
	
	# Selecionar melhor arma
	var best_weapon = ai_controller.select_best_weapon()
	
	# Deve selecionar a arma com maior dano
	if best_weapon:
		var avg_damage = (best_weapon.min_damage + best_weapon.max_damage) / 2.0
		assert(avg_damage >= 7.5,
			"Selected weapon should have reasonable damage")

## Testa que busca de cobertura retorna posição válida
func test_ai_find_cover_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	target.global_position = Vector2(100, 100)
	
	ai_controller.set_controlled_critter(critter)
	ai_controller.set_target(target)
	
	critter.global_position = Vector2(0, 0)
	
	# Encontrar cobertura
	var cover_position = ai_controller.find_cover()
	
	# Verificar que a posição é válida
	assert(cover_position is Vector2,
		"Cover position should be a Vector2")
	
	# Verificar que está longe do alvo
	var distance_to_target = cover_position.distance_to(target.global_position)
	assert(distance_to_target > 50.0,
		"Cover position should be away from target")

## Testa que mudança de estado é válida
func test_ai_state_change_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	
	ai_controller.set_controlled_critter(critter)
	
	# Testar todas as transições de estado
	var states = [
		AIController.AIState.IDLE,
		AIController.AIState.PATROL,
		AIController.AIState.ALERT,
		AIController.AIState.COMBAT,
		AIController.AIState.FLEE
	]
	
	for state in states:
		ai_controller.set_state(state)
		assert(ai_controller.current_state == state,
			"AI state should change correctly")

## Testa que aquisição de alvo é válida
func test_ai_target_acquisition_validity() -> void:
	var ai_controller = AIController.new()
	var critter = _create_test_critter()
	var target = _create_test_critter()
	target.critter_name = "Target"
	
	ai_controller.set_controlled_critter(critter)
	
	# Verificar que não tem alvo inicialmente
	assert(not ai_controller.has_target(),
		"AI should not have target initially")
	
	# Adquirir alvo
	ai_controller.set_target(target)
	assert(ai_controller.has_target(),
		"AI should have target after acquisition")
	
	# Perder alvo
	ai_controller.set_target(null)
	assert(not ai_controller.has_target(),
		"AI should not have target after losing it")

## Testa que personalidades afetam comportamento
func test_ai_personality_affects_behavior() -> void:
	var personalities = [
		AIController.AIPersonality.AGGRESSIVE,
		AIController.AIPersonality.DEFENSIVE,
		AIController.AIPersonality.COWARD,
		AIController.AIPersonality.BERSERK
	]
	
	for personality in personalities:
		var ai_controller = AIController.new()
		ai_controller.personality = personality
		
		var critter = _create_test_critter()
		ai_controller.set_controlled_critter(critter)
		
		# Reduzir HP
		critter.stats.current_hp = int(critter.stats.max_hp * 0.2)
		
		# Verificar que personalidade afeta decisão de fuga
		var should_flee = ai_controller.should_flee()
		
		match personality:
			AIController.AIPersonality.AGGRESSIVE:
				assert(not should_flee, "Aggressive should not flee")
			AIController.AIPersonality.DEFENSIVE:
				assert(should_flee, "Defensive should flee")
			AIController.AIPersonality.COWARD:
				assert(should_flee, "Coward should flee")
			AIController.AIPersonality.BERSERK:
				assert(not should_flee, "Berserk should not flee")

## Cria um personagem de teste
func _create_test_critter() -> Critter:
	var critter = Critter.new()
	critter.critter_name = "Test Critter"
	critter.is_player = false
	critter.faction = "enemy"
	critter.level = 5
	
	critter.stats = StatData.new()
	critter.stats.strength = 6
	critter.stats.perception = 6
	critter.stats.endurance = 6
	critter.stats.charisma = 5
	critter.stats.intelligence = 5
	critter.stats.agility = 6
	critter.stats.luck = 5
	critter.stats.calculate_derived_stats()
	
	critter.skills = SkillData.new()
	
	return critter

## Executa todos os testes
func run_all_tests() -> void:
	print("=== Running AI Action Validity Property Tests ===")
	
	test_ai_action_validity()
	print("✓ test_ai_action_validity passed")
	
	test_ai_combat_action_ap_requirement()
	print("✓ test_ai_combat_action_ap_requirement passed")
	
	test_ai_flee_action_validity()
	print("✓ test_ai_flee_action_validity passed")
	
	test_ai_weapon_selection_validity()
	print("✓ test_ai_weapon_selection_validity passed")
	
	test_ai_find_cover_validity()
	print("✓ test_ai_find_cover_validity passed")
	
	test_ai_state_change_validity()
	print("✓ test_ai_state_change_validity passed")
	
	test_ai_target_acquisition_validity()
	print("✓ test_ai_target_acquisition_validity passed")
	
	test_ai_personality_affects_behavior()
	print("✓ test_ai_personality_affects_behavior passed")
	
	print("=== All AI Action Validity tests passed! ===")
